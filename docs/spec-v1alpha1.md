# LXP v1alpha1 规范

[English](spec-v1alpha1.en.md) | **中文主版本**

状态：public alpha；不承诺向前或向后兼容。`MUST`、`MUST NOT`、`SHOULD`、`MAY` 按 RFC 2119 解释。首个可部署子集由 [Production MVP Profile](production-mvp.md) 定义：可信环境、官方 `git@v1`、embedded-only。

## 1. 目标与生命周期

LXP 以 Git-like 方式追踪和交换 Agent 工作上下文：

```text
Import → Work → Add/Status → Export → Import …
```

Import 从不可变 Artifact 创建工作 Session；Work 修改已物化内容；Add 让 owning Provider 选择变更或注册新的 ownership root；Status 聚合 Core 与 Provider 状态；Export 创建新的不可变 Artifact。

标准 CLI SHOULD 提供 Git-like `init`、`import`、`add`、`status`、`export`。Worktree 根的 `.lxp` 是 local discovery/state directory，MUST NOT 导出；从 Worktree 子目录执行命令时 SHOULD 自动发现它。`import` 从 Artifact 创建可工作的 Session，`export` 对应选择状态后的 immutable checkpoint。

LXP 不定义部署渲染、命令工作流、模型输出重放、hidden reasoning、外部副作用或 in-flight operation。YAML 是机器交换格式，不是要求用户日常手写的配置语言。

## 2. Artifact 与历史

逻辑 Artifact 是 `.lxp` 目录；`.lxpz` 是等价的 gzip tar envelope：

```text
manifest.yaml
lock.yaml
objects/sha256/<hex>
```

Artifact 具有 `namespace/name/version` 可读坐标，`manifest.yaml` 的 SHA-256 digest 是不可变身份。同一坐标不得解析为不同 bytes。`provenance.parent` 可指向直接父 Artifact digest，从而形成线性历史。`v1alpha1` 不定义 branch、merge、rebase 或多父历史。

完整、经过实现校验的交换格式见 [manifest.yaml](../examples/artifact/manifest.yaml) 与 [lock.yaml](../examples/artifact/lock.yaml)；对应 Schema 为 [ContextArtifact](../schemas/v1alpha1/context-artifact.schema.json) 和 [Artifact Lock](../schemas/v1alpha1/artifact-lock.schema.json)。

Importer MUST 在调用 Provider 前验证 archive path、manifest lock、payload digest 与 size。Archive MUST NOT 包含 absolute path、parent traversal、link、device 或其他特殊 entry。

## 3. Component ownership

Component 是一个由 Provider 管理并物化到 Session 相对路径的持久内容单元。

```yaml
components:
  - id: source
    path: repositories/source
    provider: git
    contract: v1
    config: {}
    distribution: embedded
    embedded:
      revision: 0123456789abcdef0123456789abcdef01234567
      payloads:
        base:
          media_type: application/vnd.git.bundle
          digest: sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
          size: 123
```

以下规则是规范不变量：

- Component path MUST 是安全 normalized relative path，且不得位于 local-only `.loop` 或 `.lxp`。
- 所有 Component roots MUST prefix-free：任意 root 不得等于、包含或被另一 root 包含。
- Engine 只拥有 root、identity、Provider routing、Requirements 与交换 envelope。
- Component root 内部对 Core MUST opaque。Core MUST NOT 递归解释内部 marker，也不得自动创建嵌套 Component。
- 路径一旦位于 Component root 内，操作 MUST 路由给 owning Provider。“从哪里来就到哪里去，原来谁管就交回谁管”。
- 需要递归或嵌套语义时，MAY 使用拥有整个 root 的 composite Provider；其内部 child 不是 Core Component。

## 4. Provider contract

Provider identity 由稳定的 `provider` ID 与 `contract` version 共同组成。`config` 是 Provider-specific object，Core MUST 保真传输但 MUST NOT 解释其字段。Provider payload role 同样由 contract 定义。

Provider contract 包含：

- `Match`：只在未归属 root 上判断 marker/内容是否匹配；
- `Resolve`：把 selector 固定为不可变 descriptor；
- `Materialize` / `Restore`：在声明路径产生可用内容；
- `Plan`：在执行前暴露 Requirements、动作与安全影响；
- `Add`：选择 Provider-native 变更；
- `Status`：返回 Provider-native tracked/untracked/ignored 状态；
- `Activate`：在 Requirements 满足后执行 bounded activation；
- `ExportComponent`：产生 immutable reference、embedded payload 或两者。

Artifact MUST NOT 携带 Provider executable、plugin binary 或安装 hook。Importer MUST 只使用本地预装且受信任的匹配 contract；缺失或版本不匹配 MUST 失败，不得降级或要求 Agent 猜测迁移。

Provider MAY 使用 symlink、Git worktree、copy、reflink、mount 等机制。LXP 只规范声明路径上的语义结果，不规范本地实现机制；任何本地目标路径、socket、PID、port、credential handle 或 Provider Store path MUST NOT 进入 Artifact。

## 5. Add 与 discovery

`lxp add PATH...` 必须遵循最长 ownership root 路由：

1. PATH 位于已有 Component 内：调用该 Provider 的 `Add`；不得注册子 Component。
2. PATH 是未归属 root：调用受信任 Provider 的 `Match`，注册唯一匹配 Provider 后再调用 `Add`。
3. 无 Provider 匹配：失败；Core 不猜测或隐式安装 fallback Provider。
4. 多 Provider 匹配：失败并要求调用者显式选择。

标准 discovery marker 只在首次注册时有意义：`.git` 匹配 `git@v1`；第三方 marker（如 `.oss`）由相应 Provider contract 定义。Artifact manifest 是后续 Import 的唯一 portable routing truth，marker 不是。

`.lxpignore` 使用 gitignore pattern，只作用于未归属 root；不得改变 Provider 内部 tracking rule。存在既未 owned 也未 ignored 的路径时 Export MUST 失败。

## 6. Status 与 Export selection

`lxp status` MUST 同时报告：Component roots、Provider-native changes、未归属 paths 与 ignored paths，并提供 structured output。Core 不得把 Provider 内部 untracked path 误报为顶层 ownership 缺失。

Export MUST 读取 Provider 选择的当前状态。Git Provider 的 Add/Status 语义与 Git index 对齐。Export MUST NOT 静默包含 Git-untracked 内容。

每个 Component 记录实际 distribution：

- `reference`：不可变 Provider-native locator + revision；
- `embedded`：Artifact 内的内容寻址 payload；
- `mirrored`：同一状态的 reference 与 embedded fallback。

不支持的 distribution MUST 失败。Standalone Artifact 的所有消费内容必须 embedded，并能在 exporter Engine state 与原始 source 删除后 Import。Production MVP 只允许 embedded；reference 与 mirrored 保留为实验性 wire capability，不属于生产 conformance。

## 7. Requirements 与 activation

Requirement 表示不能作为 portable Component state 交换的条件。MVP Check type 为 `executable`、`mcp`、`credential`。Check 是 Engine interface，不是 Component Provider。

Engine MUST 在 materialization/activation 前展示 Provider Plan 与 Requirement checklist。Executable/MCP action 需要显式 Import policy；不得执行 shell fragment。Secret value MUST NOT 进入 manifest、lock、payload、argv、log、Conversation 或 provenance。Provider 只能在被授权的单次操作中使用不可序列化 local credential handle。

`component.requires` 与 `requirement.provided_by` 构成的依赖图 MUST 无环。Consumed Requirement 未满足时 Import MUST 失败；未消费项保持可见但不阻塞。

## 8. Conversation

Conversation 作为普通 Component 内容交换；Production MVP 要求它位于 Git-managed Component 内。`continue` 只表示 portable messages 与已完成 tool events 可交给兼容 Agent 并追加；历史 tool call MUST NOT 在 Import 时重放。Private cache、hidden reasoning、approval state 与外部 transaction 不在保证范围内。

## 9. Import 算法

Importer MUST：安全解包；验证 schema/lock/digest；验证 paths prefix-free；定位精确 Provider contract；在任何 materialization/activation 副作用前展示内部 Provider Plan/Requirements 并应用本地 policy；restore/materialize；按依赖顺序 activate；写 local lock；暴露 Workdir。Plan 是 Import preflight contract，不要求独立 CLI。任何未知 Provider、contract mismatch、digest、Requirement 或 activation failure 都 MUST 终止 Import。

## 10. Export 算法

Exporter MUST：读取 ownership；聚合 Status；拒绝未归属 path；调用各 Provider ExportComponent；验证 immutable reference 与 payload；设置可选 parent digest；原子写入 Artifact。每次 Export 都创建新身份，不修改旧 Artifact。

## 11. 安全与一致性

`v1alpha1` 仅面向可信 Artifact。Validation、safe extraction、digest verification 与 execution policy 是纵深防御，不构成恶意输入的完整安全边界。

Conformance harness MUST 删除 exporter root 与原始 source 后导入 standalone Artifact，并验证 Provider 所选择的 bytes/state、Requirements、secret non-disclosure、第二代 Export/Import、path traversal 与 digest tamper。Empty directory 与安全 symlink 只在对应 Provider contract 声明支持时验证；`git@v1` 遵循 Git tree 语义，不表示未追踪空目录。
