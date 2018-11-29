# Supported tags and respective `Dockerfile` links

* latest [(latest/Dockerfile)](https://github.com/ambiverse-nlu/dockerfiles/blob/master/nlu-db-postgres/Dockerfile)

# AmbiverseNLU PostgreSQL Database Dockerfile

This Dockerfile is an extension of the [postgres:9.4](https://github.com/docker-library/postgres/blob/3f585c58df93e93b730c09a13e8904b96fa20c58/9.4/Dockerfile) official docker image. It creates a database user specified by an environment variable (`ambiversenlu` by default), downloads the specified database dump and restores the database from the dump. With this image you are ready to use the [AmbiverseNLU](https://github.com/ambiverse-nlu/ambiverse-nlu) service with PostgreSQL database.

## Environment Variables
This image has several environment variables that need to be setup. Besides the environment variables from the [original image](https://hub.docker.com/_/postgres/) that can be setup and are optional, some the following environment variables are mandatory. 

### POSTGRES_DB
This environment variable is used to define a name for the database that is created when the image is first started. 

This environmental variable is also used to define the name of the database dump.  
The name must be chosen from the following list of dumps:


- **[aida_20180120_cs_de_en_es_ru_zh_v18](http://ambiversenlu-download.mpi-inf.mpg.de/postgres/aida_20180120_cs_de_en_es_ru_zh_v18.sql.gz)** - full database dump extracted from YAGO (Wikipedia dump from 20180120) in six languages (czech, german, english, spanish, russian and chinese).
- **[aida_20180120_b3_de_en_v18](http://ambiversenlu-download.mpi-inf.mpg.de/postgres/aida_20180120_b3_de_en_v18.sql.gz)** - a sample database containing companies in the DJIA and related entities.

### POSTGRES_USER
This optional environment variable is used in conjunction with `POSTGRES_PASSWORD` to set a user that will be the owner of the schema defined in the database dump. 
If you don't set it up, the default user is `ambiversenlu`.

### POSTGRES_PASSWORD
This environmental variable sets the password for the user `POSTGRES_USER`. If you don't set it up, the default user is `ambiversenlu`.

## Running the image
To run the image as a standalone database server:
~~~~~~~~
docker run -d --restart=always --name nlu-db-postgres \
  -p 5432:5432 \
  -e POSTGRES_DB=aida_20180120_cs_de_en_es_ru_zh_v18 \
  -e POSTGRES_USER=ambiversenlu \
  -e POSTGRES_PASSWORD=ambiversenlu \
  ambiverse/nlu-db-postgres
~~~~~~~~

## Connecting it from the Entity Linking container
To run the image from and connect it to directly with the [AmbiverseNLU](https://github.com/ambiverse-nlu/ambiverse-nlu) service you can do it in the following two ways:

~~~~~~~~
docker run -d --restart=always --name ambiverse-nlu \
 -p 8080:8080 \
 --link nlu-db-postgres:db \
 -e POSTGRES_DB=aida_20180120_cs_de_en_es_ru_zh_v18 \
 -e POSTGRES_USER=ambiversenlu \
 -e POSTGRES_PASSWORD=ambiversenlu \
 -e AIDA_CONF=aida_20180120_cs_de_en_es_ru_zh_v18_db \
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

Run docker stack deploy -c service-postgres.yml postgres (or docker-compose -f service-postgres.yml up), wait for it to initialize completely.

## Advanced Database Configuration.
There are many ways to configure the PostgreSQL database server. There is a whole section in the official PostgreSQL docker image [page](https://hub.docker.com/_/postgres/).
We are copying a `postgresql.conf.sample` over to `/usr/share/postgresql/postgresql.conf.sample`. 
If you want to extend this configurations, you can link the file [postgresql.conf.sample](https://github.com/ambiverse-nlu/dockerfiles/blob/master/nlu-db-postgres/postgresql.conf.sample) in your docker run by adding it as a volume:
~~~~~~~~
docker run -d --restart=always --name nlu-db-postgres \
  -p 5432:5432 \
  -e POSTGRES_DB=aida_20180120_cs_de_en_es_ru_zh_v18 \
  -e POSTGRES_USER=ambiversenlu \
  -e POSTGRES_PASSWORD=ambiversenlu \
  -v "$PWD/postgresql.conf.sample":/usr/share/postgresql/postgresql.conf.sample \
  ambiverse/nlu-db-postgres
~~~~~~~~