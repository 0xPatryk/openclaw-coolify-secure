FROM ghcr.io/moltbot/clawdbot:main

USER root

# Add bootstrap script
COPY scripts/bootstrap.sh /app/scripts/bootstrap.sh
RUN chmod +x /app/scripts/bootstrap.sh

# Ensure the node user owns the necessary directories for state and workspace
RUN mkdir -p /home/node/.clawdbot /home/node/clawd && \
    chown -R node:node /home/node

# Back to non-root (important for security + review)
USER node