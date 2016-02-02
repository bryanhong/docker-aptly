#! /bin/bash
set -e

UBUNTU_RELEASE=trusty
UPSTREAM_URL="http://archive.ubuntu.com/ubuntu/"
REPOS=( ${UBUNTU_RELEASE} ${UBUNTU_RELEASE}-updates ${UBUNTU_RELEASE}-security )

# Export the GPG Public key
if [[ ! -f /opt/aptly/aptly_repo_key.pub ]]; then
  gpg --export --armor > /opt/aptly/${HOSTNAME}_signing.key
fi

# Create repository mirrors if they don't exist
set +e
for repo in ${REPOS[@]}; do
  aptly mirror list -raw | grep "^${repo}$"
  if [[ $? -ne 0 ]]; then
    echo "Creating mirror of ${repo} repository."
    aptly mirror create \
      -architectures=amd64 ${repo} ${UPSTREAM_URL} ${repo} main
  fi
done
set -e

# Update all repository mirrors
for repo in ${REPOS[@]}; do
  echo "Updating ${repo} repository mirror.."
  aptly mirror update ${repo}
done

# Create snapshots of updated repositories
for repo in ${REPOS[@]}; do
  echo "Creating snapshot of ${repo} repository mirror.."
  aptly snapshot create ${repo}-`date +%Y%m%d%H` from mirror ${repo}
done

# Merge snapshots into a single snapshot with updates applied
echo "Merging snapshots into one.." 
aptly snapshot merge -latest                 \
  ${UBUNTU_RELEASE}-merged-`date +%Y%m%d%H`  \
  ${UBUNTU_RELEASE}-`date +%Y%m%d%H`         \
  ${UBUNTU_RELEASE}-updates-`date +%Y%m%d%H` \
  ${UBUNTU_RELEASE}-security-`date +%Y%m%d%H`

# Publish the latest merged snapshot
set +e
aptly publish list -raw | awk '{print $2}' | grep "^${UBUNTU_RELEASE}$"
if [[ $? -eq 0 ]]; then
  aptly publish switch            \
    -passphrase="${GPG_PASSWORD}" \
    ${UBUNTU_RELEASE} ${UBUNTU_RELEASE}-merged-`date +%Y%m%d%H`
else
  aptly publish snapshot \
    -passphrase="${GPG_PASSWORD}" \
    -distribution=${UBUNTU_RELEASE} ${UBUNTU_RELEASE}-merged-`date +%Y%m%d%H`
fi
set -e

# Generate Aptly Graph
aptly graph
cp `ls -rt /tmp/aptly-graph*.png | tail -n1` /opt/aptly/public/aptly_graph.png
