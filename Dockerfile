# Use the official PostgreSQL image from the Docker Hub
FROM postgres:14

# Install PostGIS
RUN apt-get update && \
    apt-get install -y postgis postgresql-14-postgis-3

# Add the database initialization script
COPY hospital_schema.sql /docker-entrypoint-initdb.d/

# Expose the default PostgreSQL port
EXPOSE 5432