#!/usr/bin/env bash

# (C) 2019 Radek Slaby, jakjinak (https://github.com/jakjinak)
# This work is licensed under the terms of the MIT license, see LICENSE.MIT.

# verify user
[[ "$(id -u)" -eq 0 || "$(id -un)" = root ]] || { echo -e "\e[1;31mMust be root to do this.\e[0m" ; exit 1 ; }

# verify given image
image="$1"
[[ -z "$image" ]] && {
  echo -e "\e[1;31mDisk image must be given as first argument.\e[0m"
  exit 1
}
[[ -r "$image" ]] || {
  echo -e "\e[31mCould not read '\e[1m$image\e[22m'.\e[0m"
  exit 1
}
# convert image to full path
image="$(cd $(dirname "$image") && pwd)/$(basename "$image")"
[ -r "$image" ] || {
  echo -e "\e[31mCould not read '\e[1m$image\e[22m'.\e[0m"
  exit 1
}

# verify given mount path
mntpath="$2"
[[ -z "$mntpath" ]] && {
  echo -e "\e[1;31mThe mount point must be given as second argument.\e[0m"
  exit 1
}
[[ -d "$mntpath" && -x "$mntpath" ]] || {
  echo -e "\e[31mThe given '\e[1m$mntpath\e[22m' is not a directory or does not exist.\e[0m"
  exit 1
}
mntpath="$(cd "$mntpath" && pwd)"

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
  echo -e "\e[1;31mNo /dev/nbd* found.\e[0m You might want to run (as root) \e[1mmodprobe nbd max_part=\e[33mnum\e[0m where num is the max number of disks nbd will be able to handle."
  exit 1
}

echo "Found the following nbd devices (red appear to be in use):"
for i in "${!nbds0[@]}"
do
  cnt="${nbds[$i]:-0}"
  [[ $cnt -gt 0 ]] && echo -en "\e[31;2m"
  echo -n "/dev/nbd$i"
  [[ $cnt -gt 0 ]] && echo -en " (used, $cnt partitions: $(ls /dev/nbd${i}p* | tr '\n' ' ')\e[0m"
  echo
done
read -p "Pick a free one to mount the image: " device

[[ -b "$device" ]] || {
  echo -e "You chose '\e[1m$device\e[0m', but that \e[31mdevice does not exist.\e[0m"
  exit 1
}

# connect image via nbd
echo -e "About to connect '\e[1m$image\e[0m' via '\e[1m$device\e[0m'. Continue=ENTER, cancel=Ctrl+C."
[[ "$3" ]] && echo -e "Format of image forced to '\e[1m$3\e[0m'."
read bz

run_cmd()
{ "${cmd[@]}"
  ret=$?
  [[ $ret -eq 0 ]] || {
    echo -e "\e[31m'\e[1m${cmd[@]}\e[22m' failed with \e[1m$ret\e[0m"
    exit $ret
  }
}

cmd=(qemu-nbd --connect="$device" "$image")
[[ "$3" ]] && cmd=("${cmd[@]}" -f "$3")
run_cmd

echo -e "\e[36m\e[1m$image\e[22m is now at \e[1m$device\e[22m with the following content:\e[0m"

# check partitions within image and mount the root
cmd=(fdisk -l "$device")
run_cmd

read -p "Choose which partition from the above (${device}p...) shall be mounted into $mntpath: " part
[[ -b "$part" ]] || {
  echo -e "You chose '\e[1m$part\e[0m', but that \e[31mpartition does not exist.\e[0m"
  exit 1
}

cmd=(mount "$part" "$mntpath")
run_cmd

echo -e "\e[36m\e[1m$part\e[22m is now in \e[1m$mntpath\e[0m"

# optionally mount the boot
[[ -d "$mntpath"/boot ]] || exit 0 # no boot in mounted root, nothing more to do

read -p "Choose which partition from the above (${device}p...) shall be mounted into $mntpath/boot; keep empty to skip: " part
[[ -b "$part" ]] || {
  echo -e "You chose '\e[1m$part\e[0m', but that \e[31mpartition does not exist.\e[0m"
  exit 1
}

cmd=(mount "$part" "$mntpath/boot")
run_cmd

echo -e "\e[36m\e[1m$part\e[22m is now in \e[1m$mntpath/boot\e[0m"
