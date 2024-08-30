#! /bin/sh
script_dir=$(cd "$(dirname "$0")" && pwd)

# build devops image.
# docker build -t bukaka/alert-brige -f ./alert-brige.dockerfile "$script_dir"

# build nginx init helper.
docker build -t bukaka/nginx:1.21.1-alpine -f "$script_dir"/nginx.dockerfile "$script_dir"

# build mysql exporter
# docker build -t bukaka/mysql-client:8.4.1 -f "$script_dir"/mysql-client.dockerfile "$script_dir"

# build php fpm
# docker build -t bukaka/php-fpm:8.0.6 -f "$script_dir"/php-fpm.dockerfile "$script_dir"