<div align="center">

# ⚡ Agent-Pulse
### *Smart Automation, Notifications & Web Hub for AI Coding Agents on Android Termux*

[![Platform: Android Termux](https://img.shields.io/badge/Platform-Android%20Termux-2ea043?logo=android&logoColor=white)](https://termux.dev)
[![Python: 3.8+](https://img.shields.io/badge/Python-3.8%2B-58a6ff?logo=python&logoColor=white)](https://python.org)
[![Supported: Antigravity & Claude](https://img.shields.io/badge/Supports-Antigravity%20%7C%20Claude%20Code-d29922)](#integration)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

*Never miss when your agent is waiting for permission or finishes an autonomous coding turn in background.*

</div>

---

## 🌟 What is Agent-Pulse?

Running AI coding assistants like **Google Antigravity (`agy`)** or **Claude Code (`claude`)** inside **Android Termux** is a game-changer for mobile engineering. But when you switch apps or put your phone away, long-running agent tasks leave you wondering:
- *Has the agent finished?*
- *Is it blocked waiting for permission?*
- *Which of my 5 Termux sessions is asking for input?*

**Agent-Pulse** bridges terminal execution loops with Android hardware alerts, native notifications, voice synthesis, and a **mobile-first Web Portal** running on your local device.

---

## ✨ Features

- 🌐 **Mobile-First Web Dashboard**: Modern, glassmorphism dark-mode UI accessible at `http://localhost:8899`. Zero external `pip` dependencies—runs on Python standard library!
- ⚡ **Auto-Open Termux**: Optional automation that pops Termux straight onto your screen the moment an agent asks for permission or completes a task.
- 🎙️ **Voice TTS Studio**: Real-time voice announcements over phone speaker with adjustable speech rate (`0.5x` - `2.0x`), pitch sliders, and customizable phrase templates.
- 🔔 **Multi-Session Terminal Badges**: Dynamically identifies the exact Termux session number (`Session 1` to `Session N`) and prints an in-terminal colored banner + terminal bell to `/dev/pts/X` so you instantly spot the active terminal.
- 🎛️ **In-Terminal Badge Switch**: Prefer a clean terminal? Easily toggle terminal badges ON/OFF directly from the web portal.
- 📳 **Smart Vibration & Sound**: Gentle vibration patterns for task completion, alert patterns for permissions, accompanied by custom LED colors.
- 🔗 **Dual CLI Support**: Out-of-the-box hooks for both **Google Antigravity (`agy`)** and **Anthropic Claude Code**.
- 🛠️ **Instant Test Center**: Test notifications, voice synthesis, and activity launching right from the web browser.

---

## 🚀 Quick Install

Open **Termux** and run:

```bash
git clone https://github.com/your-username/agent-pulse.git ~/.agent-pulse
cd ~/.agent-pulse
./install.sh
```

The installer automatically:
1. Verifies required packages (`python`, `jq`, `termux-api`).
2. Configures hooks for **Antigravity** (`~/.gemini/config/hooks.json`) and **Claude** (`~/.claude/settings.json`).
3. Installs the `agent-pulse` command into `$PREFIX/bin`.
4. Starts the local Web Portal daemon on port `8899`.

---

## 📱 Web Portal Controls

Open the dashboard in your mobile browser anytime:

```bash
agent-pulse open
```
Or navigate manually to: **`http://localhost:8899`**

### Available Settings:
| Category | Setting | Description |
| :--- | :--- | :--- |
| **Automation** | `Auto-Open on Permission` | Launches Termux when agent needs permission or asks a question |
| **Automation** | `Auto-Open on Complete` | Launches Termux when agent completes its run |
| **Voice TTS** | `Speech Rate & Pitch` | Sliders from 0.5x to 2.0x for voice speed and tone |
| **Voice TTS** | `Speech Templates` | Phrase customization with tags `{session}`, `{folder}`, `{tool}` |
| **Alerts** | `Sound & Vibration` | Toggle audio chime and tactile haptic vibration patterns |
| **Alerts** | `In-Terminal Screen Badge`| Print or hide highlighted status banners inside the terminal |
| **Alerts** | `Notification Templates`| Custom title and message templates for push notifications |

---

## ⌨️ CLI Cheat Sheet

```bash
agent-pulse status       # Check if Web Portal daemon is active
agent-pulse open         # Open Web Dashboard in default browser
agent-pulse restart      # Restart daemon to apply manual config changes
agent-pulse stop         # Stop background daemon
agent-pulse start        # Start background daemon
```

---

## ⚙️ Configuration Schema (`config.json`)

Settings modified in the Web Portal are saved to `~/.agent-pulse/config.json`:

```json
{
  "server": {
    "port": 8899,
    "host": "127.0.0.1"
  },
  "automation": {
    "auto_open_on_permission": false,
    "auto_open_on_complete": false,
    "only_open_when_background": true
  },
  "tts": {
    "enabled": true,
    "rate": 1.0,
    "pitch": 1.0,
    "permission_text": "Antigravity in {session} is waiting for permission",
    "complete_text": "Antigravity task completed in {session}",
    "error_text": "Antigravity in {session} stopped with an error"
  },
  "notification": {
    "sound": true,
    "vibrate": true,
    "vibrate_pattern_complete": "100,100,100",
    "vibrate_pattern_permission": "300,150,300,150,300",
    "led": true,
    "led_color_complete": "00FF00",
    "led_color_permission": "FFCC00",
    "led_color_error": "FF0000",
    "terminal_banner": true
  },
  "templates": {
    "title_complete": "AGY [{session}: {folder}] - Task Completed ✅",
    "title_permission": "AGY [{session}: {folder}] - Permission Required 🔒",
    "title_error": "AGY [{session}: {folder}] - Error ⚠️"
  }
}
```

---

## 🔧 Prerequisites

- **Termux** (from [F-Droid](https://f-droid.org/packages/com.termux/))
- **Termux:API** app installed on Android
- Core packages:
  ```bash
  pkg install python jq termux-api
  ```
- Android Permission: Grant **"Display over other apps"** (Appear on top) to `Termux` and `Termux:API` in Android Settings to enable background auto-opening.

---

## 🤝 Contributing

Pull requests are welcome! Feel free to open issues for new agent integrations (e.g. OpenCode, Aider, Codex) or UI themes.

---

## 📄 License

MIT License © 2026

---

<div align="center">
<sub>Built with 💙 for mobile AI developers running Termux.</sub>
<br/>
<sub><b>AGY Session Reference:</b> <code>d4839470-f94f-4b61-94b6-c0cd1b25b144</code></sub>
</div>
