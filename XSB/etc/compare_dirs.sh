#!/usr/bin/env bash

  set -o pipefail

  if [ "$#" -ne 2 ]; then
    echo "Usage: $0 DIR_A DIR_B" >&2
    exit 1
  fi

  a=$1
  b=$2

  if [ ! -d "$a" ] || [ ! -d "$b" ]; then
    echo "Both arguments must be directories." >&2
    exit 1
  fi

  tmpdir=$(mktemp -d) || exit 1
  trap 'rm -rf "$tmpdir"' EXIT

  list_files() (
    cd -- "$1" || exit 1
    find . -type f \
      ! -name '*.xwam' ! -name '#*' ! -name '*.o' \
      ! -name '*.pyc' ! -name '*~' ! -name '*_new' \
      ! -name '*dylib' ! -name '*so' \
      -print | sed 's#^\./##' | LC_ALL=C sort
  )

  list_files "$a" > "$tmpdir/a" || exit 1
  list_files "$b" > "$tmpdir/b" || exit 1

  echo "Files in $a but not $b:"
  LC_ALL=C comm -23 "$tmpdir/a" "$tmpdir/b" || exit 1

  echo
  echo "Files in $b but not $a:"
  LC_ALL=C comm -13 "$tmpdir/a" "$tmpdir/b" || exit 1

  echo
  echo "Files with different contents in $a and $b:"
  LC_ALL=C comm -12 "$tmpdir/a" "$tmpdir/b" > "$tmpdir/common" || exit 1
  status=0
  while IFS= read -r file; do
    cmp -s -- "$a/$file" "$b/$file"
    result=$?
    if [ "$result" -eq 1 ]; then
      printf '%s\n' "$file"
    elif [ "$result" -ne 0 ]; then
      printf 'Could not compare: %s\n' "$file" >&2
      status=1
    fi
  done < "$tmpdir/common"
  exit "$status"
