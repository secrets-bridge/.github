<p align="center">
  <img src="logo.svg" alt="Secrets Bridge" width="640" />
</p>

<h2 align="center">Access control for the secrets you already keep.</h2>

<p align="center">
  Secrets Bridge governs who may use the secrets your team keeps in <b>AWS Secrets Manager</b> or <b>HashiCorp Vault</b>.<br/>
  It adds access requests, approvals, RBAC, audit and agent execution around them. The values stay in your provider.<br/>
  <b>Azure Key Vault</b> and <b>GCP Secret Manager</b> are on the roadmap.
</p>

<p align="center">
  <a href="https://secrets-bridge.io/latest/">Documentation</a> ·
  <a href="https://secrets-bridge.io/latest/overview/product-status/">Product status</a> ·
  <a href="https://secrets-bridge.io/latest/operations/docker-compose/">Run it locally</a> ·
  <a href="https://secrets-bridge.io/latest/overview/architecture/">Architecture</a>
</p>

---

## The model

```text
Control plane       =  requests, approvals, RBAC, policy, audit, jobs and metadata
Agent               =  runs inside your account or cluster, executes approved jobs, only connects out
Gateway (optional)  =  read-only observation inside your boundary: did the change roll out?
Provider            =  the secret values (the source of truth)
```

We keep requests, approvals and audit metadata. We don't keep your secret values: an agent inside your infrastructure reads and writes them with its own credentials and connects out to the control plane, so you open no inbound port.

The optional Gateway also runs inside your boundary and only connects out. Release 1 reads Argo CD Application state, never Secrets, and reports metadata-only evidence that a change reached the workloads. External Secrets Operator and Deployment rollout observation are planned for Release 2.

## Why

Developers need a safe way to ask for and update secrets without broad provider access. Security teams need approvals, separation of duties and an audit trail. Secrets Bridge adds those around the providers you already use instead of replacing them.

## Repositories

| Repo | What it is |
|------|-----------|
| [**core**](https://github.com/secrets-bridge/core) | Shared Go module: provider connectors, sync engine, shared types |
| [**api**](https://github.com/secrets-bridge/api) | Control Plane API (Go + Fiber) |
| [**worker**](https://github.com/secrets-bridge/worker) | Background workers (Go) |
| [**agent**](https://github.com/secrets-bridge/agent) | Outbound-only, least-privilege execution agent (Go) |
| [**gateway**](https://github.com/secrets-bridge/gateway) | Optional, outbound-only, read-only observation plane: Argo CD rollout evidence in Release 1 (Go) |
| [**controller**](https://github.com/secrets-bridge/controller) | Kubernetes operator + CRDs for SecretsSync (GitOps) |
| [**ui**](https://github.com/secrets-bridge/ui) | Dashboard SPA (React + TypeScript + Vite) |
| [**charts**](https://github.com/secrets-bridge/charts) | Helm charts / deploy manifests |
| [**docs**](https://github.com/secrets-bridge/docs) | Documentation site: [secrets-bridge.io](https://secrets-bridge.io/latest/) |

## Security principles

- No secret values in plain text in the control plane: not in Postgres, Redis, logs, API responses or audit events. A value in transit exists only as a KMS-wrapped, single-use wrap with a short lifetime.
- Agents are outbound-only and least-privilege, with no database or cache dependency.
- The Gateway is read-only and has no access to Kubernetes Secrets. It refuses to start if it can read them.
- Production environments never allow direct reveal. The refusal is enforced in code and audited.
- Every privileged action is audited with a correlation ID.
- Provider access is scoped by account, project, environment, path, tag, or policy.

## Brand

<p align="center">
  <img src="icon.svg" alt="Icon · Control Plane" width="120" />
  &nbsp;&nbsp;&nbsp;
  <img src="favicon.svg" alt="Favicon · App" width="80" />
  &nbsp;&nbsp;&nbsp;
  <img src="mascot.svg" alt="Bridgey, the Secrets Bridge mascot" width="120" />
</p>

<p align="center"><sub>Wordmark · icon set · favicon · <b>Bridgey</b> the mascot, all in <a href="./"><code>profile/</code></a>. Canonical design source: the Secrets Bridge brand file in Figma.</sub></p>

---

Status: open source and pre-1.0. The control plane, agent, worker, dashboard, Helm charts and docs site are live; Gateway Release 1 (Argo CD) is in progress. [Product status](https://secrets-bridge.io/latest/overview/product-status/) lists what is live, QA-certified, in progress and on the roadmap.
