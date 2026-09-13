#!/data/data/com.termux/files/usr/bin/bash
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

CONFIG_FILE="/data/data/com.termux/files/home/.agent-pulse/config.json"
OPEN_SCRIPT="/data/data/com.termux/files/home/.agent-pulse/open.sh"
LOG_FILE="/data/data/com.termux/files/home/.agent-pulse/logs/activity.log"

mode="$1"

# Helper to read config via jq
get_config() {
    jq -r "$1" "$CONFIG_FILE" 2>/dev/null
}

# Standalone test modes
if [ "$mode" = "test_voice" ]; then
    rate=$(get_config 'if .tts.rate != null then .tts.rate else 1.0 end')
    pitch=$(get_config 'if .tts.pitch != null then .tts.pitch else 1.0 end')
    msg="${2:-Agent Pulse voice test is working successfully}"
    termux-tts-speak -r "$rate" -p "$pitch" "$msg"
    exit 0
fi

if [ "$mode" = "test_notify" ]; then
    title="${2:-Agent Pulse Test}"
    content="${3:-This is a test notification from Agent Pulse.}"
    termux-notification \
        --id "agent-pulse-test" \
        --title "$title" \
        --content "$content" \
        --priority "high" \
        --sound \
        --vibrate "100,100,100" \
        --action "$OPEN_SCRIPT agent-pulse-test" \
        --button1 "Open Termux" \
        --button1-action "$OPEN_SCRIPT agent-pulse-test" \
        --button2 "Dismiss" \
        --button2-action "termux-notification-remove agent-pulse-test"
    exit 0
fi

# Read stdin JSON payload from Agent (Antigravity or Claude)
input=$(cat)

# 1. Detect which Termux session & tty agent is running in
cur_tty=$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' ')
if [ -z "$cur_tty" ] || [ "$cur_tty" = "?" ]; then
    parent_pid=$(ps -o ppid= -p $PPID 2>/dev/null | tr -d ' ')
    cur_tty=$(ps -o tty= -p "$parent_pid" 2>/dev/null | tr -d ' ')
fi

pts_num=$(echo "$cur_tty" | grep -o '[0-9]\+')
if [ -n "$pts_num" ]; then
    session_num=$((pts_num + 1))
    session_label="Session $session_num"
    notify_id="agent-pulse-$pts_num"
else
    session_num="1"
    session_label="Session 1"
    notify_id="agent-pulse-default"
fi

folder_name=$(basename "$(pwd)")
[ -z "$folder_name" ] && folder_name="workspace"

# 2. Session and folder metadata ready

# 3. Read settings from config.json
smart_dnd=$(get_config 'if .smart_dnd.enabled != null then .smart_dnd.enabled else true end')
silent_toast=$(get_config 'if .smart_dnd.silent_toast_in_termux != null then .smart_dnd.silent_toast_in_termux else true end')
auto_open_perm=$(get_config 'if .automation.auto_open_on_permission != null then .automation.auto_open_on_permission else false end')
auto_open_comp=$(get_config 'if .automation.auto_open_on_complete != null then .automation.auto_open_on_complete else false end')
tts_enabled=$(get_config 'if .tts.enabled != null then .tts.enabled else true end')
tts_rate=$(get_config 'if .tts.rate != null then .tts.rate else 1.0 end')
tts_pitch=$(get_config 'if .tts.pitch != null then .tts.pitch else 1.0 end')
snd_enabled=$(get_config 'if .notification.sound != null then .notification.sound else true end')
vib_enabled=$(get_config 'if .notification.vibrate != null then .notification.vibrate else true end')
led_enabled=$(get_config 'if .notification.led != null then .notification.led else true end')
banner_enabled=$(get_config 'if .notification.terminal_banner != null then .notification.terminal_banner else false end')

vib_comp=$(get_config '.notification.vibrate_pattern_complete // "100,100,100"')
vib_perm=$(get_config '.notification.vibrate_pattern_permission // "300,150,300,150,300"')
led_comp=$(get_config '.notification.led_color_complete // "00FF00"')
led_perm=$(get_config '.notification.led_color_permission // "FFCC00"')
led_err=$(get_config '.notification.led_color_error // "FF0000"')

# Prepare Event Details
is_error=false
is_permission=false
tool_name=""
event_status=""

if [ "$mode" = "stop" ]; then
    term_reason=$(printf '%s' "$input" | jq -r '.stopHookArgs.terminationReason // .terminationReason // empty' 2>/dev/null)
    err_msg=$(printf '%s' "$input" | jq -r '.stopHookArgs.error // .error // empty' 2>/dev/null)
    last_prompt=$(printf '%s' "$input" | jq -r '.common.lastUserInput // .lastUserInput // empty' 2>/dev/null)
    if [ "$term_reason" = "error" ] || [ -n "$err_msg" ]; then
        is_error=true
        event_status="error"
    else
        event_status="completed"
    fi
elif [ "$mode" = "pre_tool" ]; then
    tool_name=$(printf '%s' "$input" | jq -r '.preToolHookArgs.toolCall.name // .toolCall.name // empty' 2>/dev/null)
    question=$(printf '%s' "$input" | jq -r '(.preToolHookArgs.toolCall.args // .toolCall.args).questions[0].question // empty' 2>/dev/null)
    is_permission=true
    event_status="permission"
elif [ "$mode" = "claude" ]; then
    claude_type=$(printf '%s' "$input" | jq -r '.notification_type // empty' 2>/dev/null)
    claude_msg=$(printf '%s' "$input" | jq -r '.message // empty' 2>/dev/null)
    if [ "$claude_type" = "permission_prompt" ]; then
        is_permission=true
        event_status="permission"
    else
        event_status="completed"
    fi
fi

# Template Replacer function
format_tpl() {
    local str="$1"
    str="${str//\{session\}/$session_label}"
    str="${str//\{folder\}/$folder_name}"
    str="${str//\{tool\}/$tool_name}"
    str="${str//\{status\}/$event_status}"
    echo "$str"
}

# Build Notification Elements
if [ "$is_error" = true ]; then
    tpl_title=$(get_config '.templates.title_error // "AGY [{session}: {folder}] - Error ⚠️"')
    title=$(format_tpl "$tpl_title")
    content="Stopped with error: ${err_msg:-Execution error}"
    tpl_tts=$(get_config '.tts.error_text // "Antigravity in {session} stopped with an error"')
    tts_text=$(format_tpl "$tpl_tts")
    vibrate_pat="$vib_perm"
    led_color="$led_err"
    priority="max"
    terminal_banner="\a\n\033[1;41;97m [AGENT PULSE ERROR] \033[0m \033[1;31mTask failed in $session_label ($folder_name)\033[0m\n"
elif [ "$is_permission" = true ]; then
    tpl_title=$(get_config '.templates.title_permission // "AGY [{session}: {folder}] - Permission Required 🔒"')
    title=$(format_tpl "$tpl_title")
    if [ -n "$question" ]; then
        content=$(printf '%s' "$question" | tr '\n' ' ' | cut -c 1-80)
    elif [ -n "$claude_msg" ]; then
        content="$claude_msg"
    else
        content="Waiting for approval for ${tool_name:-command} in $folder_name"
    fi
    tpl_tts=$(get_config '.tts.permission_text // "Antigravity in {session} is waiting for permission"')
    tts_text=$(format_tpl "$tpl_tts")
    vibrate_pat="$vib_perm"
    led_color="$led_perm"
    priority="max"
    terminal_banner="\a\n\033[1;43;30m [AGENT PULSE WAITING] \033[0m \033[1;33mWaiting for permission in $session_label ($folder_name)\033[0m\n"
else
    tpl_title=$(get_config '.templates.title_complete // "AGY [{session}: {folder}] - Task Completed ✅"')
    title=$(format_tpl "$tpl_title")
    if [ -n "$last_prompt" ]; then
        short_prompt=$(printf '%s' "$last_prompt" | tr '\n' ' ' | cut -c 1-65)
        content="$short_prompt"
    else
        content="Task completed in $folder_name"
    fi
    tpl_tts=$(get_config '.tts.complete_text // "Antigravity task completed in {session}"')
    tts_text=$(format_tpl "$tpl_tts")
    vibrate_pat="$vib_comp"
    led_color="$led_comp"
    priority="high"
    terminal_banner="\a\n\033[1;42;97m [AGENT PULSE DONE] \033[0m \033[1;32mTask completed in $session_label ($folder_name)\033[0m\n"
fi

# Print highlighted banner directly inside terminal session if enabled
if [ "$banner_enabled" = "true" ] && [ -n "$cur_tty" ] && [ -c "/dev/$cur_tty" ]; then
    printf '%b' "$terminal_banner" > "/dev/$cur_tty" 2>/dev/null
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Event: $event_status ($session_label, folder: $folder_name)" >> "$LOG_FILE"

# Keep-alive: ensure Agent-Pulse web server is alive in background
if ! curl -s -m 0.15 http://127.0.0.1:8899/api/status >/dev/null 2>&1; then
    /data/data/com.termux/files/home/.agent-pulse/start.sh >/dev/null 2>&1 &
fi

# AUTO-OPEN AUTOMATION (Triggered only if explicitly toggled ON by user)
if [ "$is_permission" = true ] && [ "$auto_open_perm" = "true" ]; then
    "$OPEN_SCRIPT" "$notify_id" >/dev/null 2>&1 &
elif [ "$is_permission" = false ] && [ "$is_error" = false ] && [ "$auto_open_comp" = "true" ]; then
    "$OPEN_SCRIPT" "$notify_id" >/dev/null 2>&1 &
fi

# DISPATCH NOTIFICATION
extra_flags=()
[ "$snd_enabled" = "true" ] && extra_flags+=(--sound)
[ "$vib_enabled" = "true" ] && extra_flags+=(--vibrate "$vibrate_pat")
if [ "$led_enabled" = "true" ]; then
    extra_flags+=(--led-color "$led_color" --led-on 500 --led-off 500)
fi

termux-notification \
    --id "$notify_id" \
    --title "$title" \
    --content "$content" \
    --priority "$priority" \
    "${extra_flags[@]}" \
    --action "$OPEN_SCRIPT $notify_id" \
    --button1 "Open Termux" \
    --button1-action "$OPEN_SCRIPT $notify_id" \
    --button2 "Dismiss" \
    --button2-action "termux-notification-remove $notify_id"

# DISPATCH VOICE TTS
if [ "$tts_enabled" = "true" ] && [ -n "$tts_text" ]; then
    termux-tts-speak -r "$tts_rate" -p "$tts_pitch" "$tts_text" &
fi

# CONTRACT RESPONSE
if [ "$mode" = "stop" ]; then
    printf '{"decision":""}\n'
elif [ "$mode" = "pre_tool" ]; then
    printf '{"decision":"allow"}\n'
else
    printf '{}\n'
fi
exit 0
