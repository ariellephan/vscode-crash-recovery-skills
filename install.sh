#!/usr/bin/env bash

set -eu

PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH

usage() {
  cat <<'EOF'
Usage: install.sh [--link] TARGET [CUSTOM_DIRECTORY]

Targets:
  generic        ~/.agents/skills (Copilot, Codex, Kimi, and other clients)
  copilot        ~/.copilot/skills
  claude         ~/.claude/skills
  codex          ~/.agents/skills (official Codex personal location)
  kimi           ~/.kimi/skills
  kimi-code      ~/.kimi-code/skills (compatibility for existing clients)
  config-agents  ~/.config/agents/skills (Kimi-recommended generic location)
  custom PATH    Any absolute Agent Skills directory
  all            All named personal locations, after collision preflight

The default copies both skills. --link creates symlinks to this checkout so one
source tree serves multiple harnesses. Existing skills are never overwritten.
EOF
}

mode=copy
if [[ "${1:-}" == --link ]]; then
  mode=link
  shift
fi

target=${1:-}
[[ -n "$target" ]] || { usage >&2; exit 2; }
shift

case "$target" in
  generic|agents|codex)
    destinations=("$HOME/.agents/skills")
    ;;
  copilot)
    destinations=("$HOME/.copilot/skills")
    ;;
  claude)
    destinations=("$HOME/.claude/skills")
    ;;
  kimi)
    destinations=("$HOME/.kimi/skills")
    ;;
  kimi-code)
    destinations=("$HOME/.kimi-code/skills")
    ;;
  config-agents)
    destinations=("$HOME/.config/agents/skills")
    ;;
  custom)
    [[ $# -eq 1 ]] || { echo "custom requires one absolute directory" >&2; exit 2; }
    custom_directory=$1
    [[ "$custom_directory" == /* ]] || { echo "custom directory must be absolute" >&2; exit 2; }
    destinations=("$custom_directory")
    ;;
  all)
    destinations=(
      "$HOME/.copilot/skills"
      "$HOME/.claude/skills"
      "$HOME/.agents/skills"
      "$HOME/.kimi/skills"
      "$HOME/.kimi-code/skills"
      "$HOME/.config/agents/skills"
    )
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

repo_dir=$(CDPATH= cd -- "$(/usr/bin/dirname "$0")" && /bin/pwd)
skills=(cleanup-builds vscode-crash-recovery)

for destination in "${destinations[@]}"; do
  for skill in "${skills[@]}"; do
    if [[ -e "$destination/$skill" ]]; then
      echo "refusing to overwrite: $destination/$skill" >&2
      exit 1
    fi
  done
done

for destination in "${destinations[@]}"; do
  /bin/mkdir -p "$destination"
  for skill in "${skills[@]}"; do
    if [[ "$mode" == link ]]; then
      /bin/ln -s "$repo_dir/skills/$skill" "$destination/$skill"
    else
      /bin/cp -R "$repo_dir/skills/$skill" "$destination/$skill"
    fi
    echo "installed ($mode): $destination/$skill"
  done
done
