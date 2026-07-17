# LXP 生态仓库组织

[English](ecosystem.en.md) | **中文主版本**

LXP 的规范、Schema、权威文档、案例和一致性要求同源；SDK 按语言发布；Provider 按“语言 × 领域”独立发布，以保留清晰的发布周期、依赖边界和贡献归属。

GitHub Organization：[`loop-exchange-protocol`](https://github.com/loop-exchange-protocol)。

```text
loop-exchange-protocol/
├── loop-exchange-protocol # 唯一规范源、文档、Schema、案例与 Conformance 要求
├── go-sdk                 # Go SDK、Engine 与官方 lxp CLI
├── go-provider-git        # Go Git Provider
└── go-provider-local      # 实验性 Go file@v1 与 filesystem@v1 Providers
```

## 仓库边界

### loop-exchange-protocol

协议文本、JSON Schemas、中英权威文档、canonical YAML、完整用户案例和 SDK-neutral Conformance 要求。它不包含特定语言实现，也不把文档拆到另一个仓库，避免规范漂移。

### go-sdk

Go 类型、Provider 接口、Engine 与官方 CLI。CLI 是各 Provider 的 composition root；SDK Core 不导入具体 Provider。只有真正出现第二语言实现时才建立对应 SDK 仓库。

### go-provider-git

实现 `git@v1`。它拥有 Git discovery、selection、materialization、export 与 restore 语义，独立记名和发布。

### go-provider-local

实验性实现 `file@v1` 与 `filesystem@v1`。二者共享本地路径、symlink 与 archive 安全模型，因此保持同仓库；它们不注入官方 CLI，也不属于 Production MVP conformance。

## 案例与一致性

案例保留在本仓库 `examples/`，与其解释的规范和 YAML 同步。可执行 Harness 可由 SDK 仓库消费，但 `docs/conformance.md` 和 `schemas/` 始终是权威来源。第三方实现只有通过适用 profile 才能声明 conformant。

Provider Registry 等到第三方数量产生真实的发现、签名、撤回和版本治理需求后再建立。Public alpha 不维护空壳 Registry。

拆分不得复制规范源。实现仓库只能链接或消费带版本的规范；`loop.exchange/v1alpha1` 不承诺兼容性，当前仅面向可信 Artifact。
