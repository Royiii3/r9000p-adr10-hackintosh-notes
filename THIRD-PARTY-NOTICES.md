# 第三方组件与来源

[返回首页](README.md) · [完整版本与获取清单](artifacts/efi-desktop-manifest.json) · [许可文本索引](third-party-notices/index.json)

这是一份个人安装经历和排障档案。原作者的软件、驱动、补丁和生成器各自保留版权与许可；本仓库不把它们统一改成自己的许可证，也不代表 NullMoth、Acidanthera 或其他项目。

## 公开范围

公开经验正文、脱敏配置、配置差异、精选日志、文件清单和上游获取链接。**完整历史 EFI ZIP 保留本地，不作为公开下载附件。** 已补齐能确认的来源和许可正文；少数组件只找到了原始载荷，没有找到可适用的明确再分发条款。没有许可证文件不直接等于禁止分享，但也不能由本仓库补写成“已获授权”。

核对日期为 2026-10-24。版本来自保存的 EFI；下载 URL 来自实际使用的 1401 引擎 mirror.json、生成器源码和历史更换记录。版本、下载记录与源码链接分别列出，不把它们当作本次重新构建二进制的证明。

## OpenCore、文件系统驱动与资源

| 项目 | 本机记录与来源 | 许可与归档处理 |
|---|---|---|
| BOOTx64、OpenCore、OpenRuntime | 三个文件一起切换为 [1.0.9 RELEASE 构建](https://github.com/dortania/build-repo/releases/tag/OpenCorePkg-d9ef47a)，[源码提交 d9ef47a](https://github.com/acidanthera/OpenCorePkg/tree/d9ef47a2a7bd69a026a92b0eb040b9be71810620) | 已收录该提交的 BSD 顶层许可；项目内各子组件仍遵循自身说明。 |
| OpenShell、ResetNvramEntry | [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg) 工具 | 已确定项目归属，本次没有另行证明工具二进制与上述提交完全相同。 |
| HfsPlus.efi、apfs_aligned.efi、字体与图标 | 引擎实际取得 [OcBinaryData master ZIP](https://github.com/acidanthera/OcBinaryData/archive/refs/heads/master.zip) | 核对了仓库目录，未确认覆盖这些独立载荷的统一再分发许可；不能套用 OpenCorePkg 的 BSD 许可。此仓库提供来源，不附这些文件。 |

## 内核扩展

| 组件与观察版本 | 源码、版本或实际获取入口 | 已确认说明 |
|---|---|---|
| Lilu 1.7.3 | [源码 0515f40](https://github.com/acidanthera/Lilu/tree/0515f40) | BSD-3-Clause 文本已收录。 |
| WhateverGreen 1.7.2 | [源码 093e76f](https://github.com/acidanthera/WhateverGreen/tree/093e76f) | BSD-3-Clause 文本已收录。 |
| VirtualSMC、SMCBatteryManager、SMCLightSensor 1.3.9 | [源码 b5c62c2](https://github.com/acidanthera/VirtualSMC/tree/b5c62c2) | BSD-3-Clause 文本已收录。 |
| RestrictEvents 1.1.7 | [源码 9265e78](https://github.com/acidanthera/RestrictEvents/tree/9265e78) | BSD-3-Clause 文本已收录。 |
| BrightnessKeys 1.0.4 | [源码 37bdf47](https://github.com/acidanthera/BrightnessKeys/tree/37bdf47) | BSD-3-Clause 文本已收录。 |
| NVMeFix 1.1.4 | [源码 4862220](https://github.com/acidanthera/NVMeFix/tree/4862220) | 上游完整声明含 BSD、Linux GPL-2.0 及例外说明，不能只保留 BSD 部分。 |
| VoodooPS2Controller 2.3.8 | [源码 7eab4a3](https://github.com/acidanthera/VoodooPS2/tree/7eab4a344d901d1e4aa6ece4189ecde5a7356287) | 该提交 APSL-2.0 正文已收录；内含 VoodooInput 另有 GPL-2.0，不能只看父项目。 |
| VoodooI2C 2.9.1、VoodooI2CHID 1 | [源码 5c0c99c](https://github.com/VoodooI2C/VoodooI2C/tree/5c0c99c) | 收录原样 GPL-3.0 文本。原文件首行本身为 AL PUBLIC LICENSE，raw 来源确认如此，未擅自修补；不是本次抓取截断。内含 VoodooInput 也有独立声明。 |
| YogaSMC 1.5.3 | [1.5.3 发布入口](https://github.com/zhen-zen/YogaSMC/releases/tag/1.5.3) | GPL-2.0 文本已收录。 |
| RTL812xLucy 1.1.100 | [v1.1.1 发布入口](https://github.com/Mieze/RTL812xLucy/releases/tag/v1.1.1)、[该版本源文件头](https://github.com/Mieze/RTL812xLucy/blob/v1.1.1/RTL812xLucy/RTL812xLucy.cpp) | README 写 GPLv2，源文件头明确 GPL-2.0-or-later。保存版本号与发布标签写法不同。 |
| USBToolBox 1.2.0、UTBDefault 1.0 | [1.2.0 发布入口](https://github.com/USBToolBox/kext/releases/tag/1.2.0)、[该版本源文件头](https://github.com/USBToolBox/kext/blob/1.2.0/USBToolBox/USBToolBox.cpp) | 已查树、README 与主要源文件头；源文件写 Dhinak G 版权所有，未找到明确覆盖本载荷的再分发条款。不套用独立 USBToolBox/tool 仓库的 MIT 许可。 |
| AMFIPass 1.4.1 | [OCLP 保存的原始载荷](https://github.com/dortania/OpenCore-Legacy-Patcher/blob/main/payloads/Kexts/Acidanthera/AMFIPass-v1.4.1-RELEASE.zip) | 实际读取该 ZIP，仅有 kext，未附源码、许可或说明；OCLP 自身许可不能自动覆盖它。未虚构独立源码仓库。 |
| AppleMCEReporterDisabler 1.2 | [原始 Issue 附件](https://github.com/acidanthera/bugtracker/files/3703498/AppleMCEReporterDisabler.kext.zip) | 本地是无可执行文件的注入器，Info.plist 注明 XLNC 2019、All rights reserved；未找到额外分发授权。 |

精确下载 URL 保存在 [JSON 清单](artifacts/efi-desktop-manifest.json)。GPL/APSL 组件的源码链接和许可文本只是来源记录，不声称已经为这个二进制组合完成对应源码与构建材料的交付。因此公开配置和获取清单，不另行提供整包二进制。

## AMD 补丁和 ACPI 的实际来源链

引擎实际读取 [laobamac/AMD_Vanilla 的 patches.plist](https://github.com/laobamac/AMD_Vanilla/blob/master/patches.plist)，原始项目是 [AMD-OSX/AMD_Vanilla](https://github.com/AMD-OSX/AMD_Vanilla)。不能只写原始项目而隐去实际 fork。README 和补丁内容已核对；致谢包括 AlGrey、XLNC、CaseySJ、Shaneee 等。未确认明确的仓库级许可，故保留补丁作者注释、链接和历史配置用途，不把这些规则重新授权。

5 份 SSDT 来自生成器流程。1401 固定的 [OpCore-Simplify e5d8a9f5](https://github.com/lzhoang2801/OpCore-Simplify/tree/e5d8a9f551b1e2a96e2f968696b460b65a7dad2e) 中，acpi_guru.py 声明改编自 [SSDTTime 44aadf01](https://github.com/corpnewt/SSDTTime/blob/44aadf01b7fe75cb4a3eab5590e7b6c458265c6f/SSDTTime.py)。前者 BSD-3-Clause、后者 MIT 文本均已收录。PLUG-ALT 模板另引用 [OpenCore ACPI 示例](https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/AcpiSamples/Source/SSDT-PLUG-ALT.dsl)，XOSI 模板引用 [Dortania 示例](https://github.com/dortania/Getting-Started-With-ACPI/blob/master/extra-files/decompiled/SSDT-XOSI.dsl)。这是模板来源链，不代表本次反编译并重建了全部历史 AML。

## NullMoth 与 Apple

[1401 的许可](third-party-notices/nullmoth--1401--main--LICENSE.txt)为 PolyForm Noncommercial 1.0.0；[原项目 NOTICE](third-party-notices/nullmoth--1401--NOTICE_md.txt) 明确独立依赖保留各自条款，品牌、名称与图案没有一并授权。本仓库引用名称用于说明经历，不使用其身份发布软件，也不附生成器、NVIDIA 安装包或商标资源。

macOS 恢复镜像、完整安装器、NVIDIA/GSP 固件、账户数据库和个人身份信息均不在公开附件中。

许可文本按 [索引](third-party-notices/index.json) 保留原始 URL、获取日期和所用 ref；既有 9 份文本已改为 raw 官方来源的原样副本，没有新计算哈希。
