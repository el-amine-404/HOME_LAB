# Open WebUI

Open WebUI is the private chat interface for Batlab's existing Ollama service.
It does not install another Ollama instance or duplicate its models.

## Storage layout

```text
${VOLUMES_ROOT}/open-webui/   accounts, chats, uploads and application database
${VOLUMES_ROOT}/ollama/       Ollama models shared with Paperless-GPT
```

The Open WebUI directory contains valuable state and is included in the server's
existing Restic backup of `${VOLUMES_ROOT}`. Ollama models can be downloaded
again and do not need a second copy.

## Prepare and start

Generate a stable session-encryption secret on the server. Keep it in the
untracked `compose/.env`; changing or losing it can invalidate encrypted session
data.

```bash
openssl rand -hex 32
```

Add the result and the new non-secret variables from `compose/.env.example`:

```dotenv
OPEN_WEBUI_SECRET_KEY=replace_with_the_generated_value
```

Then run:

```bash
make setup
make config STACK=open-webui
make up STACK=open-webui
make logs STACK=open-webui
```

Open `http://open-webui.homelab.lan`. The first registered account becomes the
administrator. Immediately go to **Admin Panel > Settings > General** and turn
off new-user signups. Create any additional users deliberately from the admin
panel.

## Operations

Open WebUI reaches Ollama at `http://ollama:11434` on Docker's private
`home_server` network. Ollama is intentionally not exposed through Caddy.

```bash
# See service and health state
make status STACK=open-webui

# Follow logs
make logs STACK=open-webui

# Pull and recreate after changing the pinned image tag
make update STACK=open-webui
```

The UI cannot make this server's CPU inference fast. Keep one small quantized
model loaded at a time on the current hardware; Ollama's existing limits enforce
that policy.
