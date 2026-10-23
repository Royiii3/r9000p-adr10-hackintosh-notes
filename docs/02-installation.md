# 安装与进入桌面的准确流程

[返回首页](../README.md) · [故障排查](03-troubleshooting.md) · [辅助脚本](../scripts/README.md)

这篇把反复试错整理为可阅读的顺序。**目标是复现本次能进桌面的状态，不承诺复现多核日用稳定系统。** 对 ADR10 以外的机器，先重新确认硬件，不直接照搬 MMIO、PCI、ACPI 或核心数设置。

## 阶段 0：准备材料与记录

需要 Windows、一个可靠的外置 U 盘、网线、电源，以及内部 SSD 上独立给 macOS 的空间。2.4GHz USB 鼠标可以作为初期触控板不可用时的替代。

保留 Windows 的分区布局和启动方式记录。设备身份应结合型号、总容量、总线类型、分区结构判断；需要时在本地核对序列号。**盘符和磁盘编号都可能变化。** 经验稿没有保留作者自己的磁盘序列号和卷 UUID。

这次使用外置 OpenCore，通过固件一次性启动菜单进入；没有把 OpenCore 安装到内部 Windows ESP。这样失效时还能直接从 Windows 回来修外置配置。

## 阶段 1：准备文件，不先抹系统

1. 从 [OpenCore](https://github.com/acidanthera/OpenCorePkg) 或本次使用的 [匹配构建](https://github.com/dortania/build-repo/releases/tag/OpenCorePkg-d9ef47a) 取得启动文件。
2. 从 [AMD Vanilla](https://github.com/AMD-OSX/AMD_Vanilla) 准备对应内核的 AMD 补丁。本机物理核心数为 **16 / `0x10`**。
3. 根据机器准备基础 kext 与 ACPI。此处只记录本机曾使用的列表，见[配置篇](00-hardware-and-config.md)，不提供冒充通用兼容的完整 EFI。
4. 通过 OpenCore `Utilities/macrecovery` 或 1401 的恢复下载流程，从 Apple 获取目标恢复文件。具体下载命令的 board-id / 型号参数应按当前上游文档选择，不猜测一个型号保证下载到 26。
5. 本次 Tahoe 恢复镜像记录来自 `oscdn.apple.com`，产品标识 `140-93589`，`BaseSystem.dmg` 为 **960530321 字节**，对应 chunklist 为 **3604 字节**。这是当时的文件，不是所有 26 恢复镜像的固定大小。
6. 从 [v2.3.4 发布页](https://github.com/nullmoth/nvidia-macos-driver/releases/tag/v2.3.4) 准备 `nullmoth-nvidia-2.3.4.tar.gz`。该包不放进 `EFI/OC/Kexts`。

不要为解决 `DMG has been altered` 而把 `DmgLoading` 改成允许未签名镜像。先区分文件没下完整、chunklist 不配套和介质读取异常。本次最终确认的是旧 U 盘的读取链路异常。

## 阶段 2：U 盘布局

本次新盘采用 MBR，两分区：

```text
SanDisk 256GB
├── MACBOOT       2GiB FAT32，活动主分区
└── 普通数据分区   剩余空间 exFAT
```

这是对已明确允许清空的新 U 盘进行的分区，**不能将操作目标换成内部 SSD**。本文不提供自动 `clean` / 清盘命令，避免读者把示例磁盘号直接执行到自己的系统盘。

MACBOOT 的关键目录如下。完整辅助布局见 [scripts/README.md](../scripts/README.md)。

```text
MACBOOT/
├── EFI/
│   ├── BOOT/BOOTx64.efi
│   └── OC/
│       ├── OpenCore.efi
│       ├── config.plist
│       ├── ACPI/
│       ├── Kexts/
│       └── Drivers/
│           ├── apfs_aligned.efi
│           ├── HfsPlus.efi
│           └── OpenRuntime.efi
├── com.apple.recovery.boot/
│   ├── BaseSystem.dmg
│   └── BaseSystem.chunklist
├── prepare234.sh
├── setup-state.sh
├── create-account.sh
└── NullMoth/v2.3.4/
    ├── nullmoth-nvidia-2.3.4.tar.gz
    ├── install.no-nvram.sh
    ├── run234.sh
    └── setup-state.sh
```

恢复目录直接放在分区根目录；不要误放成 `EFI/com.apple.recovery.boot`，也不要让解压多嵌套一层。三个 OpenCore 核心文件要匹配，`OpenRuntime.efi` 的引用必须启用且文件真实存在。

运行与该 OpenCore 版本相配的 `ocvalidate`。它检查配置结构，不能证明 kext 与硬件兼容，也不能证明 U 盘读数据稳定。

## 阶段 3：使用恢复安装配置启动

本机恢复配置重点：

- `ScanPolicy=0`、`HideAuxiliary=false`、`DmgLoading=Signed`。
- `ResizeAppleGpuBars=0`、`ResizeGpuBars=-1`。
- **不要启用 IONDRVSupport 的 Exclude**；恢复环境依赖固件 framebuffer。
- 本次能进桌面的路线保留 `cpus=1` 和 `gfxrst=4`；这不是所有机器的默认要求。
- Zen 4 补丁与当前 Darwin 匹配，16 核物理核心补丁保留 `0x10`。
- 本机 MMIO 白名单等特殊参数依据本机日志，不照搬给其他机器。

插好新盘，从联想固件一次性启动菜单选该 U 盘的 UEFI 项。旧 U 盘先拔掉，避免启动来源不明确。

OpenCore 中按**名称**选 `MACBOOT (external) (dmg)`。数字不是固定的；插拔设备、安装进度变化或辅助入口显示状态都会改变序号。

如果菜单按键后屏幕不变，先区分“键盘无输入”和“已经收到选择、正在读镜像”。之前固定等几分钟的现象最终通过切换匹配 RELEASE 核心文件明显改善；不能因为存在 `debug=0x100` 就判断又变回了 DEBUG。

## 阶段 4：在内部独立空间安装 macOS

完整系统不装在 2GiB MACBOOT 中。

本次从 D 盘让出独立空间。若重装的是已有 macOS，只在磁盘工具中选择**自己的 Macintosh HD APFS 宗卷组**，理解“抹掉宗卷组”会删除它的系统和用户数据，再按需求操作。不要抹整个物理 SSD、Windows C/D、Windows ESP、MSR 或 Windows 恢复分区。

命名为 `Macintosh HD`、格式 APFS，便于本次历史辅助脚本识别对应 `Macintosh HD - Data`。如果使用其他名字，脚本需要传入自己的 Data 卷名。

退出磁盘工具，开始安装到 Macintosh HD。**这一阶段需要网络**，恢复安装器会下载完整系统。本机采用网线；MT7925 无线没有验证可用，iPhone C-to-C USB 共享也没有在恢复环境中验证，不作为本流程的已确认替代方案。

### 自动重启时选什么

1. 始终仍从外置 U 盘进入 OpenCore。
2. 安装过程有 `macOS Installer` 时，选择它继续。
3. 安装入口消失、进入已安装系统阶段后，选择 `Macintosh HD`。
4. 不要每次重启都选择 MACBOOT 重新发起安装。
5. 若固件自动进了 Windows，从一次性启动菜单重新选 U 盘；这本身不是安装失败。

不要用重启次数判断完成。安装器正常重启、内核 Panic、显示会话崩溃和用户手动重启是不同事件。看到 `launchd` 结束进程、卸载 APFS、关机日志，只能说明走了关机流程，不能单独判断成功或失败。

## 阶段 5：在已安装系统里安装 NVIDIA 驱动

**恢复环境中看得到画面，不代表显卡驱动已安装；驱动包放在 U 盘中，也不会自动成为系统驱动。**

本次在 macOS 初始化黑屏或卡住时，采用以下原理：

1. 从 MACBOOT 回恢复环境，打开终端。
2. 脚本定位**这次新安装的 Data 卷**，把驱动包、适配后的安装器和一次性 LaunchDaemon 放入该卷。
3. 在 U 盘配置中临时加入 `-nvoff`，让下一次已安装系统的启动先不初始化 NVIDIA 驱动。
4. 重启选择 Macintosh HD。任务在**已安装的 macOS**中执行，写驱动和重建 AuxKC，不是在 Recovery 里强行装驱动。
5. 安装器成功返回后，脚本启用已装驱动配置中的 IONDRVSupport Exclude，移除 `-nvoff`，然后自动重启一次。
6. 再从 U 盘选 Macintosh HD，并读取真实加载版本。

使用本仓库历史辅助脚本前，先按[辅助脚本说明](../scripts/README.md)准备完整文件。目录齐全后，恢复终端的入口是：

```sh
sh /Volumes/MACBOOT/prepare234.sh
```

看到 `READY_234` 再运行：

```sh
reboot
```

驱动安装由后台任务执行，不要中途断电。自动重启后再选 Macintosh HD。驱动包、版本记录、四个 kext 的加载、Metal API 能力和实际渲染，要分别验证。

本次安装器副本省略了四处直接删除固件变量的命令，以符合当时对固件 NVRAM 的操作限制。**这是本机定制的改动，不代表与上游完整回退机制行为相同。** 补丁和生成方法见脚本说明；不要把它伪装成上游原版安装器。

驱动已在本地 U 盘中时，这个安装阶段不需要再联网下载。它也不是 Windows NVIDIA 驱动或旧版 macOS Web Driver。

## 阶段 6：正常初始化卡住时的处理

国家选择继续后转圈、白屏或黑屏鼠标，先读取：

```sh
cat /Library/NullMoth/driver-version
kmutil showloaded --list-only | grep -i nullmoth
sysctl kern.bootargs hw.ncpu
```

这几条要在**已安装系统**的终端运行。通常期望看到四个 NVIDIA 模块。工具若报告权限不足，要保留原文，不把空输出直接当成“没有驱动”。

本次 `mostFrequent countries found: (null)`、`scannedCountryInfos: ()` 没有被证明是主因。`_mbsetupuser` 是初始化临时账户，终端提示切换 zsh 也不是安装任务，反复 `chsh` 无法修复显卡或初始化。

### 本次走通的绕过办法

先确认没有普通用户：

```sh
dscl . -list /Users UniqueID | awk '$2>=501 && $2<65534'
```

用户报告没有输出。随后回到**恢复环境**，运行本次账户脚本：

```sh
sh /Volumes/MACBOOT/create-account.sh
```

脚本对目标 Data 卷的 `/Local/Target` 离线目录节点创建普通管理员账户，直接让 `dscl` 提示设置密码；不把密码写成命令行参数或明文 U 盘文件。密码记录、管理员组和主目录成功创建后，才写入 `.AppleSetupDone` 和用户 `.skipbuddy`。

看到 `SETUP_SKIP_READY` 后再重启，选择 Macintosh HD，用刚创建的账户登录。这次用户确认能进入桌面，随后使用了 macOS 应用。

**不要只执行 `touch .AppleSetupDone` 就跳过向导。** 没有正常用户时，这不会替你创建可登录账户。新版 Recovery 对离线改密码的支持也可能不同，失败就保留错误，不用空密码或启用 root 自动登录绕过。本仓库的公开版脚本只做了用户名默认值的泛化，未在清空后的机器上重新执行验证。

## 阶段 7：桌面出现后才开始验收

按顺序检查：

1. 实际在线 CPU、启动参数、驱动实际加载版本。
2. 显示、输入、有线网络是否稳定。
3. Metal 小测试是否真实完成和回读正确，而不只看“关于本机”。
4. 逐个外设、接口、睡眠、电源、冷/热启动。
5. 再考虑移除 `cpus=1`。本机在这一步 Panic，没有完成多核验收。

“命令执行完”“脚本显示安装成功”“能显示 Metal 3”“能进桌面”“可日用”是不同的里程碑。
