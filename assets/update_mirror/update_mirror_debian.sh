#! /bin/bash
set -e

# Automate the initial creation and update of a Debian package mirror in aptly

# The variables (as set below) will create a mirror of the Debian jessie repo 
# with the main and update components. If you do mirror these, you'll want to
# include "deb http://security.debian.org jessie/updates main" in your sources.list
# file or mirror it similarly as done below to keep up with security updates.

DEBIAN_RELEASE=buster
UPSTREAM_URL="http://deb.debian.org/debian/"
COMPONENTS=( main )
REPOS=( ${DEBIAN_RELEASE} ${DEBIAN_RELEASE}-updates )

# Setup gpg-agent to cache GPG passphrase for unattended operation
# Allow passphrase preset for unattended updates
if [[ ! -f ~/.gnupg/gpg-agent.conf ]]; then
  echo "allow-preset-passphrase" > ~/.gnupg/gpg-agent.conf
  killall5 1 gpg-agent
fi

gpg-agent --homedir /root/.gnupg --daemon || true
gpg2 --import /opt/aptly/aptly.pub
KG=`gpg2 --list-keys --with-keygrip | awk '/rsa2048/{getline; getline; print $3}'`
echo "$GPG_PASSWORD" | /usr/lib/gnupg2/gpg-preset-passphrase --preset "$KG"

# Create repository mirrors if they don't exist
set +e
for component in ${COMPONENTS[@]}; do
  for repo in ${REPOS[@]}; do
    aptly mirror list -raw | grep "^${repo}$"
    if [[ $? -ne 0 ]]; then
      echo "Creating mirror of ${repo} repository."
      aptly mirror create \
        -architectures=amd64 ${repo} ${UPSTREAM_URL} ${repo} ${component}
    fi
  done
done
set -e

# Update all repository mirrors
for component in ${COMPONENTS[@]}; do
  for repo in ${REPOS[@]}; do
    echo "Updating ${repo} repository mirror.."
    aptly mirror update ${repo}
  done
done

# Create snapshots of updated repositories
for component in ${COMPONENTS[@]}; do
  for repo in ${REPOS[@]}; do
    echo "Creating snapshot of ${repo} repository mirror.."
    SNAPSHOTARRAY+="${repo}-`date +%Y%m%d%H%M` "
    aptly snapshot create ${repo}-`date +%Y%m%d%H%M` from mirror ${repo}
  done
done

echo ${SNAPSHOTARRAY[@]}

# Merge snapshots into a single snapshot with updates applied
echo "Merging snapshots into one.." 
aptly snapshot merge -latest                 \
  ${DEBIAN_RELEASE}-merged-`date +%Y%m%d%H%M`  \
  ${SNAPSHOTARRAY[@]}

# Publish the latest merged snapshot
set +e
aptly publish list -raw | awk '{print $2}' | grep "^${DEBIAN_RELEASE}$"
if [[ $? -eq 0 ]]; then
  aptly publish switch            \
    ${DEBIAN_RELEASE} ${DEBIAN_RELEASE}-merged-`date +%Y%m%d%H%M`
else
  aptly publish snapshot \
    -distribution=${DEBIAN_RELEASE} ${DEBIAN_RELEASE}-merged-`date +%Y%m%d%H%M`
fi
set -e

# Export the GPG Public key
if [[ ! -f /opt/aptly/public/aptly_repo_signing.key ]]; then
  gpg2 --import /opt/aptly/aptly.pub
  gpg2 --export --armor > /opt/aptly/public/aptly_repo_signing.key
fi

# Generate Aptly Graph
aptly graph -output /opt/aptly/public/aptly_graph.png
