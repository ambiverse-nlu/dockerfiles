# Supported tags and respective `Dockerfile` links

* latest [(latest/Dockerfile)](https://github.com/ambiverse-nlu/dockerfiles/blob/master/nlu-db-cassandra/Dockerfile)

# AmbiverseNLU Cassandra Database Dockerfile

This Dockerfile is an extension of the [cassandra:3.11](https://github.com/docker-library/cassandra/blob/4474c6c5cc2a81ee57c5615aae00555fca7e26a6/3.11/Dockerfile)
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
 ambiverse/nlu-db-cassandra
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
version: '3.1'

services:

  db:
    image: ambiverse/nlu-db-cassandra
    restart: always
    environment:
      DATABASE_NAME: aida_20180120_cs_de_en_es_ru_zh_v18

  nlu:
    image: ambiverse/ambiverse-nlu
    restart: always
    depends_on:
      - db
    ports:
      - 8080:8080
    environment:
      AIDA_CONF: aida_20180120_cs_de_en_es_ru_zh_v18_cass
~~~~~~~~

Run `docker stack deploy -c service-cassandra.yml cassandra` (or `docker-compose -f service-cassandra.yml up`), wait for it to initialize completely.

If you want to create a cluster of nodes, you can add another db service, and add the `CASSANDRA_SEEDS` env variable with values of both services, like this:

~~~~~~~~
version: '3.1'

services:

  db:
    image: ambiverse/nlu-db-cassandra
    restart: always
    environment:
      DATABASE_NAME: aida_20180120_2f_de_en_v18
      CASSANDRA_SEEDS: db,db1
  db1:
      image: ambiverse/nlu-db-cassandra
      restart: always
      environment:
        DATABASE_NAME: aida_20180120_2f_de_en_v18
        CASSANDRA_SEEDS: db,db1

  nlu:
    image: ambiverse/ambiverse-nlu
    restart: always
    depends_on:
      - db
      - db1
    ports:
      - 8080:8080
    environment:
      AIDA_CONF: aida_20180120_2f_de_en_v18_cass
~~~~~~~~