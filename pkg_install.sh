#!/bin/bash
while [ ! -f "pkg_list" ]; do
    echo "pkg_list does not exist"
	i=0
	while (( $i == 0 )); do
		i=1
		echo "Please enter whether you want to cancel pkg_install.sh or fix the problem: cancel/fix"
		read can_fix
		if [[ $can_fix != "cancel" ]] && [[ $can_fix != "fix" ]] && [[ $can_fix != "" ]]; then
			echo "Please enter cancel/fix"
			i=0
			continue
		fi
		echo "You entered: $can_fix"
		echo "Is it correct? yes/no"
		read ans
		if [[ $ans != "yes" ]]; then
			i=0
			continue
		fi
	done
	if (( $can_fix == "cancel" )); then
		exit
	else
		echo "Please make sure pkg_list is present, then press enter to continue"
		read
	fi
done

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

pkg_list_string=$(cat pkg_list)
for x in $pkg_list_string; do
	i=0
	while (( $i == 0 )); do
		i=1
		echo "command: pacman -S $x --noconfirm"
		pacman -S $x --noconfirm
		OUT=$?
		if (( $OUT == 1 )); then
			echo ""
			echo "Package: $x not found"
			j=0
			ans=""
			cor_skip=""
			man_pkg=""
			while (( $j == 0 )); do
				j=1
				echo ""
				echo "Do you want to correct it manually or skip? cor/skip"
				echo "Warning: Blank answer will be treated as \"skip\""
				read cor_skip
				if [[ $cor_skip != "cor" ]] && [[ $cor_skip != "skip" ]] && [[ $cor_skip != "" ]]; then
					echo "Please enter cor/skip"
					j=0
					continue
				fi
				echo ""
				echo -n "You entered: $cor_skip"
				if [[ $cor_skip == "" ]]; then
					echo "(skip)"
				else
					echo ""
				fi
				echo "Is it correct? yes/no"
				read ans
				if [[ $ans != "yes" ]]; then
					j=0
					continue
				fi
				if [[ $cor_skip == "cor" ]]; then
					z=0
					while (( $z == 0 )); do
						z=1
						echo ""
						echo -n "Please enter package name: "
						read man_pkg
						echo "You entered: $man_pkg"
						echo "Is it correct? yes/no"
						read ans
						if [[ $ans != "yes" ]]; then
							z=0
							continue
						fi
						echo ""
						echo "command: pacman -S $man_pkg --noconfirm"
						pacman -S $man_pkg --noconfirm
						OUT2=$?
						if (( $OUT2 != 0 )); then
							echo "Package: $man_pkg installation failed, please try again manually after this automated installation"
							echo "Failed package name is recorded in new system's /root directory, file name is \"failed_pkg_list\""
							echo "$man_pkg" >> /root/failed_pkg_list
							sleep 1
							clear
						fi
					done
				else
					echo ""
					echo "Skipping package $x"
					sleep 1
					clear
				fi
			done
		fi
		if (( $OUT != 0 )) && (( $OUT != 1 )); then
			echo "Problem detected"
			echo "Please fix the problem and press enter"
			i=0
			read
		fi
	done
done