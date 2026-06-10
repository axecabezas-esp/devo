# --- ETAPA 1: Compilación del JAR (Build) ---
    FROM maven:3.9.6-eclipse-temurin-17-alpine AS build

    WORKDIR /app
    
    # Copiamos el archivo de configuración de Maven (POM)
    COPY pom.xml .
    
    # Descargamos las dependencias necesarias en caché (optimiza futuras compilaciones)
    RUN mvn dependency:go-offline -B
    
    # Copiamos el código fuente del proyecto
    COPY src ./src
    
    # Compilamos el proyecto omitiendo los tests para acelerar el empaquetado de la imagen
    RUN mvn clean package -DskipTests
    
    # --- ETAPA 2: Imagen de ejecución (Runtime) ---
    FROM eclipse-temurin:17-jre-alpine
    
    WORKDIR /app
    
    # Copiamos el archivo .jar generado en la etapa anterior
    # Nota: Como el pom.xml define el artefacto de tu API, el jar compilado se llamará "Springboot-API-REST-0.0.1-SNAPSHOT.jar"
    COPY --from=build /app/target/Springboot-API-REST-0.0.1-SNAPSHOT.jar app.jar
    
    # Exponemos el puerto por defecto de Spring Boot
    EXPOSE 8080
    
    # Comando para ejecutar la aplicación
    ENTRYPOINT ["java", "-jar", "app.jar"]