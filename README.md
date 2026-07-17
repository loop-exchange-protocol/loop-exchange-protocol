# LXP — Loop Exchange Protocol

[English](README.en.md) | **中文主版本**

LXP 是一套面向 Agent 工作上下文的开放交换协议。它采用 Git 的心智模型：导入一个不可变状态，在工作区中修改和选择变更，再导出一个有父状态的新快照。

```text
Init/Import → Work → Add → Status → Export
                         │             │
                         └── Provider ─┘
```

LXP 不是部署模板、包安装器或工作流语言。YAML 是机器交换格式，日常入口是 CLI；Production MVP 的 Artifact 自包含、内容寻址且不可变。

![LXP 协议架构](assets/lxp-architecture.svg)

![LXP 生命周期](assets/lxp-lifecycle.svg)

## Git-like 的含义

- `lxp import`：从 Artifact 恢复一个可工作的 Session。
- `lxp add PATH...` 类似 `git add`：把选择权交给拥有该路径的 Provider。
- `lxp status` 聚合顶层 ownership 与 Provider-native 状态。
- `lxp export` 类似 `git commit` 加可移植打包：读取 Provider 已选择的状态并创建新的不可变 Artifact。
- `provenance.parent` 连接上一代 Artifact digest，形成线性历史；`v1alpha1` 暂不定义 branch、merge 或 rebase。

这里的类比止于使用习惯。协议允许不同类型的 Provider；首个 Production MVP 只承诺 Git repository Component，其他 Provider 不进入最小生产边界。

## 核心规则

1. **LXP 管 ownership，Provider 管内容。** Component root 一旦注册，其内部对 Core 不透明。
2. Component roots 必须互不重叠。Core 不递归解释已归属目录内的 `.git`、`.oss` 或其他 marker。
3. `lxp add` 位于已有 Component 内时调用 owning Provider 的 `Add`；位于未归属 root 时才执行 Provider discovery 并注册新 Component。
4. Provider 由稳定的 `provider + contract` 标识；Provider-specific `config` 对 Core 不透明。
5. 递归、嵌套或复合语义由一个 composite Provider 自己实现，Core 仍只看到一个 Component。
6. Artifact 不携带 Provider 可执行代码。Importer 必须预装并信任匹配 contract 的 Provider，否则失败。
7. Provider 可用 symlink、Git worktree、copy、reflink 或 mount 物化；协议只要求声明路径上的结果一致。
8. Production MVP 只装配 `git@v1` 并只导出 embedded Artifact；无匹配 Provider 时失败。

## 快速体验

先从 [`go-sdk`](https://github.com/loop-exchange-protocol/go-sdk) 安装 `lxp` CLI。最快的方式是把该二进制交给完整黑盒 Quickstart：

```bash
LXP_BIN="$(command -v lxp)" examples/quickstart/run.sh
```

它会真实执行两代 `init/import/add/status/export`，删除原工作区验证 standalone portability，并打印 CLI 生成的 Artifact YAML。手动最短路径是：

```bash
lxp init demo
cd demo
git clone YOUR_REPOSITORY source
# 修改内容后只选择需要交换的 Git 变更
lxp add source/PATH

lxp export ../review-loop.lxpz

cd ..
lxp import review-loop.lxpz continued
```

Git Component 内的 `lxp add` 调用 Git Provider 的原生 index 语义，不创建嵌套 Component。未归属 path 没有匹配 Provider 时失败。`lxp import` 会在任何副作用前验证 Artifact、展示 Provider actions 并检查 Requirements。

## 文档

- [v1alpha1 规范](docs/spec-v1alpha1.md) · [English](docs/spec-v1alpha1.en.md)
- [Production MVP Profile](docs/production-mvp.md) · [English](docs/production-mvp.en.md)
- [Go SDK 与 CLI](docs/go-engine.md) · [English](docs/go-engine.en.md)
- [Requirements](docs/requirements.md) · [English](docs/requirements.en.md)
- [v1alpha1 一致性矩阵](docs/conformance.md) · [English](docs/conformance.en.md)
- [生态仓库组织](docs/ecosystem.md) · [English](docs/ecosystem.en.md)
- [Git-like CLI 示例](examples/git-like/README.md) · [English](examples/git-like/README.en.md)
- [完整可执行 Quickstart](examples/quickstart/README.md) · [English](examples/quickstart/README.en.md)
- [Artifact YAML 示例](examples/artifact/README.md) · [English](examples/artifact/README.en.md)
- [ContextArtifact Schema](schemas/v1alpha1/context-artifact.schema.json)
- [Artifact Lock Schema](schemas/v1alpha1/artifact-lock.schema.json)
- [HTML 协议概览](dist/import-export-protocol.html)

## Alpha 与安全边界

`loop.exchange/v1alpha1` 是 public alpha，**不承诺任何向前或向后兼容性**。本阶段仅处理可信 Artifact。Schema、路径与 digest 验证以及显式 execution policy 是纵深防御，不构成处理恶意 Artifact 的完整安全边界。

```bash
make ci
```
