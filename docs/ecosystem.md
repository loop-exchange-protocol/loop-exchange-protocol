# LXP 生态仓库组织

[English](ecosystem.en.md) | **中文主版本**

LXP 采用“语言无关规范 + 一套官方参考实现 + 按领域拆分 Provider”，而不是多语言 SDK 矩阵。实现语言是技术选择，不进入仓库或 contract 名称。

GitHub Organization：[`loop-exchange-protocol`](https://github.com/loop-exchange-protocol)。

```text
loop-exchange-protocol/
├── loop-exchange-protocol # 规范、文档、Schema、案例与 Conformance
├── lxp                    # 官方 Go SDK、Engine 与 CLI
└── provider-git           # 官方 Git Provider
```

## 仓库边界

### loop-exchange-protocol

唯一语言无关规范源，包含 JSON Schema、中英文文档、canonical YAML、设计图和 Conformance 要求。它不包含实现代码，也不把文档拆到另一个仓库。

### lxp

官方参考实现，当前使用 Go，包含类型、Provider/Checker 接口、Engine、Artifact codec 与 `cmd/lxp`。仓库名不含语言前缀：项目没有维护 Java/Rust/Python SDK 系列的承诺，而且该仓库不只是 SDK。

### provider-git

实现全局 contract `loop.exchange:git:v1`，拥有 Git discovery、index selection、幂等 Apply、三种 distribution 与 submodule boundary 语义。仓库不带语言前缀；Go 是当前实现技术，不是协议身份。

旧 `go-provider-local` 已归档。File/Filesystem 不属于 Git-only Production MVP，不继续制造正式生态承诺。

## 扩展分发与贡献归属

第三方 Provider/Checker 以全局 `namespace:name:version` contract 标识，并按独立领域仓库维护 credit、发布周期与安全责任。Artifact 只声明 contract；消费端 EngineConfig 配置 builtin、本地 Helper 或 OCI contract→implementation binding。LXP 不建立中心 Registry：分发复用 OCI/GHCR，激活使用 Helper 子进程；只有本地显式 `auto_install` 与 namespace allowlist 可以下载，Artifact 不能授权。

案例保留在本规范仓库，与 Schema 同步；可执行 Harness 位于实现仓库。第三方实现只有通过适用 Conformance Profile 才能声明兼容。`v1alpha1` 不承诺兼容性，当前只面向可信 Artifact。
