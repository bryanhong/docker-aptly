#! /bin/bash

# If the repository GPG keypair doesn't exist, create it.
if [[ ! -f /opt/aptly/aptly.sec ]] || [[ ! -f /opt/aptly/aptly.pub ]]; then
  /opt/gpg_batch.sh
  gpg --batch --gen-key /opt/gpg_batch
fi

# Import Ubuntu keyrings
gpg --no-default-keyring \
    --keyring /usr/share/keyrings/ubuntu-archive-keyring.gpg \
    --export | \
gpg --no-default-keyring \
    --keyring trustedkeys.gpg \
    --import

# Aptly looks in /root/.gnupg for default keyrings
ln -sf /opt/aptly/aptly.sec /root/.gnupg/secring.gpg
ln -sf /opt/aptly/aptly.pub /root/.gnupg/pubring.gpg

# Generate Nginx Config
/opt/nginx.conf.sh

# Start Supervisor
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
