#!/bin/bash
set -e

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then

	if ! [ -e index.php ]; then
		echo >&2 "CakePHP not found in $(pwd) - copying now..."
		if [ "$(ls -A)" ]; then
			echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
			( set -x; ls -A; sleep 10 )
		fi

	fi

	/usr/bin/supervisord -c /etc/supervisord.conf &

fi

exec "$@"
