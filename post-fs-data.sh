#!/system/bin/sh
# post-fs-data.sh - Runs early in boot to prepare environment

# Detect root solution and set paths
if [ -d "/data/adb/ksu" ]; then
    ROOT_TYPE="kernelsu"
    MODULES_DIR="/data/adb/ksu/modules"
elif [ -d "/data/adb/apatch" ] || [ -d "/data/adb/ap" ]; then
    ROOT_TYPE="apatch"
    MODULES_DIR="/data/adb/modules"
else
    ROOT_TYPE="magisk"
    MODULES_DIR="/data/adb/modules"
fi

MODDIR="$MODULES_DIR/IntegrityHelper"
UI_DIR="$MODDIR/webroot"
SCRIPTS_DIR="$MODDIR/scripts"

# Ensure directories exist
mkdir -p /data/adb/IntegrityHelper
mkdir -p /data/local/tmp/modules
mkdir -p "$UI_DIR/cgi-bin"

# Copy CGI scripts to ui/cgi-bin/
cp "$SCRIPTS_DIR"/*.sh "$UI_DIR/cgi-bin/"
chmod +x "$UI_DIR/cgi-bin/"*.sh

# Copy handle_request.sh to scripts directory (same as simple_http_server.sh)
cp "$SCRIPTS_DIR/handle_request.sh" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/handle_request.sh"

# Copy httpd.conf to webroot
cp "$SCRIPTS_DIR/httpd.conf" "$UI_DIR/"

# Note: Servers will be started by service.sh
# This script just prepares the environment

# Log that preparation completed
echo "$(date): IntegrityHelper environment prepared on $ROOT_TYPE" >> /data/adb/IntegrityHelper/service.log