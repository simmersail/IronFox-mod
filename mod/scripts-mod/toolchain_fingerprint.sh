#!/bin/bash
set -euo pipefail

echo "=== [STEALTH] Generating ultra-modular environment fingerprints... ==="

# Resolve absolute paths relative to this script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

INPUT_FILE="${PROJECT_ROOT}/scripts/versions.sh"

# Toolchain tracking manifests
HOST_TOOLS_ENV="${PROJECT_ROOT}/host-tools.env"
COMPILERS_ENV="${PROJECT_ROOT}/compilers.env"

# Isolated source code tracking manifests
GECKO_PURE_ENV="${PROJECT_ROOT}/gecko-pure-sources.env"
EXTERNAL_APPS_ENV="${PROJECT_ROOT}/external-apps-sources.env"
GLEAN_SOURCES_ENV="${PROJECT_ROOT}/glean-sources.env"

if [ ! -f "$INPUT_FILE" ]; then
    echo "CRITICAL ERROR: Version manifest not found at $INPUT_FILE"
    exit 1
fi

# =====================================================================
# STEP 1: Consolidate all declaration rows containing state targets
# =====================================================================
TEMP_MANIFEST="${PROJECT_ROOT}/all_versions.tmp"
grep -E "readonly .*(VERSION|REVISION|COMMIT|SHA512SUM|DATE|TARGET|MIN)" "$INPUT_FILE" | sort > "$TEMP_MANIFEST"

# =====================================================================
# STEP 2: Filter Host Runtimes & Orchestration Tools
# =====================================================================
# Fast-changing host utilities, orchestrators, and system dependencies
HOST_PATTERNS="RUST|CBINDGEN|NODE|NPM|NVM|PYTHON|PIP|PYYAML|ANDROGUARD|GYP|S3CMD|SHELLCHECK|SHFMT|GRADLE"
grep -E "$HOST_PATTERNS" "$TEMP_MANIFEST" > "$HOST_TOOLS_ENV" || true

# =====================================================================
# STEP 3: Filter Heavy Target Cross-Compilers
# =====================================================================
# Standalone binary bundles from upstream vendor platforms (Google/Adoptium)
COMPILER_PATTERNS="NDK|SDK|JDK|BUNDLETOOL|WASI|UNIFFI"
grep -E "$COMPILER_PATTERNS" "$TEMP_MANIFEST" > "$COMPILERS_ENV" || true

# =====================================================================
# STEP 4: Filter Pristine Mozilla Gecko & Localization Core
# =====================================================================
# Giant multi-gigabyte browser source code tied directly to Mozilla releases
GECKO_PATTERNS="GECKO|FIREFOX|L10N|APPSERVICES"
# Guard option to prevent capturing cross-compilers like JDK into pure sources
grep -E "$GECKO_PATTERNS" "$TEMP_MANIFEST" | grep -Ev "JDK" > "$GECKO_PURE_ENV" || true

# =====================================================================
# STEP 5: Filter Independent Third-Party Sub-Applications
# =====================================================================
# Standalone software extensions moving on separate upstream lifecycles
EXTERNAL_PATTERNS="PHOENIX|GMSCORE|UNIFIEDPUSHAC|UP_AC|PREBUILDS"
# Guard option to avoid duplication conflicts with host-layer toolchains
grep -E "$EXTERNAL_PATTERNS" "$TEMP_MANIFEST" | grep -Ev "ANDROGUARD" > "$EXTERNAL_APPS_ENV" || true

# =====================================================================
# STEP 6: Filter Isolated Telemetry Layers
# =====================================================================
# Isolated tracking configuration for downstream scrubbing passes
grep -E "GLEAN" "$TEMP_MANIFEST" > "$GLEAN_SOURCES_ENV" || true

# Clear out transient runtime workspace artifacts
rm -f "$TEMP_MANIFEST"

echo "=== [STEALTH] SUCCESS: All 5 independent fingerprints verified! ==="
echo "-> 1. Host Tools Manifest:         $HOST_TOOLS_ENV"
echo "-> 2. Heavy Compilers Manifest:    $COMPILERS_ENV"
echo "-> 3. Pure Gecko Code Manifest:    $GECKO_PURE_ENV"
echo "-> 4. External Apps Manifest:      $EXTERNAL_APPS_ENV"
echo "-> 5. Telemetry Code Manifest:     $GLEAN_SOURCES_ENV"
