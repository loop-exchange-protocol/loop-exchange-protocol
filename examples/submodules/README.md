# 嵌套 Component 与 Git submodule

[English](README.en.md) | **中文主版本**

[`manifest.yaml`](manifest.yaml) 展示父 Git repository 与 submodule 的 portable 结构。父子关系不需要额外 `parent` 或 mount 字段，而是由 normalized path 推导：`shared-library.path` 严格位于 `application.path` 下。

- 父 Component 拥有 `.gitmodules` 与 `deps/shared-library` 上的 gitlink boundary，但不拥有 child 工作树实体。
- 子 Component 拥有 nested root 下的全部实体，并携带独立 revision 与 payload。
- 父 selected gitlink 必须等于子 Component 的 locked revision；示例中的 child revision 为 `bbbb…`。
- Import 父到子物化；Export 子到父固定身份并验证 boundary。
- Artifact 不声明 copy、symlink 或 mount capability。Provider 无法安全组合具体路径时直接失败。

YAML 使用占位 digest/size 来突出结构，不附带大型 Git bundle。真实 CLI 会自动生成 manifest、payload 与 lock：

```bash
git clone YOUR_REPOSITORY source
lxp init .
lxp add source
lxp export --distribution embedded ../context.lxpz
```

`lxp add` 会从 parent index 的 gitlink 逐层初始化 child 与更深 submodule，只 checkout 各自锁定 commit，不跟进 remote 新 revision。

无法安全初始化的 submodule、没有对应 nested Component 的 gitlink、child revision mismatch、穿越 symlink 或非空 child target 都必须失败。
