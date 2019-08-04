#!/usr/bin/env bash

# (C) 2019 Radek Slaby, jakjinak (https://github.com/jakjinak)
# This work is licensed under the terms of the MIT license, see LICENSE.MIT.

# verify user
[[ "$(id -u)" -eq 0 || "$(id -un)" = root ]] || { echo -e "\e[1;31mMust be root to do this.\e[0m" ; exit 1 ; }

# choose which nbd device to use
declare -a nbds
declare -a nbds0
max=-1
while read x
do
  n=${x#/dev/nbd}
  case "$n" in
    *p*)
      p=${n##*p}
      n=${n%%p*}
      nbds[$n]=$((${nbds[$n]}+1))
      ;;
    *)
      [ $max -lt $n ] && max=$n
      nbds0[$n]=1
      ;;
  esac
done < <(ls -1 /dev/nbd*)

[[ $max -lt 0 ]] && {
  echo -e "\e[1;31mNo /dev/nbd* found.\e[0m"
  exit 1
}

echo "Found the following nbd devices (yellow appear to be in use):"
for i in "${!nbds0[@]}"
do
  cnt="${nbds[$i]:-0}"
  [[ $cnt -gt 0 ]] && echo -en "\e[1;33m"
  echo -n "/dev/nbd$i"
  [[ $cnt -gt 0 ]] && echo -en "\e[22m ($cnt partitions: $(ls /dev/nbd${i}p* | tr '\n' ' ')\e[0m"
  echo
done
read -p "Pick one to unmount (make sure noone uses them anymore): " device

[[ -b "$device" ]] || {
  echo -e "You chose '\e[1m$device\e[0m', but that \e[31mdevice does not exist.\e[0m"
  exit 1
}

# unmount and disconnect
echo -e "About to disconnect '\e[1m$device\e[0m' and all its partitions. Continue=ENTER, cancel=Ctrl+C."
mount | sed -n -e 's|^\('"$device"'\)|\1|' -e T -e p
read bz

run_cmd()
{ "${cmd[@]}"
  ret=$?
  [[ $ret -eq 0 ]] || {
    echo -e "\e[31m'\e[1m${cmd[@]}\e[22m' failed with \e[1m$ret\e[0m"
    exit $ret
  }
}
mount | sed -n -e 's|^'"$device"'.* on \(.*\) type .*|\1|' -e T -e p | tac | while read part
  do
    echo -e "About to unmount '\e[1m$part\e[0m'? Continue=ENTER, cancel=Ctrl+C."
    read bz < /dev/tty
    cmd=(umount "$part")
    run_cmd
  done

cmd=(qemu-nbd --disconnect "$device")
run_cmd
