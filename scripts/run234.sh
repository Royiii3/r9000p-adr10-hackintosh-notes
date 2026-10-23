#!/bin/sh
# Native installation first; record loaded versions after the automatic restart.
set -eu
PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH
stage=/Library/CodexDriverUpdate234
job=/Library/LaunchDaemons/local.codex.driver-update234.plist
pb=/usr/libexec/PlistBuddy
usb=
exec >> "$stage/update.log" 2>&1
mount_usb() {
 diskutil mount "$(cat "$stage/usb-uuid.txt")" || true
 diskutil info -plist "$(cat "$stage/usb-uuid.txt")" > "$stage/usb-running.plist" 2>/dev/null || true
 usb=$("$pb" -c 'Print :MountPoint' "$stage/usb-running.plist" 2>/dev/null || true)
}
mirror() {
 if [ -n "$usb" ]; then
  cp "$stage/STATUS.txt" "$usb/DRIVER-234-STATUS.txt" || true
  cp "$stage/update.log" "$usb/DRIVER-234-LOG.txt" || true
  for out in "$stage"/setup-state-*; do
   [ -d "$out" ] || continue
   ditto "$out" "$usb/$(basename "$out")" || true
  done
 fi
 sync
}
trap 'code=$?; if [ "$code" -ne 0 ]; then printf "FAILED: exit %s; inspect the saved update.log.\n" "$code" > "$stage/STATUS.txt"; rm -f "$job"; mirror; fi' EXIT
date -u
sw_vers
sysctl kern.bootargs hw.ncpu
phase=$(cat "$stage/phase")
if [ "$phase" = collect ]; then
 kextstat > "$stage/loaded-after-restart.txt" 2>&1
 {
  printf 'DRIVER_234_INSTALL_FINISHED\nRecorded installed version: %s\n' "$(cat /Library/NullMoth/driver-version)"
  grep 'com.nullmoth' "$stage/loaded-after-restart.txt" || true
 } > "$stage/STATUS.txt"
 rm -f "$job"
 mount_usb
 mirror
 exit 0
fi
if [ "$phase" != install ]; then
 printf 'Previous installation was interrupted; inspect update.log before retrying.\n'
 exit 1
fi
printf 'INSTALLING: NVIDIA 2.3.4. Do not interrupt.\n' > "$stage/STATUS.txt"
printf 'installing\n' > "$stage/phase"
# Start local logging and installation even if the USB is not yet mounted.
tar -xzf "$stage/package.tar.gz" -C "$stage"
cp "$stage/install.no-nvram.sh" "$stage/pkgroot/install.no-nvram.sh"
caffeinate -dims /bin/bash "$stage/pkgroot/install.no-nvram.sh" --payload "$stage/pkgroot"
cat /Library/NullMoth/driver-version
mount_usb
config="$usb/EFI/OC/config.plist"
# The installer uses the firmware framebuffer; the installed NVIDIA driver needs this exclusion.
"$pb" -c "Set :Kernel:Block:0:Enabled true" "$config"
key=':NVRAM:Add:7C436110-AB2A-4BBB-A880-FE41995C9F82:boot-args'
args=$("$pb" -c "Print $key" "$config")
args=$(printf '%s' "$args" | sed -E 's/(^| )-nvoff( |$)/ /g;s/  +/ /g;s/^ //;s/ $//')
"$pb" -c "Set $key $args" "$config"
printf 'collect\n' > "$stage/phase"
printf 'DRIVER_234_INSTALLED: restarting once, then recording loaded driver versions.\n' > "$stage/STATUS.txt"
mirror
/sbin/shutdown -r now
