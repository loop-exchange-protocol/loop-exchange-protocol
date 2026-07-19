# LXP — Loop Exchange Protocol

[English](README.en.md) | **中文主版本**

LXP 是面向 Agent 工作上下文的开放交换协议。它采用 Git-like 心智模型：导入不可变状态，在 Workdir 中修改并选择变更，再导出带父状态的新 Artifact。

```text
Import → Work → Add/Status → Export → Import …
```

LXP 不是部署模板、包安装器或命令工作流。YAML 是机器交换格式；日常入口是 `lxp` CLI。

![LXP 协议架构](assets/lxp-architecture.svg)

![LXP 生命周期](assets/lxp-lifecycle.svg)

## Git-like 的含义

- `lxp import` 把 Artifact 协调为可工作的 Session；失败状态可用相同命令重试。
- `lxp add PATH...` 把 selection 交给最深 owning Provider；Git Provider 使用 index。
- `lxp status` 聚合 ownership 与 Provider-native changes。
- `lxp export` 读取已选择状态并创建新的 immutable Artifact。
- `provenance.parent` 连接上一代 manifest digest，形成线性历史；v1alpha1 不定义 branch、merge、rebase。

LXP 管 ownership，Provider 管内容。Component roots 唯一且可形成严格嵌套 lexical tree；实体归最深 root，父 Provider 排除 child subtree。协议不定义 symlink/copy/mount capability 矩阵，无法安全组合时 fail closed。

## Artifact 与扩展

Artifact 只有：

```text
manifest.yaml
objects/sha256/<hex>
```

没有 `lock.yaml`，也不接受未知文件或未被 manifest 引用的孤儿 object。Manifest 已固定 revision、distribution 与 payload digest；Artifact identity 是验证通过的 `manifest.yaml` 原始 bytes 的 SHA-256，不执行 YAML canonicalization。

Provider 与 Checker 使用跨 kind 全局唯一的 `namespace:name:version` contract 坐标，例如 `loop.exchange:git:v1`。Artifact 只声明 contract，不携带实现包、仓库 URL、executable 或安装 hook。本地 [EngineConfig](examples/config/README.md) 配置有序仓库与 contract→implementation binding，并精确核验注册实现；官方 CLI 只执行 builtin Go 实现，不自动安装 repository extension。

协议保持语言无关，但项目只维护一套官方 Go 参考实现，不承诺多语言 SDK：

- [`lxp`](https://github.com/loop-exchange-protocol/lxp)：SDK、Engine 与 CLI；
- [`provider-git`](https://github.com/loop-exchange-protocol/provider-git)：`loop.exchange:git:v1`。

## Production MVP

官方组合只包含 Git Provider，完整支持 reference、embedded、mirrored `.lxpz`，默认 embedded。`lxp add` 按 gitlink 锁定 revision 初始化缺失 submodule并递归注册为独立 Component，不自动跟进远端新 revision。Import 父到子幂等 Apply，并在重建父仓时保留 child roots；Export 子到父验证 gitlink/revision。

Import 在 Component 写入前验证 Artifact、解析全部 Provider/Checker、检查 consumed Requirements，并调用所有 Provider `Validate`。Apply 失败时 Core 保留 target 与固定扩展解析的 `importing` state，不做整体 rollback；相同 Artifact 使用相同实现继续，ready Session 的相同重试是 no-op。

## 快速体验

```bash
go install github.com/loop-exchange-protocol/lxp/cmd/lxp@latest
LXP_BIN="$(command -v lxp)" examples/quickstart/run.sh
```

或手动执行：

```bash
lxp init demo
cd demo
git clone YOUR_REPOSITORY source
# 修改后只选择需要交换的 Git 变更
lxp add source/PATH
lxp export ../review-loop.lxpz

cd ..
lxp import review-loop.lxpz continued
```

## 文档

- [v1alpha1 规范](docs/spec-v1alpha1.md) · [English](docs/spec-v1alpha1.en.md)
- [Production MVP](docs/production-mvp.md) · [English](docs/production-mvp.en.md)
- [Go Engine 与 CLI](docs/go-engine.md) · [English](docs/go-engine.en.md)
- [Requirements/Checkers](docs/requirements.md) · [English](docs/requirements.en.md)
- [Distribution](docs/distributions.md) · [English](docs/distributions.en.md)
- [Conformance](docs/conformance.md) · [English](docs/conformance.en.md)
- [生态仓库](docs/ecosystem.md) · [English](docs/ecosystem.en.md)
- [Quickstart](examples/quickstart/README.md) · [English](examples/quickstart/README.en.md)
- [Artifact YAML](examples/artifact/README.md) · [English](examples/artifact/README.en.md)
- [EngineConfig YAML](examples/config/README.md) · [English](examples/config/README.en.md)
- [ContextArtifact Schema](schemas/v1alpha1/context-artifact.schema.json)
- [EngineConfig Schema](schemas/v1alpha1/engine-config.schema.json)
- [HTML 协议概览](dist/import-export-protocol.html)

## Alpha 与安全边界

`loop.exchange/v1alpha1` 是不承诺兼容性的 public alpha，只面向可信 Artifact。Schema、safe path、digest verification 与显式 execution policy 是纵深防御，不是恶意输入的完整安全边界。

```bash
make ci
```
