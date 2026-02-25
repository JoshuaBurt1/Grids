# Stage 1: Build Flutter using a pre-built image to save time/resources
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Ensure dependencies are resolved
RUN flutter pub get

# Build the web app in release mode (removes debug banner)
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:stable-alpine
# Copy the built web files to Nginx
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port 80 for Render
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]