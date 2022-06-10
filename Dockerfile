FROM node:16.15.1-alpine3.15 as node
FROM php:8.0.20-fpm-alpine3.16

COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

RUN apk --update --no-cache add wget \
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
  freetype-dev \
  python3 \
  python3-dev \
  py-pip \
  mysql-client \
  libzip-dev \
  restic

RUN docker-php-ext-install mysqli mbstring pdo pdo_mysql pcntl exif
RUN docker-php-ext-configure gd --enable-gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/
RUN docker-php-ext-install gd
RUN docker-php-ext-install zip

RUN mkdir -p /usr/src/app /var/www
WORKDIR /usr/src/app

COPY laravel-echo-server/package.json /usr/src/app/

RUN npm install


# Add a non-root user:
ARG PUID=1000
ENV PUID ${PUID}
ARG PGID=1000
ENV PGID ${PGID}

RUN addgroup -g ${PGID} phpapps && \
    adduser -D -G phpapps -u ${PUID} phpapps

WORKDIR /usr/src

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY supervisor/ /etc/supervisor
COPY startup.sh /
COPY php-fpm/www.conf /usr/local/etc/php-fpm.d/
RUN chmod +x /startup.sh

#ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c",  "/etc/supervisord.conf"]
CMD ["/startup.sh"]

WORKDIR /etc/supervisor/conf.d/

EXPOSE 80 81 9000
