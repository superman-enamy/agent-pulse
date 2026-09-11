#!/data/data/com.termux/files/usr/bin/bash
echo "Stopping Agent-Pulse..."
agent-pulse stop 2>/dev/null || true

echo "Removing CLI command..."
rm -f "$PREFIX/bin/agent-pulse"

echo "Uninstall completed. Configuration preserved at ~/.agent-pulse/config.json"
