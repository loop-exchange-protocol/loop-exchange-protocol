# LXP v1alpha1 conformance requirements

**English** | [中文主版本](conformance.md)

This document defines language-neutral evidence required for a `loop.exchange/v1alpha1` implementation to claim conformance. It does not replace the [specification](spec-v1alpha1.en.md) or Schemas. Public-alpha profiles and vectors carry no compatibility promise, and the current scope accepts trusted Artifacts only.

## Profiles

| Profile | Required behavior | Minimum evidence |
|---|---|---|
| `artifact-core` | envelope, manifest/lock, SHA-256, safe normalized paths, a unique and nestable lexical root tree, contract-mismatch failure | positive and negative canonical-YAML tests; nested/duplicate-root coverage; rejection of digest/size mismatch, absolute paths, parent traversal, links, and special archive entries |
| `tracking-core` | Init/Import, longest-root Add/Status routing, nested ownership exclusions, parent-to-child Import, child-to-parent Export, and parent provenance | black-box CLI/API tests; nested discovery, child routing, symlink/non-empty collisions, unowned paths blocking Export, and one Session discovered through symlinked physical-path aliases |
| `provider-CONTRACT` | Match, Plan, Resolve, Materialize/Restore, Add/Status, ExportComponent, and supported distributions | Provider contract suite; unknown contracts and unsupported distributions fail; Provider config and payloads remain opaque to Core; external-operation cancellation/deadlines and non-interactive credentials |
| `requirements-core` | Plan/checklist, dependency DAG, explicit executable/MCP policy, and credential-handle isolation | missing, ambiguous, and cyclic Requirements; unauthorized execution; secrets absent from files, locks, payloads, argv, and logs |
| `standalone-portability` | restore from an embedded Artifact after deleting exporter state and original sources, then continue to another generation | destructive two-generation Export/Import Harness; identical Provider-selected bytes/state; empty directories and safe symlinks only when claimed by the contract |
| `production-git-v1` | official CLI composes `git@v1` only; supports reference/embedded/mirrored, recursive submodule Components, index selection, minimal HEAD bundles, and parent advancement | automatic parent/child/grandchild initialization after a plain parent clone; parent submodule config and recursive `git submodule status` consistency after Import/discovery without network access during config-only init; all three submodule distributions; offline embedded/mirrored child restore; strict gitlink/child-revision validation; symmetric 256 MiB staged-patch limit; rejection of unsafe initialization/unregistered submodules, secret/local locators, invalid staged indexes, shallow repositories, escaping symlinks, and extra payload roles; LFS pointer mode never executes filters |

An implementation claims only the Profiles it actually passes. An Artifact-codec-only library cannot claim `tracking-core`; a Provider declares `provider-CONTRACT` together with its exact contract version. A Production MVP release claims all five base Profiles, instantiating `provider-CONTRACT` as `provider-git-v1`, plus `production-git-v1`; the public CLI must provide end-to-end evidence for all three distributions.

## Canonical vectors

- [`examples/artifact/manifest.yaml`](../examples/artifact/manifest.yaml) and [`lock.yaml`](../examples/artifact/lock.yaml) are readable canonical exchange vectors.
- [`examples/distributions/`](../examples/distributions/README.en.md) provides reference/mirrored manifest and lock structure vectors; the specification repository does not commit their large payloads.
- [`examples/submodules/`](../examples/submodules/README.en.md) shows path-derived parent/child topology, independent payloads, and the gitlink/child-revision invariant.
- [`examples/quickstart/run.sh`](../examples/quickstart/run.sh) is a two-generation black-box journey consumable by SDKs and CLIs, not a normative source for one language implementation.
- [`schemas/v1alpha1/`](../schemas/v1alpha1/) defines structural constraints. Passing Schema validation is necessary but insufficient for conformance.

A third-party report records the implementation version, claimed Profiles, Provider contracts, vector version, platform, and failures. It cannot omit failing cases or count Agent guesses, implicit migration, or exporter-local fallback as success.
