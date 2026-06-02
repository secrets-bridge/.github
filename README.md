# Secrets Bridge

**A distributed secrets control plane platform.**

Secrets Bridge governs and synchronizes secrets across **HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, GCP Secret Manager, and Kubernetes / GitOps** — adding approval workflows, RBAC, audit, provider inventory, and least‑privilege agent execution on top of the providers you already use.

## The model

```text
Control Plane  =  decisions, workflow, metadata, audit, RBAC, jobs, status
Agent          =  least-privilege execution inside the target account / cluster
Providers      =  the actual secret values (source of truth)
```

The Control Plane **never holds your secret values** or broad provider access. A lightweight, **outbound-only agent** runs inside each target boundary and executes approved jobs locally with scoped credentials.

## Why

Developers need a safe way to request and update secrets without broad provider access. Security teams need approvals, separation of duties, and an audit trail. Platform teams need cross‑provider sync with drift and conflict visibility. Secrets Bridge brings **governance and synchronization** together in one platform.

## Repositories

| Repo | What it is |
|------|-----------|
| **core** | Shared Go module — provider connectors, sync engine, shared types |
| **api** | Control Plane API (Go + Fiber) |
| **worker** | Background workers (Go) |
| **agent** | Outbound-only execution agent (Go) |
| **controller** | Kubernetes operator + CRDs (GitOps) |
| **ui** | Dashboard SPA (React + TypeScript + Vite) |
| **charts** | Helm charts / deploy manifests |
| **docs** | Documentation site → secrets-bridge.io |

## Security principles

- No secret values in databases, caches, logs, API responses, or the frontend.
- Agents are outbound-only and least-privilege, with **no database or cache dependency**.
- Every privileged action is audited with a **correlation ID**.
- Provider access is scoped by account, project, environment, path, tag, or policy.

## Status

The platform has reached a usable preview: the core control‑plane, agent, worker, dashboard, Helm chart, and docs site are all live. The work since the v0.1.0 sync controller has gone in slice-by-slice; recent ground covered:

- **MFA pivot (Slices H + I + J + K)** — TOTP + WebAuthn enrollment, step‑up auth on Tier‑2 ops, login‑time MFA gate, Helm value + docs packaging.
- **EPIC Slice L — Project navigation + non‑prod direct reveal** — first‑class environment classification (`kind=non_prod|prod`), policy‑level access decisions, env‑id binding across the access‑request lifecycle, new `secret.reveal.direct` permission, "My Projects" SPA tree + per‑env dev page, operator docs for the env model + policy templates.

`secrets-bridge/skills/PROGRESS.md` is the slice‑by‑slice log; each merged PR has an entry with the load‑bearing invariants called out.

🚧 Still pre‑v1.0 — the platform is being hardened before a tagged release. See the per‑repo READMEs + the [docs site](https://secrets-bridge.io/) for what's shipped and what's next.
