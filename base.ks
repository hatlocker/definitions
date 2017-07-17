#version=DEVEL
# Keyboard layouts
keyboard 'us'
# Reboot after installation
reboot
# Root password
rootpw --plaintext provision123
# System timezone
timezone Etc/UTC --isUtc
# System language
lang en_US.UTF-8
# Firewall configuration
firewall --disabled
# Network information
network  --bootproto=dhcp --device=link --activate
url --url=http://dl.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/x86_64/os
repo --name="fedora" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-26&arch=x86_64
repo --name="updates" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f26&arch=x86_64
# System authorization information
auth --useshadow
text
# SELinux configuration
selinux --enforcing

# System bootloader configuration
bootloader --location=mbr --extlinux
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all
# Disk partitioning information
part / --fstype="ext4" --grow --size=3000

%post --erroronfail
# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
EOF

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

echo "Import RPM GPG key"
releasever=$(rpm -q --qf '%{version}\n' fedora-release)
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch

# Note that running rpm recreates the rpm db files which aren't needed/wanted
rm -f /var/lib/rpm/__db*


#echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
#dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
#rm -f /var/tmp/zeros
#echo "(Don't worry -- that out-of-space error was expected.)"

%end

%packages --instLangs=en
# Some basic groups
@core
@base-x
@fonts
@virtualization
@hardware-support
@networkmanager-submodules
# Some additional base tools
docker
lvm2
cryptsetup
efibootmgr
basesystem
# The custom packages
i3
i3lock
git
libreswan
lightdm
trousers
pcsc-lite
pcsc-lite-ccid
# Exclude some packages
-fedora-release
-dracut-config-rescue
-grub2
%end
