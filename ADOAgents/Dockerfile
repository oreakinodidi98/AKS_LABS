FROM debian:12-slim

ENV TARGETARCH="linux-x64"
ENV AGENT_TOOLSDIRECTORY="azp/_work/_tool"
ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
  bash \
  build-essential \
  ca-certificates \
  curl \
  git \
  gnupg \
  jq \
  libbz2-1.0 \
  libffi8 \
  libgdbm6 \
  libicu72 \
  liblzma5 \
  libncursesw6 \
  libreadline8 \
  libsqlite3-0 \
  libssl3 \
  lsb-release \
  procps \
  sudo \
  tk \
  unzip \
  xz-utils \
  zlib1g && \
  rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

WORKDIR /azp

COPY ./start.sh ./

RUN chmod +x ./start.sh && \
  mkdir -p /azp/_work/_tool && \
  useradd -m -d /home/agent -s /bin/bash agent && \
  usermod -aG sudo agent && \
  echo "agent ALL=(ALL) NOPAASSWD:ALL" > /etc/sudoers.d/agent && \
  chmod 0440 /etc/sudoers.d/agent && \
  chown -R agent:agent /azp /home/agent

USER agent

ENTRYPOINT [ "./start.sh" ]
