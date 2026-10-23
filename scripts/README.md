# 本次辅助脚本：用途与准确用法

[返回首页](../README.md) · [完整安装流程](../docs/02-installation.md)

这些脚本保存本次实际采用的处理方式，供阅读和复现对应阶段。**不是完整 EFI，也不是通用一键安装器。** 不会因为放在仓库或 U 盘里就自动执行。

| 文件 | 运行位置 | 作用 |
|---|---|---|
| `patch-installer-234.py` | 有 Python 3 的 Windows / 其他准备环境 | 从 2.3.4 原安装器生成省略四处直接 NVRAM 删除的副本 |
| `prepare234.sh` | MACBOOT 恢复终端，root | 向所选已安装 macOS Data 卷暂存驱动安装任务，并在外置配置临时加 `-nvoff` |
| `run234.sh` | 已安装 macOS 的一次性 root LaunchDaemon | 本地安装、成功后切回驱动配置、重启，下一次启动记录版本并删除自己的任务 |
| `setup-state.sh` | 已安装 macOS 的终端 | 读取版本、设备、进程和图形日志，写入脚本所在目录的采集文件夹；权限不足的采集可能不完整 |
| `create-account.sh` | MACBOOT 恢复终端，root | 在无普通用户时为所选 Data 卷创建管理员、设密码，成功后尝试跳过初始化 |

公开脚本主要保留历史实现。账户脚本把原作者的用户名默认值改成了 `macuser`；原机成功执行的是原始版本，公开版只做语法检查，没有重新清空系统跑完整安装。

## A. 准备 2.3.4 的原始安装器副本

从 [官方 v2.3.4 发布页](https://github.com/nullmoth/nvidia-macos-driver/releases/tag/v2.3.4) 获取：

```text
nullmoth-nvidia-2.3.4.tar.gz
```

在准备目录解压，取得 `pkgroot/install.sh`。例如 Windows PowerShell 的当前目录中已经有该包、且已有可用 Python 3 时：

```powershell
tar -xzf .\nullmoth-nvidia-2.3.4.tar.gz
python .\scripts\patch-installer-234.py .\pkgroot\install.sh
```

它在原安装器旁生成 `install.no-nvram.sh`，只省略本次历史记录中的四条 `nvram -d`。不改驱动二进制，不追加文件哈希检查，不移除官方安装器原有检查。

这项改动也会影响安装器原有固件标志与回退机制，**不能说它与上游安装方式完全等价**。其他版本不应套用此补丁，脚本在匹配不到四条原命令时停止。本机后期验证的是 2.3.4，不是带着这个补丁运行了所有后续版本。

恢复环境未必有 Python，因此这一步在准备电脑上完成，不要重演 `shasum` / Python 在 Recovery 不存在的情况。

## B. 复制到 MACBOOT 的完整布局

将本目录脚本复制到下面的位置，包和安装器副本另行准备：

```text
/Volumes/MACBOOT/
├── EFI/OC/config.plist                  自己匹配硬件的配置
├── com.apple.recovery.boot/             自己从 Apple 获取的恢复文件
├── prepare234.sh                        来自本仓库 scripts/
├── setup-state.sh                       来自本仓库 scripts/
├── create-account.sh                    来自本仓库 scripts/
└── NullMoth/v2.3.4/
    ├── nullmoth-nvidia-2.3.4.tar.gz      官方原包
    ├── install.no-nvram.sh              上一步生成的副本
    ├── run234.sh                        来自本仓库 scripts/
    └── setup-state.sh                   来自本仓库 scripts/
```

不能只复制 `prepare234.sh` 就期待它下载或补齐所有文件。

### 这套历史驱动脚本的限定

1. 目标卷默认名为 `Macintosh HD - Data`，应先确认这是自己的新装 macOS Data 卷。改过名字可以把实际卷名作为第一个参数传入。
2. U 盘卷名按历史流程为 `MACBOOT`，实际目录以 `ls /Volumes` 为准。脚本不绑定作者的旧 UUID。
3. 活动 EFI 中 `Kernel/Block[0]` 在本机就是 `com.apple.iokit.IONDRVSupport`。历史 `run234.sh` 使用该索引切换 Exclude；**其他 EFI 必须先核对这一点，不能让它误改另一条屏蔽规则**。
4. 当前 Booter/BAR/AMD 配置需要已经能启动该机器；脚本不会替你生成或修复它们。
5. 执行安装后将自动重启一次，并在下一次原生系统启动时尝试写回 U 盘状态。不包含开机后自动重度进程采样。
6. 脚本只退役本次旧的 `local.codex.driver-update243` 待执行任务，不会批量清除其他 LaunchDaemon。

## C. 原生安装阶段

从 MACBOOT 恢复环境终端运行：

```sh
sh /Volumes/MACBOOT/prepare234.sh
```

若目标 Data 卷叫另一个名称，例如 `Test macOS - Data`：

```sh
sh /Volumes/MACBOOT/prepare234.sh "Test macOS - Data"
```

出现 `READY_234` 后 `reboot`，下一次选 Macintosh HD，安装任务在原生系统执行。它自动重启后，再选 Macintosh HD。

U 盘上的 `DRIVER-234-STATUS.txt` 和 `DRIVER-234-LOG.txt` 区分“已暂存”“安装中”“安装完成待重启”和“已记录重启后的加载版本”。回到恢复环境还可运行 `prepare234.sh status` 读取默认 Data 卷上的任务记录。

**出现失败应读本次日志，不要反复运行安装或根据旧状态文件猜当前结果。** 已删掉 macOS 后，这些任务目录和卷标也不再有执行目标。

## D. 初始化仍卡住，但系统已装好

如果能打开已安装 macOS 的终端，可先手动收集：

```sh
sh /Volumes/MACBOOT/setup-state.sh
```

输出目录包含本机进程、硬件和可能的设备身份。不要把原始目录不经检查直接公开上传。该脚本不跳过初始化、不创建账户、不装驱动。

账户脚本只用于“还没有普通用户、需要尝试绕过初始化”的情形。在恢复终端运行：

```sh
sh /Volumes/MACBOOT/create-account.sh
```

按提示输入账户名（公开版默认 `macuser`）和密码。密码由系统工具隐藏读取，脚本不将明文密码记录到 U 盘。只有出现 `SETUP_SKIP_READY` 才表示这次流程到了写完成标记的阶段；随后重启、实际输入密码登录才算账户验收成功。

若出现 `PASSWORD_FAILED`，脚本会停止且不会新建完成标记。不要手工补上 `.AppleSetupDone` 来把错误隐藏掉。

离线创建用户不等于完成 FileVault/Secure Token 配置；这次没有启用或验证 FileVault。它也不会修复显卡、多核、音频和无线。
