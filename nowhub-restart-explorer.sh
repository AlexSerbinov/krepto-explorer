#!/bin/bash

# Simple Krepto Explorer Restart Script for nowHub
# Quick restart without complex checks

echo "Restarting Krepto Explorer..."

# Kill existing processes
pkill -f "node.*bin/www" 2>/dev/null || true
sleep 2

# Change to explorer directory
cd /opt/krepto-explorer

# Start Explorer in background
nohup node ./bin/www > /var/log/krepto-explorer.log 2>&1 &

echo "Explorer restarted. PID: $!"
echo "Check status with: curl -I http://localhost:12348/" 