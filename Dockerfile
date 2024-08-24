# Use an official Ruby runtime as a parent image
FROM ruby:3.0-slim

# Set the working directory in the container
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy the Gemfile and Gemfile.lock into the container
COPY Gemfile Gemfile.lock ./

# Install dependencies
RUN bundle install

# Copy the rest of the application code into the container
COPY . .

# Download GeoLite2 database during build
RUN mkdir -p /app/bin && \
    wget -O /app/bin/GeoLite2-City.mmdb.gz "https://cdn.jsdelivr.net/npm/geolite2-city@1.0.0/GeoLite2-City.mmdb.gz" && \
    gunzip -f /app/bin/GeoLite2-City.mmdb.gz

# Set environment variables
ENV RACK_ENV=production
ENV GEOIP_DB_PATH=/app/bin/GeoLite2-City.mmdb

# Expose the port the app runs on
EXPOSE 4567

# Start the application using Thin
CMD ["bundle", "exec", "dotenv", "thin", "start", "-p", "4567", "-e", "production"]