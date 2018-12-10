# Supported tags and respective `Dockerfile` links

* latest [(latest/Dockerfile)](https://github.com/ambiverse-nlu/dockerfiles/blob/master/ambiverse-kg/Dockerfile)
* 1.0.0 [(1.0.0/Dockerfile)](https://github.com/ambiverse-nlu/dockerfiles/blob/master/ambiverse-kg/1.0.0/Dockerfile)
      
# AmbiverseNLU Knowledge Graph Dockerfile
This docker images is the official image of the [AmbiverseNLU KG](https://github.com/ambiverse-nlu/ambiverse-kg) project.
The image contains the full repository of the code, and it starts a jetty webservice on `8080` port.

## Starting with `docker run`
If you want to start the container and link it to the `kg-db-neo4j` docker container that has the YAGO database dump in Neo4j you need to the the following.
First start the Neo4j docker container that contains the database dump:

~~~~~~~~
docker run -d --restart=always --name kg-db-neo4j \
	-p 7474:7474 -p 7687:7687 \
	-e NEO4J_dbms_active__database=yago_aida_en20180120_cs20180120_de20180120_es20180120_ru20180120_zh20180120.db \
	-e NEO4J_dbms_memory_pagecache_size=50G \
	-e NEO4J_dbms_memory_heap_initial__size=20G \
	-e NEO4J_dbms_memory_heap_max__size=20G \
	-e NEO4J_dbms_connectors_default__listen__address=0.0.0.0 \
	-e NEO4J_dbms_security_procedures_unrestricted=apoc.* \
	-e NEO4J_AUTH=neo4j/neo4j_pass \
	-e DUMP_NAME=yago_aida_en20180120_cs20180120_de20180120_es20180120_ru20180120_zh20180120 \
	--ulimit=nofile=40000:40000 \
	-v $HOME/neo4j/data:/data \
	ambiverse/kg-db-neo4j
~~~~~~~~

&nbsp;

Then start the AmbiverseNLU Knowledge Graph container by linking the running Neo4j container.
~~~~~~~~
docker run -d --restart=always --name ambiverse-kg \
 -p 8080:8080 \
 --link kg-db-neo4j:kg-db \
 ambiverse/ambiverse-kg
~~~~~~~~


### ... or via `docker-stack deploy` or `docker-compose`
Example service-kg.yml for [AmbiverseNLU KG](https://github.com/ambiverse-nlu/ambiverse-kg):
~~~~~~~~
version: '3.1'

services:

  kg-db:
    image: ambiverse/kg-db-neo4j
    restart: always
    environment:
      DUMP_NAME: yago_aida_en20180120_cs20180120_de20180120_es20180120_ru20180120_zh20180120
      NEO4J_dbms_active__database: yago_aida_en20180120_cs20180120_de20180120_es20180120_ru20180120_zh20180120.db
      NEO4J_dbms_memory_pagecache_size: 8G
      NEO4J_dbms_memory_heap_initial__size: 8G
      NEO4J_dbms_memory_heap_max__size: 12G
      NEO4J_dbms_connectors_default__listen__address: 0.0.0.0
      NEO4J_dbms_security_procedures_unrestricted: apoc.*
      NEO4J_AUTH: neo4j/neo4j_pass
    ulimits:
        nofile:
            40000:40000
    volumes:
       - $HOME/neo4j/data:/data                    

  kg:
    image: ambiverse/ambiverse-kg
    restart: always
    depends_on:
      - kg-db
    ports:
      - 8080:8080
~~~~~~~~

&nbsp;

Run `docker stack deploy -c service-postgres.yml cassandra` (or `docker-compose -f service-postgres.yml up`), wait for it to initialize completely.


## Running a custom configuration
If you want to run a custom configuration, i.e. you have a running database server which is not a docker container, you can create a `neo4j.properties` files yourself, and link the file. 
For example, you have neo4j running one real servers or another machine that uses different username and password that the default, and you want the service to use this neo4j, you create the file `neo4j.properties` and mount the file as a docker volume with the following command:

~~~~~~~~
docker run -d --restart=always --name ambiverse-kg \
 -p 8080:8080 \
 --link kg-db-neo4j:kg-db \
 -v $(pwd)/neo4j.properties:/ambiverse-kg/src/main/resources/default/neo4j.properties \
 ambiverse/ambiverse-kg
~~~~~~~~