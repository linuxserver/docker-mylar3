# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/unrar:latest as unrar

FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG MYLAR3_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

ARG DEBIAN_FRONTEND="noninteractive"

RUN \
  echo "**** install build dependencies ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    libjpeg9-dev \
    libwebp-dev \
    python3-dev \
    zlib1g-dev && \
  echo "**** install runtime packages ****" && \
  apt-get install -y --no-install-recommends \
    libjpeg9 \
    nodejs \
    python3-venv \
    webp \
    zlib1g-dev && \
  echo "**** install mylar3 ****" && \
  if [ -z ${MYLAR3_RELEASE+x} ]; then \
    MYLAR3_RELEASE=$(curl -sX GET https://api.github.com/repos/mylar3/mylar3/releases/latest \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  mkdir /app/mylar3 && \
  curl -o \
    /tmp/mylar3.tar.gz -L \
    "https://github.com/mylar3/mylar3/archive/${MYLAR3_RELEASE}.tar.gz" && \
  tar xf /tmp/mylar3.tar.gz -C \
    /app/mylar3/ --strip-components=1 && \
  cd /app/mylar3 && \
  python3 -m venv /lsiopy && \
  pip install -U --no-cache-dir \
    pip \
    wheel && \
  pip install --no-cache-dir --find-links https://wheel-index.linuxserver.io/ubuntu/ -r requirements.txt && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.cache \
    /tmp/*

# add local files
COPY root/ /

# add unrar
COPY --from=unrar /usr/bin/unrar-ubuntu /usr/bin/unrar

# ports and volumes
VOLUME /config
EXPOSE 8090
