#!/usr/bin/env sh

DATADIR="/var/lib/mysql"
HOSTNAME="$(hostname -s)"
MYSQLD_SOCKET="/run/mysqld/mysqld.sock"

MARIADB_DATABASE=${MARIADB_DATABASE:-""}
MARIADB_USER=${MARIADB_USER:-""}
MARIADB_PASSWORD=${MARIADB_PASSWORD:-""}

USER_EXTRA_FLAGS=${USER_EXTRA_FLAGS:-""}

DEFAULT_FLAGS="--console --skip-name-resolve"

MARIADB_REPLICATION_USER=${MARIADB_REPLICATION_USER:-"replication"}
MARIADB_REPLICATION_PASSWORD=${MARIADB_REPLICATION_PASSWORD:-""}
POD_NETWORK=${POD_NETWORK:-"%"}

POD_NUM=$(echo "$HOSTNAME" | awk -F'-' '{ print $2 }')
MASTER_HOSTNAME=$(echo "$MASTER_FQDN" | awk -F'.' '{ print $1 }')
SERVER_ID="1$POD_NUM"
REPLICATION_FLAGS="--server-id=$SERVER_ID --log-bin --relay-log=mariadb --log-basename=mariadb --binlog-format=mixed"
SLAVE_FLAGS="--log-slave-updates=ON --relay-log-recovery --read-only"


log() {
  (>&2 printf "\n>>> [mysqld] ($(date '+%Y-%m-%d %H:%M:%S')) $*\n");
}

if [ -z "$MARIADB_ROOT_PASSWORD" ]; then
  log "mysql root password environment variable missing, please export \$MARIADB_ROOT_PASSWORD" && exit 1
fi

execute_pre_init_scripts() {
  for i in /scripts/pre-init.d/*sh; do
  	if [ -e "$i" ]; then
  		log "pre-init.d - processing $i"
  		. "$i"
  	fi
  done
}

execute_pre_exec_scripts() {
  for i in /scripts/pre-exec.d/*sh; do
  	if [ -e "$i" ]; then
  		log "pre-exec.d - processing $i"
  		. "$i"
  	fi
  done
}

start_tmp_server() {
	log "Start temporary server"
    mysqld $DEFAULT_FLAGS --skip-grant-tables --socket="$MYSQLD_SOCKET" $DEFAULT_FLAGS $REPLICATION_FLAGS $USER_EXTRA_FLAGS &
	for i in $(seq 0 30); do
		if mysqladmin -uroot --socket="$MYSQLD_SOCKET" status > /dev/null 2>&1; then
			log "Temporary server started"
			break
		fi
		sleep 1
	done
	if [ "$i" = 30 ]; then
	    log "Unable to start temporary server" && exit 1
	fi
}

stop_tmp_server() {
	log "Stop temporary server"
    if ! mysqladmin -uroot -p"$MARIADB_ROOT_PASSWORD" --socket="$MYSQLD_SOCKET" shutdown > /dev/null 2>&1; then
    	log "Unable to stop temporary server" && exit 1
    fi
}

# execute any pre-init scripts
execute_pre_init_scripts

if [ "$(ls "$DATADIR")" = "" ]; then
	log "mariadb data directory not found, creating initial DBs"

	mysql_install_db --datadir=/var/lib/mysql --skip-test-db

	sql_init_script=$(mktemp)
	if [ ! -f "$sql_init_script" ]; then exit 1; fi

	cat << EOF > "$sql_init_script"
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL ON *.* TO 'root'@'%' identified by '$MARIADB_ROOT_PASSWORD' WITH GRANT OPTION;
GRANT ALL ON *.* TO 'root'@'localhost' identified by '$MARIADB_ROOT_PASSWORD' WITH GRANT OPTION;
SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MARIADB_ROOT_PASSWORD}');
EOF

	if [ "$MARIADB_DATABASE" != "" ]; then
	    log "Creating database: $MARIADB_DATABASE"
		if [ "$MARIADB_CHARSET" != "" ] && [ "$MARIADB_COLLATION" != "" ]; then
			log "with character set [$MARIADB_CHARSET] and collation [$MARIADB_COLLATION]"
			echo "CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\` CHARACTER SET $MARIADB_CHARSET COLLATE $MARIADB_COLLATION;" >> "$sql_init_script"
		else
			log "with character set: 'utf8' and collation: 'utf8_general_ci'"
			echo "CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> "$sql_init_script"
		fi

	 if [ "$MARIADB_USER" != "" ]; then
		log "Creating user: $MARIADB_USER with password $MARIADB_PASSWORD"
		echo "GRANT ALL ON \`$MARIADB_DATABASE\`.* to '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD';" >> "$sql_init_script"
	    fi
	fi

    # init master
    if [ "$MARIADB_REPLICATION_PASSWORD" != "" ] && [ "$HOSTNAME" = "$MASTER_HOSTNAME" ]; then
    	log "Configure master"
    	cat << EOF >> "$sql_init_script"
CREATE USER '$MARIADB_REPLICATION_USER'@'127.0.0.1' IDENTIFIED BY '$MARIADB_REPLICATION_PASSWORD';
CREATE USER '$MARIADB_REPLICATION_USER'@'$POD_NETWORK' IDENTIFIED BY '$MARIADB_REPLICATION_PASSWORD';
GRANT REPLICATION SLAVE ON *.* TO '$MARIADB_REPLICATION_USER'@'127.0.0.1';
GRANT REPLICATION SLAVE ON *.* TO '$MARIADB_REPLICATION_USER'@'$POD_NETWORK';
EOF
    fi

    # init slaves
    if [ "$MARIADB_REPLICATION_PASSWORD" != "" ] && [ "$HOSTNAME" != "$MASTER_HOSTNAME" ]; then
    	log "Configure slave"
    	REPLICATION_FLAGS="$REPLICATION_FLAGS $SLAVE_FLAGS"
    	cat << EOF >> "$sql_init_script"
STOP SLAVE;
CHANGE MASTER TO MASTER_HOST='$MASTER_FQDN', MASTER_PORT=3306, MASTER_USER='$MARIADB_REPLICATION_USER', MASTER_PASSWORD='$MARIADB_REPLICATION_PASSWORD', MASTER_USE_GTID=slave_pos;
START SLAVE;
EOF
    fi

    start_tmp_server    

	log "Run scripts"
    echo "FLUSH PRIVILEGES;" >> "$sql_init_script"
    mysql --protocol=socket -uroot -hlocalhost --socket="$MYSQLD_SOCKET" < "$sql_init_script"

	for f in /entrypoint-initdb.d/*; do
		case "$f" in
			*.sql)    echo "$0: running $f"; mysql --protocol=socket -uroot -hlocalhost --socket="$MYSQLD_SOCKET" < "$f"; echo ;;
			*.sql.gz) echo "$0: running $f"; gunzip -c "$f" | mysql --protocol=socket -uroot -hlocalhost --socket="$MYSQLD_SOCKET" < "$f"; echo ;;
			*)        echo "$0: ignoring or entrypoint initdb empty $f" ;;
		esac
		echo
	done

    stop_tmp_server    

	log 'MySQL init process done. Ready for start up.\n'

	echo "exec mysqld $DEFAULT_FLAGS $REPLICATION_FLAGS $USER_EXTRA_FLAGS" "$@"
fi

# execute any pre-exec scripts
execute_pre_exec_scripts

exec mysqld $DEFAULT_FLAGS $REPLICATION_FLAGS $USER_EXTRA_FLAGS $@
