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
keyboard --vckeymap=us --xlayouts=''
# U.S. English
lang en_US.UTF-8
# Network config and repo
network  --bootproto=dhcp --device=link --activate
url --url=http://dl.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/x86_64/os
repo --name="fedora" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-26&arch=x86_64
repo --name="updates" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f26&arch=x86_64
repo --name="hatlocker" --baseurl=https://hatlocker.org/repo/repo
# Disk partitioning
zerombr
clearpart --all
part /boot --fstype="ext4" --size=200
part / --fstype="ext4" --grow --size=1000
# Disable root
#rootpw --lock
rootpw provision123
# SELinux enforcing
selinux --enforcing
# Timezone
timezone Etc/UTC --utc
# Auth config
authconfig --enableshadow --passalgo=bcrypt --disablefingerprint --enablecryptfs
# Services
services --enabled="chronyd"
xconfig --startxonboot


%post --erroronfail
echo "Import RPM GPG key"
releasever=$(rpm -q --qf '%{version}\n' fedora-release)
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch

# Note that running rpm recreates the rpm db files which aren't needed/wanted
rm -f /var/lib/rpm/__db*

# Register our compose time
echo "{{ version }}" >/var/lib/hatlocker-version

# Make sure we get the correct dracut modules added
printf "add_dracutmodules+=\" verity crypt \"\nhostonly=\"no\"" > /etc/dracut.conf.d/hatlocker.conf
kernel="`ls /boot/vmlinuz-* | sed -e 's./boot/vmlinuz-..'`"
dracut -v --force --no-hostonly --reproducible --show-modules /boot/hlinitramfs-$kernel.img $kernel

# Create mnt dirs
mkdir /mnt/etc
mkdir /mnt/var
mkdir /mnt/var_work

# Rewrite fstab
# TODO: Make sure that guestfs (imgfac, FactoryUtils.py:48, does not crash
echo "" >/etc/fstab
echo "tmpfs   /tmp         tmpfs   nodev,nosuid,size=2G          0  0" >>/etc/fstab
echo "tmpfs   /mnt/var_work  tmpfs   nodev,nosuid,size=2G          0  0" >>/etc/fstab
echo "tmpfs   /mnt/var       tmpfs   nodev,nosuid,size=2G          0  0" >>/etc/fstab
echo "/dev/mapper/datavg-datavol /home                       xfs     defaults,x-systemd.device-timeout=0 0 0" >>/etc/fstab
echo "/dev/mapper/datavg-etcvol  /mnt/etc                    xfs     defaults,x-systemd.device-timeout=0 0 0" >>/etc/fstab
echo "overlay /var overlay noauto,x-systemd.automount,lowerdir=/var,upperdir=/mnt/var,workdir=/mnt/var_work 0 0" >>/etc/fstab

# Create tempfiles now
systemd-tmpfiles --create --boot

# Disable some tmpfiles
ln -s /dev/null /etc/tmpfiles.d/home.conf
ln -s /dev/null /etc/tmpfiles.d/etc.conf

# Make lightdm default
rm -f /etc/systemd/system/display-manager.service /etc/systemd/system/default.target
ln -s /usr/lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service
ln -s /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target
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
# Hatlocker custom packages
dracut-verity
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
-grubby
%end
