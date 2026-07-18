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
lxp export ../context.lxpz

cd ..
lxp inspect context.lxpz
lxp requirements --format json context.lxpz
lxp import context.lxpz continued
```

## Add 与 Status

未归属 path 首次 Add 时，Engine 从该 path 向上寻找 Git root；匹配 `source/.git` 后把整个 `source` 注册为一个 Component，再把相对 path 交给 `git add --`。Component 内部始终回到 Git Provider，不创建嵌套 Component。

`status` 同时显示 Component roots、Git porcelain changes、未归属 paths 与 ignored paths。Git-untracked 内容属于 Git Provider 状态，不会被 Core 注册成另一个 Component，也不会被 Export 静默包含。未归属且未忽略的顶层 path 会阻塞 Export。

## Export 与 Import

Production Export 只生成 embedded Artifact：当前 `HEAD` 的最小 Git bundle 加可选 staged binary patch。Import 不联系原 remote，恢复后 selection 仍位于 Git index。成功 Export 推进 Session parent，下一代 Artifact 自动写入 `provenance.parent`。

为保证 standalone 语义，Git Provider 拒绝 shallow repository、submodule/gitlink、escaping symlink 和 clean/smudge filter（包括 Git LFS）。Artifact output 不覆盖现有路径；Import target 必须不存在，失败时清理新 target。

## 实验 Distribution API

Go Engine 与 `git@v1` Provider API 额外实现 reference/mirrored，但官方 Production CLI 不提供对应 flag，也不接受这两种 Artifact。Reference 使用安全 network locator + 完整 commit ID；mirrored 在 reference 不可用时回退到相同 revision 的 embedded base。两种模式都要求 index 与 `HEAD` 一致，不能运输 staged patch。

完整规则和 YAML 见 [Distribution 指南](distributions.md)；四个真实仓库的可执行验证位于 [`go-provider-git` Spring AI + MCP Harness](https://github.com/loop-exchange-protocol/go-provider-git/tree/main/harness/spring-ai-mcp)。

## Requirements 与信任边界

`lxp requirements` 不物化 Artifact；它检查 executable、MCP 与 credential contract，TUI 只持久化本地非 secret policy profile。Executable/MCP probe 必须显式授权；Credential 只保存 local binding 名称，值不进入 Artifact、lock、argv 或 log。

Production MVP 只面向同一信任域内的 Artifact。路径、digest 与 contract 验证是失败安全和完整性机制，不是恶意输入沙箱。
