# LXP v1alpha1 一致性要求

[English](conformance.en.md) | **中文主版本**

本文件定义 `loop.exchange/v1alpha1` 实现声明 conformance 时必须提供的语言无关证据；它不替代[规范](spec-v1alpha1.md)或 Schema。Public alpha 不承诺 profile 或测试向量兼容性，且当前只面向可信 Artifact。

## Profile

| Profile | 必须覆盖的行为 | 最低证据 |
|---|---|---|
| `artifact-core` | 只有 manifest/被引用 payload 的 envelope、SHA-256、safe normalized paths、唯一且可嵌套的 lexical root tree、跨 kind 全局 contract 坐标 | canonical YAML 正反向测试；拒绝冗余 `lock.yaml`、未知文件、孤儿 object、digest/size mismatch、duplicate roots、absolute/traversal/link/special entry |
| `tracking-core` | Init/Import、最长 root Add/Status、nested exclusions、父到子幂等 Apply、子到父 Export、parent provenance | 黑盒 CLI/API；失败 Import 保留并固定实现后重试、ready no-op、不同 Artifact/无 marker 非空 target/重试新增无归属内容拒绝、symlink physical alias |
| `provider-CONTRACT` | Contract/Implementation、Match、Validate、幂等/可重试 Apply、Add/Status、ExportComponent 与 distribution | 精确全局 contract 与 implementation package；未知/未绑定/mismatch/重复注册失败；重复 Apply 等价；不推进 revision、不删除 child/unowned content；deadline 与 non-interactive credential |
| `requirements-core` | 全局 Checker contract、本地 binding、只读 Check、显式 executable/MCP policy、credential handle 隔离 | 未知/未绑定 Checker 与 consumed failure；未授权 execution；secret 不进入配置、state、payload、argv 或 log；无 install/Activate |
| `standalone-portability` | 删除 exporter state 与原始 source 后从 embedded Artifact 恢复并继续下一代 | destructive 两代 Export/Import Harness；Provider-selected bytes/state 一致；仅对 contract 声明支持的 empty directory 与安全 symlink 验证 |
| `extension-helper-v1` | builtin/helper/repository binding、OCI digest 与 platform package、精确进程握手、命令级生命周期、本地 trust | Helper Provider/Checker 往返；未知 source、identity/capability/protocol mismatch 失败；未授权 namespace 不下载；OCI manifest/config/layer 正反向测试；cache 离线复用与损坏修复；取消、deadline、有界消息/诊断；无 shell 与 Artifact 授权 |
| `production-git-v1` | 官方 CLI 默认装配 `loop.exchange:git:v1` builtin，并验证等价独立 Helper；三种 distribution、递归 submodule、index selection 与最小 HEAD bundle | builtin/Helper 往返；精确握手；parent/child/grandchild 初始化；父 Apply 重试保留 child；config-only init 不访问网络；offline embedded/mirrored；gitlink 强校验；256 MiB 双向上限；拒绝不安全 submodule、secret/local locator、shallow、escaping symlink、filter 与额外 payload role |

实现只能声明实际通过的 Profile。例如只实现 Artifact codec 的库不得声明 `tracking-core`；Provider 必须连同明确的 contract version 声明 `provider-CONTRACT`。Production MVP 发布必须声明前六个基础 Profile（其中 `provider-CONTRACT` 实例化为 `provider-git-v1`）与 `production-git-v1`；公开 CLI 必须端到端通过三种 distribution 的证据。

## Canonical vectors

- [`examples/artifact/manifest.yaml`](../examples/artifact/manifest.yaml) 是可读 canonical exchange vector。
- [`examples/config/`](../examples/config/README.md) 是本地仓库与 contract→implementation binding 向量。
- [`examples/distributions/`](../examples/distributions/README.md) 提供 reference/mirrored manifest 结构；大 payload 不提交到规范仓库。
- [`examples/submodules/`](../examples/submodules/README.md) 展示由 path 推导的父子拓扑、独立 payload 与 gitlink/child revision 不变量。
- [`examples/quickstart/run.sh`](../examples/quickstart/run.sh) 是 SDK/CLI 可消费的两代黑盒旅程，不是某种语言实现的规范源。
- [`schemas/v1alpha1/`](../schemas/v1alpha1/) 定义结构约束；通过 Schema 只是 conformance 的必要条件，不是充分条件。

第三方测试报告必须记录实现版本、声明的 Profile、Provider contract、测试向量版本、平台和失败结果。不得省略失败 case，也不得把 Agent 猜测、隐式迁移或 exporter-local fallback 计为通过。
