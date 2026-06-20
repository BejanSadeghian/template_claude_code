FROM node:24-trixie

ARG TZ
ENV TZ="$TZ"
ARG CLAUDE_CODE_VERSION=latest

# Base dev tools + iOS-friendly utilities (the iOS app itself builds on macOS host)
RUN apt-get update && apt-get install -y --no-install-recommends \
    less git procps sudo fzf zsh man-db unzip gnupg2 gh rsync \
    iptables ipset iproute2 dnsutils aggregate jq \
    nano vim curl wget ca-certificates \
    ripgrep fd-find bat \
    python3 python3-pip python3-venv pipx \
    build-essential \
    sqlite3 postgresql-client \
    sox \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Symlink fd (Debian ships as fdfind) and bat (batcat)
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd && \
    ln -sf /usr/bin/batcat /usr/local/bin/bat

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash + zsh history
RUN mkdir -p /commandhistory && \
    touch /commandhistory/.bash_history /commandhistory/.zsh_history && \
    chown -R $USERNAME /commandhistory

ENV DEVCONTAINER=true

RUN mkdir -p /workspace /home/node/.claude && \
    chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

ARG GIT_DELTA_VERSION=0.19.2
RUN ARCH=$(dpkg --print-architecture) && \
    wget -q "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Install Railway CLI (used by /verify and runbook)
RUN curl -fsSL https://railway.app/install.sh | sh || true

# Install Azure CLI (so Azure deploys work out of the box)
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash || true

USER node

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin:/home/node/.local/bin
ENV SHELL=/bin/zsh
ENV EDITOR=nano
ENV VISUAL=nano

ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
    -p git -p fzf -p z -p sudo -p history-substring-search \
    -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
    -a "source /usr/share/doc/fzf/examples/completion.zsh" \
    -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    -a "alias claude='claude --dangerously-skip-permissions'" \
    -a "alias setup='bash /workspace/scripts/setup.sh'" \
    -a "alias module='bash /workspace/scripts/module.sh'" \
    -a "alias update='bash /workspace/scripts/update.sh'" \
    -a "alias template-status='bash /workspace/scripts/template-status.sh'" \
    -a "alias template-update='bash /workspace/scripts/template-sync.sh'" \
    -x

# Same aliases for bash (devcontainer terminals occasionally use it)
RUN printf "alias claude='claude --dangerously-skip-permissions'\nalias setup='bash /workspace/scripts/setup.sh'\nalias module='bash /workspace/scripts/module.sh'\nalias update='bash /workspace/scripts/update.sh'\nalias template-status='bash /workspace/scripts/template-status.sh'\nalias template-update='bash /workspace/scripts/template-sync.sh'\n" >> /home/node/.bashrc

# Claude Code + globally useful CLIs
RUN npm install -g \
    @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    pnpm \
    typescript \
    tsx \
    vitest \
    playwright \
    @playwright/test

# Common Python tooling for API work and testing
RUN pip install --user --break-system-packages \
    httpie \
    pre-commit \
    ruff \
    pytest \
    pytest-asyncio || true

# Firewall script + sudo allowlist
COPY init-firewall.sh /usr/local/bin/
COPY post-create.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh /usr/local/bin/post-create.sh && \
    echo "node ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/node-firewall && \
    chmod 0440 /etc/sudoers.d/node-firewall
USER node
