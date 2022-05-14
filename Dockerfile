FROM ubuntu:focal

LABEL MAINTAINER Patrick Stebbe <info@moonliightz.de>

ENV SINUS_USER="sinusbot" \
    SINUS_GROUP="sinusbot" \
    SINUS_USERID="3000" \
    SINUS_GROUPID="3000" \
    SINUS_DIR="/sinusbot" \
    YTDLP_BIN="/usr/local/bin/yt-dlp" \
    SINUS_DL_URL="https://www.sinusbot.com/dl/sinusbot.current.tar.bz2" \
    YTDLP_VERSION="latest" \
    TS3_VERSION="3.5.6" \
    TS3_OFFSET="1386"

ENV SINUS_DATA_DIR="${SINUS_DIR}/data" \
    TS3_DIR="${SINUS_DIR}/TeamSpeak3-Client-linux_amd64"

RUN DEBIAN_FRONTEND="noninteractive" apt-get update && apt-get -y install tzdata
RUN DEBIAN_FRONTEND="noninteractive" apt-get update && apt-get -y install keyboard-configuration

RUN apt-get update && \
    apt-get install -y \
      locales \
      wget \
      sudo \
      x11vnc \
      xinit \
      xvfb \
      xcb \
      screen \
      libxcursor1 \
      libglib2.0-0 \
      libnss3 \
      libegl1-mesa \
      x11-xkb-utils \
      libasound2 \
      libpci3 \
      libxslt1.1 \
      libxkbcommon0 \
      python \
      python3 \
      bzip2 \
      sqlite3 \
      ca-certificates
RUN groupadd -g "$SINUS_GROUPID" -r "$SINUS_GROUP" && \
    useradd -u "$SINUS_USERID" -r -g "$SINUS_GROUP" -d "$SINUS_DIR" "$SINUS_USER" && \
    update-ca-certificates && \
    wget --no-check-certificate -q -O "$YTDLP_BIN" "https://github.com/yt-dlp/yt-dlp/releases/$YTDLP_VERSION/download/yt-dlp" && \
    chmod 755 -f "$YTDLP_BIN" && \
    locale-gen --purge en_US.UTF-8 && \
    echo LC_ALL=en_US.UTF-8 >> /etc/default/locale && \
    echo LANG=en_US.UTF-8 >> /etc/default/locale && \
    mkdir -p "$SINUS_DIR" "$TS3_DIR" "$TS3_DIR/plugins" && \
    wget -qO- "$SINUS_DL_URL" | \
    tar -xjf- -C "$SINUS_DIR" && \
    # wget -q -O- "http://dl.4players.de/ts/releases/$TS3_VERSION/TeamSpeak3-Client-linux_amd64-$TS3_VERSION.run" | \
    # tail -n +$TS3_OFFSET | \
    # tar xzf - -C "$TS3_DIR" && \
    cd "$SINUS_DIR" && \
    wget -q -O "TeamSpeak3-Client-linux_amd64-$TS3_VERSION.run" \
        "https://files.teamspeak-services.com/releases/client/$TS3_VERSION/TeamSpeak3-Client-linux_amd64-$TS3_VERSION.run" && \
    chmod 755 "TeamSpeak3-Client-linux_amd64-$TS3_VERSION.run" && \
    yes | "./TeamSpeak3-Client-linux_amd64-$TS3_VERSION.run" && \
    rm -f "TeamSpeak3-Client-linux_amd64-$TS3_VERSION.run" && \
    rm "$TS3_DIR/xcbglintegrations/libqxcb-glx-integration.so" && \
    mv -f "$SINUS_DIR/config.ini.dist" "$SINUS_DIR/config.ini" && \
    sed -i "s|TS3Path = .*|TS3Path = \"$TS3_DIR/ts3client_linux_amd64\"|g" "$SINUS_DIR/config.ini" && \
    echo YoutubeDLPath = \"$YTDLP_BIN\" >> "$SINUS_DIR/config.ini" && \
    cp -f "$SINUS_DIR/plugin/libsoundbot_plugin.so" "$TS3_DIR/plugins/" && \
    chown -fR "$SINUS_USER":"$SINUS_GROUP" "$SINUS_DIR" "$TS3_DIR" && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
RUN wget -q https://sinusbot-demo.vercel.app/nonapi.js && mv nonapi.js /sinusbot/scripts/

VOLUME [ "${SINUS_DATA_DIR}" ]

EXPOSE 8087

ENTRYPOINT [ "./entrypoint.sh" ]
