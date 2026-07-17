# LXP v1alpha1 conformance requirements

**English** | [中文主版本](conformance.md)

This document defines language-neutral evidence required for a `loop.exchange/v1alpha1` implementation to claim conformance. It does not replace the [specification](spec-v1alpha1.en.md) or Schemas. Public-alpha profiles and vectors carry no compatibility promise, and the current scope accepts trusted Artifacts only.

## Profiles

| Profile | Required behavior | Minimum evidence |
|---|---|---|
| `artifact-core` | envelope, manifest/lock, SHA-256, safe normalized paths, prefix-free roots, contract-mismatch failure | positive and negative canonical-YAML tests; rejection of digest/size mismatch, absolute paths, parent traversal, links, and special archive entries |
| `tracking-core` | Init/Import, Add/Status routing, ownership, Export checkpoints, and parent provenance | black-box CLI/API tests; Add inside a Component returns to its owning Provider; unowned paths block Export |
| `provider-CONTRACT` | Match, Plan, Resolve, Materialize/Restore, Add/Status, ExportComponent, and supported distributions | Provider contract suite; unknown contracts and unsupported distributions fail; Provider config and payloads remain opaque to Core |
| `requirements-core` | Plan/checklist, dependency DAG, explicit executable/MCP policy, and credential-handle isolation | missing, ambiguous, and cyclic Requirements; unauthorized execution; secrets absent from files, locks, payloads, argv, and logs |
| `standalone-portability` | restore from an embedded Artifact after deleting exporter state and original sources, then continue to another generation | destructive two-generation Export/Import Harness; identical Provider-selected bytes/state; empty directories and safe symlinks only when claimed by the contract |
| `production-git-v1` | official CLI composes `git@v1` only, embedded-only exchange, index-selection round trip, minimal HEAD bundle, and parent advancement | rejection of reference/mirrored, shallow repositories, submodules, filters, escaping symlinks, and extra payload roles; failed Import target cleanup |

An implementation claims only the Profiles it actually passes. An Artifact-codec-only library cannot claim `tracking-core`; a Provider declares `provider-CONTRACT` together with its exact contract version. A Production MVP release claims all five base Profiles, instantiating `provider-CONTRACT` as `provider-git-v1`, plus `production-git-v1`.

## Canonical vectors

- [`examples/artifact/manifest.yaml`](../examples/artifact/manifest.yaml) and [`lock.yaml`](../examples/artifact/lock.yaml) are readable canonical exchange vectors.
- [`examples/quickstart/run.sh`](../examples/quickstart/run.sh) is a two-generation black-box journey consumable by SDKs and CLIs, not a normative source for one language implementation.
- [`schemas/v1alpha1/`](../schemas/v1alpha1/) defines structural constraints. Passing Schema validation is necessary but insufficient for conformance.

A third-party report records the implementation version, claimed Profiles, Provider contracts, vector version, platform, and failures. It cannot omit failing cases or count Agent guesses, implicit migration, or exporter-local fallback as success.
