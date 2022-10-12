FROM ghcr.io/linuxserver/baseimage-alpine:3.16

# set version label
ARG UNRAR_VERSION=6.1.7
ARG BUILD_DATE
ARG VERSION
ARG MYLAR3_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

RUN \
  echo "**** install build dependencies ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base \
    curl \
    jpeg-dev \
    libffi-dev \
    libwebp-dev \
    py3-cffi \
    python3-dev \
    zlib-dev && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    jpeg \
    libwebp-tools \
    nodejs \
    py3-pip \
    python3 \
    zlib && \
  echo "**** install unrar from source ****" && \
  mkdir /tmp/unrar && \
  curl -o \
    /tmp/unrar.tar.gz -L \
    "https://www.rarlab.com/rar/unrarsrc-${UNRAR_VERSION}.tar.gz" && \  
  tar xf \
    /tmp/unrar.tar.gz -C \
    /tmp/unrar --strip-components=1 && \
  cd /tmp/unrar && \
  make && \
  install -v -m755 unrar /usr/local/bin && \
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
  pip3 install --no-cache-dir -U \
    pip wheel && \
  pip install --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.16/ -r requirements.txt && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.cache \
    /tmp/*

# add local files
COPY root/ /

# ports and volumes
VOLUME /config
EXPOSE 8090
