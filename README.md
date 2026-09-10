<!-- markdownlint-disable MD033 MD041 -->

<p align="center">
    <img
        src="https://img.shields.io/badge/Fedora%20setup%20scripts-reproducible%20automation-294172?style=for-the-badge&logo=fedora&logoColor=white"
        alt="Fedora-branded badge: reproducible workstation automation"
    />
</p>

<h1 align="center">Fedora Setup Scripts</h1>

<p align="center"><strong>Production-style Bash provisioning for standardized developer workstations.</strong></p>

<p align="center">
    Split <strong>install</strong> and <strong>configuration</strong> flows, audited helper patterns, submodule-backed dotfiles, and CI you can anchor release gates on—whether you onboard one laptop or fifty.
</p>

<p align="center">
    <a href="./LICENSE"><img src="https://img.shields.io/github/license/garretpatten/fedora-setup-scripts?style=flat-square" alt="License: MIT" /></a>
    <a href="https://fedoraproject.org/"
        ><img src="https://img.shields.io/badge/platform-Fedora%20Workstation%2040%2B-294172?style=flat-square&logo=fedora&logoColor=white" alt="Fedora Workstation 40 or newer"
    /></a>
    <img src="https://img.shields.io/badge/shell-bash-black?style=flat-square&logo=gnu-bash&logoColor=white" alt="Shell: Bash" />
    <img src="https://img.shields.io/badge/infra-DNF%20%2B%20Flatpak-3C6EB4?style=flat-square&logo=redhat&logoColor=white" alt="Package flows: DNF and Flatpak" />
</p>

<p align="center">
    <a href="https://github.com/garretpatten/fedora-setup-scripts/actions/workflows/test-runner.yaml"
        ><img src="https://img.shields.io/github/actions/workflow/status/garretpatten/fedora-setup-scripts/test-runner.yaml?branch=master&label=Fedora%20CI&logo=github&style=flat-square" alt="Test runner workflow status"
    /></a>
    <a href="https://github.com/garretpatten/fedora-setup-scripts/actions/workflows/quality-checks.yaml"
        ><img src="https://img.shields.io/github/actions/workflow/status/garretpatten/fedora-setup-scripts/quality-checks.yaml?branch=master&label=quality&logo=github&style=flat-square" alt="Quality checks workflow status"
    /></a>
    <a href="https://github.com/garretpatten/fedora-setup-scripts/actions/workflows/security-checks.yaml"
        ><img src="https://img.shields.io/github/actions/workflow/status/garretpatten/fedora-setup-scripts/security-checks.yaml?branch=master&label=security&logo=github&style=flat-square" alt="Security checks workflow status"
    /></a>
</p>

<p align="center">
    ✓ Modular orchestration &nbsp;
    ✓ Split install/config bundles &nbsp;
    ✓ Linted Bash + docs in PR &nbsp;
    ✓ Idempotent, rerunnable phases
</p>

<!-- markdownlint-enable MD033 MD041 -->

---

## Overview

Fedora Setup Scripts automate a **baseline engineering stack**: security tooling,
shells and terminals, development runtimes (Node, Docker, Neovim, and peers), GNOME ergonomics when a
desktop session exists, and a pinned **dotfiles** submodule for editor and tmux parity across
machines. The layout and philosophy mirror [ubuntu-setup-scripts](https://github.com/garretpatten/ubuntu-setup-scripts), with **DNF/RPM** repositories, **Flatpak**, and Fedora-specific paths (e.g. `dnf-automatic`, Brave’s RPM repo, Proton VPN stable RPM, **Ghostty** when Fedora ships it in enabled repos).

## ✨ Features

- **🔧 Automated setup**: Full pass with one command
- **🛡️ Security first**: Tooling, firewall defaults, and guarded downloads
- **⚡ Efficient batching**: Fewer round-trips through DNF metadata where practical
- **🔄 Idempotent**: Safe to rerun; helpers skip first-touch copies when targets exist
- **📝 Centralized errors**: `setup_errors.log` aggregates script noise for triage
- **🎯 Modular design**: Per-app/category scripts plus `master.sh`, `run-install.sh`, and `run-config.sh`
- **⚙️ Install vs configuration**: Packages and installers live under `src/scripts/install/`; GNOME
  defaults, `dnf-automatic` timer, home layout, firewall posture, and dotfile copies live under
  `src/scripts/config/`. Use **`npm run install:all`**, **`npm run config`**, or **`npm run all`**, or
  invoke runners directly.

## 🚀 Quick Start

### Prerequisites

- Fedora Workstation (GNOME) **40+** recommended; other spins may work with package name drift
- Network access and **sudo**

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/garretpatten/fedora-setup-scripts
cd fedora-setup-scripts
```

1. **Install Node deps** (optional; enables `npm run` shortcuts)

```bash
npm install
```

1. **Update submodules** (for dotfiles)

```bash
git submodule update --init --remote --recursive src/dotfiles/
```

1. **Make scripts executable**

```bash
chmod +x src/scripts/**/*.sh scripts/**/*.sh
```

1. **Run the complete setup**

```bash
npm run all
# or:
./src/scripts/master.sh
```

### npm scripts

| Command               | Runs                                                                                                         |
| --------------------- | ------------------------------------------------------------------------------------------------------------ |
| `npm run all`         | Full provisioning (`master.sh`): config first, then installs, then remaining config.                         |
| `npm run install:cli` | CLI-only install (`run-install.sh cli`): no desktop/media apps.                                              |
| `npm run install:all` | Full install (`run-install.sh all`): CLI + desktop/native. Default when `run-install.sh` has no argument.    |
| `npm run config`      | Configuration bundle only (`run-config.sh`): defaults, home layout, firewall, submodule copies, shell.       |
| `npm run lint`        | **Prettier**, **markdownlint-cli2**, **yamllint** (local checks; see **[CONTRIBUTING](./CONTRIBUTING.md)**). |

Bash equivalents:

```bash
bash src/scripts/run-install.sh       # full install (default: all)
bash src/scripts/run-install.sh cli   # CLI-only install
bash src/scripts/run-install.sh all   # full install
bash src/scripts/run-config.sh        # config only (submodules are synced)
bash src/scripts/master.sh            # install + config
```

Use **`npm run config`** when packages are already satisfied but GNOME or dotfiles subtrees should refresh after a submodule bump.

### Granular scripts

Each category exists as per-app **install** and/or **configuration** scripts:

```bash
bash src/scripts/install/all.sh                # full install orchestrator
bash src/scripts/install/cli.sh                # CLI-only install wrapper
bash src/scripts/install/preflight/all.sh      # DNF essentials + timezone
bash src/scripts/install/packages/*.packages   # package lists
bash src/scripts/install/repos/setup.sh        # vendor RPM repos
bash src/scripts/install/apps/chrome.sh
bash src/scripts/install/apps/proton-pass.sh
bash src/scripts/install/dev/nvm.sh
bash src/scripts/install/shell/oh-my-posh.sh
bash src/scripts/install/post-install/all.sh   # maintenance + banner

bash src/scripts/config/system/all.sh          # GNOME + dnf-automatic + sysctl + GDM guest hint
bash src/scripts/config/home/all.sh            # home scaffold
bash src/scripts/config/dev/all.sh             # dotfiles + Git identity
bash src/scripts/config/security/all.sh        # disable firewalld + UFW posture
bash src/scripts/config/shell/all.sh           # shell dotfiles + chsh
```

Prefer the orchestrators so ordering stays predictable.

### Validation scripts (`scripts/`)

| Script                     | Use with                                   |
| -------------------------- | ------------------------------------------ |
| `validate-installs-cli.sh` | After `run-install.sh cli`                 |
| `validate-installs.sh`     | After `run-install.sh all` or `master.sh`  |
| `validate-config-only.sh`  | After `run-config.sh`                      |
| `validate-config.sh`       | After `master.sh` or full install + config |
| `validate.sh`              | After `master.sh` (installs + config)      |

CI runs four jobs in a `fedora:latest` container:

- `test-cli`: `run-install.sh cli` → `validate-installs-cli.sh`
- `test-config`: `run-config.sh` → `validate-config-only.sh`
- `test-full`: `run-install.sh all` → `validate-installs.sh`
- `test-master`: `master.sh` → `validate.sh` (full installs + config)

## Project structure

```text
fedora-setup-scripts/
├── src/
│   ├── scripts/
│   │   ├── master.sh           # Full run — config then installs then remaining config
│   │   ├── run-install.sh      # DNF/Flatpak/installers/post-install hooks only
│   │   ├── run-config.sh       # GNOME, home layout, firewall policy, dotfiles, shell
│   │   ├── lib/
│   │   │   ├── env.sh
│   │   │   ├── run.sh
│   │   │   ├── parallel.sh
│   │   │   ├── dnf-packages.sh
│   │   │   ├── dnf-repo-add.sh
│   │   │   ├── flatpak-install.sh
│   │   │   ├── git-submodules.sh
│   │   │   ├── gnome-session.sh
│   │   │   ├── zsh-login.sh
│   │   │   └── dotfiles-install.sh
│   │   ├── install/
│   │   │   ├── all.sh
│   │   │   ├── cli.sh
│   │   │   ├── packages/
│   │   │   ├── apps/
│   │   │   ├── dev/
│   │   │   ├── shell/
│   │   │   ├── repos/
│   │   │   ├── preflight/
│   │   │   └── post-install/
│   │   └── config/
│   │       ├── all.sh
│   │       ├── system/
│   │       ├── home/
│   │       ├── dev/
│   │       ├── security/
│   │       └── shell/
│   ├── dotfiles/               # submodule
│   └── assets/
│       └── fedora.txt          # completion banner
└── scripts/                    # validation scripts
```

### Execution flow (`master.sh`)

1. Initialize/update the `src/dotfiles` submodule.
2. **`install/preflight/all.sh`** — DNF refresh, toolchain packages, timezone nudge off **UTC**
3. **`config/system/all.sh`** — GNOME defaults when D-Bus/schemas exist; **`dnf-automatic`** timer; GDM **`AllowGuest`** hint; logind + sysctl keepalive drop-in
4. **`config/home/all.sh`** — home scaffold and permissions
5. **`install/all.sh`** — package lists, vendor repos, per-app installers
6. **`config/dev/all.sh`** — dotfiles symlinks/manifest + Git globals
7. **`config/security/all.sh`** — stop/disable **firewalld** when present, then **UFW** defaults
8. **`config/shell/all.sh`** — shell dotfiles + best-effort **`chsh`**

---

## 📋 What gets installed vs configured

The lists below mirror the **`install/`** and **`config/`** split; open each script for exact commands.

### **`install/` bundle**

#### 🧰 **Bootstrap** (`install/preflight/all.sh`)

- DNF cache refresh; **`git`**, **`curl`**, **`wget`**, **`gnupg2`**, **`dnf-plugins-core`**, **`unzip`**, **`file`**
- Timezone nudge from **UTC** toward **America/New_York** when unchanged

#### 📦 **Package lists** (`install/packages/*.packages`)

Plain-text package lists consumed by `lib/dnf-packages.sh`:

- `base.packages` — CLI/security essentials: `bat`, `btop`, `eza`, `fd`, `fzf`, `gh`, `htop`, `jq`, `nmap`, `openvpn`, `ripgrep`, `shellcheck`, `tealdeer`, `tree-sitter-cli`, `ufw`, `vim-enhanced`, `zoxide`, ...
- `shell.packages` — `zsh`, `tmux`, `fontawesome-fonts`, `fira-code-fonts`, `zsh-autosuggestions`, `zsh-syntax-highlighting`
- `media.packages` — `vlc`, `ffmpeg-free`
- `desktop.packages` — `gnome-shell-extensions`, `gnome-tweaks`
- `productivity.packages` — `flameshot`, `keepassxc`, `libreoffice`, `redshift`
- `dev.packages` — `neovim`, `python3` stack
- `lsp.packages` — build essentials + language runtimes for LSP support
- `griffo.packages` — `lazygit`, `lazydocker`, `yazi`
- `third-party-cli.packages` — Docker CE stack, NodeSource `nodejs`
- `third-party-desktop.packages` — `brave-browser`, appindicator support

#### 🛠️ **Development installers** (`install/dev/`)

- **Node.js** from NodeSource RPM repo, NVM installer when missing, **`@vue/cli`** globally
- **Python**, **Docker CE** repo, **`docker-compose-plugin`**, **Neovim**, **`gh`**, **`shellcheck`**
- **Language servers**: npm-based + best-effort `lua-language-server` binary
- **`semgrep`** (pip), **`rustup`**, **Cursor CLI**, **Ollama**

#### 🎬 **Media** (`install/apps/` + Flatpak)

Brave (official RPM repo), VLC, **ffmpeg-free**, Spotify (**Flatpak**)

#### 📊 **Productivity** (`install/apps/` + Flatpak)

LibreOffice, Zoom (**Flatpak**), Google Chrome, KeePassXC, Redshift,
Flameshot, Balena Etcher AppImage, Bruno (**Flatpak**)

#### 🔒 **Security packages & payloads** (`install/apps/`)

- **`ufw`**, **`openvpn`**, **`nmap`**, **`perl-Image-ExifTool`**
- OWASP ZAP (**Flatpak**), Proton Pass CLI
- **`~/Hacking`** clones and the **`ufw-docker`** helper
- Proton VPN/Pass desktop RPMs and Signal (**Flatpak**)

#### 🐚 **Shell tooling** (`install/shell/`)

Zsh + plugins, **`tmux`**, **`ghostty`** from enabled repos, Google Noto Emoji + Fira Code fonts, Meslo Nerd Font drop, user Oh My Posh

#### 🏁 **Post maintenance** (`install/post-install/all.sh`)

`dnf upgrade` + autoremove, **docker** daemon + group membership, **`tldr --update`**, completion banner

### **`config/` bundle**

#### 🏠 **Home layout** (`config/home/all.sh`)

Same structure as the Ubuntu sibling (`Projects`, `Hacking`, **`AppImages`**, etc.) with sane perms.

#### ⚙️ **Desktop & automatic updates** (`config/system/all.sh`)

- **GNOME** when available (mirrors Ubuntu defaults: dark UI, Nautilus ergonomics, Dash to Dock when installed, Night Light, privacy toggles)
- **`dnf-automatic`** timer enablement (adjust **`/etc/dnf/automatic.conf`** locally if you want download-only vs applied updates)
- **`/etc/gdm/custom.conf`** **`AllowGuest`** hint, logind lid policy, TCP keepalive sysctl drop-in

Minimal/CI runners without GNOME sessions skip **`gsettings`** safely.

#### 💻 **Editor & Git prefs** (`config/dev/all.sh`)

Dotfiles symlinks/manifest, VS Code **`settings.json`** seed, first-touch **`~/.gitconfig`**.

#### 🔒 **UFW posture** (`config/security/all.sh`)

Stops/disables **firewalld** when the unit exists, then **`ufw`** reset/deny-in/allow-out/SSH/enable when **iptables filter** works (minimal containers skip quietly).

#### 🐚 **Shell dotfiles** (`config/shell/all.sh`)

Modular tmux tree, oh-my-posh, Ghostty configs, home files, best-effort **`chsh`**.

**Full symlink mirror** from **`src/dotfiles`**: **`./setup.sh --link-xdg-config`** (see the [dotfiles README](https://github.com/garretpatten/dotfiles/blob/master/README.md)).

## 📊 Monitoring & logs

- **Error log**: `setup_errors.log`
- **Summary** (optional tooling): `setup_summary.txt` — parity hook for future reporting
- Console output uses the same red **[ERROR]** helpers as the Ubuntu project

## ⚠️ Post-installation notes

1. **Re-login** after **docker** group and default shell changes.
1. **GNOME**: some `gsettings` tweaks need an active session.
1. **Firewall**: `config/security/ufw-rules.sh` **stops firewalld** to run **UFW** like the Ubuntu twin—if you rely on **firewalld** zones, fork that script.
1. **Night Light vs Redshift**: pick one warm-light policy.
1. **Subscriptions & sign-in**: Brave, Proton, Signal, Spotify, etc. still require user auth.

## 🔍 Troubleshooting

### Permission errors

```bash
chmod +x src/scripts/**/*.sh scripts/**/*.sh
```

### DNF failures

`setup_errors.log` only records **failed** **`dnf`** transactions — normal progress no longer floods the file.

```bash
sudo dnf upgrade --refresh
# then re-run the stage that failed
```

If **Docker CE** metadata vanishes after a distro bump, reinstall **`/etc/yum.repos.d/docker-ce.repo`** from Docker’s Fedora instructions and **`sudo dnf makecache`** again.

### Docker still needs sudo

```bash
newgrp docker
```

### Default shell

```bash
chsh -s "$(command -v zsh)"
```

## 🛡️ Security features

- Vendor RPM repositories with GPG keys (Brave, Docker CE, NodeSource, Proton VPN)
- Firewall defaults with SSH allowance
- Temporary assets under **`/tmp/fedora-setup-$$`**

## Community

| Resource                                | Use                                         |
| --------------------------------------- | ------------------------------------------- |
| [Code of Conduct](./CODE_OF_CONDUCT.md) | Expected behavior in issues and PRs         |
| [Contributing](./CONTRIBUTING.md)       | Branching, checks, submodule notes          |
| [Security policy](./SECURITY.md)        | Vulnerability reporting (not public issues) |
| [Agent guide](./AGENTS.md)              | Conventions for assistants working in-repo  |

## Maintainers

[@garretpatten](https://github.com/garretpatten/).

Use [issue templates](./.github/ISSUE_TEMPLATE/) for bugs and enhancements.

## License

Licensed under the [MIT License](./LICENSE).
