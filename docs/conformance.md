# LXP v1alpha1 一致性要求

[English](conformance.en.md) | **中文主版本**

本文件定义 `loop.exchange/v1alpha1` 实现声明 conformance 时必须提供的语言无关证据；它不替代[规范](spec-v1alpha1.md)或 Schema。Public alpha 不承诺 profile 或测试向量兼容性，且当前只面向可信 Artifact。

## Profile

| Profile | 必须覆盖的行为 | 最低证据 |
|---|---|---|
| `artifact-core` | envelope、manifest/lock、SHA-256、safe normalized paths、prefix-free roots、contract mismatch failure | canonical YAML 的正反向测试；digest/size、absolute path、parent traversal、link/special archive entry 拒绝测试 |
| `tracking-core` | Init/Import、Add/Status routing、ownership、Export checkpoint 与 parent provenance | 黑盒 CLI/API 测试；Component 内 Add 回到 owning Provider；未归属 path 阻塞 Export |
| `provider-CONTRACT` | Match、Plan、Resolve、Materialize/Restore、Add/Status、ExportComponent 和支持的 distribution | Provider contract suite；未知 contract 与不支持 distribution 失败；Provider config/payload 对 Core 不透明 |
| `requirements-core` | Plan/checklist、依赖 DAG、显式 executable/MCP policy、credential handle 隔离 | missing/ambiguous/cyclic Requirement；未授权 execution；secret 不进入文件、lock、payload、argv 或 log |
| `standalone-portability` | 删除 exporter state 与原始 source 后从 embedded Artifact 恢复并继续下一代 | destructive 两代 Export/Import Harness；Provider-selected bytes/state 一致；仅对 contract 声明支持的 empty directory 与安全 symlink 验证 |
| `production-git-v1` | 官方 CLI 只装配 `git@v1`、embedded-only、index selection 往返、最小 HEAD bundle、parent 推进 | 拒绝 reference/mirrored、shallow、submodule、filter、escaping symlink 与额外 payload role；失败 Import 清理 target |
| `git-v1-alpha-distributions` | Go Engine/Provider API 的 Git reference 与 mirrored；不扩大 Production CLI | 在线 reference 恢复；离线 reference 失败并清理；相同离线条件下 mirrored fallback；拒绝 secret/local locator、revision mismatch 和 staged index；声明的 LFS pointer 模式不得执行 filter |

实现只能声明实际通过的 Profile。例如只实现 Artifact codec 的库不得声明 `tracking-core`；Provider 必须连同明确的 contract version 声明 `provider-CONTRACT`。Production MVP 发布必须声明前五个基础 Profile（其中 `provider-CONTRACT` 实例化为 `provider-git-v1`）与 `production-git-v1`。实现 `git-v1-alpha-distributions` 不会让 reference/mirrored 进入 Production Profile，也不得改变公开 CLI 的 embedded-only 默认与验收边界。

## Canonical vectors

- [`examples/artifact/manifest.yaml`](../examples/artifact/manifest.yaml) 与 [`lock.yaml`](../examples/artifact/lock.yaml) 是可读 canonical exchange vectors。
- [`examples/distributions/`](../examples/distributions/README.md) 提供 reference/mirrored manifest 与 lock 结构向量；大 payload 不提交到规范仓库。
- [`examples/quickstart/run.sh`](../examples/quickstart/run.sh) 是 SDK/CLI 可消费的两代黑盒旅程，不是某种语言实现的规范源。
- [`schemas/v1alpha1/`](../schemas/v1alpha1/) 定义结构约束；通过 Schema 只是 conformance 的必要条件，不是充分条件。

第三方测试报告必须记录实现版本、声明的 Profile、Provider contract、测试向量版本、平台和失败结果。不得省略失败 case，也不得把 Agent 猜测、隐式迁移或 exporter-local fallback 计为通过。
