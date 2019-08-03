# QEMU related scripts
- ifup-nat.sh / ifdown-nat.sh - scripts to auto-enable a NAT network with automatic IP address assignment for qemu machines
- ifsetup-nat.sh - installs above scripts into the system, make backup of the original first!
- run-qemu.sh - a trivial wrapper over the qemu-system-... command converting all the params to a (sourceable bash script) config file

# Enabling raspbian images to run in QEMU
- enabling.html - a howto for the said thing; note: github can't show html -> save "raw" and view that copy
