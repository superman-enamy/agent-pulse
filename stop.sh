#!/data/data/com.termux/files/usr/bin/bash
DIR="/data/data/com.termux/files/home/.agent-pulse"
PID_FILE="$DIR/server.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        rm -f "$PID_FILE"
        echo "🛑 Agent-Pulse service stopped."
        exit 0
    fi
    rm -f "$PID_FILE"
fi

# Fallback: kill by pattern
pkill -f "python3.*agent-pulse/server.py" 2>/dev/null
termux-wake-unlock 2>/dev/null || true
echo "Agent-Pulse is stopped."
