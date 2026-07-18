# Reference 与 Mirrored YAML 示例

[English](README.en.md) | **中文主版本**

本目录给出 `reference` 和 `mirrored` 的完整 manifest/lock 结构：

- [`reference-manifest.yaml`](reference-manifest.yaml) 与 [`reference-lock.yaml`](reference-lock.yaml)：Spring AI Examples 的 immutable Git reference，不含 `objects/` payload；
- [`mirrored-manifest.yaml`](mirrored-manifest.yaml) 与 [`mirrored-lock.yaml`](mirrored-lock.yaml)：Spring AI 的相同 reference revision 与 embedded base fallback，并声明 LFS pointer 模式。

这些文件是 Schema/canonical 结构向量，不是可直接 Import 的 `.lxpz`：示例 mirrored payload digest 没有在仓库中附带对应的大型 Git bundle。可执行的四 Component 旅程位于 [`go-provider-git` Harness](https://github.com/loop-exchange-protocol/go-provider-git/tree/main/harness/spring-ai-mcp)。

关键不变量：mirrored 的两个 revision 完全相同；lock distribution/revision/payload digest 必须与 manifest 对齐；reference locator 不包含 credential 或本地路径。更多语义见 [Distribution 指南](../../docs/distributions.md)。
