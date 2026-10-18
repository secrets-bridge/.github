# Releasing Secrets Bridge

All repos release together under **one shared version**: `core`, `api`, `worker`, `agent`, `controller`, `ui` and `charts` are tagged `vX.Y.Z` at the same time, so `api:0.1.0`, `agent:0.1.0` and chart `0.1.0` are known to work together. A repo with no changes still gets the tag.

Versions follow [SemVer](https://semver.org/). Before `1.0.0`, a minor bump (`0.2.0`) may break compatibility and a patch bump (`0.1.1`) never does. A prerelease is `vX.Y.Z-rc.N`.

## What a tag does

A tag must be strict semver and point at a commit on `main`, or the workflow stops before publishing anything.

| Repo | On `vX.Y.Z` |
|---|---|
| `api`, `worker`, `agent`, `controller`, `ui` | Multi-arch image `ghcr.io/secrets-bridge/<repo>:X.Y.Z` (plus `X.Y` and `latest` for a final release, not for a prerelease), with an SPDX SBOM and SLSA provenance attached, signed with cosign (keyless). Then a GitHub Release with the tag's CHANGELOG section, the image digest and the verify commands. `worker` builds against `api` at the same tag. |
| `core` | Builds and tests the tagged commit, creates the GitHub Release and publishes the version to the Go module proxy. |
| `charts` | Both charts as OCI artifacts at version `X.Y.Z` with `appVersion: X.Y.Z`, signed with cosign, after checking every image they default to exists. Then a GitHub Release with both chart digests. |

Pushes to `main` keep publishing `:dev`, `:main`, `:sha-<short>` images and `X.Y.Z-dev.<sha>` charts, signed the same way.

## Release steps

1. **Prepare**, in normal PRs:
   - In every repo with a `CHANGELOG.md`, move `[Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` and start a new empty `[Unreleased]`.
   - In `charts`, set `version: X.Y.Z` in both `secrets-bridge/Chart.yaml` and `agent/Chart.yaml`. Leave `appVersion: "dev"`; the tag build sets it.
2. **Check**: `scripts/release-check.sh X.Y.Z` from this repo. It reads every repo through the API and lists what blocks the release: red or running CI on `main`, a missing CHANGELOG section, chart versions, the `core` pin in `agent` and `controller`, a tag that already exists.
3. **Tag `core`** from `main`'s head, then bump it in `agent` and `controller` (`go get github.com/secrets-bridge/core@vX.Y.Z && go mod tidy`) and merge those PRs. Run the check again.
4. **Tag the rest** in the order the check prints: `api`, then `worker`, `agent`, `controller`, `ui`, and `charts` last. Wait for each repo's publish and release jobs before the next step: `worker` needs the `api` tag, and `charts` needs every image.
5. **Verify** each release page, then the artifacts (below), then install the charts at `X.Y.Z` in a sandbox and run the smoke test.

Tag with an annotated, signed tag from `main`'s head:

```bash
git -C <repo> fetch origin
git -C <repo> tag -s vX.Y.Z -m vX.Y.Z origin/main
git -C <repo> push origin vX.Y.Z
```

For a dry run, release `vX.Y.Z-rc.1` the same way (the chart versions become `X.Y.Z-rc.1` too). Prereleases never move `latest`.

## Verifying a release

Images and charts are signed by the workflow that built them:

```bash
cosign verify ghcr.io/secrets-bridge/api:0.1.0 \
  --certificate-identity https://github.com/secrets-bridge/api/.github/workflows/docker-publish.yml@refs/tags/v0.1.0 \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

cosign verify ghcr.io/secrets-bridge/charts/secrets-bridge:0.1.0 \
  --certificate-identity https://github.com/secrets-bridge/charts/.github/workflows/chart-publish.yml@refs/tags/v0.1.0 \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

docker buildx imagetools inspect ghcr.io/secrets-bridge/api:0.1.0 --format '{{ json .Provenance }}'
docker buildx imagetools inspect ghcr.io/secrets-bridge/api:0.1.0 --format '{{ json .SBOM }}'
```

Each release page carries these commands with the exact digest. Pin by digest in production, as the charts already require.

## Tags never move

A published tag is never moved, deleted or reused, even for a bad release. Images and charts are pulled by version and digest, so moving a tag would change what people already run. If a release is broken, add a note to its GitHub Release and ship `X.Y.Z+1`.

The rulesets in [`rulesets/`](rulesets/) enforce this on every repo: only repository admins can create `v*` tags, and nobody can update or delete one. Apply them with:

```bash
for r in core api worker agent controller ui charts; do
  for f in rulesets/release-tags-*.json; do
    gh api --method POST "repos/secrets-bridge/$r/rulesets" --input "$f"
  done
done
```

## Security fixes

A security fix ships as a patch release of every repo (`X.Y.Z+1`) as soon as it merges. Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md), never in a public issue.
