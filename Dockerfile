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
ENV AWS_CLI_VERSION=1.19.111
ENV AWS_CLI_CHECKSUM=b23bbd35962acf920624ceffc4fd4d0fe9612fb274bdf296a115f92b959184ca
RUN set -x \
  && apt-get update \
  && apt-get -y install python unzip \
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
ENV DUMB_INIT_VERSION=1.2.5
ENV DUMB_INIT_CHECKSUM=e874b55f3279ca41415d290c512a7ba9d08f98041b28ae7c2acb19a545f1c4df
RUN set -x \
  && wget --no-verbose https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 -O /tmp/dumb-init \
  && echo "${DUMB_INIT_CHECKSUM}  dumb-init" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum dumb-init)"; exit 1; )) \
  && mv /tmp/dumb-init /usr/local/bin/ \
  && chmod +x /usr/local/bin/dumb-init \
  && rm -f /tmp/SHA256SUM \
  ;

# Install Rundeck
ENV RUNDECK_VERSION=3.4.2.20210803-1_all
ENV RUNDECK_CHECKSUM=9828978b862d7e617dba29dd5da6485ae45d20692002c367d5d2e67783609e67
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
ENV RUNDECK_CLI_VERSION=1.3.10-1_all
ENV RUNDECK_CLI_CHECKSUM=e9f6fb2cd051b32b452a055ce5aa7e354b21e011a9c00c76e3d624c2338a3736
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
  && echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list \
  && wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/Debian_10/Release.key -O- | apt-key add - \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y skopeo \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install apprise github.com/caronc/apprise
RUN set -x \
  && apt-get update \
  && apt-get install -y python-pip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && pip install apprise==0.9.3 \
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
