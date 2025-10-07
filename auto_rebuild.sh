#!/bin/bash

PROJECT_DIR="/home/midnom/arithmetic_api"
IMAGE_NAME="arithmetic-api"

cd "$PROJECT_DIR"


echo "[*] Initial build and container start..."
docker build -t $IMAGE_NAME .
docker stop $IMAGE_NAME-container 2>/dev/null
docker rm $IMAGE_NAME-container 2>/dev/null
docker run -d --name $IMAGE_NAME-container -p 5000:5000 $IMAGE_NAME

echo "[*] Monitoring for changes in $PROJECT_DIR..."
while true; do
  inotifywait -e modify,create,delete -r .
  echo "[*] Change detected! Rebuilding Docker image..."
  docker build -t $IMAGE_NAME .
  docker stop $IMAGE_NAME-container 2>/dev/null
  docker rm $IMAGE_NAME-container 2>/dev/null
  docker run -d --name $IMAGE_NAME-container -p 5000:5000 $IMAGE_NAME
done
