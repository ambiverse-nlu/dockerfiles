#Dockerfile for KG Neo4j Database

FROM neo4j:3.4.9-enterprise

MAINTAINER AmbiverseNLU <ambiversenlu-admin@mpi-inf.mpg.de>

ENV DATA_PATH=/var/tmp/data

RUN apk add --no-cache --quiet \
    wget \
    python3 \
    && mkdir -p ${DATA_PATH} \
    && chown neo4j ${DATA_PATH}


VOLUME ${DATA_PATH}

COPY docker-entrypoint.sh /docker-entrypoint.sh