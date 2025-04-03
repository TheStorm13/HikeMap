FROM eclipse-temurin:17-jdk-jammy as builder
WORKDIR /app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline

COPY ./src ./src
RUN ./mvnw clean install -DskipTests

FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

COPY --from=builder /app/target/*.jar /app/app.jar

EXPOSE 8081
ENTRYPOINT ["java", "-jar", "/app/app.jar"]