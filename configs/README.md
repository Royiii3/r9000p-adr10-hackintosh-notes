# 历史配置与变更

[返回首页](../README.md) · [CPU 与 Panic](../docs/04-cpu-and-panic.md)

这些配置来自本次保留的备份，供逐项对照。序列号、MLB、ROM 和系统 UUID 已清空或置零，公开副本没有再次启动验证，不能直接作为自己的启动配置使用。

| 文件 | 当时的用途与结果 |
|---|---|
| [desktop-cpus1.redacted.plist](desktop-cpus1.redacted.plist) | 曾进入桌面的单核基线，保留 `cpus=1`；不代表日用稳定 |
| [panic-no-cpu-limit.redacted.plist](panic-no-cpu-limit.redacted.plist) | 去掉 `cpus=1` 后的配置，下一次启动由用户反馈发生 Panic |
| [test-cpus12-unverified.redacted.plist](test-cpus12-unverified.redacted.plist) | 后续准备的 `cpus=12` 测试；没有可确认的实机结果 |
| [recovery-reference.redacted.plist](recovery-reference.redacted.plist) | 恢复环境参考配置；与桌面基线的区别见差异文件 |

## 实际差异

- [桌面基线 → 解除限制](diffs/01-desktop-to-failed-unrestricted.diff)：删除 `cpus=1`，同时增加了 NVRAM Delete 中的 `boot-args` 条目。这次实际包含两个变动，不能写成严格的单变量实验。
- [解除限制 → cpus=12](diffs/02-unrestricted-to-cpus12.diff)：在上一份配置基础上加入 `cpus=12`。
- [桌面基线 → 恢复参考](diffs/03-desktop-to-recovery-reference.diff)：`IONDRVSupport` 的排除状态不同，恢复环境需要保留该系统驱动。

AMD 补丁中的物理核心数保持为 16。`cpus=12` 不是把物理核心补丁改为 12，也不能根据“关于本机”显示的 Intel 型号推导应填多少。

这里记录的是配置内容与随后观察到的现象，没有足够的原始 Panic 文件来确认多核失败的精确原因。完整 EFI 的文件与版本清单在 [附件说明](../artifacts/README.md)。
