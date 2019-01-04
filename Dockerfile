FROM node:10.15-alpine
LABEL authors="john.lin<john.lin@ringcentral.com>"

ENV NODE_CONTAINER=docker

# Tell Puppeteer to skip installing Chrome. We'll be using the installed package.
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV VERSION_PJSIP 2.8
ENV VERSION_CHROMIUM 71
#========================
# Add edge into repositories
#========================
RUN echo @edge http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories \
    && echo @edge http://dl-cdn.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories

#========================
# Install bash and ca-certificates
#========================
RUN apk update && apk upgrade \
    && apk add --no-cache ca-certificates bash git python-dev py-pip \
    && pip install socketIO_client \
    && rm -rf /var/cache/apk/*

#========================
# Install pjsua
# https://github.com/minoruta/pjsip-node-alpine/blob/master/Dockerfile
#========================
RUN apk add --no-cache --virtual .build4pjsip \
    alpine-sdk \
    && apk add --no-cache \
    libsrtp-dev \
    openssl-dev \
    opus-dev \
    && cd /opt \
    && wget -qnv "http://www.pjsip.org/release/$VERSION_PJSIP/pjproject-$VERSION_PJSIP.tar.bz2" -O - | tar xjf - \
    && cd /opt/pjproject-$VERSION_PJSIP \
    && ./configure CFLAGS='-O2 -fPIC' \
    && make dep \
    && make \
    && make install \
    && cd /opt/pjproject-$VERSION_PJSIP/pjsip-apps/src/python \
    && python ./setup.py install \
    && cd /opt \
    && rm -rf pjproject-$VERSION_PJSIP \
    && apk del .build4pjsip

#========================
# Install mongodb
# https://github.com/mvertes/docker-alpine-mongo
#========================
RUN apk update && apk upgrade \
    && apk add --no-cache mongodb \
    && mkdir -p /data/db \
    && rm -rf /var/cache/apk/*

#========================
# Installs latest Chromium package.
# https://github.com/GoogleChrome/puppeteer/blob/master/docs/troubleshooting.md
#========================
RUN apk update && apk upgrade && \
    apk add --no-cache \
      chromium@edge~=${VERSION_CHROMIUM} \
      nss@edge \
      harfbuzz@edge

#========================
# Installs supervisor
#========================
RUN apk update && apk upgrade \
    && apk add --no-cache supervisor openssh \
    && rm -rf /var/cache/apk/* \
    && rm -f /etc/supervisord.conf \
    && mkdir -p /etc/supervisor/conf.d \
    && mkdir /var/log/supervisor
COPY supervisor/supervisord.conf /etc/supervisord.conf
COPY supervisor/mongodb.conf /etc/supervisor/conf.d/mongodb.conf