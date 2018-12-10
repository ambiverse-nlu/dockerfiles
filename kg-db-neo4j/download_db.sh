#!/bin/sh
NEO4J_HOME=/var/lib/neo4j
CONF=${NEO4J_HOME}/conf/neo4j.conf


if [ ! -d "/data/databases/${DUMP_NAME}.db" ]
then
    echo "Database does not exist"
    echo "Downloading dump from http://ambiversenlu-download.mpi-inf.mpg.de/neo4j/${DUMP_NAME}.tar.gz to ${DATA_PATH}..."

    wget -q --no-cookies -O - "http://ambiversenlu-download.mpi-inf.mpg.de/neo4j/${DUMP_NAME}.tar.gz" \
    | tar xz --directory=${DATA_PATH} -f -
    echo "Download finished!"

    nodes_rels=$(cat ${DATA_PATH}/${DUMP_NAME}/import_script.txt | sed 's:YAGOOUTPUTPATH:'"${DATA_PATH}/${DUMP_NAME}"':g' | sed 's:"::g')

    su-exec neo4j $NEO4J_HOME/bin/neo4j-admin import \
    --mode=csv \
    --ignore-missing-nodes true \
    --ignore-duplicate-nodes true \
    --delimiter TAB \
    --multiline-fields=true \
    --database ${DUMP_NAME}.db \
    $nodes_rels

    cd $NEO4J_HOME

    echo 'dbms.security.procedures.unrestricted=apoc.*,algo.*' >> $CONF
    #echo 'dbms.security.auth_enabled=false' >> $CONF
    echo 'browser.remote_content_hostname_whitelist=*' >> $CONF

    echo "Removing the dump";
    rm -rf ${DATA_PATH}/${DUMP_NAME}

else
    echo "Database ${DUMP_NAME}.db already exists"
fi


