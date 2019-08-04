# Howtos
- enabling.html - Enabling raspbian images to run in QEMU
- static_chroot.html - Running ARM binaries in chrooted filesystem using qemu-arm-static

note: github can't show html -> save "raw" and view that copy

# QEMU related scripts
- ifup-nat.sh / ifdown-nat.sh - scripts to auto-enable a NAT network with automatic IP address assignment for qemu machines
- ifsetup-nat.sh - installs above scripts into the system, make backup of the original first!
- run-qemu.sh - a trivial wrapper over the qemu-system-... command converting all the params to a (sourceable bash script) config file
- nbd_mount.sh / nbd_umount.sh - wrappers over mounting qemu image files using qemu-nbd + mount
- static_chroot.sh - "simulating" ARM using chroot and qemu-arm-static
