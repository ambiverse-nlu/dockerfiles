#Dockerfile for AmbiverseNLU KG Neo4j Database

FROM neo4j:3.5.4

MAINTAINER AmbiverseNLU <ambiversenlu-admin@mpi-inf.mpg.de>

ENV DATA_PATH=/var/tmp/data

RUN apk add --no-cache --quiet \
    wget \
    && mkdir -p ${DATA_PATH} \
    && chown neo4j ${DATA_PATH}

#Make the datapath as a separate volume
VOLUME ${DATA_PATH}

#Add the apoc plugin
ADD https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/3.5.0.1/apoc-3.5.0.1-all.jar /var/lib/neo4j/plugins/
ADD https://github.com/neo4j-contrib/neo4j-graph-algorithms/releases/download/3.5.0.1/graph-algorithms-algo-3.5.0.1.jar /var/lib/neo4j/plugins/

COPY download_db.sh /download_db.sh

ENV EXTENSION_SCRIPT /download_db.sh
ENV NEO4J_AUTH=neo4j/neo4j_pass
