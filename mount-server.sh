#!/bin/bash
set -o nounset
set -o pipefail
set -o errexit
set -o errtrace
shopt -s nullglob
shopt -s failglob

SERVER_IP='10.0.0.1'
SHARES=( '/home/leo/Server-Freenet' # dest of CIFS share
		'/home/leo/Server' # dest of CIFS share
		'/home/leo/Multimedia' # dest of CIFS share
		'/home/leo/Multimedia/Music/Archive' # src of bind mountpoint, dest won't work
		'/home/leo/Multimedia/Music-Old/Albums' # src of bind mountpoint, dest won't work
		)

wait_for_network() {
	echo "Waiting for $1 seconds for $SERVER_IP to come online..."

	for (( t=0 ; t<"$1" ; t++ )) ; do
		if ping -c1 "$SERVER_IP" &> /dev/null ; then
			return 0
		fi
		sleep 1
	done
	return 1
}

if [ "$#" -eq 0 ] ; then
	echo "Mounting all server shares..."

	# The Thinkpad dock-handler script gets called BEFORE the network is up during boot so we wait for 60 seconds
	if ! wait_for_network 60 ; then
		echo "Server is offline!" >&2
		exit 1
	fi

	for share in "${SHARES[@]}" ; do
		if ! mount "$share" ; then
			echo "Mounting a share failed, aborting: $share" >&2
			# If mounting one share failes we need to exit because I do bind-mounts
			# on subfolders of some CIFS shares and it wouldn't be possible to mount
			# the binds if the subfolders do not exist.
			exit 1
		fi
	done
	exit 0
elif [ "$#" -eq 1 ] && [ "$1" = '-u' ] ; then
	echo "Unmounting all server shares..."

	exitcode=0

	# I have some CIFS shares which I first mount to one path and then do a bind-mount
	# of that mountpoint to another path. For cleanly unmounting those, we need
	# to unmount in reverse order so the binds get umounted first because it wouldn't
	# be possible to umount the actual CIFS mountpoints if there are still open handles
	# on them.
	for (( i=${#SHARES[@]}-1 ; i>=0 ; i-- )) ; do
		share="${SHARES[$i]}"
		
		if ! umount -r "$share" ; then
			echo "Unmounting failed for: $share" >&2
			# Don't exit if unmounting one share failes, we want to unmount everything
			# which can be unmounted for flushing file buffers for safety.
			exitcode=1
		fi

		sleep 2	# Umounting the sources of the bind-mounts won't work without this delay
	done

	exit "$exitcode"
else
	echo "Syntax: $0 [-u]"
	exit 1
fi
