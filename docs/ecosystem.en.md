# LXP ecosystem repositories

**English** | [中文主版本](ecosystem.md)

The specification, Schemas, authoritative documentation, examples, and conformance requirements stay together. SDKs publish per language; Providers publish by language and domain so releases, dependencies, and contributor credit remain clear.

GitHub Organization: [`loop-exchange-protocol`](https://github.com/loop-exchange-protocol).

```text
loop-exchange-protocol/
├── loop-exchange-protocol # sole spec, docs, Schemas, examples, conformance requirements
├── go-sdk                 # Go SDK, Engine, and official lxp CLI
├── go-provider-git        # Go Git Provider
└── go-provider-local      # experimental Go file@v1 and filesystem@v1 Providers
```

## Repository boundaries

### loop-exchange-protocol

Protocol text, JSON Schemas, authoritative Chinese and English documentation, canonical YAML, complete user journeys, and SDK-neutral conformance requirements. It contains no language-specific implementation, and documentation stays with the specification to prevent drift.

### go-sdk

Go types, Provider interfaces, Engine, and the official CLI. The CLI is the composition root for concrete Providers; SDK Core does not import them. A repository for another language is created only when that implementation exists.

### go-provider-git

Implements `git@v1`, owning Git discovery, selection, materialization, export, and restore semantics with an independent release and credit history.

### go-provider-local

Experimentally implements `file@v1` and `filesystem@v1`. They remain together because they share local-path, symlink, and archive safety rules; the official CLI does not inject them, and they are outside Production MVP conformance.

## Examples and conformance

Examples stay under this repository's `examples/`, synchronized with the specification and YAML they explain. SDK repositories may consume executable Harnesses, but `docs/conformance.en.md` and `schemas/` remain authoritative. A third-party implementation claims conformance only after passing the applicable profile.

A Provider Registry waits until third-party volume creates real discovery, signing, withdrawal, and version-governance needs. The public alpha does not maintain an empty registry shell.

A split must not duplicate the specification source. Implementation repositories only link to or consume a versioned specification; `loop.exchange/v1alpha1` promises no compatibility and currently accepts trusted Artifacts only.
