FROM docker.io/debian:bullseye

# Set encoding
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Install base packages
RUN set -x \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y wget curl ca-certificates vim jq openssh-client uuid-runtime procps gnupg2 dirmngr db-util libpam-modules libpam0g libpam0g-dev git make lsb-release \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install JDK11
RUN set -x \
  && apt-get update \
  && apt-get -y install openjdk-11-jre-headless \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install AWS CLI
ENV AWS_CLI_VERSION=1.22.85 AWS_CLI_CHECKSUM=f6f8f3635daa82049d02b828169e43c9db09a9fc791fdf4582d62c74060baf32
RUN set -x \
  && apt-get update \
  && apt-get -y install python3 python3-venv unzip \
  && ln -s /usr/bin/python3 /usr/bin/python \
  && cd /tmp \
  && wget -nv https://s3.amazonaws.com/aws-cli/awscli-bundle-${AWS_CLI_VERSION}.zip -O /tmp/awscli-bundle-${AWS_CLI_VERSION}.zip \
  && echo "${AWS_CLI_CHECKSUM}  awscli-bundle-${AWS_CLI_VERSION}.zip" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum awscli-bundle-${AWS_CLI_VERSION}.zip)"; exit 1; )) \
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
ENV DUMB_INIT_VERSION=1.2.5 DUMB_INIT_CHECKSUM=e874b55f3279ca41415d290c512a7ba9d08f98041b28ae7c2acb19a545f1c4df
RUN set -x \
  && wget --no-verbose https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 -O /tmp/dumb-init \
  && echo "${DUMB_INIT_CHECKSUM}  dumb-init" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum dumb-init)"; exit 1; )) \
  && mv /tmp/dumb-init /usr/local/bin/ \
  && chmod +x /usr/local/bin/dumb-init \
  && rm -f /tmp/SHA256SUM \
  ;

# Install Rundeck
ENV RUNDECK_VERSION=4.0.1.20220404-1_all RUNDECK_CHECKSUM=89df16e165ea826b8e99e0b9216d9247636fba9f9c199f393f56b74d58b06d7c
RUN set -x \
  && wget --no-verbose -O /tmp/rundeck_${RUNDECK_VERSION}.deb "https://packagecloud.io/pagerduty/rundeck/packages/any/any/rundeck_${RUNDECK_VERSION}.deb/download.deb" \
  && echo "${RUNDECK_CHECKSUM}  rundeck_${RUNDECK_VERSION}.deb" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum rundeck_${RUNDECK_VERSION}.deb)"; exit 1; )) \
  && dpkg -i /tmp/rundeck_${RUNDECK_VERSION}.deb \
  && chown -R root:rundeck /etc/rundeck \
  && chmod -R 640 /etc/rundeck/* \
  && rm -f /tmp/rundeck_${RUNDECK_VERSION}.deb /tmp/SHA256SUM \
  ;

# Install Rundeck CLI
ENV RUNDECK_CLI_VERSION=1.3.11-1_all RUNDECK_CLI_CHECKSUM=ad0623ba26aeaf98c27147766f1d1c167b64cd748e88f14c7a06312be784ee8f
RUN set -x \
  && wget --no-verbose -O /tmp/rundeck_${RUNDECK_CLI_VERSION}.deb "https://packagecloud.io/pagerduty/rundeck/packages/any/any/rundeck-cli_${RUNDECK_CLI_VERSION}.deb/download.deb" \
  && echo "${RUNDECK_CLI_CHECKSUM}  rundeck_${RUNDECK_CLI_VERSION}.deb" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum rundeck_${RUNDECK_CLI_VERSION}.deb)"; exit 1; )) \
  && dpkg -i /tmp/rundeck_${RUNDECK_CLI_VERSION}.deb \
  && rm -f /tmp/rundeck_${RUNDECK_CLI_VERSION}.deb /tmp/SHA256SUM \
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
  && echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_11/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list \
  && wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/Debian_11/Release.key -O- | apt-key add - \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y skopeo \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install apprise github.com/caronc/apprise
RUN set -x \
  && apt-get update \
  && apt-get install -y python3-pip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && pip install apprise==0.9.7 \
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

ENV RD_URL http://localhost:4440
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/run.sh"]
