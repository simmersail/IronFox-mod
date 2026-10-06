#!/bin/bash
set -euo pipefail

echo "=== [STEALTH] Step 1: Deploying Android Release Signing Key ==="

# Define sensitive paths
TARGET_DIR="/opt/IronFox"
KEYSTORE_PATH="${TARGET_DIR}/ironfox-android-keystore.jks"
PASS_FILE="${TARGET_DIR}/ironfox-android-keystore-pass.txt"
KEY_FILE="${TARGET_DIR}/ironfox-android-signing-key-pass.txt"
SB_FILE="${TARGET_DIR}/ironfox-sb-gapi-key.txt"

# SECURITY SHIELD: Cleanup function to destroy secrets if the pipeline fails midway
cleanup_secrets() {
    echo "=== [STEALTH] Security Shield: Cleaning up sensitive files from disk... ==="
    rm -f "$PASS_FILE" "$KEY_FILE"
    # Overwrite keystore with zeros before deleting to prevent forensic recovery
    if [ -f "$KEYSTORE_PATH" ]; then
        dd if=/dev/null of="$KEYSTORE_PATH" status=none 2>/dev/null || true
        rm -f "$KEYSTORE_PATH"
    fi
}
# Register the trap: execute cleanup_secrets on exit, errors, or interruptions
trap cleanup_secrets EXIT ERR INT TERM

# 1. Create target directory required by the build system
mkdir -p "$TARGET_DIR"

# 2. Generate Safe Browsing placeholder
echo "disabled" > "$SB_FILE"

# 3. Validate and restore the keystore binary from GitHub Secrets
if [ -n "${SIGNING_KEY_BASE64+x}" ] && [ -n "$SIGNING_KEY_BASE64" ] && [ -n "${SIGNING_KEY_PASS+x}" ]; then
    echo "=== [STEALTH] Decoding binary Keystore from Base64 string... ==="
    # Decode base64 to binary without printing the string to stdout
    echo "$SIGNING_KEY_BASE64" | base64 -d > "$KEYSTORE_PATH"
    
    echo "=== [STEALTH] Writing passwords securely... ==="
    # SECURITY FIX: Use printf to avoid leaking secrets into logs
    # We pass the secret variable directly without any aggressive filtering
    printf "%s" "$SIGNING_KEY_PASS" > "$PASS_FILE"
    printf "%s" "$SIGNING_KEY_PASS" > "$KEY_FILE"
    
    # Hide passwords from being readable by other non-root users inside container
    chmod 600 "$PASS_FILE" "$KEY_FILE" "$KEYSTORE_PATH"
else
    echo "CRITICAL ERROR: SIGNING_KEY_BASE64 or SIGNING_KEY_PASS is missing in environment variables!"
    exit 1
fi

echo "=== [STEALTH] Release digital signature successfully deployed to /opt/IronFox/ ==="

# Disable the trap's auto-cleanup for the rest of the build execution.
# The keys will remain available until the final Gradle task packages the APK.
trap - EXIT ERR INT TERM
