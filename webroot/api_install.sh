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

# Parse form data
NAME=$(echo "$POST_DATA" | sed 's/.*name=\([^&]*\).*/\1/' | sed 's/%20/ /g' | sed 's/%22/"/g' | sed 's/%3A/:/g' | sed 's/%2F/\//g')

if [ -z "$NAME" ]; then
    echo "Error: Invalid input - name missing"
    exit 1
fi

ZIP_FILE="/data/local/tmp/modules/${NAME}.zip"
if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: Zip file not found for $NAME"
    exit 1
fi

# Determine module directory based on root type
if [ -d "/data/adb/modules" ]; then
    MODULE_DIR="/data/adb/modules"
elif [ -d "/data/adb/ksu/modules" ]; then
    MODULE_DIR="/data/adb/ksu/modules"
else
    echo "Error: No module directory found"
    exit 1
fi

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