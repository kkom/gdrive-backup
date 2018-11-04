FROM ubuntu:latest

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl man-db unzip && curl https://rclone.org/install.sh | bash
