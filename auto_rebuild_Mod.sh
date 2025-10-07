#!/bin/bash

REPO_DIR="/home/midnom/arithmetic_api"
IMAGE_NAME="arithmetic-api"
CONTAINER_NAME="${IMAGE_NAME}-container"

cd "$REPO_DIR"

# Function to get the machine's local IP address
get_ip() {
    hostname -I | awk '{print $1}'
}

# Function to build and run Docker container
run_container() {
    echo "[*] Building Docker image..."
    docker build -t "$IMAGE_NAME" .
    echo "[*] Stopping existing container (if any)..."
    docker stop "$CONTAINER_NAME" 2>/dev/null
    docker rm "$CONTAINER_NAME" 2>/dev/null
    echo "[*] Starting new container..."
    docker run -d --name "$CONTAINER_NAME" -p 5000:5000 "$IMAGE_NAME"

    IP=$(get_ip)
    echo "[*] Website is accessible at: http://$IP:5000"
}

# Initial build and run
echo "[*] Initial build and container start..."
run_container

echo "[*] Monitoring $REPO_DIR for file changes or new Git commits..."

# Keep track of last commit hash to avoid repeated pulls
LAST_COMMIT=$(git rev-parse HEAD)

while true; do
    REBUILD=false

    # Check for Git updates
    git fetch origin
    REMOTE_COMMIT=$(git rev-parse origin/main)

    if [ "$LAST_COMMIT" != "$REMOTE_COMMIT" ]; then
        echo "[*] New Git commit detected! Pulling changes..."
        git pull origin main
        LAST_COMMIT=$(git rev-parse HEAD)
        REBUILD=true
        SKIP_FILE_WATCH=true  # Prevent immediate rebuild from Git pull
    fi

    # Check for file changes
    if [ "$SKIP_FILE_WATCH" != true ]; then
        CHANGES=$(inotifywait -t 5 -e modify,create,delete -r . 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "[*] File changes detected!"
            REBUILD=true
        fi
    else
        SKIP_FILE_WATCH=false
    fi

    # Rebuild and restart Docker if needed
    if [ "$REBUILD" = true ]; then
        run_container
    fi

    sleep 5
done
