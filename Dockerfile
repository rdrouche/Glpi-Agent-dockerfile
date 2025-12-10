FROM ubuntu:24.04

# docker compose run --entrypoint bash glpi-agent

LABEL org.opencontainers.image.authors="Romain" \
      com.rdritcom.ubuntu_version="24.04" \
      com.rdritcom.glpi-agent="1.15" 

ENV DEBIAN_FRONTEND=noninteractive
ENV GLPI_AGENT_VERSION=1.15
ENV GLPI_AGENT_URL=https://github.com/glpi-project/glpi-agent/releases/download/${GLPI_AGENT_VERSION}/glpi-agent_${GLPI_AGENT_VERSION}_linux_all.deb
ENV GLPI_AGENT_NET_URL=https://github.com/glpi-project/glpi-agent/releases/download/${GLPI_AGENT_VERSION}/glpi-agent-task-network_${GLPI_AGENT_VERSION}-1_all.deb
ENV GLPI_AGENT_INSTALLER_URL=https://github.com/glpi-project/glpi-agent/releases/download/${GLPI_AGENT_VERSION}/glpi-agent-${GLPI_AGENT_VERSION}-linux-installer.pl

# Update + base deps
RUN apt-get update && apt-get install -y \
    curl \
    perl \
    snmp \
    snmp-mibs-downloader \
    dmidecode \ 
    libsmbclient \
    libsnmp-dev \
    ca-certificates \
    libcrypt-des-perl \
    libnet-snmp-perl \
    libnet-nbname-perl \
    libdigest-hmac-perl \
    libnet-ip-perl \
    libparallel-forkmanager-perl \
    ucf \
    libnet-cups-perl \
    libnet-ssh2-perl \
    libwww-perl \
    libparse-edid-perl \
    libproc-daemon-perl \
    libuniversal-require-perl \
    libfile-which-perl \
    libxml-libxml-perl \
    libyaml-perl \
    libtext-template-perl \
    libcpanel-json-xs-perl \
    pciutils \
    usbutils \
    libhttp-daemon-perl \
    libyaml-tiny-perl \
    libossp-uuid-perl \
    libdatetime-perl \
    libsocket-getaddrinfo-perl \
    hdparm \
    util-linux \
    net-tools \
    libio-socket-ssl-perl \
    usb.ids \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L -o /tmp/glpi-agent-installer.pl "$GLPI_AGENT_INSTALLER_URL"
RUN perl /tmp/glpi-agent-installer.pl --install --force --type=network --verbose --no-question --skip=dmidecode,usb.ids --no-p2p --no-compression --no-ssl-check --debug=DEBUG || true
RUN rm /tmp/glpi-agent-installer.pl

# Persist config
VOLUME ["/etc/glpi-agent", "/var/lib/glpi-agent"]

# Web UI port
EXPOSE 62354

# Copier l'entrypoint
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]