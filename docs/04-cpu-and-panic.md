# CPU 数量、SMBIOS 与多核 Panic

[返回首页](../README.md)

## 三种“核心数”不能混在一起

| 信息 | 本机值 | 应如何理解 |
|---|---|---|
| 实际处理器拓扑 | 16 物理核 / 32 线程 | 来自硬件识别 |
| AMD Vanilla 物理核心补丁 | `0x10` | 16 的十六进制；不填线程数 |
| boot-args 的 `cpus=N` | 桌面时为 1，后准备 12 | 限制最多参与运行的逻辑处理器数量；实际生效需读取 |
| “关于本机”的 Intel 名称 | 审计记录为 Intel Xeon W 等兼容呈现 | 不能当作真实 CPU 或在线核心数 |
| SMBIOS | `MacBookPro16,2` | 兼容机型设置，不意味着物理 CPU 变成对应 Mac 的型号 |

[AMD Vanilla 的说明](https://github.com/AMD-OSX/AMD_Vanilla#read-me-first)明确使用物理核心数。Apple 的 [x86 初始化代码](https://github.com/apple/darwin-xnu/blob/main/osfmk/i386/i386_init.c)读取 `cpus` 并限制 `max_ncpus`。这是对参数含义的源码依据，不是证明当前 Tahoe/AMD 补丁的全部行为。

## 本次真正发生了什么

能进入桌面时，报告记录：

```text
hw.ncpu = 1
hw.physicalcpu = 1
hw.logicalcpu = 1
hw.activecpu = 1
machdep.cpu.core_count = 16
machdep.cpu.thread_count = 32
```

这不矛盾：封装拓扑和实际在线数量不同。它也说明不能根据“关于本机 16 核”认定 32 个线程都参与工作。

随后 macOS 端只删除了启动参数里的 `cpus=1`，并为 boot-args 增加了 NVRAM/Delete 项，以便下一次 OpenCore 重新提供配置值。**不是把参数改成 `cpus=16`。** 原报告在修改时没有重启，写的是“待验证”。

下一次启动用户拍到 Kernel Panic。Windows 端先恢复 `cpus=1`，然后按用户要求改为 `cpus=12` 做折中测试；四条 AMD 核心数补丁仍保持 `0x10`。`cpus=12` 的实际启动结果没有记录，不能写成成功。

## Intel 兼容名称是不是原因

用户提出过“模拟的 Intel 是 12 核，实际 AMD 是 16 核，所以不匹配”的假设。现有配置检查没有发现 AMD 物理核心补丁误填为 12，报告中的处理器显示名称也不足以证明这种因果关系。

不因为将 boot-args 改为 `cpus=12`，就把物理核心补丁从 `0x10` 改成 `0x0C`。两项处理不同的事情，乱改可能引入新的问题。

## 还没有定位的根因

这次没有取得足够的原始 Panic 文件来区分 CPU/TSC 同步、IPI、多核并发下的第三方驱动、PCI/GPU 或其他路径。照片中出现某个 kext，不等于它一定是根因；运行时堆栈需要完整解析。

Windows 按 UTC 解释硬件时钟的设置，解决的是双系统固定时区偏移问题；它不是跨 CPU 的 TSC 同步修复。本次没有凭这一点就安装新的同步 kext，也没有证明一律需要关 SMT、改 BIOS 或指定某个同步驱动。

## 如果后人接着试

保留能进桌面的独立 EFI 备份，确保 Windows 或 UEFI Shell 可以回退。每次只改变 CPU 限制一个变量，同时保存完整 Panic，再核对真实在线数量和稳定性。可以测试部分逻辑处理器数量，但不要用“进过一次”替代冷启动、热启动、持续负载和外设并发验收。

建议记录：

```sh
sysctl hw.ncpu hw.physicalcpu hw.logicalcpu hw.activecpu kern.bootargs
kmutil showloaded --list-only | grep -i nullmoth
```

本机停止折腾后已经没有可继续运行的 macOS，仓库也没有声称完成多核修复。
