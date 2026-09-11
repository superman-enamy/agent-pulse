---
name: agent-pulse
description: Automatically install, configure, verify, and manage Agent-Pulse in Android Termux. Provides smart background notifications, Voice TTS alerts, Termux auto-open, multi-session tracking, and a local web dashboard for Google Antigravity and Claude Code. Use whenever the user mentions Agent-Pulse, Termux notifications, Termux voice alerts, or background agent monitoring in Termux.
---

# Agent-Pulse Skill: Termux Automation & Notification Hub

This skill teaches agents how to set up, configure, diagnose, and operate **Agent-Pulse** on Android Termux for **Google Antigravity (`agy`)** and **Anthropic Claude Code (`claude`)**.

---

## When to Activate This Skill

- User wants to install or set up notifications/automation for Antigravity or Claude CLI in Termux.
- User wants spoken voice alerts (TTS), hardware vibration, or LED notifications when tasks finish or need permission.
- User wants Termux to auto-open when an agent requests input.
- User needs to start, stop, restart, or check the status of the local Agent-Pulse Web Dashboard.
- User wants to customize notification titles, voice speed, speech pitch, or terminal banners.

---

## 1. Automated Installation & Setup Workflow

Run these steps when the user asks to install or configure Agent-Pulse:

### Step 1: Ensure Prerequisites
Verify core packages are available:
```bash
pkg install -y python jq termux-api
```
*Note:* The user must also have the **Termux:API** Android app installed from F-Droid.

### Step 2: Clone & Run Installer
```bash
if [ ! -d "$HOME/.agent-pulse" ]; then
    git clone https://github.com/superman-enamy/agent-pulse.git "$HOME/.agent-pulse"
fi
cd "$HOME/.agent-pulse" && ./install.sh
```

### Step 3: Verify CLI Hooks
The installer automatically sets up hooks:
- **Antigravity**: Check that `~/.gemini/config/hooks.json` maps `PreToolUse` and `Stop` to `$HOME/.agent-pulse/notify.sh`.
- **Claude Code**: Check that `~/.claude/settings.json` has `hooks.Notification` pointing to `$HOME/.agent-pulse/notify.sh claude`.

### Step 4: Verify Service Health
Run the status check:
```bash
agent-pulse status
```
Expected output: `🟢 Agent-Pulse is RUNNING` at `http://localhost:8899`.

---

## 2. Managing the Web Portal & Daemon

The `agent-pulse` command manages the background server:

```bash
agent-pulse status      # Check if running and get PID
agent-pulse open        # Launch dashboard in device browser (http://localhost:8899)
agent-pulse restart     # Restart background server
agent-pulse stop        # Stop background daemon
agent-pulse start       # Start daemon
```

---

## 3. Configuration via CLI (Headless)

If the user prefers terminal configuration over the web portal, edit `~/.agent-pulse/config.json`:

- **Auto-Open on Permission**:
  ```bash
  jq '.automation.auto_open_on_permission = true' ~/.agent-pulse/config.json > tmp && mv tmp ~/.agent-pulse/config.json
  ```
- **Toggle Voice TTS**:
  ```bash
  jq '.tts.enabled = true' ~/.agent-pulse/config.json > tmp && mv tmp ~/.agent-pulse/config.json
  ```
- **Adjust Speech Rate (e.g. 1.2x)**:
  ```bash
  jq '.tts.rate = 1.2' ~/.agent-pulse/config.json > tmp && mv tmp ~/.agent-pulse/config.json
  ```
- **In-Terminal Screen Badges (ON/OFF)**:
  ```bash
  jq '.notification.terminal_banner = false' ~/.agent-pulse/config.json > tmp && mv tmp ~/.agent-pulse/config.json
  ```
*Changes apply immediately to subsequent events without restarting the agent session.*

---

## 4. Live Verification Suite

Test alerts without waiting for an actual long task:

- **Test Push Notification**:
  ```bash
  ~/.agent-pulse/notify.sh test_notify "Test Title" "Testing Agent-Pulse"
  ```
- **Test Voice Synthesis**:
  ```bash
  ~/.agent-pulse/notify.sh test_voice "Agent Pulse voice is functioning correctly."
  ```
- **Test Foreground Activity Launcher**:
  ```bash
  ~/.agent-pulse/open.sh
  ```

---

## 5. Troubleshooting & Best Practices

1. **Termux doesn't pop up from background**:
   - In Android Settings -> Apps -> **Termux** AND **Termux:API**, grant **"Display over other apps"** (Appear on top).
2. **No voice spoken**:
   - Verify device volume and check TTS engine:
     ```bash
     termux-tts-engines
     ```
3. **Address already in use on port 8899**:
   - Run `agent-pulse restart` to cleanly release and rebind port 8899.
