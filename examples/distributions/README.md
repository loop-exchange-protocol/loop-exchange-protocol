# Distribution YAML 案例

[English](README.en.md) | **中文主版本**

本目录给出两种 manifest 结构：

- [`reference-manifest.yaml`](reference-manifest.yaml)：Spring AI Examples 的 immutable Git reference，不含 `objects/` payload；
- [`mirrored-manifest.yaml`](mirrored-manifest.yaml)：Spring AI 的相同 reference revision 与 embedded base fallback，并声明 LFS pointer 模式。

这些是 Schema/canonical structure vectors，不是可直接导入的 `.lxpz`，因为仓库不提交示例所指的大型 Git bundle。可执行四 Component 旅程位于 [`provider-git` Harness](https://github.com/loop-exchange-protocol/provider-git/tree/main/harness/spring-ai-mcp)。

关键不变量：mirrored 的两个 revision 完全相同；manifest 中的 payload digest/size 必须与 objects 对齐；reference locator 不含 credential 或本地路径。Artifact 没有第二份 lock。更多语义见 [Distribution 指南](../../docs/distributions.md)。
