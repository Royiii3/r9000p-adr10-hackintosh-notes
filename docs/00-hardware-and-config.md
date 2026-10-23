# 本机硬件、版本与配置

[返回首页](../README.md) · [下一篇：时间线](01-timeline.md)

## 1. 硬件识别

本次是 **R9000P ADR10 / 83LV / Ryzen 9 8945HX / RTX 5060 Laptop**。CPU 有 16 个物理核心、32 个逻辑线程。Windows 扫描中没有另外枚举到一张可用于本次 macOS 的 AMD 集成显卡，不能因为 CPU 名称含 “with Radeon Graphics” 就假设可以改用核显加速。

关键设备：

| 设备 | 标识 / 说明 |
|---|---|
| GPU | `10DE:2D59`，8GB RTX 5060 Laptop |
| 内屏 | CSOT MNG007DA6-2，2560×1600 |
| Ethernet | `10EC:8125`，RTL8125 |
| Wi-Fi | `14C3:7925`，MT7925 |
| Bluetooth | USB `0489:E111`，MediaTek |
| AMD 音频相关 | AZAL `1022:15E3`、ACP `1022:15E2` |
| NVIDIA 音频 | `10DE:22EB` |
| 功放线索 | ACPI/I2C 设备 `AWDZ8399`；未完成独立硬件验证和驱动配置 |
| SSD | UMIS RPJYJ1T24MML1AWY |

Secure Boot 曾由用户关闭。**Above 4G Decoding 和固件 Resizable BAR 开关的实际状态没有可靠确认，记为未知。** Windows 里 ReBAR 的报告、OpenCore BAR 参数、BIOS 的 Above 4G 是不同的信息，不能互相代替。

## 2. 软件版本记录

| 组件 | 这次用到的版本 / 状态 |
|---|---|
| OpenCore | 1.0.9，早期 DEBUG，后期切到同提交 RELEASE |
| RELEASE 提交 | `d9ef47a2a7bd69a026a92b0eb040b9be71810620` |
| macOS 桌面审计 | Tahoe 26.7.1，Build `25G241`，Darwin 25.6.0；这是本机报告所记录的版本 |
| macOS 15 对照 | 有一次明确记录为 15.6.1 / `24G90` / Darwin 24.6.0 的恢复环境；不是已完成的 15 日用安装 |
| NVIDIA | 早期曾装 2.3.3；后期实际安装并加载的是 2.3.4 |
| 2.3.7 / 2.4.3 | 有下载或暂存过程，不据此认定在本机安装成功 |
| SMBIOS | `MacBookPro16,2`；是兼容配置，不代表硬件真的变成该 Mac |
| Lilu / AMFIPass | 后期配置为 Lilu 1.7.3、AMFIPass 1.4.1 |
| WhateverGreen | 后期配置为 1.7.2，与 `gfxrst=4` 一起保留 |

项目更新很快。“最新版本”没有可复现性。重做时应记录准确发布标签、文件来源和实机加载版本，再决定是否升级。

## 3. 外置启动盘与系统安装空间

早期是一只约 8GB 的 FAT32 U 盘，卷名 THINKBOOK。后期换为 256GB SanDisk Extreme Pro：

| 分区 | 用途 |
|---|---|
| MACBOOT，2GiB，FAT32，MBR 活动主分区 | UEFI 启动文件、Recovery DMG、驱动包、辅助脚本 |
| 其余空间，exFAT | 普通数据分区，与启动分区分开 |

UEFI 是否能直接读取 exFAT 取决于固件。这里使用 FAT32 是实际采用的可启动布局，不宣称只有这一种可行布局。

**2GiB 是 U 盘启动分区，不是 macOS 内存，也不是系统安装分区。** 本次恢复 DMG 约 960.5MB、驱动压缩包约 269MB，加上 EFI 可以放下。完整 macOS 由恢复安装器联网下载到内部 SSD。

安装时从 D 盘让出了约 128GiB 级别的空间，后续实际 APFS 物理存储记录为约 139.5GB（约 130GiB）。应以具体分区大小为准，不要混用 GB/GiB，也不要照抄本次磁盘编号。2026-10-24 这块 APFS 分区已删除，D 盘扩大；历史的 `disk0s5` 和 UUID 已不再适用。

## 4. 进入桌面前后保留的关键设置

下面是**本机历史配置摘要**，不是新的默认配置建议。

| 路径 | 值 | 说明 |
|---|---|---|
| `Kernel/Quirks/ProvideCurrentCpuInfo` | `true` | AMD Vanilla 要求项 |
| 四条 `Force cpuid_cores_per_package` 补丁 | 核心数 `0x10` | 16 个物理核心，不填 32 线程，也不因 `cpus=12` 改成 `0x0C` |
| Zen 4 IOPCIFamily 10-bit tags 补丁 | 启用，按 Darwin 范围区分 | Darwin 24、25 不能混用错误匹配范围 |
| 可选 `IOPCIIsHotplugPort` 补丁 | 后期启用 | 此后一次恢复启动成功；未完成严格重复对照 |
| `Booter/Quirks/DevirtualiseMmio` | `true` | 与本机内存映射问题一起处理 |
| `Booter/Quirks/SetupVirtualMap` | `true` | 本机保留值 |
| `Booter/MmioWhitelist` | `0xFF000000` 启用 | 来自本机运行时内存图与早期故障地址；不可推广到所有机器 |
| `Booter/Quirks/ResizeAppleGpuBars` | `0` | 本机恢复/安装阶段保留值 |
| `UEFI/Quirks/ResizeGpuBars` | `-1` | 不在 UEFI 阶段强制重设 BAR |
| `Misc/Security/ScanPolicy` | `0` | 排查恢复入口时使用 |
| `Misc/Boot/HideAuxiliary` | `false` | 不隐藏辅助入口 |
| `Misc/Security/DmgLoading` | `Signed` | 没有靠关闭 DMG 校验解决 U 盘错误 |
| `Misc/Security/SecureBootModel` | `Disabled` | 与 BIOS Secure Boot 分开理解 |
| `UEFI/Input/KeySupport` | `true` | UEFI 菜单输入设置 |
| `UEFI/Input/KeySupportMode` | `Auto` | 后期保留值 |
| `UEFI/Output/Resolution` | `Max` | 低分辨率对照未修复黑屏后恢复 |
| `NVRAM/WriteFlash` | `false` | 本机配置限制；不等于从未有运行时变量处理 |
| `Booter/Quirks/DisableVariableWrite` | `true` | 本机保留值 |

### 必须分开的两个阶段

| 项目 | 恢复 / 安装阶段 | NVIDIA 驱动安装成功后的系统 |
|---|---|---|
| `IONDRVSupport` 的 `Kernel/Block` | **不启用 Exclude**，使用固件 framebuffer | 本次驱动配置启用 Exclude |
| `-nvoff` | 原生系统执行驱动安装任务前临时加入 | 安装成功、启用驱动前移除 |
| NVIDIA kext 的位置 | 不是向 Recovery 里注入四个 kext | `/Library/Extensions` + Auxiliary Kernel Collection |

此前曾误把已装显卡驱动的配置继续用作重装恢复配置，后来纠正。纠正配置不等于已经证明当时所有卡住都由这一项导致。

### 能进桌面的启动参数记录

```text
-v debug=0x100 keepsyms=1 -amfipassbeta -vi2c-force-polling revpatch=sbvmm nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 cpus=1 gfxrst=4
```

这整行是历史状态，不代表每个参数都被证明不可省略。`debug=0x100` 是 macOS 的调试启动参数，**不能用来判断 OpenCore 是 DEBUG 还是 RELEASE**。后期测试只把其中的 `cpus=1` 换为 `cpus=12`，没有确认结果。

## 5. 驱动与 ACPI

启用的基础 kext 包括 Lilu、AMFIPass、VirtualSMC 及电池/光线传感器插件、AppleMCEReporterDisabler、NVMeFix、RestrictEvents、WhateverGreen、RTL812xLucy、USBToolBox、UTBDefault、VoodooI2C、VoodooI2CHID、VoodooPS2Controller、BrightnessKeys、YogaSMC。插件引用和依赖顺序需要按自己的配置核对。

这里用的是 **UTBDefault 通用配置，不是完成本机物理插拔测试的 UTBMap**。

本机启用的 SSDT 为 EC、PLUG-ALT、USB-Reset、USBX、XOSI，并有对应 `_OSI → XOSI` 重命名。文件存在和 AML 长度正确只证明基础结构，不代表运行时每个设备都已正常初始化。最终审计仍缺少正常音频栈，不能因为这些 SSDT 在就宣称声音完整。

UEFI 阶段启用的驱动为 `apfs_aligned.efi`、`HfsPlus.efi`、`OpenRuntime.efi`；`ResetNvramEntry.efi` 未启用。OpenCore 核心文件应来自匹配的同版本、同构建包。

来源：[AMD Vanilla](https://github.com/AMD-OSX/AMD_Vanilla)、[NullMoth v2.3.4 配置说明](https://github.com/nullmoth/nvidia-macos-driver/blob/v2.3.4/README.md)、[OpenCore 构建](https://github.com/dortania/build-repo/releases/tag/OpenCorePkg-d9ef47a)。
