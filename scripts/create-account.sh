#!/bin/bash
# Run in MACBOOT Recovery Terminal. Modify only the selected installed macOS Data volume.
set -e
umask 077
PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH
base=$(CDPATH= cd "$(dirname "$0")" && pwd)
pb=/usr/libexec/PlistBuddy

if [ "$(id -u)" != 0 ]; then
    echo 'Run this script in MACBOOT Recovery > Utilities > Terminal, not the Setup Assistant terminal.'
    exit 1
fi

target=${1:-"Macintosh HD - Data"}
diskutil mount "$target"
info=$(mktemp /tmp/codex-account.XXXXXX)
diskutil info -plist "$target" > "$info"
data=$("$pb" -c 'Print :MountPoint' "$info")
rm -f "$info"
db="$data/private/var/db/dslocal/nodes/Default"
if [ ! -d "$db/users" ] || [ ! -f "$db/groups/admin.plist" ]; then
    echo 'Installed macOS account database not found. No account or setup marker changed.'
    exit 1
fi

ds() { /usr/bin/dscl -f "$db" localonly "$@"; }
users=$(ds -list /Local/Target/Users UniqueID)
regular=$(printf '%s\n' "$users" | awk '$2>=501 && $2<65534')
if [ -n "$regular" ]; then
    printf 'A normal account already exists; this script will not replace it:\n%s\n' "$regular"
    exit 1
fi

printf 'Installed macOS Data volume: %s\n' "$data"
printf 'New account short name [macuser]: '
read -r name
name=${name:-macuser}
case "$name" in
    *[!a-z0-9_-]*|-*|_*|[0-9]*) echo 'Use a short name starting with a lower-case letter, containing a-z, 0-9, underscore or hyphen.'; exit 1 ;;
esac
if printf '%s\n' "$users" | awk '{print $1}' | grep -Fxq "$name"; then
    echo 'That account name already exists. No account changed.'
    exit 1
fi
if [ -e "$data/Users/$name" ]; then
    echo 'That home folder already exists. It will not be replaced.'
    exit 1
fi

backup="$data/Library/CodexSetupSkip/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
cp -p "$db/groups/admin.plist" "$backup/admin.plist"
printf 'Data: %s\nAccount: %s\nUID: 501\n' "$data" "$name" > "$backup/change.txt"
record="/Local/Target/Users/$name"
guid=$(uuidgen)
ds -create "$record"
ds -create "$record" UniqueID 501
ds -create "$record" PrimaryGroupID 20
ds -create "$record" GeneratedUID "$guid"
ds -create "$record" RealName "$name"
ds -create "$record" UserShell /bin/zsh
ds -create "$record" NFSHomeDirectory "/Users/$name"

printf '\nSet the login password for %s. Input is hidden.\n' "$name"
# Let Apple's tool prompt directly. No password argument, shell variable, transcript or password file.
if ! ds -passwd "$record"; then
    ds -delete "$record"
    echo 'PASSWORD_FAILED: Recovery could not set the password. Setup Assistant has NOT been skipped.'
    exit 1
fi
if ! "$pb" -c 'Print :ShadowHashData:0' "$db/users/$name.plist" >/dev/null 2>&1; then
    ds -delete "$record"
    echo 'PASSWORD_FAILED: No local password record was written. Setup Assistant has NOT been skipped.'
    exit 1
fi

ds -append /Local/Target/Groups/admin GroupMembership "$name"
ds -append /Local/Target/Groups/admin GroupMembers "$guid"
home="$data/Users/$name"
mkdir -p "$home/Desktop" "$home/Documents" "$home/Downloads" "$home/Library" "$home/Movies" "$home/Music" "$home/Pictures" "$home/Public"
touch "$home/.skipbuddy"
chown -R 501:20 "$home"
chmod 700 "$home"

# Mark setup complete only after the account, password record, admin membership and home exist.
touch "$data/private/var/db/.AppleSetupDone"
chown 0:0 "$data/private/var/db/.AppleSetupDone"
chmod 644 "$data/private/var/db/.AppleSetupDone"
printf 'SETUP_SKIP_READY\nAccount: %s\nUID: 501\nData: %s\nBackup: %s\n' "$name" "$data" "$backup" > "$base/SETUP-SKIP-STATUS.txt"
sync
printf '\nSETUP_SKIP_READY\nAccount: %s\nRestart, choose Macintosh HD, and log in with the password you just set.\n' "$name"
