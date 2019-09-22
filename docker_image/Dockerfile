FROM google/cloud-sdk:263.0.0

RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
        ca-certificates \
        curl \
        man-db \
        unzip \
    && rm -rf /var/lib/apt/lists/* \
    # The rclone version in Debian repository (as of cloud-sdk:263.0.0) is
    # too old. It does not have the `--drive-impersonate` flag
    && curl https://rclone.org/install.sh | bash

COPY gdrive-backup.bash /usr/bin/

CMD gdrive-backup.bash
