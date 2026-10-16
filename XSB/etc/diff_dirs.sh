#!/usr/bin/env bash

# Edit this list to change the extensions compared (case-sensitive).
extensions=(.P .pl .c .H .h .i .tex)
# Lines of unchanged context shown around each change.
context=3

# Like compare_dirs.sh, differences are a successful result (exit 0).
# Invalid arguments or comparison errors cause exit 1.
diff_options=(--strip-trailing-cr)
while getopts ':w' option; do
  case "$option" in
    w) diff_options+=(-w) ;;
    *)
      echo "Usage: $0 [-w] [--] DIR_A DIR_B" >&2
      exit 1
      ;;
  esac
done
shift "$((OPTIND - 1))"

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 [-w] [--] DIR_A DIR_B" >&2
  exit 1
fi

if [ ! -d "$1" ] || [ ! -d "$2" ]; then
  echo "Both arguments must be directories." >&2
  exit 1
fi

a=$(cd -- "$1" && pwd -P) || exit 1
b=$(cd -- "$2" && pwd -P) || exit 1
a=${a%/}/
b=${b%/}/

tmpdir=$(mktemp -d) || exit 1
trap 'rm -rf "$tmpdir"' EXIT
find "$a" -type f -print0 > "$tmpdir/files" || exit 1

color=0
if [ -t 1 ] && [ "${TERM:-dumb}" != dumb ] && [ -z "${NO_COLOR+x}" ]; then
  color=1
fi

printf 'A: %s\nB: %s\n' "$1" "$2"
printf 'Changes below transform A into B: - removed, + added.\n'

compared=0
different=0
status=0
while IFS= read -r -d '' file; do
  relative=${file#"$a"}
  selected=0
  for extension in "${extensions[@]}"; do
    if [[ "$relative" == *"$extension" ]]; then
      selected=1
      break
    fi
  done
  [ "$selected" -eq 1 ] || continue
  [ -f "$b$relative" ] || continue

  compared=$((compared + 1))
  # Treat LF and CRLF line endings as equivalent.
  diff "${diff_options[@]}" -U "$context" -L "A/$relative" -L "B/$relative" \
    -- "$file" "$b$relative" > "$tmpdir/diff"
  result=$?
  if [ "$result" -gt 1 ]; then
    status=1
    continue
  fi
  [ "$result" -eq 1 ] || continue

  different=$((different + 1))
  printf '\n=== %s ===\n' "$relative"
  awk -v color="$color" '
    BEGIN {
      esc = sprintf("%c", 27)
      reset = esc "[0m"
      red = esc "[31m"
      green = esc "[32m"
      cyan = esc "[36m"
      bold = esc "[1m"
    }
    {
      style = ""
      if (/^--- / || /^\+\+\+ /) style = bold
      else if (/^@@/) style = cyan
      else if (/^-/) style = red
      else if (/^\+/) style = green
      if (color && style != "") printf "%s%s%s\n", style, $0, reset
      else print
    }
  ' "$tmpdir/diff" || status=1
done < "$tmpdir/files"

printf '\nCompared %d shared files with the selected extensions; %d differed.\n' \
  "$compared" "$different"
exit "$status"
