#!/bin/bash
if ! source "lib-bash-leo.sh" ; then
	echo 'lib-bash-leo.sh is missing in PATH!'
	exit 1
fi

# $1 = battery
# $2 = force discharge
force_discharge() {
	local bat
	case "$1" in
		main)
			bat=0 ;;
		ultrabay)
			bat=1 ;;
		*)
			return 1 ;;
	esac

	stdout "$2" > "/sys/devices/platform/smapi/BAT$bat/force_discharge"
}

print_syntax_and_die() {
	die 'Syntax: choose-powersource.sh batmain|batultrabay|line'
}

main() {
	if [ $# -ne 1 ] ; then
		print_syntax_and_die
	fi
	
	case "$1" in
		batmain)
			force_discharge main 1
			force_discharge ultrabay 0
			;;
		batultrabay)
			force_discharge main 0
			force_discharge ultrabay 1
			;;
		line)
			force_discharge main 0
			force_discharge ultrabay 0
			;;
		*)
			print_syntax_and_die
			;;
	esac
	
}

main "$@"
