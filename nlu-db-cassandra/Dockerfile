#Dockerfile for NLU Cassandra Database
FROM cassandra:3.11.4

MAINTAINER Ambiverse <ambiversenlu-admin@mpi-inf.mpg.de>

ENV DATA_PATH=/var/tmp/data

#Download the database dump and put it in the /var/tmp directory.
RUN export DEBIAN_FRONTEND=noninteractive \
  && mkdir -p ${DATA_PATH} \
  && chown cassandra ${DATA_PATH}

VOLUME ${DATA_PATH}

COPY ready-probe.sh /ready-probe.sh
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
     wget


