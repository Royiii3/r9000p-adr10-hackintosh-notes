# 关键里程碑与脱敏摘录

## 1. 匹配 RELEASE 后的用户反馈

记录日期：2026-10-19。用户反馈为 OpenCore 明显变快，选择入口后立即开始启动。它支持“这次切换对本机有效”，不支持“所有 DEBUG 必然等 300 秒”。

## 2. 旧 U 盘读取对照

记录日期：2026-10-21，抽样位置各读取两次，每次 1MiB，绕过 Windows 文件缓存：

```text
Old USB, original port: 28 sample positions, 22 returned different bytes.
Old USB, another direct port: 28 positions, 14 returned different bytes.
Internal SSD control image: 28 positions, stable.
New SanDisk Recovery DMG: 28 positions, stable and matching local source.
New SanDisk driver package: 8 positions, stable and matching local source.
```

这是抽样，不是对整个设备做过完整认证；未通过它定位具体故障硬件。

## 3. 重新安装后的 NVIDIA 2.3.4 安装日志

记录日期：2026-10-23。省略了具体备份目录和其他机器身份：

```text
ProductVersion: 26.7.1
BuildVersion: 25G241
hw.ncpu: 1
boot-args include: cpus=1 gfxrst=4 -nvoff

== 3. test kernel collection
   ok  test collection holds all four kexts
== 4. back up what is there now
   ok  backup written
== 5. install
   ok  installed
...
2.3.4
DRIVER_234_INSTALLED: restarting once, then recording loaded driver versions.
```

这份摘录证明这次安装器实际执行，不独自证明下一次所有 kext 已加载。后续 macOS 端审计报告另记录四个 2.3.4 kext 的加载和 GPU 测试。

## 4. 创建账户与跳过初始化

脚本执行后 U 盘留下：

```text
SETUP_SKIP_READY
Account: <LOCAL_USER>
UID: 501
Data: /Volumes/Macintosh HD - Data
Backup: <LOCAL_BACKUP_PATH>
```

用户随后确认进入桌面，并在 macOS 中安装应用、运行审计。能进入桌面的用户反馈和这个文件一起构成结果；不能单靠状态文件证明账户登录真的成功。

## 5. CPU 变化

```text
Desktop baseline: boot-args contain cpus=1 gfxrst=4.
macOS-side test: remove cpus=1; add boot-args to the configured NVRAM/Delete list.
Next boot: user supplied Kernel Panic photo.
Windows rollback: restore cpus=1.
Next requested test: change only cpus=1 to cpus=12.
Physical core patch: retained 0x10 (16 physical cores).
cpus=12 boot result: not recorded.
```

## 6. 停止后的只读观察

2026-10-24，用户明确说明 macOS 已删除、空间还给 D 盘。Windows 侧只读分区枚举也显示：内部 SSD 只剩 EFI/MSR/C/D 四个分区，D 盘比此前扩大，旧 APFS 物理分区已不在。该观察只用于确认记录终点，没有执行新的磁盘操作。
