#!/usr/bin/env bash
# =============================================================================
# fix-token-config.sh
# Fixes the "HOME_ASSISTANT_TOKEN not configured" error on existing installs.
# Run this on your OpenClaw host (Linux server where OpenClaw runs).
# =============================================================================
set -euo pipefail

OC_CONFIG="${HOME}/.openclaw/openclaw.json"
SKILLS_DIR="${HOME}/.openclaw/agents/main/agent/skills"

echo "=== OpenClaw Home Assistant Skill — Token Fix ==="
echo ""

# 1. Detect current token location
CURRENT=$(python3 -c "
import json, os
from pathlib import Path
p = Path('$OC_CONFIG')
if p.exists():
    t = json.loads(p.read_text()).get('env', {}).get('HOME_ASSISTANT_TOKEN', '')
    if t: print('FOUND_IN_OC_JSON'); quit()
if os.environ.get('HOME_ASSISTANT_TOKEN'):
    print('FOUND_IN_ENV'); quit()
s = Path.home() / '.openclaw/workspace/.secrets/home_assistant.token'
if s.exists() and s.read_text().strip():
    print('FOUND_IN_SECRETS'); quit()
print('NOT_FOUND')
" 2>/dev/null || echo "NOT_FOUND")

echo "Token status: $CURRENT"
echo ""

if [[ "$CURRENT" == "FOUND_IN_OC_JSON" ]]; then
    echo "✅ Token IS in openclaw.json already."
    echo "   Most likely cause: OpenClaw wasn't restarted after config change."
    echo ""
    python3 -c "import json; json.load(open('$OC_CONFIG')); print('✅ JSON is valid')" 2>/dev/null \
        || echo "❌ openclaw.json has invalid JSON — fix it before restarting"
    echo ""
    echo "   Restart: sudo systemctl restart openclaw"
    exit 0
fi

if [[ "$CURRENT" == "FOUND_IN_ENV" ]]; then
    echo "⚠️  Token is in env var but may not reach cron/scripts."
    echo "   Best fix: also add it to openclaw.json (continue below)."
    echo ""
fi

# 2. Prompt for credentials
echo "Enter your HA Long-Lived Access Token."
echo "(HA → Profile → Security → Long-Lived Access Tokens)"
echo ""
read -rp "Token: " HA_TOKEN
[[ -z "$HA_TOKEN" ]] && { echo "❌ Token cannot be empty."; exit 1; }

read -rp "Home Assistant URL [http://homeassistant.local:8123]: " HA_URL
HA_URL="${HA_URL:-http://homeassistant.local:8123}"

HA_SSL_VERIFY="true"
if [[ "$HA_URL" == https://* ]]; then
    read -rp "Self-signed cert — skip SSL verify? [y/N]: " ssl_ans
    [[ "$ssl_ans" =~ ^[Yy]$ ]] && HA_SSL_VERIFY="false"
fi

# 3. Write to openclaw.json
if [[ -f "$OC_CONFIG" ]]; then
    cp "$OC_CONFIG" "${OC_CONFIG}.bak.fix-$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backed up openclaw.json"
    python3 -c "
import json; from pathlib import Path
p = Path('$OC_CONFIG'); cfg = json.loads(p.read_text())
cfg.setdefault('env', {})['HOME_ASSISTANT_URL']   = '$HA_URL'
cfg.setdefault('env', {})['HOME_ASSISTANT_TOKEN'] = '$HA_TOKEN'
if '$HA_SSL_VERIFY' == 'false':
    cfg['env']['HOME_ASSISTANT_SSL_VERIFY'] = 'false'
p.write_text(json.dumps(cfg, indent=2))
print('✅ openclaw.json updated')
"
else
    mkdir -p "${HOME}/.openclaw/workspace/.secrets"
    printf '%s\n%s\n' "$HA_TOKEN" "$HA_URL" \
        > "${HOME}/.openclaw/workspace/.secrets/home_assistant.token"
    chmod 600 "${HOME}/.openclaw/workspace/.secrets/home_assistant.token"
    echo "✅ Token saved to secrets file"
fi

# 4. Update skill file if repo is present
if [[ -f "skill/home_assistant.json" ]]; then
    python3 -c "import json; json.load(open('skill/home_assistant.json'))" 2>/dev/null && {
        cp "skill/home_assistant.json" "$SKILLS_DIR/home_assistant.json"
        echo "✅ Skill file updated to latest version"
    }
fi

# 5. Test connectivity
echo ""
CURL_K=""; [[ "$HA_SSL_VERIFY" == "false" ]] && CURL_K="-k"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $CURL_K \
    -H "Authorization: Bearer $HA_TOKEN" "${HA_URL}/api/" 2>/dev/null || echo "000")
case "$HTTP_CODE" in
    200) echo "✅ HA API reachable and token valid (HTTP 200)" ;;
    401) echo "❌ HTTP 401 — token invalid. Generate a new one in HA." ;;
    000) echo "⚠️  Cannot reach $HA_URL — check URL and HA status" ;;
    *)   echo "⚠️  HTTP $HTTP_CODE — check HA logs" ;;
esac

echo ""
echo "=== Restart OpenClaw ==="
echo "  sudo systemctl restart openclaw"
echo ""
echo "Then test: ask your bot 'home summary'"
echo ""
echo "Done ✅"
