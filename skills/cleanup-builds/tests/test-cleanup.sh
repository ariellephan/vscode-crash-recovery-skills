#!/usr/bin/env bash

set -eu

PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH

skill_dir=$(CDPATH= cd -- "$(/usr/bin/dirname "$0")/.." && /bin/pwd)
script="$skill_dir/scripts/cleanup.sh"
temp=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/cleanup-builds-test.XXXXXX")
trap '/bin/rm -rf "$temp"' EXIT HUP INT TERM

project="$temp/example-project"
/bin/mkdir -p "$project/.git"
project_resolved=$(CDPATH= cd -- "$project" && /bin/pwd -P)

/bin/bash -n "$script"
/bin/bash "$script" --help | /usr/bin/grep -q 'default is a dry run'

output=$(PATH=/not-used /bin/bash "$script" --root "$project")
printf '%s\n' "$output" | /usr/bin/grep -q '^build cleanup (dry-run)$'
printf '%s\n' "$output" | /usr/bin/grep -q "^scope: $project_resolved$"
printf '%s\n' "$output" | /usr/bin/grep -q '^Gradle daemons: none in scope$'

if /bin/bash "$script" --root "$temp/missing" >/dev/null 2>&1; then
  echo 'missing roots must fail' >&2
  exit 1
fi
if /bin/bash "$script" --sample-seconds 0 --root "$project" >/dev/null 2>&1; then
  echo 'zero sample time must fail' >&2
  exit 1
fi
global_option='--'"global"
forbidden_pattern="$global_option|shutdown all|qemu-system|adb emu|(^|[[:space:]])pkill([[:space:]]|$)|(^|[[:space:]])killall([[:space:]]|$)"
if /usr/bin/grep -nE -- "$forbidden_pattern" "$script"; then
  echo 'whole-machine behavior is forbidden' >&2
  exit 1
fi

/bin/echo 'cleanup-builds tests passed'
