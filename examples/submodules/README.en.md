# Nested Components and Git submodules

**English** | [中文主版本](README.md)

[`manifest.yaml`](manifest.yaml) shows the portable structure of a parent Git repository and its submodule. No additional `parent` or mount field is needed: normalized paths derive the relationship because `shared-library.path` is strictly below `application.path`.

- The parent Component owns `.gitmodules` and the gitlink boundary at `deps/shared-library`, but not child worktree entities.
- The child Component owns every entity below its nested root and carries an independent revision and payload.
- The selected parent gitlink must equal the child Component's locked revision; the example child revision is `bbbb…`.
- Import materializes parent to child; Export locks child to parent and validates the boundary.
- The Artifact declares no copy, symlink, or mount capability. A Provider fails when it cannot safely compose the concrete path.

The YAML uses placeholder digests and sizes to emphasize structure and omits large Git bundles. The real CLI generates the manifest, payloads, and lock automatically:

```bash
git clone --recurse-submodules YOUR_REPOSITORY source
lxp init .
lxp add source
lxp export --distribution embedded ../context.lxpz
```

An uninitialized submodule, a gitlink without a nested Component, child-revision mismatch, symlink traversal, or a non-empty child target must fail.
