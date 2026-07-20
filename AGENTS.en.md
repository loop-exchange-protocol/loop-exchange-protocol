# Agent Contract

**English** | [中文主版本](AGENTS.md)

This repository is the language-neutral specification source for LXP (Loop Exchange Protocol). Normative behavior lives in `docs/spec-v1alpha1.md` and `schemas/v1alpha1/`; implementations live in the Organization's SDK and Provider repositories.

## Required verification

```bash
make ci
```

`make ci` checks Schemas, canonical YAML, Shell, bilingual documents and links, SVG, stale terminology, and diff hygiene. Executable conformance Harnesses live in implementation repositories and consume this repository's specification and examples.

## Invariants

- The lifecycle is `Import → Work → Add/Status → Export`; every Export creates a new immutable Artifact.
- LXP owns routing and Providers own content. Component roots are unique and may form a strictly nested lexical tree; every entity path belongs only to its deepest root.
- `lxp add` routes to the deepest owning Provider. Native discovery may register nested Components; ancestor Providers exclude child subtrees and fail when composition is unsafe.
- Providers and Checkers use `namespace:name:version` contract coordinates that are globally unique across kinds. Artifacts declare contracts only; ordered consumer-local repositories and bindings resolve implementations and exactly verify the implementation package reported by builtin registration or a Helper handshake.
- Artifacts carry no executable Provider code; unknown or mismatched contracts fail. The Engine may execute local Helper argv or install a Helper by digest only from an operator-enabled OCI repository that trusts its namespace; it must handshake exactly, inherit deadlines, bound diagnostics, and close the process at command end. An Artifact cannot authorize installation or execution.
- Exchange state contains logical identities and SHA-256 payloads, never local materialization or Provider Store paths.
- A standalone embedded Artifact imports without original sources or exporter Engine state.
- An Artifact contains only its manifest and referenced content-addressed payloads; unknown files, orphan objects, and redundant `lock.yaml` are rejected. Secrets never enter manifests, payloads, argv, or logs. Executable and MCP Checks require explicit authorization.
- CLI/Provider external operations inherit a cancellable execution context with a deadline, never wait for interactive credentials, and bound diagnostic output.
- Unowned, non-ignored paths block Export. Git-untracked content is never exported silently.
- During `lxp add`, `loop.exchange:git:v1` initializes each missing submodule at its gitlink-locked revision and recursively registers it as an independent nested Component; it never advances an initialized submodule to a newer remote revision. Import and discovery use config-only `git submodule init` to keep parent native config consistent with a restored child, without fetching or checking out content. Export validates gitlink/revision child-to-parent; Import Applies parent-to-child.
- Provider `Apply` is idempotent and retryable without Core rollback. A failed Import keeps local `importing` state and pinned extension resolution for the same Artifact, successful Components are not rolled back, and retrying a ready Session is a no-op.
- `loop.exchange:git:v1` applies the same 256 MiB embedded staged-patch limit at Export and Import; Export cannot create an Artifact this contract cannot restore.
- Conversations may continue; execution replay is unsupported.

`v1alpha1` is a public alpha with no compatibility promise and is limited to trusted Artifacts. Validation, digest verification, and execution policy are not a complete security boundary for hostile input.

The Production MVP is a constrained specification subset: the official default composition contains builtin Go `loop.exchange:git:v1` and provides an independent Git Helper as the standard extension example, with no multi-language SDK promise. The public CLI is limited to `init/add/status/export/import/inspect/requirements` and accepts `reference`, `embedded`, and `mirrored` `.lxpz` Artifacts. `lxp export --distribution` selects the form and defaults to `embedded`; Import follows the Artifact declaration. The Engine supports local Helpers and explicitly authorized OCI auto-installation, but provides no central Registry, global search, or Artifact-driven installation. File/Filesystem Providers and Template repositories remain outside the production claim.
