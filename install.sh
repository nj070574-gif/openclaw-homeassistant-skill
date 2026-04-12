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
    [[ "$ans" =~ ^[Yy]$ ]] || { echo ""; ok "Keeping existing credentials."; echo ""; goto_restart; exit 0; }
fi

# 5. Collect credentials
echo ""
echo "   Generate a token: HA → Profile → Security → Long-Lived Access Tokens"
echo ""
read -rp "   Home Assistant URL [http://homeassistant.local:8123]: " HA_URL
HA_URL="${HA_URL:-http://homeassistant.local:8123}"
read -rp "   Home Assistant Token: " HA_TOKEN
[[ -z "$HA_TOKEN" ]] && { err "Token cannot be empty."; exit 1; }

HA_SSL_VERIFY="true"
if [[ "$HA_URL" == https://* ]]; then
    warn "HTTPS URL detected."
    read -rp "   Self-signed cert — skip SSL verify? [y/N] " ssl_ans
    [[ "$ssl_ans" =~ ^[Yy]$ ]] && HA_SSL_VERIFY="false"
fi

# 6. Write to openclaw.json
echo ""
if [[ -f "$OC_CONFIG" ]]; then
    cp "$OC_CONFIG" "${OC_CONFIG}.bak.ha-skill-$(date +%Y%m%d_%H%M%S)"
    ok "Backed up openclaw.json"
    python3 -c "
import json; from pathlib import Path
p = Path('$OC_CONFIG'); cfg = json.loads(p.read_text())
cfg.setdefault('env', {})['HOME_ASSISTANT_URL']   = '$HA_URL'
cfg.setdefault('env', {})['HOME_ASSISTANT_TOKEN'] = '$HA_TOKEN'
$( [[ "$HA_SSL_VERIFY" == "false" ]] && echo "cfg['env']['HOME_ASSISTANT_SSL_VERIFY'] = 'false'" )
p.write_text(json.dumps(cfg, indent=2)); print('openclaw.json updated')
"
    ok "Credentials written to openclaw.json"
else
    warn "openclaw.json not found — writing to secrets file"
    mkdir -p "$SECRETS_DIR"
    printf '%s\n%s\n' "$HA_TOKEN" "$HA_URL" > "$SECRETS_DIR/home_assistant.token"
    chmod 600 "$SECRETS_DIR/home_assistant.token"
    ok "Token saved to secrets file"
fi

# 7. Test connectivity
echo ""; echo "── Connectivity Test ─────────────────────────────────"
CURL_K=""; [[ "$HA_SSL_VERIFY" == "false" ]] && CURL_K="-k"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $CURL_K \
    -H "Authorization: Bearer $HA_TOKEN" "${HA_URL}/api/" 2>/dev/null || echo "000")
case "$HTTP_CODE" in
    200) ok "Home Assistant API reachable (HTTP 200)" ;;
    401) err "HTTP 401 — token invalid. Generate a new one in HA." ;;
    000) err "Cannot reach $HA_URL — check URL and that HA is running" ;;
    *)   warn "HTTP $HTTP_CODE — unexpected. Check HA logs." ;;
esac

# 8. Done
echo ""; echo "── Next Steps ────────────────────────────────────────"; echo ""
info "1. Restart OpenClaw:  sudo systemctl restart openclaw"
info "2. Test: ask your bot 'home summary' or 'what is the temperature?'"
info "3. Issues? See README.md → Troubleshooting"
echo ""; ok "Installation complete!"; echo ""
