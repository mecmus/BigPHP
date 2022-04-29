FROM node:16.15.0-alpine3.15 as node
FROM php:8.0.17-fpm-alpine

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
  python2 \
  python2-dev \
  py-pip \
  mysql-client \
  libzip-dev \
  restic

RUN docker-php-ext-install mysqli mbstring pdo pdo_mysql tokenizer xml pcntl exif
RUN docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/
RUN docker-php-ext-install gd
RUN docker-php-ext-configure zip --with-zlib-dir=/usr && docker-php-ext-install zip
 
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
