# Arguments
ARG SDK_VERSION=8.0
ARG APP_DLL_NAME=mica.codes.dll

# Stage 1: Build the ASP.NET Core application
FROM mcr.microsoft.com/dotnet/sdk:$SDK_VERSION AS build
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

# Stage 2: Create the runtime image
FROM mcr.microsoft.com/dotnet/aspnet:$SDK_VERSION
WORKDIR /app
COPY --from=build /app/out ./

# Expose the application port
EXPOSE 5000

# Start the application
ENTRYPOINT ["dotnet", "$APP_DLL_NAME"]

# Stage 3: Nginx for reverse proxy
FROM nginx:alpine AS nginx_stage

# Copy the Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy the static assets if any.
#COPY ./wwwroot /var/www/html #Uncomment and change if you have static files.

# Expose Nginx port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]

# Stage 4: Multi-stage build to copy aspnet app and nginx config into final image.
FROM alpine:latest
RUN apk update && apk add --no-cache ca-certificates

COPY --from=1 /app .
COPY --from=nginx_stage /etc/nginx/nginx.conf /etc/nginx/nginx.conf
#COPY --from=nginx_stage /var/www/html /var/www/html #Uncomment if you have static files.
COPY --from=nginx_stage /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx_stage /usr/lib/nginx/modules /usr/lib/nginx/modules
COPY --from=nginx_stage /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 80

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
