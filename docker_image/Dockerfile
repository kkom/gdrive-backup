FROM google/cloud-sdk:263.0.0

ENV SHELL2HTTP_VERSION="1.13"
ENV SHELL2HTTP_DEB_FILE="shell2http_${SHELL2HTTP_VERSION}_amd64.deb"

WORKDIR /tmp/gdrive-install

RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
        ca-certificates \
        curl \
        man-db \
        wget \
        unzip \
    && rm -rf /var/lib/apt/lists/* \
    # The rclone version in Debian repository (as of cloud-sdk:263.0.0) is
    # too old. It does not have the `--drive-impersonate` flag
    && curl https://rclone.org/install.sh | bash \
    && wget https://github.com/msoap/shell2http/releases/download/$SHELL2HTTP_VERSION/$SHELL2HTTP_DEB_FILE \
    && dpkg -i $SHELL2HTTP_DEB_FILE \
    && apt-get install --assume-yes --fix-broken ./$SHELL2HTTP_DEB_FILE

COPY gdrive-backup.bash /usr/bin/

WORKDIR /root

CMD gdrive-backup.bash
