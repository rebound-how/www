#!/bin/sh

# Licensed under the Apache v2 license
# <https://www.apache.org/licenses/LICENSE-2.0>, at your
# option. This file may not be copied, modified, or distributed
# except according to those terms.


#==============================================================================
# Rebound installer
#
# This sets up:
#   • fault         - a self-contained binary (Linux/macOS)
#   • Chaos Toolkit - a Python package
#   • Reliably      - a Python application using PostgreSQL 17 as its DB
#
# It ensures these dependencies are present:
#   • uv            - a fast package manager (installed via its official script)
#   • A uv-managed Python 3.12 (installed with uv)
#   • Docker        - with the Docker daemon running
#   • PostgreSQL 17 Docker image
#
# The script exits early if the OS is not Linux/macOS/Windows (WSL) or if a
# 32‑bit system is detected.
#
# All detailed output is logged to ./install.log.
#==============================================================================

set -euo pipefail

REBOUND_PYTHON_VERSION="3.12"

LOGFILE="./install.log"
: > "$LOGFILE"  # Clear the log file at start

# Color codes
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BOLD="\033[1m"
NC="\033[0m"  # No Color
REB=$(echo -e "REBOUND")

#---------------------------------------------------------------------
# Helper functions for printing status messages with emojis
#---------------------------------------------------------------------
print_success() {
    echo -e "${GREEN}✔${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}${BOLD}! $1${NC}"
}

print_error() {
    echo -e "${RED}✘${NC} $1" >&2
    exit 1
}
# Run a command silently (logging its output); exit with an error message if it fails.
run_step() {
    "$@" >> "$LOGFILE" 2>&1 || { print_error "Command '$*' failed. See $LOGFILE for details."; }
}

#---------------------------------------------------------------------
# Check system: only support Linux/macOS on 64-bit
#---------------------------------------------------------------------
check_system() {
    local os_type arch
    os_type=$(uname -s)
    arch=$(uname -m)
    echo "System check: OS=$os_type, Arch=$arch" >> "$LOGFILE"

    # Allow Linux and Darwin normally
    if [[ "$os_type" == "Linux" || "$os_type" == "Darwin" ]]; then
        :
    # If on a Windows environment (e.g. MINGW, CYGWIN, MSYS) check for WSL
    elif [[ "$os_type" == MINGW* || "$os_type" == CYGWIN* || "$os_type" == MSYS* ]]; then
        if [ -f /proc/version ] && grep -qi microsoft /proc/version; then
            echo "Detected WSL environment." >> "$LOGFILE"
        else
            print_error "Unsupported Windows environment. Please run this script under WSL."
        fi
    else
        print_error "Unsupported OS: $os_type. Only Linux, macOS, and Windows under WSL are supported by this installer."
    fi

    # Disallow 32-bit architectures
    if [[ "$arch" == "i386" || "$arch" == "i686" ]]; then
        print_error "Unsupported architecture: $arch. 32-bit systems are not supported."
    fi
}


#---------------------------------------------------------------------
# Ensure Docker is installed and running.
#---------------------------------------------------------------------
check_docker() {
    run_step command -v docker
    run_step docker info
}

#---------------------------------------------------------------------
# Install uv if not already installed.
#---------------------------------------------------------------------
install_uv() {
    if ! command -v uv &> /dev/null; then
        run_step bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
        export PATH="$HOME/.local/bin:$PATH"
    fi
    if ! command -v uv &> /dev/null; then
        print_error "uv installation failed. Check $LOGFILE."
    fi
}

#---------------------------------------------------------------------
# Update the shell environment using uv.
#---------------------------------------------------------------------
update_shell() {
    run_step uv tool update-shell
}

#---------------------------------------------------------------------
# Install Python 3.12 via uv.
#---------------------------------------------------------------------
install_python() {
    run_step uv python install --python-preference only-managed ${REBOUND_PYTHON_VERSION}
    if ! uv python list | grep -q "3.12" >> "$LOGFILE" 2>&1; then
        print_error "Python ${REBOUND_PYTHON_VERSION} installation via uv did not complete successfully."
    fi
}

#---------------------------------------------------------------------
# Install Chaos Toolkit and Reliably via uv.
#---------------------------------------------------------------------
install_tools() {
    run_step uv tool install --python-preference only-managed --python ${REBOUND_PYTHON_VERSION} chaostoolkit
    run_step uv tool install --python-preference only-managed --python ${REBOUND_PYTHON_VERSION} reliably-cli
}

#---------------------------------------------------------------------
# Install the fault binary if present.
#---------------------------------------------------------------------
FAULT_CLI_INSTALLED=1
install_fault_cli() {
    run_step bash -c 'curl -sSL https://fault-project.com/get | bash'

    if ! command -v fault &> /dev/null; then
        FAULT_CLI_INSTALLED=0
        print_error "fault installation failed. Check $LOGFILE."
    fi
}

#---------------------------------------------------------------------
# Pull the PostgreSQL 17 Docker image.
#---------------------------------------------------------------------
pull_postgresql() {
    run_step docker pull postgres:17
}

#---------------------------------------------------------------------
# Main installer: run steps and print a friendly summary gradually.
#---------------------------------------------------------------------
main() {
    echo "Starting ${REB} installation..."
    echo
    check_system
    check_docker
    pull_postgresql
    install_uv
    update_shell
    install_python
    install_fault_cli
    if [[ "$FAULT_CLI_INSTALLED" -eq 1 ]]; then
        print_success "fault cli installed: $(command -v fault)"
    else
        print_warning "fault cli not installed"
    fi
    install_tools
    print_success "Chaos Toolkit installed: $(command -v  chaos)"
    print_success "Reliably installed: $(command -v  reliably-server)"
    echo ""
    echo "Installation complete! Enjoy your freshly set up environment!"
    echo ""
    echo -e "Run '\033[34mreliably-server run\033[0m' and enjoy exploring your reliability posture!"
}

main
