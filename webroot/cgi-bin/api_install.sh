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

# Determine module directory based on root type
if [ -d "/data/adb/modules" ]; then
    MODULE_DIR="/data/adb/modules"
    echo "DEBUG: Using Magisk/APatch module directory: $MODULE_DIR"
elif [ -d "/data/adb/ksu/modules" ]; then
    MODULE_DIR="/data/adb/ksu/modules"
    echo "DEBUG: Using KernelSU module directory: $MODULE_DIR"
else
    echo "Error: No module directory found"
    exit 1
fi

# Check if module is already installed
if [ -d "$MODULE_DIR/$NAME" ]; then
    echo "DEBUG: Module $NAME already exists, removing old version"
    rm -rf "$MODULE_DIR/$NAME"
fi

echo "DEBUG: Extracting ZIP to $MODULE_DIR/$NAME"

# Extract zip
mkdir -p "$MODULE_DIR/$NAME"
if busybox unzip -q -o "$ZIP_FILE" -d "$MODULE_DIR/$NAME" 2>/dev/null; then
    echo "DEBUG: ZIP extraction successful"

    # Set permissions
    chmod -R 755 "$MODULE_DIR/$NAME"
    find "$MODULE_DIR/$NAME" -name "*.sh" -exec chmod 755 {} \;

    # Read version from module.prop
    VERSION=""
    if [ -f "$MODULE_DIR/$NAME/module.prop" ]; then
        VERSION=$(grep '^version=' "$MODULE_DIR/$NAME/module.prop" | cut -d'=' -f2 | tr -d '\r' | sed 's/^v//' | sed 's/^ *//;s/ *$//')
        echo "DEBUG: Found version in module.prop: '$VERSION'"
    fi

    # Fallback to tag name if version not found
    if [ -z "$VERSION" ]; then
        # Try to get version from ZIP filename or other sources
        VERSION="installed"
        echo "DEBUG: No version found, using 'installed'"
    fi

    # Update state
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

    # Clean up
    rm -f "$ZIP_FILE"
    echo "DEBUG: Cleaned up ZIP file"

    echo "Successfully installed $NAME (version: $VERSION)"
else
    echo "Error: Failed to extract ZIP file for $NAME"
    exit 1
fi