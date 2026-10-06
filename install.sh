#!/usr/bin/env bash
# =============================================================================
# OpenClaw Home Assistant Skill — Installer
# Run from the repository root on your OpenClaw server (Linux/Debian)
# =============================================================================
set -euo pipefail

SKILL_FILE="skill/home_assistant.json"
SKILLS_DIR="${HOME}/.openclaw/agents/main/agent/skills"
SECRETS_DIR="${HOME}/.openclaw/workspace/.secrets"
OC_CONFIG="${HOME}/.openclaw/openclaw.json"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
err()  { echo -e "${RED}❌ $*${NC}"; }
info() { echo -e "   $*"; }

echo ""
echo "======================================================"
echo "  OpenClaw Home Assistant Skill — Installer"
echo "======================================================"
echo ""

# 1. Validate JSON
if python3 -c "import json; json.load(open('$SKILL_FILE'))" 2>/dev/null; then
    ok "Skill JSON is valid"
else
    err "Invalid JSON in $SKILL_FILE — aborting"; exit 1
fi

# 2. Create skills dir if needed
if [[ ! -d "$SKILLS_DIR" ]]; then
    warn "Skills directory not found: $SKILLS_DIR"
    read -rp "   Create and continue? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
    mkdir -p "$SKILLS_DIR"
fi

# 3. Copy skill
cp "$SKILL_FILE" "$SKILLS_DIR/home_assistant.json"
ok "Skill installed to $SKILLS_DIR/home_assistant.json"

# 4. Check for existing credentials
echo ""; echo "── Credential Configuration ──────────────────────────"
EXISTING_TOKEN=""
if [[ -f "$OC_CONFIG" ]]; then
    EXISTING_TOKEN=$(python3 -c "import json; d=json.load(open('$OC_CONFIG')); print(d.get('env',{}).get('HOME_ASSISTANT_TOKEN',''))" 2>/dev/null || true)
fi
if [[ -z "$EXISTING_TOKEN" && -f "$SECRETS_DIR/home_assistant.token" ]]; then
    EXISTING_TOKEN=$(head -1 "$SECRETS_DIR/home_assistant.token" 2>/dev/null || true)
fi
if [[ -z "$EXISTING_TOKEN" ]]; then EXISTING_TOKEN="${HOME_ASSISTANT_TOKEN:-}"; fi

if [[ -n "$EXISTING_TOKEN" ]]; then
    ok "Found existing HOME_ASSISTANT_TOKEN (${#EXISTING_TOKEN} chars)"
    read -rp "   Configure new credentials? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || {
        echo ""; ok "Keeping existing credentials."
        echo ""; echo "── Next Steps ────────────────────────────────────────"; echo ""
        echo "   Restart OpenClaw so it loads the skill (e.g. systemctl --user restart openclaw)"
        echo "   Then test: ask your bot 'home summary' or 'what is the temperature?'"
        echo ""
        exit 0
    }
fi

# 5. Collect credentials
echo ""
echo "   Generate a token: HA → Profile → Security → Long-Lived Access Tokens"
echo ""
read -rp "   Home Assistant URL [http://homeassistant.local:8123]: " HA_URL
HA_URL="${HA_URL:-http://homeassistant.local:8123}"
read -rp "   Home Assistant Token: " HA_TOKEN
[[ -z "$HA_TOKEN" ]] && { err "Token cannot be empty."; exit 1; }

# TLS verification stays ON. For a self-signed cert, point at your CA cert so
# HTTPS is still verified — there is no disable-verification path.
HA_CA_CERT=""
if [[ "$HA_URL" == https://* ]]; then
    read -rp "   Self-signed cert? Path to your CA cert (blank if using a public CA): " HA_CA_CERT
    if [[ -n "$HA_CA_CERT" && ! -f "$HA_CA_CERT" ]]; then
        warn "CA cert not found at '$HA_CA_CERT' — continuing with system trust store."
        HA_CA_CERT=""
    fi
fi

# 6. Write to openclaw.json
echo ""
if [[ -f "$OC_CONFIG" ]]; then
    cp "$OC_CONFIG" "${OC_CONFIG}.bak.ha-skill-$(date +%Y%m%d_%H%M%S)"
    ok "Backed up openclaw.json"
    HA_URL="$HA_URL" HA_TOKEN="$HA_TOKEN" HA_CA="$HA_CA_CERT" OC_CONFIG="$OC_CONFIG" python3 - <<'PY'
import json, os
from pathlib import Path
p = Path(os.environ["OC_CONFIG"]); cfg = json.loads(p.read_text())
cfg.setdefault("env", {})["HOME_ASSISTANT_URL"]   = os.environ["HA_URL"]
cfg.setdefault("env", {})["HOME_ASSISTANT_TOKEN"] = os.environ["HA_TOKEN"]
ca = os.environ.get("HA_CA", "").strip()
if ca:
    cfg["env"]["HOME_ASSISTANT_CA_CERT"] = ca
p.write_text(json.dumps(cfg, indent=2)); print("openclaw.json updated")
PY
    ok "Credentials written to openclaw.json"
else
    warn "openclaw.json not found — writing to secrets file"
    mkdir -p "$SECRETS_DIR"
    printf '%s\n%s\n' "$HA_TOKEN" "$HA_URL" > "$SECRETS_DIR/home_assistant.token"
    chmod 600 "$SECRETS_DIR/home_assistant.token"
    ok "Token saved to secrets file"
fi

# 7. Test connectivity (TLS always verified; uses your CA cert if supplied)
echo ""; echo "── Connectivity Test ─────────────────────────────────"
CURL_CA=(); [[ -n "$HA_CA_CERT" ]] && CURL_CA=(--cacert "$HA_CA_CERT")
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${CURL_CA[@]}" \
    -H "Authorization: Bearer $HA_TOKEN" "${HA_URL}/api/" 2>/dev/null || echo "000")
case "$HTTP_CODE" in
    200) ok "Home Assistant API reachable (HTTP 200)" ;;
    401) err "HTTP 401 — token invalid. Generate a new one in HA." ;;
    000) err "Cannot reach $HA_URL — check URL, TLS/CA cert, and that HA is running" ;;
    *)   warn "HTTP $HTTP_CODE — unexpected. Check HA logs." ;;
esac

# 8. Done
echo ""; echo "── Next Steps ────────────────────────────────────────"; echo ""
info "1. Restart OpenClaw so it loads the skill (e.g. systemctl --user restart openclaw)"
info "2. Test: ask your bot 'home summary' or 'what is the temperature?'"
info "3. Issues? See README.md → Troubleshooting"
echo ""; ok "Installation complete!"; echo ""
