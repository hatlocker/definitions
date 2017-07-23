# We do not need a bootloader - we will do UEFI-only
bootloader --location none --disabled
# We want fully kickstarted
cmdline
# Set a strict firewall
firewall --enable
# Disable firstboot
firstboot --disable
# At the end, just power off
poweroff
# Set keyboard
keyboard 'us'
# U.S. English
lang en_US.UTF-8
# Network config and repo
network  --bootproto=dhcp --device=link --activate
url --url=http://dl.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/x86_64/os
repo --name="fedora" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-26&arch=x86_64
repo --name="updates" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f26&arch=x86_64
# Disk partitioning
zerombr
clearpart --all
part / --fstype="ext4" --grow --size=1000
# Disable root
rootpw --lock
# SELinux enforcing
selinux --enforcing
# Timezone
timezone etc/UTC --utc
# Auth config
authconfig --enableshadow --passalgo=bcrypt --disablefingerprint --enablecryptfs


%post --erroronfail
echo "Import RPM GPG key"
releasever=$(rpm -q --qf '%{version}\n' fedora-release)
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch

# Note that running rpm recreates the rpm db files which aren't needed/wanted
rm -f /var/lib/rpm/__db*
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
veritysetup
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
-dnf
%end
