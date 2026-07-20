# LXP v1alpha1 规范

[English](spec-v1alpha1.en.md) | **中文主版本**

状态：public alpha；不承诺向前或向后兼容。`MUST`、`MUST NOT`、`SHOULD`、`MAY` 按 RFC 2119 解释。首个可部署子集见 [Production MVP](production-mvp.md)：可信环境、官方 `loop.exchange:git:v1`、reference/embedded/mirrored `.lxpz`。

## 1. 目标与生命周期

LXP 以 Git-like 方式追踪和交换 Agent 工作上下文：

```text
Import → Work → Add/Status → Export → Import …
```

Import 把不可变 Artifact 协调为工作 Session；Work 修改已物化内容；Add 让 owning Provider 选择变更或注册 ownership root；Status 聚合 Core 与 Provider 状态；每次 Export 创建新的不可变 Artifact。

标准 CLI SHOULD 提供 `init`、`import`、`add`、`status`、`export`。Worktree 根的 `.lxp` 是本地 discovery/state directory，MUST NOT 导出。LXP 不定义部署渲染、命令工作流、hidden reasoning、外部副作用或 execution replay。YAML 是机器交换格式，不要求用户日常手写。

## 2. Artifact 与历史

逻辑 Artifact 是 `.lxp` 目录；`.lxpz` 是等价的 gzip tar envelope：

```text
manifest.yaml
objects/sha256/<hex>
```

Artifact 具有 `namespace/name/version` 可读坐标；Artifact 内经过解析与 Schema 验证的 `manifest.yaml` 原始 bytes 直接计算 SHA-256，得到不可变身份，不执行 YAML canonicalization。同一坐标不得解析为不同 bytes。`provenance.parent` MAY 指向直接父 digest，形成线性历史；v1alpha1 不定义 branch、merge、rebase 或多父历史。

Artifact 不包含 `lock.yaml`。Component revision、distribution 和 payload digest 已由 manifest 固定；重复一份可漂移的 portable lock 没有额外权威性。实现 MAY 保存本地扩展解析或 Requirement observed state，但它们不是 Artifact 内容，也不得改变 Artifact 身份。

完整交换格式见 [manifest.yaml](../examples/artifact/manifest.yaml)，Schema 为 [ContextArtifact](../schemas/v1alpha1/context-artifact.schema.json)。Importer MUST 在调用 Provider 前验证 archive path、manifest、所有 payload digest 与 size，并拒绝 `manifest.yaml` 与实际引用的 `objects/sha256/<hex>` 之外的文件或孤儿 object。Archive MUST NOT 包含 absolute path、parent traversal、link、device 或其他特殊 entry。

## 3. Component ownership

Component 是由一个 Provider 管理并物化到 Session 相对路径的持久内容单元：

```yaml
components:
  - id: source
    path: repositories/source
    provider:
      namespace: loop.exchange
      name: git
      version: v1
    distribution: embedded
```

- Component path MUST 是安全 normalized relative path，且不得位于 `.loop` 或 `.lxp`。
- Roots MUST 唯一，并 MAY 形成严格嵌套 lexical tree；不得以 symlink alias 绕过该树。
- LXP 拥有 root、identity、routing、Requirement 与交换 envelope；Provider 拥有内容语义。
- 实体 path 由最深 root 唯一拥有。祖先 Provider MUST 排除 direct child subtree；无法安全组合时 MUST fail closed。
- Core 不定义 symlink、copy、mount 或 capability 矩阵。本地 Provider 决定物理组合，不得把物化路径或能力写进 Artifact。
- 本地 containment 与 Session discovery MUST 解析既有 symlink prefix 后使用物理绝对路径；结果不得进入 Artifact。
- `lxp add` MAY 调用 Provider-native child discovery。发现的 child 必须独立注册；Core 不猜测未知 marker。

普通 path 操作路由给最深 owning Provider。父 Provider MAY 维护 gitlink 等 boundary metadata，但不得读取或导出 child 实体内容。

## 4. 全局 Contract 坐标

Provider 与 Checker 使用相同的全局 contract 坐标：

```yaml
namespace: loop.exchange
name: git
version: v1
```

文本形式是 `namespace:name:version`，例如 `loop.exchange:git:v1`。`namespace` MUST 是实现维护者控制的 DNS namespace；`name` 在 namespace 内唯一；`version` 标识精确 contract。坐标在 Provider 与 Checker 两种 kind 之间也 MUST 全局唯一，不得把同一坐标复用为不同 kind。实现语言不得进入 contract 身份。

Artifact 只声明 contract，不声明实现包、仓库、下载 URL 或 executable。Engine MUST 使用本机 [EngineConfig Schema](../schemas/v1alpha1/engine-config.schema.json) 将 contract 绑定到精确实现坐标；无法解析、kind 不匹配或 contract 不匹配 MUST 在 Component 副作用前失败。

EngineConfig 中 `repositories` 是本地有序 OCI 候选仓库列表，`bindings` 把 Provider/Checker contract 映射到精确 implementation package 坐标。Repository ID MUST 唯一；每个 contract MUST 只有一个 binding，并不得跨 Provider/Checker kind 复用。Binding 可选择 `builtin`、本地 `helper` argv 或 `repository`；后者 MUST 固定 OCI manifest SHA-256，并且只有 `auto_install: true` 且显式信任 implementation namespace 的仓库可以下载。当前仓库没有该 digest 时继续下一个；一旦取得内容，digest、descriptor、platform 或握手不符 MUST 立即失败，不得继续搜索或降级。仓库 credential 只能引用本地 secret handle，值不得写入配置。Artifact 不得覆盖仓库顺序、镜像、trust 或安装 policy。完整规则见[扩展与 Helper 协议](extensions.md)，配置案例见 [engine-config.yaml](../examples/config/engine-config.yaml)。

每个本地 Provider/Checker，不论 builtin 或 Helper，MUST 声明自己的 implementation package 坐标。Engine 在新的或 `importing` 状态的 Import，以及 Add、Status、Export 前 MUST 精确比较 registration/握手结果与 binding；不得因为 contract 相同就使用另一个 package/version。Import 首次进入 `importing` 时 MUST 把解析结果固定在本地 Session state；重试配置发生变化时必须失败，不得换实现继续 Apply。相同 digest 的 `ready` Session 在安全验证 envelope 与本地身份后直接 no-op，不再解析扩展、运行 Checker 或调用 Provider。该 state 不是 Artifact 内容。

`v1alpha1` 定义 language-neutral Helper 进程协议与 platform-specific OCI Extension Package，不定义 in-process ABI，也不承诺多语言 SDK。Engine MAY 在本地 policy 已明确启用时按 digest 自动下载 Helper；MUST 直接执行 argv、精确握手、传播 deadline、限制诊断并在命令结束时关闭进程。Artifact 单独声明 contract 永远不能授权安装或执行。官方默认组合 MAY 内置 Git Provider 以避免首次使用依赖网络，同时必须允许本地 EngineConfig 选择独立 Helper。

## 5. Provider contract

Provider-specific `config` 与 payload role 对 Core opaque。Provider contract 包含：

- `Contract`：返回全局坐标；
- `Match`：只在未归属 root 判断 native marker；
- `Validate`：无 Component 写副作用地验证 desired state、distribution、payload 与 direct child boundary；
- `Apply`：把 desired Component 协调到 target，返回 observed state；
- `Add` / `Status`：实现 native change-selection；
- `DiscoverChildren`、`TrackChild`（可选）：发现 native child 与维护 boundary metadata；
- `ExportComponent`：产生 immutable reference、embedded payload 或两者。

`Apply(desired, target)` MUST 幂等且可重试：相同 desired state 和已完成 target 返回相同 observed state；遇到本 Provider 在同一未完成 Import 中留下的部分状态，应继续或安全重建自己的 root；不得推进到未声明 revision、删除 child root 或改写无归属内容。Provider 不提供 Core rollback，也不得依赖全局 transaction。

可能访问外部服务或启动 executable 的操作 MUST 继承 cancellation/deadline；调用方没有 deadline 时实现 MUST 使用有限默认值。Provider MUST 禁止 interactive credential，且 diagnostic output MUST 有界。Secret、本地 target、socket、PID、port、credential handle 与 Provider Store path MUST NOT 进入 Artifact。

## 6. Add、Status 与 Export selection

`lxp add PATH...` 使用最长 ownership root：已有 root 内调用 owning Provider；未归属或新发现 child root 先由本地已解析 Provider 唯一 Match 并注册；零匹配或同优先级多匹配失败。`.lxpignore` 只作用于未归属 root。存在既未 owned 也未 ignored 的 path 时 Export MUST 失败。

`lxp status` MUST 报告 Component roots、Provider-native changes、未归属与 ignored paths。Export MUST 使用 Provider 选择的当前状态；Git Provider 的 Add/Status 与 Git index 对齐，Git-untracked 内容不得静默导出。

每个 Component 声明一种 distribution：

- `reference`：immutable Provider-native locator + revision；
- `embedded`：Artifact 内的 content-addressed payload；
- `mirrored`：相同 revision 的 reference 与 embedded fallback。

Mirrored MUST 先尝试 reference；只有 source 不可用等 contract 声明的可恢复错误才能切换到已经校验的 fallback。Fallback 清理由 owning Provider 在自己的 Component root 内完成，不是 Core 全局回滚。Standalone embedded/mirrored fallback 在删除 exporter Engine state 与原始 source 后仍必须可导入。

## 7. Requirements 与 Checker

Requirement 是只能观察、不能作为 Component 交换的外部条件。Check 使用全局 Checker contract：

```yaml
requirements:
  - id: git-cli
    check:
      checker:
        namespace: loop.exchange
        name: executable
        version: v1
      config:
        command: git
        args: [--version]
```

Checker-specific `config` 对 Core opaque。Checker MUST 是只读、有界、幂等的观察；它不得安装软件、构建 Component、留下服务或满足 Requirement。Fulfillment 属于用户、Agent Harness、平台或环境管理器；之后重新 Check。

被 `component.requires` 引用的 Requirement 在 Apply 前必须 ready；未消费项仍可显示但不阻塞。Executable/MCP Check 必须由本地 policy 显式授权，不得执行 shell fragment。Secret value MUST NOT 进入 manifest、payload、argv、log、Conversation 或 provenance。

## 8. Import：验证后协调

Importer MUST：

1. 安全解包并验证 Schema、roots、payload digest/size；
2. 根据本地 EngineConfig 精确解析全部 Provider 与 Checker contract，必要时从已授权 OCI 仓库按 digest 安装并握手 Helper；
3. 执行受 policy 允许的 Requirement Check，并在任何 Component 写入前确认所有 consumed Requirement ready；
4. 无副作用调用所有 Provider `Validate`；
5. 写入本地 `importing` marker，然后按父到子调用 `Apply`，每个成功 observed state 原子记录；
6. 全部完成后原子标记 Session `ready` 并暴露 Workdir。

首次 Import 的 target MUST 不存在或为空。重试只允许进入带有同一 Artifact digest、Session ID 与 `importing` marker 的 target；不同 Artifact、已存在 symlink 或无归属内容 MUST 失败。相同 Artifact 的 `ready` Session 重试 MUST 是 no-op。

某 Component 失败时 Import 返回错误并保留 target、已完成 observed state 与 marker，以便相同命令重试。重试 target 中除 `.lxp`、desired Component root 及其祖先外出现无归属内容 MUST 失败。Core MUST NOT 回滚已成功 Component，也不得删除整个 target。局部临时文件与 owning Provider 的部分 root 可由各自实现清理。Helper 安装与握手属于本地 extension resolution；Import 不包含 Artifact 驱动的 install、build 或独立 Activate 阶段。

## 9. Export

Exporter MUST：读取 ownership；聚合 Status；拒绝未归属 path；按子到父调用 `ExportComponent`，使父 Provider 可验证 child identity 与 native attachment；验证 immutable reference 与 payload；设置可选 parent digest；原子写入 Artifact。每次 Export 都创建新身份，不修改旧 Artifact。

## 10. Conversation、安全与一致性

Conversation 作为普通 Component 内容交换；Production MVP 要求位于 Git-managed Component 内。`continue` 只表示可移植消息与已完成 tool event 可以追加；历史 tool call MUST NOT 重放。Private cache、hidden reasoning、approval state 与外部 transaction 不在保证范围内。

`v1alpha1` 只面向可信 Artifact，不承诺兼容性。Validation、safe extraction、digest verification 与 execution policy 是纵深防御，不构成恶意输入的完整安全边界。

Conformance Harness MUST 验证三种 distribution、删除 exporter source 后的 standalone Import、相同 Import 的失败重试和 ready no-op、Provider/Checker contract mismatch、Requirement、secret non-disclosure、第二代 Export/Import、path traversal 与 digest tamper。
