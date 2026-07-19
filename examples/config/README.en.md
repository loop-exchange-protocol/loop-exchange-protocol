# Engine extension configuration example

[中文](README.md) | **English**

[`engine-config.yaml`](engine-config.yaml) shows how a machine configures extension repositories and binds globally unique Provider/Checker contract coordinates to concrete implementation packages. An Artifact declares contracts only; repositories, credentials, mirrors, and implementation versions remain consumer-local and never enter `.lxpz`.

Repositories are searched in declaration order for an exact package coordinate, `source: repository` pins a SHA-256 digest, and credential fields only reference local secret slots. The official Production MVP executes only Go implementations declared with `source: builtin`. `source: repository` reserves the extension-resolution model, but v1alpha1 defines no generic package ABI, requires no automatic installation, and never lets an Artifact select or trigger installation.
