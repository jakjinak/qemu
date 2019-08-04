#!/usr/bin/env bash

# (C) 2019 Radek Slaby, jakjinak (https://github.com/jakjinak)
# This work is licensed under the terms of the MIT license, see LICENSE.MIT.

# verify user
[[ "$(id -u)" -eq 0 || "$(id -un)" = root ]] || { echo -e "\e[1;31mMust be root to do this.\e[0m" ; exit 1 ; }

declare -a unm

trap 'for u in "${unm[@]}" ; do umount "$u" ; echo -e "umount \e[1m$u\e[0m; exits $?" ; done' EXIT

# verify given dir
dir="$1"
[[ -z "$dir" ]] && {
  echo -e "\e[1;31mDirectory to be used as root must be given as first argument.\e[0m"
  exit 1
}
[[ -d "$dir" && -x "$dir" ]] || {
  echo -e "\e[31m'\e[1m$dir\e[22m cannot be read or is not a directory.\e[0m"
  exit 1
}
dir="$(cd "$dir" && pwd)"
[[ -d "$dir" && -x "$dir" ]] || {
  echo -e "\e[31m'\e[1m$dir\e[22m cannot be read or is not a directory.\e[0m"
  exit 1
}

# check if the correct interpreter is in place
# defaults to /usr/bin/qemu-arm-static but can be overriden
inte="$3"
[[ -z "$inte" ]] && inte=/usr/bin/qemu-arm-static
[[ -x "$dir$inte" ]] || cp -v "$inte" "$dir$inte"
[[ -x "$dir$inte" ]] || {
  echo -e "\e[31mThere is no \e[1m$dir$inte\e[22m, neither could it be auto-established.\e[0m"
  exit 1
}

update-binfmts --display | grep "$inte"
[[ $? -eq 0 ]] || {
  echo -e "\e[31mInterpreter \e[1m$inte\e[22m not registered in system.\e[0m"
  exit 1
}

# remount system dirs
for i in dev sys proc dev/pts
do
  [[ -d "$dir/$i" ]] || continue
  echo -e "Remounting \e[1m/$i\e[0m as \e[1m$dir/$i\e[0m"
  mount --bind /$i "$dir/$i"
  ret=$?
  [[ $ret -eq 0 ]] && unm=("$dir/$i" "${unm[@]}") || echo -e "\e[31mCould not remount \e[1m/$i\e[0m"
done

# check if user was given
us="$2"

[[ "$us" ]] && cmd=(bin/su - "$us") || cmd=(bin/sh)
echo -e "chrooting to \e[1m$dir\e[0m and running \e[1m${cmd[@]}\e[0m"
chroot "$dir" "${cmd[@]}"
