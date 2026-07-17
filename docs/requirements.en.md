# LXP Requirement Check Model

**English** | [中文](requirements.md)

This document explains the Requirement model defined normatively by [spec-v1alpha1.en.md](./spec-v1alpha1.en.md). Current implementation coverage is recorded in [go-engine.en.md](./go-engine.en.md).

## Boundary

LXP separates portable work units from external conditions:

- `components` contain persistent state that a Provider can resolve or restore, materialize, activate, and export by reference, embedding, or both.
- `requirements` declare conditions that can only be checked, such as a host executable, MCP interface, external service, or local credential.

A Requirement is not a weak Component and has no Provider, materialization, activation, or snapshot lifecycle.

## Lifecycle

Every Requirement has the same public lifecycle:

```text
Declare -> Check -> Satisfied | Unsatisfied
```

Fulfillment is not a Requirement stage. It may be performed by Component activation, an Engine capability, a platform, a user, an Agent, or an external environment manager. LXP checks again afterward.

## Check contract

```yaml
requirements:
  - id: git-cli
    description: Git executable used by a Component Provider
    prompt: Install Git or make it available on PATH, then refresh.
    check:
      type: executable
      command: git
      args: [--version]
```

The MVP defines three Check types:

- `executable`: locate a bare executable and optionally run an argv-only probe.
- `mcp`: initialize an MCP stdio endpoint, discover tools, and compare its contract.
- `credential`: resolve an accepted local credential scheme without exposing its value.

Checks execute only under local policy. They never evaluate shell fragments, pipelines, redirections, substitutions, Prompt text, or package-local lifecycle scripts.

## Results and Prompts

An Engine exposes the complete Requirement checklist before activation. Every result includes the Requirement ID, status, detail, action, Prompt, and Prompt source.

Prompt text is attributed transportable metadata, not executable protocol. A client may show it to a user or Agent. LXP does not silently follow it.

## Component relationship and orchestration

A Component declares what it consumes, while a Requirement declares its producer:

```yaml
components:
  - id: github-mcp
    requires: [github-token]

requirements:
  - id: github-token
    check:
      type: credential
      accepts: [environment, bearer-token]
  - id: github-mcp-ready
    provided_by: component:github-mcp
    check:
      type: mcp
      command: github-mcp-server
      required_tools: [repository.get]
```

`requires` must be satisfied before activation. `provided_by` defaults to `environment`; a Component reference means the Engine checks the Requirement after that Component activates. The declaration is not proof of satisfaction.

A Requirement has no independent `required` flag. Referencing it from `component.requires` makes it mandatory for that Component. An unconsumed Requirement remains visible in the checklist, but an unsatisfied result does not fail Import.

Together they form a restricted bipartite DAG of Component Activate and Requirement Check nodes. The Engine rejects missing references, ambiguous producers, and cycles; it may run independent ready nodes concurrently. Failure propagates to dependent nodes.

## Bounded activation

Activate may install, build, initialize, and generate configuration, but it completes without leaving a process, socket, port, or credential handle owned by LXP. There is no Deactivate stage or Activation Handle in the MVP. Agent Harnesses and host platforms own any long-running service lifecycle.

An MCP Check may temporarily start a stdio process, initialize it, inspect its tool contract, and close it before returning. A satisfied MCP Requirement means the endpoint is startable and contract-compatible, not that LXP keeps it running. Remote MCP services remain externally managed.

During activation, a Provider may request an authorized credential handle by Requirement ID. The Engine scopes the handle to the target operation and prevents its value from entering files, locks, logs, embedded Payloads, Provider Stores, or Artifacts.

## Extension model

Check types are trusted Engine interfaces. They are distinct from Component Providers because they own no Component content. An unknown Check type remains unsatisfied; it is not an instruction for an Agent to improvise.

LXP does not provide a generic `RUN` primitive. Reproducible environment definitions and reviewed scripts may be transported as Component content, while their execution remains an explicit Provider operation governed by local policy.
