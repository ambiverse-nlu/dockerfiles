#Dockerfile for NLU Cassandra Database

FROM cassandra:3.11

MAINTAINER Ambiverse <ambiversenlu-admin@mpi-inf.mpg.de>

ENV DATA_PATH=/var/tmp/data

#Download the database dump and put it in the /var/tmp directory.
RUN export DEBIAN_FRONTEND=noninteractive \
  && mkdir -p ${DATA_PATH} \
  && chown cassandra ${DATA_PATH}

VOLUME ${DATA_PATH}

# Copy the custom docker-entrypoint.sh script.
# The script is taken from https://github.com/emschimmel/cassandra/blob/master/3.11/docker-entrypoint.sh
# and allows to execute eny cql files loaded in the /data directory.
COPY docker-entrypoint.sh /usr/local/bin/

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
     wget


