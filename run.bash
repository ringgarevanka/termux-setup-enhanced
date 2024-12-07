#!/data/data/com.termux/files/usr/bin/bash

# Script Information
readonly SCRIPT_NAME="TERMUX SETUP"
readonly SCRIPT_DESCRIPTION="A configuration and script setup for Termux environment."
readonly SCRIPT_VERSION="1.0.241207"
readonly DEVELOPER="Ringga"
readonly DEV_USERNAME="@ringgarevanka"

# Directory constants
readonly TERMUX_DIR="/data/data/com.termux"
readonly HOME_DIR="$HOME"
readonly TERMUX_CONF_DIR="$HOME_DIR/.termux"
readonly TERMUX_BIN_DIR="$TERMUX_DIR/files/usr/bin"

# ANSI color codes
readonly RESET="\033[0m"
readonly RED="\033[1;31m"
readonly GREEN="\033[1;32m"
readonly YELLOW="\033[1;33m"
readonly BLUE="\033[1;34m"

# Display functions
display_color() {
    printf "%b%s%b\n" "$1" "$2" "${RESET}"
}

display_red() {
    display_color "${RED}" "$1"
}
display_green() {
    display_color "${GREEN}" "$1"
}
display_yellow() {
    display_color "${YELLOW}" "$1"
}
display_blue() {
    display_color "${BLUE}" "$1"
}

show_header() {
    clear
    display_green "══════════════════════════════════════════════"
    display_green " $SCRIPT_NAME"
    display_green " $SCRIPT_DESCRIPTION"
    display_green " v$SCRIPT_VERSION"
    display_green " By: $DEVELOPER"
    display_green " $DEV_USERNAME"
    display_green "══════════════════════════════════════════════"
    echo
}

show_message() {
    show_header
    display_green "$1"
    echo
}

# Error handling and logging
readonly LOG_FILE="$HOME_DIR/termux_setup.log"

log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >>"$LOG_FILE"
}

log_error() {
    local line_no="$1"
    local command="$2"
    local error_code="$3"
    local message="Error on line ${line_no} executing: ${command} (Exit code: ${error_code})"
    display_red "$message"
    log_message "ERROR" "$message"
    return 1
}

# Network checking with retry
check_network() {
    local max_attempts=3
    local timeout=5

    for ((i = 1; i <= max_attempts; i++)); do
        display_yellow "Checking network connectivity (Attempt $i/$max_attempts)..."
        if timeout "${timeout}" ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            display_green "Network connectivity confirmed"
            return 0
        fi
        display_yellow "Network check failed. Retrying in 2 seconds..."
        sleep 2
    done

    display_red "Network unavailable after $max_attempts attempts"
    return 1
}

# Environment initialization
initialize_environment() {
    # Enable strict error handling
    set -euo pipefail

    # Set up error trapping
    trap 'log_error "$LINENO" "$BASH_COMMAND" "$?"' ERR
    trap 'display_red "Signal caught, cleaning up..."; cleanup; exit 1' INT TERM HUP

    # Move old log file if exist
    if [ -f "$LOG_FILE" ]; then
        OLD_LOG_FILE="$HOME_DIR/termux_setup_$(stat --format=%y "$LOG_FILE" | sed 's/ /_/g' | sed 's/://g').log"
        mv "$LOG_FILE" "$OLD_LOG_FILE"
    fi

    # Create new log file
    touch "$LOG_FILE"
    log_message "INFO" "Starting Termux setup script v$SCRIPT_VERSION"

    # Check network connectivity
    if ! check_network; then
        log_message "ERROR" "Network check failed"
        cleanup
        exit 1
    fi
}

# Package management functions
install_package() {
    local command="$1"
    local package="$2"
    local extra="${3:-" "}" # If extra is empty, defaults to " "
    local retry_count=3
    local attempt=1

    while ((attempt <= retry_count)); do
        display_yellow "Installing $package (attempt $attempt/$retry_count)..."
        if $command "$package" $extra >/dev/null 2>&1; then
            display_green "Successfully installed $package"
            log_message "INFO" "Package installed: $package"
            return 0
        fi

        display_yellow "Failed to install $package. Retrying..."
        ((attempt++))
        sleep 2
    done

    display_red "Failed to install $package after $retry_count attempts"
    log_message "ERROR" "Failed to install package: $package"
    return 1
}

perform_update_and_upgrade() {
    show_message "Updating package lists..."
    if ! pkg update -y; then
        log_message "ERROR" "Failed to update package lists"
        return 1
    fi

    show_message "Upgrading packages..."
    if ! pkg upgrade -y; then
        log_message "ERROR" "Failed to upgrade packages"
        return 1
    fi

    log_message "INFO" "Package update and upgrade completed"
}

# Storage configuration
configure_storage() {
    show_message "Setting up storage access..."
    if ! termux-setup-storage; then
        log_message "ERROR" "Failed to setup storage"
        return 1
    fi
    log_message "INFO" "Storage access configured"
}

# Package installation
install_repositories() {
    local -r repos=(
        x11-repo
        root-repo
        science-repo
        game-repo
        tur-repo
    )

    for repo in "${repos[@]}"; do
        show_message "Adding repository: $repo"
        install_package "pkg install" "$repo" "-y"
    done
}

install_essential_packages() {
    local -r packages=(
        # Terminal utilities
        termux-api
        termux-tools
        termux-auth
        termux-exec

        # Basic System Tools
        coreutils
        procps
        util-linux
        proot
        proot-distro

        # Version Management & Control
        git
        git-lfs
        subversion

        # Development Tools
        make
        clang
        libffi
        cmake
        shfmt
        pkg-config
        autoconf
        automake
        libtool

        # Programming language
        ## Python
        python
        python2
        python-pip

        ## Java
        openjdk-11
        openjdk-11-x
        openjdk-17
        openjdk-17-x
        openjdk-21
        openjdk-21-x

        ## Other Languages
        nodejs-lts
        ruby
        rust
        perl
        php
        golang

        # Network Tools
        ## Connectivity Tools
        curl
        wget
        openssh
        sshpass

        ## Network Analysis Tools
        nmap
        dnsutils
        iproute2
        httping
        tcpdump
        wireshark-gtk

        ## Browser Text
        w3m

        # Text & Processing Tools
        ## Editor
        vim
        nano
        emacs

        ## Text Utilities
        less
        grep
        sed
        jq
        figlet
        libxml2-utils

        # Compression Tool
        zip
        unzip
        tar
        gzip
        bzip2

        # Monitoring System
        fastfetch
        htop
        ncdu

        # Media Tools
        ffmpeg
        imagemagick

        # Security
        openssl
        gnupg
        sshpass

        # Database
        sqlite
        postgresql

        # Additional Utilities
        fzf
        ripgrep
        bat
        fd
        tree
        fakeroot
        cowsay

        # Shell Environment
        zsh
        fish
        tmux
        screen

        # Documentation
        man
        texinfo
    )

    show_message "Installing Termux packages..."
    for package in "${packages[@]}"; do
        show_message "Installing package: $package"
        install_package "pkg install" "$package" "-y"
    done
}

# Python packages installation
install_python_packages() {
    local -r packages=(
        # Package Management and Virtual Environments
        setuptools
        virtualenv

        # Interactive Development
        ipython

        # Web Development Frameworks
        flask
        django

        # Web Scraping, Automation and Networking
        requests[socks]
        requests
        beautifulsoup4
        selenium
        httpie

        # Image and Video Processing
        pillow

        # Code Quality and Testing
        pytest
        black
        pylint
    )

    show_message "Installing Python packages..."
    for package in "${packages[@]}"; do
        show_message "Installing package: $package"
        install_package "pip install --upgrade" "$package"
    done
}

# Node.js packages installation
install_node_packages() {
    local -r packages=(
        # Package Management
        yarn

        # Development Tools
        typescript
        nodemon
        pm2

        # Web application tools
        express-generator
        http-server
    )

    show_message "Installing Node.js packages..."
    for package in "${packages[@]}"; do
        show_message "Installing package: $package"
        install_package "npm install -g" "$package"
    done
}

# PHP Composer setup
#!/bin/bash

setup_php_composer() {
    show_message "Setting up PHP Composer..."

    # Define paths
    local tmp_dir="$HOME_DIR/tmp"
    local composer_setup="$tmp_dir/composer-setup.php"

    # Create tmp directory if it doesn't exist
    if [ ! -d "$tmp_dir" ]; then
        mkdir -p "$tmp_dir"
        if [ $? -ne 0 ]; then
            log_message "ERROR" "Failed to create temporary directory"
            return 1
        fi
        log_message "INFO" "Created temporary directory: $tmp_dir"
    fi

    # Check if PHP is installed
    if ! command -v php >/dev/null; then
        display_red "PHP is not installed. Please install PHP first."
        log_message "ERROR" "PHP is not installed"
        return 1
    fi

    local expected_sig
    local actual_sig

    # Download signature with retry mechanism
    for i in {1..3}; do
        if expected_sig=$(wget -q -O - https://composer.github.io/installer.sig); then
            break
        fi
        if [ $i -eq 3 ]; then
            log_message "ERROR" "Failed to download composer signature after 3 attempts"
            return 1
        fi
        sleep 2
    done

    # Download installer with retry mechanism
    for i in {1..3}; do
        if wget -q -O "$composer_setup" https://getcomposer.org/installer; then
            break
        fi
        if [ $i -eq 3 ]; then
            log_message "ERROR" "Failed to download composer installer after 3 attempts"
            return 1
        fi
        sleep 2
    done

    # Verify file exists before calculating hash
    if [ ! -f "$composer_setup" ]; then
        log_message "ERROR" "Composer setup file not found"
        return 1
    fi

    actual_sig=$(php -r "echo hash_file('SHA384', '${composer_setup}');")

    if [ "$expected_sig" = "$actual_sig" ]; then
        if php "$composer_setup" --install-dir="$TERMUX_BIN_DIR" --filename=composer; then
            display_green "PHP Composer installed successfully"
            log_message "INFO" "PHP Composer installed"
            rm -f "$composer_setup"
            return 0
        else
            display_red "Failed to install composer"
            log_message "ERROR" "Failed to install composer"
        fi
    else
        display_red "Composer installation failed: invalid signature"
        log_message "ERROR" "Composer installation failed: signature mismatch"
    fi

    rm -f "$composer_setup"
    return 1
}

# Terminal customization
customize_terminal() {
    show_message "Customizing terminal environment..."

    # Custom .bashrc file
    rm -rf "$HOME_DIR/.bashrc"
    cat >"$HOME_DIR/.bashrc" <<EOF
# Alias
source ~/.alias

# Main
clear
fastfetch -l none
EOF

    rm -rf "$HOME_DIR/.alias"
    cat >"$HOME_DIR/.alias" <<EOF
# Aliases

alias la='ls -a'         # List all files and directories, including hidden ones, in long format
alias ll='ls -lah'           # List files and directories in long format
alias lt='ls -ltr'         # List files and directories, sorted by modification time, newest last
alias md='mkdir'          # Create a new directory
alias rd='rmdir'          # Remove an empty directory
alias go='cd'             # Change directory
alias bd='cd ..'          # Change to the parent directory
alias hd='cd ~'           # Change to the home directory
alias pd='pwd'            # Print the current working directory
alias tf='touch'          # Create a new empty file or update file timestamp
alias cp='cp -i'          # Copy files/directories with confirmation if destination exists
alias mv='mv -i'          # Move/rename files/directories with confirmation if destination exists
alias rm='rm -i'          # Remove files/directories with confirmation
alias rf='rm -rf'         # Remove files/directories recursively and forcefully (USE WITH CAUTION!)
alias sz='du -sh *'       # Show the size of all files and directories in the current directory
alias fz='df -h'          # Show disk usage information
alias ff='find . -name'    # Find files by name in the current directory and its subdirectories
alias au='apt update'      # Update the list of available packages
alias ag='apt upgrade'     # Upgrade installed packages
alias ai='apt install'     # Install a new package
alias ar='apt remove'      # Remove an installed package
alias as='apt search'      # Search for available packages
alias pu='pkg update'      # Update the list of packages (alternative to apt)
alias pg='pkg upgrade'     # Upgrade packages (alternative to apt)
alias pi='pkg install'     # Install a package (alternative to apt)
alias pr='pkg remove'      # Remove a package (alternative to apt)
alias ps='pkg search'      # Search for packages (alternative to apt)
alias apug='apt update -y && apt upgrade -y && pkg update -y && pkg upgrade -y'  # Update and Upgrade
alias c='clear'           # Clear the terminal screen
EOF

    # Configure Termux properties
    mkdir -p "$TERMUX_CONF_DIR"
    rm -rf "$TERMUX_CONF_DIR/termux.properties"
    cat >"$TERMUX_CONF_DIR/termux.properties" <<EOF
# Terminal configuration
extra-keys = [[{key: 'ESC', popup: {macro: 'CTRL d', display: 'EXIT'}},{key: '/', popup: '&&'},{key: '-', popup: '|'},'HOME',{key: 'UP', popup: 'PGUP'},'END',{key: 'BKSP', popup: 'DEL'}],['TAB',{key: 'CTRL', popup: 'PASTE'},'ALT','LEFT',{key: 'DOWN', popup: 'PGDN'},'RIGHT',{key: 'KEYBOARD', popup: 'DRAWER'}]]
use-black-ui=true
shortcut.create-session = ctrl + t
shortcut.next-session = ctrl + 2
shortcut.previous-session = ctrl + 1
shortcut.rename-session = ctrl + n
bell-character=vibrate
allow-external-apps=true
terminal-transcript=true

EOF

    log_message "INFO" "Terminal customization completed"
}

# System cleanup
cleanup() {
    show_message "Performing system cleanup..."

    # Clean package cache
    pkg clean
    apt autoremove -y --purge
    apt clean

    # Remove temporary files
    rm -rf "${TERMUX_DIR}/tmp/"* 2>/dev/null
    rm -rf "${HOME_DIR}/.termux/tmp/"* 2>/dev/null

    # Clean bash path cache
    hash -r

    # Clean pip cache
    pip cache purge

    # Clean npm cache
    npm cache clean --force

    log_message "INFO" "System cleanup completed"

    # Remove setup script
    rm -f "$0"
}

# Main installation process
main() {
    show_header

    local failed_steps=()

    {
        perform_update_and_upgrade &&
            configure_storage &&
            install_repositories &&
            install_essential_packages &&
            install_python_packages &&
            install_node_packages &&
            setup_php_composer &&
            customize_terminal &&
            termux-reload-settings
    } || {
        failed_steps+=("$?")
    }

    if ((${#failed_steps[@]} > 0)); then
        display_red "Setup completed with ${#failed_steps[@]} errors"
        log_message "ERROR" "Setup completed with errors"
        return 1
    fi

    display_green "══════════════════════════════════════════════"
    display_green " Setup completed successfully!"
    display_green " "
    display_green " Please restart Termux to apply changes."
    display_green "══════════════════════════════════════════════"

    log_message "INFO" "Setup completed successfully"
    return 0
}

# Execute with proper initialization and cleanup
initialize_environment
main
cleanup
