# Supported tags and respective `Dockerfile` links

* latest [(latest/Dockerfile)](https://github.com/ambiverse-nlu/dockerfiles/blob/master/nlu-db-cassandra/Dockerfile)

# AmbiverseNLU Cassandra Database Dockerfile

This Dockerfile is an extension of the [cassandra:3.11.4](https://github.com/docker-library/cassandra/blob/f98d3fc5282a99cdfe1ec8aa808d6313080137c0/3.11/Dockerfile)
official docker image. It extends the `docker-endpoint.sh` script from the [this](https://github.com/emschimmel/cassandra/blob/master/3.11/docker-entrypoint.sh) pull-request 
that allows initializing the image with `*.cql` dumps.  With this image you are ready to use the [AmbiverseNLU](https://github.com/ambiverse-nlu/ambiverse-nlu) service with Cassandra database.

This image shows how to setup a single node cassandra database populated with the Entity Linking database. If you want to make a cassandra cluster, please
have a look at the official cassandra docker [documentation](https://hub.docker.com/_/cassandra/).

## Environment Variables
This image has several environment variables that need to be setup. Besides the environment variables from the [original image](https://hub.docker.com/_/cassandra/)
that can be setup and are optional, some the following environment variables are mandatory. 

### DATABASE_NAME
This environmental variable is used to define the name of the database and the database dump that is automatically downloaded.  
The name must be chosen from the following list of dumps:

- **[aida_20180120_cs_de_en_es_ru_zh_v18](http://ambiversenlu-download.mpi-inf.mpg.de/cassandra/aida_20180120_cs_de_en_es_ru_zh_v18.tar.gz)** - full database dump extracted from YAGO (Wikipedia dump from 20180120) in six languages (czech, german, english, spanish, russian and chinese).
- **[aida_20180120_b3_de_en_v18](http://ambiversenlu-download.mpi-inf.mpg.de/cassandra/aida_20180120_b3_de_en_v18.tar.gz)** - a sample database containing companies in the DJIA and related entities.


## Running the image
To run the image as a standalone database server:
~~~~~~~~
docker run -d --restart=always --name nlu-db-cassandra \
 -p 7000:7000 \
 -p 7001:7001 \
 -p 9042:9042 \
 -p 7199:7199 \
 -p 9160:9160 \
 -e DATABASE_NAME=aida_20180120_cs_de_en_es_ru_zh_v18 \
 ambiverse/nlu-db-cassandra:3.11.4
~~~~~~~~

## Connecting it from the AmbiverseNLU container
To run the image from and connect it to directly with the [AmbiverseNLU](https://github.com/ambiverse-nlu/ambiverse-nlu) service you can do it in the following two ways:



Then start the AmbiverseNLU container by linking the running Cassandra container.
~~~~~~~~
docker run -d --restart=always --name ambiverse-nlu \
 -p 8080:8080 \
 --link nlu-db-cassandra:db \
 -e AIDA_CONF=aida_20180120_cs_de_en_es_ru_zh_v18_cass \
 ambiverse/ambiverse-nlu
~~~~~~~~

### ... or via `docker-stack deploy` or `docker-compose`
Example service-cassandra.yml for [AmbiverseNLU](https://github.com/ambiverse-nlu/ambiverse-nlu):
~~~~~~~~
version: '3.6'

services:
  cassandra:
    image: ambiverse/nlu-cassandra-cassandra:3.11.4
    restart: always
    deploy:
      resources:
        limits:
          memory: 32G
      restart_policy:
        condition: on-failure
        max_attempts: 3
        window: 120s
    environment:
      DATABASE_NAME: aida_20180120_cs_de_en_es_ru_zh_v18
      MAX_HEAP_SIZE: 16G
      HEAP_NEWSIZE: 800M
    volumes:
      - "cassandra_data:/var/lib/cassandra"
    networks:
      nlunet:
        aliases:
          - nlu-cassandra
    healthcheck:
      test: /bin/bash -c /ready-probe.sh || exit 1
      interval: 1m
      timeout: 10s
      retries: 10
      start_period: 60s
  nlu:
    image: ambiverse/ambiverse-nlu
    restart: always
    ports:
      - 8080:8080
    environment:
      AIDA_CONF: aida_20180120_cs_de_en_es_ru_zh_v18_cass
      DATABASE: aida_20180120_cs_de_en_es_ru_zh_v18
      DOWNLOAD_HOST: http://ambiversenlu-download.mpi-inf.mpg.de/
    entrypoint: [ "/cassandra-init.sh", "http://ambiversenlu-download.mpi-inf.mpg.de/", "-d", "aida_20180120_cs_de_en_es_ru_zh_v18", "-ch", "nlu-cassandra", "-cp","9042", "-s", "-t", "720", "--", "mvn", "jetty:run" ]
    deploy:
      replicas: 1
        resources:
          limits:
            memory: 44G
    volumes:
      - "nlu-caches:/var/lib/jetty/caches/aida_20180120_cs_de_en_es_ru_zh_v18_cass/"
      - "nlu-logs:/var/lib/jetty/logs"
      - type: tmpfs
        target: /var/tmp/data
        tmpfs:
        size: 107374182400
    networks:
      - nlunet
    healthcheck:
      test: curl -sS http://127.0.0.1:8080/v2/entitylinking/analyze/_status || exit 1
      interval: 60s
      timeout: 60s
      retries: 10
      start_period: 5m

volumes:
  cassandra_data:
  nlu-caches:
  nlu-logs:

networks:
  nlunet:
~~~~~~~~

Run `docker stack deploy -c service-cassandra.yml cassandra` (or `docker-compose -f service-cassandra.yml up`), wait for it to initialize completely.
