# Git-like 工作循环

[English](README.en.md) | **中文主版本**

此示例只使用正常 CLI，不要求手写协议 YAML：

```bash
go install github.com/loop-exchange-protocol/lxp/cmd/lxp@latest
LXP_BIN="$(command -v lxp)"
"$LXP_BIN" init /tmp/lxp-demo
cd /tmp/lxp-demo

mkdir source && git -C source init -b main
printf 'hello\n' > source/README.md
git -C source add README.md
git -C source -c user.name=Demo -c user.email=demo@example.test \
  commit -m initial

printf 'selected\n' >> source/README.md
"$LXP_BIN" status
"$LXP_BIN" add source/README.md
"$LXP_BIN" export ../demo.lxpz

cd /tmp
"$LXP_BIN" inspect demo.lxpz
"$LXP_BIN" import demo.lxpz lxp-continued
cd lxp-continued && "$LXP_BIN" status
```

`source/README.md` 由 Git Provider 放入 Git index。Import 后 selection 仍保持 staged，`.lxp` 位于 Worktree root，所有命令都可以从其任意子目录自动发现 Session。
