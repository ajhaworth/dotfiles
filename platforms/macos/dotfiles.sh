#!/usr/bin/env bash
# platforms/macos/dotfiles.sh - Dotfiles installation for macOS

# Source shared dotfiles functions
source "$SCRIPT_DIR/lib/dotfiles.sh"

# Setup dotfiles
setup_dotfiles() {
    print_header "Dotfiles Setup"

    local dotfiles_dir="$SCRIPT_DIR/config/dotfiles"
    local manifest="$dotfiles_dir/manifest.txt"

    if [[ ! -f "$manifest" ]]; then
        log_warn "Dotfiles manifest not found: $manifest"
        return 0
    fi

    log_step "Processing dotfiles manifest"

    # Process the manifest file
    process_manifest "$manifest"

    # Show status
    log_step "Dotfiles status"
    check_manifest "$manifest" || true

    # Create local override files if they don't exist
    create_local_overrides

    # Check GitHub CLI authentication
    setup_gh_auth

    log_success "Dotfiles setup complete"
}
