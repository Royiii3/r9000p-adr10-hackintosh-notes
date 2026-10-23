#!/bin/sh
# Read-only diagnostics of the running installed OS. Output stays on the USB.
umask 077
PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH
base=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 1
case "$base" in /Volumes/*|/Library/CodexDriverUpdate234) ;; *) exit 1;; esac
out="$base/setup-state-$(date +%Y%m%d-%H%M%S)-$$"
mkdir "$out" || exit 1
diskutil info -plist /System/Volumes/Data > "$out/running-data.plist" 2>/dev/null || { echo 'STOP: collect from Macintosh HD, not Recovery.'; exit 1; }
printf 'Saving setup/graphics evidence to %s\n' "$out"
{
 date -u
 id
 sw_vers
 sysctl kern.bootargs hw.ncpu hw.physicalcpu hw.logicalcpu
 csrutil status
 cat /Library/NullMoth/driver-version
} > "$out/environment.txt" 2>&1
kextstat > "$out/loaded-kexts.txt" 2>&1
ioreg -r -c IOFramebuffer -l -w0 > "$out/framebuffer.txt" 2>&1
ioreg -r -c IOAccelerator -l -w0 > "$out/accelerator.txt" 2>&1
system_profiler SPDisplaysDataType -detailLevel mini -timeout 15 > "$out/displays.txt" 2>&1
ps -axo pid,ppid,uid,etime,state,pcpu,comm > "$out/processes.txt" 2>&1
top -l 1 -n 15 -o cpu > "$out/cpu.txt" 2>&1
dmesg > "$out/kernel.txt" 2>&1
for name in 'Setup Assistant' SetupAssistant 'Language Chooser' LanguageChooser WindowServer; do
 pid=$(pgrep -x "$name" 2>/dev/null | head -1)
 [ -n "$pid" ] || continue
 sample "$pid" 3 -file "$out/sample-$pid.txt" > "$out/sample-$pid-status.txt" 2>&1
done
log show --last 2m --style compact --predicate 'process == "WindowServer" OR process == "Setup Assistant" OR process == "SetupAssistant" OR process == "LanguageChooser" OR process == "Language Chooser" OR eventMessage CONTAINS[c] "NVAccel" OR eventMessage CONTAINS[c] "nvmtl"' 2>&1 | head -c 2097152 > "$out/setup-session.txt"
for f in /tmp/*nvmtl*.log /tmp/*nullmoth*.log /tmp/*nvrm*.log /var/root/Library/Preferences/com.apple.SetupAssistant.plist; do
 [ -f "$f" ] || continue
 tail -c 1048576 "$f" > "$out/$(basename "$f").txt" 2>&1
done
printf 'SETUP_STATE_DONE\nRead-only collection; no preferences, accounts, drivers, EFI, NVRAM or partitions changed.\n' > "$out/RESULT.txt"
sync
printf 'SETUP_STATE_DONE: %s\n' "$out"
