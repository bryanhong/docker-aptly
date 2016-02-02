#! /bin/bash
cat << EOF > /opt/gpg_batch
%echo Generating a GPG key, might take a while
Key-Type: RSA
Key-Length: 2048
Subkey-Type: ELG-E
Subkey-Length: 1024
Name-Real: ${FULL_NAME}
Name-Comment: Aptly Repo Signing
Name-Email: ${EMAIL_ADDRESS}
Expire-Date: 0
Passphrase: ${GPG_PASSWORD}
%pubring /opt/aptly/aptly.pub
%secring /opt/aptly/aptly.sec 
%commit
%echo done
EOF
