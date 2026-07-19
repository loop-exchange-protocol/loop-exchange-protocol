# LXP Requirement 与 Checker 模型

[English](requirements.en.md) | **中文主版本**

本文解释 [v1alpha1 规范](spec-v1alpha1.md)的 Requirement 模型。

## 边界与生命周期

Component 保存 Provider 能够 Apply 和 Export 的持久内容；Requirement 描述只能在消费端观察的外部条件，例如 executable、MCP interface 或 credential binding。

```text
Declare → Check → Ready | Unavailable
```

Requirement 不是弱化的 Component，没有物化、安装、构建、Activate 或 snapshot 生命周期。Checker 只观察；用户、Agent Harness、平台或环境管理器负责满足条件，然后重新 Check。

## 全局 Checker contract

Checker 与 Provider 使用同一种 `namespace:name:version` 坐标：

```yaml
requirements:
  - id: git-cli
    description: Git executable used by the Git Provider
    prompt: Install Git or make it available on PATH, then refresh.
    check:
      checker:
        namespace: loop.exchange
        name: executable
        version: v1
      config:
        command: git
        args: [--version]
```

`check.config` 由精确 Checker contract 定义，对 Core opaque。官方 MVP 内置：

- `loop.exchange:executable:v1`：定位裸 executable name，并以 argv-only probe 观察版本；
- `loop.exchange:mcp:v1`：临时初始化 MCP stdio endpoint、发现 tools、比较 contract 后关闭；
- `loop.exchange:credential:v1`：观察允许的本地 credential scheme，不读取或输出 secret value。

未知 Checker、缺失本地 binding 或 contract mismatch 保持不可用；Artifact 不能指定实现包或触发安装。

## 消费关系与结果

Component 通过 `requires` 声明消费项：

```yaml
components:
  - id: source
    requires: [git-cli]
```

被消费的 Requirement 必须在任何 Component Apply 前 ready；未消费项仍显示，但不阻塞 Import。由于 Checker 不产生 Component state，也没有 `provided_by`、activation DAG 或隐式 fulfillment。

`lxp requirements` 与 Import checklist 返回 ID、Checker coordinate、status、detail、action、Prompt 和 Prompt source。Prompt 是 metadata，不是 executable protocol。Executable/MCP Check 需要本地 policy 显式授权，不得解释 shell fragment、pipeline、redirection 或 package lifecycle script。

Credential 配置只声明接受的 scheme 与 secret slot 名称。值只能通过不可序列化的本地 handle 提供，不能进入 Artifact、EngineConfig、payload、argv、log、Conversation 或本地 Requirement state。

## 扩展解析

Artifact 声明 Checker contract；本机 EngineConfig 把它绑定到 implementation package。仓库、镜像、实现版本、digest 与 credential 都由消费端 policy 控制。官方 CLI 只执行编入二进制的 Go Checker；v1alpha1 不要求自动安装或多语言 SDK。
