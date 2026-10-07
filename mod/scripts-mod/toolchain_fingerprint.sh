#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -euo pipefail

echo "=== [STEALTH] Generating clean toolchain fingerprint... ==="

# FIX 2: Dynamic path resolution based on script location
# Find the root project directory relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

INPUT_FILE="${PROJECT_ROOT}/scripts/versions.sh"
OUTPUT_FILE="${PROJECT_ROOT}/toolchain-only.env"

# Verify that the author's version file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "CRITICAL ERROR: Version manifest not found at $INPUT_FILE"
    exit 1
fi

# FIX 1: Comprehensive toolchain filtering
# Includes every single standalone tool used by the builder:
# NDK, SDK, JDK, RUST, CBINDGEN, BUNDLETOOL, NODE, NPM, UV, WASI, ANDROGUARD, GYP
TARGET_KEYWORDS="NDK|SDK|JDK|RUST|CBINDGEN|BUNDLETOOL|NODE|NPM|UV|WASI|ANDROGUARD|GYP"

# Filter, sort, and save to prevent line-order cache invalidation
grep -E "$TARGET_KEYWORDS" "$INPUT_FILE" | sort > "$OUTPUT_FILE"

echo "=== [STEALTH] Fingerprint file successfully created: $OUTPUT_FILE ==="
