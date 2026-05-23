# Contributing

Participants are expected to follow the [Code of Conduct](./CODE_OF_CONDUCT.md).

## Issues

Security vulnerabilities are **not** tracked in public issues until addressed; see **[SECURITY.md](./SECURITY.md)**.

Use [GitHub Issues](https://github.com/garretpatten/fedora-setup-scripts/issues) with the **Bug report** or **Feature request** form. Include Fedora version (`cat /etc/os-release`), desktop vs headless context, commands run, and relevant lines from **`setup_errors.log`** (redact private paths).

## Pull requests

- Branch from **`master`**, focused scope per PR.
- Keep installs idempotent (skip work if keys, repos, or targets already satisfy the goal).
- **Headless-safe**: **`gsettings`** only behind **`gsettings_ok`**; do not require a GNOME session in CI-only paths.
- **Dotfiles submodule**: substantive configs belong upstream in **`src/dotfiles`** unless the provisioning scripts own one-off machine behavior — submodule bumps must be explicit.
- Fedora ships **firewalld** by default; **`config/security.sh`** currently stops it when **UFW** is configured—document behavior changes prominently.

### Checks (from repo root)

```bash
npm install

npm run lint

shellcheck src/scripts/utils.sh \
  src/scripts/master.sh \
  src/scripts/run-install.sh \
  src/scripts/run-config.sh \
  src/scripts/install/*.sh \
  src/scripts/config/*.sh
```

**`npm run lint`** runs **Prettier** (**`prettier --check .`**), **`markdownlint-cli2`** over `**/*.md` excluding **`node_modules`** and **`src/dotfiles`**, and **`yamllint`** on **`.github`**, **`.yamllint`**, and **`.markdownlint.yaml`**.

Keep YAML within **`.yamllint`** (80-character lines unless an existing waiver applies).

Install **`yamllint`** locally when missing (for example **`pip install yamllint`**). Markdown or workflow-only changes still need a clean **`npm run lint`** before you open a PR.
