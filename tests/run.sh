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
  /usr/bin/grep -q '^disable-model-invocation: true$' "$manifest"
  /usr/bin/grep -q '^compatibility:' "$manifest"
  openai_policy="$repo_dir/skills/$skill/agents/openai.yaml"
  /usr/bin/grep -q '^  allow_implicit_invocation: false$' "$openai_policy"
done

if /usr/bin/grep -RInE '~/.claude|~/.copilot|CLAUDE_SKILL_DIR|COPILOT_' "$repo_dir/skills"; then
  echo 'harness-specific path or variable found in a portable skill payload' >&2
  exit 1
fi

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

assert_install() {
  target=$1
  expected=$2
  home="$temp/home-$target"
  /bin/mkdir -p "$home"
  HOME="$home" /bin/bash "$repo_dir/install.sh" "$target" >/dev/null
  [[ -f "$home/$expected/cleanup-builds/SKILL.md" ]]
  [[ -f "$home/$expected/vscode-crash-recovery/SKILL.md" ]]
}

assert_install copilot .copilot/skills
assert_install claude .claude/skills
assert_install codex .agents/skills
assert_install generic .agents/skills
assert_install kimi .kimi/skills
assert_install kimi-code .kimi-code/skills
assert_install config-agents .config/agents/skills

custom_dir="$temp/custom-skills"
HOME="$temp/custom-home" /bin/bash "$repo_dir/install.sh" custom "$custom_dir" >/dev/null
[[ -f "$custom_dir/cleanup-builds/SKILL.md" ]]
[[ -f "$custom_dir/vscode-crash-recovery/SKILL.md" ]]

link_dir="$temp/linked-skills"
HOME="$temp/link-home" /bin/bash "$repo_dir/install.sh" --link custom "$link_dir" >/dev/null
[[ -L "$link_dir/cleanup-builds" ]]
[[ -L "$link_dir/vscode-crash-recovery" ]]

if HOME="$temp/home-copilot" /bin/bash "$repo_dir/install.sh" copilot >/dev/null 2>&1; then
  echo 'installer must refuse overwrites' >&2
  exit 1
fi

/bin/echo 'all tests passed'
