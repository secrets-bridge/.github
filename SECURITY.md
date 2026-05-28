# Security Policy

## Reporting a vulnerability

Secrets Bridge is a secrets governance platform — security issues are taken seriously and triaged ahead of normal work.

**Please do not open a public GitHub issue for security reports.**

Use **GitHub Security Advisories** (private disclosure):

→ <https://github.com/secrets-bridge/core/security/advisories/new>

Or any of the other component repos' "Security" tab if the issue is component-specific (`api`, `agent`, `controller`, `worker`, `ui`, `charts`, `docs`).

Include:

- The repository and component affected.
- The vulnerability class (e.g. authn bypass, value leak, privilege escalation, audit gap).
- A minimal reproduction (steps, configuration, and expected vs. observed behavior).
- The version / commit you tested against.
- Any suggested remediation, if you have one.

You will receive an acknowledgement within **3 business days**.

## What's in scope

- Any code in the `secrets-bridge` GitHub organization.
- The published container images, Helm charts, and binary releases.
- The documentation site at <https://secrets-bridge.io>.

## What's out of scope

- Vulnerabilities in upstream dependencies — please report to the upstream first, then notify us if it affects Secrets Bridge.
- Issues that require already-compromised credentials (e.g. a stolen Vault root token, a stolen AWS access key) as the attack precondition.
- Provider-side configuration mistakes (e.g. an over-broad IAM policy on the user's side).

## Disclosure timeline

- **Day 0:** report received.
- **Within 3 business days:** acknowledgement.
- **Within 14 days:** triage outcome (accepted / out-of-scope / needs more info).
- **Within 90 days:** fix shipped, or a coordinated disclosure date agreed with the reporter.

We follow **coordinated disclosure** — the reporter and the maintainers agree on a public disclosure date once the fix is available. Credit is given in the release notes unless the reporter prefers to remain anonymous.

## Hardening guidance

- Run the Secrets Bridge **Agent**, not Central Connector Mode, in production.
- Scope provider credentials to the smallest path / namespace / tag possible.
- Enable audit-log export to an append-only sink.
- Keep the agent and controller up to date with the latest patch release.
