#!/data/data/com.termux/files/usr/bin/bash
DIR="/data/data/com.termux/files/home/.agent-pulse"
PID_FILE="$DIR/server.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "🟢 Agent-Pulse is RUNNING (PID: $PID)"
        echo "🌐 Dashboard: http://localhost:8899"
        exit 0
    fi
fi
echo "🔴 Agent-Pulse is STOPPED."
exit 1
