#!/data/data/com.termux/files/usr/bin/bash
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

DIR="/data/data/com.termux/files/home/.agent-pulse"
PID_FILE="$DIR/server.pid"
LOG_FILE="$DIR/logs/server.log"

mkdir -p "$DIR/logs"

if curl -s -m 1 http://127.0.0.1:8899/api/status >/dev/null 2>&1; then
    echo "🟢 Agent-Pulse is already running at http://localhost:8899"
    exit 0
fi

setsid -f /data/data/com.termux/files/usr/bin/python3 "$DIR/server.py" > "$LOG_FILE" 2>&1

sleep 1
if curl -s -m 2 http://127.0.0.1:8899/api/status >/dev/null 2>&1; then
    PID=$(pgrep -f "python3.*agent-pulse/server.py" | head -n 1)
    [ -n "$PID" ] && echo "$PID" > "$PID_FILE"
    echo "✅ Agent-Pulse Web Portal started successfully!"
    echo "🌐 URL: http://localhost:8899"
else
    echo "❌ Failed to start Agent-Pulse. Check logs at $LOG_FILE"
    exit 1
fi
