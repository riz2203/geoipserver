#!/bin/bash
#############################################
# MaxMind GeoIP Database Download Script
# Downloads database only when updated
#############################################


##############################################################
# Configuration - Get from environment variables with defaults
##############################################################
ACCOUNT_ID="${MAXMIND_ACCOUNT_ID:-YOUR_ACCOUNT_ID}"
LICENSE_KEY="${MAXMIND_LICENSE_KEY:-YOUR_LICENSE_KEY}"
DATABASE_URL="${MAXMIND_DATABASE_URL:-https://download.maxmind.com/geoip/databases/GeoLite2-Country/download?suffix=tar.gz}"
DOWNLOAD_DIR="${GEOIP_DIR:-/var/lib/geoip}"
TIMESTAMP_FILE="${DOWNLOAD_DIR}/last_modified"
LOG_FILE="${DOWNLOAD_DIR}/download.log"
SYMLINK_NAME="GeoLite2-Country.mmdb"

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

##############################
# Function to log messages
##############################
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

###########################################################
# Function to get Last-Modified header from remote database
###########################################################
get_remote_date() {
    curl -sI -L -u "${ACCOUNT_ID}:${LICENSE_KEY}" "$DATABASE_URL" | \
        grep -i "^Last-Modified:" | \
        sed 's/Last-Modified: //i' | \
        tr -d '\r'
}

# Function to convert date string to epoch seconds
date_to_epoch() {
    date -d "$1" +%s 2>/dev/null || date -j -f "%a, %d %b %Y %H:%M:%S %Z" "$1" +%s 2>/dev/null
}

##################################
# Function to extract tar.gz file
#################################
extract_database() {
    log "Extracting database files..."
    
    cd "$DOWNLOAD_DIR" || exit 1
    
    # Find the most recent tar.gz file
    TARFILE=$(ls -t GeoLite2-Country_*.tar.gz 2>/dev/null | head -n 1)
    
    if [ -z "$TARFILE" ]; then
        log "ERROR: No tar.gz file found to extract"
        return 1
    fi
    
    log "Extracting: $TARFILE"
    
    # Extract the tar.gz file
    if tar -xzf "$TARFILE"; then
        log "Extraction successful"
        
        # Find the extracted directory
        EXTRACTED_DIR=$(tar -tzf "$TARFILE" | head -1 | cut -f1 -d"/")
        
        if [ -d "$EXTRACTED_DIR" ]; then
            log "Extracted to directory: $EXTRACTED_DIR"
            
            # Create/update symlink to the .mmdb file
            MMDB_FILE="${EXTRACTED_DIR}/${SYMLINK_NAME}"
            
            if [ -f "$MMDB_FILE" ]; then
                # Remove old symlink if it exists
                if [ -L "$SYMLINK_NAME" ]; then
                    log "Removing old symlink: $SYMLINK_NAME"
                    rm -f "$SYMLINK_NAME"
                fi
                
                # Create new symlink
                log "Creating symlink: $SYMLINK_NAME -> $MMDB_FILE"
                ln -sf "$MMDB_FILE" "$SYMLINK_NAME"
                
                if [ $? -eq 0 ]; then
                    log "Symlink created successfully"
                    log "Applications can now use: ${DOWNLOAD_DIR}/${SYMLINK_NAME}"
                else
                    log "ERROR: Failed to create symlink"
                    return 1
                fi
            else
                log "ERROR: Database file not found: $MMDB_FILE"
                return 1
            fi
            
            # Clean up old extracted directories (keep only the 2 most recent)
            OLD_DIRS=$(ls -td GeoLite2-Country_*/ 2>/dev/null | tail -n +3)
            if [ -n "$OLD_DIRS" ]; then
                echo "$OLD_DIRS" | while read -r dir; do
                    log "Removing old directory: $dir"
                    rm -rf "$dir"
                done
            fi
            
            # Clean up old tar.gz files (keep only the 2 most recent)
            OLD_ARCHIVES=$(ls -t GeoLite2-Country_*.tar.gz 2>/dev/null | tail -n +3)
            if [ -n "$OLD_ARCHIVES" ]; then
                echo "$OLD_ARCHIVES" | while read -r file; do
                    log "Removing old archive: $file"
                    rm -f "$file"
                done
            fi
        else
            log "WARNING: Could not find extracted directory"
            return 1
        fi
        
        return 0
    else
        log "ERROR: Extraction failed"
        return 1
    fi
}

####################################
# Function to download the database
####################################
download_database() {
    log "Downloading database..."
    
    cd "$DOWNLOAD_DIR" || exit 1
    
    if curl -O -J -L -u "${ACCOUNT_ID}:${LICENSE_KEY}" "$DATABASE_URL"; then
        log "Download completed successfully"
        
        # Extract the downloaded file
        if extract_database; then
            echo "$1" > "$TIMESTAMP_FILE"
            return 0
        else
            log "ERROR: Extraction failed but download succeeded"
            return 1
        fi
    else
        log "ERROR: Download failed"
        return 1
    fi
}

######################
# Main script
######################
log "Checking for database updates..."

# Validate credentials
if [ "$ACCOUNT_ID" = "YOUR_ACCOUNT_ID" ] || [ "$LICENSE_KEY" = "YOUR_LICENSE_KEY" ]; then
    log "ERROR: MaxMind credentials not configured!"
    log "Please set MAXMIND_ACCOUNT_ID and MAXMIND_LICENSE_KEY environment variables"
    exit 1
fi

# Get remote Last-Modified date
REMOTE_DATE=$(get_remote_date)

if [ -z "$REMOTE_DATE" ]; then
    log "ERROR: Could not retrieve Last-Modified header. Check credentials and URL."
    exit 1
fi

log "Remote Last-Modified: $REMOTE_DATE"

# Check if we have a local timestamp
if [ -f "$TIMESTAMP_FILE" ]; then
    LOCAL_DATE=$(cat "$TIMESTAMP_FILE")
    log "Local Last-Modified: $LOCAL_DATE"
    
    # Convert dates to epoch for comparison
    REMOTE_EPOCH=$(date_to_epoch "$REMOTE_DATE")
    LOCAL_EPOCH=$(date_to_epoch "$LOCAL_DATE")
    
    if [ "$REMOTE_EPOCH" -gt "$LOCAL_EPOCH" ]; then
        log "New version available. Downloading..."
        download_database "$REMOTE_DATE"
    else
        log "Database is up to date. No download needed."
    fi
else
    log "No local timestamp found. Downloading database..."
    download_database "$REMOTE_DATE"
fi

log "Update check completed."
log "=========================================="
