# Artifact YAML example

**English** | [中文主版本](README.md)

The complete [manifest.yaml](manifest.yaml) and [lock.yaml](lock.yaml) demonstrate:

- Artifact coordinates and parent digest;
- `git@v1` Provider identity and opaque `config`;
- an embedded Git bundle and staged-state payload;
- executable and credential Requirements;
- lock binding of Provider contract, distribution, and revision.

This static Artifact uses placeholder digests without object payloads, so it is intended for reading and Schema/validator tests rather than Import. The [Quickstart Harness](../quickstart/README.en.md) generates a real importable embedded Artifact and exposes its generated YAML under `/tmp/lxp-quickstart`.

Normal users do not hand-author this YAML. The CLI generates manifests, locks, and content-addressed objects.
