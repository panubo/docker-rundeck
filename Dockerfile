FROM docker.io/debian:stretch

# Set encoding
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Install base packages
RUN set -x \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y wget curl vim awscli jq openjdk-8-jre-headless openssh-client uuid-runtime procps gnupg2 dirmngr db-util libpam-modules libpam0g libpam0g-dev git make \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install Dumb-init
ENV DUMB_INIT_VERSION=1.2.1
ENV DUMB_INIT_CHECKSUM=057ecd4ac1d3c3be31f82fc0848bf77b1326a975b4f8423fe31607205a0fe945
RUN set -x \
  && wget --no-verbose -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64 \
  && echo "${DUMB_INIT_CHECKSUM}  dumb-init" > /usr/local/bin/SHA256SUM \
  && ( cd /usr/local/bin; sha256sum -c SHA256SUM; ) \
  && chmod +x /usr/local/bin/dumb-init \
  && rm /usr/local/bin/SHA256SUM \
  ;

# Install rundeck
ENV RUNDECK_VERSION 2.10.3-1-GA_all
ENV RUNDECK_CHECKSUM 91ea1194376a1ecafba49e60f5265ea38ab2c4db
RUN set -x \
  && wget --no-verbose -O /tmp/rundeck_${RUNDECK_VERSION}.deb "http://download.rundeck.org/deb/rundeck_${RUNDECK_VERSION}.deb" \
  && echo "${RUNDECK_CHECKSUM}  rundeck_${RUNDECK_VERSION}.deb" > /tmp/SHA1SUM \
  && ( cd /tmp; sha1sum -c SHA1SUM; ) \
  && dpkg -i /tmp/rundeck_${RUNDECK_VERSION}.deb \
  && mv /var/lib/rundeck /var/lib/rundeck-defaults \
  && chown -R root:rundeck /etc/rundeck \
  && chmod -R 640 /etc/rundeck/* \
  && rm -f /tmp/rundeck_${RUNDECK_VERSION}.deb /tmp/SHA1SUM \
  ;

# Install ansible
RUN set -x \
  && echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main' > /etc/apt/sources.list.d/ansible.list \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y ansible \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Download plugins
RUN set -x \
  && mkdir /opt/rundeck-plugins \
  && ANSIBLE_PLUGIN_VERSION=2.2.2 \
  && wget --no-verbose -O /opt/rundeck-plugins/ansible-plugin-${ANSIBLE_PLUGIN_VERSION}.jar -L https://github.com/Batix/rundeck-ansible-plugin/releases/download/${ANSIBLE_PLUGIN_VERSION}/ansible-plugin-${ANSIBLE_PLUGIN_VERSION}.jar \
  ;

VOLUME ["/var/lib/rundeck", "/var/rundeck", "/var/log/rundeck"]

# Add config files
COPY run.sh /run.sh
COPY ansible-bootstrap/ /ansible-bootstrap/

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/run.sh"]
