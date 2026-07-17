# Artifact YAML 示例

[English](README.en.md) | **中文主版本**

这里提供完整的 [manifest.yaml](manifest.yaml) 与 [lock.yaml](lock.yaml)，用于展示协议交换格式。它们覆盖：

- Artifact coordinates 与父 digest；
- `git@v1` Provider identity 和不透明 `config`；
- embedded Git bundle 与 staged-state payload；
- executable 与 credential Requirements；
- lock 对 Provider contract、distribution 与 revision 的绑定。

这个静态 Artifact 使用占位 digest 且不附带 objects，因此用于阅读和 Schema/validator 测试，不用于 Import。真正可导入的 embedded Artifact 由 [Quickstart Harness](../quickstart/README.md) 实时生成；运行后可直接查看 `/tmp/lxp-quickstart/generation-2.manifest.yaml`。

普通用户不需要手写这些 YAML。CLI 负责生成 manifest、lock 和 content-addressed objects。
