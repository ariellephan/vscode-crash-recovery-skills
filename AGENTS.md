# Agent Guide

This repository publishes local macOS maintenance skills. Treat safety and
privacy as part of the public API.

- Never add real project names, user paths, session identifiers, transcripts,
  screenshots, credentials, account data, or generated assets.
- Never add whole-machine cleanup. Every action must resolve one workspace or
  project first.
- Keep `vscode-health-check.sh` metadata-only and notification-only.
- Keep `cleanup.sh` dry-run by default and require explicit `--apply`.
- Never signal a process without rechecking command, CWD, and sampled activity.
- Never add broad Git recovery, cache deletion, simulator shutdown, emulator
  shutdown, or transcript rewriting shortcuts.
- Use temporary synthetic fixtures and sparse files for tests.
- Run `bash tests/run.sh` and `git diff --check` before committing.
