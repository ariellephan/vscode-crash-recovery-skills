# Contributing

Contributions are welcome when they preserve the repository's safety boundary.

## Before Opening A Pull Request

1. Keep all behavior scoped to one explicitly resolved project or workspace.
2. Keep the monitor detection-only and free of network access.
3. Keep build cleanup dry-run by default and require explicit `--apply`.
4. Do not add whole-machine process, simulator, emulator, cache, or history
   cleanup.
5. Do not add real workspace paths, project names, session IDs, transcript
   content, screenshots, credentials, or generated user assets to fixtures.
6. Use synthetic metadata and sparse files in tests.
7. Run:

```bash
bash tests/run.sh
```

## Pull Request Notes

Explain the safety impact, exact validation commands, supported macOS versions,
and any new process or filesystem access. Changes that broaden scope or make
cleanup automatic should be rejected.
