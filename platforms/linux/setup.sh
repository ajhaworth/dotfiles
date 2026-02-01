#!/usr/bin/env bash
# linux/setup.sh - Linux setup
#
# This script coordinates Linux setup.
# Currently supports dotfiles only; package management planned for future.

linux_setup() {
    print_header "Linux Setup"

    # Source Linux-specific modules
    source "$SCRIPT_DIR/platforms/linux/dotfiles.sh"

    # Dotfiles
    if [[ "${PROFILE_DOTFILES:-true}" == "true" ]]; then
        setup_dotfiles
    else
        log_info "Skipping dotfiles (disabled in profile)"
    fi

    # Future implementation will include:
    # - Package manager detection (apt, dnf, pacman, etc.)
    # - Package installation
    # - Desktop environment configuration

    log_success "Linux setup complete"
}
