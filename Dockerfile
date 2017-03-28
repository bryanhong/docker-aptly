# Copyright 2016 Bryan J. Hong
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM debian:jessie

MAINTAINER bryan@turbojets.net

ENV DEBIAN_FRONTEND noninteractive

# Add Aptly repository
RUN echo "deb http://repo.aptly.info/ squeeze main" > /etc/apt/sources.list.d/aptly.list
RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 9E3E53F19C7DE460

# Update APT repository and install packages
RUN apt-get -q update                  \
 && apt-get -y install aptly           \
                       bash-completion \
                       bzip2           \
                       gnupg           \
                       gpgv            \
                       graphviz        \
                       supervisor      \
                       nginx           \
                       wget            \
                       xz-utils

# Install Aptly Configuration
COPY assets/aptly.conf /etc/aptly.conf

# Enable Aptly Bash completions
RUN wget https://github.com/aptly-dev/aptly-bash-completion/raw/master/aptly \
  -O /etc/bash_completion.d/aptly \
  && echo "if ! shopt -oq posix; then\n\
  if [ -f /usr/share/bash-completion/bash_completion ]; then\n\
    . /usr/share/bash-completion/bash_completion\n\
  elif [ -f /etc/bash_completion ]; then\n\
    . /etc/bash_completion\n\
  fi\n\
fi" >> /etc/bash.bashrc

# Install Nginx Config
COPY assets/nginx.conf.sh /opt/nginx.conf.sh
COPY assets/supervisord.nginx.conf /etc/supervisor/conf.d/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Install scripts
COPY assets/*.sh /opt/

# Bind mount location
VOLUME [ "/opt/aptly" ]

# Execute Startup script when container starts
ENTRYPOINT [ "/opt/startup.sh" ]
