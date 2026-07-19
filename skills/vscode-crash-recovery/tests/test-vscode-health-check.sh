#!/usr/bin/env bash

set -eu

PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH

skill_dir=$(CDPATH= cd -- "$(/usr/bin/dirname "$0")/.." && /bin/pwd)
check="$skill_dir/scripts/vscode-health-check.sh"
control="$skill_dir/scripts/monitor-control.sh"
temp=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/vscode-health-check.XXXXXX")
trap '/bin/rm -rf "$temp"' EXIT HUP INT TERM

/bin/mkdir -p "$temp/healthy-storage" "$temp/healthy-state"
/bin/cat > "$temp/healthy.vm" <<'EOF'
Mach Virtual Memory Statistics: (page size of 4096 bytes)
Pages free:                               8388608.
Pages speculative:                             0.
EOF
/bin/cat > "$temp/healthy.ps" <<'EOF'
101 262144 /Applications/Visual Studio Code.app/Contents/Frameworks/Code Helper (Renderer).app/Contents/MacOS/Code Helper (Renderer) --type=renderer
102 131072 /Applications/Visual Studio Code.app/Contents/Frameworks/Code Helper (Plugin).app/Contents/MacOS/Code Helper (Plugin) --type=utility
EOF

healthy=$(VSCODE_HEALTH_VM_STAT_FILE="$temp/healthy.vm" \
  VSCODE_HEALTH_SWAP_USAGE='total = 20480.00M used = 1024.00M free = 19456.00M' \
  VSCODE_HEALTH_PS_FILE="$temp/healthy.ps" \
  VSCODE_HEALTH_STORAGE_ROOT="$temp/healthy-storage" \
  VSCODE_HEALTH_STATE_DIR="$temp/healthy-state" \
  /bin/bash "$check" --no-notify)
printf '%s\n' "$healthy" | /usr/bin/grep -q '^status=ok|alerts=0|'

storage="$temp/warning-storage/workspace-hash"
/bin/mkdir -p "$storage/chatSessions" "$temp/warning-state"
printf '%s\n' '{"folder":"file:///tmp/example-project"}' > "$storage/workspace.json"
/bin/dd if=/dev/null of="$storage/chatSessions/11111111-2222-3333-4444-555555555555.jsonl" bs=1 seek=$((129 * 1024 * 1024)) 2>/dev/null
/bin/cat > "$temp/warning.vm" <<'EOF'
Mach Virtual Memory Statistics: (page size of 4096 bytes)
Pages free:                                131072.
Pages speculative:                             0.
EOF
/bin/cat > "$temp/warning.ps" <<'EOF'
201 2621440 /Applications/Visual Studio Code.app/Contents/Frameworks/Code Helper (Renderer).app/Contents/MacOS/Code Helper (Renderer) --type=renderer
202 1700000 /Applications/Visual Studio Code.app/Contents/Frameworks/Code Helper (Plugin).app/Contents/MacOS/Code Helper (Plugin) --type=utility
EOF

warning=$(VSCODE_HEALTH_VM_STAT_FILE="$temp/warning.vm" \
  VSCODE_HEALTH_SWAP_USAGE='total = 20480.00M used = 19000.00M free = 1480.00M' \
  VSCODE_HEALTH_PS_FILE="$temp/warning.ps" \
  VSCODE_HEALTH_STORAGE_ROOT="$temp/warning-storage" \
  VSCODE_HEALTH_STATE_DIR="$temp/warning-state" \
  /bin/bash "$check" --no-notify)
printf '%s\n' "$warning" | /usr/bin/grep -q '^status=warning|alerts=4|'
printf '%s\n' "$warning" | /usr/bin/grep -q '^host|free_mib=512|swap_pct=93$'
printf '%s\n' "$warning" | /usr/bin/grep -q '^process|kind=renderer|pid=201|rss_mib=2560$'
printf '%s\n' "$warning" | /usr/bin/grep -q '^process|kind=plugin|pid=202|rss_mib=1660$'
printf '%s\n' "$warning" | /usr/bin/grep -q '^chat|session=11111111-2222-3333-4444-555555555555|bytes=135266304|workspace=file:///tmp/example-project$'

/bin/bash "$control" render-plist > "$temp/monitor.plist"
/usr/bin/plutil -lint "$temp/monitor.plist" >/dev/null
/usr/bin/grep -q 'io.github.ariellephan.vscode-health-monitor' "$temp/monitor.plist"

/bin/echo 'vscode-health-check tests passed'
