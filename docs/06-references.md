# 上游资料与相近案例

[返回首页](../README.md)

整理日期：**2026-10-24**。链接是资料入口，不代表其中后续版本已在这台机器上测试。来自上游 Issue 的反馈是当事人报告，不等于本仓库作者的复测。

## 配置与文件来源

| 资料 | 本次用途 |
|---|---|
| [NullMoth NVIDIA 项目](https://github.com/nullmoth/nvidia-macos-driver) | NVIDIA RTX 路线与驱动机制 |
| [1401](https://github.com/nullmoth/1401) | Windows/macOS 准备与辅助工具；与内核驱动项目分开理解 |
| [NullMoth v2.3.4 README](https://github.com/nullmoth/nvidia-macos-driver/blob/v2.3.4/README.md) | 本机实际版本对应的参数、IONDRVSupport 两阶段配置、gfxrst=4、加载验收 |
| [v2.3.4 发布页](https://github.com/nullmoth/nvidia-macos-driver/releases/tag/v2.3.4) | 实际安装包来源；不转载二进制 |
| [AMD Vanilla](https://github.com/AMD-OSX/AMD_Vanilla) | 物理核心数补丁与 Zen 4 IOPCIFamily |
| [OpenCore 项目](https://github.com/acidanthera/OpenCorePkg) | 引导器和配置规范 |
| [OpenCore 配置文档](https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/Configuration.tex) | boot-args Add/Delete、驱动与 Quirk 含义 |
| [本次匹配 RELEASE 构建](https://github.com/dortania/build-repo/releases/tag/OpenCorePkg-d9ef47a) | 提交 d9ef47a 的 1.0.9 核心文件 |
| [OpenCore Install Guide](https://dortania.github.io/OpenCore-Install-Guide/) | 基础安装概念；不替代当前硬件/内核支持核对 |
| [Apple 管理 Setup Assistant 文档](https://support.apple.com/en-ie/guide/deployment/depdeff4a547/web) | 新版初始化和标记行为背景；企业管理路径不是本次家庭用户方案 |
| [Apple x86 内核初始化源码](https://github.com/apple/darwin-xnu/blob/main/osfmk/i386/i386_init.c) | `cpus` 参数和最大 CPU 数量限制的源码依据 |
| [Lima 的 macOS 初始配置讨论](https://github.com/lima-vm/lima/issues/3618) | 完成标记、账户、首次启动配置的参考；其 VM 方案没有被直接当成本机整套方案 |

AMD Vanilla、OpenCore 的默认分支会继续变化。重做时应保存自己用到的提交，不把今天的默认分支内容当成当年版本。

## 与症状相关的 Issue

- [NullMoth / 1401 #6](https://github.com/nullmoth/1401/issues/6)：早期地址/内存映射问题的参考。平台不同，不直接复制所有值。
- [NullMoth / 1401 #9](https://github.com/nullmoth/1401/issues/9)：AM5/MMIO 的相关讨论，用于形成具体测试假设。
- [NVIDIA 驱动 #185](https://github.com/nullmoth/nvidia-macos-driver/issues/185)：相近 7945HX / RTX 4060 Laptop 的 BAR/RM 初始化和后续问题。
- [NVIDIA 驱动 #320](https://github.com/nullmoth/nvidia-macos-driver/issues/320)：7945HX / RTX 4060 Laptop，黑屏可移动鼠标，后续多位用户反馈。

## 不同时间的相近机型反馈

检索时不能只写“网上有成功案例”，需要说明是哪台机器、做到哪一步。

1. [yanakulov 的初始反馈](https://github.com/nullmoth/nvidia-macos-driver/issues/320#issuecomment-6304203889)：Legion Pro 5 16ARX8、7945HX、RTX 4060 Laptop、26.7.1，官方 2.4.3 配合实验 NVRM，能进入桌面、内外屏可用；最初明确没有完成长期兼容性验证。
2. [iussch 的反馈](https://github.com/nullmoth/nvidia-macos-driver/issues/320#issuecomment-6310496740)：相近 R9000P 2023，用相同实验分支后能进桌面，但仍有严重卡顿、黑屏或会话退出。不能从第一人的结果推导所有同系列都正常。
3. [yanakulov 的后续反馈](https://github.com/nullmoth/nvidia-macos-driver/issues/320#issuecomment-6315464544)：桌面流畅、外屏工作等进一步观察，仍应按该人的配置和测试范围理解。
4. [ma0shu 的后续反馈](https://github.com/nullmoth/nvidia-macos-driver/issues/320#issuecomment-6319203298)：R9000P 2023 的整体流畅度改善，并讨论背光 ACPI。该机是不同代际，附带的 EFI 和背光补丁未在本 ADR10 上验证。

这些后续报告说明项目仍在推进，**不能把本人的停止写成“到 2026-10-24 所有 R9000P 都无法稳定运行 26”**。反过来，它们也不是 8945HX + 5060 Laptop 的精确复现。

本机最后实际运行的驱动是 2.3.4，没有在停止前转用上述 2.4.3 实验 NVRM 路线。不要把别人的后续成果写成本机已经完成的步骤。
