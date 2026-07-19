# Privacy Policy

Effective: July 18, 2026

VS Code Crash Recovery Skills is a local, open-source collection of Agent Skills
and shell scripts. It has no hosted service, account system, analytics SDK,
advertising, or network API.

## Local Data Access

When explicitly invoked, the skills may inspect local metadata needed to diagnose
memory pressure, including:

- process identifiers, commands, CPU time, and resident memory
- free memory and swap usage
- file paths, sizes, counts, timestamps, tracking state, ignore rules, and open
  handles
- small workspace sidecars or the first metadata record of a local agent session

The skills instruct agents not to inspect transcript bodies, decode images,
access production systems, or search unrelated projects. The optional monitor
stores only its latest health summary and a notification digest under
`~/Library/Caches/vscode-health-monitor/`.

## Data Transmission

The bundled scripts do not transmit local metadata or file contents. Cloning,
installing, or updating through GitHub, skills.sh, an agent marketplace, or a
package manager is governed by that service's privacy policy and is outside the
runtime behavior of these scripts.

## Retention And Deletion

Local monitor state can be removed by uninstalling the monitor and deleting
`~/Library/Caches/vscode-health-monitor/`. Transcript backups, when a user
explicitly authorizes transcript remediation, remain local at the path reported
by the invoking agent and should be removed only by the user after review.

## Contact

Open a privacy or security report through the repository's GitHub issue or
private security-advisory flow:
https://github.com/ariellephan/vscode-crash-recovery-skills
