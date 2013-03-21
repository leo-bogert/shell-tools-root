#!/bin/bash
set -o nounset
set -o pipefail
set -o errexit
set -o errtrace
shopt -s nullglob
shopt -s failglob

if ! mount-server.sh -u ; then
	echo "Unmounting server shares failed!" >&2
	exit 1
fi

echo '1' > '/sys/bus/platform/drivers/thinkpad_acpi/thinkpad_acpi/subsystem/devices/dock.0/undock'

exit 0
