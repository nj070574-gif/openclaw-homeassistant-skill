# Contributing to OpenClaw Home Assistant Skill

Thank you for considering a contribution! This is a community skill for OpenClaw and all improvements are welcome.

## Ways to Contribute

- **Bug reports** — open a GitHub issue using the bug report template
- **Feature requests** — open an issue using the feature request template
- **Code contributions** — submit a pull request
- **Documentation** — fix typos, improve clarity, add examples

## Development Setup

1. Fork and clone the repository
2. Copy the skill file to your OpenClaw skills directory:
   ```bash
   cp skill/home_assistant.json ~/.openclaw/agents/main/agent/skills/
   ```
3. Set your credentials in your local `openclaw.json`
4. Test with a real Home Assistant instance

## Submitting Changes

1. Create a branch: `git checkout -b feature/your-feature-name`
2. Make your changes
3. **Validate the JSON** before committing:
   ```bash
   python3 -c "import json; json.load(open('skill/home_assistant.json')); print('JSON valid')"
   ```
4. Update `docs/CHANGELOG.md` under a new version or `[Unreleased]`
5. Submit a pull request with a clear description

## Code Guidelines

### Security — most important
- **Never** commit tokens, passwords, IP addresses, or any private information
- All credential access must go through the `_load_config` snippet pattern
- Credentials must only come from env vars, `openclaw.json` env block, or the secrets file

### Python style
- Keep snippets self-contained and runnable as standalone scripts
- Use `stdlib` modules first (`urllib`, `json`, `os`, `pathlib`)
- `requests` is an optional enhancement — code must work without it
- Add `try/except` with helpful error messages to all network calls
- Target Python 3.9+ compatibility

### Snippet guidelines
- Each snippet should do one clear thing
- Include a brief comment at the top explaining what to change
- Use `UPPER_CASE` for variables the user needs to edit

## Reporting a Bug

Please include:
- OpenClaw version (`openclaw --version`)
- Home Assistant version
- The exact error message or unexpected behaviour
- Steps to reproduce
- **No tokens or private IP addresses** — use placeholders like `YOUR_TOKEN` and `192.168.X.X`

## License

By contributing, you agree your contributions will be licensed under the MIT license.
