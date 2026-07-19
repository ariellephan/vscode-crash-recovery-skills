#!/usr/bin/env bash

set -u

PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH

apply=0
root_override=""
sample_seconds=3
sample_file=""

usage() {
  cat <<'EOF'
Usage: cleanup.sh [--apply] [--root PATH] [--sample-seconds N]

Safely inventories Gradle daemons whose current working directory is inside one
project. The default is a dry run. --apply sends TERM only when a candidate's
CPU time is unchanged across the sample and its command and CWD still match.

This script never stops simulators, emulators, or daemons from other projects.
It has no whole-machine mode.
EOF
}

cleanup_temp() {
  if [[ -n "$sample_file" && -f "$sample_file" ]]; then
    /bin/rm -f "$sample_file"
  fi
}
trap cleanup_temp EXIT HUP INT TERM

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      apply=1
      shift
      ;;
    --root)
      [[ $# -ge 2 ]] || { echo "--root requires a path" >&2; exit 2; }
      root_override=$2
      shift 2
      ;;
    --sample-seconds)
      [[ $# -ge 2 ]] || { echo "--sample-seconds requires an integer" >&2; exit 2; }
      sample_seconds=$2
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$sample_seconds" in
  ''|*[!0-9]*) echo "--sample-seconds must be a positive integer" >&2; exit 2 ;;
  0) echo "--sample-seconds must be greater than zero" >&2; exit 2 ;;
esac

resolve_root() {
  local directory
  if [[ -n "$root_override" ]]; then
    [[ -d "$root_override" ]] || { echo "project root does not exist: $root_override" >&2; return 1; }
    (CDPATH= cd -- "$root_override" && /bin/pwd -P)
    return
  fi

  directory=$PWD
  while [[ "$directory" != / ]]; do
    if [[ -e "$directory/.git" || -f "$directory/gradlew" || -f "$directory/settings.gradle" || -f "$directory/settings.gradle.kts" ]]; then
      printf '%s\n' "$directory"
      return
    fi
    directory=$(/usr/bin/dirname "$directory")
  done

  echo "no project root found; run inside a repository or pass --root" >&2
  return 1
}

memory_summary() {
  local vm_output page_size free_pages free_gib swap
  vm_output=$(/usr/bin/vm_stat)
  page_size=$(printf '%s\n' "$vm_output" | /usr/bin/sed -n 's/.*page size of \([0-9][0-9]*\) bytes.*/\1/p' | /usr/bin/head -n 1)
  page_size=${page_size:-4096}
  free_pages=$(printf '%s\n' "$vm_output" | /usr/bin/awk -F: '/Pages free|Pages speculative/ {gsub(/[^0-9]/, "", $2); sum += $2} END {print sum+0}')
  free_gib=$(/usr/bin/awk -v pages="$free_pages" -v bytes="$page_size" 'BEGIN {printf "%.1f", pages * bytes / 1073741824}')
  swap=$(/usr/sbin/sysctl -n vm.swapusage | /usr/bin/sed 's/.*used = //; s/  free.*//')
  printf 'free RAM: %s GiB | swap used: %s\n' "$free_gib" "$swap"
}

daemon_command_matches() {
  local pid=$1 command
  command=$(/bin/ps -p "$pid" -o command= 2>/dev/null || true)
  [[ "$command" == *GradleDaemon* ]]
}

daemon_cwd() {
  local pid=$1
  /usr/sbin/lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | /usr/bin/sed -n 's/^n//p' | /usr/bin/head -n 1
}

cwd_in_root() {
  local cwd=$1 root=$2
  [[ "$cwd" == "$root" || "$cwd" == "$root"/* ]]
}

daemons_in_root() {
  local root=$1 pid cwd
  for pid in $(/usr/bin/pgrep -f GradleDaemon 2>/dev/null || true); do
    daemon_command_matches "$pid" || continue
    cwd=$(daemon_cwd "$pid")
    cwd_in_root "$cwd" "$root" && printf '%s\n' "$pid"
  done
}

project_root=$(resolve_root) || exit 2
[[ "$project_root" != / ]] || { echo "refusing filesystem root scope" >&2; exit 2; }
mode=dry-run
[[ "$apply" -eq 1 ]] && mode=apply

printf 'build cleanup (%s)\n' "$mode"
printf 'scope: %s\n' "$project_root"
printf 'before: '; memory_summary

pids=$(daemons_in_root "$project_root")
if [[ -z "$pids" ]]; then
  echo "Gradle daemons: none in scope"
  printf 'after:  '; memory_summary
  exit 0
fi

sample_file=$(/usr/bin/mktemp "${TMPDIR:-/tmp}/cleanup-builds.XXXXXX")
for pid in $pids; do
  cpu_time=$(/bin/ps -p "$pid" -o time= 2>/dev/null | /usr/bin/tr -d ' ')
  [[ -n "$cpu_time" ]] && printf '%s %s\n' "$pid" "$cpu_time" >> "$sample_file"
done

printf 'sampling %s candidate(s) for %s seconds...\n' "$(/usr/bin/wc -l < "$sample_file" | /usr/bin/tr -d ' ')" "$sample_seconds"
/bin/sleep "$sample_seconds"

stopped=0
would_stop=0
kept=0
while read -r pid first_cpu; do
  [[ -n "$pid" ]] || continue
  second_cpu=$(/bin/ps -p "$pid" -o time= 2>/dev/null | /usr/bin/tr -d ' ')
  if [[ -z "$second_cpu" ]]; then
    continue
  fi

  current_cwd=$(daemon_cwd "$pid")
  if [[ "$second_cpu" != "$first_cpu" ]] || ! daemon_command_matches "$pid" || ! cwd_in_root "$current_cwd" "$project_root"; then
    printf 'keep pid=%s (active or scope changed)\n' "$pid"
    kept=$((kept + 1))
    continue
  fi

  if [[ "$apply" -eq 0 ]]; then
    printf 'would stop pid=%s cwd=%s\n' "$pid" "$current_cwd"
    would_stop=$((would_stop + 1))
  elif /bin/kill -TERM "$pid" 2>/dev/null; then
    printf 'stopped pid=%s cwd=%s\n' "$pid" "$current_cwd"
    stopped=$((stopped + 1))
  else
    printf 'keep pid=%s (TERM failed)\n' "$pid"
    kept=$((kept + 1))
  fi
done < "$sample_file"

/bin/rm -f "$sample_file"
sample_file=""
printf 'summary: stopped=%s would_stop=%s kept=%s\n' "$stopped" "$would_stop" "$kept"
printf 'after:  '; memory_summary
