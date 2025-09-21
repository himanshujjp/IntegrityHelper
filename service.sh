#!/system/bin/sh
# service.sh - Runs persistent servers to keep the web UI servers running

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

# Make CGI scripts executable
chmod +x "$UI_DIR/api_*.sh"

# Copy httpd.conf to webroot
cp "$SCRIPTS_DIR/httpd.conf" "$UI_DIR/"

# Kill any existing servers
pkill -f "httpd.*127.0.0.1:8585" 2>/dev/null || true

# Wait a moment
sleep 1

# Start busybox httpd for static web UI (port 8585)
httpd -p 127.0.0.1:8585 -c "$MODDIR/webroot/httpd.conf" -h "$MODDIR/webroot" -f

# Wait for servers to start
sleep 3

# Verify servers are running
if pgrep -f "httpd.*127.0.0.1:8585" > /dev/null; then
    echo "$(date): HTTPD server started successfully on port 8585" >> /data/adb/IntegrityHelper/service.log
else
    echo "$(date): ERROR: HTTPD server failed to start" >> /data/adb/IntegrityHelper/service.log
fi

# Show notification that UI is ready
if command -v am > /dev/null && pgrep -f "httpd.*127.0.0.1:8585" > /dev/null; then
    # Show notification
    am broadcast -a android.intent.action.MAIN -e message "Integrity Helper UI is running on http://127.0.0.1:8585" -e title "Integrity Helper" --ez ongoing true --ei notification_id 12345 > /dev/null 2>&1 &
fi

# Log that service started
echo "$(date): IntegrityHelper service started on $ROOT_TYPE" >> /data/adb/IntegrityHelper/service.log