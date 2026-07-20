# LXP — Loop Exchange Protocol

[中文](README.md) | **English**

LXP is an open exchange protocol for agent work context. It uses a Git-like mental model: import immutable state, modify and select changes in a Workdir, then export a new Artifact linked to its parent.

```text
Import → Work → Add/Status → Export → Import …
```

LXP is not a deployment template, package installer, or command workflow. YAML is a machine exchange format; the daily entry point is the `lxp` CLI.

![LXP architecture](assets/lxp-architecture.svg)

![LXP lifecycle](assets/lxp-lifecycle.svg)

## What Git-like means

- `lxp import` reconciles an Artifact into a working Session; the same command retries failed state.
- `lxp add PATH...` delegates selection to the deepest owning Provider; Git uses its index.
- `lxp status` aggregates ownership and Provider-native changes.
- `lxp export` reads selected state and creates a new immutable Artifact.
- `provenance.parent` links the previous manifest digest into linear history. v1alpha1 defines no branch, merge, or rebase.

LXP owns ownership; Providers own content. Component roots are unique and may form a strictly nested lexical tree. Each entity belongs to its deepest root and a parent excludes child subtrees. The protocol defines no symlink/copy/mount capability matrix; unsafe composition fails closed.

## Artifacts and extensions

An Artifact contains only:

```text
manifest.yaml
objects/sha256/<hex>
```

There is no `lock.yaml`, and unknown files or orphan objects not referenced by the manifest are rejected. The manifest already fixes revisions, distributions, and payload digests. Artifact identity is the SHA-256 of validated raw `manifest.yaml` bytes; no YAML canonicalization is performed.

Providers and Checkers use `namespace:name:version` contract coordinates that are globally unique across kinds, such as `loop.exchange:git:v1`. An Artifact declares contracts only and carries no implementation package, repository URL, executable, or installation hook. Local [EngineConfig](examples/config/README.en.md) binds a builtin, local Helper argv, or a Helper installed by digest from an explicitly authorized OCI repository; the process uses an exact, language-neutral [Helper protocol](docs/extensions.en.md) handshake. The official CLI retains a builtin Git Provider by default and also supplies an independent Git Helper. An Artifact cannot authorize download or execution.

The protocol is language-neutral, but the project maintains one official Go reference implementation and promises no multi-language SDK matrix:

- [`lxp`](https://github.com/loop-exchange-protocol/lxp): SDK, Engine, and CLI;
- [`provider-git`](https://github.com/loop-exchange-protocol/provider-git): `loop.exchange:git:v1`.

## Production MVP

The official composition contains only the Git Provider and fully supports reference, embedded, and mirrored `.lxpz`, defaulting to embedded. `lxp add` initializes a missing submodule at its gitlink-locked revision and recursively registers an independent Component without following newer remote revisions. Import Applies parent-to-child and preserves child roots while rebuilding a parent; Export validates gitlink/revision child-to-parent.

Before Component writes, Import validates the Artifact, resolves all Providers/Checkers, checks consumed Requirements, and calls every Provider `Validate`. On Apply failure Core preserves the target and `importing` state with pinned extension resolution instead of global rollback. The same Artifact continues with the same implementations; retrying a ready Session is a no-op.

## Quick experience

```bash
go install github.com/loop-exchange-protocol/lxp/cmd/lxp@latest
LXP_BIN="$(command -v lxp)" examples/quickstart/run.sh
```

Or run the short path manually:

```bash
lxp init demo
cd demo
git clone YOUR_REPOSITORY source
# Select only the Git changes to exchange
lxp add source/PATH
lxp export ../review-loop.lxpz

cd ..
lxp import review-loop.lxpz continued
```

## Documentation

- [v1alpha1 specification](docs/spec-v1alpha1.en.md) · [中文](docs/spec-v1alpha1.md)
- [Production MVP](docs/production-mvp.en.md) · [中文](docs/production-mvp.md)
- [Go Engine and CLI](docs/go-engine.en.md) · [中文](docs/go-engine.md)
- [Requirements/Checkers](docs/requirements.en.md) · [中文](docs/requirements.md)
- [Distributions](docs/distributions.en.md) · [中文](docs/distributions.md)
- [Conformance](docs/conformance.en.md) · [中文](docs/conformance.md)
- [Ecosystem repositories](docs/ecosystem.en.md) · [中文](docs/ecosystem.md)
- [Quickstart](examples/quickstart/README.en.md) · [中文](examples/quickstart/README.md)
- [Artifact YAML](examples/artifact/README.en.md) · [中文](examples/artifact/README.md)
- [EngineConfig YAML](examples/config/README.en.md) · [中文](examples/config/README.md)
- [ContextArtifact Schema](schemas/v1alpha1/context-artifact.schema.json)
- [EngineConfig Schema](schemas/v1alpha1/engine-config.schema.json)
- [Extension Package Schema](schemas/v1alpha1/extension-package.schema.json)
- [Helper Message Schema](schemas/v1alpha1/helper-message.schema.json)
- [HTML overview](dist/import-export-protocol.html)

## Alpha and security boundary

`loop.exchange/v1alpha1` is a public alpha with no compatibility promise and is limited to trusted Artifacts. Schema checks, safe paths, digest verification, and explicit execution policy are defense in depth, not a complete hostile-input boundary.

```bash
make ci
```
