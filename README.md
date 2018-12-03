# AmbiverseNLU Dockerfiles

This project contains all the official Docker files of the AmbiverseNLU modules. The files here are built from sources in [ambiverse-nlu](https://github.com/ambiverse-nlu/), for support please create an issue in the corresponding repository.

Here are the supported Dockerfiles:

* [AmbiverseNLU](ambiverse-nlu) -- The Ambiverse Natural Language Understanding suite (AmbiverseNLU) Dockerfile that exposes a number of state-of-the-art components for language understanding tasks as a web service. Read more [here](https://github.com/ambiverse-nlu/ambiverse-nlu).
* [NLU PostgreSQL Database](nlu-db-postgres) -- A Dockerfile for the PostgreSQL dump of the AmbiverseNLU database.
* [NLU Cassandra Database](nlu-db-cassandra) -- A Dockerfile for the Cassandra dump of the AmbiverseNLU database.
* [Ambiverse KG](ambiverse-kg) -- The AmbiverseNLU Knowledge Graph web service allows you to search and query the [YAGO](http://yago-knowledge.org) Knowledge Graph (imported to Neo4j).
* [KG Neo4j Database](kg-db-neo4j) -- A Dockerfile for the AmbiverseNLU Knowledge Graph database dump in Neo4j Graph Database.