---
name: vscode-crash-recovery
description: 'Audit and remediate a slow, frozen, repeatedly reloading, crashing, or high-memory VS Code project window. Use for renderer OOM, extension-host OOM, high swap, oversized local AI histories, generated/build residue, or excessive workspace indexing. Targets one explicit workspace and never touches other windows or production.'
argument-hint: 'Absolute workspace path, optionally with the exact window or session ID'
user-invocable: true
disable-model-invocation: true
---

# VS Code Crash Recovery

Use this workflow only when explicitly invoked. The bundled monitor is read-only
and may recommend this skill, but it never performs remediation.

## Non-Negotiable Safety

1. Require one absolute workspace path. Resolve its repository and window before
   attributing any process, transcript, cache, or build output.
2. Start with metadata only: file sizes/counts/timestamps, process RSS, RAM,
   swap, workspace ownership, tracking, ignore rules, and open handles.
3. Do not open, attach, decode, summarize, or visually inspect images.
4. Do not read transcript bodies or large logs. Read only a small workspace
   sidecar or a transcript's first metadata record when ownership requires it.
5. Do not run broad content searches across `$HOME`, `.git`, dependencies,
   build output, assets, caches, or session histories.
6. Never kill, reload, or modify another VS Code window or its agents. Do not
   use global process/cache cleanup while other projects are active.
7. Never access production services or data during local crash recovery.
8. Preserve tracked assets. A generated-looking file is not disposable until
   tracking, ignore, recency, active-writer, and reproducibility checks pass.
9. More than 100 files is a Yellow bulk action. Immediately before applying it,
   state exact paths, file count, byte total, tracking/ignore evidence,
   recent-write count, active-process check, and reproducibility basis.
10. Never rewrite an active/recent AI session or the session performing the
    audit. Back up any changed transcript and validate every JSONL record.
11. Never use destructive Git recovery, global cache deletion, or broad process
    termination as a shortcut.
12. Do not build, test, launch simulators/emulators, or generate assets until
    memory pressure is controlled. Small syntax checks are allowed.

## Fast Read-Only Check

Resolve the bundled script relative to this skill and run:

```bash
bash scripts/vscode-health-check.sh --no-notify
```

It reports host pressure, oversized VS Code renderer/plugin processes, and VS
Code Chat transcripts over 128 MiB. It does not map a process to a workspace;
use `code --status` before attributing or acting on it.

## Phase 1: Host And Window Ownership

Run, in order:

```bash
vm_stat
sysctl vm.swapusage
ps -axo pid=,ppid=,rss=,etime=,command= | sort -k3 -nr | head -n 25
code --status
```

Map renderer, file-watcher, extension-host, language-server, browser/webview,
and agent PIDs to the named workspace. Do not infer ownership from RSS alone.
Record a baseline for the target window and host.

## Phase 2: Workspace Pressure

Read repository agent instructions and check ownership/coordination before any
write. Inventory only bounded candidate paths such as:

- repository `tmp`, QA preview, generated, cache, and ignored output trees
- Android `.gradle`, `.cxx`, `.kotlin`, and `build`
- iOS `build`, `Pods`, and project-specific DerivedData
- Expo caches, Node dependencies, Python virtualenvs and bytecode caches

For every cleanup candidate, collect:

```text
exact path | bytes | files | newest write | writes in 5m/24h | tracked count |
ignore rule | open handles | associated generator/build process
```

Do not descend into source assets merely because their directory name resembles
`cache` or `generated`.

Identify Java/JDT, Gradle build server, Kotlin daemon, Python/Pylance, TypeScript,
Codex, Claude, Copilot, Kimi, simulator, emulator, Expo, Metro, Xcode, and image
generation processes associated with the exact workspace.

## Phase 3: Local AI Histories

Audit sizes only for:

- VS Code Chat under the workspace hash identified by its small `workspace.json`
- Copilot agent/CLI using small workspace sidecars and exact session IDs
- Claude using its workspace-encoded project directory
- Codex using only the first `session_meta` record, plus exact generated-image
  cache metadata for one session ID
- Kimi using small workspace sidecars

Distinguish active/recent sessions from inactive ones using exact session ID,
mtime, live lock PID, open handles, and client process ownership. If a large
session is active, stop and tell the user to close that exact session or reload
only the affected workspace window.

## Phase 4: Repair Proven Causes

Prefer the smallest reversible action:

1. Add workspace-only watcher/search/Explorer exclusions for proven generated
   dependencies, builds, DerivedData, caches, `tmp`, and QA previews.
2. Keep tracked source assets visible. Do not use a blanket `assets`, `cache`,
   `generated`, or `build` exclusion without checking repository structure.
3. Disable unnecessary Java/Gradle/Python indexing only in the target workspace.
4. Clean ignored output only after all evidence in Phase 2 passes.
5. For an inactive oversized transcript, use exact client and session ID. Back
   up the original unchanged. Preserve message text, reasoning, encrypted fields,
   and metadata; replace only schema-typed image payloads when pruning is needed.
6. Remove an exact generated-image cache only when its finished session is
   proven to belong to the target workspace, or when it is a true orphan that
   cannot map to another resumable project.
7. Run only project-scoped build cleanup. Never use cross-project cleanup.

## Phase 5: Prevention

For the target repository:

- commit generated-only watcher/search/Explorer exclusions where appropriate
- use open-files-only language analysis when full indexing adds no value
- require bounded, attested JPEG previews for visual QA
- rotate after 20 previews or 128 MiB of session history
- document exact metadata-only dry-run and exact-path apply commands
- add focused tests for any cleanup or guard script changed

Do not install broad global exclusions that could hide another project's tracked
source. Keep global automation detection-only.

## Phase 6: Validation

After repair:

1. Run focused syntax/tests for the changed guard or cleanup surface.
2. Check editor diagnostics and `git diff --check`.
3. Re-measure target temp/output and transcript/cache sizes.
4. Confirm no tracked asset deletion was introduced.
5. Confirm no active generator/build process was disrupted.
6. Run the repository's project-scoped build cleanup, if one exists.
7. Reload or close/reopen only the affected workspace window when approved.
8. Remap its new PIDs and compare renderer/extension-host RSS, free RAM, and swap.

Report remaining active sessions or a renderer that requires a full window
close/reopen. Never claim memory recovery from disk cleanup alone.

## Optional Automatic Monitor

The companion monitor is detection-only and opt-in:

```bash
bash scripts/monitor-control.sh install
bash scripts/monitor-control.sh status
bash scripts/monitor-control.sh run
bash scripts/monitor-control.sh uninstall
```

It warns when a renderer exceeds 2 GiB, a plugin/extension host exceeds 1.5 GiB,
a VS Code Chat transcript exceeds 128 MiB, or low free RAM coincides with high
swap. It never maps ownership or takes action; invoke this skill for that work.
