#!/bin/bash
set -o nounset
set -o pipefail
set -o errexit
set -o errtrace
shopt -s nullglob
shopt -s failglob

DEBUG=0
LOG='/var/log/thinkpad-dock.log'
HOME='/home/leo'	# TODO: SET THIS TO THE HOMEDIR OF YOUR LOGGED IN USER!

if [ "$DEBUG" -eq 1 ] ; then
	touch "$LOG"
	chown root:root "$LOG"
	chmod 700 "$LOG"
	exec &>> "$LOG"
fi

sleep 3 # wait for the dock state to change

DOCKED="$(</sys/devices/platform/dock.0/docked)"

call_disper() {
	export DISPLAY=':0'
	export HOME
	disper "$@"
}

case "$DOCKED" in
	'0') #undocked event
		echo "$(date --rfc-3339=s): Undock handler..."

		if ! call_disper --single ; then # prevent errexit
			echo "Warning: Switching display failed!" >&2
		fi

		now="$(date +%s)"
		freenet_start="$(stat --format=%Y /home/freenet/bootID)"
		freenet_uptime="$(( ($now - $freenet_start) / 60 ))"
		if [ "$freenet_uptime" -gt 3 ] ; then
			# Freenet has a bug which kills the database if we shut it down during defragmentation so we give it some time
			echo "Freenet uptime is sufficient for clean shutdown, stopping it ..."
			if ! service freenet stop ; then
				echo "Warning: Stopping Freenet failed!" >&2
			fi
		fi
	;;
	'1') #docked event
		echo "$(date --rfc-3339=s): Dock handler..."

		if ! call_disper --secondary ; then
			echo "Warning: Switching display failed!" >&2
		fi

		if ! service freenet start ; then
			echo "Warning: Starting Freenet failed!" >&2
		fi

		mount-server.sh
	;;
esac
exit 0
