# LXP Requirement 检查模型

[English](requirements.en.md) | **中文**

本文解释 [v1alpha1 规范](spec-v1alpha1.md)定义的 Requirement 模型；当前实现范围见 [Go Engine MVP](go-engine.md)。

## 边界

LXP 将可移植工作单元与外部条件分开：

- `components` 保存 Provider 可以 resolve/restore、materialize、activate 并按 reference、embedded 或 mirrored 导出的持久状态；
- `requirements` 声明只能检查的条件，例如 host executable、MCP interface、external service 或 local credential。

Requirement 不是弱化的 Component，没有 Provider、materialization、activation 或 snapshot 生命周期。

## 生命周期

所有 Requirement 都使用：

```text
Declare → Check → Satisfied | Unsatisfied
```

Fulfillment 不是 Requirement 阶段。Component activation、Engine、平台、用户、Agent 或外部环境管理器都可以满足条件；LXP 随后重新执行 Check。

## Check contract

```yaml
requirements:
  - id: git-cli
    description: Git executable used by a Component Provider
    prompt: Install Git or make it available on PATH, then refresh.
    check:
      type: executable
      command: git
      args: [--version]
```

MVP 定义三种 Check：

- `executable`：定位裸 executable name，并可选择运行 argv-only probe；
- `mcp`：初始化 MCP stdio endpoint、发现 tools 并比较 contract；
- `credential`：解析允许的本地 credential scheme，不暴露 secret value。

Check 只在本地 policy 允许时执行。不得解释 shell fragment、pipeline、redirection、substitution、Prompt 或 package-local lifecycle script。

## 结果与 Prompt

Engine 在 activation 前展示完整 Requirement checklist。每项包含 ID、status、detail、action、Prompt 与 Prompt source。Prompt 是带来源的 transportable metadata，不是 executable protocol；LXP 不会静默执行它。

## 与 Component 的关系

Component 声明消费什么，Requirement 声明由谁产生：

```yaml
components:
  - id: github-mcp
    requires: [github-token]

requirements:
  - id: github-token
    check:
      type: credential
      accepts: [environment, bearer-token]
  - id: github-mcp-ready
    provided_by: component:github-mcp
    check:
      type: mcp
      command: github-mcp-server
      required_tools: [repository.get]
```

`requires` 必须在 activation 前 satisfied。`provided_by` 默认为 `environment`；`component:<id>` 表示该 Component activate 后再检查。声明 producer 不等于证明 satisfied。

Requirement 没有独立 `required` flag。被 `component.requires` 引用时才阻塞该 Component；未消费 Requirement 仍显示，但 unsatisfied 不会让 Import 失败。

两类声明形成由 Component Activate 与 Requirement Check 节点组成的受限二部 DAG。Engine 拒绝缺失引用、歧义 producer 和 cycle；独立 ready node 可以并发执行。

## 有界 Activation

Activate 可以安装、构建、初始化并生成配置，但必须结束，不能留下由 LXP 所有的 process、socket、port 或 credential handle。MVP 没有 Deactivate 或 Activation Handle；长期服务由 Agent Harness 或 host platform 管理。

MCP Check 可以临时启动 stdio process、初始化、检查 tool contract，然后关闭。Satisfied 表示 endpoint 可启动且 contract 兼容，不表示 LXP 会保持服务运行。

Provider 在 activation 时可以按 Requirement ID 请求授权 credential handle；Engine 将其限制在目标操作，防止值进入 file、lock、log、payload、Provider Store 或 Artifact。

## 扩展模型

Check type 是可信 Engine interface，与 Component Provider 分离。未知 Check type 保持 unsatisfied，不是让 Agent 自行推断的指令。

LXP 不提供通用 `RUN` primitive。可复现环境定义或已审查脚本可以作为 Component 内容运输，但执行只能是受本地 policy 管理的显式 Provider 操作。
