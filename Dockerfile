FROM docker.io/debian:buster

# Set encoding
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Install base packages
RUN set -x \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y wget curl ca-certificates vim jq openssh-client uuid-runtime procps gnupg2 dirmngr db-util libpam-modules libpam0g libpam0g-dev git make lsb-release \
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

# Install AWS CLI
ENV AWS_CLI_VERSION=1.19.16
ENV AWS_CLI_CHECKSUM=5b1af214aa8cc1afe6badd056d3c16d411872d4ab1e5a9da515c3cecbd491de4
RUN set -x \
  && apt-get update \
  && apt-get -y install python unzip \
  && cd /tmp \
  && wget -nv https://s3.amazonaws.com/aws-cli/awscli-bundle-${AWS_CLI_VERSION}.zip -O /tmp/awscli-bundle-${AWS_CLI_VERSION}.zip \
  && echo "${AWS_CLI_CHECKSUM}  awscli-bundle-${AWS_CLI_VERSION}.zip" > /tmp/SHA256SUM \
  && sha256sum -c SHA256SUM \
  && unzip awscli-bundle-${AWS_CLI_VERSION}.zip \
  && /tmp/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws \
  && apt-get -y remove unzip \
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
ENV RUNDECK_VERSION=3.3.12.20210521-1_all
ENV RUNDECK_CHECKSUM=f404f379ce56a719e61f23487a781343847931b69ef128e16ae4ffdb0b7d40a6
RUN set -x \
  && wget --no-verbose -O /tmp/rundeck_${RUNDECK_VERSION}.deb "https://packagecloud.io/pagerduty/rundeck/packages/any/any/rundeck_${RUNDECK_VERSION}.deb/download.deb" \
  && echo "${RUNDECK_CHECKSUM}  rundeck_${RUNDECK_VERSION}.deb" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum rundeck_${RUNDECK_VERSION}.deb)"; exit 1; )) \
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

# Install skopeo
RUN set -x \
  && echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list \
  && wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/Debian_10/Release.key -O- | apt-key add - \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y skopeo \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install apprise github.com/caronc/apprise
RUN set -x \
  && pip install apprise==0.8.6 \
  ;

# Download plugins
COPY install-plugins.sh /
RUN /install-plugins.sh

# Install tools
COPY install-tools.sh /
RUN set -x \
  && mkdir /opt/bin \
  && /install-tools.sh \
  ;

ENV PATH=/usr/local/sbin:/usr/local/bin:/opt/bin:/usr/sbin:/usr/bin:/sbin:/bin

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
