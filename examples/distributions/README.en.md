# Distribution YAML examples

[中文](README.md) | **English**

This directory provides two manifest structures:

- [`reference-manifest.yaml`](reference-manifest.yaml), an immutable Git reference to Spring AI Examples with no `objects/` payload;
- [`mirrored-manifest.yaml`](mirrored-manifest.yaml), the same Spring AI reference revision with an embedded base fallback and declared LFS pointer mode.

These are Schema/canonical structure vectors, not directly importable `.lxpz` archives, because the repository does not commit the large Git bundles they name. The executable four-Component journey lives in the [`provider-git` Harness](https://github.com/loop-exchange-protocol/provider-git/tree/main/harness/spring-ai-mcp).

Both mirrored revisions are identical, manifest payload digest/size matches its object, and reference locators contain neither credentials nor local paths. There is no second Artifact lock. See the [Distribution guide](../../docs/distributions.en.md).
