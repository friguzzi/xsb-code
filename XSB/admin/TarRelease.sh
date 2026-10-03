#!/bin/sh

# Create matching source archives from one committed repository revision.
# Run from any directory, after committing the intended release changes.
#
# Usage: TarRelease.sh VERSION OUTPUT_DIR COMMIT_OR_TAG
#   VERSION       Release number used in the archive names, e.g. 5.1.0.
#   OUTPUT_DIR    Directory in which to create the .tar.gz and .zip files.
#   COMMIT_OR_TAG Existing Git commit ID or tag to archive. This is argument 3.
#                 From the repository root, `git rev-parse HEAD` prints the
#                 current commit ID; `git tag --list` shows available tags.
#
# Example, from the repository root after committing:
#   ./XSB/admin/TarRelease.sh 5.1.0 /path/to/output "$(git rev-parse HEAD)"
# Or pass an existing release tag in place of the commit ID, e.g. v5.1.0.
# Git archive intentionally omits uncommitted edits and untracked files.

set -eu

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 VERSION OUTPUT_DIR COMMIT_OR_TAG" >&2
    echo "Find the current commit with: git rev-parse HEAD" >&2
    echo "List existing tags with: git tag --list" >&2
    exit 2
fi

version=$1
output_dir=$2
ref=$3
case "$version" in
    ''|*[!a-zA-Z0-9._-]*)
        echo "Invalid release version: $version" >&2
        exit 2
        ;;
esac

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
repo_dir=$(CDPATH= cd "$script_dir/../.." && pwd)
commit=$(git -C "$repo_dir" rev-parse --verify "$ref^{commit}") || {
    echo "Not a commit or tag: $ref" >&2
    exit 2
}

mkdir -p "$output_dir"
output_dir=$(CDPATH= cd "$output_dir" && pwd)
base="XSB-$version-source"
tar_out="$output_dir/$base.tar.gz"
zip_out="$output_dir/$base.zip"
if [ -e "$tar_out" ] || [ -L "$tar_out" ] || [ -e "$zip_out" ] || [ -L "$zip_out" ]; then
    echo "Release archive already exists; choose a new output directory or version." >&2
    exit 1
fi

stage=$(mktemp -d "$output_dir/.xsb-release.XXXXXX")
cleanup() {
    rm -f "$stage/source.tar" "$stage/source.tar.gz" "$stage/source.zip" \
        "$stage/tar.list" "$stage/zip.list"
    rmdir "$stage"
}
trap 'cleanup' 0
trap 'exit 1' 1 2 3 15

# Keep tracked bootstrapping files under XSB/. Exclude generated objects only
# from the three test trees; their reference outputs and source files remain.
set -- .
for test_dir in xsbtests mttests altmttest; do
    for extension in xwam o obj so dylib dll a pyc class exe; do
        set -- "$@" ":(exclude,glob)$test_dir/*.$extension" \
            ":(exclude,glob)$test_dir/**/*.$extension"
    done
done

root="XSB-$version"
echo "Archiving commit $commit (working-tree edits and untracked files ignored)"
git -C "$repo_dir" archive --format=tar --prefix="$root/" \
    --output="$stage/source.tar" "$commit" -- "$@"
gzip -n "$stage/source.tar"
git -C "$repo_dir" archive --format=zip --prefix="$root/" \
    --output="$stage/source.zip" "$commit" -- "$@"

tar -tzf "$stage/source.tar.gz" > "$stage/tar.list"
unzip -tq "$stage/source.zip" >/dev/null
unzip -Z -1 "$stage/source.zip" > "$stage/zip.list"
LC_ALL=C sort -o "$stage/tar.list" "$stage/tar.list"
LC_ALL=C sort -o "$stage/zip.list" "$stage/zip.list"
if ! cmp -s "$stage/tar.list" "$stage/zip.list"; then
    echo "Tar and ZIP contents differ" >&2
    exit 1
fi
for required in \
    "$root/XSB/build/configure" \
    "$root/XSB/build/configure.ac" \
    "$root/XSB/packages/janus/configure" \
    "$root/XSB/packages/janus/configure.ac" \
    "$root/xsbtests/testsuite.sh" \
    "$root/mttests/test_concurr.sh"; do
    if ! grep -Fqx "$required" "$stage/tar.list"; then
        echo "Missing required release file: $required" >&2
        exit 1
    fi
done
if grep -Eq '/(xsbtests|mttests|altmttest)/.*\.(xwam|o|obj|so|dylib|dll|a|pyc|class|exe)$' "$stage/tar.list"; then
    echo "Test build object found in release archive" >&2
    exit 1
fi

mv "$stage/source.tar.gz" "$tar_out"
mv "$stage/source.zip" "$zip_out"
echo "Created $tar_out"
echo "Created $zip_out"
shasum -a 256 "$tar_out" "$zip_out"
