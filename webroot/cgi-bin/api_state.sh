#!/system/bin/sh
# api_state.sh - CGI API endpoint for getting module state

echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo "Access-Control-Allow-Headers: *"
echo "Access-Control-Allow-Methods: GET, POST, OPTIONS"
echo ""

STATE_FILE="/data/adb/IntegrityHelper/state.json"
if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
else
    echo "{}"
fi