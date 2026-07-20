# Engine 扩展配置案例

[English](README.en.md) | **中文主版本**

[`engine-config.yaml`](engine-config.yaml) 展示如何把 `loop.exchange:git:v1` 绑定到本机 PATH 中的 `lxp-provider-git` Helper；`command` 是 argv 数组，不经过 shell。[`engine-config.repository.yaml`](engine-config.repository.yaml) 展示同一 contract 如何改为 OCI 分发；其中全 `a` digest 是文档占位，使用时必须替换为发布 manifest 的真实 SHA-256。Artifact 只声明 contract；仓库、凭据、镜像与实现版本只属于消费端配置，不进入 `.lxpz`。

`repositories` 按声明顺序搜索 `${base}/${implementation.namespace}/${implementation.name}@digest`。`source: repository` 必须固定 SHA-256，且只有 `auto_install: true` 并在 `trusted_namespaces` allowlist 中的 namespace 能下载；credential 字段命名本地环境 secret handle，值不写入 YAML。官方 CLI 默认仍可使用 builtin Git Provider；Helper 与 OCI 是本机显式 policy，Artifact 不能指定或触发安装。Package layout、握手和 lifecycle 见[扩展协议](../../docs/extensions.md)。
