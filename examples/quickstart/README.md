# 完整 Quickstart

[English](README.en.md) | **中文主版本**

这个案例是可执行文档，不需要手写 YAML。它通过真实 `lxp` 二进制演示：

```text
Init → Git discovery → Add → Status → Export
     → 删除原工作区 → Import → 继续工作 → 二代 Export/Import
```

运行：

```bash
LXP_BIN="$(command -v lxp)" examples/quickstart/run.sh
```

脚本会验证三个关键语义：

- `lxp add source/README.md` 向上发现 `source/.git`，把整个仓库注册为 `git@v1`，但只选择指定变更；
- Git-untracked 的 `draft.txt` 不会被静默导出，Import 后 Git index selection 仍保持 staged；
- 删除 publisher 和第一代 Artifact 后，standalone embedded Artifact 仍能 Import，并通过 `provenance.parent` 继续到第二代。

默认产物位于 `/tmp/lxp-quickstart`，其中包括真实生成的：

```text
generation-1.manifest.yaml
generation-1.requirements.json
generation-2.manifest.yaml
status-before.json
status-after.json
```

静态 YAML 字段说明见 [Artifact YAML 示例](../artifact/README.md)。
