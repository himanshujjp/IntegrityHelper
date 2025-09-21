#!/system/bin/sh
# open_ui.sh - Script to open the Integrity Helper web UI

# Check if httpd is running
if pgrep -f "busybox httpd" > /dev/null; then
    # Show toast message
    am broadcast -a android.intent.action.MAIN -e message "Opening Integrity Helper UI..." > /dev/null 2>&1

    # Open browser to localhost:8585
    am start -a android.intent.action.VIEW -d "http://127.0.0.1:8585" > /dev/null 2>&1

    # Show success toast
    sleep 1
    am broadcast -a android.intent.action.MAIN -e message "Integrity Helper UI opened!" > /dev/null 2>&1

    echo "Opening Integrity Helper UI..."
else
    # Show error toast
    am broadcast -a android.intent.action.MAIN -e message "Web UI is not running. Please reboot." > /dev/null 2>&1
    echo "Web UI is not running. Please reboot or check module status."
fi