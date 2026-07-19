# VS Code Crash Recovery Skills

Two safety-first agent skills for diagnosing and reducing VS Code memory pressure
on macOS.

[![Tests](https://github.com/ariellephan/vscode-crash-recovery-skills/actions/workflows/test.yml/badge.svg)](https://github.com/ariellephan/vscode-crash-recovery-skills/actions/workflows/test.yml)

## Included Skills

| Skill | Purpose | Invocation |
| --- | --- | --- |
| `vscode-crash-recovery` | Metadata-first diagnosis for renderer/extension-host OOM, oversized local chat histories, workspace indexing, and generated residue | Manual only: `/vscode-crash-recovery /absolute/workspace/path` |
| `cleanup-builds` | Inventory and optionally stop idle Gradle daemons associated with one project | `/cleanup-builds /absolute/project/path` |

The crash-recovery skill includes an optional five-minute macOS monitor. The
monitor only detects and notifies; it never reloads windows, signals processes,
rewrites transcripts, deletes files, or accesses network services.

## Safety Defaults

- One explicitly resolved workspace or project at a time.
- Metadata before content: sizes, counts, timestamps, RSS, RAM, swap, ownership,
  tracking, ignore rules, and open handles.
- No transcript-body reads, image decoding, or broad home-directory searches.
- No destructive Git commands or global cache deletion.
- No cross-project process cleanup.
- Build cleanup is a dry run unless `--apply` is supplied.
- Build cleanup has no whole-machine mode and never manages simulators/emulators.
- More than 100 files requires an explicit bulk-action inventory before removal.
- Active/recent AI sessions and the session performing an audit are never
  rewritten.

## Requirements

- macOS
- Bash 3.2 or newer
- VS Code with the `code` command available for full window attribution
- Agent Skills support in GitHub Copilot, Claude, or another compatible client

The scripts use only macOS system tools. There is no package manager, telemetry,
or network dependency.

## Install

Clone the repository and choose one personal skills directory:

```bash
git clone https://github.com/ariellephan/vscode-crash-recovery-skills.git
cd vscode-crash-recovery-skills
bash install.sh copilot
# or: bash install.sh claude
# or: bash install.sh agents
```

The installer refuses to overwrite an existing skill. Review and remove or
rename an older installation yourself before upgrading.

Supported destinations:

| Argument | Destination |
| --- | --- |
| `copilot` | `~/.copilot/skills/` |
| `claude` | `~/.claude/skills/` |
| `agents` | `~/.agents/skills/` |
| `all` | All three destinations, after a complete collision preflight |

Start a new chat or reload the intended VS Code window after installation so the
client refreshes skill discovery.

## Optional Monitor

The monitor is not enabled by the installer. From the installed
`vscode-crash-recovery` skill directory:

```bash
bash scripts/monitor-control.sh install
bash scripts/monitor-control.sh status
bash scripts/monitor-control.sh run
bash scripts/monitor-control.sh uninstall
```

Default warning thresholds:

- renderer RSS: 2 GiB
- plugin/extension-host RSS: 1.5 GiB
- VS Code Chat transcript: 128 MiB
- host pressure: less than 8 GiB free RAM while swap is at least 80% used

Thresholds can be overridden for a one-shot check with environment variables:

```bash
VSCODE_HEALTH_RENDERER_MIB=3072 \
VSCODE_HEALTH_CHAT_MIB=192 \
bash scripts/vscode-health-check.sh --no-notify
```

The monitor reads process metadata, `vm_stat`, `vm.swapusage`, transcript file
sizes, and VS Code's small `workspace.json` sidecar. It does not open transcript
bodies. It stores only the latest local result and a notification digest under
`~/Library/Caches/vscode-health-monitor/`.

## Project-Scoped Build Cleanup

Dry run:

```bash
bash scripts/cleanup.sh --root /absolute/project/path
```

Apply only after confirming that project is idle:

```bash
bash scripts/cleanup.sh --root /absolute/project/path --apply
```

A candidate is signaled only if its command still identifies a Gradle daemon,
its current working directory remains inside the resolved project root, and its
CPU time is unchanged across the configured sample.

## Development

Run all focused tests on macOS:

```bash
bash tests/run.sh
```

The tests use temporary fixtures and sparse files. They do not signal a process,
install a LaunchAgent, inspect a real transcript, or touch a project cache.

## License

MIT. See [LICENSE](LICENSE).
