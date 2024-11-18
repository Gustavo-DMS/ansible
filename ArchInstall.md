# Criar partições
gdisk /dev/sda
o
y
enter 2x
+500M
ef00
n
enter 4x
w

# Criptografar partições
cryptsetup luksFormat /dev/sda2
YES
cryptsetup open /dev/sda2 main

# Formatar partições
mkfs.btrfs /dev/mapper/main
mount /dev/mapper/main /mnt
cd /mnt
btrfs subvolume create @
btrfs subvolume create @home
cd
umount /mnt
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@ /dev/mapper/main /mnt
mkdir /mnt/home
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@home /dev/mapper/main /mnt/home
mkfs.fat -F32 /dev/sda1
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# update the mirrorlist
reflector -c Brazil -a 12 --sort rate --save /etc/pacman.d/mirrorlist

# Install the base system
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs neovim git networkmanager network-manager-applet reflector sudo openssh

# Generate the fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

# Chroot
arch-chroot /mnt

# Set the timezone
ln -sf /usr/share/zoneinfo/Brazil/East /etc/localtime
hwclock --systohc

# set hostname
echo "archlinux" > /etc/hostname

# set passwd and user
passwd
useradd -m -g users -G wheel gustavo
passwd gustavo
echo "gustavo ALL=(ALL) ALL" >> /etc/sudoers.d/gustavo

# Install and configure bootloader
bootctl install
lsblk -ndo PARTUUID /dev/sda2 > /boot/loader/entries/arch.conf
nvim /boot/loader/entries/arch.conf

title   Arch Linux (linux)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options cryptdevice=PARTUUID=01150111-aad8-454e-866b-2dadf3b89007:root root=/dev/mapper/root zswap.enabled=0 rootflags=subvol=@ rw rootfstype=btrfs

# Configure mkinitcpio
sudo nvim /etc/mkinitcpio.conf
MODULES=(btrfs)
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)
mkinitcpio -p linux

# Enable services
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable reflector.timer
systemctl enable fstrim.timer

# DONE!
exit
reboot


