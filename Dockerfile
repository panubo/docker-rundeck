FROM docker.io/debian:bookworm

# Set encoding
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Install base packages
RUN set -x \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y wget curl ca-certificates vim jq openssh-client uuid-runtime procps gnupg2 dirmngr db-util libpam-modules libpam0g libpam0g-dev git make lsb-release gosu skopeo unzip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install Java, AWS CLI, ansible and python3-pip
RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && mkdir /etc/ssl/certs/java/ \
  && apt-get update \
  && apt-get -y install openjdk-17-jre-headless awscli ansible python3-pip pipx \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install apprise with pipx (the bookworm version of pipx doesn't support --global so we're setting env vars)
RUN set -x \
  && PIPX_HOME=/opt/pipx \
  && PIPX_BIN_DIR=/usr/local/bin \
  && PIPX_MAN_DIR=/usr/local/share/man \
  && export PIPX_HOME PIPX_BIN_DIR PIPX_MAN_DIR \
  && pipx install apprise==1.9.3 \
  ;

# Install Google Cloud SDK
RUN set -x \
  && export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" \
  && echo "deb [signed-by=/etc/apt/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl -sSf https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/cloud.google.gpg \
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

# Install rundeck rundeck-cli
# Available rundeck versions can be found by execing into a running container and running `apt list -a rundeck` and `apt list -a rundeck-cli`
# We are explicitly creating the rundeck group and user so the ids don't change
ENV RUNDECK_VERSION=5.15.0.20250902-1 RUNDECK_CLI_VERSION=2.0.9-1
COPY rundeck.asc /etc/apt/keyrings/rundeck.asc
COPY rundeck.sources /etc/apt/sources.list.d/rundeck.sources
RUN set -x \
  && groupadd -g 104 rundeck \
  && useradd --uid 103 --comment "Rundeck user account" --home-dir /home/rundeck --no-create-home --shell /usr/sbin/nologin --gid 104 rundeck \
  && apt update \
  && apt install rundeck=${RUNDECK_VERSION} rundeck-cli=${RUNDECK_CLI_VERSION} \
  && apt clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Extract h2 jar from rundeck
COPY h2-shell.sh /opt/bin/h2-shell.sh
RUN set -x \
  && mkdir /tmp/rundeck \
  && cd /tmp/rundeck \
  && unzip /var/lib/rundeck/bootstrap/rundeck-*.war \
  && cp WEB-INF/lib/h2-*.jar /opt/bin/h2.jar \
  && cd / \
  && rm -rf /tmp/rundeck \
  ;

# Install k8s-sidecar
RUN set -x \
  && cd /tmp \
  && git clone https://github.com/kiwigrid/k8s-sidecar.git \
  && cd k8s-sidecar \
  && cd src \
  && pip install --break-system-packages --no-cache-dir -r requirements.txt \
  && rm requirements.txt \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && cp -a /tmp/k8s-sidecar/src/ /sidecar \
  && rm -rf /tmp/k8s-sidecar \
  ;

# Install Image Triggers
ENV IMAGE_TRIGGERS_VERSION=0.1.0 \
  IMAGE_TRIGGERS_CHECKSUM_X86_64=02113698a6288c3181e0fc90c3941795b30e09a3d4bca49b3fb9ba45b8ceb712 \
  IMAGE_TRIGGERS_CHECKSUM_AARCH64=a85f3e04494605b79dfbbd9717366029eb7287214c4eb5048fcf8d14f8c9a0af
RUN set -x \
  && if [ "$(uname -m)" = "x86_64" ] ; then \
  IMAGE_TRIGGERS_CHECKSUM="${IMAGE_TRIGGERS_CHECKSUM_X86_64}"; \
  ARCH="amd64"; \
  elif [ "$(uname -m)" = "aarch64" ]; then \
  IMAGE_TRIGGERS_CHECKSUM="${IMAGE_TRIGGERS_CHECKSUM_AARCH64}"; \
  ARCH="arm64"; \
  fi \
  && wget --no-verbose https://github.com/panubo/image-triggers/releases/download/v${IMAGE_TRIGGERS_VERSION}/image-triggers-${IMAGE_TRIGGERS_VERSION}-linux-${ARCH}.tar.gz -O /tmp/image-triggers.tar.gz \
  && echo "${IMAGE_TRIGGERS_CHECKSUM}  image-triggers.tar.gz" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum image-triggers.tar.gz)"; exit 1; )) \
  && tar -C /usr/local/bin -zxf /tmp/image-triggers.tar.gz --strip-components 1 image-triggers-${IMAGE_TRIGGERS_VERSION}-linux-${ARCH}/image-triggers \
  && chmod +x /usr/local/bin/image-triggers \
  && rm -f /tmp/image-triggers.tar.gz /tmp/SHA256SUM \
  ;

# Install tools
COPY install-tools.sh /
RUN set -x \
  && mkdir -p /opt/bin \
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
COPY triggers.sh /triggers.sh
COPY ansible-bootstrap/ /ansible-bootstrap/
COPY run-h2-v2-migration.sh /run-h2-v2-migration.sh

ENV RD_URL=http://localhost:4440
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/run.sh"]
