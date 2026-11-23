#!/bin/bash
LOG_FILE="$HOME/cloud/logs/health_check.log"
STATE_DIR="$HOME/cloud/logs/alert_state"
mkdir -p "$STATE_DIR"
check_python_service() {
    if systemctl is-active --quiet python-webapp; then
        echo "Python App is running" >> "$LOG_FILE"

        if [ -f "$STATE_DIR/python-down" ]; then
            logger -t health-check "RECOVERY: Python App is running again"
            rm "$STATE_DIR/python-down"
        fi
    else
        echo "Python App is NOT running" >> "$LOG_FILE"

        if [ ! -f "$STATE_DIR/python-down" ]; then
            logger -t health-check "ALERT: Python App is NOT running"
            touch "$STATE_DIR/python-down"
        fi
    fi
}
check_website() {
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)

    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "Website is healthy (HTTP $HTTP_CODE)" >> "$LOG_FILE"

        if [ -f "$STATE_DIR/website-down" ]; then
            logger -t health-check "RECOVERY: Website is responding again"
            rm "$STATE_DIR/website-down"
        fi
    else
        echo "Website has a problem (HTTP $HTTP_CODE)" >> "$LOG_FILE"

        if [ ! -f "$STATE_DIR/website-down" ]; then
            logger -t health-check "ALERT: Website has a problem (HTTP $HTTP_CODE)"
            touch "$STATE_DIR/website-down"
        fi
    fi
}
check_disk_space() {
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

    if [ "$DISK_USAGE" -ge 80 ]; then
        echo "WARNING: Disk usage is ${DISK_USAGE}%" >> "$LOG_FILE"

        if [ ! -f "$STATE_DIR/disk-high" ]; then
            logger -t health-check "ALERT: Disk usage is ${DISK_USAGE}%"
            touch "$STATE_DIR/disk-high"
        fi
    else
        echo "Disk usage is normal (${DISK_USAGE}%)" >> "$LOG_FILE"

        if [ -f "$STATE_DIR/disk-high" ]; then
            logger -t health-check "RECOVERY: Disk usage is normal again (${DISK_USAGE}%)"
            rm "$STATE_DIR/disk-high"
        fi
    fi
}
echo "Health Check: $(date)" >> "$LOG_FILE"

check_python_service
check_website
check_disk_space

echo "" >> "$LOG_FILE"

