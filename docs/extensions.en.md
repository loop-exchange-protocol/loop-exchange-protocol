# Extension discovery, distribution, and Helper protocol

[中文](extensions.md) | **English**

This document is normative for `v1alpha1`. It defines local Provider/Checker bindings, OCI distribution, and process activation. LXP does not create a central Registry API: package discovery and download reuse OCI Distribution, while execution uses an independent process protocol modeled after Git remote helpers.

## 1. Identity and local authorization

An Artifact carries only a globally unique cross-kind contract such as `loop.exchange:git:v1`. Only consumer-local EngineConfig can bind it to an implementation package. An Artifact cannot carry a package, command, repository, digest, or installation policy.

`implementation.source` has three values:

- `builtin`: the Engine composes the implementation and its reported package coordinate must match exactly; `command` and `digest` are forbidden.
- `helper`: the operator has installed a local executable; `command` is an argv array that the Engine MUST execute directly without a shell; `digest` is forbidden.
- `repository`: the implementation is an OCI Extension Package; the binding MUST pin the OCI manifest `sha256:` digest and cannot declare `command`.

A `repository` is not authorization by itself. The Engine can use only a local repository with `auto_install: true` whose `trusted_namespaces` contains the implementation namespace. Repository order, trust, credentials, and cache are consumer policy; an Artifact cannot broaden them. The convention for official public packages is rooted at `oci://ghcr.io/loop-exchange-protocol`, although the default official composition MAY retain a builtin Git Provider so first use does not require network access.

`lxp add` runs discovery only for Provider bindings enabled by EngineConfig; it cannot scan every package in a Registry. Import already has explicit contracts but must still complete locally authorized resolution. A missing or mismatched implementation MUST fail before Component writes.

## 2. OCI Extension Package

The repository URL without its scheme is the OCI repository base. Implementation `namespace:name:version` maps to `${base}/${namespace}/${name}`. The Engine pulls the manifest by the binding digest instead of trusting a movable tag. Absence of that digest MAY continue to the next authorized repository; after content is obtained, any digest, descriptor, or platform mismatch MUST fail without fallback.

The manifest MUST have:

- `artifactType` `application/vnd.loop.exchange.extension.v1`;
- exactly one SHA-256 config with media type `application/vnd.loop.exchange.extension.config.v1+json`, valid against the [Extension Package Schema](../schemas/v1alpha1/extension-package.schema.json);
- exactly one SHA-256 raw executable layer with media type `application/vnd.loop.exchange.extension.binary.v1`, at most 128 MiB;
- a descriptor whose kind, contract, implementation, Helper protocol, OS, and architecture exactly match the local binding and platform, with an entrypoint that is one file name.

The Engine MUST atomically write the executable to a content-addressed cache, verify its layer digest before every reuse, and execute it non-interactively. A repository credential is only a local secret handle; the reference CLI resolves it as an environment variable name whose value is either a registry access token or `username:password`. The value cannot enter config, an Artifact, argv, logs, or Helper messages.

## 3. Helper lifecycle

A Helper is a command-scoped temporary process, not a daemon:

1. a package in cache is not active;
2. on first resolution of the binding, the Engine starts one process and uses `initialize` to verify kind, contract, implementation, and protocol exactly;
3. that process is reused sequentially within one CLI command;
4. command completion, cancellation, deadline, protocol error, or process failure closes stdin and terminates it.

The Engine MUST execute configured argv directly, never through a shell; MUST carry a deadline on every request and terminate the Helper on cancellation; and MUST bound stderr diagnostics. A Helper MUST propagate deadlines to all external operations and disable interactive credential prompts. A Helper is operator-authorized local code, not a hostile-code sandbox; the trusted-Artifact limitation does not imply a trusted Helper.

## 4. Wire protocol

stdin/stdout carry UTF-8 newline-delimited JSON only, with an 8 MiB maximum message. stdout cannot contain banners or logs. A connection has at most one outstanding request and the response `id` MUST match. Envelopes conform to the [Helper Message Schema](../schemas/v1alpha1/helper-message.schema.json):

```json
{"protocol":"loop.exchange/helper-v1","id":1,"method":"initialize","deadline":"2026-07-20T12:00:00Z","params":{}}
```

The first request MUST be `initialize`, with Engine root, `extension_kind`, contract, and implementation. The response repeats those exact identities. A Provider also returns `distributions` and advertises the capabilities it actually implements: `adopt`, `track`, `discover-children`, and `track-child`. Identity mismatch MUST fail; the executable file name alone is never trusted.

Provider methods are fixed:

| Method | Semantics |
| --- | --- |
| `provider.match` | `Match(path)` |
| `provider.validate` | `Validate(component, store_root, target)` |
| `provider.apply` | `Apply(component, store_root, target)` |
| `provider.export` | `ExportComponent(ref, mode, store_root)` |
| `provider.adopt` | optional `Adopt(id, path, materialized)` |
| `provider.add` / `provider.status` | optional native selection and status |
| `provider.discover-children` | optional nested Component discovery |
| `provider.track-child` | optional parent-boundary tracking |

A Checker defines only `checker.check(requirement, options)`. Provider/Checker domain models use the SDK canonical JSON field names. A Helper cannot infer portable identity from `store_root` or targets. An `error` contains only bounded `code` and `message` fields and cannot contain secrets.

## 5. Import retry

Helper download and handshake are extension resolution, not Artifact instructions or separate public install/Activate lifecycle stages. Before Import first enters `importing`, it pins source, implementation, and repository digest. A retry MUST retain that resolution, and successful Components are not rolled back. A same-Artifact retry of a `ready` Session is a no-op after local identity validation and starts no Helper or download.

A Helper crash is a failure of the current Provider/Checker call. Provider `Apply` remains idempotent and retryable; Core adds no transaction or global rollback for Helpers.
