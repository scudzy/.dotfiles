#!/bin/bash

# Output CSV file
LOGFILE="$HOME/speedlog.csv"

# If file doesn’t exist, add header
if [ ! -f "$LOGFILE" ]; then
  echo "timestamp,ping_ms,jitter_ms,download_mbps,upload_mbps,server_name" >> "$LOGFILE"
fi

# Run speedtest in JSON mode
echo "[INFO] Running Speedtest..."
RESULT=$(speedtest --format=json -v)

# Extract values using jq
TIMESTAMP=$(echo $RESULT | jq -r '.timestamp')
PING=$(echo $RESULT | jq -r '.ping.latency')
JITTER=$(echo $RESULT | jq -r '.ping.jitter')
DOWNLOAD=$(echo $RESULT | jq -r '.download.bandwidth' | awk '{print $1*8/1000000}') # bits → Mbps
UPLOAD=$(echo $RESULT | jq -r '.upload.bandwidth' | awk '{print $1*8/1000000}')
SERVER=$(echo $RESULT | jq -r '.server.name')

# Append to CSV
echo "$TIMESTAMP,$PING,$JITTER,$DOWNLOAD,$UPLOAD,$SERVER" >> "$LOGFILE"

# Verbose output
echo "[RESULT] Test completed at: $TIMESTAMP"
echo "          Server   : $SERVER"
echo "          Ping     : $PING ms"
echo "          Jitter   : $JITTER ms"
echo "          Download : $DOWNLOAD Mbps"
echo "          Upload   : $UPLOAD Mbps"
echo "[INFO] Results saved to $LOGFILE"
