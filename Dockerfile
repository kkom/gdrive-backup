FROM ubuntu:latest

RUN apt-get update && apt-get install -y --no-install-recommends curl man-db zip && curl https://rclone.org/install.sh | bash
