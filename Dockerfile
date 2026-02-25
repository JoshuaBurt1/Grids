# Stage 1: Build Flutter
FROM debian:latest AS build-env

# Install essential tools and dependencies for Flutter Web
RUN apt-get update && apt-get install -y \
    curl git wget unzip xz-utils libglu1-mesa python3 \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter stable branch
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Fix for "dubious ownership" in Git and pre-download web artifacts
RUN git config --global --add safe.directory /usr/local/flutter \
    && flutter doctor \
    && flutter precache --web

WORKDIR /app
COPY . .

# Run the build with the pub get command included to ensure dependencies are resolved
RUN flutter pub get \
    && flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:stable-alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]