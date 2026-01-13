#!/bin/bash
# ProxMorph Theme Collection Installer for Proxmox VE
# Supports: PVE 8.x, 9.x
# Integrates with native Proxmox theme selector

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PVE_MANAGER_DIR="/usr/share/pve-manager"
WIDGET_TOOLKIT_DIR="/usr/share/javascript/proxmox-widget-toolkit"
THEMES_DIR="${WIDGET_TOOLKIT_DIR}/themes"
PROXMOXLIB_JS="${WIDGET_TOOLKIT_DIR}/proxmoxlib.js"
BACKUP_DIR="/root/.proxmorph-backup"
GITHUB_REPO="IT-BAER/proxmorph"
INSTALL_DIR="/opt/proxmorph"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║        ProxMorph Theme Collection for Proxmox VE          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to print colored messages
print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }
print_theme() { echo -e "${MAGENTA}[T]${NC} $1"; }

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Check if Proxmox VE is installed
check_pve() {
    if ! command -v pveversion &> /dev/null; then
        print_error "Proxmox VE not detected. This script is for PVE only."
        exit 1
    fi
    PVE_VERSION=$(pveversion --verbose | head -1)
    print_info "Detected: $PVE_VERSION"
}

# Get latest release version from GitHub
get_latest_version() {
    curl -s "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | \
        grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/'
}

# Download and extract release from GitHub
download_release() {
    local version="${1:-$(get_latest_version)}"
    
    if [[ -z "$version" ]]; then
        print_error "Could not determine latest version"
        exit 1
    fi
    
    print_info "Downloading ProxMorph v${version}..."
    
    local download_url="https://github.com/${GITHUB_REPO}/releases/download/v${version}/proxmorph-${version}.tar.gz"
    local tmp_dir=$(mktemp -d)
    
    if ! curl -sL "$download_url" -o "${tmp_dir}/proxmorph.tar.gz"; then
        print_error "Failed to download release v${version}"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    # Extract to install directory
    mkdir -p "$INSTALL_DIR"
    rm -rf "${INSTALL_DIR:?}"/*
    tar -xzf "${tmp_dir}/proxmorph.tar.gz" -C "$INSTALL_DIR"
    rm -rf "$tmp_dir"
    
    # Save version info
    echo "$version" > "${INSTALL_DIR}/.version"
    
    print_status "Downloaded ProxMorph v${version}"
}

# Check for updates
check_updates() {
    local current_version=""
    if [[ -f "${INSTALL_DIR}/.version" ]]; then
        current_version=$(cat "${INSTALL_DIR}/.version")
    fi
    
    local latest_version=$(get_latest_version)
    
    if [[ -z "$latest_version" ]]; then
        print_warning "Could not check for updates (no internet?)"
        return 1
    fi
    
    if [[ "$current_version" == "$latest_version" ]]; then
        print_status "Already on latest version (v${current_version})"
        return 0
    elif [[ -n "$current_version" ]]; then
        print_info "Update available: v${current_version} → v${latest_version}"
        return 2
    else
        print_info "Latest version: v${latest_version}"
        return 2
    fi
}

# Create backup of original files
backup_files() {
    mkdir -p "$BACKUP_DIR"
    if [[ ! -f "${BACKUP_DIR}/proxmoxlib.js.original" ]]; then
        cp "$PROXMOXLIB_JS" "${BACKUP_DIR}/proxmoxlib.js.original"
        print_status "Created backup of proxmoxlib.js"
    fi
}

# Restore from package (clean state)
restore_packages() {
    print_info "Reinstalling widget toolkit to clean state..."
    apt-get -qq -o Dpkg::Use-Pty=0 reinstall proxmox-widget-toolkit 2>/dev/null
    print_status "Restored proxmox-widget-toolkit"
}

# Extract theme title from CSS file (first line comment)
get_theme_title() {
    local css_file="$1"
    # First line should be: /*!Theme Name*/
    local title=$(head -1 "$css_file" | sed -n 's|^/\*!\(.*\)\*/.*|\1|p')
    if [[ -z "$title" ]]; then
        # Fallback to filename
        title=$(basename "$css_file" .css | sed 's/theme-//' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
    fi
    echo "$title"
}

# Extract theme key from filename
get_theme_key() {
    local css_file="$1"
    # theme-blue-slate.css -> blue-slate
    basename "$css_file" .css | sed 's/^theme-//'
}

# Add theme to theme_map in proxmoxlib.js
patch_theme_map() {
    local theme_key="$1"
    local theme_title="$2"
    
    # Check if theme already exists
    if grep -q "\"${theme_key}\":" "$PROXMOXLIB_JS"; then
        print_info "Theme '${theme_key}' already registered"
        return 0
    fi
    
    # Add theme to theme_map
    sed -i "s/theme_map: {/theme_map: {\n\t\"${theme_key}\": \"${theme_title}\",/" "$PROXMOXLIB_JS"
    
    if grep -q "\"${theme_key}\":" "$PROXMOXLIB_JS"; then
        print_theme "Registered: ${theme_title}"
        return 0
    else
        print_error "Failed to register ${theme_title}"
        return 1
    fi
}

# Install all themes from themes directory
install_themes() {
    print_info "Installing ProxMorph themes..."
    
    # Find themes source - prefer INSTALL_DIR if it exists, otherwise use script dir
    if [[ -d "${INSTALL_DIR}/themes" ]]; then
        THEMES_SOURCE="${INSTALL_DIR}/themes"
    else
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        THEMES_SOURCE="${SCRIPT_DIR}/themes"
    fi
    
    if [[ ! -d "$THEMES_SOURCE" ]]; then
        print_error "Themes directory not found: $THEMES_SOURCE"
        print_info "Run with 'update' to download from GitHub releases"
        exit 1
    fi
    
    # Count themes
    theme_count=$(find "$THEMES_SOURCE" -name "theme-*.css" 2>/dev/null | wc -l)
    if [[ $theme_count -eq 0 ]]; then
        print_error "No theme files found (looking for theme-*.css)"
        exit 1
    fi
    
    print_info "Found $theme_count theme(s)"
    
    # Backup original files
    backup_files
    
    # Create themes directory if not exists
    mkdir -p "$THEMES_DIR"
    
    # Process each theme
    for css_file in "$THEMES_SOURCE"/theme-*.css; do
        if [[ -f "$css_file" ]]; then
            theme_key=$(get_theme_key "$css_file")
            theme_title=$(get_theme_title "$css_file")
            
            # Copy CSS file
            cp "$css_file" "${THEMES_DIR}/"
            chmod 644 "${THEMES_DIR}/$(basename "$css_file")"
            
            # Register in theme_map
            patch_theme_map "$theme_key" "$theme_title"
        fi
    done
    
    echo ""
    print_status "ProxMorph themes installed successfully!"
    echo ""
    print_info "To apply a theme:"
    print_info "  1. Clear your browser cache (Ctrl+Shift+R)"
    print_info "  2. Click your username → Color Theme"
    print_info "  3. Select a ProxMorph theme from the dropdown"
    
    # Restart pveproxy in background
    print_info "Restarting pveproxy service in background..."
    nohup systemctl restart pveproxy &>/dev/null &
}

# Install a specific theme
install_single_theme() {
    local theme_file="$1"
    
    if [[ ! -f "$theme_file" ]]; then
        print_error "Theme file not found: $theme_file"
        exit 1
    fi
    
    backup_files
    mkdir -p "$THEMES_DIR"
    
    theme_key=$(get_theme_key "$theme_file")
    theme_title=$(get_theme_title "$theme_file")
    
    cp "$theme_file" "${THEMES_DIR}/"
    chmod 644 "${THEMES_DIR}/$(basename "$theme_file")"
    patch_theme_map "$theme_key" "$theme_title"
    
    print_status "Theme '${theme_title}' installed!"
    print_info "Restarting pveproxy service in background..."
    nohup systemctl restart pveproxy &>/dev/null &
}

# Reinstall themes (after PVE update)
reinstall_themes() {
    print_info "Reinstalling ProxMorph themes..."
    restore_packages
    install_themes
}

# Uninstall all themes
uninstall_themes() {
    print_info "Uninstalling ProxMorph themes..."
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    THEMES_SOURCE="${SCRIPT_DIR}/themes"
    
    # Remove CSS files
    for css_file in "$THEMES_SOURCE"/theme-*.css; do
        if [[ -f "$css_file" ]]; then
            target_file="${THEMES_DIR}/$(basename "$css_file")"
            if [[ -f "$target_file" ]]; then
                rm "$target_file"
                print_status "Removed: $(basename "$css_file")"
            fi
        fi
    done
    
    # Restore original proxmoxlib.js
    restore_packages
    
    echo ""
    print_status "ProxMorph themes uninstalled!"
    print_info "Clear your browser cache to see the changes."
}

# List available themes
list_themes() {
    print_info "Available ProxMorph Themes:"
    echo ""
    
    # Find themes source - prefer INSTALL_DIR if it exists
    if [[ -d "${INSTALL_DIR}/themes" ]]; then
        THEMES_SOURCE="${INSTALL_DIR}/themes"
    else
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        THEMES_SOURCE="${SCRIPT_DIR}/themes"
    fi
    
    if [[ ! -d "$THEMES_SOURCE" ]]; then
        print_error "Themes directory not found"
        return 1
    fi
    
    for css_file in "$THEMES_SOURCE"/theme-*.css; do
        if [[ -f "$css_file" ]]; then
            theme_key=$(get_theme_key "$css_file")
            theme_title=$(get_theme_title "$css_file")
            
            # Check if installed
            if [[ -f "${THEMES_DIR}/$(basename "$css_file")" ]]; then
                echo -e "  ${GREEN}●${NC} ${theme_title} (${theme_key}) - Installed"
            else
                echo -e "  ${YELLOW}○${NC} ${theme_title} (${theme_key})"
            fi
        fi
    done
    echo ""
}

# Show status
show_status() {
    print_info "ProxMorph Status:"
    echo ""
    
    # Show installed version
    if [[ -f "${INSTALL_DIR}/.version" ]]; then
        local current_ver=$(cat "${INSTALL_DIR}/.version")
        echo -e "  Version:    ${GREEN}v${current_ver}${NC}"
    else
        echo -e "  Version:    ${YELLOW}Unknown (local install)${NC}"
    fi
    
    # Check if any ProxMorph themes are registered
    if grep -q "blue-slate\|unifi" "$PROXMOXLIB_JS" 2>/dev/null; then
        echo -e "  Theme Map:  ${GREEN}Patched${NC}"
    else
        echo -e "  Theme Map:  ${YELLOW}Not patched${NC}"
    fi
    
    # Count installed themes
    installed=0
    if [[ -d "${INSTALL_DIR}/themes" ]]; then
        THEMES_SOURCE="${INSTALL_DIR}/themes"
    else
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        THEMES_SOURCE="${SCRIPT_DIR}/themes"
    fi
    
    for css_file in "${THEMES_SOURCE}"/theme-*.css; do
        if [[ -f "${THEMES_DIR}/$(basename "$css_file")" ]]; then
            ((installed++))
        fi
    done
    echo -e "  Installed:  ${GREEN}${installed}${NC} theme(s)"
    
    # Backup status
    if [[ -f "${BACKUP_DIR}/proxmoxlib.js.original" ]]; then
        echo -e "  Backup:     ${GREEN}Available${NC}"
    else
        echo -e "  Backup:     ${YELLOW}Not created${NC}"
    fi
    
    echo ""
    list_themes
}

# Main menu
show_menu() {
    echo ""
    echo "Select an option:"
    echo "  1) Install themes"
    echo "  2) Update from GitHub (latest release)"
    echo "  3) Reinstall themes (after PVE update)"
    echo "  4) Uninstall themes"
    echo "  5) List themes"
    echo "  6) Show status"
    echo "  0) Exit"
    echo ""
    read -p "Enter choice [0-6]: " choice
    
    case $choice in
        1) install_themes ;;
        2) download_release && install_themes ;;
        3) reinstall_themes ;;
        4) uninstall_themes ;;
        5) list_themes ;;
        6) show_status ;;
        0) exit 0 ;;
        *) print_error "Invalid option" ; show_menu ;;
    esac
}

# Parse command line arguments
main() {
    check_root
    check_pve
    
    case "${1:-}" in
        install)
            install_themes
            ;;
        update)
            download_release "${2:-}"
            install_themes
            ;;
        reinstall)
            reinstall_themes
            ;;
        uninstall)
            uninstall_themes
            ;;
        list)
            list_themes
            ;;
        status)
            show_status
            ;;
        check)
            check_updates
            ;;
        *)
            show_menu
            ;;
    esac
}

main "$@"
