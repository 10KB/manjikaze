#!/bin/bash
# Runs the behaviour tests and lists the files that failed.
# Usage: tests/run.sh [test file...] (default: every tests/*-test.sh)
set -e

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    tests=("$(dirname "$(readlink -f "$0")")"/*-test.sh)
fi

failed=()
for test in "${tests[@]}"; do
    echo "==> $(basename "$test")"
    # A test file stops at its first failure, so the files after it still run.
    if ! bash "$test"; then
        failed+=("$(basename "$test")")
    fi
done

if [[ ${#failed[@]} -gt 0 ]]; then
    echo "Failed: ${failed[*]}"
    exit 1
fi
echo "All tests passed."
