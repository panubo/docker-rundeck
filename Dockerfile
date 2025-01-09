FROM docker.io/debian:bullseye

# Set encoding
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Install base packages
RUN set -x \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y wget curl ca-certificates vim jq openssh-client uuid-runtime procps gnupg2 dirmngr db-util libpam-modules libpam0g libpam0g-dev git make lsb-release gosu skopeo \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install JDK11
RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && mkdir /etc/ssl/certs/java/ \
  && apt-get update \
  && apt-get -y install openjdk-11-jre-headless \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install AWS CLI
ENV AWS_CLI_VERSION=1.32.90 AWS_CLI_CHECKSUM=4ac48cc9df2731fd4d57bee573cc889c083815bb48a7696b8f15cb313c051d69
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
  && rm -rf /tmp/awscli-bundle /tmp/awscli-bundle-${AWS_CLI_VERSION}.zip \
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
  && apt-get install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install Dumb-init
ENV DUMB_INIT_VERSION=1.2.5 \
    DUMB_INIT_CHECKSUM_X86_64=e874b55f3279ca41415d290c512a7ba9d08f98041b28ae7c2acb19a545f1c4df \
    DUMB_INIT_CHECKSUM_AARCH64=b7d648f97154a99c539b63c55979cd29f005f88430fb383007fe3458340b795e
RUN set -x \
  && if [ "$(uname -m)" = "x86_64" ] ; then \
        DUMB_INIT_CHECKSUM="${DUMB_INIT_CHECKSUM_X86_64}"; \
      elif [ "$(uname -m)" = "aarch64" ]; then \
        DUMB_INIT_CHECKSUM="${DUMB_INIT_CHECKSUM_AARCH64}"; \
      fi \
  && wget --no-verbose https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_$(uname -m) -O /tmp/dumb-init \
  && echo "${DUMB_INIT_CHECKSUM}  dumb-init" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum dumb-init)"; exit 1; )) \
  && mv /tmp/dumb-init /usr/local/bin/ \
  && chmod +x /usr/local/bin/dumb-init \
  && rm -f /tmp/SHA256SUM \
  ;

# Install Rundeck
ENV RUNDECK_VERSION=4.17.6.20240402-1_all RUNDECK_CHECKSUM=9b20f4f7536a1fef36a3f057069b2c1c99c43e4ee963e88f0250204c9982c2a6
RUN set -x \
  && wget --no-verbose -O /tmp/rundeck_${RUNDECK_VERSION}.deb "https://packagecloud.io/pagerduty/rundeck/packages/any/any/rundeck_${RUNDECK_VERSION}.deb/download.deb" \
  && echo "${RUNDECK_CHECKSUM}  rundeck_${RUNDECK_VERSION}.deb" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum rundeck_${RUNDECK_VERSION}.deb)"; exit 1; )) \
  && dpkg -i /tmp/rundeck_${RUNDECK_VERSION}.deb \
  && chown -R root:rundeck /etc/rundeck \
  && chmod -R 640 /etc/rundeck/* \
  && rm -f /tmp/rundeck_${RUNDECK_VERSION}.deb /tmp/SHA256SUM \
  && mkdir /tmp/rundeck \
  && chown rundeck:rundeck /tmp/rundeck \
  ;

# Install Rundeck CLI
ENV RUNDECK_CLI_VERSION=2.0.8-1_all RUNDECK_CLI_CHECKSUM=0bd1857b5f84e8ecc91212587cf5c666b2bc8a7f4299461843647f1ff7c90edb
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

# Install apprise github.com/caronc/apprise
RUN set -x \
  && apt-get update \
  && apt-get install -y python3-pip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && pip install apprise==1.7.6 \
  ;

# Install k8s-sidecar
RUN set -x \
  && cd /tmp \
  && git clone https://github.com/macropin/k8s-sidecar.git --branch fix/file-mode \
  && cd k8s-sidecar \
  && cd src \
  && pip install --no-cache-dir -r requirements.txt \
  && rm requirements.txt \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && cp -a /tmp/k8s-sidecar/src/ /sidecar \
  && rm -rf /tmp/k8s-sidecar \
  ;

# Install Image Triggers
ENV IMAGE_TRIGGERS_VERSION=0.0.4 \
    IMAGE_TRIGGERS_CHECKSUM_X86_64=d48257a84ca50a9d955a5e41ba954e68724ad0a6baf5ecf4fab8120262925efc \
    IMAGE_TRIGGERS_CHECKSUM_AARCH64=b242e58d4502e11542d64e5d4905c7f480a0444a3081b03ba9f3d6d7256ef298
RUN set -x \
  && if [ "$(uname -m)" = "x86_64" ] ; then \
        IMAGE_TRIGGERS_CHECKSUM="${IMAGE_TRIGGERS_CHECKSUM_X86_64}"; \
        ARCH="linux_amd64"; \
      elif [ "$(uname -m)" = "aarch64" ]; then \
        IMAGE_TRIGGERS_CHECKSUM="${IMAGE_TRIGGERS_CHECKSUM_AARCH64}"; \
        ARCH="linux_arm64"; \
      fi \
  && wget --no-verbose https://github.com/panubo/image-triggers/releases/download/v${IMAGE_TRIGGERS_VERSION}/image-triggers_${IMAGE_TRIGGERS_VERSION}_${ARCH}.tar.gz -O /tmp/image-triggers.tar.gz \
  && echo "${IMAGE_TRIGGERS_CHECKSUM}  image-triggers.tar.gz" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum image-triggers.tar.gz)"; exit 1; )) \
  && tar -C /usr/local/bin -zxf /tmp/image-triggers.tar.gz \
  && chmod +x /usr/local/bin/image-triggers \
  && rm -f /tmp/image-triggers.tar.gz /tmp/SHA256SUM \
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

# Download helm plugins
# Set HELM_PLUGINS since we can't install these in /home/rundeck since it is normally mounted into the container
COPY install-helm-plugins.sh /
RUN gosu rundeck /install-helm-plugins.sh
ENV HELM_PLUGINS="/var/lib/rundeck/.local/share/helm/plugins"

ENV PATH=/usr/local/sbin:/usr/local/bin:/opt/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN set -x \
  && cp -a /etc/skel /home/rundeck \
  && usermod --home /home/rundeck rundeck \
  && chown -R rundeck:rundeck /home/rundeck \
  && sed -i 's/HashKnownHosts.*/HashKnownHosts no/' /etc/ssh/ssh_config \
  ;

WORKDIR /home/rundeck

VOLUME ["/var/lib/rundeck/data", "/var/lib/rundeck/logs", "/var/rundeck", "/var/log/rundeck"]

# Add config files
COPY run.sh /run.sh
COPY sidecar.sh /sidecar.sh
COPY ansible-bootstrap/ /ansible-bootstrap/
COPY run-h2-v2-migration.sh /run-h2-v2-migration.sh

ENV RD_URL http://localhost:4440
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/run.sh"]
