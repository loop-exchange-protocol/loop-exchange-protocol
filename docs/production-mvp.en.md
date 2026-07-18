# LXP Production MVP Profile

**English** | [中文主版本](production-mvp.md)

This document defines the first minimal LXP Profile suitable for a real team workflow. It is a restricted subset of `loop.exchange/v1alpha1` and does not broaden the security claim.

## Operating boundary

The Production MVP targets engineering teams and automation inside one trust domain: Artifact publishers, Importers, the installed CLI, and Providers are trusted. It guarantees fail-closed behavior, content integrity, offline restoration, and a traceable linear parent chain, but does **not** treat LXP as a hostile-input sandbox.

## One working loop

```text
Init → Add/Status → Export → Import → Work → Add/Status → Export …
```

The public CLI is frozen to:

```text
lxp init [WORKDIR]
lxp add PATH...
lxp status [--format text|json]
lxp export [--distribution reference|embedded|mirrored] ARTIFACT.lxpz
lxp import ARTIFACT.lxpz [WORKDIR]
lxp inspect ARTIFACT.lxpz
lxp requirements [--format tui|json] ARTIFACT.lxpz
```

`Plan` remains an internal Provider preflight contract used by Import, not a separate user command. Before any materialization or activation, Import validates the Artifact, matches exact contracts, displays Provider actions, and checks Requirements.

## Provider and content scope

- The official composition contains `git@v1` only; there is no implicit File/Filesystem fallback.
- The current `git@v1` implementation requires a preinstalled, trusted Git CLI. This is a Provider installation prerequisite, not an executable carried by the Artifact.
- `lxp add` and Export fail when an unowned path has no matching Provider.
- One Git repository is one opaque Component root; Core creates no nested Component inside it.
- Conversations, Skills, results, and other context enter an MVP Artifact only when stored in a Git-managed repository and selected through the Git index.
- The protocol retains third-party Provider extension points, but they are outside this Profile's production claim.

## Artifact Profile

- Production Export supports `reference`, `embedded`, and `mirrored`, defaulting to `embedded`; Import follows each Component declaration in the Artifact.
- The official CLI accepts `.lxpz` archives only. Logical `.lxp` directories remain part of the generic wire model, not this Profile's public entry point.
- Reference carries a safe network locator and full commit ID and requires its source during Import. Mirrored carries a reference plus an embedded fallback at the identical revision and tries the reference first.
- Embedded and mirrored fallbacks carry a Git bundle limited to history reachable from the current `HEAD`; only embedded may include a staged binary patch.
- Embedded and mirrored restore after exporter state and source repositories are deleted. Reference fails and cleans its target when the source is unavailable.
- Embedded Git index selection remains staged after Import. Reference and mirrored require the index to match `HEAD` at Export. Git-untracked and unselected tracked changes do not enter the Artifact.
- Artifact identity is the SHA-256 of the exact `manifest.yaml` bytes; coordinates are human-readable labels, not identity.
- Every successful Export advances the current Session parent digest; the next manifest references it.

`git@v1` Production Export rejects shallow repositories, submodules/gitlinks, and escaping symlinks. Embedded rejects clean/smudge filters. Reference and mirrored may declare `lfs_mode: pointer`, exchange only canonical LFS pointers tracked in the Git tree, never execute filters, and do not promise external LFS objects.

## Failure and persistence guarantees

- Manifests, Session state, and profiles use same-directory temporary files followed by atomic rename. Archives are completed in a same-directory temporary file and then published atomically without clobbering an existing path.
- Existing Artifact outputs are never overwritten.
- An Import target must not exist; a failed Import removes the newly created target.
- Every payload is checked for SHA-256 and size before a Provider call; Providers validate payload roles and media types.
- Unknown Providers, contract mismatches, distribution mismatches, extra payload roles, Requirement failures, and non-portable Git features fail closed.
- A Session is single-writer. Callers serialize `add` and `export`; this Profile does not promise concurrent-writer coordination.

## Explicit non-goals

This Profile provides no remote Registry, coordinate install/resolve, Template-repository import, branch/merge/rebase, multi-parent history, multi-writer Sessions, submodule recursion, external Git LFS object exchange, automatic Provider installation, execution replay, or hostile-Artifact sandbox.

## Release gate

Before claiming the Production MVP, an implementation passes:

1. Go unit, race, and vet checks;
2. positive and negative Git Provider contract tests;
3. online/offline reference and mirrored-fallback Harnesses, plus a two-generation embedded Export/Import Harness after deleting exporter/source state;
4. digest, size, traversal, duplicate-entry, symlink, submodule, filter, and contract-mismatch tests;
5. consistency checks across bilingual specifications, Schemas, canonical YAML, HTML, and CLI help.
