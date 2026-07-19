#!/usr/bin/env bash

set -eu

PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH

repo_dir=$(CDPATH= cd -- "$(/usr/bin/dirname "$0")/.." && /bin/pwd)
temp=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/vscode-crash-skills.XXXXXX")
trap '/bin/rm -rf "$temp"' EXIT HUP INT TERM

while IFS= read -r script; do
  /bin/bash -n "$script"
done < <(/usr/bin/find "$repo_dir" -type f -name '*.sh' -not -path '*/.git/*' | /usr/bin/sort)

/bin/bash "$repo_dir/skills/cleanup-builds/tests/test-cleanup.sh"
/bin/bash "$repo_dir/skills/vscode-crash-recovery/tests/test-vscode-health-check.sh"

for skill in cleanup-builds vscode-crash-recovery; do
  manifest="$repo_dir/skills/$skill/SKILL.md"
  [[ "$(/usr/bin/head -n 1 "$manifest")" == '---' ]]
  [[ "$(/usr/bin/grep -c '^---$' "$manifest")" -ge 2 ]]
  /usr/bin/grep -q "^name: $skill$" "$manifest"
  /usr/bin/grep -q '^description:' "$manifest"
done

user_path='/'"Users"'/'
workspace_marker='workspace'"Storage"'/[0-9a-f]{32}'
session_marker='session-'"state"'/[0-9a-f-]{36}'
private_key_marker='BEGIN [A-Z ]*PRIVATE'" KEY"
privacy_pattern="$user_path|file://$user_path|$workspace_marker|$session_marker|$private_key_marker"
if /usr/bin/grep -RInE --exclude-dir=.git "$privacy_pattern" "$repo_dir"; then
  echo 'machine-specific path, session identifier, or private key marker found' >&2
  exit 1
fi
global_option='--'"global"
if /usr/bin/grep -RIn --exclude-dir=.git -- "$global_option" "$repo_dir"; then
  echo 'whole-machine option is forbidden' >&2
  exit 1
fi

/bin/mkdir -p "$temp/home"
HOME="$temp/home" /bin/bash "$repo_dir/install.sh" copilot
[[ -f "$temp/home/.copilot/skills/cleanup-builds/SKILL.md" ]]
[[ -f "$temp/home/.copilot/skills/vscode-crash-recovery/SKILL.md" ]]
if HOME="$temp/home" /bin/bash "$repo_dir/install.sh" copilot >/dev/null 2>&1; then
  echo 'installer must refuse overwrites' >&2
  exit 1
fi

/bin/echo 'all tests passed'
