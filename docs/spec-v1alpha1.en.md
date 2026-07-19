# LXP v1alpha1 Specification

[中文](spec-v1alpha1.md) | **English**

Status: public alpha, with no forward- or backward-compatibility promise. `MUST`, `MUST NOT`, `SHOULD`, and `MAY` follow RFC 2119. The first deployable subset is the [Production MVP](production-mvp.en.md): trusted environments, official `loop.exchange:git:v1`, and reference/embedded/mirrored `.lxpz` Artifacts.

## 1. Goal and lifecycle

LXP tracks and exchanges agent work context with a Git-like lifecycle:

```text
Import → Work → Add/Status → Export → Import …
```

Import reconciles an immutable Artifact into a working Session. Work changes materialized content. Add asks the owning Provider to select changes or register an ownership root. Status aggregates Core and Provider state. Every Export creates a new immutable Artifact.

A standard CLI SHOULD expose `init`, `import`, `add`, `status`, and `export`. The worktree-root `.lxp` directory is local discovery/state and MUST NOT be exported. LXP does not define deployment rendering, command workflows, hidden reasoning, external side effects, or execution replay. YAML is a machine exchange format, not a daily authoring requirement.

## 2. Artifact and history

A logical Artifact is a `.lxp` directory; `.lxpz` is its equivalent gzip tar envelope:

```text
manifest.yaml
objects/sha256/<hex>
```

An Artifact has readable `namespace/name/version` coordinates. SHA-256 is computed directly over the raw `manifest.yaml` bytes in the Artifact after successful parsing and Schema validation, with no YAML canonicalization, to produce immutable identity. One coordinate MUST NOT resolve to different bytes. `provenance.parent` MAY point to the direct parent digest, creating linear history. v1alpha1 defines no branch, merge, rebase, or multi-parent history.

An Artifact has no `lock.yaml`. The manifest already fixes Component revisions, distributions, and payload digests; a second portable lock would add drift, not authority. An implementation MAY retain local extension-resolution or Requirement-observation state, but it is not Artifact content and cannot alter Artifact identity.

See the complete [manifest.yaml](../examples/artifact/manifest.yaml) and [ContextArtifact Schema](../schemas/v1alpha1/context-artifact.schema.json). Before calling a Provider, an Importer MUST validate archive paths, the manifest, and every payload digest and size, rejecting files outside `manifest.yaml` and actually referenced `objects/sha256/<hex>` payloads as well as orphan objects. An archive MUST NOT contain absolute paths, parent traversal, links, devices, or other special entries.

## 3. Component ownership

A Component is persistent content managed by one Provider and materialized at a Session-relative path:

```yaml
components:
  - id: source
    path: repositories/source
    provider:
      namespace: loop.exchange
      name: git
      version: v1
    distribution: embedded
```

- A Component path MUST be a safe normalized relative path outside `.loop` and `.lxp`.
- Roots MUST be unique and MAY form a strictly nested lexical tree. A symlink alias cannot bypass that tree.
- LXP owns roots, identity, routing, Requirements, and the exchange envelope; Providers own content semantics.
- An entity belongs to its deepest root. An ancestor Provider MUST exclude direct-child subtrees and MUST fail closed when composition is unsafe.
- Core defines no symlink, copy, mount, or capability matrix. Local Providers decide physical composition; materialized paths and capabilities never enter an Artifact.
- Local containment and Session discovery MUST use physical absolute paths after resolving existing symlink prefixes. The result remains local.
- `lxp add` MAY invoke Provider-native child discovery. Discovered children are registered independently; Core never guesses unknown markers.

Ordinary path operations route to the deepest owning Provider. A parent MAY maintain boundary metadata such as a gitlink, but cannot read or export child entities.

## 4. Globally unique contract coordinates

Providers and Checkers share one global contract-coordinate form:

```yaml
namespace: loop.exchange
name: git
version: v1
```

Its text form is `namespace:name:version`, for example `loop.exchange:git:v1`. `namespace` MUST be a DNS namespace controlled by the maintainer, `name` is unique within it, and `version` identifies an exact contract. A coordinate MUST also be globally unique across the Provider and Checker kinds; the same coordinate cannot identify both. Implementation language is not part of contract identity.

An Artifact declares only contracts, never implementation packages, repositories, download URLs, or executables. An Engine MUST use local [EngineConfig](../schemas/v1alpha1/engine-config.schema.json) to bind every contract to exact implementation coordinates. Missing resolution, kind mismatch, or contract mismatch MUST fail before Component side effects.

Ordered `repositories` in EngineConfig are local candidate sources. `bindings` map Provider/Checker contracts to exact implementation package coordinates. Repository IDs MUST be unique; each contract has exactly one binding and cannot be reused across Provider/Checker kinds. `source: repository` also MUST pin a SHA-256 digest. A missing coordinate continues to the next repository; once a repository contains that coordinate, a digest mismatch MUST fail immediately without further search or fallback; the first verified match wins. Repository credentials can only refer to local secret slots; values cannot appear in config. An Artifact cannot override repository order, mirrors, trust, or installation policy. See [engine-config.yaml](../examples/config/engine-config.yaml).

Every locally registered Provider or Checker MUST declare its own implementation package coordinate. Before a new or `importing` Import, Add, Status, or Export, Engine MUST compare it exactly with the binding; a matching contract cannot authorize a different package or version. When an Import first enters `importing`, its resolved implementations MUST be pinned in local Session state. A retry fails if configuration would change them instead of continuing with another implementation. A same-digest `ready` Session returns no-op after safe envelope and local-identity validation, without resolving extensions, running Checkers, or calling Providers. This state is not Artifact content.

Automatic installation is not required by v1alpha1, and v1alpha1 defines no interoperable package layout, ABI, or process protocol. An implementation MAY download and verify its own package format under operator configuration, but MUST NOT install or execute solely because an Artifact requests a contract. The official Production MVP executes only Go implementations explicitly compiled into the CLI as `builtin`; LXP does not promise a multi-language SDK matrix.

## 5. Provider contract

Provider-specific `config` and payload roles are opaque to Core. A Provider contract contains:

- `Contract`, returning the global coordinate;
- `Match`, inspecting a native marker only for an unowned root;
- `Validate`, checking desired state, distribution, payload, and direct-child boundaries without Component-write side effects;
- `Apply`, reconciling a desired Component into a target and returning observed state;
- `Add` and `Status`, implementing native change selection;
- optional `DiscoverChildren` and `TrackChild`, for native children and boundary metadata;
- `ExportComponent`, producing an immutable reference, embedded payloads, or both.

`Apply(desired, target)` MUST be idempotent and retryable. The same desired state and completed target return equivalent observed state. Partial state left by this Provider in the same incomplete Import is continued or safely rebuilt inside its own root. Apply cannot advance to an undeclared revision, delete child roots, or rewrite unowned content. Providers expose no Core rollback and cannot depend on a global transaction.

Any operation that may access an external service or start an executable MUST inherit cancellation/deadline, use a finite default when absent, disable interactive credentials, and bound diagnostics. Secrets, local targets, sockets, PIDs, ports, credential handles, and Provider Store paths MUST NOT enter an Artifact.

## 6. Add, Status, and Export selection

`lxp add PATH...` uses the longest ownership root. Inside an existing root it invokes the owning Provider. An unowned or newly discovered child root is uniquely matched by locally resolved Providers before registration. Zero matches or a tied priority fails. `.lxpignore` affects only unowned roots. Export MUST fail while any path is neither owned nor ignored.

`lxp status` reports Component roots, Provider-native changes, unowned paths, and ignored paths. Export uses Provider-selected state. Git Add/Status follows the index; Git-untracked content cannot be exported silently.

Each Component declares one distribution:

- `reference`: immutable Provider-native locator and revision;
- `embedded`: content-addressed Artifact payloads;
- `mirrored`: a reference and embedded fallback for the same revision.

Mirrored first tries its reference and switches to the verified fallback only for contract-defined recoverable errors such as source unavailability. The owning Provider cleans partial work inside its Component root; this is not a Core rollback. Standalone embedded and mirrored fallback Import must work after exporter Engine state and original sources are deleted.

## 7. Requirements and Checkers

A Requirement is an observable external condition that cannot be exchanged as Component state. Its Check uses a global Checker contract:

```yaml
requirements:
  - id: git-cli
    check:
      checker:
        namespace: loop.exchange
        name: executable
        version: v1
      config:
        command: git
        args: [--version]
```

Checker-specific `config` is opaque to Core. A Checker MUST be a read-only, bounded, idempotent observation. It cannot install software, build a Component, retain a service, or fulfill a Requirement. Fulfillment belongs to the user, agent Harness, platform, or environment manager; Check is then repeated.

A Requirement referenced by `component.requires` must be ready before Apply. Unconsumed items remain visible without blocking. Executable/MCP Checks require explicit local-policy authorization and cannot run shell fragments. Secret values MUST NOT enter manifests, payloads, argv, logs, Conversations, or provenance.

## 8. Import: validate, then reconcile

An Importer MUST:

1. safely unpack and validate Schema, roots, and every payload digest/size;
2. resolve every Provider and Checker contract exactly through local EngineConfig;
3. run policy-authorized Requirement Checks and establish that every consumed Requirement is ready before Component writes;
4. call every Provider `Validate` without write side effects;
5. atomically write a local `importing` marker, then call `Apply` parent-to-child and atomically record each successful observed state;
6. atomically mark the Session `ready` and expose the Workdir after all Components succeed.

A first Import target MUST be absent or empty. A retry may enter only a target carrying the same Artifact digest, Session ID, and `importing` marker. A different Artifact, existing symlink, or unowned content fails. Retrying the same Artifact against a `ready` Session MUST be a no-op.

When a Component fails, Import returns the error and preserves the target, completed observed state, and marker for the same command to retry. A retry MUST fail if the target contains unowned content outside `.lxp`, desired Component roots, and their ancestors. Core MUST NOT roll back successful Components or delete the target. Local temporary files and Provider-owned partial roots may be cleaned by their owners. Import has no install, build, or Activate stage.

## 9. Export

Export reads ownership, aggregates Status, rejects unowned paths, invokes `ExportComponent` child-to-parent so parents can validate child identity and native attachment, validates immutable references and payloads, sets an optional parent digest, and writes the Artifact atomically. Every Export creates a new identity and never modifies an old Artifact.

## 10. Conversation, security, and consistency

A Conversation is ordinary Component content; the Production MVP stores it inside a Git-managed Component. `continue` means portable messages and completed tool events can be appended. Historical tool calls MUST NOT replay. Private caches, hidden reasoning, approval state, and external transactions are outside the guarantee.

`v1alpha1` is limited to trusted Artifacts and makes no compatibility promise. Validation, safe extraction, digest verification, and execution policy are defense in depth, not a complete hostile-input boundary.

A Conformance Harness MUST cover all three distributions, standalone Import after exporter-source deletion, failed-Import retry and ready no-op, Provider/Checker contract mismatch, Requirements, secret non-disclosure, second-generation Export/Import, path traversal, and digest tampering.
