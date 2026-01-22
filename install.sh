#!/bin/bash

# ProxMorph Theme Collection Installer for Proxmox VE and Proxmox Backup Server

# Supports: PVE 8.x/9.x, PBS 3.x/4.x

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

VERSION="2.2.4"

WIDGET_TOOLKIT_DIR="/usr/share/javascript/proxmox-widget-toolkit"

THEMES_DIR="${WIDGET_TOOLKIT_DIR}/themes"

PROXMOXLIB_JS="${WIDGET_TOOLKIT_DIR}/proxmoxlib.js"

BACKUP_DIR="/root/.proxmorph-backup"

GITHUB_REPO="IT-BAER/proxmorph"

INSTALL_DIR="/opt/proxmorph"



# PVE-specific paths

PVE_MANAGER_DIR="/usr/share/pve-manager"

PVE_INDEX_TPL="${PVE_MANAGER_DIR}/index.html.tpl"

PVE_JS_PATCHES_DIR="${PVE_MANAGER_DIR}/js/proxmorph"

PVE_SERVICE="pveproxy"



# PBS-specific paths

PBS_MANAGER_DIR="/usr/share/javascript/proxmox-backup"

PBS_INDEX_HBS="${PBS_MANAGER_DIR}/index.hbs"

PBS_JS_PATCHES_DIR="${PBS_MANAGER_DIR}/js/proxmorph"

PBS_SERVICE="proxmox-backup-proxy"



# Product detection (set by check_product)

PRODUCT=""

PRODUCT_VERSION=""

INDEX_TEMPLATE=""

JS_PATCHES_DIR=""

PROXY_SERVICE=""



echo -e "${CYAN}"

echo "╔═══════════════════════════════════════════════════════════╗"

echo "║    ProxMorph Theme Collection for Proxmox VE and PBS      ║"

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

    if command -v pveversion &> /dev/null; then

        PRODUCT="PVE"

        PRODUCT_VERSION=$(pveversion | head -1)

        INDEX_TEMPLATE="$PVE_INDEX_TPL"

        JS_PATCHES_DIR="$PVE_JS_PATCHES_DIR"

        PROXY_SERVICE="$PVE_SERVICE"

        return 0

    fi

    return 1

}



# Check if Proxmox Backup Server is installed

check_pbs() {

    if command -v proxmox-backup-manager &> /dev/null; then

        PRODUCT="PBS"

        PRODUCT_VERSION=$(proxmox-backup-manager version 2>/dev/null | head -1)

        INDEX_TEMPLATE="$PBS_INDEX_HBS"

        JS_PATCHES_DIR="$PBS_JS_PATCHES_DIR"

        PROXY_SERVICE="$PBS_SERVICE"

        return 0

    fi

    return 1

}



# Detect which Proxmox product is installed

check_product() {

    if check_pve; then

        print_info "Detected: $PRODUCT_VERSION"

    elif check_pbs; then

        print_info "Detected: $PRODUCT_VERSION"

    else

        print_error "Neither Proxmox VE nor Proxmox Backup Server detected."

        print_error "This script requires PVE 8.x/9.x or PBS 3.x/4.x."

        exit 1

    fi

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



# JavaScript Patches Configuration (Dynamic markers)
JS_PATCH_MARKER="<!-- ProxMorph JS Patches -->"
JS_PATCH_MARKER_END="<!-- /ProxMorph JS Patches -->"

# Install JavaScript patches
install_js_patches() {
    local patches_source="${1:-}"
    
    if [[ -z "$patches_source" ]]; then
        # Try to find patches directory
        local themes_source=$(get_themes_source)
        if [[ -n "$themes_source" ]] && [[ -d "${themes_source}/patches" ]]; then
            patches_source="${themes_source}/patches"
        fi
    fi
    
    if [[ -z "$patches_source" ]] || [[ ! -d "$patches_source" ]]; then
        print_info "No JavaScript patches found (optional)"
        return 0
    fi
    
    local js_count=$(find "$patches_source" -name "*.js" 2>/dev/null | wc -l)
    if [[ $js_count -eq 0 ]]; then
        print_info "No JavaScript patches to install"
        return 0
    fi
    
    print_info "Installing $js_count JavaScript patch(es) for ${PRODUCT}..."
    
    # Create JS patches directory
    mkdir -p "$JS_PATCHES_DIR"
    
    # Copy JS files
    for js_file in "$patches_source"/*.js; do
        if [[ -f "$js_file" ]]; then
            cp "$js_file" "${JS_PATCHES_DIR}/"
            chmod 644 "${JS_PATCHES_DIR}/$(basename "$js_file")"
            print_theme "Installed: $(basename "$js_file")"
        fi
    done
    
    # Patch index template to load JS files
    if [[ -f "$INDEX_TEMPLATE" ]]; then
        # Check if already patched
        if grep -q "$JS_PATCH_MARKER" "$INDEX_TEMPLATE"; then
            print_info "$(basename "$INDEX_TEMPLATE") already patched for JS"
        else
            # Build script tags for all JS patches
            local script_tags="$JS_PATCH_MARKER"
            local js_web_path=""
            
            if [[ "$PRODUCT" == "PVE" ]]; then
                js_web_path="/pve2/js/proxmorph"
            else
                js_web_path="/js/proxmorph"
            fi
            
            for js_file in "${JS_PATCHES_DIR}"/*.js; do
                if [[ -f "$js_file" ]]; then
                    local js_name=$(basename "$js_file")
                    script_tags="${script_tags}\n<script src=\"${js_web_path}/${js_name}\"></script>"
                fi
            done
            script_tags="${script_tags}\n${JS_PATCH_MARKER_END}"
            
            # Insert before </body>
            sed -i "s|</body>|${script_tags}\n</body>|" "$INDEX_TEMPLATE"
            print_status "Patched $(basename "$INDEX_TEMPLATE") with JS loader"
        fi
    else
        print_warning "$(basename "$INDEX_TEMPLATE") not found - JS patches may not load"
    fi
}

# Remove JavaScript patches
remove_js_patches() {
    # Remove JS files directory
    if [[ -d "$JS_PATCHES_DIR" ]]; then
        rm -rf "$JS_PATCHES_DIR"
        print_info "Removed JS patches directory"
    fi
    
    # Remove patch from template
    if [[ -f "$INDEX_TEMPLATE" ]] && grep -q "$JS_PATCH_MARKER" "$INDEX_TEMPLATE"; then
        # Use a different delimiter (|) to avoid issues with / in the pattern
        # Escape special regex characters for sed
        local escaped_start=$(printf '%s\n' "$JS_PATCH_MARKER" | sed 's/[]\/$*.^[]/\\&/g')
        local escaped_end=$(printf '%s\n' "$JS_PATCH_MARKER_END" | sed 's/[]\/$*.^[]/\\&/g')
        
        # Remove the ProxMorph JS block using | as delimiter
        sed -i "\|${escaped_start}|,\|${escaped_end}|d" "$INDEX_TEMPLATE"
        print_info "Removed JS patch from $(basename "$INDEX_TEMPLATE")"
    fi
}

# APT hook configuration for persistence across updates

APT_HOOK_FILE="/etc/apt/apt.conf.d/99proxmorph"

DPKG_HOOK_DIR="/etc/dpkg/dpkg.cfg.d"

POST_INVOKE_SCRIPT="${INSTALL_DIR}/post-update.sh"



# Install apt hook for automatic re-patching after updates
install_apt_hook() {
    print_info "Installing apt hook for automatic re-patching..."
    
    # Create post-update script
    mkdir -p "${INSTALL_DIR}"
    cat > "${POST_INVOKE_SCRIPT}" << SCRIPT
#!/bin/bash
# ProxMorph post-update hook - automatically re-patches after updates

PRODUCT="${PRODUCT}"
INSTALL_DIR="${INSTALL_DIR}"
PROXMOXLIB_JS="${PROXMOXLIB_JS}"
WIDGET_TOOLKIT_DIR="${WIDGET_TOOLKIT_DIR}"
INDEX_TEMPLATE="${INDEX_TEMPLATE}"
THEMES_SOURCE="\${INSTALL_DIR}/themes"
JS_PATCHES_DIR="${JS_PATCHES_DIR}"
PROXY_SERVICE="${PROXY_SERVICE}"
LOG_FILE="/var/log/proxmorph.log"
JS_PATCH_MARKER="${JS_PATCH_MARKER}"
JS_PATCH_MARKER_END="${JS_PATCH_MARKER_END}"

log() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] \$1" >> "\$LOG_FILE"
}

# Only proceed if themes are installed
if [ ! -d "\$THEMES_SOURCE" ]; then
    exit 0
fi

needs_repatch=false

# Check if proxmoxlib.js needs patching (our themes not registered)
if ! grep -q "blue-slate\|unifi\|github-dark" "\$PROXMOXLIB_JS" 2>/dev/null; then
    needs_repatch=true
fi

# Check if template needs JS patch
if [ -d "\${THEMES_SOURCE}/patches" ] && ! grep -q "\$JS_PATCH_MARKER" "\$INDEX_TEMPLATE" 2>/dev/null; then
    needs_repatch=true
fi

if [ "\$needs_repatch" = "true" ]; then
    log "Detected \$PRODUCT update, re-applying ProxMorph patches..."
    
    # Re-register all themes
    for css_file in "\${THEMES_SOURCE}"/theme-*.css; do
        if [ -f "\$css_file" ]; then
            theme_key=\$(basename "\$css_file" .css | sed 's/^theme-//')
            theme_title=\$(head -1 "\$css_file" | sed -n 's|^/\*!\(.*\)\*/.*|\1|p')
            if [ -z "\$theme_title" ]; then
                theme_title=\$(echo "\$theme_key" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
            fi
            
            if ! grep -q "\"\${theme_key}\":" "\$PROXMOXLIB_JS"; then
                sed -i "s/theme_map: {/theme_map: {\n\t\"\${theme_key}\": \"\${theme_title}\",/" "\$PROXMOXLIB_JS"
                log "Registered theme: \${theme_title}"
            fi
        fi
    done
    
    # Re-apply JavaScript patches
    if [ -d "\${THEMES_SOURCE}/patches" ]; then
        mkdir -p "\$JS_PATCHES_DIR"
        for js_file in "\${THEMES_SOURCE}/patches"/*.js; do
            if [ -f "\$js_file" ]; then
                cp "\$js_file" "\$JS_PATCHES_DIR/"
                chmod 644 "\$JS_PATCHES_DIR/\$(basename "\$js_file")"
                log "Installed JS patch: \$(basename "\$js_file")"
            fi
        done
        
        # Patch template if needed
        if [ -f "\$INDEX_TEMPLATE" ] && ! grep -q "\$JS_PATCH_MARKER" "\$INDEX_TEMPLATE"; then
            script_tags="\$JS_PATCH_MARKER"
            js_web_path=""
            if [[ "\$PRODUCT" == "PVE" ]]; then
                js_web_path="/pve2/js/proxmorph"
            else
                js_web_path="/js/proxmorph"
            fi
            
            for js_file in "\$JS_PATCHES_DIR"/*.js; do
                if [ -f "\$js_file" ]; then
                    js_name=\$(basename "\$js_file")
                    script_tags="\${script_tags}\n<script src=\"\${js_web_path}/\${js_name}\"></script>"
                fi
            done
            script_tags="\${script_tags}\n\$JS_PATCH_MARKER_END"
            
            sed -i "s|</body>|\${script_tags}\n</body>|" "\$INDEX_TEMPLATE"
            log "Patched \$(basename "\$INDEX_TEMPLATE") with JS loader"
        fi
    fi
    
    # Restart proxy service to apply changes
    systemctl restart "\$PROXY_SERVICE" 2>/dev/null || true
    log "ProxMorph patches re-applied successfully"
fi
SCRIPT
    chmod +x "${POST_INVOKE_SCRIPT}"
    
    # Create apt hook
    cat > "${APT_HOOK_FILE}" << HOOK
// ProxMorph: Automatically re-patch after updates
DPkg::Post-Invoke { "if [ -x ${POST_INVOKE_SCRIPT} ]; then ${POST_INVOKE_SCRIPT}; fi"; };
HOOK
    
    print_status "Apt hook installed - themes will persist across ${PRODUCT} updates"
}



# Remove apt hook

remove_apt_hook() {

    if [[ -f "${APT_HOOK_FILE}" ]]; then

        rm -f "${APT_HOOK_FILE}"

        print_info "Removed apt hook"

    fi

    if [[ -f "${POST_INVOKE_SCRIPT}" ]]; then

        rm -f "${POST_INVOKE_SCRIPT}"

    fi

}



# Check if apt hook is installed

check_apt_hook() {

    if [[ -f "${APT_HOOK_FILE}" ]] && [[ -f "${POST_INVOKE_SCRIPT}" ]]; then

        return 0

    fi

    return 1

}



# Get themes source directory - prioritizes /opt/proxmorph, then script directory

get_themes_source() {

    # 1. Check /opt/proxmorph

    if [[ -d "${INSTALL_DIR}/themes" ]]; then

        echo "${INSTALL_DIR}/themes"

        return 0

    fi

    

    # 2. Check script directory
    local script_dir=""
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null)"
    fi

    # Handle piped execution where BASH_SOURCE might be /dev/fd/*
    if [[ -n "$script_dir" && "$script_dir" != /dev/fd* && "$script_dir" != /proc/* && -d "${script_dir}/themes" ]]; then
        echo "${script_dir}/themes"
        return 0
    fi

    

    return 1

}



# Install all themes from themes directory

install_themes() {

    print_info "Installing ProxMorph themes..."

    

    local themes_source=$(get_themes_source)

    

    if [[ -z "$themes_source" ]]; then

        print_info "Local themes not found, attempting to download latest release..."

        download_release

        themes_source=$(get_themes_source)

        

        if [[ -z "$themes_source" ]]; then

            print_error "Failed to locate themes even after download"

            exit 1

        fi

    fi

    

    # Count themes

    local theme_count=$(find "$themes_source" -name "theme-*.css" 2>/dev/null | wc -l)

    if [[ $theme_count -eq 0 ]]; then

        print_error "No theme files found in $themes_source (looking for theme-*.css)"

        exit 1

    fi

    

    print_info "Found $theme_count theme(s)"

    

    # Backup original files

    backup_files

    

    # Create themes directory if not exists

    mkdir -p "$THEMES_DIR"

    

    # Process each theme

    for css_file in "$themes_source"/theme-*.css; do

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

    

    # Install apt hook for persistence across updates

    install_apt_hook

    

    # Install JavaScript patches (chart colors, etc.)

    install_js_patches

    

    # Write version file
    echo "$VERSION" > "${INSTALL_DIR}/.version"

    echo ""

    print_status "ProxMorph themes installed successfully!"

    echo ""

    print_info "To apply a theme:"

    print_info "  1. Clear your browser cache (Ctrl+Shift+R)"

    print_info "  2. Click your username → Color Theme"

    print_info "  3. Select a ProxMorph theme from the dropdown"

    

    # Restart proxy service in background
    print_info "Restarting ${PROXY_SERVICE} service in background..."
    nohup systemctl restart "${PROXY_SERVICE}" &>/dev/null &
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
    print_info "Restarting ${PROXY_SERVICE} service in background..."
    nohup systemctl restart "${PROXY_SERVICE}" &>/dev/null &
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

    

    # Find themes source

    local themes_source=$(get_themes_source) || THEMES_DIR

    

    # Remove CSS files

    for css_file in "$themes_source"/theme-*.css; do

        if [[ -f "$css_file" ]]; then

            target_file="${THEMES_DIR}/$(basename "$css_file")"

            if [[ -f "$target_file" ]]; then

                rm "$target_file"

                print_status "Removed: $(basename "$css_file")"

            fi

        fi

    done

    

    # Remove JavaScript patches

    remove_js_patches

    

    # Remove apt hook

    remove_apt_hook

    

    # Restore original proxmoxlib.js

    restore_packages

    

    # Clean up install directory

    if [[ -d "$INSTALL_DIR" ]]; then

        rm -rf "$INSTALL_DIR"

        print_status "Removed install directory: $INSTALL_DIR"

    fi

    

    echo ""

    print_status "ProxMorph themes uninstalled!"

    print_info "Clear your browser cache to see the changes."

}



# List available themes

list_themes() {

    print_info "Available ProxMorph Themes:"

    echo ""

    

    # Find themes source

    local themes_source=$(get_themes_source)

    

    if [[ -z "$themes_source" ]]; then

        print_error "Themes directory not found. Run 'update' first to download themes."

        return 1

    fi

    

    for css_file in "$themes_source"/theme-*.css; do

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

    local installed=0

    local themes_source=$(get_themes_source)

    

    if [[ -n "$themes_source" ]]; then

        for css_file in "${themes_source}"/theme-*.css; do

            if [[ -f "${THEMES_DIR}/$(basename "$css_file")" ]]; then

                installed=$((installed + 1))

            fi

        done

    fi

    echo -e "  Installed:  ${GREEN}${installed}${NC} theme(s)"

    

    # Backup status

    if [[ -f "${BACKUP_DIR}/proxmoxlib.js.original" ]]; then

        echo -e "  Backup:     ${GREEN}Available${NC}"

    else

        echo -e "  Backup:     ${YELLOW}Not created${NC}"

    fi

    

    # Apt hook status (persistence)
    if check_apt_hook; then
        echo -e "  Auto-patch: ${GREEN}Enabled${NC} (persists across ${PRODUCT} updates)"
    else
        echo -e "  Auto-patch: ${YELLOW}Not installed${NC}"
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

    echo "  3) Reinstall themes (after update)"

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
    check_product

    

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
