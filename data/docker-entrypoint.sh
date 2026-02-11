#!/bin/bash

echo "Starting GeoIP Update Service..."
echo "Timezone: $(cat /etc/timezone)"
echo "Current time: $(date)"
echo ""

# Run initial update on container start
echo "Running initial database update..."
/usr/local/bin/geoip-update.sh

# Start cron in foreground
echo ""
echo "Starting cron daemon..."
echo "Cron schedule: Daily at 2:00 AM"
echo ""

# Start cron and tail the log file
cron && tail -f /var/log/cron.log /var/lib/geoip/download.log
