FROM maven:3.5.0-jdk-8

MAINTAINER AmbiverseNLU <ambiversenlu-admin@mpi-inf.mpg.de>

RUN java -version

WORKDIR /ambiverse-kg

RUN git clone https://github.com/ambiverse-nlu/ambiverse-kg.git /ambiverse-kg

RUN sed -i '/^log4j.appender.FILE.File=.*/c\log4j.appender.FILE.File=/ambiverse-kg/logs/ambiverse-kg.log' /ambiverse-kg/src/main/resources/log4j.properties

ENV MAVEN_OPTS -Djetty.port=8080 -Xmx12G -Dorg.eclipse.jetty.annotations.maxWait=180
ENTRYPOINT ["mvn", "jetty:run"]

EXPOSE 8080