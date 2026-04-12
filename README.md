# OpenClaw — Home Assistant Skill

[![OpenClaw](https://img.shields.io/badge/OpenClaw-Compatible-blue)](https://openclaw.ai)
[![Home Assistant](https://img.shields.io/badge/Home%20Assistant-2023.1%2B-41BDF5)](https://www.home-assistant.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-brightgreen)](docs/CHANGELOG.md)

Control and query your **Home Assistant** smart home through your **OpenClaw AI agent** using plain English — via Telegram, the OpenClaw web UI, or any supported channel.

---

## What You Can Do

Once installed, just talk to your bot naturally:

| You say | What happens |
|---|---|
| `Home summary` | Temperatures, lights on, heating status, active switches |
| `What is the temperature?` | All temperature sensors with current readings |
| `Turn off the living room lights` | Calls `light.turn_off` on the matching entity |
| `Is the EV charger on?` | Reads the switch/sensor state |
| `Set the heating to 21 degrees` | Calls `climate.set_temperature` |
| `Show me the front door camera` | Returns snapshot URL or image |
| `List all my automations` | Shows enabled/disabled automations |
| `Is anyone home?` | Reads presence/person entity states |
| `Turn on lights at 80% brightness` | Service call with brightness attribute |
| `What is my energy consumption?` | All power/energy sensors |
| `Lock the front door` | Calls `lock.lock` on the entity |
| `Trigger the evening scene` | Fires `automation.trigger` |

**Works with:** Telegram bot, OpenClaw web UI, any OpenClaw-supported channel.

---

## Requirements

- **OpenClaw** 2026.3.x or newer ([openclaw.ai](https://openclaw.ai))
- **Home Assistant** 2023.1 or newer (REST API enabled by default)
- **Python** 3.9+ on your OpenClaw server
- `requests` + `urllib3` Python packages (usually already present)

---

## Quick Install

```bash
# 1. Clone this repo on your OpenClaw server
git clone https://github.com/nj070574-gif/openclaw-homeassistant-skill
cd openclaw-homeassistant-skill

# 2. Run the installer
bash install.sh
```

The installer will:
- Copy the skill file to your OpenClaw skills directory
- Guide you through token setup
- Test connectivity to your Home Assistant
- Restart OpenClaw automatically

---

## Manual Install (5 steps)

### Step 1 — Copy the skill file

```bash
cp skill/home_assistant.json ~/.openclaw/agents/main/agent/skills/
```

Verify it's valid JSON:
```bash
python3 -c "import json; json.load(open('skill/home_assistant.json')); print('OK')"
```

### Step 2 — Generate a Home Assistant Long-Lived Access Token

1. Open Home Assistant in your browser
2. Click your **profile avatar** (bottom-left)
3. Scroll to **Security → Long-Lived Access Tokens**
4. Click **Create Token**, name it `openclaw`, copy the token

> ⚠️ The token is only shown once — copy it immediately.

### Step 3 — Add credentials to openclaw.json

Open `~/.openclaw/openclaw.json` and add to the `"env"` block:

```json
{
  "env": {
    "HOME_ASSISTANT_URL":   "http://homeassistant.local:8123",
    "HOME_ASSISTANT_TOKEN": "your-long-lived-token-here"
  }
}
```

**Using HTTPS with a self-signed certificate?** Also add:
```json
"HOME_ASSISTANT_SSL_VERIFY": "false"
```

**Using HTTPS with your own CA certificate?**
```json
"HOME_ASSISTANT_CA_CERT": "/path/to/your-ca.crt"
```

**Alternative — secrets file** (if you prefer not to store tokens in openclaw.json):
```bash
mkdir -p ~/.openclaw/workspace/.secrets
echo "your-token-here"              > ~/.openclaw/workspace/.secrets/home_assistant.token
echo "http://homeassistant.local:8123" >> ~/.openclaw/workspace/.secrets/home_assistant.token
chmod 600 ~/.openclaw/workspace/.secrets/home_assistant.token
```

### Step 4 — Restart OpenClaw

```bash
sudo systemctl restart openclaw
```

### Step 5 — Test it

Send your bot:
```
home summary
```

---

## Configuration Reference

The skill checks for credentials in this exact priority order:

| Priority | Location | How to set |
|---|---|---|
| 1 | System env var | `export HOME_ASSISTANT_TOKEN=...` before OpenClaw starts |
| 2 | `openclaw.json` env block | Add `"HOME_ASSISTANT_TOKEN": "..."` to the `env` object |
| 3 | Secrets file | `~/.openclaw/workspace/.secrets/home_assistant.token` |

| Variable | Required | Default | Description |
|---|---|---|---|
| `HOME_ASSISTANT_URL` | Yes | `http://homeassistant.local:8123` | Your HA instance URL |
| `HOME_ASSISTANT_TOKEN` | **Yes** | — | Long-lived access token from HA |
| `HOME_ASSISTANT_SSL_VERIFY` | No | `true` | Set `false` for self-signed HTTPS certs |
| `HOME_ASSISTANT_CA_CERT` | No | — | Path to custom CA cert file |

---

## Telegram Integration

This skill is designed to work seamlessly with OpenClaw's Telegram plugin. Responses are formatted for readability in Telegram chats automatically.

### Telegram plugin config in `openclaw.json`:

```json
{
  "plugins": {
    "allow": ["telegram"],
    "entries": {
      "telegram": {
        "enabled": true,
        "token":   "your-telegram-bot-token-from-botfather",
        "allowed": [your-telegram-chat-id]
      }
    }
  }
}
```

Get your **Telegram bot token** from [@BotFather](https://t.me/BotFather).  
Get your **chat ID** from [@userinfobot](https://t.me/userinfobot).

### Example Telegram session:

```
You: Home summary
Bot: Home Summary - 17:43 12/04/2026

     Temperatures:
       - Living Room: 21.3°C
       - Bedroom: 19.1°C
       - Outside: 8.4°C

     Lights ON: Kitchen, Hallway

     Climate Thermostat: heat, 19.1°C -> 21.0°C

     Switches ON: EV Charger, Garden Irrigation

You: Turn off the kitchen lights
Bot: Called light.turn_off on light.kitchen
     -> light.kitchen is now off
```

---

## Available Snippets

The skill includes **15 reusable Python snippets** that OpenClaw's agent uses to answer your requests:

| Snippet | What it does |
|---|---|
| `_load_config` | Loads credentials from env/openclaw.json/secrets — always runs first |
| `check_api` | Tests HA connectivity and prints version |
| `ha_summary_for_telegram` | Full home summary: temps, lights, climate, switches |
| `get_temperature_sensors` | All temperature sensors with current values |
| `get_lights` | All lights with on/off state and brightness |
| `get_switches` | All switches with on/off state |
| `get_climate` | Thermostats: mode, current temp, target temp |
| `call_service` | Control any device (turn on/off, set temp, toggle) |
| `search_entities` | Find entities by keyword |
| `get_cameras` | List cameras and snapshot URLs |
| `camera_snapshot` | Download a camera image to disk |
| `get_automations` | List all automations with last-triggered time |
| `trigger_automation` | Fire a specific automation |
| `get_energy` | All energy/power/solar/battery sensors |
| `send_notification` | Send a notification via HA notify integration |

---

## Troubleshooting

### `HOME_ASSISTANT_TOKEN not configured`

The skill cannot find your token. Check:

1. Is `HOME_ASSISTANT_TOKEN` in the `"env"` block of `~/.openclaw/openclaw.json`?
2. Did you restart OpenClaw after editing the config?
3. Validate your JSON is parseable:
   ```bash
   python3 -c "import json; json.load(open('/home/$USER/.openclaw/openclaw.json')); print('valid')"
   ```

**Quick fix** — run from the repo directory on your OpenClaw server:
```bash
bash fix-token-config.sh
```

### `401 Unauthorized`

Your token is invalid or expired. Regenerate it:  
HA → Profile → Security → Long-Lived Access Tokens → Delete old → Create Token

### `SSL certificate verify failed`

Add to your `openclaw.json` env block:
```json
"HOME_ASSISTANT_SSL_VERIFY": "false"
```
Then restart OpenClaw.

### `Connection refused` or timeout

- Is HA running? `docker ps | grep homeassistant` or `systemctl status homeassistant`
- Is the URL correct? Test from your OpenClaw server:
  ```bash
  curl -s http://homeassistant.local:8123/api/ -H "Authorization: Bearer YOUR_TOKEN"
  ```

### Skill not triggering

The skill responds to 90+ trigger phrases. If yours isn't recognised:
- Try explicit phrasing: `home assistant: list all lights`
- Check the skill is loaded: ask your bot `what skills do you have?`

---

## Scalability Notes

This skill works across any Home Assistant setup:

- **HTTP or HTTPS** — SSL handling is fully configurable
- **Any HA version** — 2023.1+ supported (REST API unchanged since 2021)
- **Any entity type** — snippets use generic entity discovery, not hardcoded entity IDs
- **Any OpenClaw channel** — Telegram, web UI, API — all work identically
- **Multi-server setups** — `HOME_ASSISTANT_URL` can point to any reachable HA instance
- **Docker or native HA** — no difference from the skill's perspective

---

## Security

**No credentials are stored in the skill file itself.**

Tokens are read at runtime from your OpenClaw environment. The `home_assistant.json` file can be safely committed to public repositories — it contains no secrets.

If you accidentally expose a token: revoke it immediately in HA (Profile → Security → Long-Lived Access Tokens → Delete) and generate a new one.

---

## Contributing

PRs welcome. Please:
- Test against a real Home Assistant instance
- Validate JSON: `python3 -c "import json; json.load(open('skill/home_assistant.json'))"`
- Compile-check all snippets before submitting
- Keep credentials out of all committed files
- Update `docs/CHANGELOG.md`

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for full guidelines.

---

## License

MIT — see [LICENSE](LICENSE).

---

## Related

- [OpenClaw](https://openclaw.ai) — the AI agent platform this skill runs on
- [Home Assistant REST API](https://developers.home-assistant.io/docs/api/rest/)
- [OpenClaw Skill Hub](https://clawhub.com) — discover more skills
