#!/usr/bin/env bash

set -eu

PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH

usage() {
  cat <<'EOF'
Usage: install.sh copilot|claude|agents|all

Installs both skills into personal agent-skill directories. The installer
refuses to overwrite an existing skill.
EOF
}

case "${1:-}" in
  copilot)
    destinations=("$HOME/.copilot/skills")
    ;;
  claude)
    destinations=("$HOME/.claude/skills")
    ;;
  agents)
    destinations=("$HOME/.agents/skills")
    ;;
  all)
    destinations=("$HOME/.copilot/skills" "$HOME/.claude/skills" "$HOME/.agents/skills")
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
    /bin/cp -R "$repo_dir/skills/$skill" "$destination/$skill"
    echo "installed: $destination/$skill"
  done
done
