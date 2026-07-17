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
- LXP 管 ownership，Provider 管内容；Component roots 必须 prefix-free，且内部对 Core 不透明。
- Component 内的 `lxp add` 必须路由到 owning Provider，不得创建嵌套 Component。
- Provider 由稳定 `provider + contract` 标识；Provider-specific config/payload 对 Core 不透明。
- Artifact 不携带 Provider 可执行代码；未知或不匹配的 contract 必须失败。
- 交换对象只包含逻辑身份与 SHA-256 payload，不包含本地物化路径或 Provider Store path。
- Standalone embedded Artifact import 不依赖原始 source 或 exporter Engine state。
- Secret 值不得进入 manifest、lock、payload、argv 或 log；Executable/MCP action 必须显式授权。
- 未归属且未忽略的 path 会阻止 Export；Git-untracked 内容不得静默导出。
- Conversation 可以 continue，但不支持 execution replay。

`v1alpha1` 是不承诺兼容性的 public alpha，只面向可信 Artifact。Validation、digest verification 与 execution policy 不是处理恶意输入的完整安全边界。

Production MVP 是规范的受限子集：官方组合只包含 `git@v1`，公开 CLI 只有 `init/add/status/export/import/inspect/requirements`，并且只接受 `.lxpz` embedded Artifact。`Plan` 仅是 Import 内部 preflight；File/Filesystem Provider、reference/mirrored distribution 与 Template repository 不属于生产承诺。
