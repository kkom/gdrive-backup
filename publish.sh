#!/bin/bash

source config

docker build -t $USERNAME/$IMG_NAME .

docker login -u $USERNAME
docker push $USERNAME/$IMG_NAME
