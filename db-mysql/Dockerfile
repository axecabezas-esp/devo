FROM mysql:8.0

# Definimos variables de entorno por defecto (se pueden cambiar al correr el contenedor)
ENV MYSQL_ROOT_PASSWORD=rootpassword
ENV MYSQL_DATABASE=db_sistema
ENV MYSQL_USER=user_sistema
ENV MYSQL_PASSWORD=userpassword

COPY ./init.sql /docker-entrypoint-initdb.d/

EXPOSE 3306