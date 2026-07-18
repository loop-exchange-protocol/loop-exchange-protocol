# LXP Distribution 指南

[English](distributions.en.md) | **中文主版本**

本文解释 `reference`、`embedded` 与 `mirrored` 的选择和当前 `git@v1` Production MVP 行为。规范性规则仍以 [v1alpha1 规范](spec-v1alpha1.md)和 [Schema](../schemas/v1alpha1/context-artifact.schema.json)为准。

## 三种分发方式

| Distribution | Artifact 保存什么 | Import 依赖 | 适合场景 |
|---|---|---|---|
| `reference` | portable locator + immutable revision | 原 source 可访问 | 大型、公开、可稳定获取的仓库 |
| `embedded` | content-addressed payload | 只依赖 Artifact 与本地 Provider | Production standalone checkpoint |
| `mirrored` | 同一 revision 的 reference + embedded fallback | 优先 source；不可用时回退 Artifact | 需要远端身份，同时希望 source outage 时恢复 |

`mirrored` 不是两个不同版本的副本。reference 与 embedded revision 必须相同；Importer 在 Provider 前验证 embedded digest/size，再尝试 reference。Reference 失败时清理部分 target，之后才恢复 embedded。Revision、payload 或 contract 不一致会直接失败，不能触发“宽松回退”。

对应的完整 YAML 结构见 [`examples/distributions/`](../examples/distributions/README.md)。YAML 是交换格式；用户不需要日常手写这些字段。

## `git@v1` 规则

当前 Go Git Provider 遵循：

- locator 只接受无内联凭据的 `https://`、`ssh://`、`git://` 或 SCP-like SSH Git URL；本地 absolute path、`file://`、query secret 与合成 locator 被拒绝；
- revision 必须是完整 40/64 位 Git object ID，并在 Export 时可从 remote advertised ref 到达；
- `reference` 与 `mirrored` 只能表达 commit state，因此 Git index 必须与 `HEAD` 一致；存在 staged selection 时使用 Production embedded，或先 commit；
- `mirrored` embedded 只包含 base bundle，不带 staged state patch；
- reference Import 保留安全 origin；mirrored fallback 恢复后也保留同一 origin identity；
- partial/shallow repository、submodule/gitlink、escaping symlink 与未声明 filter 失败。

Spring AI 使用 Git LFS。Reference/mirrored Component 可以声明：

```yaml
config:
  lfs_mode: pointer
```

此模式只把 Git tree 中的 LFS pointer blob 视为 Component state，并在 checkout 时禁用 LFS filter。外部 LFS object 不进入 mirrored payload，也不会被 Import 执行或下载。Production embedded 仍拒绝全部 clean/smudge filter。

## CLI 与 Harness

公开 CLI 端到端支持三种形式：

```bash
lxp export --distribution reference context.lxpz
lxp export --distribution embedded context.lxpz   # 默认
lxp export --distribution mirrored context.lxpz
lxp import context.lxpz continued                 # 自动读取 distribution
```

[`go-provider-git` Spring AI + MCP Harness](https://github.com/loop-exchange-protocol/go-provider-git/tree/main/harness/spring-ai-mcp) 直接使用公开 `lxp` CLI 和四个真实 Git Component，验证 reference 在线恢复、reference 离线失败/清理与 mirrored 离线 fallback。`v1alpha1` 不承诺兼容性，并且只面向可信 Artifact、locator 与本地 Provider。
