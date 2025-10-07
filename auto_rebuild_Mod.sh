#!/bin/bash

REPO_DIR="/home/midnom/arithmetic_api"
IMAGE_NAME="arithmetic-api"

cd "$REPO_DIR"

echo "[*] Initial build and container start..."
docker build -t $IMAGE_NAME .
docker stop $IMAGE_NAME-container 2>/dev/null
docker rm $IMAGE_NAME-container 2>/dev/null
docker run -d --name $IMAGE_NAME-container -p 5000:5000 $IMAGE_NAME

echo "[*] Monitoring $REPO_DIR for changes or new Git commits..."

while true; do
    REBUILD=false

    # Check for Git updates
    git fetch origin
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "[*] New Git commit detected! Pulling changes..."
        git pull origin main
        REBUILD=true
    fi

    # Check for file changes
    CHANGES=$(inotifywait -t 5 -e modify,create,delete -r . 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "[*] File changes detected!"
        REBUILD=true
    fi

    # Rebuild and restart Docker if needed
    if [ "$REBUILD" = true ]; then
        echo "[*] Rebuilding Docker image..."
        docker build -t $IMAGE_NAME .
        docker stop $IMAGE_NAME-container 2>/dev/null
        docker rm $IMAGE_NAME-container 2>/dev/null
        docker run -d --name $IMAGE_NAME-container -p 5000:5000 $IMAGE_NAME
    fi

    sleep 5
done
