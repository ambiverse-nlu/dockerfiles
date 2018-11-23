#Dockerfile for NLU PostgreSQL Database

FROM postgres:9.4

MAINTAINER AmbiverseNLU <ambiversenlu-admmin@mpi-inf.mpg.de>

ENV POSTGRES_USER=ambiversenlu \
    POSTGRES_PASSWORD=ambiversenlu \
    DATA_PATH=/var/tmp/data

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
     wget \
  && mkdir -p ${DATA_PATH} \
  && chown -R postgres:postgres ${DATA_PATH}


VOLUME ${DATA_PATH}
COPY postgresql.conf.sample /usr/share/postgresql/postgresql.conf.sample

ADD 00-init-user-db.sh /docker-entrypoint-initdb.d/