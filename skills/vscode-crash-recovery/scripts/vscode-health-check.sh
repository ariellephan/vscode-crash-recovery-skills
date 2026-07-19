#!/usr/bin/env bash

set -u

PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH

notify=1
case "${1:-}" in
  --no-notify)
    notify=0
    ;;
  --help|-h)
    cat <<'EOF'
Usage: vscode-health-check.sh [--no-notify]

Metadata-only VS Code health check. It never kills processes, reloads windows,
opens transcripts, inspects images, deletes files, or accesses services.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "unknown option: $1" >&2
    exit 2
    ;;
esac

renderer_limit_mib=${VSCODE_HEALTH_RENDERER_MIB:-2048}
plugin_limit_mib=${VSCODE_HEALTH_PLUGIN_MIB:-1536}
chat_limit_mib=${VSCODE_HEALTH_CHAT_MIB:-128}
min_free_mib=${VSCODE_HEALTH_MIN_FREE_MIB:-8192}
max_swap_pct=${VSCODE_HEALTH_MAX_SWAP_PCT:-80}
storage_root=${VSCODE_HEALTH_STORAGE_ROOT:-"$HOME/Library/Application Support/Code/User/workspaceStorage"}
state_dir=${VSCODE_HEALTH_STATE_DIR:-"$HOME/Library/Caches/vscode-health-monitor"}

if [[ -n "${VSCODE_HEALTH_VM_STAT_FILE:-}" ]]; then
  vm_output=$(/bin/cat "$VSCODE_HEALTH_VM_STAT_FILE")
else
  vm_output=$(/usr/bin/vm_stat)
fi

page_size=$(printf '%s\n' "$vm_output" | /usr/bin/sed -n 's/.*page size of \([0-9][0-9]*\) bytes.*/\1/p' | /usr/bin/head -n 1)
page_size=${page_size:-4096}
free_pages=$(printf '%s\n' "$vm_output" | /usr/bin/awk -F: '/Pages free|Pages speculative/ {gsub(/[^0-9]/, "", $2); sum += $2} END {print sum+0}')
free_mib=$(/usr/bin/awk -v pages="$free_pages" -v bytes="$page_size" 'BEGIN {printf "%.0f", pages * bytes / 1048576}')

if [[ -n "${VSCODE_HEALTH_SWAP_USAGE:-}" ]]; then
  swap_output=$VSCODE_HEALTH_SWAP_USAGE
else
  swap_output=$(/usr/sbin/sysctl -n vm.swapusage)
fi
swap_total_mib=$(printf '%s\n' "$swap_output" | /usr/bin/awk '{for (i=1; i<=NF; i++) if ($i == "total") {v=$(i+2); sub(/M$/, "", v); print v; exit}}')
swap_used_mib=$(printf '%s\n' "$swap_output" | /usr/bin/awk '{for (i=1; i<=NF; i++) if ($i == "used") {v=$(i+2); sub(/M$/, "", v); print v; exit}}')
swap_total_mib=${swap_total_mib:-0}
swap_used_mib=${swap_used_mib:-0}
swap_pct=$(/usr/bin/awk -v used="$swap_used_mib" -v total="$swap_total_mib" 'BEGIN {if (total > 0) printf "%.0f", used * 100 / total; else print 0}')

alerts=""
append_alert() {
  if [[ -z "$alerts" ]]; then
    alerts=$1
  else
    alerts="$alerts
$1"
  fi
}

host_pressure=$(/usr/bin/awk -v free="$free_mib" -v min="$min_free_mib" -v swap="$swap_pct" -v max="$max_swap_pct" 'BEGIN {print (free < min && swap >= max) ? "yes" : "no"}')
if [[ "$host_pressure" == yes ]]; then
  append_alert "host|free_mib=$free_mib|swap_pct=$swap_pct"
fi

if [[ -n "${VSCODE_HEALTH_PS_FILE:-}" ]]; then
  process_output=$(/bin/cat "$VSCODE_HEALTH_PS_FILE")
else
  process_output=$(/bin/ps -axo pid=,rss=,command=)
fi

process_alerts=$(printf '%s\n' "$process_output" | /usr/bin/awk \
  -v renderer_limit="$((renderer_limit_mib * 1024))" \
  -v plugin_limit="$((plugin_limit_mib * 1024))" '
  index($0, "Visual Studio Code.app") && index($0, "Code Helper") {
    pid=$1; rss=$2
    if (index($0, "--type=renderer") && rss >= renderer_limit) {
      printf "process|kind=renderer|pid=%s|rss_mib=%.0f\n", pid, rss / 1024
    } else if (index($0, "Code Helper (Plugin)") && rss >= plugin_limit) {
      printf "process|kind=plugin|pid=%s|rss_mib=%.0f\n", pid, rss / 1024
    }
  }')
if [[ -n "$process_alerts" ]]; then
  append_alert "$process_alerts"
fi

chat_limit_bytes=$((chat_limit_mib * 1024 * 1024))
chat_alerts=""
if [[ -d "$storage_root" ]]; then
  chat_alerts=$(/usr/bin/find "$storage_root" -type f -path '*/chatSessions/*.jsonl' -size "+${chat_limit_bytes}c" -print 2>/dev/null | while IFS= read -r transcript; do
    bytes=$(/usr/bin/stat -f '%z' "$transcript" 2>/dev/null || echo 0)
    session=$(/usr/bin/basename "$transcript" .jsonl)
    storage_dir=$(/usr/bin/dirname "$(/usr/bin/dirname "$transcript")")
    storage_id=$(/usr/bin/basename "$storage_dir")
    workspace="storage:$storage_id"
    metadata="$storage_dir/workspace.json"
    if [[ -f "$metadata" ]]; then
      metadata_bytes=$(/usr/bin/stat -f '%z' "$metadata" 2>/dev/null || echo 0)
      if [[ "$metadata_bytes" -le 65536 ]]; then
        folder=$(/usr/bin/plutil -extract folder raw -o - "$metadata" 2>/dev/null || true)
        [[ -n "$folder" ]] && workspace=$folder
      fi
    fi
    printf 'chat|session=%s|bytes=%s|workspace=%s\n' "$session" "$bytes" "$workspace"
  done)
fi
if [[ -n "$chat_alerts" ]]; then
  append_alert "$chat_alerts"
fi

if [[ -n "$alerts" ]]; then
  alert_count=$(printf '%s\n' "$alerts" | /usr/bin/awk 'NF {count++} END {print count+0}')
  status=warning
else
  alert_count=0
  status=ok
fi

summary="status=$status|alerts=$alert_count|free_mib=$free_mib|swap_pct=$swap_pct"
printf '%s\n' "$summary"
[[ -n "$alerts" ]] && printf '%s\n' "$alerts"

/bin/mkdir -p "$state_dir"
latest_tmp="$state_dir/latest.txt.tmp.$$"
printf '%s\n' "$summary" > "$latest_tmp"
[[ -n "$alerts" ]] && printf '%s\n' "$alerts" >> "$latest_tmp"
/bin/mv -f "$latest_tmp" "$state_dir/latest.txt"

alert_digest_file="$state_dir/last-alert.sha256"
if [[ -z "$alerts" ]]; then
  /bin/rm -f "$alert_digest_file"
elif [[ "$notify" -eq 1 ]]; then
  digest=$(printf '%s' "$alerts" | /usr/bin/shasum -a 256 | /usr/bin/awk '{print $1}')
  previous=""
  [[ -f "$alert_digest_file" ]] && previous=$(/bin/cat "$alert_digest_file")
  if [[ "$digest" != "$previous" ]]; then
    printf '%s\n' "$digest" > "$alert_digest_file"
    first_alert=$(printf '%s\n' "$alerts" | /usr/bin/head -n 1)
    message="$alert_count warning(s). $first_alert"
    /usr/bin/osascript - "$message" <<'APPLESCRIPT' >/dev/null 2>&1 || true
on run argv
  display notification (item 1 of argv) with title "VS Code health warning" subtitle "Run /vscode-crash-recovery"
end run
APPLESCRIPT
  fi
fi

exit 0
