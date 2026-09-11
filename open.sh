#!/data/data/com.termux/files/usr/bin/bash
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

log_file="/data/data/com.termux/files/home/.agent-pulse/logs/activity.log"
mkdir -p "$(dirname "$log_file")"

# If notification ID is passed, remove it
if [ -n "$1" ]; then
    termux-notification-remove "$1" 2>/dev/null
fi

# Show instant toast
termux-toast -b black -c white "Opening Termux..." 2>/dev/null &

# Bring Termux to foreground with launcher intent
out=$(/data/data/com.termux/files/usr/bin/am start \
    -a android.intent.action.MAIN \
    -c android.intent.category.LAUNCHER \
    -n com.termux/.app.TermuxActivity \
    --activity-brought-to-front \
    -f 0x10200000 2>&1)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Termux opened via open.sh" >> "$log_file"
