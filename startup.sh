#!/bin/sh
cd /var/www
if [ ! -f /var/www/composer.json ] && [ ! -f /var/www/package.json ];then
	echo "composer.json or package.json missing"
	exit 1
fi

if [ -d /var/www/vendor ]; then
	echo "No need for composer install"
else
	su -c 'composer install' phpapps
fi

if [ -d /var/www/node_modules ];then
        echo "No need for npm install"
else
        su -c 'npm i' phpapps
fi

npm run prod
chown -R www-data:www-data storage 
php artisan storage:link
cd /etc/supervisor/conf.d/

/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
