# Reference and Mirrored YAML Examples

**English** | [中文主版本](README.md)

This directory provides complete manifest/lock structures for `reference` and `mirrored`:

- [`reference-manifest.yaml`](reference-manifest.yaml) and [`reference-lock.yaml`](reference-lock.yaml): an immutable Git reference to Spring AI Examples with no `objects/` payload;
- [`mirrored-manifest.yaml`](mirrored-manifest.yaml) and [`mirrored-lock.yaml`](mirrored-lock.yaml): one Spring AI revision represented by both a reference and embedded base fallback, with LFS pointer mode declared.

These files are Schema/canonical structure vectors, not directly importable `.lxpz` archives: the repository does not include the large Git bundle named by the sample mirrored payload digest. The executable four-Component journey lives in the [`go-provider-git` Harness](https://github.com/loop-exchange-protocol/go-provider-git/tree/main/harness/spring-ai-mcp).

Key invariants are that both mirrored revisions are identical, lock distribution/revision/payload digests match the manifest, and reference locators contain neither credentials nor local paths. See the [Distribution guide](../../docs/distributions.en.md) for semantics.
