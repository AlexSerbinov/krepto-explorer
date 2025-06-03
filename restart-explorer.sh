#!/bin/bash

# Krepto Explorer Restart Script
# This script safely restarts the Krepto Explorer service

EXPLORER_DIR="/opt/krepto-explorer"
LOG_FILE="/var/log/krepto-explorer.log"
PID_FILE="/tmp/krepto-explorer.pid"

echo "=== Krepto Explorer Restart Script ==="
echo "$(date): Starting restart process..."

# Change to explorer directory
cd "$EXPLORER_DIR" || {
    echo "ERROR: Cannot change to $EXPLORER_DIR"
    exit 1
}

# Stop existing processes
echo "$(date): Stopping existing Explorer processes..."
pkill -f "node.*bin/www" && sleep 2

# Kill any remaining processes if needed
if pgrep -f "node.*bin/www" > /dev/null; then
    echo "$(date): Force killing remaining processes..."
    pkill -9 -f "node.*bin/www"
    sleep 1
fi

# Clear old log if it's too large (>100MB)
if [[ -f "$LOG_FILE" && $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null) -gt 104857600 ]]; then
    echo "$(date): Rotating large log file..."
    mv "$LOG_FILE" "${LOG_FILE}.old"
fi

# Start Explorer
echo "$(date): Starting Krepto Explorer..."
nohup node ./bin/www > "$LOG_FILE" 2>&1 &
EXPLORER_PID=$!

# Save PID
echo $EXPLORER_PID > "$PID_FILE"

# Wait a moment and check if it started successfully
sleep 3

if ps -p $EXPLORER_PID > /dev/null; then
    echo "$(date): ✅ Explorer started successfully (PID: $EXPLORER_PID)"
    
    # Test if service responds
    if curl -s -I http://localhost:12348/ | grep -q "HTTP/1.1 200"; then
        echo "$(date): ✅ Service is responding on port 12348"
        echo "$(date): 🎉 Restart completed successfully!"
    else
        echo "$(date): ⚠️  Service started but not responding on port 12348"
        echo "$(date): Check logs: tail -f $LOG_FILE"
    fi
else
    echo "$(date): ❌ Failed to start Explorer"
    echo "$(date): Check logs: tail -f $LOG_FILE"
    exit 1
fi

echo "=== Restart completed at $(date) ===" 