# Engine 扩展配置案例

[English](README.en.md) | **中文主版本**

[`engine-config.yaml`](engine-config.yaml) 展示本机如何配置扩展仓库，并把全局唯一的 Provider/Checker contract 坐标绑定到具体实现包。Artifact 只声明 contract；仓库、凭据、镜像与实现版本只属于消费端配置，不进入 `.lxpz`。

`repositories` 按声明顺序搜索精确 package 坐标，`source: repository` 必须固定 SHA-256；credential 字段只引用本地 secret slot。官方 Production MVP 只执行 `source: builtin` 的 Go 实现。`source: repository` 为扩展解析模型保留，但 v1alpha1 不定义通用 package ABI、不要求自动安装，也不允许 Artifact 指定或触发安装。
