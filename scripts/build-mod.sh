set -ex

mkdir -p /opt/IronFox/
echo "dummy-keystore-content" > /opt/IronFox/ironfox-android-keystore.jks
echo "disabled" > /opt/IronFox/ironfox-sb-gapi-key.txt

git config --global --add safe.directory '*'
chmod +x scripts/*.sh

# Rust
export HOME=/root
if [ ! -f /root/.cargo/bin/cargo ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  fi
  export PATH="/root/.cargo/bin:$PATH"          
  if [ ! -f /root/.cargo/bin/cbindgen ]; then
    cargo install cbindgen
    fi     
    mkdir -p /opt/ironfox-tools/bin
    cp /root/.cargo/bin/cbindgen /opt/ironfox-tools/bin/cbindgen
    chmod +x /opt/ironfox-tools/bin/cbindgen
    export PATH="/opt/ironfox-tools/bin:$PATH"
            
            echo "Preparing sources for architecture: $BUILD_ARCH"
            rm -rf /__w/IronFox-mod/IronFox-mod/external/uv
            yes | ./scripts/get_sources.sh

            echo "ac_add_options --without-google-safebrowsing-api-keyfile" > overrides.mozconfig
                 
                 echo "Generating temporary CI Keystore for APK signing..."

                 sudo rm -f /opt/IronFox/ironfox-android-keystore.jks 2>/dev/null || rm -f /opt/IronFox/ironfox-android-keystore.jks

                 sudo mkdir -p /opt/IronFox/ 2>/dev/null || mkdir -p /opt/IronFox/
                 sudo chmod 777 /opt/IronFox/ 2>/dev/null || true
                 echo "my_ci_password_123" > /opt/IronFox/ironfox-android-keystore-pass.txt
                 echo "my_ci_password_123" > /opt/IronFox/ironfox-android-signing-key-pass.txt
                 EMBEDDED_KEYTOOL="/__w/IronFox-mod/IronFox-mod/external/jdk-21/bin/keytool"

                 if [ ! -f "$EMBEDDED_KEYTOOL" ]; then
                   echo "ERROR: Embedded keytool not found at $EMBEDDED_KEYTOOL! Stopping build."
                     exit 1
                     fi
                     chmod +x "$EMBEDDED_KEYTOOL"
                     "$EMBEDDED_KEYTOOL" -genkey -v \
                       -keystore /opt/IronFox/ironfox-android-keystore.jks \
                         -alias ironfox \
                           -keyalg RSA \
                             -keysize 2048 \
                               -validity 10000 \
                                 -storepass my_ci_password_123 \
                                   -keypass my_ci_password_123 \
                                     -dname "CN=IronFoxCI, OU=Dev, O=IronFox, L=Local, S=State, C=US"
                                       
                                       if [ ! -f "/opt/IronFox/ironfox-android-keystore.jks" ]; then
                                         echo "ERROR: Keystore file was not created at /opt/IronFox/! Stopping build."
                                           exit 1
                                           fi
                                           echo "SUCCESS: Keystore generated and verified using embedded JDK!"

                                           echo 'Starting Fenix prebuild...'
                                           yes | ./scripts/prebuild.sh

                                           echo 'Starting Official Fenix build...'
                                           yes | ./scripts/build.sh "$BUILD_ARCH"