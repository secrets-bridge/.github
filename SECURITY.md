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
- **KMS backend:** never run `SB_KMS_BACKEND=local` in production. Use `vault-transit` or `aws-kms`. `local` is for `docker compose` dev only — it holds the master key in process memory.
- **Wire-envelope encryption:** configure the agent's persistent X25519 keypair via `SB_AGENT_PRIVATE_KEY_FILE` (mounted K8s Secret) or `SB_AGENT_PRIVATE_KEY` (env). Avoid ephemeral mode in production — sealed wraps addressed to a since-restarted agent become unrecoverable.
- **Transit:** keep `SB_INSECURE_TRANSPORT` UNSET (defaults to `false`). Pin the CP's CA via `SB_CP_CA_FILE` when running behind a private CA.
- **Agent identity rotation:** the agent's long-lived secret should be rotated periodically. Document and implement a rotation procedure for your deployment.
- **ArgoCD integration (BRD §26):** opt-in via `SB_GITOPS_ENABLED=true`. When enabling, scope the ArgoCD account RBAC to exactly the verbs listed in BRD §26.7 — no write verbs of any kind. The integration's `readOnlyTransport` rejects non-GET requests in process, but a leaked write-capable token used outside Secrets Bridge would still be dangerous.
- **Audit log export:** the `audit_events` table is append-only at the schema level (`BEFORE UPDATE/DELETE` triggers). Defense in depth: ship rows to an append-only sink (S3 Object Lock, CloudWatch with delete protection, SIEM) so a DBA with `superuser` cannot defeat the trigger and then erase the audit trail.
- **Network policy:** the CP API + worker + Postgres + Redis form a single trust boundary. Restrict that boundary with K8s NetworkPolicy. Agents reach the CP API over outbound HTTPS only; Redis + Postgres MUST NOT be reachable from agent-side networks.
- **Container images:** verify signatures (`cosign verify`) before deploying. Reproducible-build provenance lands with v1.0 (SLSA Level 2 minimum).
- Keep the agent, controller, api, and worker up to date with the latest patch release. Subscribe to GitHub Security Advisories per repo.

## Cryptographic primitives in use

For reviewers who want to verify the choices:

| Layer | Algorithm | Library |
|---|---|---|
| Wire-envelope CP→Agent | X25519 ECDH + HKDF-SHA256 + AES-256-GCM | Go stdlib `crypto/ecdh` + `golang.org/x/crypto/hkdf` + `crypto/aes` |
| Wire-envelope Agent→CP | KMS-issued DEK + AES-256-GCM | Same `crypto/aes`; DEK from `KeyManager` |
| Storage envelope | AES-256-GCM with KMS-wrapped DEK | `KeyManager` backend (local/vault-transit/aws-kms) |
| Identity hashes | SHA-256 with `crypto/subtle.ConstantTimeCompare` | Go stdlib |
| Audit `correlation_id` | UUID v4 | `github.com/google/uuid` |
| Token / secret material | 32 bytes from `crypto/rand.Read` | Go stdlib |
| TLS | TLS 1.2+ (1.3 preferred) | Go stdlib `crypto/tls` |

All algorithms above are FIPS 140-3 approved when implemented correctly. The Go stdlib implementations are constant-time on architectures with AES-NI (x86-64, arm64).

## Known limitations (documented in the security review)

- **No forward secrecy** for the CP→Agent wire-envelope: the agent's X25519 private key is static. An attacker who later steals the key can decrypt captured ciphertexts from the past. Mitigation: periodic agent keypair rotation; the agent re-registers its public key on each restart.
- **`LocalKMS` is dev-only.** Defaults must NOT use it in production deployments. See hardening guidance above.
- **The `audit_events` schema trigger can be defeated by a DB superuser** (`DROP TRIGGER` + UPDATE). Use a separate append-only audit sink for defense in depth.
- **Authentication / authorization** for end users is under active development. Pre-v1.0 builds MUST NOT be exposed to untrusted networks.

A detailed living document tracking findings + remediation is maintained internally (`secrets-bridge/skills/SECURITY_REVIEW.md`). Major findings are referenced in CHANGELOG entries and the `docs/` site.
