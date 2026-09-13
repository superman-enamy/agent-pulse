#!/data/data/com.termux/files/usr/bin/bash
DIR="/data/data/com.termux/files/home/.agent-pulse"
PID_FILE="$DIR/server.pid"

PID=$(pgrep -f "python3.*agent-pulse/server.py" | head -n 1)

if [ -n "$PID" ] || curl -s -m 1 http://127.0.0.1:8899/api/status >/dev/null 2>&1; then
    echo "🟢 Agent-Pulse is RUNNING (PID: ${PID:-active})"
    echo "🌐 Dashboard: http://localhost:8899"
    exit 0
fi
echo "🔴 Agent-Pulse is STOPPED."
exit 1
