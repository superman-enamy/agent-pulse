#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=============================================="
echo "      🚀 Agent-Pulse Installer for Termux     "
echo "=============================================="
echo ""

# 1. Dependency checks
echo "🔍 Checking dependencies..."
MISSING=""
for cmd in python3 jq termux-notification termux-tts-speak termux-toast; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING="$MISSING $cmd"
    fi
done

if [ -n "$MISSING" ]; then
    echo "⚠️  Missing required packages:$MISSING"
    echo "📦 Installing prerequisites via pkg..."
    pkg update -y
    pkg install -y python jq termux-api
fi

# 2. Target installation directory
TARGET_DIR="$HOME/.agent-pulse"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$SCRIPT_DIR" != "$TARGET_DIR" ]; then
    echo "📁 Copying files to $TARGET_DIR..."
    mkdir -p "$TARGET_DIR"
    cp -r "$SCRIPT_DIR"/* "$TARGET_DIR"/
fi

# 3. Create default config if not exists
if [ ! -f "$TARGET_DIR/config.json" ]; then
    echo "⚙️  Initializing default config.json..."
    cp "$TARGET_DIR/config.default.json" "$TARGET_DIR/config.json"
fi

# 4. Make scripts executable and fix shebangs
echo "🔧 Setting permissions and fixing shebangs..."
chmod +x "$TARGET_DIR"/*.sh "$TARGET_DIR"/server.py 2>/dev/null || true
if command -v termux-fix-shebang >/dev/null 2>&1; then
    termux-fix-shebang "$TARGET_DIR"/*.sh "$TARGET_DIR"/server.py 2>/dev/null || true
fi

# 5. Symlink CLI command to $PREFIX/bin
echo "🔗 Setting up 'agent-pulse' CLI shortcut..."
CLI_BIN="$PREFIX/bin/agent-pulse"
cat << 'CLIEOC' > "$CLI_BIN"
#!/data/data/com.termux/files/usr/bin/bash
DIR="$HOME/.agent-pulse"
case "$1" in
    start) "$DIR/start.sh" ;;
    stop) "$DIR/stop.sh" ;;
    restart) "$DIR/stop.sh"; sleep 1; "$DIR/start.sh" ;;
    status) "$DIR/status.sh" ;;
    open|web|dashboard) termux-open-url "http://localhost:8899" ;;
    *)
        echo "Agent-Pulse CLI - Termux Automation Hub"
        echo "Usage: agent-pulse {start|stop|restart|status|open}"
        echo ""
        "$DIR/status.sh"
        ;;
esac
CLIEOC
chmod +x "$CLI_BIN"
if command -v termux-fix-shebang >/dev/null 2>&1; then
    termux-fix-shebang "$CLI_BIN"
fi

# 6. Configure Antigravity (AGY) Hooks if installed
AGY_CONFIG_DIR="$HOME/.gemini/config"
if [ -d "$AGY_CONFIG_DIR" ] || command -v agy >/dev/null 2>&1; then
    echo "🤖 Configuring Google Antigravity (AGY) hooks..."
    mkdir -p "$AGY_CONFIG_DIR"
    cat << 'AGYEOC' > "$AGY_CONFIG_DIR/hooks.json"
{
  "agent-pulse-notifier": {
    "PreToolUse": [
      {
        "matcher": "ask_question",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.agent-pulse/notify.sh pre_tool",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "$HOME/.agent-pulse/notify.sh stop",
        "timeout": 10
      }
    ]
  }
}
AGYEOC
    echo "   ✅ Antigravity hooks configured successfully."
fi

# 7. Configure Claude Code CLI Hooks if installed
CLAUDE_DIR="$HOME/.claude"
if [ -d "$CLAUDE_DIR" ] && [ -f "$CLAUDE_DIR/settings.json" ]; then
    echo "🤖 Configuring Claude Code hooks..."
    tmp_json="$CLAUDE_DIR/settings.tmp.json"
    jq '.hooks.Notification = [{"matcher": "permission_prompt|idle_prompt", "hooks": [{"type": "command", "command": "$HOME/.agent-pulse/notify.sh claude", "timeout": 10}]}]' "$CLAUDE_DIR/settings.json" > "$tmp_json" 2>/dev/null && mv "$tmp_json" "$CLAUDE_DIR/settings.json" || true
    echo "   ✅ Claude Code hooks configured successfully."
fi

# 8. Install Agent Skill for AI Coding Assistants
echo "🧠 Installing Agent-Pulse Skill..."
mkdir -p "$HOME/.agents/skills/agent-pulse"
cp -f "$TARGET_DIR/skills/agent-pulse/SKILL.md" "$HOME/.agents/skills/agent-pulse/" 2>/dev/null || true
echo "   ✅ Agent skill installed at ~/.agents/skills/agent-pulse/SKILL.md"

# 9. Start Service
echo "🚀 Starting Agent-Pulse Dashboard..."
"$TARGET_DIR/start.sh"

echo ""
echo "=============================================="
echo "🎉 Agent-Pulse installation complete!"
echo "🌐 Web Dashboard: http://localhost:8899"
echo "👉 CLI Shortcut: agent-pulse open"
echo "=============================================="
