# LXP Production MVP Profile

[中文](production-mvp.md) | **English**

This document defines the first deployable `loop.exchange/v1alpha1` subset. It targets engineering teams and automation inside one trust domain. It is not a hostile-input sandbox and carries no v1alpha1 compatibility promise.

## Work loop and CLI

```text
Init / Import → Work → Add/Status → Export → Import …
```

The public CLI is frozen to:

```text
lxp init [WORKDIR]
lxp add [--provider NAMESPACE:NAME:VERSION] PATH...
lxp status [--format text|json]
lxp export [--distribution reference|embedded|mirrored] ARTIFACT.lxpz
lxp import ARTIFACT.lxpz [WORKDIR]
lxp inspect ARTIFACT.lxpz
lxp requirements [--format tui|json] ARTIFACT.lxpz
```

Before any Component write, Import validates the complete Artifact, resolves every extension, checks consumed Requirements, and calls every Provider `Validate`; it then calls `Apply` parent-to-child. There is no public or internal Plan command, install, build, Activate, or Core rollback stage.

## Official implementation and extensions

- The official reference implementation is [`lxp`](https://github.com/loop-exchange-protocol/lxp), written in Go and containing the SDK, Engine, and CLI. The project promises no additional language SDKs.
- The only official content implementation is [`provider-git`](https://github.com/loop-exchange-protocol/provider-git), contract `loop.exchange:git:v1`. There is no File/Filesystem fallback.
- Providers and Checkers use `namespace:name:version` coordinates that are globally unique across kinds and declare exact implementation packages. Artifacts declare contracts only; local EngineConfig supplies ordered repositories and implementation bindings, every operation verifies the registered implementation, and Import retry pins its initial resolution.
- The official CLI executes only Go implementations declared as `source: builtin`. It parses repository config but does not automatically download or execute repository extensions. An Artifact can never override repository, mirror, trust, or installation policy.
- The Git Provider requires a trusted preinstalled Git CLI. This is a host prerequisite, not an executable carried by an Artifact.

## Git ownership and selection

Every Git repository is an independent Component. Conversations, Skills, results, and other context enter an Artifact only when stored in that repository and selected by the Git index. Add and Export fail when an unowned path has no Provider match.

`lxp add` discovers submodules from index gitlinks. A missing worktree is initialized one level at a time at the gitlink-locked commit and recursively registered as a nested `loop.exchange:git:v1` Component. An initialized child is never fetched or advanced implicitly to a newer remote revision. A path inside the child selects its index; selecting the child root synchronizes the parent gitlink.

The parent owns only `.gitmodules` and the gitlink boundary and never exports child objects. Import Applies parent-to-child. Config-only `git submodule init` idempotently repairs parent native config without fetching or checking out content, and a rebuilt parent root preserves declared child roots. Export runs child-to-parent and verifies that the selected parent gitlink equals the child locked revision. Symlinks, files, and collisions that cannot be safely owned fail.

## Artifact Profile

- The official CLI accepts `.lxpz` only; the generic wire model still permits a logical `.lxp` directory.
- An Artifact contains only `manifest.yaml` and `objects/sha256/<hex>`, with no `lock.yaml`. The SHA-256 of validated raw manifest bytes is identity, with no YAML canonicalization; coordinates are readable labels.
- Export supports `reference`, `embedded`, and `mirrored`, defaulting to `embedded`. Import follows each Component declaration automatically.
- Reference uses a safe network locator and full commit ID and depends on source availability. Mirrored reference/embedded revisions are identical; Import tries the reference first and uses fallback only for contract-defined recoverable errors.
- A Git bundle covers history reachable from current `HEAD` only. Embedded alone may carry a staged binary patch, and its index selection remains staged after Import. Reference/mirrored Export requires index equal to `HEAD`.
- Embedded and mirrored fallback remain recoverable after exporter state and original repositories are deleted. Git-untracked and unselected tracked changes never enter the Artifact.
- The uncompressed embedded `diff.patch` has the same 256 MiB Export/Import limit. Oversized Export fails before publication.
- Production Export rejects shallow repositories, unsafe or unregistered submodules, gitlink mismatch, escaping symlinks, and undeclared clean/smudge filters. Reference/mirrored may explicitly use `lfs_mode: pointer`, but external LFS objects are not carried.
- Every successful Export creates a new Artifact and uses the current manifest digest as the next generation's `provenance.parent`.

## Import retry and persistence

- A first target is absent or empty. Before Apply, Core atomically writes a local marker containing Artifact digest, Session ID, and `importing` state.
- Every Provider `Apply` is idempotent, retryable, revision-fixed, and limited to its own root. A parent preserves child roots.
- If a Component fails, Core keeps the target, completed observed state, and marker. It does not roll back successful Components or delete the target. The same command with the same Artifact and Session continues; a different Artifact or non-empty target without a marker fails.
- Once all Components succeed, Session state atomically becomes `ready`. Retrying the same Artifact against a ready Session is a no-op.
- Requirement observations are local `requirements.state.yaml`, not a portable lock, and never enter the Artifact.
- Manifest, Session, Requirement, and profile state use same-directory temporary files and atomic rename. Artifact archives are completed in a temporary file before no-clobber publication. Existing outputs are never overwritten.

## Runtime safety

- Every payload digest and size is verified before Provider calls. Providers validate payload roles, media types, and content contracts.
- Unknown or unbound Provider/Checker contracts, contract/distribution mismatch, extra payload roles, Requirement failure, and non-portable Git features fail closed.
- CLI external operations default to a 15-minute deadline, overridden by a positive Go duration in `LXP_TIMEOUT`. Git uses a five-minute default when its caller supplies none. Terminal, askpass, and Git Credential Manager interactive prompts are disabled.
- Local containment, Workdir, and Session discovery use physical absolute paths after resolving existing symlink prefixes, including macOS `/var` and `/private/var`. Physical paths never enter an Artifact.
- A Session is single-writer. Callers serialize writes; this Profile requires no process lock.

## Non-goals and release gate

This Profile does not provide automatic repository-extension installation, Template import, branch/merge/rebase, multi-parent history, multi-writer coordination, automatic remote-revision advancement, external Git LFS object exchange, execution replay, or hostile-Artifact sandboxing.

A release passes public Linux/macOS CI, Go unit/race/vet, Git Provider contract tests, all three distributions and recursive-submodule Harnesses, failed-Import retry and ready no-op, two-generation embedded round trips after exporter/source deletion, and digest/size/traversal/symlink/credential/cancellation/contract-mismatch tests. Bilingual docs, Schemas, YAML, SVG, HTML, and CLI help remain consistent.
