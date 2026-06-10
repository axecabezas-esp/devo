# --- ETAPA 1: Compilación del JAR (Build) ---
    FROM maven:3.9.6-eclipse-temurin-17-alpine AS build

    WORKDIR /app
    
    # Copiamos el archivo pom.xml para descargar dependencias
    COPY pom.xml .
    
    # Cacheamos las dependencias
    RUN mvn dependency:go-offline -B
    
    # Copiamos el código fuente del microservicio
    COPY src ./src
    
    # Compilamos omitiendo los tests
    RUN mvn clean package -DskipTests
    
    # --- ETAPA 2: Imagen de ejecución (Runtime) ---
    FROM eclipse-temurin:17-jre-alpine
    
    WORKDIR /app
    
    # Copiamos el .jar generado (basado en el nombre de tu artefacto en el pom.xml)
    COPY --from=build /app/target/Springboot-API-REST-DESPACHO-0.0.1-SNAPSHOT.jar app.jar
    
    # Exponemos el puerto por defecto de Spring Boot
    EXPOSE 8080
    
    # Ejecutamos la aplicación
    ENTRYPOINT ["java", "-jar", "app.jar"]