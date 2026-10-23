#!/bin/sh
# Run from Recovery after macOS installation. Stage NVIDIA 2.3.4 for the installed system.
set -eu
PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH
base=$(CDPATH= cd "$(dirname "$0")" && pwd)
pb=/usr/libexec/PlistBuddy
target=${1:-"Macintosh HD - Data"}
[ "$target" != status ] || target="Macintosh HD - Data"
diskutil mount "$target"
diskutil info -plist "$target" > /tmp/codex234-data.plist
data=$("$pb" -c 'Print :MountPoint' /tmp/codex234-data.plist)
stage="$data/Library/CodexDriverUpdate234"
if [ "${1:-}" = status ]; then
 cat "$stage/STATUS.txt"
 tail -80 "$stage/update.log"
 cp "$stage/STATUS.txt" "$base/DRIVER-234-STATUS.txt"
 cp "$stage/update.log" "$base/DRIVER-234-LOG.txt"
 for out in "$stage"/setup-state-*; do
  [ -d "$out" ] || continue
  ditto "$out" "$base/$(basename "$out")"
 done
 exit 0
fi
mkdir -p "$stage" "$data/Library/LaunchDaemons"
# Retire only our older pending update job. Preserve its package and logs.
rm -f "$data/Library/LaunchDaemons/local.codex.driver-update243.plist"
cp "$base/NullMoth/v2.3.4/nullmoth-nvidia-2.3.4.tar.gz" "$stage/package.tar.gz"
cp "$base/NullMoth/v2.3.4/install.no-nvram.sh" "$stage/install.no-nvram.sh"
cp "$base/NullMoth/v2.3.4/run234.sh" "$stage/run234.sh"
cp "$base/NullMoth/v2.3.4/setup-state.sh" "$stage/setup-state.sh"
diskutil info -plist "$base" > "$stage/usb.plist"
"$pb" -c 'Print :VolumeUUID' "$stage/usb.plist" > "$stage/usb-uuid.txt"
config="$base/EFI/OC/config.plist"
key=':NVRAM:Add:7C436110-AB2A-4BBB-A880-FE41995C9F82:boot-args'
args=$("$pb" -c "Print $key" "$config")
args=$(printf '%s' "$args" | sed -E 's/(^| )-nvoff( |$)/ /g;s/  +/ /g;s/^ //;s/ $//')
cp "$config" "$stage/config-before-update.plist"
"$pb" -c "Set $key $args -nvoff" "$config"
printf 'install\n' > "$stage/phase"
printf 'PREPARED: next Macintosh HD boot installs 2.3.4.\n' > "$stage/STATUS.txt"
cat > "$stage/job.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>local.codex.driver-update234</string>
<key>ProgramArguments</key><array><string>/bin/sh</string><string>/Library/CodexDriverUpdate234/run234.sh</string></array>
<key>RunAtLoad</key><true/><key>KeepAlive</key><false/>
<key>StandardOutPath</key><string>/Library/CodexDriverUpdate234/launchd.log</string>
<key>StandardErrorPath</key><string>/Library/CodexDriverUpdate234/launchd.log</string>
</dict></plist>
PLIST
chown -R root:wheel "$stage"
chmod 700 "$stage" "$stage/run234.sh" "$stage/setup-state.sh"
cp "$stage/job.plist" "$data/Library/LaunchDaemons/local.codex.driver-update234.plist"
chown root:wheel "$data/Library/LaunchDaemons/local.codex.driver-update234.plist"
chmod 644 "$data/Library/LaunchDaemons/local.codex.driver-update234.plist"
cp "$stage/STATUS.txt" "$base/DRIVER-234-STATUS.txt"
sync
printf '\nREADY_234\nRestart and choose Macintosh HD. Keep the USB connected.\nThe installed OS will install the driver, restart once, then save the loaded driver versions automatically.\n'
