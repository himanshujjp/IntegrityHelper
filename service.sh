#!/system/bin/sh
# service.sh - KernelSU WebUI Module Service

MODDIR=${0%/*}
WEBROOT="$MODDIR/webroot"

# Create necessary directories
mkdir -p /data/adb/IntegrityHelper
mkdir -p /data/local/tmp/modules

# Set permissions for CGI scripts
chmod +x "$WEBROOT"/*.sh
chmod +x "$WEBROOT/cgi-bin"/*.sh

# Kill any existing httpd processes on our port
pkill -f "httpd.*127.0.0.1:8585" 2>/dev/null || true

# Wait for cleanup
sleep 1

# Start busybox httpd
httpd -p 127.0.0.1:8585 -c "$WEBROOT/httpd.conf" -h "$WEBROOT" -f &

# Wait for server to start
sleep 2

# Verify server is running
if pgrep -f "httpd.*127.0.0.1:8585" > /dev/null; then
    echo "$(date): IntegrityHelper WebUI started on port 8585" >> /data/adb/IntegrityHelper/service.log

    # Show notification if Android UI is available
    if command -v am > /dev/null; then
        am broadcast -a android.intent.action.MAIN \
            -e message "Integrity Helper WebUI running on http://127.0.0.1:8585" \
            -e title "Integrity Helper" \
            --ez ongoing true \
            --ei notification_id 12345 > /dev/null 2>&1 &
    fi
else
    echo "$(date): ERROR: Failed to start IntegrityHelper WebUI" >> /data/adb/IntegrityHelper/service.log
fi