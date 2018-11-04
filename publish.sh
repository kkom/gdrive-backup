#!/bin/bash

USERNAME=kkom
IMG_NAME=cloud-storage-backup

docker build -t $USERNAME/$IMG_NAME .

docker login -u $USERNAME
docker push $USERNAME/$IMG_NAME
