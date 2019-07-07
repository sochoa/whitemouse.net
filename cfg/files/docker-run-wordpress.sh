#!/bin/bash

/usr/bin/docker run                                            \
  --rm                                                         \
  --network=host                                               \
  -e WORDPRESS_DB_HOST=0.0.0.0                                 \
  -e WORDPRESS_DB_NAME=wordpress_db                            \
  -e "WORDPRESS_DB_PASSWORD=$(cat /srv/wordpress-db-password)" \
  --name wordpress                                             \
  -v "/srv/wordpress:/var/www/html"                            \
  -d wordpress
