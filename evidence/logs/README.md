# 精选原始日志的脱敏副本

[证据说明](../README.md) · [文件索引](index.json)

| 文件 | 可以用来检查什么 |
|---|---|
| [PCI / ACPI 摘录](20261018-pci-patcher-and-acpi.redacted.txt) | 较早一次 Darwin 24 启动的补丁与 ACPI 信息；不能替代后来的 Darwin 25 日志 |
| [运行环境](20261021-runtime-environment.redacted.txt) | 当次系统版本、启动参数及环境 |
| [已加载内核扩展](20261021-loaded-kexts.redacted.txt) | 当次加载的 kext 及版本，包括 NVIDIA 2.3.4；不代表每项功能都正常 |
| [显示设备信息](20261021-display-profiler.redacted.txt) | 系统登记的显卡、显示器和 Metal 信息；单独出现名称不能证明硬件加速正常 |
| [驱动安装输出](20261023-driver-install.redacted.txt) | 安装程序执行记录，与加载列表及审计报告结合阅读 |
| [驱动流程状态](20261023-driver-status.redacted.txt) | 脚本留下的阶段标记 |
| [账户流程状态](20261023-account-status.redacted.txt) | 跳过初始化前准备账户的阶段标记，用户名已替换 |
| [正文很少的 OpenCore 日志](20261023-opencore-sparse.redacted.txt) | 原文件占用约 256KB，但有效正文只有一行警告；没有记录内核崩溃过程 |

文件名日期沿用原记录或采集批次，不保证固件、Windows 和 macOS 的时钟在整个过程中始终一致。

没有找到最终多核失败对应的原始 `.panic` / `.ips` 文件，因此不提供所谓“完整 Panic 日志”。聊天中的照片能说明发生过崩溃，但不足以还原清晰、完整的堆栈；这里没有补写或猜测缺失内容。窗口服务与地区推荐相关的报错也不能单凭出现次数被认定为初始化卡住的根因。
