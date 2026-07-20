# 扩展发现、分发与 Helper 协议

[English](extensions.en.md) | **中文主版本**

本文是 `v1alpha1` 的规范组成部分，定义 Provider/Checker 的本地 binding、OCI 分发和进程激活。LXP 不建立自有中心 Registry API：package 发现与下载复用 OCI Distribution；运行边界采用类似 Git remote helper 的独立进程协议。

## 1. 身份与本地授权

Artifact 只携带跨 kind 全局唯一的 contract，例如 `loop.exchange:git:v1`。只有消费端 EngineConfig 能把它绑定到 implementation package；Artifact 不能携带 package、command、repository、digest 或安装 policy。

`implementation.source` 有三种：

- `builtin`：实现由 Engine 组合，`package` 必须与实现自报坐标精确相等；不得声明 `command` 或 `digest`。
- `helper`：操作者已安装本地 executable；`command` 是 argv 数组，Engine MUST 直接执行，不得经过 shell；不得声明 `digest`。
- `repository`：实现是 OCI Extension Package；binding MUST 固定 OCI manifest 的 `sha256:` digest，不得声明 `command`。

`repository` 不等于默认授权。Engine 只能使用 `auto_install: true` 且 `trusted_namespaces` 包含 implementation namespace 的本地仓库。仓库顺序、trust、credential 与 cache 都属于消费端 policy；Artifact 无法扩大它们。官方公开 package 的约定根为 `oci://ghcr.io/loop-exchange-protocol`，但默认官方组合 MAY 继续使用 builtin Git Provider，从而不要求首次命令联网。

`lxp add` 只对 EngineConfig 已启用的 Provider binding 执行 discovery；不得扫描 Registry 全量 package。Import 已有明确 contract，仍必须先完成本地授权解析。缺少或不匹配的实现 MUST 在 Component 写入前失败。

## 2. OCI Extension Package

Repository URL 去掉 scheme 后作为 OCI repository base。Implementation `namespace:name:version` 映射到 `${base}/${namespace}/${name}`；Engine 按 binding digest 拉取 manifest，而不是信任可移动 tag。当前仓库不存在该 digest 时 MAY 继续下一个已授权仓库；一旦取得内容，任何 digest、descriptor 或 platform mismatch 都 MUST 失败，不得降级。

Manifest MUST：

- `artifactType` 为 `application/vnd.loop.exchange.extension.v1`；
- 只有一个 SHA-256 config，media type 为 `application/vnd.loop.exchange.extension.config.v1+json`，且满足 [Extension Package Schema](../schemas/v1alpha1/extension-package.schema.json)；
- 只有一个 SHA-256 原始 executable layer，media type 为 `application/vnd.loop.exchange.extension.binary.v1`，最大 128 MiB；
- descriptor 的 kind、contract、implementation、Helper protocol、OS/architecture MUST 与本地 binding 和当前平台精确一致；entrypoint MUST 是单个文件名。

Engine MUST 在 content-addressed cache 中原子写入 executable，每次复用前校验 layer digest，并以不可交互方式执行。Registry credential 字段只是本地 secret handle；参考 CLI 把它解析为环境变量名，值可以是 registry access token 或 `username:password`，但不得进入 config、Artifact、argv、log 或 Helper 消息。

## 3. Helper 生命周期

Helper 是命令级临时进程，不是长期 daemon：

1. package 出现在 cache 里不表示已激活；
2. Engine 首次解析该 binding 时启动一个进程，并通过 `initialize` 精确核验 kind、contract、implementation 与 protocol；
3. 同一 CLI 命令内顺序复用该进程；
4. 命令完成、取消、deadline、协议错误或进程异常时关闭 stdin 并终止进程。

Engine MUST 直接执行配置 argv，不得调用 shell；MUST 传递每个 request 的 deadline，并在取消时终止 Helper；MUST 限制 stderr 诊断。Helper MUST 继承 deadline 到所有外部操作并禁用交互 credential prompt。Helper 是操作者授权的本地代码，不是 hostile-code sandbox；可信 Artifact 限制不等于可信 Helper。

## 4. Wire protocol

stdin/stdout 只承载逐行 JSON（NDJSON），UTF-8，每条消息最大 8 MiB；stdout 不得输出 banner 或 log。一次连接最多有一个 outstanding request，response `id` MUST 与 request 相同。Envelope 满足 [Helper Message Schema](../schemas/v1alpha1/helper-message.schema.json)：

```json
{"protocol":"loop.exchange/helper-v1","id":1,"method":"initialize","deadline":"2026-07-20T12:00:00Z","params":{}}
```

第一条 request MUST 是 `initialize`，参数为 Engine root、`extension_kind`、contract 与 implementation。响应重复这些精确身份；Provider 还返回 `distributions`，并按实际能力返回 `adopt`、`track`、`discover-children`、`track-child`。身份不一致 MUST 失败，不能仅凭 executable 文件名信任 Helper。

Provider 方法固定为：

| Method | 语义 |
| --- | --- |
| `provider.match` | `Match(path)` |
| `provider.validate` | `Validate(component, store_root, target)` |
| `provider.apply` | `Apply(component, store_root, target)` |
| `provider.export` | `ExportComponent(ref, mode, store_root)` |
| `provider.adopt` | 可选 `Adopt(id, path, materialized)` |
| `provider.add` / `provider.status` | 可选 native selection 与状态 |
| `provider.discover-children` | 可选 nested Component discovery |
| `provider.track-child` | 可选 parent boundary tracking |

Checker 只定义 `checker.check(requirement, options)`。Provider/Checker domain model 使用 SDK 的 canonical JSON field name；Helper 不得从 `store_root` 或 target 之外推断 portable identity。`error` 只返回有界的 `code` 与 `message`，不得包含 secret。

## 5. Import 重试

Helper 下载与握手属于 extension resolution，不是 Artifact 指令，也不是独立的公开 install/Activate 生命周期阶段。Import 首次进入 `importing` 前固定 source、implementation 与 repository digest；重试 MUST 使用相同解析，成功 Component 不回滚。`ready` Session 的同 Artifact 重试在本地身份验证后 no-op，不启动 Helper、不下载 package。

Helper 崩溃等价于当前 Provider/Checker 调用失败。Provider `Apply` 仍 MUST 幂等、可重试；Core 不为 Helper 增加事务或全局 rollback。
