# LXP Requirements and Checkers

[中文](requirements.md) | **English**

This guide explains the Requirement model in the [v1alpha1 specification](spec-v1alpha1.en.md).

## Boundary and lifecycle

A Component holds persistent content that a Provider can Apply and Export. A Requirement describes an external condition that can only be observed at the consumer, such as an executable, MCP interface, or credential binding.

```text
Declare → Check → Ready | Unavailable
```

A Requirement is not a weak Component and has no materialization, installation, build, Activate, or snapshot lifecycle. A Checker observes only. A user, agent Harness, platform, or environment manager fulfills the condition, then Check runs again.

## Global Checker contracts

Checkers and Providers use the same `namespace:name:version` coordinate form:

```yaml
requirements:
  - id: git-cli
    description: Git executable used by the Git Provider
    prompt: Install Git or make it available on PATH, then refresh.
    check:
      checker:
        namespace: loop.exchange
        name: executable
        version: v1
      config:
        command: git
        args: [--version]
```

The exact Checker contract defines `check.config`, which is opaque to Core. The official MVP includes:

- `loop.exchange:executable:v1`, locating a bare executable name and observing its version with an argv-only probe;
- `loop.exchange:mcp:v1`, temporarily initializing an MCP stdio endpoint, discovering tools, comparing the contract, and closing it;
- `loop.exchange:credential:v1`, observing an allowed local credential scheme without reading or exposing a secret value.

An unknown Checker, missing local binding, or contract mismatch remains unavailable. An Artifact cannot select an implementation package or trigger installation.

## Consumption and results

A Component declares consumed items through `requires`:

```yaml
components:
  - id: source
    requires: [git-cli]
```

Every consumed Requirement must be ready before any Component Apply. Unconsumed items remain visible without blocking Import. Because Checkers do not produce Component state, there is no `provided_by`, activation DAG, or implicit fulfillment.

`lxp requirements` and the Import checklist return the ID, Checker coordinate, status, detail, action, Prompt, and Prompt source. A Prompt is metadata, not an executable protocol. Executable and MCP Checks require explicit local-policy authorization and cannot interpret shell fragments, pipelines, redirections, or package lifecycle scripts.

Credential config declares accepted schemes and secret-slot names only. Values travel through non-serializable local handles and cannot enter an Artifact, EngineConfig, payload, argv, log, Conversation, or local Requirement state.

## Extension resolution

An Artifact declares a Checker contract. Local EngineConfig binds it to a builtin, local Helper, or implementation package from an authorized OCI repository. Repositories, mirrors, implementation versions, digests, commands, and credentials remain consumer policy. Helpers use a language-neutral process protocol, but v1alpha1 promises no multi-language SDK matrix. Official credential/executable/MCP Checkers remain builtin by default, and secret values do not cross the Helper wire.
