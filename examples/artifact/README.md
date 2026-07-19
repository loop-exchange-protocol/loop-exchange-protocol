# ContextArtifact YAML 案例

[English](README.en.md) | **中文主版本**

[`manifest.yaml`](manifest.yaml) 展示完整协议交换结构，包括：

- 可读 Artifact coordinates 与 parent digest；
- 全局 `loop.exchange:git:v1` Provider contract 坐标；
- embedded Git base 与 selected index state 的 content-addressed payload；
- media type、SHA-256 digest 与 size。

Artifact 不包含 `lock.yaml`：revision、distribution 与 payload digest 已由 manifest 唯一固定，Artifact identity 直接计算验证通过的 `manifest.yaml` 原始 bytes 的 SHA-256，不执行 YAML canonicalization。

普通用户无需手写 YAML。CLI 生成 manifest 与 `objects/sha256/` 内容。
