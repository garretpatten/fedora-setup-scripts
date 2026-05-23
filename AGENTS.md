# Agent guide — fedora-setup-scripts

Bash automation for Fedora Workstation developer machines: modular install scripts, shared helpers, and a
`src/dotfiles` git submodule. Changes should stay **idempotent**, **safe to re-run**, and compatible
with **non-GNOME/CI shells** (`gsettings` guarded).

## Repository layout

| Path                   | Purpose                                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------------------- |
| `src/scripts/`         | `utils.sh`, `master.sh`, `run-install.sh`, `run-config.sh`                                          |
| `src/scripts/install/` | DNF/RPM, Flatpak, COPR/third-party installers, repo clones                                          |
| `src/scripts/config/`  | GNOME defaults, **`dnf-automatic`** timer/GDM tweaks, firewall policy, submodule copies, **`chsh`** |
| `src/scripts/utils.sh` | Helpers, `SCRIPTS_DIR`, paths, logging, safe copies/downloads                                       |
| `src/dotfiles/`        | Submodule — [garretpatten/dotfiles](https://github.com/garretpatten/dotfiles)                       |
| `src/assets/`          | Completion ASCII banner (`fedora.txt`)                                                              |
| `.github/workflows/`   | Fedora container test harness + reusable quality/security callers                                   |

### Orchestration

- **`master.sh`**: `install/pre-install.sh` → `config/system-config.sh` → `config/organizeHome.sh`
  → `install/cli.sh` → `install/media.sh` → `install/productivity.sh` → `install/dev.sh`
  → `config/dev.sh` → `install/security.sh` → `config/security.sh` → `install/shell.sh`
  → `install/post-install.sh` → `config/shell.sh`.
- **`run-install.sh`**: **`install/`** only (`$SCRIPTS_DIR/install`).
- **`run-config.sh`**: **`config/`** only (`$SCRIPTS_DIR/config`).
- **`npm run all`** / **`npm run installs`** / **`npm run config`** delegate to those scripts (**`npm install`** at repo root first).

## Script conventions

Scripts in **`install/`** and **`config/`**:

1. `#!/bin/bash`, `# shellcheck source=../utils.sh`, `source "$(dirname "$0")/../utils.sh"`.
2. Top-level **`master.sh`** / **`run-*.sh`**: `# shellcheck source=utils.sh` + `source "$(dirname "$0")/utils.sh"`.

3. Prefer helpers from **`utils.sh`** (**`install_dnf_packages`**, **`copy_directory_safe`**, **`download_file_safe`**, **`gsettings_ok`**, …).

4. Preserve the soft-failure style: `|| true`, `2>>"$ERROR_LOG_FILE"`, **`log_error`** emitted from orchestrators for stage exits.

5. **Headless-safe**: **`config/security.sh`** no-ops when **`ufw`** is unavailable **or iptables tables cannot load** (typical CI containers); **`gsettings`** only when **`gsettings_ok`**.

Paths:

- **`PROJECT_ROOT`** is the repo root (two levels above **`src/scripts`**).
- Dotfiles checkout: **`$PROJECT_ROOT/src/dotfiles`**. **`config/dev.sh`** and **`config/shell.sh`** mirror the Ubuntu/Mac siblings’ selective copies; **`home/.tmux.conf`** pulls modular **`config/tmux/`** once synced.
- **`~/.dotfiles_path`** resolves **`DOTFILES`** for **`home/zsh/fedora.zsh`** exports.

Submodule workflow:

```bash
git submodule update --init --recursive src/dotfiles/
```

Content edits upstream in **`dotfiles`**; bump submodule pointers intentionally when subtree copies must change here.

## Product and safety constraints

- Fedora defaults to **firewalld** — **`config/security.sh`** disables it before **UFW** to match the Ubuntu playbook; verify this aligns with deployments (servers/Kubernetes hosts may need divergence).
- **Night Light vs Redshift** conflict remains documented in **`README.md`**.
- Downloads should continue to funnel through **`download_file_safe`** / vendor-signed repos.
- Secrets never belong in-repo; prefer **`~/.local_extras`**.

## Testing and CI

- **Test Runner** provisions inside a **`fedora:latest`** Actions container (non-privileged quirks tolerated); **`chmod +x`** all scripts beforehand; **`bash src/scripts/master.sh || true`**; scrub **`setup_errors.log`** similarly to **`ubuntu-setup-scripts`**.
- Fedora moves quickly — expect occasional COPR/repo URL drift after major releases.

## Making changes

| Task                      | Preferred edit                                                                                  |
| ------------------------- | ----------------------------------------------------------------------------------------------- |
| Packages/repos/installers | Matching **`install/*.sh`**                                                                     |
| GNOME / timers / sysctl   | **`config/system-config.sh`**, **`organizeHome.sh`**, **`install/pre-install.sh`** as needed    |
| Firewall                  | **`config/security.sh`** (policy) plus **`install/security.sh`** (**`ufw`/`openvpn`** packages) |
| Dotfile parity            | **`config/dev.sh`**, **`config/shell.sh`**                                                      |
| Shared helpers            | **`utils.sh`**                                                                                  |

## Commits and PRs

Only commit when the user asks explicitly. Mention manual QA on Fedora Workstation when altering **`gsettings`**, **`firewalld`**, COPR repos, or Proton tooling.

## Verify before you finish

Before you end a turn where you changed **any** file in this repository (Markdown,
YAML under **`.github/`**, shell, **`package.json`**, etc.), run the checks below so
**Prettier**, **markdownlint**, and **yamllint** stay green. Do not finish with failing
**`npm run lint`** output for paths this repo owns.

**Exception:** work confined to **`src/dotfiles/`** must follow **`src/dotfiles/AGENTS.md`**.
Submodule-only edits there use that repo’s tooling. If the same turn also changes parent
Markdown or YAML (for example submodule docs in the readme), **`npm run lint`** still applies
to the parent checkout.

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

**`npm run lint`** runs **`prettier --check .`**, **`markdownlint-cli2`** on `**/*.md`
(excluding **`node_modules`** and **`src/dotfiles`**), and **`yamllint`** on **`.github`**,
**`.yamllint`**, and **`.markdownlint.yaml`**. Install **`yamllint`** locally if missing (for example
**`pip install yamllint`**).

| If you edited               | Extra checks                                                                       |
| --------------------------- | ---------------------------------------------------------------------------------- |
| Markdown at repo root       | Covered by **`npm run lint`**; submodule Markdown uses dotfiles tooling separately |
| Workflows or lint configs   | **`npm run lint:yaml`**                                                            |
| **`src/dotfiles/`** subtree | Submodule linters (**`npm ci`** there per dotfiles **`AGENTS.md`**)                |

Pull requests still run **garretpatten/quality-checks**.

## License

MIT — see [LICENSE](./LICENSE).
