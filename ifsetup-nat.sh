#!/bin/sh

error()
{ echo "$1" >&2
  exit $2
}

VAR="$1"
[ -z "$VAR" ] && VAR=nat
case "$VAR" in
  nat) ;;
  *) error "Unknown variant '$VAR'." 1 ;;
esac

SD=`dirname $0`
[ -d "$SD" ] || error "No dir '$SD'" 1
SD=`cd "$SD" && pwd`
[ -d "$SD" ] || error "No dir '$SD'" 1

set -x
ln -s "$SD"/ifup-nat.sh /etc/qemu-ifup
ln -s "$SD"/ifdown-nat.sh /etc/qemu-ifdown
