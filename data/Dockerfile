FROM ubuntu:22.04

# Set environment to non-interactive to avoid prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    curl \
    cron \
    tzdata \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set timezone (change as needed)
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create directory for GeoIP databases
RUN mkdir -p /var/lib/geoip

# Copy the update script
COPY ./geoip_update.sh /usr/local/bin/geoip_update.sh
RUN chmod +x /usr/local/bin/geoip_update.sh

# Copy entrypoint script
COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create cron job file
RUN echo "0 0 * * * /usr/local/bin/geoip_update.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/geoip-cron && \
    echo "" >> /etc/cron.d/geoip-cron && \
    chmod 0644 /etc/cron.d/geoip-cron && \
    crontab /etc/cron.d/geoip-cron && \
    touch /var/log/cron.log

# Create volume for database files
VOLUME ["/var/lib/geoip"]

# Set working directory
WORKDIR /var/lib/geoip

# Run the entrypoint script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
