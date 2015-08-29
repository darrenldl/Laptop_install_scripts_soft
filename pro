@COMMAND
clear
echo "This script is designed to be launched by pre.sh"
echo "If it is not launched by pre.sh, terminate it now"
echo "Otherwise, press enter"
read
clear
<END

@COMMAND
MAIN_PART_NAME=$(cat TEMP_MAIN_PART_NAME)
BOOT_PART_NAME=$(cat TEMP_BOOT_PART_NAME)
rm TEMP_MAIN_PART_NAME
rm TEMP_BOOT_PART_NAME
#echo "test param pasing file"
#echo "$MAIN_PART_NAME"
#echo "$BOOT_PART_NAME"
DRIVE_NAME=$(echo $BOOT_PART_NAME | tr -d 0-9)
#echo "$DRIVE_NAME"
read
<END

@COMMAND
i=0
while (( $i == 0 )); do
	i=1
	echo -n "Please enter hostname: "
	read HOST_NAME
	echo "You entered: $HOST_NAME"
	echo "Is it correct? yes/no"
	read ans
	if [[ $ans != "yes" ]]; then
		i=0
		continue
	fi
done
echo "Setting host name to \"$HOST_NAME\""
<END

@APPEND
$HOST_NAME
>START
/etc/hostname
<END

@COMMAND
echo "Host name set to \"$HOST_NAME\""
<END

@COMMAND
echo ""
echo "Configuring locale.gen and locale.conf"
<END

@REPLACE
\#en_US.UTF-8 UTF-8
@WITH
en_US.UTF-8 UTF-8
>START
/etc/locale.gen
<END

@APPEND
LANG=en_US.UTF-8
>START
/etc/locale.conf
<END

@COMMAND
echo "command: locale-gen"
locale-gen
echo "locale.gen and locale.conf are configured"
<END

@COMMAND
sleep 5
clear
i=0
echo "Updating databases"
while (( $i == 0 )); do
	i=1
	echo "command: pacman -Sy --noconfirm"
	pacman -Sy --noconfirm
	OUT=$?
	if (( $OUT != 0 )); then
		echo "Problem detected"
		echo "Please fix the problem and press enter"
		i=0
		read
	fi
done
echo "Databases updated"
sleep 5
clear
echo "Updating all packages"
i=0
while (( $i == 0 )); do
	i=1
	echo "command: pacman -Su --noconfirm"
	pacman -Su --noconfirm
	OUT=$?
	if (( $OUT != 0 )); then
		echo "Problem detected"
		echo "Please fix the problem and press enter"
		i=0
		read
	fi
done
echo "Packages updated"
sleep 5
clear
<END

@COMMAND
echo "Installing GRUB bootloader"
i=0
while (( $i == 0 )); do
	i=1
	echo "command: pacman -S grub --noconfirm"
	pacman -S grub --noconfirm
	OUT=$?
	if (( $OUT != 0 )); then
		echo "Problem detected"
		echo "Please fix the problem and press enter"
		i=0
		read
	fi
done
echo "GRUB installed"
echo ""
<END

@COMMAND
echo "GRUB configured"
echo ""
echo "Installing GRUB to Key device"
if [ -d /sys/firmware/efi ]; then
	echo "The system is using UEFI"
	echo "command: grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --recheck --removable"
	grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --recheck --removable
	echo "GRUB installed to boot partition"
	echo "Generating GRUB config"
	echo "command: grub-mkconfig -o /boot/efi/EFI/GRUB/grub.cfg"
	grub-mkconfig -o /boot/efi/EFI/GRUB/grub.cfg
else
	echo "The system is using BIOS"
	echo "command: grub-install --target=i386-pc --recheck $DRIVE_NAME"
	grub-install --target=i386-pc --recheck $DRIVE_NAME
	echo "GRUB installed to boot partition"
	echo "Generating GRUB config"
	echo "command: grub-mkconfig -o /boot/grub/grub.cfg"
	grub-mkconfig -o /boot/grub/grub.cfg
fi
echo "GRUB installed"
sleep 5
clear
echo "Disabling lid switch"
<END

@REPLACE
\#HandleLidSwitch=suspend
@WITH
HandleLidSwitch=ignore
>START
/etc/systemd/logind.conf
<END

@COMMAND
echo "Lid switch disabled"
sleep 5
clear
sleep 5
echo "Now installing openssh"
i=0
while (( $i == 0 )); do
	i=1
	echo "command: pacman -S openssh --noconfirm"
	pacman -S openssh --noconfirm
	OUT=$?
	if (( $OUT != 0 )); then
		echo "Problem detected"
		echo "Please fix the problem and press enter"
		i=0
		read
	fi
done
<END

@COMMAND
echo "About to install packages"
echo "Please review pkg_list for list of packages"
echo "When you have finished editing pkg_list, press enter"
read
chmod u+x pkg_install.sh
./pkg_install.sh
<END

@COMMAND
echo "Packages installed"
sleep 5
clear
<END

@COMMAND
echo "You can choose whether to lock down root"
echo "Or set a password to protect root account"
echo "Locking down root will disable some of the means to obtain root access"
i=0
while (( $i == 0 )); do
	i=1
	echo "Do you want to lock down root? lock/passwd"
	read lock_passwd
	if [[ $lock_passwd != "lock" ]] && [[ $lock_passwd != "passwd" ]]; then
		echo "Please enter either lock or passwd"
		i=0
		continue
	fi
	echo "You entered: $lock_passwd"
	echo "Is it correct? yes/no"
	read ans
	if [[ $ans != "yes" ]]; then
		i=0
		continue
	fi
done
if [[ $lock_passwd == "lock" ]]; then
	echo "Will now generate lock_root.sh"
	./ezsetfacl.sh -g lock_root > lock_root.sh
	chmod u+rwx lock_root.sh
	echo "Now execute lock_root.sh"
	./lock_root.sh
	echo ""
	echo "Removing lock_root.sh"
	rm lock_root.sh
else
	echo "Please enter password for root"
	i=0
	while (( $i == 0 )); do
		i=1
		echo "command: passwd"
		passwd
		OUT=$?
		if (( $OUT != 0 )); then
			echo "Problem detected"
			i=0
		fi
	done
fi
echo "Removing lock_root"
rm lock_root
sleep 5
clear
i=0
while (( $i == 0 )); do
	i=1
	echo -n "Please enter the user you want to add: "
	read USR_NAME
	echo "Please note that the user name requires two lowercase letters and does not start with a number"
	echo "You entered: $USR_NAME"
	echo "Is it correct? yes/no"
	read ans
	if [[ $ans != "yes" ]]; then
		i=0
		continue
	fi
done
echo ""
echo "Adding user $USR_NAME"
useradd -m $USR_NAME
echo "Please enter password for $USR_NAME"
i=0
while (( $i == 0 )); do
	i=1
	echo "command: passwd $USR_NAME"
	passwd $USR_NAME
	OUT=$?
	if (( $OUT != 0 )); then
		echo "Problem detected"
		i=0
	fi
done
echo "User $USR_NAME added"
sleep 5
clear
#echo "Adding and configuring user files"
#echo ".bash_logout .bash_profile .bashrc .xinitrc .xsession"
#cp /etc/skel/.bash_logout /home/"$USR_NAME"
#cp /etc/skel/.bash_profile /home/"$USR_NAME"
#cp /etc/skel/.bashrc /home/"$USR_NAME"
cp /etc/skel/.xinitrc /home/"$USR_NAME"
#cp /etc/skel/.xsession /home/"$USR_NAME"
echo "Adding $USR_NAME to group users"
gpasswd -a $USR_NAME users
<END

@APPEND
exec startxfce4
>START
/home/$USR_NAME/.xinitrc
<END

@COMMAND
echo "User files added and configured"
sleep 5
clear
echo "Disabling firewire"
./ezsetfacl.sh -a disable_firewire
rm disable_firewire
sleep 5
clear
echo "Enabling services"
echo ""
echo "Enabling NetworkManager"
systemctl enable NetworkManager
echo "Enabling iptables and ip6tables"
systemctl enable iptables
systemctl enable ip6tables
echo ""
echo "Enabling sshd"
systemctl enable sshd
echo "Disabling services"
echo ""
#echo "Disabling sshd"
#systemctl disable sshd
sleep 5
clear
<END

@COMMAND
echo "Adding $USR_NAME to lock_p"
<END

@REPLACE
dummy
@WITH
$USR_NAME
>START
lock_p
lock
lock_config
<END

@COMMAND
echo "$USR_NAME added to lock"
sleep 5
clear
echo "lock_p is for basic modifications that can be safely done right now"
echo "lock is for general modifications"
echo "lock_config is for configuration files modifications"
echo ""
echo "lock_p will be executed later on during this installation session"
echo "other locking scripts are intended to be used post-installation"
echo ""
echo "All locking scripts generated are stored at /root"
echo ""
echo "Press enter to continue"
read
<END

@COMMAND
chmod u+rwx ezsetfacl.sh
./ezsetfacl.sh -g lock_p > /root/lock_p.sh
chmod u+rwx /root/lock_p.sh
echo "lock_p.sh generated, it is located at /root/lock_p.sh"
./root/lock_p.sh
sleep 5
clear
echo "About to generate lock.sh and lock_config.sh"
./ezsetfacl.sh -g lock > /root/lock.sh
chmod u+rwx /root/lock.sh
./ezsetfacl.sh -g lock_config > /root/lock_config.sh
chmod u+rwx /root/lock_config.sh
sleep 5
clear
<END

@COMMAND
echo "Generating disable_firewire.sh"
./ezsetfacl.sh -g disable_firewire > /root/disable_firewire.sh
chmod u+rwx /root/disable_firewire.sh
<END

@COMMAND
sleep 5
clear
echo "All steps were completed"
echo "Now executing disable_firewire.sh"
echo "command: ./root/disable_firewire.sh"
./root/disable_firewire.sh
echo "Now executing lock_p.sh"
echo "command: ./root/lock_p.sh"
./root/lock_p.sh
sleep 5
clear
echo "Cleaning files"
echo "Removing disable_firewire"
rm disable_firewire
echo "Removing lock_p"
rm lock_p
echo "Removing lock"
rm lock
echo "Your Archlinux for laptop is now installed and essential configurations have been done"
echo "All operations are finished, press enter to exit pro.sh and return to pre.sh"
read
<END

####