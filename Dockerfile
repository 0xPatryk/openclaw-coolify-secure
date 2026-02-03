FROM node:lts-bookworm-slim

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_ROOT_USER_ACTION=ignore

# ========================================
# STAGE 1: Create non-root user and set up directories
# ========================================
RUN groupadd -r -g 999 openclaw && \
    useradd -r -u 999 -g openclaw -m -d /home/openclaw -s /bin/bash openclaw && \
    mkdir -p /home/openclaw/.openclaw /home/openclaw/openclaw-workspace /app

# ========================================
# STAGE 2: Define Environment Variables for User-Writable Install Paths
# ========================================
# All tools will install to /home/openclaw instead of system directories
ENV HOME=/home/openclaw \
    OPENCLAW_WORKSPACE=/home/openclaw/openclaw-workspace \
    # BUN - Install to user home
    BUN_INSTALL=/home/openclaw/.bun \
    BUN_INSTALL_GLOBAL_DIR=/home/openclaw/.bun/install/global \
    BUN_INSTALL_CACHE_DIR=/home/openclaw/.bun/cache \
    # NPM - Install global packages to user home
    NPM_CONFIG_PREFIX=/home/openclaw/.npm-global \
    NPM_CONFIG_CACHE=/home/openclaw/.npm-cache \
    # Python - User install mode
    PYTHONUSERBASE=/home/openclaw/.local \
    PIP_CACHE_DIR=/home/openclaw/.pip-cache \
    PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring \
    # Go - User workspace
    GOPATH=/home/openclaw/go \
    GOCACHE=/home/openclaw/.cache/go-build \
    GOMODCACHE=/home/openclaw/go/pkg/mod \
    # UV - User install
    UV_INSTALL_DIR=/home/openclaw/.cargo/bin \
    # Claude/Kimi and other tools
    XDG_CACHE_HOME=/home/openclaw/.cache \
    XDG_CONFIG_HOME=/home/openclaw/.config \
    # PATH - Include all user-writable bin directories
    PATH="/home/openclaw/.bun/bin:/home/openclaw/.bun/install/global/bin:/home/openclaw/.npm-global/bin:/home/openclaw/.local/bin:/home/openclaw/.cargo/bin:/home/openclaw/go/bin:/usr/local/go/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ========================================
# STAGE 3: Install system packages as ROOT
# ========================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    python3 \
    python3-pip \
    python3-venv \
    jq \
    lsof \
    openssl \
    ca-certificates \
    gnupg \
    ripgrep fd-find fzf bat \
    pandoc \
    poppler-utils \
    ffmpeg \
    imagemagick \
    graphviz \
    sqlite3 \
    pass \
    chromium \
    passwd \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CE CLI (Latest) to support API 1.44+
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Install Go (Latest) - system-wide but usable by user
RUN curl -L "https://go.dev/dl/go1.23.4.linux-amd64.tar.gz" -o go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz

# Install Cloudflare Tunnel (cloudflared)
RUN ARCH=$(dpkg --print-architecture) && \
    curl -L --output cloudflared.deb "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb" && \
    dpkg -i cloudflared.deb && \
    rm cloudflared.deb

# Install GitHub CLI (gh)
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Create tool directories and set ownership (as root)
RUN mkdir -p \
    /home/openclaw/.bun/bin \
    /home/openclaw/.bun/install/global \
    /home/openclaw/.bun/cache \
    /home/openclaw/.npm-global/bin \
    /home/openclaw/.npm-cache \
    /home/openclaw/.local/bin \
    /home/openclaw/.pip-cache \
    /home/openclaw/.cache \
    /home/openclaw/.config \
    /home/openclaw/go/bin \
    /home/openclaw/go/pkg/mod \
    /home/openclaw/.cache/go-build \
    /home/openclaw/.cargo/bin \
    /home/openclaw/.claude/bin \
    /home/openclaw/.kimi/bin \
    /home/openclaw/.openclaw \
    /home/openclaw/openclaw-workspace \
    && chown -R openclaw:openclaw /home/openclaw \
    && chmod -R 755 /home/openclaw

# Debian aliases
RUN ln -s /usr/bin/fdfind /usr/bin/fd || true && \
    ln -s /usr/bin/batcat /usr/bin/bat || true

# ========================================
# STAGE 4: Switch to non-root user for tool installation
# ========================================
USER openclaw
WORKDIR /home/openclaw

# Install Bun (as openclaw user)
ENV BUN_INSTALL_NODE=0
RUN curl -fsSL https://bun.sh/install | bash

# Install uv (Python tool manager) as user
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Vercel, Marp, QMD (as openclaw user)
RUN bun install -g vercel @marp-team/marp-cli https://github.com/tobi/qmd && hash -r

# Install OpenClaw
ARG OPENCLAW_BETA=false
ENV OPENCLAW_BETA=${OPENCLAW_BETA} \
    OPENCLAW_NO_ONBOARD=1

RUN if [ "$OPENCLAW_BETA" = "true" ]; then \
    npm install -g openclaw@beta; \
    else \
    npm install -g openclaw; \
    fi && \
    if command -v openclaw >/dev/null 2>&1; then \
    echo "✅ openclaw binary found"; \
    else \
    echo "❌ OpenClaw install failed (binary 'openclaw' not found)"; \
    exit 1; \
    fi

RUN bun pm -g untrusted || true

# AI Tool Suite (as openclaw user)
RUN bun install -g @openai/codex @google/gemini-cli opencode-ai @steipete/summarize @hyperbrowser/agent

# Install Claude Code (as openclaw user)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install Kimi (as openclaw user)
RUN curl -L https://code.kimi.com/install.sh | bash

# ========================================
# STAGE 5: Python tools (as openclaw user with --user flag)
# ========================================
RUN pip3 install --user --break-system-packages ipython csvkit openpyxl python-docx pypdf botasaurus browser-use playwright && \
    /home/openclaw/.local/bin/playwright install-deps || true

# ========================================
# STAGE 6: Final setup (switch back to root temporarily for system-wide setup)
# ========================================
USER root

# Copy application files
COPY . /app/

# Set up symlinks and permissions
RUN ln -sf /home/openclaw/.claude/bin/claude /usr/local/bin/claude || true && \
    ln -sf /home/openclaw/.kimi/bin/kimi /usr/local/bin/kimi || true && \
    ln -sf /app/scripts/openclaw-approve.sh /usr/local/bin/openclaw-approve && \
    chmod +x /app/scripts/*.sh /usr/local/bin/openclaw-approve && \
    chown -R openclaw:openclaw /app

WORKDIR /app

EXPOSE 18789

# ========================================
# STAGE 7: Final switch to non-root user
# ========================================
USER openclaw

CMD ["bash", "/app/scripts/bootstrap.sh"]
