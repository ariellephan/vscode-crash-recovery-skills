#!/usr/bin/env bash

set -eu

PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH

label=io.github.ariellephan.vscode-health-monitor
plist="$HOME/Library/LaunchAgents/$label.plist"
state_dir="$HOME/Library/Caches/vscode-health-monitor"
script_dir=$(CDPATH= cd -- "$(/usr/bin/dirname "$0")" && /bin/pwd)
health_script="$script_dir/vscode-health-check.sh"
domain="gui/$(/usr/bin/id -u)"

usage() {
  cat <<'EOF'
Usage: monitor-control.sh install|uninstall|status|run|render-plist

The monitor is metadata-only and notification-only. It never remediates.
EOF
}

render_plist() {
  cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$health_script</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>300</integer>
  <key>ProcessType</key>
  <string>Background</string>
  <key>LowPriorityIO</key>
  <true/>
</dict>
</plist>
EOF
}

case "${1:-}" in
  install)
    /bin/mkdir -p "$HOME/Library/LaunchAgents" "$state_dir"
    temp="$plist.tmp.$$"
    render_plist > "$temp"
    /usr/bin/plutil -lint "$temp" >/dev/null
    /bin/mv -f "$temp" "$plist"
    /bin/launchctl bootout "$domain/$label" >/dev/null 2>&1 || true
    /bin/launchctl bootstrap "$domain" "$plist"
    /bin/launchctl enable "$domain/$label"
    /bin/launchctl kickstart -k "$domain/$label"
    echo "installed: $plist"
    ;;
  uninstall)
    /bin/launchctl bootout "$domain/$label" >/dev/null 2>&1 || true
    /bin/rm -f "$plist"
    echo "uninstalled: $label"
    ;;
  status)
    if /bin/launchctl print "$domain/$label" >/dev/null 2>&1; then
      echo "loaded: $label"
      /bin/launchctl print "$domain/$label" | /usr/bin/grep -E 'state =|last exit code =|runs =|path =' || true
    else
      echo "not loaded: $label"
    fi
    [[ -f "$state_dir/latest.txt" ]] && /bin/cat "$state_dir/latest.txt"
    ;;
  run)
    exec /bin/bash "$health_script" --no-notify
    ;;
  render-plist)
    render_plist
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
