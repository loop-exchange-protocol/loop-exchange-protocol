# Go SDK 与 CLI 使用说明

[English](go-engine.en.md) | **中文主版本**

官方 Go Production MVP 由 [`go-sdk`](https://github.com/loop-exchange-protocol/go-sdk) 与 [`go-provider-git`](https://github.com/loop-exchange-protocol/go-provider-git) 组成。SDK Core 不内置具体 Provider；官方 CLI 只注入 `git@v1`。本页是非规范性指引，承诺边界见 [Production MVP Profile](production-mvp.md)。

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

未归属 path 首次 Add 时，Engine 从该 path 向上寻找 Git root；匹配 `source/.git` 后把整个 `source` 注册为一个 Component，再把相对 path 交给 `git add --`。Component 内部始终回到 Git Provider，不创建嵌套 Component。

`status` 同时显示 Component roots、Git porcelain changes、未归属 paths 与 ignored paths。Git-untracked 内容属于 Git Provider 状态，不会被 Core 注册成另一个 Component，也不会被 Export 静默包含。未归属且未忽略的顶层 path 会阻塞 Export。

## Export 与 Import

`lxp export --distribution` 支持 `reference`、`embedded` 与 `mirrored`，省略时默认 embedded。`lxp import` 不需要 distribution flag，直接按 Artifact manifest 自动处理。成功 Export 推进 Session parent，下一代 Artifact 自动写入 `provenance.parent`。

Embedded 使用当前 `HEAD` 的最小 Git bundle 加可选 staged binary patch，Import 不联系原 remote，并恢复 Git index selection。Reference 使用安全 network locator + 完整 commit ID。Mirrored 先尝试相同 revision 的 reference，source 不可用时清理部分 target，再从 embedded base 恢复。Reference/mirrored 要求 index 与 `HEAD` 一致，不能运输 staged patch。

为保证 portable 语义，Git Provider 拒绝 shallow repository、submodule/gitlink 与 escaping symlink；embedded 还拒绝 clean/smudge filter。Reference/mirrored 的 LFS pointer 模式不执行 filter，外部 LFS object 不进入 Artifact。Artifact output 不覆盖现有路径；Import target 必须不存在，失败时清理新 target。

## Distribution 选择

日常 checkpoint 可直接使用默认 embedded；大型公开 repository 可选 reference；既要保留 remote identity 又要容忍 source outage 时选择 mirrored。完整规则和 YAML 见 [Distribution 指南](distributions.md)；公开 CLI 的四个真实仓库验证位于 [`go-provider-git` Spring AI + MCP Harness](https://github.com/loop-exchange-protocol/go-provider-git/tree/main/harness/spring-ai-mcp)。

## Requirements 与信任边界

`lxp requirements` 不物化 Artifact；它检查 executable、MCP 与 credential contract，TUI 只持久化本地非 secret policy profile。Executable/MCP probe 必须显式授权；Credential 只保存 local binding 名称，值不进入 Artifact、lock、argv 或 log。

Production MVP 只面向同一信任域内的 Artifact。路径、digest 与 contract 验证是失败安全和完整性机制，不是恶意输入沙箱。
