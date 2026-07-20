# LXP v1alpha1 conformance requirements

**English** | [中文主版本](conformance.md)

This document defines language-neutral evidence required for a `loop.exchange/v1alpha1` implementation to claim conformance. It does not replace the [specification](spec-v1alpha1.en.md) or Schemas. Public-alpha profiles and vectors carry no compatibility promise, and the current scope accepts trusted Artifacts only.

## Profiles

| Profile | Required behavior | Minimum evidence |
|---|---|---|
| `artifact-core` | manifest/referenced-payload-only envelope, SHA-256, safe normalized paths, unique/nestable lexical roots, and cross-kind global contract coordinates | positive/negative canonical YAML; rejection of redundant `lock.yaml`, unknown files, orphan objects, digest/size mismatch, duplicate roots, absolute/traversal/link/special entries |
| `tracking-core` | Init/Import, longest-root Add/Status, nested exclusions, parent-to-child idempotent Apply, child-to-parent Export, and parent provenance | black-box CLI/API; failed Import preservation with pinned implementation retry, ready no-op, different-Artifact, unmarked non-empty target, retry-time unowned-content rejection, and physical symlink aliases |
| `provider-CONTRACT` | Contract/Implementation, Match, Validate, idempotent/retryable Apply, Add/Status, ExportComponent, and distributions | exact global contract and implementation package; unknown/unbound/mismatched/duplicate registration failure; equivalent repeated Apply; no revision advance or child/unowned deletion; deadlines and non-interactive credentials |
| `requirements-core` | global Checker contracts, local binding, read-only Check, explicit executable/MCP policy, and credential isolation | unknown/unbound Checker and consumed failure; unauthorized execution; secrets absent from config/state/payload/argv/log; no install or Activate |
| `standalone-portability` | restore from an embedded Artifact after deleting exporter state and original sources, then continue to another generation | destructive two-generation Export/Import Harness; identical Provider-selected bytes/state; empty directories and safe symlinks only when claimed by the contract |
| `extension-helper-v1` | builtin/helper/repository bindings, OCI digest and platform package, exact process handshake, command-scoped lifecycle, and local trust | Helper Provider/Checker round trips; rejection of unknown source and identity/capability/protocol mismatch; no download for unauthorized namespaces; positive/negative OCI manifest/config/layer tests; offline cache reuse and corruption repair; cancellation, deadlines, bounded messages/diagnostics; no shell or Artifact authority |
| `production-git-v1` | official CLI composes builtin `loop.exchange:git:v1` by default and verifies the equivalent independent Helper; all distributions, recursive submodules, index selection, and minimal HEAD bundles | builtin/Helper round trips; exact handshake; parent/child/grandchild initialization; parent Apply retry preserves children; config-only init is offline; offline embedded/mirrored; strict gitlink checks; symmetric 256 MiB limit; rejection of unsafe submodules, secret/local locators, shallow repositories, escaping symlinks, filters, and extra roles |

An implementation claims only the Profiles it actually passes. An Artifact-codec-only library cannot claim `tracking-core`; a Provider declares `provider-CONTRACT` together with its exact contract version. A Production MVP release claims all six base Profiles, instantiating `provider-CONTRACT` as `provider-git-v1`, plus `production-git-v1`; the public CLI must provide end-to-end evidence for all three distributions.

## Canonical vectors

- [`examples/artifact/manifest.yaml`](../examples/artifact/manifest.yaml) is the readable canonical exchange vector.
- [`examples/config/`](../examples/config/README.en.md) is the local repository and contract-to-implementation binding vector.
- [`examples/distributions/`](../examples/distributions/README.en.md) provides reference/mirrored manifest structures; the specification repository does not commit their large payloads.
- [`examples/submodules/`](../examples/submodules/README.en.md) shows path-derived parent/child topology, independent payloads, and the gitlink/child-revision invariant.
- [`examples/quickstart/run.sh`](../examples/quickstart/run.sh) is a two-generation black-box journey consumable by SDKs and CLIs, not a normative source for one language implementation.
- [`schemas/v1alpha1/`](../schemas/v1alpha1/) defines structural constraints. Passing Schema validation is necessary but insufficient for conformance.

A third-party report records the implementation version, claimed Profiles, Provider contracts, vector version, platform, and failures. It cannot omit failing cases or count Agent guesses, implicit migration, or exporter-local fallback as success.
