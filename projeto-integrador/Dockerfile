# ── Build ────────────────────────────────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Baixa dependências antes de copiar o código-fonte (aproveita cache de camadas)
COPY pom.xml .
RUN mvn dependency:go-offline -q

#gera jar do projeto 
COPY src ./src
RUN mvn package -DskipTests -q  

# ── Runtime ───────────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

COPY --from=build /app/target/polivisitas-api-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
