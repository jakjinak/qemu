#!/usr/bin/env bash

# (C) 2019 Radek Slaby, jakjinak (https://github.com/jakjinak)
# This work is licensed under the terms of the MIT license, see LICENSE.MIT.

[[ "$1" && -d "$1" ]] || { echo "Specify a folder with a virtual machine as the first parameter." >&2 ; exit 1 ; }
cd "$1" || { echo "Cannot switch to '$1'." >&2 ; exit 1 ; }

DRY=0

CFG=run-qemu.config
[ -r $CFG ] || { echo "There is no '$CFG' in '$1'." ; exit 1 ; }
. "$CFG"
shift

help() {
  cat << ENDOFBLOCK
Usage: 
run-qemu.sh dir parameters...

parameters:
-h
--help ... prints this help
--dry ... only process config and params, print the command, but do not execute it

run-qemu.config definitions:
SYSTEM - mandatory, qemu-system-...
MACHINE - optional, -M
CPU - optional, -cpu
MEMORY - mandatory, -m
KERNEL - optional, -kernel
DTB - optional, -dtb
HDA - optional, -hda
CDROM - optional, -cdrom
BOOT - optional, -boot
NET - mandatory, -net 
NETNIC - mandatory, -net nic
NETMAC - mandatory, part of -net nic
APPEND - optional, -append
These can also be passed as parameter (var=val) to override config.
ENDOFBLOCK
}

CNT=0
while [ $# -gt 0 ]
do
  case "$1" in
    -h|--help) help ; exit 0 ;;
    --dry) DRY=1 ;;
    *=*) eval "$1" ;;
    *) echo "Ignoring '$1'." ;;
  esac
  shift
done

[ "$SYSTEM" ] || { echo "Provide system type; eg. x86_64, i386, arm, ..." ; exit 1 ; }
[ "$MEMORY" ] || { echo "Provide system memory (in MB)." ; exit 1; }
[ "$NET" ] || { echo "Provide network type; eg. user or tap." ; exit ; }
[ "$NETMAC" ] || { echo "Provide network's MAC address; 0-255." ; exit ; }
case "$NETMAC" in
  *:*) ;;
  *) NETMAC=`printf '52:54:00:%02i:34:56' "$NETMAC"` ;;
esac

declare -a CMD
pi=0
addp() {
  while [ $# -gt 0 ] ; do
    CMD[$i]="$1"
    ((i++))
    shift
  done
}
addp "qemu-system-${SYSTEM}"
[[ "$KERNEL" ]] && addp -kernel "$KERNEL"
[[ "$CPU" ]] && addp -cpu "$CPU"
[[ "$MACHINE" ]] && addp -M "$MACHINE"
[[ "$DTB" ]] && addp -dtb "$DTB"
addp -m $MEMORY
addp -net $NET -net nic,"macaddr=${NETMAC}${NETNIC:+,$NETNIC}"
[[ "$APPEND" ]] && addp -append "$APPEND"
[[ "$HDA" ]] && addp -hda "$HDA"
[[ "$CDROM" ]] && addp -cdrom "$CDROM"
[[ "$BOOT" ]] && addp -boot "$BOOT"
[[ "$SERIAL" ]] && addp -serial "$SERIAL"
[[ "$NOREBOOT" -eq 1 ]] && addp -no-reboot
echo "${CMD[@]}"
[ "$DRY" -gt 0 ] && exit 0
"${CMD[@]}"

