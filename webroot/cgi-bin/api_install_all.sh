#!/system/bin/sh
# api_install_all.sh - CGI API endpoint for installing all modules

echo "Content-Type: text/plain"
echo "Access-Control-Allow-Origin: *"
echo "Access-Control-Allow-Headers: *"
echo "Access-Control-Allow-Methods: GET, POST, OPTIONS"
echo ""

# Determine module directory based on root type
if [ -d "/data/adb/modules" ]; then
    MODULE_DIR="/data/adb/modules"
elif [ -d "/data/adb/ksu/modules" ]; then
    MODULE_DIR="/data/adb/ksu/modules"
else
    echo "Error: No module directory found"
    exit 1
fi

# Function to download and install a module
download_and_install() {
    NAME="$1"
    REPO="$2"

    echo "Processing $NAME..."

    # Extract owner/repo
    OWNER_REPO=$(echo "$REPO" | sed 's|https://github.com/\([^/]*\)/\([^/]*\)|\1/\2|')

    # Fetch latest release
    API_URL="https://api.github.com/repos/$OWNER_REPO/releases/latest"
    API_RESPONSE=$(busybox wget -q -O - --header="User-Agent: IntegrityHelper/1.0" "$API_URL" 2>/dev/null)
    ZIP_URL=$(echo "$API_RESPONSE" | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    TAG_NAME=$(echo "$API_RESPONSE" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

    if [ -z "$ZIP_URL" ]; then
        echo "Error: No zip asset found for $NAME"
        return
    fi

    # Download
    mkdir -p /data/local/tmp/modules
    if busybox wget -q -O "/data/local/tmp/modules/${NAME}.zip" --header="User-Agent: IntegrityHelper/1.0" "$ZIP_URL" 2>/dev/null; then
        if [ ! -f "/data/local/tmp/modules/${NAME}.zip" ]; then
            echo "Error: Download failed for $NAME - file not found"
            return
        fi
    else
        echo "Error: Download failed for $NAME - wget error"
        return
    fi

    # Now install
    ZIP_FILE="/data/local/tmp/modules/${NAME}.zip"

    # Read version from ZIP file (before flashing)
    VERSION=""
    # Try to extract temporarily to read version
    TEMP_EXTRACT="/data/local/tmp/${NAME}_temp"
    mkdir -p "$TEMP_EXTRACT"
    if busybox unzip -q -o "$ZIP_FILE" -d "$TEMP_EXTRACT" 2>/dev/null; then
        if [ -f "$TEMP_EXTRACT/module.prop" ]; then
            VERSION=$(grep '^version=' "$TEMP_EXTRACT/module.prop" | cut -d'=' -f2 | tr -d '\r' | sed 's/^v//')
        fi
        rm -rf "$TEMP_EXTRACT"
    fi

    # Fallback to tag name if version not found
    if [ -z "$VERSION" ] && [ -n "$TAG_NAME" ]; then
        VERSION=$(echo "$TAG_NAME" | sed 's/^v//')
    elif [ -z "$VERSION" ]; then
        VERSION="installed"
    fi

    # Now install/flash the module directly through root manager
    echo "Flashing $NAME through root manager..."

    FLASH_SUCCESS=false

    # Try KernelSU first
    if command -v ksud >/dev/null 2>&1; then
        echo "Using KernelSU to flash $NAME"
        if ksud module install "$ZIP_FILE"; then
            echo "KernelSU flashing successful for $NAME"
            FLASH_SUCCESS=true
        fi
    fi

    # Try Magisk/APatch if KernelSU failed or not available
    if [ "$FLASH_SUCCESS" = false ] && command -v magisk >/dev/null 2>&1; then
        echo "Using Magisk/APatch to flash $NAME"
        if magisk --install-module "$ZIP_FILE" 2>/dev/null; then
            echo "Magisk/APatch flashing successful for $NAME"
            FLASH_SUCCESS=true
        fi
    fi

    # Try APatch if Magisk failed
    if [ "$FLASH_SUCCESS" = false ] && command -v apd >/dev/null 2>&1; then
        echo "Using APatch to flash $NAME"
        if apd module install "$ZIP_FILE" 2>/dev/null; then
            echo "APatch flashing successful for $NAME"
            FLASH_SUCCESS=true
        fi
    fi

    # Clean up the ZIP file
    rm -f "$ZIP_FILE"

    if [ "$FLASH_SUCCESS" = true ]; then
        # Update state after successful flashing
        STATE_FILE="/data/adb/IntegrityHelper/state.json"
        if [ -n "$VERSION" ]; then
            # Create or update state file
            if [ -f "$STATE_FILE" ]; then
                # Use sed to update or add the module
                if grep -q "\"$NAME\":" "$STATE_FILE"; then
                    sed -i "s/\"$NAME\":\"[^\"]*\"/\"$NAME\":\"$VERSION\"/" "$STATE_FILE"
                else
                    # Add new entry
                    sed -i "s/}$/,\"$NAME\":\"$VERSION\"}/" "$STATE_FILE"
                fi
            else
                echo "{\"$NAME\":\"$VERSION\"}" > "$STATE_FILE"
            fi
        fi

        echo "Successfully flashed $NAME (version: $VERSION)"
        echo "✅ Module has been flashed and is ready to use - reboot may be required for changes to take effect"
    else
        echo "❌ Flashing failed for $NAME"
        echo "⚠️  Could not flash $NAME through root manager"
    fi
}

# List of modules to install (name and repo pairs)
download_and_install "PlayIntegrityFork" "https://github.com/osm0sis/PlayIntegrityFork"
download_and_install "TrickyStore" "https://github.com/5ec1cff/TrickyStore"
download_and_install "PlayStoreSelfUpdateBlocker" "https://github.com/himanshujjp/PlayStoreSelfUpdateBlocker"
download_and_install "yurikey" "https://github.com/YurikeyDev/yurikey"
download_and_install "ZygiskNext" "https://github.com/Dr-TSNG/ZygiskNext"

echo "All installations completed"