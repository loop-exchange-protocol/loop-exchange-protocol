# Go SDK and CLI Guide

**English** | [中文主版本](go-engine.md)

The official Go Production MVP composes [`go-sdk`](https://github.com/loop-exchange-protocol/go-sdk) with [`go-provider-git`](https://github.com/loop-exchange-protocol/go-provider-git). SDK Core embeds no concrete Provider; the official CLI injects `git@v1` only. This page is non-normative guidance; the [Production MVP Profile](production-mvp.en.md) defines the claim.

```bash
go install github.com/loop-exchange-protocol/go-sdk/cmd/lxp@latest
```

The CLI is an independent `cmd/lxp` Go module whose release tags use `cmd/lxp/vX.Y.Z`. The module requires released SDK and Provider versions and contains no `replace` directive that would block `go install ...@latest`.

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

On first Add of an unowned path, Engine searches upward for a Git root. After matching `source/.git`, it registers all of `source` as one Component and passes the relative path to `git add --`. The Git Provider also reads gitlinks from the index: a missing submodule contacts its locator, checks out the gitlink-locked commit, and is recursively registered one level at a time as a nested Git Component; an initialized child is not updated automatically. Ordinary paths route to the deepest root; the parent repository maintains only the gitlink boundary.

Status shows Component roots, Git porcelain changes, unowned paths, and ignored paths. Git-untracked content is Provider state: Core does not register another Component for it, and Export never includes it silently. An unowned, non-ignored top-level path blocks Export.

## Export and Import

`lxp export --distribution` supports `reference`, `embedded`, and `mirrored`, defaulting to embedded when omitted. `lxp import` needs no distribution flag and follows the Artifact manifest automatically. A successful Export advances the Session parent, so the next Artifact records `provenance.parent` automatically.

Embedded uses a minimal Git bundle for the current `HEAD` plus an optional staged binary patch; Import does not contact the original remote and restores Git index selection. Export and Import apply the same 256 MiB limit to the uncompressed staged `diff.patch`, and an oversized Export fails before Artifact publication. Reference uses a safe network locator plus full commit ID. Mirrored tries the same-revision reference first, cleans any partial target when its source is unavailable, and restores the embedded base. Reference and mirrored require an index matching `HEAD` and cannot transport a staged patch.

For portable behavior, the Git Provider rejects shallow repositories, submodules that cannot be initialized safely or remain unregistered, gitlink/child-revision mismatch, cross-symlink nested roots, and escaping symlinks; embedded also rejects clean/smudge filters. A submodule is an independent Component and the parent bundle contains no child objects; Import restores parent to child and Export validates child to parent. Reference/mirrored LFS pointer mode never executes filters, and external LFS objects do not enter the Artifact. Artifact output never overwrites an existing path; an Import target must not exist and a failed Import removes the new target.

For an existing submodule, use a plain clone and Add the parent root once; `git@v1` initializes recursive submodules automatically:

```bash
git clone YOUR_REPOSITORY source
lxp add source
```

Automatic initialization checks out only the commit currently locked by each gitlink; it is not `git submodule update --remote`. A symlink/non-empty target collision, unavailable locator, or failed checkout fails Add.

CLI external operations have a 15-minute timeout by default; override it with a positive Go duration such as `LXP_TIMEOUT=30m`. Every Git child process inherits that Context, while the Provider applies a five-minute default when an SDK caller supplies no deadline. Git terminal/askpass/GCM interactive prompts are disabled, so authentication must already be available from a non-interactive credential helper or SSH agent.

Session and CLI paths resolve existing symlink prefixes to physical absolute paths before local comparisons. Initializing under `/var/...` on macOS and later working through `/private/var/...` therefore identifies one Workdir without a `TMPDIR` workaround.

After changing a child repository, `lxp add source/PATH/IN/SUBMODULE` selects the child index. After the child produces a new commit, `lxp add source/PATH/TO/SUBMODULE` lets the child Provider process its root and synchronizes the parent index gitlink.

## Choosing a distribution

Use the embedded default for ordinary checkpoints, reference for large public repositories, and mirrored when remote identity and source-outage recovery both matter. See the [Distribution guide](distributions.en.md) for complete rules and YAML, and the [`go-provider-git` Spring AI + MCP Harness](https://github.com/loop-exchange-protocol/go-provider-git/tree/main/harness/spring-ai-mcp) for public-CLI validation with four real repositories.

## Requirements and trust boundary

`lxp requirements` does not materialize the Artifact. It checks executable, MCP, and credential contracts, and its TUI persists only a local non-secret policy profile. Executable and MCP probes require explicit authorization. Credentials persist local binding names only; values never enter Artifacts, locks, argv, or logs.

The Production MVP accepts Artifacts within one trust domain only. Path, digest, and contract validation provide fail-closed integrity, not a hostile-input sandbox.
