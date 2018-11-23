# Supported tags and respective `Dockerfile` links

* latest [(latest/Dockerfile)](https://github.com/ambiverse-nlu/dockerfiles/ambiverse-nlu/Dockerfile)

# AmbiverseNLU Dockerfile
This docker images is the official image of the [AmbiverseNLU](https://github.com/ambiverse-nlu/nlu) project.
The image contains the full repository of the code, and it starts a jetty webservice on `8080` port.

## Environment Variables
This image has one environment variable that need to be setup. 

### AIDA_CONF
This environmental variable is used to define the configuration used by the running webservice. 
There are two types of configuration depending on the database (postgres or cassandra), and they start with the database name and have an ending `_db` or `_cass` correspondingly. The configuration used it tightly connected with the database dump. 

These are the available configuration for the webservice:

* aida_20180120_cs_de_en_es_ru_zh_v18_db
* aida_20180120_cs_de_en_es_ru_zh_v18_cass
* aida_20180120_cs_de_en_es_ru_zh_v18_cass_2
* aida_20180120_b3_de_en_v18_db
* aida_20180120_b3_de_en_v18_cas
* default 

## Starting with `docker run`
If you want to start the container and link it to the `nlu-db-postgres` docker container that has the PostgreSQL database dump you need to the the following.
First start the PostreSQL docker container that contains the database dump:

~~~~~~~~
docker run -d --restart=always \
  --name nlu-db-postgres \
  -e POSTGRES_DB=aida_20180120_cs_de_en_es_ru_zh_v18 \
  -e POSTGRES_USER=ambiversenlu \
  -e POSTGRES_PASSWORD=ambiversenlu \
  ambiverse/nlu-db-postgres
~~~~~~~~

Then start the AmbiverseNLU container by linking the running PostgreSQL container.
~~~~~~~~
docker run -d --restart=always \ 
 --name ambiverse-nlu \
 -p 8080:8080 \
 --link nlu-db-postgres:db \
 -e POSTGRES_DB=aida_20180120_cs_de_en_es_ru_zh_v18 \
 -e POSTGRES_USER=ambiversenlu \
 -e POSTGRES_PASSWORD=ambiversenlu \
 -e AIDA_CONF=aida_20180120_cs_de_en_es_ru_zh_v18_db \
 ambiverse/ambiverse-nlu
~~~~~~~~

Similarly for Cassandra, first start the Cassandra container that contains the database dump:

~~~~~~~~
docker run -d --restart=always \
 --name nlu-db-cassandra \
 -e DATABASE_NAME=aida_20180120_cs_de_en_es_ru_zh_v18 \
 ambiverse/nlu-db-cassandra
~~~~~~~~


~~~~~~~~
docker run -d --restart=always \
 --name ambiverse-nlu \
 -p 9081:8080 \
 --link nlu-db-cassandra:db \
 -e DATABASE_NAME=aida_20180120_cs_de_en_es_ru_zh_v18 \
 -e AIDA_CONF=aida_20180120_cs_de_en_es_ru_zh_v18_cass \
 ambiverse/ambiverse-nlu
~~~~~~~~



### ... or via `docker-stack deploy` or `docker-compose`
Example service-postgres.yml for [AmbiverseNLU](https://github.com/ambiverse-nlu/ambiverse-nlu):
~~~~~~~~
version: '3.1'

services:

  db:
    image: ambiverse/nlu-db-postgres
    restart: always
    environment:
      POSTGRES_PASSWORD: ambiversenlu
      POSTGRES_DB: aida_20180120_cs_de_en_es_ru_zh_v18
      POSTGRES_USER: ambiversenlu
      
  nlu:
    image: ambiverse/ambiverse-nlu
    restart: always
    depends_on:
      - db
    ports:
      - 8080:8080
    environment:
      AIDA_CONF: aida_20180120_cs_de_en_es_ru_zh_v18_db
~~~~~~~~
Run `docker stack deploy -c service-postgres.yml cassandra` (or `docker-compose -f service-postgres.yml up`), wait for it to initialize completely.

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
      DATABASE_NAME: aida_20180120_cs_de_en_es_ru_zh_v18
      CASSANDRA_SEEDS: db,db1
  db1:
      image: ambiverse/nlu-db-cassandra
      restart: always
      environment:
        DATABASE_NAME: aida_20180120_cs_de_en_es_ru_zh_v18
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
      AIDA_CONF: aida_20180120_cs_de_en_es_ru_zh_v18_cass
~~~~~~~~