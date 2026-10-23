# macOS 端审计报告（公开脱敏版）

> 原报告日期：2026-10-23。由当时 macOS 会话中的 Codex 辅助生成，作者随后复制到启动 U 盘。
> 下文是当时的记录，含后续 Windows 端 reply；不是 2026-10-24 仍运行系统的证明。
> 原始测试的完整源码、输出与图片未全部收录。报告中的“通过”应按各段测试范围理解，非独立认证。
> 原报告将解除 cpus=1 放在“修复”章节，但它写明当时尚未重启；后续已发生 Panic。
> 后来的 cpus=12 测试没有记录结果。最终系统已删除，停止继续测试。
> 个人路径/身份已移除，私人文件超链接已转成文件名标签，原报告中的文件摘要省略。

---

# Hackintosh 系统审计、修复与优化报告

日期：2026-10-23，America/Los_Angeles（PDT）。对象：当前正在运行的 macOS；没有把此前安装失败或旧 Panic 当成本次仍在发生的故障。

**结论：当前能持续进入桌面，RTX 5060 的原生 Metal 计算、实际 3D 渲染以及 H.264/HEVC 硬件编解码均通过实测。但系统功能尚不完整：当前运行内核只启用 1 个逻辑处理器，内置音频、Wi-Fi、蓝牙、硬件亮度控制均存在实际问题；内置 Chromium 的 WebGL/WebGPU 测试也未通过。不能将本机标为“全面正常”。**

已按用户后续授权修改一项启动行为：解除 `cpus=1` 限制，待下一次启动验证。**本次没有重启；现在仍是 1 个在线逻辑处理器，尚未证明 16 核 32 线程启动稳定。**

完整原始证据、测试源码、备份及变更记录位于 审计证据目录（本机文件：`HackintoshAudit-20261023`，原件未公开）。其中含设备标识和原始配置，请勿直接公开整个目录。本报告不展示完整序列号、MLB、UUID 或 MAC 地址。

## 1. 系统总体健康状态

| 项目 | 当前检测结果 | 判断与边界 |
|---|---|---|
| macOS | 26.7.1，Build 25G241 | 实际 `sw_vers` 输出 |
| 内核 | Darwin 25.6.0，xnu-12377.161.15.700.19，RELEASE_X86_64 | x86_64，非安全模式 |
| CPU 身份 | AuthenticAMD；AMD Ryzen 9 8945HX with Radeon Graphics；Family 25 / Model 97 | 不是只根据 SMBIOS 名称判断 |
| SMBIOS | MacBookPro16,2；ProcessorType 3841 | “16-Core Intel Xeon W / 2.5GHz”等为兼容呈现，不作为硬件故障 |
| 序列化字段 | 序列号 12 字符、MLB 17 字符、ROM 6 字节、UUID 非零 | 仅格式及本地配置检查；未向 Apple 查询有效性或唯一性 |
| 当前核心 | `hw.ncpu=1`、physicalcpu=1、logicalcpu=1、activecpu=1 | 明确异常限制；同时 `machdep.cpu.core_count=16`、thread_count=32，区分封装拓扑与在线 CPU |
| 内存 | 32GiB；CXMT 16GB ×2，固件报告 5200MHz，槽位状态 OK | 工具将类型写成 RAM，未据此独立证明 DDR5；未运行破坏性/长时间内存测试 |
| 系统卷 | 内部 NVMe 上的 APFS 只读、Sealed 系统快照 | 系统卷和 Data 卷分别 `fsck_apfs -n` 校验，均退出 0、appears to be OK |
| 空间 | APFS 容器约 139.5GB，初始空余约 103.7GB | 没有系统盘空间不足证据 |
| 核心服务 | launchd PID 1、loginwindow PID 852、WindowServer PID 859 正在运行 | WindowServer 当前会话持续运行；launchd 记录 runs=2、上次正常退出 0，不是反复崩溃循环 |
| Panic | 本轮日志及可访问 DiagnosticReports 未发现当前持续 Kernel Panic | 短期审计不能证明长期绝无 Panic |
| 服务稳定性 | secd、usernoted 各有一次约 05:30 的 SIGBUS 报告；蓝牙服务持续重启 | 单次旧崩溃与持续故障分别处理，不批量重置系统数据库 |
| 初始化 | `.AppleSetupDone` 存在；未发现活动 Setup Assistant 或 `macOS Install Data` 残留任务 | installd、bootinstalld 等系统服务的存在本身不代表安装未完成 |

证据：基础配置/显卡/存储/电池（本机文件：`profiler-core.json`，原件未公开）、内存（本机文件：`memory-profiler.json`，原件未公开）、系统卷校验（本机文件：`apfs-system-verify.txt`，原件未公开）、数据卷校验（本机文件：`apfs-verify.txt`，原件未公开）。

## 2. 硬件识别与驱动状态表

| 硬件/功能 | 实际证据 | 当前状态 |
|---|---|---|
| RTX 5060 Laptop | PCI 10DE:2D59；NVIDIA/NVK GB206-B；8GB；PCIe x8 | 已识别、驱动加载，原生加速实测通过 |
| 内屏 | CSOT MNG007DA6-2；原生 2560×1600；逻辑 1280×800 HiDPI；240Hz | CoreGraphics 再次读取一致；未自动切换显示模式 |
| 硬件亮度 | 驱动明确报告 no backlight；DisplayServices 读取亮度返回 1000，未返回有效数值 | 不正常；不能因为 BrightnessKeys 已加载就判正常 |
| 键盘 | ApplePS2Keyboard / VoodooPS2Keyboard 已绑定 | 驱动层已确认；全键、组合键需人工实测 |
| 触控板 | I2C、VoodooI2CHID、VoodooInput、AppleMultitouchDevice 已注册 | 滚动/缩放等手势偏好存在；实际二/三/四指操作需人工实测 |
| USB | 3 个 XHCI；当前分别枚举 4/4/1 个根端口；7 个 USB 设备可见 | 当前 USB 启动盘可读写，鼠标/摄像头/无线模块可枚举；不能推广为每个物理接口通过 |
| Wi-Fi | MediaTek MT7925，PCI 14C3:7925，子系统 17AA:E0FF | PCI 可见，无网络驱动绑定和 Wi-Fi 接口 |
| 蓝牙 | USB 0489:E111 Wireless_Device，无实际蓝牙传输驱动子节点 | 不正常；系统所示 BCM_4350C2/UART 是无有效控制器的呈现，不是本机真实芯片认定 |
| 有线网卡 | Realtek 10EC:8125，RTL812xLucy；en0，1000baseT full-duplex | 当前联网正常；接收/发送错误及碰撞计数均为 0；未验证 2.5Gbps 链路 |
| 内置音频 | AMD AZAL 1022:15E3、ACP 1022:15E2、NVIDIA NHDA 10DE:22EB 存在 | 原生 CoreAudio 返回 0 个音频设备；内置扬声器/耳机/麦克风不能判正常 |
| 扬声器放大器 | I2C/ACPI `AWDZ8399`，地址 0x35 | 提示 AW88399 智能功放路径；仅加一个音频 layout 未必能解决扬声器 |
| 摄像头 | Integrated Camera，USB 5986:2175；AVFoundation connected=true、suspended=false、12 个格式 | 枚举与能力正常；当前摄像头授权尚未决定，未启动取景，画面需人工测试 |
| NVMe | UMIS RPJYJ1T24MML1AWY，固件 1.0L06C1，PCIe 16GT/s ×4 | SMART Verified、TRIM Yes，块设备读写错误/重试均为 0 |
| 电池 | Sunwoda L24D4PC0；26 次循环；100%、满电、AC 接入 | 电量与接电状态已确认；充放电切换、实际续航需人工实测 |
| HDMI/USB-C 显示 | 当前仅 1 个连接显示器 | 需要接显示器实测；视频与音频应分别验收 |
| 音量/亮度功能键 | PS2Keyboard、BrightnessKeys 已加载 | 按键事件、OSD 和实际效果须分开；目前没有有效音频和背光接口 |

证据：设备概况（本机文件：`profiler-devices.json`，原件未公开）、CoreAudio 原生枚举（本机文件：`audio-native.json`，原件未公开）、摄像头原生枚举（本机文件：`camera-native.json`，原件未公开）、显示及亮度 API（本机文件：`display-native.json`，原件未公开）。

## 3. RTX 5060 Metal 加速专项检查

### 驱动版本与来源

- 当前加载 `com.nullmoth.NVRM`、`NVAccel`、`NVRMFB`、`NVRMAGDC`，全部为 **2.3.4**；不是 Apple/NVIDIA 官方 macOS RTX 驱动。
- Metal 插件为 `/Library/GPUBundles/NVMTLDriver.bundle`，链路为 NVMTL → AIR/SPIR-V 转译 → Mesa NVK → NVRM → GPU。固件目录为 `/Users/LOCAL_USER/nvfw/nvidia/610.57.04`。
- 本地安装包 SHA-256 为 `[HISTORICAL_HASH_OMITTED]`，与 GitHub 官方项目 v2.3.4 release asset 的 digest 完全一致。
- 比对 52 个已安装文件：默认包路径中 NVAccel 是 macOS 15 变体，本机实际文件与包内 **26 专用变体**一致；不能将该正常版本选择误报为篡改。
- NVRM 和 NVMTL 均为 ad-hoc 签名，未配置 Developer ID TeamIdentifier。来源匹配不等于具有 Apple 的安全审查或完整硬件兼容保证。

来源与本机校验：[v2.3.4 项目说明](https://github.com/nullmoth/nvidia-macos-driver/blob/v2.3.4/README.md)、安装包来源与 hash（本机文件：`package-origin.json`，原件未公开）、已加载模块（本机文件：`kexts-loaded.txt`，原件未公开）。

### 识别、加载、API、实际执行分别验收

| 层级 | 测试 | 结果 |
|---|---|---|
| 1. 硬件识别 | PCI、显存、显示器信息 | RTX 5060 Laptop，8GB，2560×1600/240Hz |
| 2. 驱动加载 | kmutil + IORegistry | 四个 2.3.4 kext；NVRM 状态 up/running；NVAccel 已启用 |
| 3. Metal API | 创建原生 MTLDevice、运行时编译着色器、创建管线 | 成功；设备 registryID 0x10000043e 指向当前 NVIDIA 加速器 |
| 4. 计算执行 | 4096 个 uint 执行 `i*3+7`，逐项 CPU 回读比较 | 0 个错误；command status=4，error=nil |
| 4. 渲染执行 | 64×64 三角形，逐像素比较预期颜色 | 4096 像素均通过；中心 RGBA=(64,127,191,255) |
| 4. 3D 扩展 | 256×256 透视立方体，12 个三角形、GPU 顶点变换、Depth32Float，8 帧旋转 | 8 帧均正常完成，8 个不同帧 hash，回读图像可辨识立方体 |
| 桌面合成 | NVAccel user client + 显存 + 实际翻转日志 | WindowServer、WebKit、Codex 服务均有加速器连接；约 1.16GB 显存使用；观察到成功 flip |

首次计算 wall time 18.18ms，驱动报告 GPU 时间约 9.7µs；简单渲染 wall time 2.34ms，报告 GPU 时间约 10.9µs。**这些小测试用于确认正确执行，不作为 RTX 5060 满性能跑分；非官方驱动时间戳也不能单独证明性能。** 回读正确性、GPU 设备路径、3D 输出和桌面活动一起构成加速证据。

证据：基础 Metal 结果（本机文件：`metal-result.json`，原件未公开）、3D 测试结果（本机文件：`metal-3d-result.json`，原件未公开）、加速器与客户连接（本机文件：`accelerator.txt`，原件未公开）。

本机 Metal 深度测试立方体，8 帧测试中的最后一帧（原始本机图片未公开）

### 视频编解码

直接调用系统 VideoToolbox/CoreVideo/CoreMedia，要求硬件编码器和硬件解码器，检查 UsingHardwareAccelerated 属性，并将编码产物送回解码器。

| 格式 | 320×240 单帧 | 1280×720、8 帧往返 | 边界 |
|---|---|---|---|
| H.264 | 编码、解码成功，Hardware=true | 8/8 编码样本，8/8 解码图像，尺寸正确，全部 API 状态 0 | 不代表 4K、高码率或所有 profile 已通过 |
| HEVC | 编码、解码成功，Hardware=true | 8/8 编码样本，8/8 解码图像，尺寸正确，全部 API 状态 0 | 未测试 Main10/HDR、长时间播放 |
| VP9 / AV1 | 硬件解码能力查询为 false | 未执行码流测试 | 是当前 macOS/驱动接口结果，不是宣称 GPU 硬件没有相应单元 |

证据：视频往返结果（本机文件：`video-result.json`，原件未公开）、720p 多帧结果（本机文件：`video-720p-result.json`，原件未公开）。

### 浏览器与图形日志

- 在实际 Codex 内置 Chromium 155 标签页运行本地测试：Canvas 2D 回读颜色正确，**WebGL 1/2 均无法创建上下文，WebGPU 有 API 但 adapter=null**。90 次动画回调的中位间隔约 4.3ms；帧回调不等于 3D 加速。
- 本结论限定于内置 Chromium。现有 Safari/WebKit 进程确实连接 NVAccel，但没有直接完成 Safari 网页 WebGL 实测，不能将两种浏览器合并判定。
- 当前版本源码确实有 `NVMTL_ANGLE_METAL=1` 的进程级选项，同时说明 Electron 可能出现视觉问题。ANGLE 的 NVIDIA 限制是一个有来源的原因假设；仍需区分宿主浏览器策略。没有全局开启该选项，也没有关闭沙盒或伪装 GPU。
- 浏览器内部 `chrome://gpu` 被工具 URL 策略阻止，未绕过。测试页面源文件保留在 本地浏览器测试页（本机文件：`index.html`，原件未公开），可另用 Safari 打开复测。
- 本轮约 72 分钟图形日志包含 554 条 Invalid display、219 条 no gamma、118 条 Singular matrix；这些不是每条都代表黑屏。最后记录分别到约 06:25、05:57、05:31，不能说它们一直持续到审计结束。
- 未发现 Xid、GPU reset、GPU fallen off、Failed to get a MTLCommandBuffer；初始化报告 RmInitAdapter succeeded。示例翻转统计为 37 flips/s、面板 240Hz，missed/skipped=0。这是当时桌面更新频率，不是 240Hz 游戏跑分。

证据：浏览器结果（本机文件：`browser-result.json`，原件未公开）、当前版本 ANGLE 源码（本机文件：`NVMTLDevice.m`，原件未公开）、原始图形日志（本机文件：`graphics-log.txt`，原件未公开）。

## 4. OpenCore / EFI 配置审计

### 实际启动来源与双系统

- 系统安装在内部 `disk0s5` 的 APFS 容器；**OpenCore 位于外置 SanDisk 的 `disk1s1`，挂载名 MACBOOT**，是 FAT32 分区，并非内部 EFI。
- 内部 `disk0s1 SYSTEM_DRV` 已只读挂载检查，只有 Boot、Lenovo、Microsoft、UpdateCapsule 等目录，无 OC/config.plist。Windows 的 bootmgfw.efi 和原有 fallback bootx64.efi 存在；fallback 文件也不是外置 OpenCore 的相同二进制。
- 外置最后启动日志时间与本轮内核启动相邻，运行 boot-args、SMBIOS 和 kext 组合与外置配置对应。当前检查支持外置 EFI 是实际来源；固件未向 macOS 暴露 BootCurrent/BootOrder/efi-boot-device，不能伪造一份已读取的固件启动顺序。
- 内部 EFI 已卸载。Windows-SSD、Software、Microsoft/Lenovo EFI 均未写入。没有改 Windows Boot Manager、GPT、TPM、BIOS 或固件启动项。Windows 从固件菜单实际启动仍需人工验证。

### 配置与依赖

| 项目 | 检查结果 |
|---|---|
| OpenCore 版本 | U 盘原说明称 1.0.9 RELEASE；二进制只提取到 `REL-XXX-YYYY-MM-DD` 占位串，无法独立认证精确构建。尝试对应官方 release 归档返回 404，因此没有冒充已做官方二进制匹配 |
| 配置验证 | 原始及修改后 `plutil -lint` 均通过；所有启用 ACPI/kext/UEFI 文件路径存在。没有匹配版本 ocvalidate，不能把 plist 语法通过说成完整 OC schema 验证 |
| ACPI | SSDT-EC、PLUG-ALT、USB-Reset、USBX、XOSI；5 张表长度和校验和均正确；_OSI→XOSI 已启用。未声称仅凭校验和就证明语义适配 |
| Kext 顺序 | Lilu 在插件之前；VirtualSMC 在 SMC 插件之前；USBToolBox 在 UTBDefault 之前；VoodooI2CServices/GPIO/Input 等依赖可用 |
| 重复项 | PS2 包中的第二份 VoodooInput 已禁用，I2C 版本启用；不是双重加载。没有发现未被 config 引用的顶层 kext 文件夹 |
| UEFI | apfs_aligned、HfsPlus、OpenRuntime 启用；ResetNvramEntry 禁用；OpenShell 保留 |
| APFS | EnableJumpstart=false，使用外置 apfs_aligned；当前 APFS 成功启动。未替换为另一套 APFS 方案 |
| Booter | DevirtualiseMmio/RebuildAppleMemoryMap/SyncRuntimePermissions 等现有组合保留；保留原 0xFF000000 MMIO whitelist；未因历史 CR2 注释就改配置 |
| GPU BAR | ResizeAppleGpuBars=0，UEFI ResizeGpuBars=-1；运行 NVRM 看到 BAR1 8192MB。没有盲改 BIOS ReBAR |
| NVRAM | WriteFlash=false；Booter DisableVariableWrite=true；当前 macOS 只读到 7 个变量，说明可见性受限，并非一次完整固件 NVRAM 审计 |
| Windows SMBIOS 隔离 | UpdateSMBIOSMode=Custom、CustomSMBIOSGuid=true，符合仅向 macOS 提供自定义 SMBIOS 的设计；不替换当前机型 |
| 调试项 | -v、debug=0x100、keepsyms=1、日志 Target=67、AppleDebug/Panic 保留。多核尚未验证，不为日志好看先删除调试信息 |
| IONDRVSupport 阻断 | 配置有 Exclude，OC 本轮日志为 Unsupported，运行中 IONDRVSupport 600 仍加载。记录为配置与实际效果不一致；当前 NVIDIA 正常，未强制卸载或删除依赖 |

主 kext 版本：Lilu 1.7.3、AMFIPass 1.4.1、VirtualSMC/电池/光线 1.3.9、WhateverGreen 1.7.2、RestrictEvents 1.1.7、NVMeFix 1.1.4、VoodooI2C 2.9.1、VoodooPS2 2.3.8、USBToolBox 1.2.0、UTBDefault 1.0、YogaSMC 1.5.3、BrightnessKeys 1.0.4。RTL812xLucy 包的短版本为 1.1.1，运行 CFBundleVersion 显示 1.1.100，不能仅凭两个版本字段写法不同认定冲突。

证据：原版 EFI 及 hash 清单（本机文件：`MACBOOT-EFI`，原件未公开）、备份清单（本机文件：`backup-sha256.json`，原件未公开）、内部 EFI 只读挂载证据（本机文件：`internal-efi-readonly.txt`，原件未公开）。

## 5. CPU、内存、SSD 与电源管理

**CPU：** AMD 核心补丁四个 Replace 均按 16 个物理核心设置为 0x10，不是按 32 线程填写。ProvideCurrentCpuInfo=true，DummyPowerManagement=true。Darwin 25.6 对应的 Zen 4 Disable 10-bit tags 补丁、AM5 PCI 枚举补丁和 26.4+ 时间相关补丁均配置启用；Find/Mask 在当前磁盘内核或 BootKC 中能找到候选。部分模式需要 Base/Count 限定，原始候选数不能作为运行时应用成功的逐项证明。没有切换到可能影响 NVIDIA 的另一种 PAT 补丁。

与 [AMD Vanilla 原始说明](https://github.com/AMD-OSX/AMD_Vanilla) 对照，核心数和 ProvideCurrentCpuInfo 的方向正确。本机还有版本细分/本地调整，未拿最新模板覆盖整个 Kernel/Patch。

当前 `cpus=1` 是在线 CPU 数异常的直接证据。交互采样中 CPU 经常接近饱和，WindowServer 约 40–59% 单核 CPU；采样时有 Codex、网络和检测活动，**不是严格空闲基准**。优先验证解除限制后的行为，再评价剩余高占用。

`sysctl` 报告的 2.5GHz min/max 是兼容呈现，不能据此断定锁频。一次 powermetrics 报约 5.07GHz，但同时有 SMC Invalid key、没有可信 AMD 温度和 C-state 数据；不能把这些零值解释成过热或全部省电失效。未自动安装新电源管理 kext，未做长时间满载测试。

**内存：** memory_pressure 报 86% system-wide memory free percentage，压缩和 swap in/out 为 0；top 的约 31GB used 与该指标不是同一个概念，不能仅凭 used 数字清缓存或判定泄漏。

**SSD：** SMART Verified、TRIM 开启，当前 NVMe 块驱动读写错误和重试计数均为 0；System/Data 两卷只读校验通过。只在 macOS 用户日志目录创建并删除测试文件，未写原始磁盘或 Windows 分区。64MiB F_NOCACHE + fsync 测试写约 709MiB/s、带 SHA-256 读取约 216MiB/s，校验正确；进一步将 hash 移出读计时、使用 F_FULLFSYNC 后，短测写约 1278MiB/s、读约 320MiB/s。样本小、单核繁忙，包含缓存/调度影响，不代表持续 SSD 性能，不能据此给 NVMe 打满分或判坏。

**电池/睡眠：** AC、满电和健康状态正常可读，软件报告适配器 60W，未核对物理适配器铭牌，不据此判定供电不足。pmset 当前 Sleep/DarkWake/UserWake 计数均为 0；hibernatemode=3，而 OpenCore HibernateMode=None。未测试合盖/深度休眠恢复，也未擅自改变这些值。ChatGPT Electron、外置介质、USB、网络和系统后台任务持有睡眠断言；存在断言不等于电源管理故障。

补充合盖定位：`AppleACPILid` 已绑定 LID0/PNP0C0D，启动日志确实接收到“盖子打开”事件；因此不能说盖子传感器完全没驱动。IOPM 报 IOSleepSupported=true、SleepDisabled=false，但 **AppleClamshellCausesSleep=false**；日志最后为 `disabled 0/0, desktopMode 1, ac 1`。当前 AC 桌面模式策略不会把合盖等同于必须睡眠，仍需在实际使用条件下验证；未把这一策略现象直接归咎于传感器或擅自写 pmset。证据：合盖状态/绑定（本机文件：`lid-policy.json`，原件未公开）、合盖电源日志（本机文件：`lid-log.txt`，原件未公开）。

证据：补丁模式匹配结果（本机文件：`patch-pattern-check.json`，原件未公开）、powermetrics 原文（本机文件：`powermetrics.txt`，原件未公开）、SSD 校验（本机文件：`ssd-result.json`，原件未公开）、补充吞吐测试（本机文件：`ssd-throughput.json`，原件未公开）、块存储错误计数（本机文件：`storage-counters.json`，原件未公开）。

## 6. 无线、音频、USB 与日常使用的进一步定位

**Wi-Fi：** 确认 MT7925 PCI 设备存在，问题不是“机器没有网卡”。EFI 没有该芯片驱动，当前只有 Ethernet 和 iPhone USB 网络服务。已找到 [MT7925 驱动项目](https://github.com/thanhnndev/ga403wm-hackintosh/blob/main/docs/WIFI.md)，但文档包含 Recovery/Sequoia 实测、原生前端、速率和电源管理限制，不能把另一台参考机的结果直接写成这台 Tahoe 已验证。没有安装 Intel itlwm 或 Broadcom 驱动来凑数。

**蓝牙：** 约 8 分钟采样中出现 16 个 bluetoothd PID，约每 31 秒一次 `BlueTool timed out running boot script`，launchd 记录已运行超过 150 次、上次退出 1；USB 无对应 firmware loader/transport 绑定。当前首要问题是控制器初始化，而不是已证实的 LE 配对漏洞。对应的 [MtkBt 项目](https://github.com/watchthelight-labs/mt7925-hackintosh-bluetooth)明确支持本机 USB ID 和 Tahoe，但没有睡眠/唤醒处理、参考硬件有限。其配套 [LegionBtFix](https://github.com/watchthelight-labs/LegionBtFix) 只匹配 25G241，并会改变 LE 地址行为；本机尚未出现它针对的 LE/BT-clock 症状，未预先添加这些补丁，更未启用会记录音频载荷的 HCI 日志绕行。

**音频：** SPAudio、IOAudio 节点与原生 CoreAudio 三种检查均表明没有设备；当前系统无 AppleHDA.kext，EFI 也无 AppleALC。AZAL 控制器及 AWDZ8399 功放存在。外部同机型报告提示 ALC287 + AW88399，但没有读取到本机 codec ID，故保留为待核实信息。可评估 [SimpleHDA](https://github.com/laobamac/SimpleHDA) 的 OpenCore/Lilu 注入路线，避免直接修改系统卷；它依赖 AppleALC 和正确的已验证 layout，不能现在猜一个 alcid 就宣布扬声器、耳机、麦克风全部修好。功放初始化须另行确认。

**USB：** 当前使用通用 UTBDefault，没有定制 UTBMap，现有根端口数量未超过每控制器 15 的上限。BT 设备已经可见，不能将其初始化超时全部归咎于缺失端口。仍需按物理 USB-A/C、正反插、USB2/3 设备实测，确定端口连接类型和内部设备映射后再替换地图。

**网络/DNS：** Ethernet 1Gbps 全双工；收发错误 0；现用 DNS 和默认路由可工作。Apple HTTPS 返回 200，一次采样 DNS 约 24.7ms、TLS 完成约 151ms、请求总计约 232ms。未随意换 DNS 或移除代理配置。

**后台与启动：** /Library/LaunchAgents、/Library/LaunchDaemons 无第三方条目；用户 LaunchAgents 目录不存在；Background Task Management 仅发现当前 Codex/ChatGPT 项目及 Dock 插件，没有发现残留的 NVIDIA 自动安装或 WindowServer 重启任务。Spotlight 在 System/Data/外置数据盘启用，未观察到它是首要持续 CPU 瓶颈，没有关闭索引。初次用户会话比内核启动晚约 8 分钟，但本轮经历安装后账户初始化；没有拿这个数冒充稳定系统的冷启动耗时。常见应用的完整“启动至可交互”耗时仍需冷/热启动实测，当前未给出伪造跑分。

## 7. 问题、优先级与处理状态

本轮未发现已确认的当前 P0 数据损坏或持续内核崩溃。待验证启动配置仍有失败风险，已准备恢复文件，不能等同于无风险。

| 编号 | 优先级 | 当前状态与实际证据 | 原因/待验证假设 | 推荐处理 | 已修复？/是否还需确认 |
|---|---|---|---|---|---|
| CPU-01 | P1 | 在线 CPU=1，boot-args 有 cpus=1；封装拓扑 16/32 | 明确启动限制；多核稳定性未知 | 去掉限制并验证下一次启动 | 配置已改，效果未验证；执行授权已获，仍需安排重启 |
| AUD-01 | P1 | CoreAudio 0 设备，无 AppleHDA/AppleALC，存在智能功放 | 音频栈缺失；具体 codec/layout/功放配置未验证 | 确认 codec 后注入匹配音频栈，分开测耳机/扬声器/麦克风 | 未修复；需取得可靠硬件参数与选择驱动方案 |
| WLAN-01 | P1 | MT7925 PCI 可见，无网络接口 | 缺少对应驱动 | 核对 Tahoe 对应实现及可靠发行包，再做可回退试装 | 未修复；实验性方案需决定是否接受其限制 |
| BT-01 | P1 | USB 可见，BlueTool 超时约每 31 秒重启 | 缺少 MediaTek 固件加载及传输适配 | 评估 MtkBt + BlueToolFixup；先验证初始化，不预加 LE/音频补丁 | 未修复；睡眠兼容性未证明 |
| DISP-01 | P1 | no backlight；亮度 API 失败 | 当前 NVIDIA/固件未注册面板背光 | 针对本机 CSOT LCD 核对 ACPI/背光路径；不能套 ASUS OLED 的 DPCD 写入 | 未修复；不写未经验证的面板寄存器 |
| WEB-01 | P2 | 当前内置 Chromium 的 WebGL1/2、WebGPU 不可用，Canvas 正常 | 可能涉及 ANGLE NVIDIA 限制或宿主策略 | 用应用独立启动环境做 Metal 选项 A/B，并单独测 Safari | 未修复；重启应用会中断当前会话，未全局改环境 |
| SEC-01 | P1 | 当前驱动 ad-hoc、AMFI/SSV 保护放宽；后续版本有安全修复公告 | 已知安全代价；具体公告影响范围需按版本核对 | 完整备份驱动/固件后评估含修复的稳定版，独立验证 | 未升级；不因“不是最新”直接替换 |
| USB-01 | P2 | UTBDefault，无定制映射；当前可见设备工作 | 尚缺逐接口映射验证 | 人工插拔生成本机端口表，再做精确地图 | 未修改；目前没有证据支持删端口 |
| PM-01 | P2 | 无睡眠/唤醒记录；LID 已绑定，但 AC desktopMode=1、ClamshellCausesSleep=false；温度/C-state 不可靠 | 合盖策略和唤醒支持待验证，不是已证实传感器失效 | 多核验证后测试睡眠、合盖、AC/电池切换并核对桌面模式来源 | 未宣称修复；需人工实测及可恢复启动环境 |
| EFI-01 | P2 | 内部无 OC，依赖外置启动；版本构建未独立认证；Exclude 返回 Unsupported | 部署/可维护性欠缺，非当前不能启动 | 保留 U 盘；留存构建来源和 matching validator；先不迁移内部 EFI | 未迁移；任何内部部署需另行具体方案，不能覆盖 Windows |
| LOG-01 | P2 | no gamma/Invalid display 等本轮有记录；无当前重复 GPU reset | 部分图形兼容性异常，未证明就是黑屏根因 | 关联具体窗口/显示操作复现，再决定驱动调整 | 未隐藏日志、未删除错误以美化结果 |
| DBG-01 | P3 | 调试参数和调试日志保留 | 诊断阶段合理，可能有少量开销 | 多核和日常功能稳定后，仅清理有必要的调试项 | 暂不处理，不与本次 CPU 改动捆绑 |

后续 NVIDIA 安全修复公告：[v2.3.7 发布说明](https://github.com/nullmoth/nvidia-macos-driver/releases/tag/v2.3.7)。公告提到解码与本地/网页可达缺陷；本次没有运行漏洞利用，也未将新版的所有修复未经验证地套到本机现象上。

## 8. 已完成的安全修复与准确变更清单

### 已落盘的 CPU 启动修复

唯一被修改的活动 EFI 文件：config.plist（本机文件：`config.plist`，原件未公开）。

1. `NVRAM/Add/7C436110-AB2A-4BBB-A880-FE41995C9F82/boot-args` 仅删除 `cpus=1`，保留其余参数。
2. 同 GUID 的 `NVRAM/Delete` 增加 `boot-args`，使下次 OpenCore 引导时用已保存的参数取代继承旧值。[OpenCore 文档](https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/Configuration.tex)说明 Add 不覆盖已存在变量，需要配合 Delete。没有在当前系统直接写入或重置 NVRAM。

修改前 SHA-256：`[HISTORICAL_HASH_OMITTED]`。

修改后 SHA-256：`[HISTORICAL_HASH_OMITTED]`。

修改后 plist 能解析、语法检查通过，配置语义比较只出现上述两处变化；EFI 其他文件 hash 未变，运行 NVRAM 与审计前逐项一致。**未重启，不计为已完成多核修复验收。**

### 备份、恢复和提权收尾

- 原版完整 EFI 共 130 个文件，先在内部 macOS 用户目录备份，再在 U 盘备份；均按 SHA-256 校验。
- U 盘原版：EFI-STABLE-20261023（本机文件：`EFI-STABLE-20261023`，原件未公开）。内部第二份：MACBOOT-EFI（本机文件：`MACBOOT-EFI`，原件未公开）。
- 已写 恢复说明（本机文件：`Hackintosh-Rollback.txt`，原件未公开），可在现有 UEFI Shell 中识别 MACBOOT 后，将原版 `OC/config.plist` 复制回活动位置。恢复不依赖 macOS 内核成功启动。
- 按用户要求，通过 macOS 原生管理员认证临时添加了只允许本轮只读检查/挂卸 EFI 的 sudo 规则；visudo 验证通过、root:wheel 0440。检查后规则已删除，主 sudoers 未修改，不保留整个管理员账户的永久免密。
- 内部 EFI 全程只读并已卸载；磁盘布局、Windows 引导、系统卷、已安装驱动文件和安全策略均未改。
- 本轮 Python 工具探测曾触发系统开发工具安装提示，随后改用已存在的运行时并关闭提示；没有安装 Xcode/Command Line Tools。临时 SSD 测试文件已删除。

证据：变更记录（本机文件：`changes.json`，原件未公开）、最终一致性检查（本机文件：`final-verification.json`，原件未公开）。

## 9. 安全状态与可恢复范围

| 保护 | 实际状态 | 本次处理 |
|---|---|---|
| SIP | 自定义 0x0A43：Kext signing、Filesystem、NVRAM 等部分保护放宽；并非所有 SIP 位都关闭 | 保留，没有继续降低 |
| Authenticated Root | Disabled | 系统快照仍显示 Sealed；封印状态与是否强制验证不是同一件事 |
| AMFI | AMFIPass 已加载，另有 amfi=0x80、amfi_get_out_of_my_way=0x1 | 内核明确记录后者使 app bundle/container protections 关闭；不能只看 AMFI policy loaded 就称完整开启 |
| Gatekeeper | assessments enabled | 未关闭 |
| OpenCore SecureBootModel | Disabled | 未改 BIOS Secure Boot；两者不是同一个开关 |
| FileVault | Off | 未自动启用；当前引导与恢复兼容性尚需确认 |
| 固件/驱动权限 | 当前 GPU 插件、固件目录 root 所有、非任意用户可写 | 未改变已有驱动或注入来源不明脚本 |

v2.3.4 的项目安装配方要求当前 AMFI 参数、0x0A43、SecureBootModel Disabled、Lilu/AMFIPass；`gfxrst=4` 与当前 WhateverGreen 并存也有来源依据。**这是配方要求，不等于本次已经证明每一项在本机都不可省略。** 暂无证据可以直接恢复 SIP/Authenticated Root/AMFI 并保证驱动继续加载；恢复安全设置需单独做受控启动验证。没有为了显示“安全”而假报已恢复。

## 10. 人工实测、待确认事项及下一次启动验收

以下项目无法通过当前只读枚举完整证明，不标“正常”：

- 内置键盘全键、修饰键、音量/亮度等 Fn 组合；触控板点击、拖动、二/三/四指手势。
- 所有物理 USB-A/C 接口、USB-C 正反插、USB2 与 USB3、连接设备持续传输；外接显示视频和音频分别测试。
- 摄像头实际画面、曝光与持续取景；扬声器、耳机、麦克风需在音频设备恢复后实测。
- 拔插电源后的电量/充电变化、适配器实际额定功率、真实 CPU 温度和风扇变化。
- 正常睡眠、唤醒、合盖/开盖、深度休眠恢复；先保存工作，不在当前审计会话中强制合盖或睡眠。
- Safari WebGL/视频播放，浏览器缩放/滚动/多窗口；长时间 3D、HDR、4K 编解码、外接屏热插拔。
- 从固件菜单实际启动 Windows；稳定系统的冷启动、热启动、应用启动计时。

常规必要修改已获本轮执行授权，不重复要求泛泛确认。还需具体决定的事项：**何时重启验证多核；是否接受 MT7925 第三方驱动的睡眠/配对限制；是否接受 LegionBtFix 的地址隐私变化（目前没有本机对应症状，不建议预加）；音频使用何种经硬件确认的恢复栈；是否在完整驱动/固件回退备份后更换 NVIDIA 版本。** 这些均没有在本轮擅自安装或批量启用。

下一次正常启动后，应首先看到：

```sh
sysctl hw.ncpu hw.physicalcpu hw.logicalcpu hw.activecpu kern.bootargs
```

期望 16 physical / 32 logical，且无 cpus=1；随后复跑本报告 Metal/多帧视频小测试，并复查新 Panic、CPU/WindowServer 占用。若无法进入系统，按恢复说明还原 config，先恢复可启动状态。不能用新增忽略错误、关闭更多保护或掩盖时间异常来凑出“32 线程正常”。

## 11. 后续最值得执行的三项优化

1. **完成多核启动验证。** 当前性能限制最明确、收益最大，修改已准备，原版和恢复方法齐全。验证后再评价 CPU/SSD/WindowServer 性能。
2. **处理实际浏览器图形缺口并评估 NVIDIA 安全修复。** 先做应用独立的 ANGLE/Metal A/B 和 Safari 对照；不要因为原生 Metal 已通过就忽略 WebGL 失败，也不要不备份就升级整个驱动。
3. **按已确认的硬件分开恢复无线和音频。** MT7925、0489:E111、AZAL/ACP、AWDZ8399 的身份已定位；先核对 Tahoe 支持、codec/layout 和功放，再用精确 kext/USB 映射，避免套整套他人 EFI。睡眠、续航和外设完整验收随对应驱动恢复后继续。

本轮完成的是有实际测试和证据的审计，以及已落盘但尚待重启验收的 CPU 配置修复；没有将待安装驱动、待人工操作或待启动验证项目写成已经修好。


## reply（Windows 端，2026-10-23）

用户已经完成跳过初始化并进入桌面，随后在 macOS 中运行了本报告的审计。报告之外新增的启动结果与变更如下，原报告正文保留为当时的历史记录：

1. 移除 `cpus=1` 后的第一次启动发生 Kernel Panic，用户已提供屏幕照片。因此“无 CPU 数量限制”的启动验证本次未通过，不应标为多核修复完成。照片尚不足以认定具体根因，原始 Panic 报告仍待读取。
2. Windows 端已先把活动 EFI 恢复为 `cpus=1`，随后根据用户明确要求，现仅将 `cpus=1` 改为 **`cpus=12`** 做折中启动测试。当前测试尚未启动验收。
3. 上一版配置实际是删除 `cpus=1`，并不是写入 `cpus=16`。本机物理拓扑是 16 核 / 32 线程；`cpus=12` 限制的是最多在线逻辑处理器数量，不表示模拟 12 个物理核心。
4. 当前 SMBIOS 仍为 `MacBookPro16,2`，AMD 四条物理核心数补丁仍为 **`0x10`（16）**；不要为了 `cpus=12` 将它们改为 `0x0C`。“Intel 处理器显示为 12 核导致崩溃”目前仅是用户提出的假设，尚无证据确认。
5. 本次没有改显卡驱动、SMBIOS、ACPI、PCI/BAR 补丁、`gfxrst=4` 或其他启动参数。此前增加的 `NVRAM/Delete/.../boot-args` 配置项原样保留，没有直接执行 NVRAM 写入或重置，没有修改内置 SSD 分区和 Windows 引导。
6. 新测试使用 SanDisk Extreme Pro，序列号 `[DEVICE_ID_REDACTED]`，活动配置在 `/Volumes/MACBOOT/EFI/OC/config.plist`。当前 Windows 盘符 F:；不要将盘符当作固定设备身份。
7. 测试前 `cpus=1` 配置额外保存在 U 盘根目录 `config-cpus1-before-cpus12.plist`。若再次 Panic，可在 Windows 将该文件复制回 `EFI/OC/config.plist`；原 `EFI-STABLE-20261023` 备份也保留未动。
8. 若成功进入桌面，先读取 `sysctl hw.ncpu hw.physicalcpu hw.logicalcpu hw.activecpu kern.bootargs`，核对实际生效值，并读取本次 Panic 的原始报告；请先保留当前 `cpus=12`，不要直接再次删除 CPU 限制或同时叠加其他改动。

Windows 端检查：修改后 plist 可解析，ocvalidate 1.0.9 检查通过（No issues found）；本次没有做额外文件哈希校验。能否启动、实际在线处理器数量与运行稳定性均需下一次实机验证。
