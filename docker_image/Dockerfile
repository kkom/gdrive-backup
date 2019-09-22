FROM google/cloud-sdk:263.0.0

RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends rclone \
    && rm -rf /var/lib/apt/lists/*

COPY gdrive-backup.bash /usr/bin/

CMD gdrive-backup.bash
