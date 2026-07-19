# LXP Production MVP Profile

[English](production-mvp.en.md) | **中文主版本**

本文定义 `loop.exchange/v1alpha1` 首个可部署子集。它面向同一信任域内的工程团队与自动化系统，不把 LXP 当作恶意输入沙箱，也不承诺 v1alpha1 兼容性。

## 工作循环与 CLI

```text
Init / Import → Work → Add/Status → Export → Import …
```

公开 CLI 冻结为：

```text
lxp init [WORKDIR]
lxp add [--provider NAMESPACE:NAME:VERSION] PATH...
lxp status [--format text|json]
lxp export [--distribution reference|embedded|mirrored] ARTIFACT.lxpz
lxp import ARTIFACT.lxpz [WORKDIR]
lxp inspect ARTIFACT.lxpz
lxp requirements [--format tui|json] ARTIFACT.lxpz
```

Import 在任何 Component 写入前验证完整 Artifact、解析全部扩展、检查 consumed Requirements，并调用所有 Provider `Validate`；随后父到子 `Apply`。没有公开或内部 Plan command、install、build、Activate 或 Core rollback 阶段。

## 官方实现与扩展

- 官方参考实现仓库是 [`lxp`](https://github.com/loop-exchange-protocol/lxp)，使用 Go，包含 SDK、Engine 与 CLI；项目不承诺维护其他语言 SDK。
- 官方唯一内容实现是 [`provider-git`](https://github.com/loop-exchange-protocol/provider-git)，contract 为 `loop.exchange:git:v1`；没有 File/Filesystem fallback。
- Provider/Checker 使用跨 kind 全局唯一的 `namespace:name:version` 坐标，并声明精确 implementation package。Artifact 只声明 contract；本机 EngineConfig 配置有序仓库与 implementation binding，所有操作核验实际注册实现，Import 重试固定首次解析。
- 官方 CLI 只执行 `source: builtin` 的 Go 实现。它解析配置，但不自动下载或执行 repository extension；Artifact 永远不能覆盖仓库、镜像、trust 或安装 policy。
- Git Provider 依赖预装的受信任 Git CLI，这是宿主前提，不是 Artifact 携带的 executable。

## Git ownership 与 selection

每个 Git repository 是独立 Component。Conversation、Skill、结果或其他上下文只有位于该仓库并由 Git index 选择，才能进入 Artifact。未归属 path 没有 Provider 匹配时，Add 与 Export 失败。

`lxp add` 从 index gitlink 发现 submodule；缺失 worktree 按 gitlink 锁定 commit 逐层初始化，并递归注册为嵌套 `loop.exchange:git:v1` Component。已初始化 child 不会隐式 fetch 或前进到远端新 revision。Child 内 path 选择 child index，选择 child root 同步父 gitlink。

父 Provider 只拥有 `.gitmodules` 与 gitlink boundary，不导出 child objects。Import 父到子 Apply，父仓以 config-only `git submodule init` 幂等修复 native config且不 fetch/checkout；Git Apply 重建父 root 时必须保留声明的 child roots。Export 子到父，父 Provider 验证 selected gitlink 等于 child locked revision。Symlink、文件或无法安全归属的 collision 失败。

## Artifact Profile

- 官方 CLI 只接受 `.lxpz`；通用 wire model 仍允许逻辑 `.lxp` 目录。
- Artifact 只包含 `manifest.yaml` 与 `objects/sha256/<hex>`，没有 `lock.yaml`。验证通过的 manifest 原始 bytes 的 SHA-256 是身份（不执行 YAML canonicalization），coordinates 只是可读标签。
- Export 支持 `reference`、`embedded`、`mirrored`，默认 `embedded`；Import 自动读取每个 Component 声明。
- Reference 使用安全 network locator 与完整 commit ID，依赖 source 可用。Mirrored 的 reference/embedded revision 必须一致，先尝试 reference，只在 contract 声明的可恢复错误时使用 fallback。
- Git bundle 只覆盖当前 `HEAD` 可达历史。仅 embedded 可附带 staged binary patch；Import 后 index selection 仍为 staged。Reference/mirrored Export 要求 index 与 `HEAD` 一致。
- Embedded 与 mirrored fallback 在删除 exporter state 和原始 repository 后仍可恢复。Git-untracked 和未选择的 tracked changes不得进入 Artifact。
- Embedded staged patch 的未压缩 `diff.patch` 在 Export/Import 两端上限均为 256 MiB；超限 Export 必须在发布前失败。
- Production Export 拒绝 shallow repository、未注册/不安全 submodule、gitlink mismatch、escaping symlink 与未声明 clean/smudge filter。Reference/mirrored 可显式使用 `lfs_mode: pointer`，但不携带外部 LFS object。
- 每次成功 Export 创建新 Artifact，并把当前 manifest digest 作为下一代 `provenance.parent`。

## Import 重试与持久化

- 首次 target 必须不存在或为空。Core 在 Apply 前原子写入包含 Artifact digest、Session ID 和 `importing` 状态的本地 marker。
- 每个 Provider `Apply` 必须幂等、可重试、固定 revision，并只修改自己的 root；父 Provider必须保留 child roots。
- Component 失败时 Core 保留 target、已完成 observed state 和 marker，不回滚成功 Component、不删除整个 target。使用同一 Artifact 与 Session 的相同命令继续；不同 Artifact 或无 marker 的非空 target 失败。
- 全部成功后 Session 原子变为 `ready`。相同 Artifact 对 ready Session 的重试是 no-op。
- Requirement observation 写入本地 `requirements.state.yaml`，不是 portable lock，不进入 Artifact。
- Manifest、Session state、Requirement state 与 profile 使用同目录临时文件原子 rename；Artifact archive 先完整写临时文件，再 no-clobber 发布。已有输出不得覆盖。

## 运行安全

- 所有 payload 在 Provider 调用前验证 digest 与 size；Provider 验证 payload role、media type 和 content contract。
- 未知/未绑定 Provider 或 Checker、contract/distribution mismatch、额外 payload role、Requirement failure 与非 portable Git feature fail closed。
- CLI 外部操作默认 deadline 15 分钟，可由 `LXP_TIMEOUT` 正数 Go duration 覆盖。Git 在调用方无 deadline 时使用 5 分钟默认；terminal、askpass 与 Git Credential Manager 交互 prompt 禁用。
- 本地 containment、Workdir 与 Session discovery 使用解析既有 symlink prefix 后的物理绝对路径，覆盖 macOS `/var` 与 `/private/var` alias；物理路径不进入 Artifact。
- Session 是 single-writer；调用方串行执行写操作。本 Profile 不要求进程锁。

## 非目标与发布门槛

本 Profile 不提供 repository extension 自动安装、Template import、branch/merge/rebase、多父历史、multi-writer、远端 revision 自动前进、外部 Git LFS object exchange、execution replay 或 hostile Artifact sandbox。

发布前必须通过 Linux/macOS 公开 CI、Go unit/race/vet、Git Provider contract 测试、三种 distribution 与递归 submodule Harness、失败 Import 重试与 ready no-op、删除 exporter/source 后的两代 embedded 往返，以及 digest/size/traversal/symlink/credential/cancellation/contract mismatch 测试。中英文文档、Schema、YAML、SVG、HTML 与 CLI help 必须一致。
