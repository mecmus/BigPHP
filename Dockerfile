FROM node:alpine as node
FROM php:7.3-fpm-alpine

COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

RUN apk --update add wget \
  curl \
  git \
  build-base \
  libmemcached-dev \
  libmcrypt-dev \
  libxml2-dev \
  pcre-dev \
  zlib-dev \
  autoconf \
  cyrus-sasl-dev \
  libgsasl-dev \
  oniguruma-dev \
  openssl \
  openssl-dev \
  supervisor \
  libjpeg-turbo-dev \
  libpng-dev \
  freetype-dev

RUN docker-php-ext-install mysqli mbstring pdo pdo_mysql tokenizer xml pcntl exif
RUN docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/
RUN docker-php-ext-install gd


# Add a non-root user:
ARG PUID=1000
ENV PUID ${PUID}
ARG PGID=1000
ENV PGID ${PGID}

RUN addgroup -g ${PGID} phpapps && \
    adduser -D -G phpapps -u ${PUID} phpapps

WORKDIR /usr/src

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY supervisor/ /etc/
COPY startup.sh /
RUN chmod +x /startup.sh

#ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c",  "/etc/supervisord.conf"]
CMD ["/startup.sh"]

# Clean up
RUN rm /var/cache/apk/* \
    && mkdir -p /var/www

WORKDIR /etc/supervisor/conf.d/

EXPOSE 80 9000
