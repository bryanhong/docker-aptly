#! /bin/bash
set -e

# Automate the initial creation and update of an Ubuntu package mirror in aptly

# The variables (as set below) will create a mirror of the Ubuntu Trusty repo 
# with the main & universe components, you can add other components like restricted
# multiverse etc by adding to the array (separated by spaces).

# For more detail about each of the variables below refer to: 
# https://help.ubuntu.com/community/Repositories/CommandLine

UBUNTU_RELEASE=trusty
UPSTREAM_URL="http://archive.ubuntu.com/ubuntu/"
COMPONENTS=( main universe )
REPOS=( ${UBUNTU_RELEASE} ${UBUNTU_RELEASE}-updates ${UBUNTU_RELEASE}-security )

# Create repository mirrors if they don't exist
set +e
for component in ${COMPONENTS[@]}; do
  for repo in ${REPOS[@]}; do
    aptly mirror list -raw | grep "^${repo}-${component}$"
    if [[ $? -ne 0 ]]; then
      echo "Creating mirror of ${repo}-${component} repository."
      aptly mirror create \
        -architectures=amd64 ${repo}-${component} ${UPSTREAM_URL} ${repo} ${component}
    fi
  done
done
set -e

# Update all repository mirrors
for component in ${COMPONENTS[@]}; do
  for repo in ${REPOS[@]}; do
    echo "Updating ${repo}-${component} repository mirror.."
    aptly mirror update ${repo}-${component}
  done
done

# Create snapshots of updated repositories
for component in ${COMPONENTS[@]}; do
  for repo in ${REPOS[@]}; do
    echo "Creating snapshot of ${repo}-${component} repository mirror.."
    SNAPSHOTARRAY+="${repo}-${component}-`date +%Y%m%d%H` "
    aptly snapshot create ${repo}-${component}-`date +%Y%m%d%H` from mirror ${repo}-${component}
  done
done

echo ${SNAPSHOTARRAY[@]}

# Merge snapshots into a single snapshot with updates applied
echo "Merging snapshots into one.." 
aptly snapshot merge -latest                 \
  ${UBUNTU_RELEASE}-merged-`date +%Y%m%d%H`  \
  ${SNAPSHOTARRAY[@]}

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

# Export the GPG Public key
if [[ ! -f /opt/aptly/public/aptly_repo_signing.key ]]; then
  gpg --export --armor > /opt/aptly/public/aptly_repo_signing.key
fi

# Generate Aptly Graph
aptly graph -output /opt/aptly/public/aptly_graph.png
