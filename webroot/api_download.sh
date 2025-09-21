#!/system/bin/sh
# api_download.sh - CGI API endpoint for downloading modules

echo "Content-Type: text/plain"
echo "Access-Control-Allow-Origin: *"
echo "Access-Control-Allow-Headers: *"
echo "Access-Control-Allow-Methods: GET, POST, OPTIONS"
echo ""

# Read POST data
if [ "$REQUEST_METHOD" = "POST" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
    POST_DATA=$(dd bs=1 count="$CONTENT_LENGTH" 2>/dev/null)
    echo "DEBUG: Read $CONTENT_LENGTH bytes of POST data"
else
    echo "Error: Invalid request method or no data"
    exit 1
fi

# Parse form data
NAME=$(echo "$POST_DATA" | sed 's/.*name=\([^&]*\).*/\1/' | sed 's/%20/ /g' | sed 's/%22/"/g' | sed 's/%3A/:/g' | sed 's/%2F/\//g')
REPO=$(echo "$POST_DATA" | sed 's/.*repo=\([^&]*\).*/\1/' | sed 's/%20/ /g' | sed 's/%22/"/g' | sed 's/%3A/:/g' | sed 's/%2F/\//g')

if [ -z "$NAME" ] || [ -z "$REPO" ]; then
    echo "Error: Invalid input - name or repo missing"
    exit 1
fi

# Extract owner/repo
OWNER_REPO=$(echo "$REPO" | sed 's|https://github.com/\([^/]*\)/\([^/]*\)|\1/\2|')

# Fetch latest release
API_URL="https://api.github.com/repos/$OWNER_REPO/releases/latest"
echo "DEBUG: Fetching from $API_URL"
if command -v busybox >/dev/null 2>&1; then
    echo "DEBUG: busybox found"
    API_RESPONSE=$(busybox wget -q -O - --header="User-Agent: IntegrityHelper/1.0" "$API_URL" 2>/dev/null)
    echo "DEBUG: API response length: ${#API_RESPONSE}"
else
    echo "DEBUG: busybox not found, trying wget"
    API_RESPONSE=$(wget -q -O - --header="User-Agent: IntegrityHelper/1.0" "$API_URL" 2>/dev/null)
    echo "DEBUG: API response length: ${#API_RESPONSE}"
fi
echo "DEBUG: API response preview: $(echo "$API_RESPONSE" | head -c 200)"
ZIP_URL=$(echo "$API_RESPONSE" | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

echo "DEBUG: ZIP_URL='$ZIP_URL'"
echo "DEBUG: ZIP_URL length: ${#ZIP_URL}"

if [ -z "$ZIP_URL" ]; then
    echo "Error: No zip asset found for $NAME"
    exit 1
fi

# Download
mkdir -p /data/local/tmp/modules
echo "DEBUG: Downloading to /data/local/tmp/modules/${NAME}.zip"
if command -v busybox >/dev/null 2>&1; then
    echo "DEBUG: Using busybox wget for download"
    if busybox wget -q -O "/data/local/tmp/modules/${NAME}.zip" --header="User-Agent: IntegrityHelper/1.0" "$ZIP_URL" 2>/dev/null; then
        if [ -f "/data/local/tmp/modules/${NAME}.zip" ]; then
            echo "Downloaded $NAME successfully"
        else
            echo "Error: Download failed for $NAME - file not found"
        fi
    else
        echo "Error: Download failed for $NAME - wget error"
    fi
else
    echo "DEBUG: busybox not found, trying wget"
    if wget -q -O "/data/local/tmp/modules/${NAME}.zip" --header="User-Agent: IntegrityHelper/1.0" "$ZIP_URL" 2>/dev/null; then
        if [ -f "/data/local/tmp/modules/${NAME}.zip" ]; then
            echo "Downloaded $NAME successfully"
        else
            echo "Error: Download failed for $NAME - file not found"
        fi
    else
        echo "Error: Download failed for $NAME - wget error"
    fi
fi