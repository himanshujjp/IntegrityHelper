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

# List of modules to install (name and repo pairs)
download_and_install "PlayIntegrityFork" "https://github.com/osm0sis/PlayIntegrityFork"
download_and_install "TrickyStore" "https://github.com/5ec1cff/TrickyStore"
download_and_install "PlayStoreSelfUpdateBlocker" "https://github.com/himanshujjp/PlayStoreSelfUpdateBlocker"
download_and_install "yurikey" "https://github.com/YurikeyDev/yurikey"
download_and_install "ZygiskNext" "https://github.com/Dr-TSNG/ZygiskNext"

echo "All installations completed"

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

    # Extract zip
    mkdir -p "$MODULE_DIR/$NAME"
    busybox unzip -q -o "$ZIP_FILE" -d "$MODULE_DIR/$NAME" 2>/dev/null

    if [ $? -eq 0 ]; then
        # Set permissions
        chmod -R 755 "$MODULE_DIR/$NAME"
        find "$MODULE_DIR/$NAME" -name "*.sh" -exec chmod 755 {} \;

        # Read version from module.prop
        VERSION=""
        if [ -f "$MODULE_DIR/$NAME/module.prop" ]; then
            VERSION=$(grep '^version=' "$MODULE_DIR/$NAME/module.prop" | cut -d'=' -f2 | tr -d '\r' | sed 's/^v//')
        fi
        
        # Fallback to tag name if version not found
        if [ -z "$VERSION" ] && [ -n "$TAG_NAME" ]; then
            VERSION=$(echo "$TAG_NAME" | sed 's/^v//')
        elif [ -z "$VERSION" ]; then
            VERSION="installed"
        fi

        # Update state
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

        # Clean up
        rm -f "$ZIP_FILE"

        echo "Installed $NAME successfully"
    else
        echo "Error: Installation failed for $NAME"
    fi
}