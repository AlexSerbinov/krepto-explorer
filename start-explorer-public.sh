#!/bin/bash

# Krepto Explorer Startup Script (Public Access)
# Запускає Explorer без аутентифікації
# ОБМЕЖЕННЯ: RPC браузер та RPC термінал НЕ будуть доступні

EXPLORER_DIR="/opt/krepto-explorer"
LOG_FILE="/var/log/krepto-explorer.log"

echo "=== Krepto Explorer Startup (Public Mode) ==="
echo "$(date): Setting up environment variables..."

# Налаштування без аутентифікації
export KREPTOEXP_HOST=0.0.0.0
export KREPTOEXP_PORT=12348
export KREPTOEXP_ADDRESS_API=electrum
export KREPTOEXP_ELECTRUM_SERVERS=tcp://127.0.0.1:50001
export DEBUG=kreptoexp:app,kreptoexp:error

echo "$(date): Environment configured"
echo "  - Host: $KREPTOEXP_HOST"
echo "  - Port: $KREPTOEXP_PORT" 
echo "  - Electrum: $KREPTOEXP_ELECTRUM_SERVERS"

echo "$(date): ⚠️  УВАГА: RPC браузер та RPC термінал НЕ будуть доступні"
echo "$(date): Для використання RPC функцій запустіть start-explorer-with-auth.sh"

# Change to explorer directory
cd "$EXPLORER_DIR" || {
    echo "ERROR: Cannot change to $EXPLORER_DIR"
    exit 1
}

echo "$(date): Starting Krepto Explorer (Public Mode)..."
nohup node ./bin/www > "$LOG_FILE" 2>&1 &
EXPLORER_PID=$!

echo "$(date): Explorer started with PID: $EXPLORER_PID"
echo "$(date): 🌐 Access at: https://krepto.com/explorer/"
echo "$(date): 🔓 Відкритий доступ (без аутентифікації)"
echo "$(date): ❌ RPC браузер: НЕДОСТУПНИЙ"
echo "$(date): ❌ RPC термінал: НЕДОСТУПНИЙ"

sleep 3

if ps -p $EXPLORER_PID > /dev/null; then
    echo "$(date): ✅ Process is running"
    echo "$(date): 📋 Сайт доступний без пароля"
else
    echo "$(date): ❌ Process failed to start"
    echo "$(date): Check logs: tail -f $LOG_FILE"
fi 