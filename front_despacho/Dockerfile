# --- ETAPA 1: Construcción de la App ---
    FROM node:20-alpine AS build

    WORKDIR /app
    
    # Copiamos los archivos de dependencias
    COPY package*.json ./
    
    # Instalamos las dependencias
    RUN npm install
    
    # Copiamos el resto del código del proyecto
    COPY . .
    
    # Compilamos la aplicación para producción
    RUN npm run build
    
    # --- ETAPA 2: Servidor de Producción ---   
    FROM nginx:1.25-alpine
    
    # Copiamos los archivos estáticos compilados desde la etapa de build al directorio de Nginx
    COPY --from=build /app/dist /usr/share/nginx/html
    
    # Exponemos el puerto 80
    EXPOSE 80
    
    # Arrancamos Nginx
    CMD ["nginx", "-g", "daemon off;"]