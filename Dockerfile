FROM maven:3-eclipse-temurin-17 as builder

WORKDIR /app

COPY .mvn .mvn
COPY mvnw .
COPY pom.xml .
RUN mvn dependency:resolve

COPY src src

ENV JDBC_URL="jdbc:postgresql://localhost:5432/db?user=app&password=pass"
RUN mvn verify

FROM postgres:14 as base

RUN apt-get update \
    && apt-get install curl -y \
    && rm -rf /var/lib/apt/lists/*


FROM base as final

ENV JDBC_URL="jdbc:postgresql://localhost:5432/db?user=app&password=pass"
ENV PATH=/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/postgresql/14/bin
ENV POSTGRES_PASSWORD=pass
ENV POSTGRES_USER=app
ENV POSTGRES_DB=db

COPY --from=builder /app/target/app.jar /app.jar
COPY --from=builder /opt/java/openjdk /opt/java/openjdk
COPY --chmod=777 app-entrypoint.sh /usr/local/bin/app-entrypoint.sh

EXPOSE 5432
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/app-entrypoint.sh"]

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl --silent --fail http://localhost:8080/actuator/health || exit 1