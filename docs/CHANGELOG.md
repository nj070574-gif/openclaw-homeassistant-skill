# Changelog

## 2.3.0 — 2026-10-06

### Security
- **Finished pruning vague triggers** (the audit's 97%-confidence HIGH). v2.2.0 removed a handful of bare words but the trigger list still shadowed ordinary conversation with single nouns ("temperature", "camera", "lights", "energy", "heating", "automation", "switches", …). Triggers are now explicit, action-scoped phrases ("turn on the", "set the heating to", "home summary", "show me the front door camera", "lock the", …), so incidental mentions no longer fire physical actions.
- **Runtime warning when TLS verification is disabled.** `_load_config` now prints a stderr warning whenever `HOME_ASSISTANT_SSL_VERIFY=false` (previously only plain-HTTP was warned), since the bearer token can be intercepted on an untrusted network. Addresses the "Unsafe Defaults" findings.
- **Confirm-before-act guidance** added to SKILL.md and README: state-changing services (lights/switches/climate/locks/scenes/automations) and camera snapshots are confirmed with the user first; read-only queries are not. Addresses "Missing User Warnings".
- **`call_service` documented as general-purpose.** SKILL.md now states plainly that `call_service` can invoke *any* HA service and must be confirmed for state changes, and that `send_notification` uses only the user's own HA notify integration. Addresses "Description-Behavior Mismatch".

### Added
- **Declarative security frontmatter in SKILL.md:** `risk_level`/`risk_acknowledged`, `auth_method`, `tls_verification`, `destructive_ops`, a `binaries:` list, and a `prompt_injection_mitigation:` block (entity/sensor/camera data is reported as data, never executed; state changes and snapshots are confirmed; connection params come only from the environment).
- **"Consent, safety & privacy" section** in SKILL.md (own-instance-only, least-privilege token, token rotation, camera privacy, TLS guidance); matching bullets in the README.

### Changed
- Setup `sudo systemctl restart openclaw` reframed as a one-time user step; the skill never runs `sudo` at runtime.
- SSL troubleshooting (SKILL.md + README) now recommends `HOME_ASSISTANT_CA_CERT` first; `SSL_VERIFY=false` is a documented trusted-LAN last resort.
- **Fixed corrupted Markdown in SKILL.md** — code fences had lost their leading backticks/language (```` ```json ````/```` ```bash ````) and a few words had a dropped leading letter ("Turn"/"Trigger"). Rewritten cleanly.
- Version bumped to 2.3.0 (SKILL.md, home_assistant.json, .clawhub.yaml).

### Notes
- No change to the credential-loading model, endpoints, or snippet behaviour (the v2.2.0 `camera_snapshot` `mkstemp` fix and CA-cert support are retained). Existing setups keep working.

## 2.2.0 — 2026-10-02

### Fixed
- `_load_config` crashed on the openclaw.json token-load path — `Path` was used but `pathlib` was never imported
- Added the Priority-3 `.secrets/home_assistant.token` fallback the error message and docs already promised, so the documented path actually works
- `install.sh` called an undefined `goto_restart` in the "keep existing credentials" branch — replaced with inline restart/next-steps output

### Security
- Warn on stderr when `HOME_ASSISTANT_URL` uses plain HTTP to a non-local host — the long-lived bearer token would be sent unencrypted
- `camera_snapshot` now writes to a secure `tempfile.mkstemp` file instead of a predictable `/tmp/ha_snapshot.jpg` path (symlink/clobber risk)
- Pruned overly-broad single-word triggers (e.g. light, door, lock, power, media, weather) that shadowed other skills
- Added explicit user warnings in SKILL.md: this skill controls physical devices, and camera operations return private images
- Strengthened `HOME_ASSISTANT_SSL_VERIFY=false` guidance toward `https://` + `HOME_ASSISTANT_CA_CERT`
- Installers no longer string-interpolate the token/URL into Python source — credentials are passed via environment into a quoted heredoc

## [2.0.0] — 2026-04-12

### Breaking Changes
- Credential loading completely redesigned — tokens are **never** hardcoded in skill files
- `HOME_ASSISTANT_SSL_VERIFY` env var now controls SSL (was always `verify=False` before)

### Added
- 3-location credential fallback: env var → openclaw.json env block → secrets file
- `_ssl_verify()` helper — respects `HOME_ASSISTANT_SSL_VERIFY` and `HOME_ASSISTANT_CA_CERT`
- `camera_snapshot` snippet — download camera image to disk
- `trigger_automation` snippet — fire a specific automation by entity ID
- `send_notification` snippet — send alerts via any HA notify integration
- `setup` block in skill JSON — machine-readable setup guide
- `requires` block — documents Python/HA version requirements
- 90 trigger phrases (up from 43)
- 12 usage examples
- `install.sh` — interactive installer with connectivity test
- `fix-token-config.sh` — targeted fix for token-not-found errors
- Complete `README.md` with Telegram integration guide and troubleshooting
- `docs/CONTRIBUTING.md`, `docs/CHANGELOG.md`

### Fixed
- `192.168.x.x` private IPs removed from all skill metadata
- All snippet strings now properly escaped — no quote corruption on install
- All 15 snippets pass `compile()` check before deployment
- `notes` field no longer contains environment-specific information

### Changed
- Fallback URL changed from private IP to `http://homeassistant.local:8123`
- Snippets use string concatenation (no f-string nesting) for reliable JSON serialisation
- Version bumped to 2.0.0 — significant rewrite

## [1.3.0] — 2026-04-12

- Fixed corrupted snippet strings (missing quotes around dict keys)
- All snippets verified to compile before deployment
- 12 snippets

## [1.2.0] — 2026-04-12

- Rewrote skill using Python string builder to avoid heredoc quoting issues
- Added `ha_summary_for_telegram` snippet
- 12 snippets, all compile OK

## [1.1.0] — 2026-04-08

- Added 3-location token loader (env → openclaw.json → secrets file)
- HTTPS support with SSL verify options
- Interactive installer script

## [1.0.0] — 2026-04-07

- Initial release
- Basic HA REST API integration
- Temperature sensors, lights, switches, cameras, climate
