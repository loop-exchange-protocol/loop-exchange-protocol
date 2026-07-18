# LXP Distribution Guide

**English** | [中文主版本](distributions.md)

This guide explains how to choose `reference`, `embedded`, or `mirrored`, plus the current `git@v1` alpha behavior. The [v1alpha1 specification](spec-v1alpha1.en.md) and [Schema](../schemas/v1alpha1/context-artifact.schema.json) remain normative.

## Three distribution forms

| Distribution | What the Artifact stores | Import dependency | Typical use |
|---|---|---|---|
| `reference` | portable locator + immutable revision | original source remains reachable | large, public, stably available repositories |
| `embedded` | content-addressed payload | Artifact and local Provider only | Production standalone checkpoints |
| `mirrored` | reference + embedded fallback for one revision | source first; Artifact fallback on outage | preserve remote identity while tolerating source outage |

Mirrored does not contain two different versions. Its reference and embedded revisions must match. Import validates embedded digests and sizes before Provider execution, then tries the reference. Only after a reference failure and partial-target cleanup does it restore embedded content. Revision, payload, and contract mismatches fail directly rather than triggering a permissive fallback.

See [`examples/distributions/`](../examples/distributions/README.en.md) for complete YAML structures. YAML is the exchange format; users are not expected to author these fields in daily work.

## `git@v1` alpha rules

The experimental modes in the current Go Git Provider follow these rules:

- locators accept credential-free `https://`, `ssh://`, `git://`, or SCP-like SSH Git URLs; absolute local paths, `file://`, query secrets, and synthetic locators fail;
- a revision is a full 40- or 64-character Git object ID reachable at Export from a remote advertised ref;
- `reference` and `mirrored` can express commit state only, so the Git index must match `HEAD`; use Production embedded for staged selection, or commit it first;
- mirrored embedded content contains a base bundle only, never a staged-state patch;
- reference Import retains its safe origin, and mirrored fallback retains the same origin identity;
- partial/shallow repositories, submodules/gitlinks, escaping symlinks, and undeclared filters fail.

Spring AI uses Git LFS. An experimental Component can declare:

```yaml
config:
  lfs_mode: pointer
```

This mode treats only the LFS pointer blob tracked in the Git tree as Component state and disables LFS filters during checkout. External LFS objects do not enter the mirrored payload and Import neither executes nor downloads them. Production embedded continues to reject every clean/smudge filter.

## Profile and Harness

The official Production CLI still accepts embedded `.lxpz` only and has no reference or mirrored flag. Experimental support is exposed through the Go Engine/Provider API without changing the frozen public command surface.

The [`go-provider-git` Spring AI + MCP Harness](https://github.com/loop-exchange-protocol/go-provider-git/tree/main/harness/spring-ai-mcp) uses four real Git Components to verify online reference restore, offline reference failure/cleanup, and offline mirrored fallback. `v1alpha1` carries no compatibility promise and is limited to trusted Artifacts, locators, and locally installed Providers.
