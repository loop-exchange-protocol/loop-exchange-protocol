# ContextArtifact YAML example

[中文](README.md) | **English**

[`manifest.yaml`](manifest.yaml) demonstrates the complete exchange structure:

- readable Artifact coordinates and parent digest;
- the global `loop.exchange:git:v1` Provider contract coordinate;
- content-addressed payloads for an embedded Git base and selected index state;
- media type, SHA-256 digest, and size.

An Artifact has no `lock.yaml`: the manifest already fixes revision, distribution, and payload digests, and Artifact identity is the SHA-256 of validated raw `manifest.yaml` bytes, with no YAML canonicalization.

Normal users do not hand-author YAML. The CLI generates the manifest and `objects/sha256/` content.
