#!/system/bin/sh
# api_install.sh - CGI API endpoint for installing modules

echo "Content-Type: text/plain"
echo "Access-Control-Allow-Origin: *"
echo "Access-Control-Allow-Headers: *"
echo "Access-Control-Allow-Methods: GET, POST, OPTIONS"
echo ""

# Read POST data
if [ "$REQUEST_METHOD" = "POST" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
    POST_DATA=$(dd bs=1 count="$CONTENT_LENGTH" 2>/dev/null)
else
    echo "Error: Invalid request method or no data"
    exit 1
fi

# Parse form data - improved parsing
NAME=$(echo "$POST_DATA" | sed -n 's/.*name=\([^&]*\).*/\1/p' | sed 's/%20/ /g' | sed 's/%22/"/g' | sed 's/%3A/:/g' | sed 's/%2F/\//g' | sed 's/%26/\&/g')

if [ -z "$NAME" ]; then
    echo "Error: Invalid input - name missing"
    echo "DEBUG: POST_DATA='$POST_DATA'"
    exit 1
fi

echo "DEBUG: Installing module: $NAME"

ZIP_FILE="/data/local/tmp/modules/${NAME}.zip"
if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: Zip file not found for $NAME at $ZIP_FILE"
    echo "Please download the module first using the Download button"
    exit 1
fi

echo "DEBUG: Found ZIP file: $ZIP_FILE"

# Determine module directory based on root type (for version detection only)
if [ -d "/data/adb/modules" ]; then
    MODULE_DIR="/data/adb/modules"
    echo "DEBUG: Detected Magisk/APatch root manager"
elif [ -d "/data/adb/ksu/modules" ]; then
    MODULE_DIR="/data/adb/ksu/modules"
    echo "DEBUG: Detected KernelSU root manager"
else
    echo "Error: No module directory found - cannot determine root manager"
    exit 1
fi

# Read version from ZIP file (before flashing)
VERSION=""
# Try to extract temporarily to read version
TEMP_EXTRACT="/data/local/tmp/${NAME}_temp"
mkdir -p "$TEMP_EXTRACT"
if busybox unzip -q -o "$ZIP_FILE" -d "$TEMP_EXTRACT" 2>/dev/null; then
    if [ -f "$TEMP_EXTRACT/module.prop" ]; then
        VERSION=$(grep '^version=' "$TEMP_EXTRACT/module.prop" | cut -d'=' -f2 | tr -d '\r' | sed 's/^v//' | sed 's/^ *//;s/ *$//')
        echo "DEBUG: Found version in module.prop: '$VERSION'"
    fi
    rm -rf "$TEMP_EXTRACT"
fi

# Fallback to tag name if version not found
if [ -z "$VERSION" ]; then
    VERSION="installed"
    echo "DEBUG: No version found, using 'installed'"
fi

# Now actually flash/install the module through root manager
echo "DEBUG: Flashing module through root manager..."

FLASH_SUCCESS=false

# Try KernelSU first
if command -v ksud >/dev/null 2>&1; then
    echo "DEBUG: Using KernelSU to flash module"
    if ksud module install "$ZIP_FILE"; then
        echo "DEBUG: KernelSU flashing successful"
        FLASH_SUCCESS=true
    fi
fi

# Try Magisk/APatch if KernelSU failed or not available
if [ "$FLASH_SUCCESS" = false ] && command -v magisk >/dev/null 2>&1; then
    echo "DEBUG: Using Magisk/APatch to flash module"
    if magisk --install-module "$ZIP_FILE" 2>/dev/null; then
        echo "DEBUG: Magisk/APatch flashing successful"
        FLASH_SUCCESS=true
    fi
fi

# Try APatch if Magisk failed
if [ "$FLASH_SUCCESS" = false ] && command -v apd >/dev/null 2>&1; then
    echo "DEBUG: Using APatch to flash module"
    if apd module install "$ZIP_FILE" 2>/dev/null; then
        echo "DEBUG: APatch flashing successful"
        FLASH_SUCCESS=true
    fi
fi

# Clean up the ZIP file
rm -f "$ZIP_FILE"
echo "DEBUG: Cleaned up ZIP file"

if [ "$FLASH_SUCCESS" = true ]; then
    # Update state after successful flashing
    STATE_FILE="/data/adb/IntegrityHelper/state.json"
    mkdir -p "/data/adb/IntegrityHelper"

    if [ -n "$VERSION" ]; then
        echo "DEBUG: Updating state file: $STATE_FILE"
        # Create or update state file
        if [ -f "$STATE_FILE" ]; then
            # Use sed to update or add the module
            if grep -q "\"$NAME\":" "$STATE_FILE"; then
                sed -i "s/\"$NAME\":\"[^\"]*\"/\"$NAME\":\"$VERSION\"/" "$STATE_FILE"
                echo "DEBUG: Updated existing entry for $NAME"
            else
                # Add new entry
                sed -i "s/}$/,\"$NAME\":\"$VERSION\"}/" "$STATE_FILE"
                echo "DEBUG: Added new entry for $NAME"
            fi
        else
            echo "{\"$NAME\":\"$VERSION\"}" > "$STATE_FILE"
            echo "DEBUG: Created new state file"
        fi
    fi

    echo "Successfully flashed $NAME (version: $VERSION)"
    echo "✅ Module has been flashed and is ready to use!"
    echo "🔄 A reboot may be required for changes to take effect."
else
    echo "❌ Flashing failed for $NAME"
    echo "⚠️  Could not flash through root manager"
    echo "💡 Try flashing manually through your root manager app"
    exit 1
fi