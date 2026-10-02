# Changelog

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
