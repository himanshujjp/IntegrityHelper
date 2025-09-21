#!/bin/sh
# test_api.sh - Manual test for API server

echo "Testing API server on port 8081..."

# Test if server is running
if pgrep -f "simple_http_server.sh" > /dev/null; then
    echo "✓ API server process is running"
else
    echo "✗ API server process is NOT running"
    exit 1
fi

# Test if port is listening
if netstat -tln 2>/dev/null | grep -q ":8081 "; then
    echo "✓ Port 8081 is listening"
else
    echo "✗ Port 8081 is NOT listening"
fi

# Test API endpoint
echo "Testing /api/test endpoint..."
response=$(busybox wget -q -O - --timeout=5 http://127.0.0.1:8081/api/test 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$response" ]; then
    echo "✓ API test successful:"
    echo "$response"
else
    echo "✗ API test failed"
    echo "Response: $response"
fi

# Check logs
echo ""
echo "Recent server logs:"
tail -10 /data/adb/IntegrityHelper/server.log 2>/dev/null || echo "No server logs found"