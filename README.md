# Secrets Bridge

A distributed secrets control plane.

Secrets Bridge governs and synchronizes secrets across the providers you already use, adding approval workflows, RBAC, audit, provider inventory, and least-privilege agent execution on top of them. HashiCorp Vault and AWS Secrets Manager are supported today; Azure Key Vault and GCP Secret Manager are on the roadmap. Kubernetes and GitOps are covered too.

## The model

```text
Control Plane  =  decisions, workflow, metadata, audit, RBAC, jobs, status
Agent          =  least-privilege execution inside the target account / cluster
Providers      =  the actual secret values (source of truth)
```

The Control Plane never holds your secret values or broad provider access. A lightweight, outbound-only agent runs inside each target boundary and executes approved jobs locally with scoped credentials.

## Why

Developers need a safe way to request and update secrets without broad provider access. Security teams need approvals, separation of duties, and an audit trail. Platform teams need cross-provider sync with drift and conflict visibility. Secrets Bridge puts governance and synchronization in one platform.

## Repositories

| Repo | What it is |
|------|-----------|
| **core** | Shared Go module: provider connectors, sync engine, shared types |
| **api** | Control Plane API (Go + Fiber) |
| **worker** | Background workers (Go) |
| **agent** | Outbound-only execution agent (Go) |
| **controller** | Kubernetes operator + CRDs (GitOps) |
| **ui** | Dashboard SPA (React + TypeScript + Vite) |
| **charts** | Helm charts / deploy manifests |
| **docs** | Documentation site → secrets-bridge.io |

## Security principles

- No secret values in databases, caches, logs, API responses, or the frontend.
- Agents are outbound-only and least-privilege, with no database or cache dependency.
- Every privileged action is audited with a correlation ID.
- Provider access is scoped by account, project, environment, path, tag, or policy.

## Status

Secrets Bridge is a usable preview. The control plane, agent, worker, dashboard, Helm chart, and docs site are all live. Recent work:

- Multi-factor auth: TOTP and WebAuthn enrollment, step-up auth on Tier-2 operations, a login-time MFA gate, and Helm and docs packaging.
- Project navigation and non-prod direct reveal: environment classification (`kind=non_prod|prod`), policy-level access decisions, environment-id binding across the access-request lifecycle, the `secret.reveal.direct` permission, a "My Projects" tree in the SPA with a per-environment developer page, and operator docs for the environment model and policy templates.

`secrets-bridge/skills/PROGRESS.md` logs the work in order, with the load-bearing invariants of each merged PR called out.

Still pre-v1.0: the platform is being hardened before a tagged release. See the per-repo READMEs and the [docs site](https://secrets-bridge.io/) for what's shipped and what's next.
