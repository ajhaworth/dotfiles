# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Setup-OS is a cross-platform workstation setup tool using shell scripts. It automates the installation of packages, dotfiles, and system preferences across macOS and Linux, with Windows support planned.

## Key Concepts

### Profiles

Profiles (`config/profiles/*.conf`) control what gets installed:
- `personal.conf` - Full installation for personal macOS devices
- `work.conf` - Minimal installation for work macOS devices
- `linux.conf` - Full dev station setup for Linux (Debian/Ubuntu)

Profile variables control which package categories are enabled:
- `FORMULAE_*` - Homebrew formula categories (macOS)
- `CASKS_*` - Homebrew cask categories (macOS)
- `PROFILE_MAS` - Mac App Store apps (macOS)
- `PROFILE_PACKAGES` - System packages (Linux)
- `PROFILE_APPLY_SECURITY` - Security preferences

### Package Lists

Packages are defined in text files under `config/packages/`:
- `macos/formulae/*.txt` - Homebrew CLI tools
- `macos/casks/*.txt` - Homebrew GUI apps
- `macos/mas/apps.txt` - Mac App Store apps (`ID|Name` format)
- `linux/apt/*.txt` - APT packages

Format: one package per line, comments start with `#`

### Dotfiles

Dotfiles use symlinks managed via `config/dotfiles/manifest.txt`:
- Format: `source|destination` or `source|destination|CONDITION_VAR`
- When a condition variable is specified, the line is only processed if that profile variable is `true`
- Existing files are backed up before linking
- Local overrides (`.local` files) are not tracked

### macOS Defaults

System preferences are set via `defaults write` commands in `platforms/macos/defaults/*.sh`. Each file defines an `apply_<name>()` function.

## Commands

```bash
# Full setup (interactive profile selection)
./setup.sh

# Full setup with profile
./setup.sh --profile personal   # macOS personal
./setup.sh --profile work       # macOS work
./setup.sh --profile linux      # Linux

# Dry run to preview changes
./setup.sh --dry-run --profile personal

# Install specific components (macOS)
./setup.sh homebrew            # Homebrew packages only
./setup.sh formulae            # CLI tools only
./setup.sh casks               # GUI apps only
./setup.sh mas                 # Mac App Store apps only
./setup.sh defaults            # System preferences only

# Install specific components (Linux)
./setup.sh packages            # APT packages only

# Install specific components (all platforms)
./setup.sh dotfiles            # Dotfiles only

# List/check status (no changes)
./setup.sh homebrew ls         # Show Homebrew package status (macOS)
./setup.sh formulae ls         # Show formulae status (macOS)
./setup.sh casks ls            # Show cask status (macOS)
./setup.sh mas ls              # Show MAS app status (macOS)
./setup.sh packages ls         # Show package status (Linux)
./setup.sh dotfiles ls         # Show symlink status
```

## Common Tasks

### Adding a new Homebrew package (macOS)

Add to appropriate category file in `config/packages/macos/`:
- `formulae/core.txt` - Essential CLI tools
- `formulae/shell.txt` - Shell enhancements
- `formulae/software-dev.txt` - Programming languages/tools
- `formulae/devops.txt` - Infrastructure tools
- `formulae/media.txt` - Media processing CLI tools
- `casks/productivity.txt` - Productivity apps
- `casks/development.txt` - Development apps
- `casks/utilities.txt` - System utilities
- `casks/creative.txt` - Graphics/design apps
- `casks/media.txt` - Media player apps

### Adding a new Linux package

Add to appropriate category file in `config/packages/linux/apt/`:
- `core.txt` - Essential CLI tools
- `shell.txt` - Shell enhancements
- `software-dev.txt` - Programming languages/tools
- `browsers.txt` - Web browsers

### Adding a new dotfile

1. Create the config file in `config/dotfiles/`
2. Add mapping to `config/dotfiles/manifest.txt` using `source|destination` format
3. Test with `./setup.sh dotfiles --dry-run`

### Adding a new macOS preference

1. Create or edit file in `platforms/macos/defaults/`
2. Define `apply_<filename>()` function
3. Check `is_dry_run` before running `defaults write` commands

### Adding a new profile

1. Copy existing profile: `cp config/profiles/personal.conf config/profiles/newprofile.conf`
2. Edit boolean flags to enable/disable package categories
3. Run with `./setup.sh --profile newprofile`

## Code Style

- Shell scripts use bash with `set -euo pipefail`
- Functions are documented with comments
- Use library functions from `lib/` for consistency:
  - `log_info`, `log_success`, `log_warn`, `log_error` for output
  - `log_step`, `log_substep` for section headers
  - `is_dry_run` to check dry-run mode
  - `run_cmd` to execute commands respecting dry-run
  - `command_exists` to check if a command is available

## Architecture

```
setup.sh (entry point)
    ├── Parses arguments and handles subcommands (homebrew, dotfiles, defaults, etc.)
    ├── Detects OS via lib/detect.sh
    ├── Loads profile from config/profiles/*.conf
    └── Dispatches to platform-specific setup:
        ├── platforms/macos/setup.sh
        │   ├── homebrew.sh (install_formulae, install_casks, install_mas_apps)
        │   ├── dotfiles.sh (process_manifest, check_manifest)
        │   └── defaults.sh (sources all defaults/*.sh files)
        └── platforms/linux/setup.sh
            ├── packages.sh (apt package installation)
            ├── repositories.sh (add third-party repos like NodeSource)
            ├── extras.sh (install tools like starship, eza, delta, zoxide)
            └── dotfiles.sh (process_manifest)
```

### Profile Variable Naming

Profile variables follow a naming convention that maps to package directories:
- `FORMULAE_CORE` → `config/packages/macos/formulae/core.txt`
- `CASKS_PRODUCTIVITY` → `config/packages/macos/casks/productivity.txt`
- `PACKAGES_CORE` → `config/packages/linux/apt/core.txt`
- Variable names use underscores, directory names use hyphens (e.g., `FORMULAE_SOFTWARE_DEV` → `software-dev.txt`)

## Security Considerations

This repo is public-safe:
- Personal data goes in `.local` files (gitignored)
- Git user.email is set in `~/.gitconfig.local`
