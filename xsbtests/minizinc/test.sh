#! /bin/sh

echo "-------------------------------------------------------"
echo "--- Running MiniZinc tests minizinc/test.sh         ---"
echo "-------------------------------------------------------"


XEMU=$1
options=$2

if ! command -v minizinc >/dev/null 2>&1; then
    echo "CONFIGURATION WARNING: minizinc/mzn_examples skipped because the minizinc command is unavailable."
    exit 0
fi

../gentest.sh "$XEMU $options" mzn_examples "test."
