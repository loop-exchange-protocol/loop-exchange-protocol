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
- LXP owns routing; Providers own content. Component roots are prefix-free and opaque to Core.
- `lxp add` inside a Component routes to its owning Provider and never creates a nested Component.
- Providers use stable `provider + contract` identity; Provider config and payloads are opaque to Core.
- Artifacts carry no executable Provider code; unknown or mismatched contracts fail.
- Exchange state contains logical identities and SHA-256 payloads, never local materialization or Provider Store paths.
- A standalone embedded Artifact imports without original sources or exporter Engine state.
- Secrets never enter manifests, locks, payloads, argv, or logs. Executable and MCP actions require explicit authorization.
- Unowned, non-ignored paths block Export. Git-untracked content is never exported silently.
- Conversations may continue; execution replay is unsupported.

`v1alpha1` is a public alpha with no compatibility promise and is limited to trusted Artifacts. Validation, digest verification, and execution policy are not a complete security boundary for hostile input.

The Production MVP is a constrained specification subset: the official composition includes `git@v1` only, the public CLI is limited to `init/add/status/export/import/inspect/requirements`, and it accepts embedded `.lxpz` Artifacts only. `Plan` is internal Import preflight; File/Filesystem Providers, reference/mirrored distribution, and Template repositories are outside the production claim.
