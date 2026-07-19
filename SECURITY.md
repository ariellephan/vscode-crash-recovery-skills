# Security Policy

## Reporting

Report security issues through GitHub's private security-advisory flow for this
repository. Do not post credentials, private workspace paths, transcript
contents, session identifiers, or personal data in a public issue.

## Safety Boundary

These skills are local macOS maintenance tools. They must not access production
services, transmit telemetry, inspect transcript bodies, decode images, perform
cross-project cleanup, or expose a whole-machine process mode.

The optional monitor is detection-only. Build cleanup is project-scoped,
dry-run by default, and requires explicit `--apply` before signaling a
revalidated Gradle daemon candidate.
