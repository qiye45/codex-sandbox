FROM ubuntu:24.04

# Install basic development tools, ca-certificates, and iptables/ipset, then clean up apt cache to reduce image size
RUN apt-get update && apt-get install -y --no-install-recommends \
  aggregate \
  build-essential \
  ca-certificates \
  curl \
  dnsutils \
  fzf \
  gh \
  git \
  libbz2-dev \
  libffi-dev \
  libgdbm-dev \
  liblzma-dev \
  libncursesw5-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  libuuid1 \
  gnupg2 \
  iproute2 \
  ipset \
  iptables \
  jq \
  less \
  man-db \
  tk-dev \
  procps \
  uuid-dev \
  unzip \
  wget \
  ripgrep \
  xz-utils \
  zlib1g-dev \
  zsh \
  && rm -rf /var/lib/apt/lists/*

# Install Node.js 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

# Install Go (multi-arch)
ARG GO_VERSION=1.25.7
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
    amd64) GO_ARCH='amd64' ;; \
    arm64) GO_ARCH='arm64' ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
  esac \
  && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tar.gz \
  && rm -rf /usr/local/go \
  && tar -C /usr/local -xzf /tmp/go.tar.gz \
  && rm -f /tmp/go.tar.gz

# Install Python 3.13.5 from source
ARG PYTHON_VERSION=3.13.5
RUN curl -fsSL "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" -o /tmp/python.tgz \
  && tar -xzf /tmp/python.tgz -C /tmp \
  && cd "/tmp/Python-${PYTHON_VERSION}" \
  && ./configure --enable-optimizations --with-ensurepip=install \
  && make -j"$(nproc)" \
  && make altinstall \
  && ln -sf /usr/local/bin/python3.13 /usr/local/bin/python3 \
  && ln -sf /usr/local/bin/python3.13 /usr/local/bin/python \
  && ln -sf /usr/local/bin/pip3.13 /usr/local/bin/pip3 \
  && ln -sf /usr/local/bin/pip3.13 /usr/local/bin/pip \
  && rm -rf "/tmp/Python-${PYTHON_VERSION}" /tmp/python.tgz

# Set up npm global directory with proper permissions
RUN mkdir -p /usr/local/share/npm-global \
  && chmod 755 /usr/local/share/npm-global

# Set up Go workspace directory
RUN mkdir -p /go/bin /go/pkg /go/src \
  && chmod -R 755 /go

# Install codex from npm globally
ARG CODEX_VERSION=latest
RUN npm install -g @openai/codex@${CODEX_VERSION} \
    && npm cache clean --force

# Set npm global config for any user
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV GOPATH=/go
ENV PATH=/usr/local/bin:/usr/local/sbin:/usr/local/share/npm-global/bin:/usr/local/go/bin:/go/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Inside the container we consider the environment already sufficiently locked
# down, therefore instruct Codex CLI to allow running without sandboxing.
ENV CODEX_UNSAFE_ALLOW_NO_SANDBOX=1
