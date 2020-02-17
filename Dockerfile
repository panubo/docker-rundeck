FROM docker.io/debian:buster

# Set encoding
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Install base packages
RUN set -x \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y wget curl vim awscli jq openssh-client uuid-runtime procps gnupg2 dirmngr db-util libpam-modules libpam0g libpam0g-dev git make lsb-release \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install JDK8 (required)
RUN set -x \
  && echo "deb https://adoptopenjdk.jfrog.io/adoptopenjdk/deb buster main" | tee -a /etc/apt/sources.list.d/adoptopenjdk.list \
  && curl https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - \
  && apt-get update \
  && apt-get -y install adoptopenjdk-8-hotspot \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install Google Cloud SDK
RUN set -x \
  && export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" \
  && echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
  && apt-get update \
  && apt-get install -y google-cloud-sdk \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install Dumb-init
ENV DUMB_INIT_VERSION=1.2.2
ENV DUMB_INIT_CHECKSUM=37f2c1f0372a45554f1b89924fbb134fc24c3756efaedf11e07f599494e0eff9
RUN set -x \
  && wget --no-verbose -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64 \
  && echo "${DUMB_INIT_CHECKSUM}  dumb-init" > /usr/local/bin/SHA256SUM \
  && ( cd /usr/local/bin; sha256sum -c SHA256SUM; ) \
  && chmod +x /usr/local/bin/dumb-init \
  && rm -f /usr/local/bin/SHA256SUM \
  ;

# Install Rundeck
ENV RUNDECK_VERSION=3.2.2.20200204-1_all
ENV RUNDECK_CHECKSUM=7e1aaf32390cf8c8e1be1d6cce3cea11b0eb433835ec059a513917004d2d2fe2
RUN set -x \
  && wget --no-verbose -O /tmp/rundeck_${RUNDECK_VERSION}.deb "https://dl.bintray.com/rundeck/rundeck-deb/rundeck_${RUNDECK_VERSION}.deb" \
  && echo "${RUNDECK_CHECKSUM}  rundeck_${RUNDECK_VERSION}.deb" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM; ) \
  && dpkg -i /tmp/rundeck_${RUNDECK_VERSION}.deb \
  && chown -R root:rundeck /etc/rundeck \
  && chmod -R 640 /etc/rundeck/* \
  && rm -f /tmp/rundeck_${RUNDECK_VERSION}.deb /tmp/SHA256SUM \
  ;

# Install Ansible
RUN set -x \
  && echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main' > /etc/apt/sources.list.d/ansible.list \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y ansible \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install Kubernetes SDK
RUN set -x \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y python-pip \
  && KUBERNETES_SDK_VERSION=8.0.1 \
  && pip install kubernetes==${KUBERNETES_SDK_VERSION} \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Download plugins
ADD install-plugins.sh /
RUN /install-plugins.sh

RUN set -x \
  && cp -a /etc/skel /home/rundeck \
  && usermod --home /home/rundeck rundeck \
  && chown -R rundeck:rundeck /home/rundeck \
  ;

WORKDIR /home/rundeck

VOLUME ["/var/lib/rundeck/data", "/var/lib/rundeck/logs", "/var/rundeck", "/var/log/rundeck"]

# Add config files
COPY run.sh /run.sh
COPY ansible-bootstrap/ /ansible-bootstrap/

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/run.sh"]
