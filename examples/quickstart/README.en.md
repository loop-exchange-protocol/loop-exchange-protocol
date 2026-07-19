# Complete quickstart

**English** | [中文主版本](README.md)

This is executable documentation and requires no hand-authored YAML. It drives the real `lxp` binary through:

```text
Init → Git discovery → Add → Status → Export
     → delete the source worktree → Import → continue → generation-2 Export/Import
```

Run:

```bash
LXP_BIN="$(command -v lxp)" examples/quickstart/run.sh
```

The script verifies three important semantics:

- `lxp add source/README.md` discovers `source/.git` upward, registers the repository as `loop.exchange:git:v1`, and selects only the requested change;
- Git-untracked `draft.txt` is not silently exported, and Git index selection remains staged after Import;
- after deleting the publisher and generation 1, a standalone embedded Artifact still imports and continues through `provenance.parent` into generation 2.

Generated evidence defaults to `/tmp/lxp-quickstart` and includes:

```text
generation-1.manifest.yaml
generation-1.requirements.json
generation-2.manifest.yaml
status-before.json
status-after.json
```

See the [Artifact YAML example](../artifact/README.en.md) for a field-by-field static example.
