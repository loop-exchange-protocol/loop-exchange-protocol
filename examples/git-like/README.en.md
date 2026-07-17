# Git-like work loop

**English** | [中文主版本](README.md)

This example uses only the normal CLI and requires no hand-authored protocol YAML:

```bash
go install github.com/loop-exchange-protocol/go-sdk/cmd/lxp@latest
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

`source/README.md` enters the Git index through the Git Provider. Its selection remains staged after Import; `.lxp` lives at the Worktree root and commands discover the Session from any subdirectory.
