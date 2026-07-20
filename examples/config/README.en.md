# Engine extension configuration example

[中文](README.md) | **English**

[`engine-config.yaml`](engine-config.yaml) binds `loop.exchange:git:v1` to `lxp-provider-git` on local PATH; `command` is argv and never passes through a shell. [`engine-config.repository.yaml`](engine-config.repository.yaml) shows the same contract using OCI distribution. Its all-`a` digest is a documentation placeholder that must be replaced by the released manifest's real SHA-256. An Artifact declares contracts only; repositories, credentials, mirrors, and implementation versions remain consumer-local and never enter `.lxpz`.

Repositories are searched in order for `${base}/${implementation.namespace}/${implementation.name}@digest`. `source: repository` pins SHA-256 and can download only when `auto_install: true` and the namespace appears in `trusted_namespaces`. A credential names a local environment secret handle; its value never enters YAML. The official CLI may still use its builtin Git Provider by default. Helper and OCI use explicit local policy, never Artifact authority. See the [extension protocol](../../docs/extensions.en.md) for package layout, handshake, and lifecycle.
