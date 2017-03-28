#! /bin/bash

cat << EOF > /etc/nginx/conf.d/default.conf
server_names_hash_bucket_size 64;
server {
  root /opt/aptly/public;
  server_name ${HOSTNAME};

  location / {
    autoindex on;
  }
}
EOF
