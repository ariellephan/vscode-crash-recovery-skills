# Harness Compatibility

The skill payloads follow the open [Agent Skills specification](https://agentskills.io/).
They use standard `SKILL.md` frontmatter, relative resource links, and portable
shell scripts. No workflow depends on a Claude-, Copilot-, Codex-, or Kimi-only
environment variable.

## Personal Installation

| Harness | Discovery directory | Installer target | Explicit invocation |
| --- | --- | --- | --- |
| GitHub Copilot in VS Code or CLI | `~/.copilot/skills/` or `~/.agents/skills/` | `copilot` or `generic` | `/vscode-crash-recovery` |
| Claude Code | `~/.claude/skills/` | `claude` | `/vscode-crash-recovery` |
| OpenAI Codex CLI/IDE | `~/.agents/skills/` | `codex` or `generic` | Select with `/skills` or mention `$vscode-crash-recovery` |
| Kimi Code CLI | `~/.kimi/skills/`, `~/.config/agents/skills/`, or `~/.agents/skills/` | `kimi`, `config-agents`, or `generic` | `/skill:vscode-crash-recovery` |
| Existing Kimi Code clients using the legacy local root | `~/.kimi-code/skills/` | `kimi-code` | Client-specific skill selector |
| Any Agent Skills-compatible harness | Harness-defined skills directory | `custom /absolute/path` | Harness-specific selector |

`generic` is the best first choice for cross-harness use because Copilot, Codex,
and Kimi Code all discover `~/.agents/skills/`. Claude Code requires its own
`~/.claude/skills/` location.

## Project Installation

For repository-scoped sharing, install or copy both skill directories into the
project's `.agents/skills/` directory:

```bash
bash install.sh custom /absolute/repository/.agents/skills
```

Copilot, Codex, and Kimi Code discover `.agents/skills/`. Claude Code's official
project path is `.claude/skills/`; install there too when Claude-specific project
discovery is required.

## Copy Versus Link

The installer copies by default. To keep multiple harness locations synchronized
with one checkout, use links:

```bash
bash install.sh --link generic
bash install.sh --link claude
```

The installer performs a complete collision preflight and never overwrites an
existing skill. Keep the repository checkout at a stable path when using links.

## Invocation Policy

Both skills declare `disable-model-invocation: true` for clients that support the
field. Codex also receives `agents/openai.yaml` with
`allow_implicit_invocation: false`. Kimi Code does not currently document an
equivalent deterministic policy field, so each skill's description and first
instruction explicitly require a user request.

## Sources

- [Agent Skills specification](https://agentskills.io/specification)
- [GitHub Copilot Agent Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [OpenAI Codex skills](https://learn.chatgpt.com/docs/build-skills)
- [Kimi Code CLI skills](https://github.com/MoonshotAI/kimi-cli/blob/main/docs/en/customization/skills.md)
