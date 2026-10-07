#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -euo pipefail

echo "=== [STEALTH] Generating clean toolchain fingerprint... ==="

# FIX 2: Dynamic path resolution based on script location
# Find the root project directory relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

INPUT_FILE="${PROJECT_ROOT}/scripts/versions.sh"

# Paths for our new isolated fingerprint files
HOST_TOOLS_ENV="${PROJECT_ROOT}/host-tools.env"
COMPILERS_ENV="${PROJECT_ROOT}/compilers.env"

# Verify that the author's version file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "CRITICAL ERROR: Version manifest not found at $INPUT_FILE"
    exit 1
fi

# =====================================================================
# FILTER 1: Host & Runtime Packagers (Rust, Cargo, UV, Node, Python tools)
# =====================================================================
# These tools execute on the host or inside the container to orchestrate building.
# If they change, we ONLY invalidate the fast cargo/uv package layer.
HOST_KEYWORDS="RUST|CBINDGEN|NODE|NPM|UV|PIP|PYYAML|ANDROGUARD|GYP|S3CMD|SHELLCHECK|SHFMT"
grep -E "$HOST_KEYWORDS" "$INPUT_FILE" | sort > "$HOST_TOOLS_ENV"

# =====================================================================
# FILTER 2: Heavy Cross-Compilers (Android SDK, NDK, JDK, WASI, Packaging)
# =====================================================================
# These are giant standalone binaries from Google and Adoptium. 
# They rarely change. Keeping them isolated prevents re-downloading gigabytes.
COMPILER_KEYWORDS="NDK|SDK|JDK|BUNDLETOOL|WASI"
grep -E "$COMPILER_KEYWORDS" "$INPUT_FILE" | sort > "$COMPILERS_ENV"

echo "=== [STEALTH] SUCCESS: Modular fingerprints created successfully! ==="
echo "-> Host tools manifest: $HOST_TOOLS_ENV"
echo "-> Compilers manifest:  $COMPILERS_ENV"
