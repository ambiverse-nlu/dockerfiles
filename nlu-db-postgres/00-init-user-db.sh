#!/bin/bash
set -e

echo "*** CREATING DATABASE ***"

PGPASSWORD="$POSTGRES_PASSWORD"

cd $DATA_PATH

echo "Downloading database dump from http://ambiversenlu-download.mpi-inf.mpg.de/postgres/${POSTGRES_DB}.sql.gz ..."
wget -q --no-cookies -O ${POSTGRES_DB}.sql.gz "http://ambiversenlu-download.mpi-inf.mpg.de/postgres/${POSTGRES_DB}.sql.gz"

echo "Download finished!"

echo "Restore file ${DATA_PATH}/${POSTGRES_DB}.sql.gz"



gunzip -c "${DATA_PATH}/${POSTGRES_DB}.sql.gz" | psql -v -U "$POSTGRES_USER"  --dbname "$POSTGRES_DB"

echo "*** DATABASE IMPORTED ***"
