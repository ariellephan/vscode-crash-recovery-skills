# VS Code Crash Recovery Skills

Two safety-first, harness-neutral [Agent Skills](https://agentskills.io/) for
diagnosing and reducing VS Code memory pressure on macOS.

[![Tests](https://github.com/ariellephan/vscode-crash-recovery-skills/actions/workflows/test.yml/badge.svg)](https://github.com/ariellephan/vscode-crash-recovery-skills/actions/workflows/test.yml)
[![skills.sh](https://skills.sh/b/ariellephan/vscode-crash-recovery-skills)](https://skills.sh/ariellephan/vscode-crash-recovery-skills)

## Included Skills

| Skill | Purpose | Invocation |
| --- | --- | --- |
| `vscode-crash-recovery` | Metadata-first diagnosis for renderer/extension-host OOM, oversized local chat histories, workspace indexing, and generated residue | Manual only; selector varies by harness |
| `cleanup-builds` | Inventory and optionally stop idle Gradle daemons associated with one project | Manual only; dry-run by default |

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
- An Agent Skills-compatible harness

The scripts use only macOS system tools. There is no package manager, telemetry,
or network dependency.

## Install

Clone the repository. For the broadest compatibility, install to the generic
Agent Skills directory used by Copilot, Codex, Kimi Code, and other clients:

```bash
git clone https://github.com/ariellephan/vscode-crash-recovery-skills.git
cd vscode-crash-recovery-skills
bash install.sh generic
```

Claude Code requires its personal directory separately:

```bash
bash install.sh claude
```

The installer refuses to overwrite an existing skill. It copies by default; use
`--link` to keep multiple harness directories synchronized with one stable
checkout.

Supported destinations:

| Argument | Destination |
| --- | --- |
| `generic`, `agents`, or `codex` | `~/.agents/skills/` |
| `copilot` | `~/.copilot/skills/` |
| `claude` | `~/.claude/skills/` |
| `kimi` | `~/.kimi/skills/` |
| `kimi-code` | `~/.kimi-code/skills/` for compatible existing clients |
| `config-agents` | `~/.config/agents/skills/` |
| `custom /absolute/path` | Any harness-defined Agent Skills directory |
| `all` | Every named personal destination after complete collision preflight |

Examples:

```bash
bash install.sh --link generic
bash install.sh custom /absolute/repository/.agents/skills
```

See [Harness Compatibility](docs/HARNESS_COMPATIBILITY.md) for official paths
and invocation syntax for Copilot, Claude, Codex, Kimi Code, and custom clients.

Start a new chat or reload the intended VS Code window after installation so the
client refreshes skill discovery.

## Marketplaces And Discovery

### skills.sh

Install or inspect the open-standard skills with:

```bash
npx skills add ariellephan/vscode-crash-recovery-skills
```

### Claude Code

This repository is a Claude plugin marketplace:

```bash
claude plugin marketplace add ariellephan/vscode-crash-recovery-skills
claude plugin install vscode-crash-recovery-skills@vscode-health-skills
```

### OpenAI Codex

This repository is also a Codex plugin marketplace:

```bash
codex plugin marketplace add ariellephan/vscode-crash-recovery-skills
codex plugin list
```

The public OpenAI Plugins Directory has a separate human review process. The
repository includes the required skill-only plugin manifest and public
[privacy policy](PRIVACY.md) and [terms](TERMS.md) for that submission.

### GitHub Copilot And VS Code

The source repository can be installed directly with Copilot CLI:

```bash
copilot skill add https://github.com/ariellephan/vscode-crash-recovery-skills
```

Marketplace review status is tracked in the repository documentation after a
submission is opened with the Awesome Copilot community catalog.

## Optional Monitor

The monitor is not enabled by the installer. Resolve the skill directory through
your harness, then run:

```bash
/bin/bash <skill-directory>/scripts/monitor-control.sh install
/bin/bash <skill-directory>/scripts/monitor-control.sh status
/bin/bash <skill-directory>/scripts/monitor-control.sh run
/bin/bash <skill-directory>/scripts/monitor-control.sh uninstall
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
/bin/bash <skill-directory>/scripts/vscode-health-check.sh --no-notify
```

The monitor reads process metadata, `vm_stat`, `vm.swapusage`, transcript file
sizes, and VS Code's small `workspace.json` sidecar. It does not open transcript
bodies. It stores only the latest local result and a notification digest under
`~/Library/Caches/vscode-health-monitor/`.

## Project-Scoped Build Cleanup

Dry run:

```bash
/bin/bash <skill-directory>/scripts/cleanup.sh --root /absolute/project/path
```

Apply only after confirming that project is idle:

```bash
/bin/bash <skill-directory>/scripts/cleanup.sh --root /absolute/project/path --apply
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
