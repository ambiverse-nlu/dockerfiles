#!/bin/bash

IMPORT_cmdname=${0##*/}

echoerr() { if [[ $WAITFORIT_QUIET -ne 1 ]]; then echo "$@" 1>&2; fi }

usage()
{
    cat << USAGE >&2
Usage:
    $IMPORT_cmdname host:port [-d database] [-c cassandra_host] [-- command args]
    -h HOST | --host=HOST       Host or IP under test
    -p PORT | --port=PORT       TCP port under test
                                Alternatively, you specify the host and port as host:port

    -d DATABASE | --dbname=DATABASE     Database name
    -ch CASSANDRA_HOST | --chost=CASSANDRA_HOST  Cassandra Host
    -cp CASSANDRA_PORT | --cport=CASSANDRA_PORT Cassandra Port
    -s | --strict        Only execute subcommand if the test succeeds
    -t TIMEOUT | --timeout=TIMEOUT
                                    Timeout in seconds, zero for no timeout
    -q | --quiet                Don't output any status messages
    -- COMMAND ARGS             Execute command with args after the test finishes
USAGE
    exit 1
}

if [[ ${CASSANDRA_VERSION} == "" ]]
then
    CASSANDRA_VERSION=3.11.4
fi

CASSANDRA_PORT=9042

# process arguments
while [[ $# -gt 0 ]]
do
    case "$1" in
        *:* )
        _hostport=(${1//:/ })
        _HOST=${_hostport[0]}
        _PORT=${_hostport[1]}
        shift 1
        ;;
        --child)
        WAITFORIT_CHILD=1
        shift 1
        ;;
        -q | --quiet)
        WAITFORIT_QUIET=1
        shift 1
        ;;
        -s | --strict)
        WAITFORIT_STRICT=1
        shift 1
        ;;
        -h)
        _HOST="$2"
        if [[ $_HOST == "" ]]; then break; fi
        shift 2
        ;;
        --host=*)
        _HOST="${1#*=}"
        shift 1
        ;;
        -p)
        _PORT="$2"
        if [[ $_PORT == "" ]]; then break; fi
        shift 2
        ;;
        --port=*)
        _PORT="${1#*=}"
        shift 1
        ;;
        -d)
        DATABASE_NAME="$2"
        if [[ $DATABASE_NAME == "" ]]; then break; fi
        shift 2
        ;;
        --dbname=*)
        DATABASE_NAME="${1#*=}"
        shift 1
        ;;
        -ch)
        CASSANDRA_HOST="$2"
        if [[ CASSANDRA_HOST == "" ]]; then break; fi
        shift 2
        ;;
        --chost=*)
        CASSANDRA_HOST="${1#*=}"
        shift 1
        ;;
        -cp)
        CASSANDRA_PORT="$2"
        if [[ CASSANDRA_PORT == "" ]]; then break; fi
        shift 2
        ;;
        --cport=*)
        CASSANDRA_PORT="${1#*=}"
        shift 1
        ;;
        -t)
        WAITFORIT_TIMEOUT="$2"
        if [[ $WAITFORIT_TIMEOUT == "" ]]; then break; fi
        shift 2
        ;;
        --timeout=*)
        WAITFORIT_TIMEOUT="${1#*=}"
        shift 1
        ;;
        --)
        shift
        _CLI=("$@")
        break
        ;;
        --help)
        usage
        ;;
        *)
        echo "Unknown argument: $1"
        usage
        ;;
    esac
done

if [[ "$CASSANDRA_HOST" == "" || "$CASSANDRA_PORT" == "" ]]; then
    echoerr "Error: you need to provide a cassandra host and port to test."
    usage
fi

wait_for()
{
    if [[ $WAITFORIT_TIMEOUT -gt 0 ]]; then
        echoerr "IMPORT_cmdname: waiting $WAITFORIT_TIMEOUT seconds for $CASSANDRA_HOST:$CASSANDRA_PORT"
    else
        echoerr "IMPORT_cmdname: waiting for $CASSANDRA_HOST:$CASSANDRA_PORT without a timeout"
    fi
    WAITFORIT_start_ts=$(date +%s)
    while :
    do
        if [[ $WAITFORIT_ISBUSY -eq 1 ]]; then
            nc -z $CASSANDRA_HOST $CASSANDRA_PORT
            WAITFORIT_result=$?
        else
            (echo > /dev/tcp/$CASSANDRA_HOST/$CASSANDRA_PORT) >/dev/null 2>&1
            WAITFORIT_result=$?
        fi
        if [[ $WAITFORIT_result -eq 0 ]]; then
            WAITFORIT_end_ts=$(date +%s)
            echoerr "IMPORT_cmdname: $CASSANDRA_HOST:$CASSANDRA_PORT is available after $((WAITFORIT_end_ts - WAITFORIT_start_ts)) seconds"
            break
        fi
        sleep 1
    done
    return $WAITFORIT_result
}

wait_for_wrapper()
{
    # In order to support SIGINT during timeout: http://unix.stackexchange.com/a/57692
    if [[ $WAITFORIT_QUIET -eq 1 ]]; then
        timeout $WAITFORIT_BUSYTIMEFLAG $WAITFORIT_TIMEOUT $0 --quiet --child --chost=$CASSANDRA_HOST --cport=$CASSANDRA_PORT --timeout=$WAITFORIT_TIMEOUT &
    else
        timeout $WAITFORIT_BUSYTIMEFLAG $WAITFORIT_TIMEOUT $0 --child --chost=$CASSANDRA_HOST --cport=$CASSANDRA_PORT --timeout=$WAITFORIT_TIMEOUT &
    fi
    WAITFORIT_PID=$!
    trap "kill -INT -$WAITFORIT_PID" INT
    wait $WAITFORIT_PID
    WAITFORIT_RESULT=$?
    if [[ $WAITFORIT_RESULT -ne 0 ]]; then
        echoerr "IMPORT_cmdname: timeout occurred after waiting $WAITFORIT_TIMEOUT seconds for $CASSANDRA_HOST:$CASSANDRA_PORT"
    fi
    return $WAITFORIT_RESULT
}

# execute a cql file as a string statement to cqlsh
_execute() {
	statement=$(<$1)
	until echo "$statement" | $CQLSH $CASSANDRA_HOST; do
		echo "cqlsh: Cassandra is unavailable - retry later"
		sleep 2
	done
}

# determing how to execute the file based on extension
_process_init_file() {
	local f="$1"; shift

	case "$f" in
 		*.sh)     echo "$0: running $f"; . "$f" ;;
		*.cql)    echo "$0: running $f"; _execute "$f"; echo ;;
		*.cql.gz) echo "$0: running $f"; gunzip -c "$f" | _execute; echo ;;
		*)        echo "$0: ignoring $f" ;;
	esac
}

_check_files() {
	until $CQLSH $CASSANDRA_HOST -e 'describe cluster'; do
		# processing the files in the data directory
		echo "Cassandra service is still starting up, waiting for it...";
		sleep 30
	done
	echo "Cassandra service ready, starting to import.";
	for f in $DATA_PATH/$DATABASE_NAME/*.cql; do
		echo "processing file $f"
		_process_init_file "$f"
	done
}


_load_data() {
    if [ "$DATABASE_NAME" ]
    then
        if [ -d "$DATA_PATH" ]
        then
            #cd $DATA_PATH/$DATABASE_NAME
            #Move the data to the folders
            for D in $DATA_PATH/$DATABASE_NAME/*
            do
              echo "Processing table $D"
              echo "command used $SSTABLELOADER -d $D"
              $SSTABLELOADER -d $CASSANDRA_HOST $D
            done
         fi
     fi
}

_remove_data_tmp(){
    if [ "$DATA_PATH/$DATABASE_NAME" ]
    then
        cd $DATA_PATH/
        echo "Removing $DATA_PATH"
        rm -rf *
    fi
}

_download_dump(){
    local dump="$1"

     echo "Downloading dump from $DOWNLOAD_HOST/cassandra/$dump.tar.gz ..."
     wget -q --no-cookies -O - "$DOWNLOAD_HOST/cassandra/$dump.tar.gz" \
     | tar xz --directory=$DATA_PATH -f -
     echo "Download finished!"
}


CQLSH=/usr/local/apache-cassandra-${CASSANDRA_VERSION}/bin/cqlsh
SSTABLELOADER=/usr/local/apache-cassandra-${CASSANDRA_VERSION}/bin/sstableloader
NODETOOL=/usr/local/apache-cassandra-${CASSANDRA_VERSION}/bin/nodetool



WAITFORIT_TIMEOUT=${WAITFORIT_TIMEOUT:-15}
WAITFORIT_STRICT=${WAITFORIT_STRICT:-0}
WAITFORIT_CHILD=${WAITFORIT_CHILD:-0}
WAITFORIT_QUIET=${WAITFORIT_QUIET:-0}

# check to see if timeout is from busybox?
WAITFORIT_TIMEOUT_PATH=$(type -p timeout)
WAITFORIT_TIMEOUT_PATH=$(realpath $WAITFORIT_TIMEOUT_PATH 2>/dev/null || readlink -f $WAITFORIT_TIMEOUT_PATH)

DATA_PATH=/var/tmp/data

if [[ ! -d "$DATA_PATH" ]]
then
    mkdir -p $DATA_PATH
fi

echo "Data path: $DATA_PATH"
echo "Cassandra Host: ${CASSANDRA_HOST}"

if [[ $WAITFORIT_TIMEOUT_PATH =~ "busybox" ]]; then
        WAITFORIT_ISBUSY=1
        WAITFORIT_BUSYTIMEFLAG="-t"
else
        WAITFORIT_ISBUSY=0
        WAITFORIT_BUSYTIMEFLAG=""
fi

if [[ $WAITFORIT_CHILD -gt 0 ]]; then
    wait_for
    WAITFORIT_RESULT=$?
    exit $WAITFORIT_RESULT
else
    if [[ $WAITFORIT_TIMEOUT -gt 0 ]]; then
        wait_for_wrapper
        WAITFORIT_RESULT=$?
    else
        wait_for
        WAITFORIT_RESULT=$?
    fi
fi



if [[ $WAITFORIT_RESULT -ne 0 && $WAITFORIT_STRICT -eq 1 ]]; then
    echoerr "$INPUT_cmdname: strict mode, refusing to execute subprocess"
    exit $WAITFORIT_RESULT
fi



if [[ "$_HOST" == "" || "$_PORT" == "" ]]; then
    echo "Error: you need to provide a host and port for the download server."
    usage
fi

if [[ "$DATABASE_NAME" == "" ]]; then
    echo "Error: you need to provide a database name."
    usage
fi

if [[ "$DATABASE_NAME" == "" ]]; then
    echo "Error: you need to specify the cassandra host. It can also be localhost."
    usage
fi

DOWNLOAD_HOST=$_HOST:$_PORT

echo "DOWNLOAD HOST: $DOWNLOAD_HOST"
echo "Database Name: $DATABASE_NAME"
echo "Data Path: $DATA_PATH"

command=`$CQLSH $CASSANDRA_HOST -e "use system_schema; select count(*) from keyspaces where keyspace_name='$DATABASE_NAME';"`

echo "Command to evaluate $command"

keyspace_exists=0
if [[ "$command" =~ 0 ]];
then
    keyspace_exists=0
else
    keyspace_exists=1
fi

echo "Keyspace exists? $keyspace_exists";

if [ $keyspace_exists == 0 ]
then
    # first test if the "data" directory exists and contains files
    if [ -d "$DATA_PATH" ]; then

        if [ ! -d "$DATA_PATH/$DATABASE_NAME" ]
        then
            if [ "$DATABASE_NAME" ] && [ "$DOWNLOAD_HOST" ]
            then
                _remove_data_tmp
                echo "Should download the data now..."
                _download_dump "$DATABASE_NAME"
            fi
        fi

        if [ ! -z "$(ls -A ${DATA_PATH})" ]; then
            # if there is an init-db.cql file, we probably want it to be executed first
            # I rename it because scripts are executed in alphabetic order

            if [ -e $DATA_PATH/$DATABASE_NAME/$DATABASE_NAME.cql ]
            then
                _check_files
            fi
            #Extract the data after the keyspace schema is created

            _load_data

            #Once the data is loaded successfully, remove the downloaded data from the temp folder.
            _remove_data_tmp
            if [ "$_CLI" ]
            then
                exec "${_CLI[@]}"
            fi
        fi
    fi
else
     if [ "$_CLI" ]
     then
        exec "${_CLI[@]}"
     fi
fi
