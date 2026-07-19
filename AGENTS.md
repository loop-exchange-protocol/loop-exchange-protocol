# Agent 合约

[English](AGENTS.en.md) | **中文主版本**

本仓库是 LXP（Loop Exchange Protocol）的语言无关规范源。规范行为定义在 `docs/spec-v1alpha1.md` 与 `schemas/v1alpha1/`；实现位于 Organization 下的 SDK 与 Provider 仓库。

## 必需验证

```bash
make ci
```

`make ci` 检查 Schema、canonical YAML、Shell、双语文档与链接、SVG、stale terminology 和 diff hygiene。可执行 conformance Harness 位于实现仓库并消费本仓库的规范与案例。

## 不变量

- 生命周期为 `Import → Work → Add/Status → Export`；每次 Export 创建新的不可变 Artifact。
- LXP 管 ownership，Provider 管内容；Component roots 唯一且可形成严格嵌套 lexical tree，实体 path 只归最深 root。
- `lxp add` 路由到最深 owning Provider；native discovery 可注册嵌套 Component，祖先 Provider 必须排除 child subtree，无法安全组合时失败。
- Provider 与 Checker 由跨 kind 全局唯一的 `namespace:name:version` contract 坐标标识；Artifact 只声明 contract，本地有序仓库与 binding 解析具体实现，并精确核验已注册 implementation package。
- Artifact 不携带 Provider 可执行代码；未知或不匹配的 contract 必须失败。
- 交换对象只包含逻辑身份与 SHA-256 payload，不包含本地物化路径或 Provider Store path。
- Standalone embedded Artifact import 不依赖原始 source 或 exporter Engine state。
- Artifact 只有 manifest 与被引用的 content-addressed payload；未知文件、孤儿 object 与冗余 `lock.yaml` 必须拒绝。Secret 值不得进入 manifest、payload、argv 或 log；Executable/MCP Check 必须显式授权。
- CLI/Provider 外部操作必须继承可取消且有 deadline 的执行上下文，不得交互式等待 credential；诊断输出必须有界。
- 未归属且未忽略的 path 会阻止 Export；Git-untracked 内容不得静默导出。
- `loop.exchange:git:v1` 在 `lxp add` 时按 gitlink 锁定 revision 自动初始化缺失 submodule，并递归注册为独立嵌套 Component；不得把已初始化 submodule更新到远端新 revision。Import/discovery 必须用 config-only `git submodule init` 保持父仓 native config 与 restored child 一致，不得因此 fetch 或 checkout。Export 子到父验证 gitlink/revision，Import 父到子 Apply。
- Provider `Apply` 必须幂等、可重试且不依赖 Core rollback。Import 失败保留同 Artifact 的本地 `importing` state 并固定扩展解析；成功 Component 不回滚，ready Session 重试为 no-op。
- `loop.exchange:git:v1` embedded staged patch 的 Export/Import 上限同为 256 MiB；Export 不得创建本 contract 无法恢复的 Artifact。
- Conversation 可以 continue，但不支持 execution replay。

`v1alpha1` 是不承诺兼容性的 public alpha，只面向可信 Artifact。Validation、digest verification 与 execution policy 不是处理恶意输入的完整安全边界。

Production MVP 是规范的受限子集：官方组合只包含内置 Go `loop.exchange:git:v1`，不承诺多语言 SDK；公开 CLI 只有 `init/add/status/export/import/inspect/requirements`，接受 `.lxpz` 的 `reference`、`embedded` 与 `mirrored`。`lxp export --distribution` 选择分发形式，默认 `embedded`；Import 按 Artifact 自动处理。自动安装扩展、File/Filesystem Provider 与 Template repository 不属于生产承诺。
