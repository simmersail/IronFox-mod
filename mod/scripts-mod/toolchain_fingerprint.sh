#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -euo pipefail

echo "=== [STEALTH] Generating clean toolchain fingerprint... ==="

INPUT_FILE="scripts/versions.sh"
OUTPUT_FILE="toolchain-only.env"

# Verify that the author's version file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "ERROR: $INPUT_FILE not found!"
    exit 1
fi

# Filter only lines containing tool versions (NDK, SDK, JDK, RUST, CBINDGEN)
# We also sort the output so changes in line order won't invalidate the hash
grep -E "NDK|SDK|JDK|RUST|CBINDGEN" "$INPUT_FILE" | sort > "$OUTPUT_FILE"

echo "=== [STEALTH] Fingerprint file successfully created: $OUTPUT_FILE
==="
