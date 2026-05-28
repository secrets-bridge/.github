# Contributing to Secrets Bridge

Thanks for taking the time to contribute. These rules apply to every repo in the [`secrets-bridge`](https://github.com/secrets-bridge) organization. Per-repo `CONTRIBUTING.md` files (if present) layer on top of this one.

## Ground rules

- **One repo, one task at a time.** Confirm which component you're touching (`core`, `api`, `worker`, `agent`, `controller`, `ui`, `charts`, `docs`) before starting work.
- **Branch off `main`.** Use a descriptive branch name: `feat/short-description`, `fix/short-description`, `docs/short-description`, `ci/short-description`, `chore/short-description`.
- **Conventional commits.** Commit messages follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) — `feat:`, `fix:`, `docs:`, `chore:`, `ci:`, `refactor:`, `test:`, etc. Use `!` or `BREAKING CHANGE:` for breaking changes.
- **Open a pull request.** Push your branch and open a PR against `main`. Fill in the PR template.
- **Never merge or approve your own PR.** `main` is protected on every repo; the maintainer (or a designated reviewer) merges.
- **No force-push to `main`.** Force-push is allowed on your own feature branches during review iteration.

## Local checks before opening a PR

Each Go repo should be green on:

```bash
go mod tidy   # leaves go.mod / go.sum unchanged
go build ./...
go vet ./...
go test -race -count=1 ./...
golangci-lint run
```

The `core` CI runs the same four jobs; other repos add `helm lint` or `mkdocs build --strict` as appropriate.

## Architectural rules (hard)

These are enforced in review. Violations block merge.

- **No secret values** anywhere except inside a `GetValue` / `PutValue` call. Specifically: not in PostgreSQL, not in Redis, not in logs, not in API responses, not in error messages, not in audit events, not in the browser.
- **`core` is infra-free.** No Postgres driver, no Redis client, no provider root credentials. Importable by every other Go service.
- **`agent` and `controller` import only `core/providers` + `core/sync`.** Never `api/pkg/storage` or `api/pkg/runtime`. The agent has no database or cache dependency.
- **Control Plane has no broad provider access by default.** Agent Mode is the default; Central Connector Mode must be opt-in.
- **Every workflow-changing action emits an audit event** with a correlation ID.
- **API / worker / UI are stateless** and horizontally scalable. Durable state lives in Postgres; short-lived coordination in Redis.

## Reporting security issues

**Do not open a public issue.** See [SECURITY.md](SECURITY.md).

## Code of Conduct

This project follows the [Contributor Covenant 2.1](CODE_OF_CONDUCT.md). By participating you agree to its terms.

## License

By contributing, you agree your work will be licensed under the same license as the repository you're contributing to (see each repo's `LICENSE`).
