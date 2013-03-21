#!/bin/bash
set -o nounset
set -o pipefail
set -o errexit
set -o errtrace
shopt -s nullglob
shopt -s failglob

if [ "$#" -ne 2 ]; then
	echo "Syntax: $0 LOGIN LENGTH"
	exit 1
fi

user="$1"
length="$2"
chpasswdfile="$HOME/passwords/useraccounts/$user.chpasswd"
smbpasswdfile="$HOME/passwords/useraccounts/$user.smbpasswd"

if [ -e "$chpasswdfile" ] || [ -e "$smbpasswdfile" ]; then
	echo "Passwords exists already!"
	exit 1
fi

if ! password="$(password.sh "$length")" ; then
	echo "Generating password failed!"
	exit 1
fi

echo "$user:$password" > "$chpasswdfile"
echo -n -e "$password\n$password\n" > "$smbpasswdfile"

if ! chpasswd < "$chpasswdfile" ; then
	echo "chpasswd failed!"
	exit 1
fi

if ! smbpasswd -a -s "$user" < "$smbpasswdfile" ; then
	echo "smbpasswd failed!"
	exit 1
fi

if ! passwd -l "$user" ; then
	echo "passwd -l failed!"
	exit 1
fi
