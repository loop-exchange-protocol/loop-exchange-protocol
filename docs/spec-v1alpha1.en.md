# LXP v1alpha1 Specification

**English** | [中文主版本](spec-v1alpha1.md)

Status: public alpha with no forward or backward compatibility promise. `MUST`, `MUST NOT`, `SHOULD`, and `MAY` follow RFC 2119. The first deployable subset is the [Production MVP Profile](production-mvp.en.md): trusted environments, official `git@v1`, and reference/embedded/mirrored `.lxpz` exchange.

## 1. Goal and lifecycle

LXP tracks and exchanges agent working context with a Git-like lifecycle:

```text
Import → Work → Add/Status → Export → Import …
```

Import creates a working Session from an immutable Artifact. Work changes materialized content. Add asks an owning Provider to select changes or registers a new ownership root. Status aggregates Core and Provider state. Export creates a new immutable Artifact.

A standard CLI SHOULD provide Git-like `init`, `import`, `add`, `status`, and `export`. Worktree-root `.lxp` is a local discovery/state directory that MUST NOT be exported and SHOULD be discovered from subdirectories. `import` creates a working Session from an Artifact; `export` is an immutable checkpoint of selected state.

LXP does not define deployment rendering, command workflows, model-output replay, hidden reasoning, external side effects, or in-flight operations. YAML is a machine exchange format, not the expected daily authoring interface.

## 2. Artifacts and history

A logical Artifact is a `.lxp` directory; `.lxpz` is its equivalent gzip tar envelope:

```text
manifest.yaml
lock.yaml
objects/sha256/<hex>
```

An Artifact has human-readable `namespace/name/version` coordinates. The SHA-256 digest of `manifest.yaml` is its immutable identity. A coordinate MUST NOT resolve to different bytes. `provenance.parent` MAY name the direct parent Artifact digest to form linear history. Branches, merges, rebases, and multiple parents are outside `v1alpha1`.

See the implementation-validated [manifest.yaml](../examples/artifact/manifest.yaml) and [lock.yaml](../examples/artifact/lock.yaml), together with the [ContextArtifact](../schemas/v1alpha1/context-artifact.schema.json) and [Artifact Lock](../schemas/v1alpha1/artifact-lock.schema.json) Schemas.

Before invoking a Provider, an Importer MUST validate archive paths, the manifest lock, and every payload digest and size. An archive MUST NOT contain absolute paths, parent traversal, links, devices, or other special entries.

## 3. Component ownership

A Component is a persistent content unit managed by a Provider and materialized at a Session-relative path.

```yaml
components:
  - id: source
    path: repositories/source
    provider: git
    contract: v1
    config: {}
    distribution: embedded
    embedded:
      revision: 0123456789abcdef0123456789abcdef01234567
      payloads:
        base:
          media_type: application/vnd.git.bundle
          digest: sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
          size: 123
```

Normative invariants:

- Component paths MUST be safe normalized relative paths outside local-only `.loop` and `.lxp`.
- Component roots MUST be unique. Roots MAY be strictly nested by normalized lexical path and therefore form an unambiguous ownership tree; symlink aliases cannot bypass that tree.
- Engine owns roots, identities, Provider routing, Requirements, and the exchange envelope.
- Except for declared direct child roots, a Component remains opaque to Core. Every entity path is owned by its deepest containing Component root. An ancestor Provider MUST exclude every direct child subtree and MUST fail when it cannot do so safely.
- Core MUST NOT standardize symlink, copy, mount, or Provider-pair compatibility, and local materialization capabilities MUST NOT enter the Artifact. Local Providers decide whether a parent and child can be composed physically and fail closed when they cannot.
- During Add, Core MAY invoke native child discovery on the owning Provider. A discovered child is registered as an independent Component; Core cannot guess unknown markers.
- Ordinary path operations route to the deepest owning Provider. A parent Provider may additionally maintain Provider-native attachment metadata such as a gitlink at the boundary, but cannot read or export child entity content.

## 4. Provider contract

Provider identity consists of a stable `provider` ID and `contract` version. Provider-specific `config` is opaque: Core MUST transport it faithfully and MUST NOT interpret its fields. Payload roles are likewise contract-defined.

A Provider contract contains `Match`, `Resolve`, `Materialize`, `Restore`, `Plan`, `Add`, `Status`, `Activate`, and `ExportComponent`. It MAY implement `DiscoverChildren` for initialized Provider-native direct child roots and `TrackChild` for parent boundary metadata after child selection. Plan exposes Requirements, actions, and security effects before execution. Add and Status implement native change-selection semantics.

Artifacts MUST NOT carry Provider executables, plugin binaries, or install hooks. Import MUST use a preinstalled, trusted, exactly matching contract and otherwise fail. Silent downgrade and Agent-inferred migration are forbidden.

Providers MAY materialize using symlinks, Git worktrees, copies, reflinks, mounts, or another local mechanism. LXP standardizes the semantic result at the declared path, not the mechanism. Local target paths, sockets, PIDs, ports, credential handles, and Provider Store paths MUST NOT enter an Artifact.

Core supplies a parent Provider with the relative roots and portable identities of its direct children. This runtime context exists only to exclude child subtrees or validate Provider-native attachments; it is not an Artifact mount-capability DSL. A Provider that cannot compose a concrete path safely MUST fail during Plan, Import, or Export.

## 5. Add and discovery

`lxp add PATH...` follows ownership routing:

1. Inside the deepest existing Component, first invoke its Provider's native child discovery. If no deeper root matches, invoke that Component Provider's `Add`.
2. At an unowned root, or at a deeper root returned by discovery, invoke trusted Providers' `Match`, register the unique match, then invoke `Add`.
3. With no match, fail; Core never guesses or implicitly installs a fallback Provider.
4. Multiple matches fail and require explicit selection.

Discovery markers matter only during initial registration. `.git` matches `git@v1`; third-party markers such as `.oss` are contract-defined. The Artifact manifest is the only portable routing truth after registration.

`.lxpignore` uses gitignore patterns only for unowned roots and cannot alter Provider-internal tracking. Export MUST fail while a path is neither owned nor ignored.

## 6. Status and export selection

`lxp status` MUST report Component roots, Provider-native changes, unowned paths, and ignored paths in both human-readable and structured output. Core cannot misclassify Provider-internal untracked paths as missing top-level ownership.

Export reads Provider-selected current state. Git Provider Add/Status aligns with the Git index. Export MUST NOT silently include Git-untracked content.

Each Component records `reference`, `embedded`, or `mirrored` distribution. References contain immutable Provider-native locators and revisions. Embedded payloads are content-addressed. Mirrored contains an equivalent reference and fallback.

`mirrored.reference.revision` and `mirrored.embedded.revision` MUST be identical. Import MUST try the reference first; if it cannot restore, Import MUST remove partial materialization before using the already digest- and size-verified embedded fallback. A Provider cannot use fallback to hide a revision mismatch, payload validation failure, or contract mismatch.

A reference locator MUST be a portable identity declared by its Provider contract and cannot contain secrets, local materialization paths, or Provider Store paths. Reference availability depends on its external source, so an unavailable source fails reference Import. A mirrored fallback MUST represent the same Provider-selected state, but MAY explicitly exclude objects that its contract declares as external Requirements.

Unsupported distributions MUST fail. A standalone Artifact embeds all consumed content and imports after deleting the exporter Engine state and original sources; a mirrored fallback satisfies this condition, while reference explicitly depends on its external source. The Production MVP public CLI MUST support all three distributions and defaults Export to embedded. See the [Distribution guide](distributions.en.md) for structure and selection rules.

## 7. Requirements and activation

A Requirement describes a condition that is not portable Component state. MVP Check types are `executable`, `mcp`, and `credential`; Checks are Engine interfaces, not Component Providers.

Before materialization or activation, Engine MUST present Provider Plans and the Requirement checklist. Executable and MCP actions require explicit Import policy; shell fragments are forbidden. Secret values MUST NOT enter manifests, locks, payloads, argv, logs, Conversations, or provenance. Providers may use non-serializable local credential handles only for an authorized operation.

The graph formed by `component.requires` and `requirement.provided_by` MUST be acyclic. An unsatisfied consumed Requirement fails Import; unconsumed items remain visible without blocking.

## 8. Conversations

A Conversation is exchanged as ordinary Component content; the Production MVP stores it inside a Git-managed Component. `continue` means portable messages and completed tool events can be passed to a compatible Agent and appended. Historical tool calls MUST NOT replay during Import. Private caches, hidden reasoning, approval state, and external transactions are outside the guarantee.

## 9. Import and export

Import MUST safely unpack, validate schema/lock/digests, verify that roots are unique and form a safe lexical tree, locate exact Provider contracts, present internal Provider Plans and Requirements before any materialization or activation side effect, apply local policy, restore/materialize from parent to child, reject symlink traversal and non-empty child-target collisions, activate in dependency order, write local locks, and expose the Workdir. Plan is an Import preflight contract, not a required standalone CLI. Unknown Providers, contract mismatch, digest failure, unmet consumed Requirements, physical composition failure, and activation failure terminate Import and clean a new target.

Export MUST read ownership, aggregate Status, reject unowned paths, invoke Provider ExportComponent from child to parent so each parent can validate child identities and native attachments, validate immutable references and payloads, set an optional parent digest, and atomically write the Artifact. Every Export creates a new identity and never mutates an old Artifact.

## 10. Security and conformance

`v1alpha1` is limited to trusted Artifacts. Validation, safe extraction, digest verification, and execution policy are defense in depth, not a complete security boundary for hostile input.

A conformance harness MUST import a standalone Artifact after deleting both exporter state and original sources, then verify Provider-selected bytes and state, Requirements, secret non-disclosure, a second Export/Import generation, traversal rejection, and digest tampering. Empty directories and safe symlinks are verified only when the Provider contract claims them; `git@v1` follows Git tree semantics and does not represent untracked empty directories.
