#!/bin/bash -x 
/bin/docker run --rm                                     \
  --rm                                                   \
  --network=host                                         \
  -e "MYSQL_ROOT_PASSWORD=$(cat /srv/mysql-db-password)" \
  -e "MYSQL_PASSWORD=$(cat /srv/wordpress-db-password)"  \
  -e MYSQL_USER=wordpress_db_user                        \
  -e MYSQL_DATABASE=wordpress                            \
  -v "/srv/db:/var/lib/mysql"                            \
  --name docker.wordpress-mysql.service                  \
  -d mysql:5.7
