---
name: cleanup-builds
description: 'Reclaim macOS memory from idle Gradle daemons associated with one explicit project. Use after builds/tests or when VS Code is under memory pressure. Dry-run by default, requires --apply to signal a revalidated candidate, and has no whole-machine mode.'
argument-hint: 'Optional absolute project root; omit to resolve from the current directory'
user-invocable: true
---

# Cleanup Builds

This workflow inventories and optionally stops idle Gradle daemons associated
with one project. It never stops simulators, emulators, or another project's
processes. There is no whole-machine mode.

## Safety Contract

1. Run from the intended project or pass its absolute path with `--root`.
2. Run the default dry run first and review every candidate.
3. Apply only when no build/test is active in that project.
4. The script rechecks PID command, CWD, and sampled CPU time before `TERM`.
5. Never substitute broad process matching, simulator shutdown, emulator
   shutdown, or cross-project daemon cleanup.
6. Report before/after free RAM and swap plus stopped/kept counts.

## Dry Run

Resolve the bundled script relative to this skill, then run:

```bash
bash scripts/cleanup.sh
```

An explicit project root is also supported:

```bash
bash scripts/cleanup.sh --root /absolute/project/path
```

## Apply

After checking that the project is idle:

```bash
bash scripts/cleanup.sh --root /absolute/project/path --apply
```

For iOS or Android, shut down only the exact simulator/emulator started by the
current task using its device identifier. That is intentionally outside this
script.
