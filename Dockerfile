# Stage 1: Build Flutter
FROM debian:latest AS build-env

RUN apt-get update && apt-get install -y curl git wget unzip xz-utils libglu1-mesa
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter doctor
WORKDIR /app
COPY . .
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:stable-alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]