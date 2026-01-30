# OpenClaw (Coolify Edition)

**Your Assistant. Your Machine. Your Rules.**

OpenClaw is an open agent platform that runs on your machine and works from the chat apps you already use. WhatsApp, Telegram, Discord, Slack, Teams—wherever you are, your AI assistant follows.

Unlike SaaS assistants where your data lives on someone else’s servers, OpenClaw runs where you choose—laptop, homelab, or VPS. Your infrastructure. Your keys. Your data.

---

## � Architecture: The AI Office

Think of this Docker container not as an app, but as an **Office Building**.

### 1. The Staff (Multi-Agent System)
*   **The Manager (Gateway)**: The main `openclaw` process. It hires "staff" to do work.
*   **The Workers (Sandboxes)**: When you ask for a complex coding task, the Manager spins up **isolated Docker containers** (sub-agents).
    *   They have their own Linux tools (Python, Node, Go).
    *   They work safely in a sandbox, then report back.
    *   *Managed via: Docker Socket Proxy (Secure Sidecar).*

### 2. Corporate Memory (Long-Term Storage)
Your office never forgets, thanks to a 3-tier memory architecture:
*   **The Filing Cabinet (`openclaw-workspace`)**: A persistent Docker Volume where agents write code, save files, and store heavy data. Survives restarts.
*   **The Brain (Internal SQLite)**: OpenClaw's native transactional memory for conversations and facts.
*   **The Library (Qdrant)**: A dedicated Vector Database (`qdrant:6333`) for advanced RAG.
*   **The Newsroom (Miniflux)**: An RSS feed reader (`miniflux:8080`) backed by Postgres. Your agent can stay updated on tech news automatically.
*   **The Archive (Linkding)**: A self-hosted bookmark manager (`linkding:9090`) to save important research, docs, and links.
*   **Web Search (SearXNG)**: A private, tracking-free search engine (`searxng:8080`) for the agent's research.

### 3. The Security Vault
Your agent can securely manage credentials without leaking them:
*   **Bitwarden (`rbw`)**: Securely fetch secrets from your Bitwarden vault.
*   **Pass**: Local GPG-encrypted password storage for the agent's exclusive use.

### 4. The Public Front Door (Cloudflare Tunnel)
Need to show a client your work?
*   The agent can start a web server (e.g., Next.js on port 3000).
*   It uses `cloudflared` to instantly create a **secure public URL** (e.g., `https://project-viz.trycloudflare.com`).
*   *No router port forwarding required.*

### 5. Advanced Web Utilities
*   **Universal Scraper**: 5-stage fallback engine (Curl -> AI Browser -> Anti-Detect) to read any website.
*   **Research Tools**: `hackernews-cli`, `tuir` (Reddit), `newsboat` (RSS), `sonos` control.

### 6. Zero-Config & Production Ready
*   **Pre-installed Tools**: `gh` (GitHub), `vercel`, `bun`, `python`, `ripgrep`.
*   **Office Suite**: `pandoc` (Docs), `marp` (Slides), `csvkit` (Excel), `qmd` (Local AI Search).
*   **Secure**: All sub-agents are firewalled.
*   **Self-Healing**: Docker volumes ensure `openclaw-config` and `openclaw-workspace` persist forever.

---

## 🚀 Easy Setup on Coolify

1.  Open your Coolify Dashboard.
2.  Navigate to **Project** > **New**.
3.  Select **Public Repository**.
4.  Enter the URL: `https://github.com/essamamdani/moltbot-coolify`
5.  **Important**: When generating a domain, remember to append the port number (e.g., `:18789`) after the domain.
    *   Example: `https://openclaw.your-domain.com:18789`
6.  Click **Continue**.

---

## 🛠️ Environment Configuration

Before deploying, configure your **Environment Variables** in Coolify. These keys unlock different AI models and features.

### 🧠 AI Models (Required: At least one)
You must provide **at least one** of the following keys to power the agent.

| Variable | Description |
| :--- | :--- |
| `OPENAI_API_KEY` | Required for many core reasoning tasks (OpenAI models). |
| `ANTHROPIC_API_KEY` | Unlocks Claude 3.5 Sonnet / Opus (highly recommended for coding). |
| `MINIMAX_API_KEY` | Unlocks MiniMax M2.1 models (great performance/price). |
| `GEMINI_API_KEY` | Google Gemini models. |
| `KIMI_API_KEY` | Kimi / Moonshot AI models. |
| `MOONSHOT_API_KEY` | Alias for `KIMI_API_KEY`. |

### 🔌 Integrations (Optional)
Enable public URLs, deployments, or chat channels.

| Variable | Description |
| :--- | :--- |
| `TELEGRAM_BOT_TOKEN` | If using Telegram (see Channel Setup below). |
| `CF_TUNNEL_TOKEN` | Cloudflare Tunnel token for exposing agent-created apps (Public URLs). |
| `VERCEL_TOKEN` | For deploying apps to Vercel (`vercel deploy --token ...`). |
| `GITHUB_TOKEN` | For creating repos/PRs (`gh auth login --with-token`). |
| `OPENCLAW_GATEWAY_PORT` | Internal port (Default: `18789`). Only change if needed. |

> **Pro Tip**: You can simply copy the contents of [.env.example](.env.example) into Coolify's bulk edit view.

---

## 📦 Post-Deployment (Ready)
Once the container is running and healthy:

1.  **Access the Dashboard**:
    - Open the **Service Logs** in Coolify.
    - Look for: `🦞 OPENCLAW READY`.
    - You will see a **Dashboard URL** with a token (e.g., `http://.../?token=xyz`).
    - **Click that link** to access your OpenClaw Gateway UI.
2.  **Approve Your Device**:
    - You will see an "Unauthorized" or pairing screen (this is normal).
    - Open the **Service Terminal** in Coolify.
    - Run: `openclaw-approve`
    - > [!WARNING]
    - > **Security Note**: `openclaw-approve` is a break-glass utility that auto-accepts ALL pending pairing requests. Only run this immediately after accessing the URL yourself. Do not leave it running or use it when you don't recognize a request.
3.  **Guided Onboarding**: To configure your agent's personality and skills:
    - In the terminal, run: `openclaw onboard`
    - Follow the interactive wizard.
4.  **Configure Channels**: Go to the **Channels** tab in the dashboard to link WhatsApp, Telegram, etc.

---

## � Channel Setup

OpenClaw lives where you work. You can connect it to WhatsApp, Telegram, Discord, etc.

### 📱 Telegram
**Fastest setup.**
1.  Talk to **@BotFather** on Telegram.
2.  Create a new bot (`/newbot`) and get the **Token**.
3.  Add `TELEGRAM_BOT_TOKEN` to your Coolify Environment Variables.
4.  **Redeploy** (or just restart).
5.  DM your new bot. It will ask for a **Pairing Code**.
6.  Go to your OpenClaw Dashboard > **Pairing** to approve it.
    *   *Docs: [Telegram Channel Guide](docs/channels/telegram.md)*

### 🟢 WhatsApp
**Requires scanning a QR code.**
1.  Go to your OpenClaw Dashboard (from the logs).
2.  Navigate to **Channels** > **WhatsApp**.
3.  Open WhatsApp on your phone > **Linked Devices** > **Link a Device**.
4.  Scan the QR code shown on the dashboard.
5.  **Done!** You can now chat with OpenClaw.
    *   *Docs: [WhatsApp Channel Guide](docs/channels/whatsapp.md)*

### ⚡ Other Channels
You can verify status or manage other channels (Discord, Slack) via the dashboard or CLI.
*   *CLI Docs: [Channel Management](docs/cli/channels.md)*

---

## 🔒 Security & Sandboxing

- **Authentication**: Dashboard is token-protected. New chat users must be "paired" (approved) first.
- **Docker Proxy**: This setup uses a **Sockety Proxy (Sidecar)** pattern.
    - OpenClaw talks to a restricted Docker API proxy (`tcp://docker-proxy:2375`).
    - **Blocked**: Swarm, Secrets, System, Volumes, and other critical host functions.
    - **Allowed**: Only what's needed for sandboxing (Containers, Images, Networks).
- **Isolation**: Sub-agents run in disposable containers. `SOUL.md` rules forbid the agent from touching your other Coolify services.