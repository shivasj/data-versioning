#!/bin/bash

set -e

export BASE_DIR=$(pwd)
export SECRETS_DIR=$(pwd)/../secrets/
export DATA_DIR=$(pwd)/../allimages/
export GCS_BUCKET_NAME="cheese-app-data-demo"
export GCP_PROJECT="ac215-project"
export GCP_ZONE="us-central1-a"


echo "Creating network"
docker network inspect data-versioning-network >/dev/null 2>&1 || docker network create data-versioning-network

echo "Building image"
docker build -t data-version-cli -f Dockerfile .

echo "Running container"
docker run --rm --name data-version-cli -ti \
--privileged \
--cap-add SYS_ADMIN \
--device /dev/fuse \
-v "$BASE_DIR":/app \
-v "$SECRETS_DIR":/secrets \
-v "$DATA_DIR":/data \
-v ~/.gitconfig:/etc/gitconfig \
-e GOOGLE_APPLICATION_CREDENTIALS=/secrets/data-service-account.json \
-e GCP_PROJECT=$GCP_PROJECT \
-e GCP_ZONE=$GCP_ZONE \
-e GCS_BUCKET_NAME=$GCS_BUCKET_NAME \
--network data-versioning-network data-version-cli \
bash -c "
gcloud auth activate-service-account --key-file=/secrets/data-service-account.json
mkdir -p /mnt/gcs_bucket
gcsfuse --key-file=/secrets/data-service-account.json $GCS_BUCKET_NAME /mnt/gcs_data
echo 'GCS bucket mounted at /mnt/gcs_data'
"