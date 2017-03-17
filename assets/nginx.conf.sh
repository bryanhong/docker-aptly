#! /bin/bash

cat << EOF > /etc/nginx/conf.d/default.conf
server {
  root /opt/aptly/public;
  server_name ${HOSTNAME};

  location / {
    autoindex on;
  }
  location =/aptly.pub {
    root /opt/aptly/;
  }
}
EOF
