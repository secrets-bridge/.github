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
| [**core**](https://github.com/secrets-bridge/core) | Shared Go module — provider connectors, sync engine, shared types |
| [**api**](https://github.com/secrets-bridge/api) | Control Plane API (Go + Fiber) |
| [**worker**](https://github.com/secrets-bridge/worker) | Background workers (Go) |
| [**agent**](https://github.com/secrets-bridge/agent) | Outbound-only execution agent (Go) |
| [**controller**](https://github.com/secrets-bridge/controller) | Kubernetes operator + CRDs (GitOps) |
| [**ui**](https://github.com/secrets-bridge/ui) | Dashboard SPA (React + TypeScript + Vite) |
| [**charts**](https://github.com/secrets-bridge/charts) | Helm charts / deploy manifests |
| [**docs**](https://github.com/secrets-bridge/docs) | Documentation site → [secrets-bridge.io](https://secrets-bridge.io) |

## Security principles

- No secret values in databases, caches, logs, API responses, or the frontend.
- Agents are outbound-only and least-privilege, with **no database or cache dependency**.
- Every privileged action is audited with a **correlation ID**.
- Provider access is scoped by account, project, environment, path, tag, or policy.

---

🚧 **Status:** actively refactoring from a Kubernetes sync controller (v0.1.0) into the full control plane platform.
