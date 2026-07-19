# LXP ecosystem repositories

[中文](ecosystem.md) | **English**

LXP uses a language-neutral specification, one official reference implementation, and domain-specific Providers—not a multi-language SDK matrix. Implementation language is a technical choice and does not enter repository or contract names.

GitHub Organization: [`loop-exchange-protocol`](https://github.com/loop-exchange-protocol).

```text
loop-exchange-protocol/
├── loop-exchange-protocol # specification, docs, Schemas, examples, Conformance
├── lxp                    # official Go SDK, Engine, and CLI
└── provider-git           # official Git Provider
```

## Repository boundaries

### loop-exchange-protocol

The sole language-neutral source for JSON Schemas, bilingual documentation, canonical YAML, diagrams, and Conformance requirements. It contains no implementation code and does not split documentation into a separate repository.

### lxp

The official reference implementation, currently written in Go. It contains types, Provider/Checker interfaces, Engine, Artifact codec, and `cmd/lxp`. It is no longer called `go-sdk`: the project promises no Java/Rust/Python SDK family, and this repository is more than an SDK.

### provider-git

Implements the global `loop.exchange:git:v1` contract and owns Git discovery, index selection, idempotent Apply, all three distributions, and submodule-boundary semantics. Its repository has no language prefix; Go is an implementation technology, not protocol identity.

The old `go-provider-local` repository is archived. File/Filesystem Providers are outside the Git-only Production MVP and no longer imply an official ecosystem commitment.

## Extension distribution and credit

A third-party Provider or Checker uses a global `namespace:name:version` contract and keeps credit, release cadence, and security responsibility in a domain-specific repository. An Artifact declares only contracts; consumer EngineConfig supplies repositories and contract-to-implementation bindings. The official CLI currently executes builtins only and does not auto-install repository packages.

Examples remain in the specification repository alongside their Schemas. Executable Harnesses live with implementations. A third-party implementation claims compatibility only after passing an applicable Conformance Profile. `v1alpha1` has no compatibility promise and is limited to trusted Artifacts.
