#!/bin/sh
# Stage and validate a local XSB 5.1.0 MacPorts package without modifying
# the installed MacPorts ports tree. Usage: build_package.sh source.tar.gz
set -eu

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
    echo "Usage: $0 /absolute/path/to/source.tar.gz" >&2
    exit 2
fi

archive_dir=$(cd "$(dirname "$1")" && pwd)
archive="$archive_dir/$(basename "$1")"
tar -tzf "$archive" | grep -q '^XSB/admin/macosx/install_in_place.sh$' || {
    echo "Archive lacks the in-place installer" >&2
    exit 1
}

stage=$(mktemp -d "${TMPDIR:-/tmp}/xsb-macports.XXXXXX")
script_dir=$(cd "$(dirname "$0")" && pwd)
cp "$archive" "$stage/xsb-5.1.0.tar.gz"
sha256=$(shasum -a 256 "$stage/xsb-5.1.0.tar.gz" | awk '{print $1}')
sed -e "s|@DISTDIR@|$stage|g" -e "s|@SHA256@|$sha256|g" \
    "$script_dir/Portfile" > "$stage/Portfile"

echo "Staged Portfile: $stage/Portfile"
echo "Source archive: $archive"
echo "SHA-256: $sha256"
echo "Checking MacPorts and linting the staged Portfile..."
port version
port -D "$stage" lint
port -D "$stage" pkg
echo "MacPorts package build completed in $stage/work; install-test the .pkg before release."
