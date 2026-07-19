# Go SDK 与 CLI 使用说明

[English](go-engine.en.md) | **中文主版本**

官方 Go 参考实现由 [`lxp`](https://github.com/loop-exchange-protocol/lxp) 与 [`provider-git`](https://github.com/loop-exchange-protocol/provider-git) 组成。Core 通过显式 composition 注入 Provider；官方 CLI 只注入 `loop.exchange:git:v1`。项目不维护多语言 SDK 矩阵。本页是非规范性指引，承诺边界见 [Production MVP](production-mvp.md)。

```bash
go install github.com/loop-exchange-protocol/lxp/cmd/lxp@latest
```

CLI 位于独立 `cmd/lxp` Go module，release tag 使用 `cmd/lxp/vX.Y.Z`；module 依赖已发布 SDK/Provider 版本，不包含阻断 `go install ...@latest` 的 `replace`。

```bash
lxp init work
git clone YOUR_REPOSITORY work/source
cd work

# 修改后选择需要交换的 Git 状态
lxp add source/PATH...
lxp status
lxp export --distribution mirrored ../context.lxpz

cd ..
lxp inspect context.lxpz
lxp requirements --format json context.lxpz
lxp import context.lxpz continued
```

## Add 与 Status

未归属 path 首次 Add 时，Engine 从该 path 向上寻找 Git root；匹配 `source/.git` 后把整个 `source` 注册为一个 Component，再把相对 path 交给 `git add --`。Git Provider 同时读取 index 中的 gitlink：缺失 submodule 会联系其 locator、checkout gitlink 锁定 commit，并逐层递归注册为嵌套 Git Component；已经初始化的 child 不会自动更新。普通 path 始终路由给最深 root；父仓库只维护 gitlink boundary。

`status` 同时显示 Component roots、Git porcelain changes、未归属 paths 与 ignored paths。Git-untracked 内容属于 Git Provider 状态，不会被 Core 注册成另一个 Component，也不会被 Export 静默包含。未归属且未忽略的顶层 path 会阻塞 Export。

## Export 与 Import

`lxp export --distribution` 支持 `reference`、`embedded` 与 `mirrored`，省略时默认 embedded。`lxp import` 不需要 distribution flag，直接按 Artifact manifest 自动处理。成功 Export 推进 Session parent，下一代 Artifact 自动写入 `provenance.parent`。

Embedded 使用当前 `HEAD` 的最小 Git bundle 加可选 staged binary patch，Import 不联系原 remote，并恢复 Git index selection。未压缩 staged `diff.patch` 的 Export/Import 上限同为 256 MiB，超限 Export 在 Artifact 发布前失败。Reference 使用安全 network locator + 完整 commit ID。Mirrored 先尝试相同 revision 的 reference，source 不可用时由 Git Provider 在自己的 staging root 内切换到 embedded base。Reference/mirrored 要求 index 与 `HEAD` 一致，不能运输 staged patch。

为保证 portable 语义，Git Provider 拒绝 shallow repository、无法安全初始化或未注册的 submodule、gitlink 与 child revision 不一致、cross-symlink nested root 和 escaping symlink；embedded 还拒绝 clean/smudge filter。Submodule 是独立 Component，父 bundle 不包含子 objects；Import 父到子 Apply，Export 子到父验证。Reference/mirrored 的 LFS pointer 模式不执行 filter，外部 LFS object 不进入 Artifact。Artifact output 不覆盖现有路径。

首次 Import target 必须不存在或为空。失败会保留 `.lxp` 中同 Artifact 的 `importing` marker 和已完成 observed state；再次运行相同 Import 继续协调，不整体回滚或删除 target。全部完成后状态变为 `ready`，再运行相同 Import 是 no-op。Git Apply 每次先重建目标状态，再替换自己的 root；重建 parent 时显式保留声明的 child roots。

已有 submodule 的最短路径是普通 clone 后一次 Add 父 root；`loop.exchange:git:v1` 会自动初始化递归 submodule：

```bash
git clone YOUR_REPOSITORY source
lxp add source
```

自动初始化只 checkout 每个 gitlink 当前锁定的 commit，不等同于 `git submodule update --remote`。Import 在恢复 child content 前用 `git submodule init` 写入父仓 native config；discovery 会幂等修复缺失 config，这两个 config-only 操作都不 fetch 或 checkout。Symlink/non-empty target collision、不可访问 locator 或 checkout 失败都会使 Add 失败。

CLI 外部操作默认 15 分钟 timeout，可用 `LXP_TIMEOUT=30m` 等正数 Go duration 覆盖。所有 Git 子进程继承该 Context；Provider 在 SDK 调用方没有 deadline 时使用 5 分钟默认值。Git terminal/askpass/GCM interactive prompt 被禁用，认证需预先由非交互 credential helper 或 SSH agent 提供。

Session 与 CLI path 在本地比较前解析既有 symlink prefix 为物理绝对路径。因而 macOS 上从 `/var/...` 初始化、再从 `/private/var/...` 工作仍属于同一 Workdir，无需改写 `TMPDIR` 绕过。

修改子仓库后，`lxp add source/PATH/IN/SUBMODULE` 选择 child index；子仓库产生新 commit 后，`lxp add source/PATH/TO/SUBMODULE` 同时让 child Provider 处理 root 并同步父 index 的 gitlink。

## Distribution 选择

日常 checkpoint 可直接使用默认 embedded；大型公开 repository 可选 reference；既要保留 remote identity 又要容忍 source outage 时选择 mirrored。完整规则和 YAML 见 [Distribution 指南](distributions.md)；公开 CLI 的四个真实仓库验证位于 [`provider-git` Spring AI + MCP Harness](https://github.com/loop-exchange-protocol/provider-git/tree/main/harness/spring-ai-mcp)。

## 扩展配置、Requirements 与信任边界

Provider/Checker 由 `namespace:name:version` 标识。`LXP_CONFIG` 可指向本地 EngineConfig；默认读取用户配置目录的 `lxp/config.yaml`，未找到时使用官方 builtin binding。仓库、implementation 版本和 digest 不进入 Artifact；当前 CLI 不自动安装 repository extension。

`lxp requirements` 不 Apply Artifact；它用全局 Checker contract 检查 executable、MCP 与 credential，TUI 只持久化本地 non-secret policy profile。Executable/MCP probe 必须显式授权；Credential 只保存 local binding 名称，值不进入 Artifact、local state、argv 或 log。

Production MVP 只面向同一信任域内的 Artifact。路径、digest 与 contract 验证是失败安全和完整性机制，不是恶意输入沙箱。
