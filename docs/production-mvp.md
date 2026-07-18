# LXP Production MVP Profile

[English](production-mvp.en.md) | **中文主版本**

本文定义首个可以部署到真实团队流程的最小 LXP Profile。它是 `loop.exchange/v1alpha1` 的受限子集，不扩大安全承诺。

## 适用边界

Production MVP 面向同一信任域内的工程团队和自动化系统：Artifact 发布者、Importer、预装 CLI 与 Provider 均受信任。它保证失败安全、内容完整性、离线可恢复和可追踪的线性父链，但**不**把 LXP 当作恶意输入沙箱。

## 唯一工作循环

```text
Init → Add/Status → Export → Import → Work → Add/Status → Export …
```

公开 CLI 冻结为：

```text
lxp init [WORKDIR]
lxp add PATH...
lxp status [--format text|json]
lxp export [--distribution reference|embedded|mirrored] ARTIFACT.lxpz
lxp import ARTIFACT.lxpz [WORKDIR]
lxp inspect ARTIFACT.lxpz
lxp requirements [--format tui|json] ARTIFACT.lxpz
```

`Plan` 仍是 Import 内部的 Provider preflight contract，但不是独立用户命令。Import 必须在任何物化或 activation 前验证 Artifact、精确匹配 contract、展示 Provider actions 并检查 Requirements。

## Provider 与内容范围

- 官方组合只包含 `git@v1`；没有隐式 File/Filesystem fallback。
- 当前 `git@v1` 实现要求本机预装受信任的 Git CLI；这是 Provider 安装前提，不是 Artifact 内携带的 executable。
- 未归属 path 没有 Provider 匹配时，`lxp add` 和 Export 必须失败。
- 一个 Git repository 是一个不透明 Component root；仓库内不得创建嵌套 Core Component。
- Conversation、Skill、结果文件或其他上下文若需进入 MVP Artifact，必须位于被 Git Provider 管理的 repository 中并由 Git index 选择。
- 协议仍保留第三方 Provider 扩展点，但不属于本 Profile 的生产承诺。

## Artifact Profile

- Production Export 支持 `reference`、`embedded` 与 `mirrored`，默认 `embedded`；Import 根据 Artifact 中每个 Component 的声明自动处理。
- 官方 CLI 只接受 `.lxpz` archive；逻辑 `.lxp` 目录仍属于通用 wire model，不属于本 Profile 的公开入口。
- Reference 携带安全 network locator 与完整 commit ID，Import 依赖 source 可访问；mirrored 同时携带相同 revision 的 reference 与 embedded fallback，并先尝试 reference。
- Embedded 和 mirrored fallback 的 Git bundle 只覆盖当前 `HEAD` 可达历史；仅 embedded 可附带 staged binary patch。
- Embedded 与 mirrored 在删除 exporter state 和原始 repository 后仍必须恢复；reference source 不可用时必须失败并清理 target。
- Embedded 的 Git index selection 必须在 Import 后保持 staged；reference/mirrored 要求 Export 时 index 与 `HEAD` 一致。Git-untracked 与未选择的 tracked changes 不得进入 Artifact。
- Artifact identity 是 `manifest.yaml` 原始 bytes 的 SHA-256；coordinates 只是人类可读标签，不是身份。
- 每次成功 Export 更新当前 Session 的 parent digest；下一代 manifest 必须引用它。

`git@v1` Production Export 拒绝 shallow repository、submodule/gitlink 与 escaping symlink。Embedded 拒绝 clean/smudge filter；reference/mirrored 可声明 `lfs_mode: pointer`，只交换 Git tree 中的 canonical LFS pointer，不执行 filter，也不承诺携带外部 LFS object。

## Failure 与持久化保证

- Manifest、Session state 与 profile 必须通过同目录临时文件写入并原子 rename；archive 必须先完整写入同目录临时文件，再以 no-clobber 方式原子发布。
- 已存在的 Artifact output 不得覆盖。
- Import target 必须不存在；失败 Import 必须清理新建 target。
- 所有 payload 在 Provider 调用前验证 SHA-256 与 size；Provider 必须验证 payload role 和 media type。
- 未知 Provider、contract mismatch、distribution mismatch、额外 payload role、Requirement failure 或非 portable Git feature 必须 fail closed。
- 一个 Session 是 single-writer；调用方必须串行执行 `add` 与 `export`。本 Profile 不承诺并发写入协调。

## 明确非目标

本 Profile 不提供 remote Registry、coordinate install/resolve、Template repository import、branch/merge/rebase、多父历史、multi-writer Session、submodule recursion、外部 Git LFS object exchange、Provider 自动安装、execution replay 或 hostile Artifact sandbox。

## 发布门槛

实现发布 Production MVP 前必须通过：

1. Go unit、race 与 vet；
2. Git Provider contract 的正向与负向测试；
3. reference 在线/离线与 mirrored fallback Harness，以及删除 exporter/source 后的 embedded 两代 Export/Import Harness；
4. digest、size、archive traversal、duplicate entry、symlink、submodule、filter 和 contract mismatch 测试；
5. 中英文规范、Schema、canonical YAML、HTML 与 CLI help 一致性检查。
