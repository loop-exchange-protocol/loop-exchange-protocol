# Go SDK and CLI Guide

**English** | [中文主版本](go-engine.md)

The official Go Production MVP composes [`go-sdk`](https://github.com/loop-exchange-protocol/go-sdk) with [`go-provider-git`](https://github.com/loop-exchange-protocol/go-provider-git). SDK Core embeds no concrete Provider; the official CLI injects `git@v1` only. This page is non-normative guidance; the [Production MVP Profile](production-mvp.en.md) defines the claim.

```bash
lxp init work
git clone YOUR_REPOSITORY work/source
cd work

# Select the Git state to exchange after making changes.
lxp add source/PATH...
lxp status
lxp export --distribution mirrored ../context.lxpz

cd ..
lxp inspect context.lxpz
lxp requirements --format json context.lxpz
lxp import context.lxpz continued
```

## Add and Status

On first Add of an unowned path, Engine searches upward for a Git root. After matching `source/.git`, it registers all of `source` as one Component and passes the relative path to `git add --`. Paths inside that Component always return to the Git Provider and never create nested Components.

Status shows Component roots, Git porcelain changes, unowned paths, and ignored paths. Git-untracked content is Provider state: Core does not register another Component for it, and Export never includes it silently. An unowned, non-ignored top-level path blocks Export.

## Export and Import

`lxp export --distribution` supports `reference`, `embedded`, and `mirrored`, defaulting to embedded when omitted. `lxp import` needs no distribution flag and follows the Artifact manifest automatically. A successful Export advances the Session parent, so the next Artifact records `provenance.parent` automatically.

Embedded uses a minimal Git bundle for the current `HEAD` plus an optional staged binary patch; Import does not contact the original remote and restores Git index selection. Reference uses a safe network locator plus full commit ID. Mirrored tries the same-revision reference first, cleans any partial target when its source is unavailable, and restores the embedded base. Reference and mirrored require an index matching `HEAD` and cannot transport a staged patch.

For portable behavior, the Git Provider rejects shallow repositories, submodules/gitlinks, and escaping symlinks; embedded also rejects clean/smudge filters. Reference/mirrored LFS pointer mode never executes filters, and external LFS objects do not enter the Artifact. Artifact output never overwrites an existing path; an Import target must not exist and a failed Import removes the new target.

## Choosing a distribution

Use the embedded default for ordinary checkpoints, reference for large public repositories, and mirrored when remote identity and source-outage recovery both matter. See the [Distribution guide](distributions.en.md) for complete rules and YAML, and the [`go-provider-git` Spring AI + MCP Harness](https://github.com/loop-exchange-protocol/go-provider-git/tree/main/harness/spring-ai-mcp) for public-CLI validation with four real repositories.

## Requirements and trust boundary

`lxp requirements` does not materialize the Artifact. It checks executable, MCP, and credential contracts, and its TUI persists only a local non-secret policy profile. Executable and MCP probes require explicit authorization. Credentials persist local binding names only; values never enter Artifacts, locks, argv, or logs.

The Production MVP accepts Artifacts within one trust domain only. Path, digest, and contract validation provide fail-closed integrity, not a hostile-input sandbox.
