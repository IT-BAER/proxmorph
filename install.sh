#!/bin/bash
# ProxMorph Theme Collection Installer for Proxmox VE, Proxmox Backup Server, and Proxmox Datacenter Manager
# Supports: PVE 8.x/9.x, PBS 3.x/4.x, PDM 1.x
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
VERSION="2.6.0"
WIDGET_TOOLKIT_DIR="/usr/share/javascript/proxmox-widget-toolkit"
THEMES_DIR="${WIDGET_TOOLKIT_DIR}/themes"
PROXMOXLIB_JS="${WIDGET_TOOLKIT_DIR}/proxmoxlib.js"
BACKUP_DIR="/root/.proxmorph-backup"
GITHUB_REPO="IT-BAER/proxmorph"
INSTALL_DIR="/opt/proxmorph"

# Sensor support paths
SENSORS_CONFIG="${INSTALL_DIR}/.sensors-enabled"
NODES_PM="/usr/share/perl5/PVE/API2/Nodes.pm"
SENSORS_PATCH_MARKER="# ProxMorph Sensors"

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

# PDM-specific paths (Proxmox Datacenter Manager)
PDM_MANAGER_DIR="/usr/share/javascript/proxmox-datacenter-manager"
PDM_INDEX_HBS="${PDM_MANAGER_DIR}/index.hbs"
PDM_JS_PATCHES_DIR="${PDM_MANAGER_DIR}/js/proxmorph"
PDM_THEMES_DIR="${PDM_MANAGER_DIR}/proxmorph-themes"
PDM_SERVICE="proxmox-datacenter-api"

# Product detection (set by check_product)
PRODUCT=""
PRODUCT_VERSION=""
INDEX_TEMPLATE=""
JS_PATCHES_DIR=""
PROXY_SERVICE=""

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   ProxMorph Theme Collection for Proxmox VE, PBS & PDM   ║"
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

# Check if Proxmox Datacenter Manager is installed
check_pdm() {
    if command -v proxmox-datacenter-manager &> /dev/null || \
       dpkg -l proxmox-datacenter-manager-ui &> /dev/null; then
        PRODUCT="PDM"
        PRODUCT_VERSION=$(dpkg -l proxmox-datacenter-manager 2>/dev/null | awk '/^ii/{print "PDM " $3}' || echo "PDM (unknown version)")
        INDEX_TEMPLATE="$PDM_INDEX_HBS"
        JS_PATCHES_DIR="$PDM_JS_PATCHES_DIR"
        PROXY_SERVICE="$PDM_SERVICE"
        THEMES_DIR="$PDM_THEMES_DIR"
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
    elif check_pdm; then
        print_info "Detected: $PRODUCT_VERSION"
    else
        print_error "No supported Proxmox product detected."
        print_error "This script requires PVE 8.x/9.x, PBS 3.x/4.x, or PDM 1.x."
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
    if [[ "$PRODUCT" == "PDM" ]]; then
        # PDM: back up index.hbs only
        if [[ -f "$INDEX_TEMPLATE" && ! -f "${BACKUP_DIR}/index.hbs.original" ]]; then
            cp "$INDEX_TEMPLATE" "${BACKUP_DIR}/index.hbs.original"
            print_status "Created backup of index.hbs"
        fi
    elif [[ -f "$PROXMOXLIB_JS" && ! -f "${BACKUP_DIR}/proxmoxlib.js.original" ]]; then
        cp "$PROXMOXLIB_JS" "${BACKUP_DIR}/proxmoxlib.js.original"
        print_status "Created backup of proxmoxlib.js"
    fi
}

# Restore from package (clean state)
restore_packages() {
    if [[ "$PRODUCT" == "PDM" ]]; then
        # PDM: restore index.hbs from backup
        if [[ -f "${BACKUP_DIR}/index.hbs.original" ]]; then
            cp "${BACKUP_DIR}/index.hbs.original" "$INDEX_TEMPLATE"
            print_status "Restored index.hbs from backup"
        else
            print_warning "No index.hbs backup found — manually reinstall proxmox-datacenter-manager-ui"
        fi
        return 0
    fi
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

# PDM CSS Theme Override Configuration (Dynamic markers)
PDM_CSS_MARKER="<!-- ProxMorph PDM Theme -->"
PDM_CSS_MARKER_END="<!-- /ProxMorph PDM Theme -->"

# Install JavaScript patches
install_js_patches() {
    local patches_source="${1:-}"
    
    if [[ -z "$patches_source" ]]; then
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
        # If already patched, remove old block so we re-generate with current file list
        if grep -q "$JS_PATCH_MARKER" "$INDEX_TEMPLATE"; then
            local escaped_start_jp=$(printf '%s\n' "$JS_PATCH_MARKER" | sed 's/[]\/$*.^[]/\\&/g')
            local escaped_end_jp=$(printf '%s\n' "$JS_PATCH_MARKER_END" | sed 's/[]\/$*.^[]/\\&/g')
            sed -i "/${escaped_start_jp}/,/${escaped_end_jp}/d" "$INDEX_TEMPLATE"
            print_info "Refreshing JS patch list in $(basename "$INDEX_TEMPLATE")"
        fi
        {
            local script_tags="$JS_PATCH_MARKER"
            local js_web_path=""
            
            if [[ "$PRODUCT" == "PVE" ]]; then
                js_web_path="/pve2/js/proxmorph"
            elif [[ "$PRODUCT" == "PDM" ]]; then
                js_web_path="/pdm/js/proxmorph"
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
        }
    else
        print_warning "$(basename "$INDEX_TEMPLATE") not found - JS patches may not load"
    fi
}

# Remove JavaScript patches
remove_js_patches() {
    if [[ -d "$JS_PATCHES_DIR" ]]; then
        rm -rf "$JS_PATCHES_DIR"
        print_info "Removed JS patches directory"
    fi
    
    if [[ -f "$INDEX_TEMPLATE" ]] && grep -q "$JS_PATCH_MARKER" "$INDEX_TEMPLATE"; then
        local escaped_start=$(printf '%s\n' "$JS_PATCH_MARKER" | sed 's/[]\/$*.^[]/\\&/g')
        local escaped_end=$(printf '%s\n' "$JS_PATCH_MARKER_END" | sed 's/[]\/$*.^[]/\\&/g')
        sed -i "\|${escaped_start}|,\|${escaped_end}|d" "$INDEX_TEMPLATE"
        print_info "Removed JS patch from $(basename "$INDEX_TEMPLATE")"
    fi
}

# Install PDM CSS theme overrides into index.hbs
# PDM themes work by injecting a <link> tag that overrides --pwt-color-* tokens
# from the WASM-loaded base theme (Crisp/Desktop/Material)
install_pdm_themes() {
    local themes_source="$1"

    print_info "Installing PDM theme overrides..."

    mkdir -p "$PDM_THEMES_DIR"
    mkdir -p "$PDM_JS_PATCHES_DIR"

    # Copy base component CSS (always-on styling: rounded corners, shadows, etc.)
    local base_css="${themes_source}/proxmorph-pdm-base.css"
    if [[ -f "$base_css" ]]; then
        cp "$base_css" "${PDM_THEMES_DIR}/"
        chmod 644 "${PDM_THEMES_DIR}/proxmorph-pdm-base.css"
        print_info "Installed PDM base component styles"
    fi

    local theme_count=0
    for css_file in "$themes_source"/theme-*.css; do
        if [[ -f "$css_file" ]]; then
            cp "$css_file" "${PDM_THEMES_DIR}/"
            chmod 644 "${PDM_THEMES_DIR}/$(basename "$css_file")"
            local title=$(get_theme_title "$css_file")
            print_theme "Installed: ${title}"
            theme_count=$((theme_count + 1))
        fi
    done

    if [[ $theme_count -eq 0 ]]; then
        print_warning "No PDM theme files found"
        return 1
    fi

    # Copy theme selector JS patch
    # themes_source is either .../themes/pdm or /opt/proxmorph/themes/pdm
    # The JS patch lives in .../themes/patches/ (sibling to pdm/)
    local patches_dir="$(dirname "$themes_source")/patches"
    local selector_js="${patches_dir}/pdm-theme-selector.js"
    if [[ -f "$selector_js" ]]; then
        cp "$selector_js" "${PDM_JS_PATCHES_DIR}/"
        chmod 644 "${PDM_JS_PATCHES_DIR}/pdm-theme-selector.js"
        print_info "Installed PDM theme selector patch"
    fi

    # Inject CSS <link> tags + JS into index.hbs
    if [[ -f "$INDEX_TEMPLATE" ]]; then
        # Remove old block if present
        if grep -q "$PDM_CSS_MARKER" "$INDEX_TEMPLATE"; then
            local esc_start=$(printf '%s\n' "$PDM_CSS_MARKER" | sed 's/[]\/$*.^[]/\\&/g')
            local esc_end=$(printf '%s\n' "$PDM_CSS_MARKER_END" | sed 's/[]\/$*.^[]/\\&/g')
            sed -i "\|${esc_start}|,\|${esc_end}|d" "$INDEX_TEMPLATE"
            print_info "Refreshing PDM theme links in $(basename "$INDEX_TEMPLATE")"
        fi

        # Build injection block as a temp file (avoids sed multiline issues)
        local tmpblock=$(mktemp)
        echo "$PDM_CSS_MARKER" > "$tmpblock"

        # Base CSS — always enabled (component styles)
        echo "<link rel=\"stylesheet\" href=\"/proxmorph-themes/proxmorph-pdm-base.css\" class=\"proxmorph-base\" disabled>" >> "$tmpblock"

        # Theme CSS links — disabled by default, activated by JS
        for css_file in "${PDM_THEMES_DIR}"/theme-*.css; do
            if [[ -f "$css_file" ]]; then
                local css_name=$(basename "$css_file")
                echo "<link rel=\"stylesheet\" href=\"/proxmorph-themes/${css_name}\" class=\"proxmorph-theme\" disabled>" >> "$tmpblock"
            fi
        done

        # Inline activation script (runs before WASM loads)
        cat >> "$tmpblock" << 'JSBLOCK'
<script>
(function() {
    var saved = localStorage.getItem('proxmorph-theme');
    if (!saved) return;
    // Enable base component styles
    var base = document.querySelector('link.proxmorph-base');
    if (base) base.removeAttribute('disabled');
    // Enable the saved theme
    var links = document.querySelectorAll('link.proxmorph-theme');
    links.forEach(function(l) {
        if (l.href.indexOf(saved) !== -1) l.removeAttribute('disabled');
    });
})();
</script>
JSBLOCK

        # Theme selector patch (injects themes into native PDM Theme dialog)
        echo "<script src=\"/js/proxmorph/pdm-theme-selector.js\"></script>" >> "$tmpblock"

        echo "$PDM_CSS_MARKER_END" >> "$tmpblock"

        # Insert block before first </head> using awk
        local tmpout=$(mktemp)
        awk -v blockfile="$tmpblock" 'BEGIN{done=0; while((getline line < blockfile)>0) block=block (block?"\n":"") line} !done && /<\/head>/{print block; done=1} {print}' "$INDEX_TEMPLATE" > "$tmpout"
        mv "$tmpout" "$INDEX_TEMPLATE"
        chmod 644 "$INDEX_TEMPLATE"
        rm -f "$tmpblock"

        print_status "Injected ${theme_count} theme(s) + base styles + selector patch into $(basename "$INDEX_TEMPLATE")"
    else
        print_warning "$(basename "$INDEX_TEMPLATE") not found — PDM themes may not load"
    fi

    print_status "PDM themes installed — ${theme_count} theme(s)"
}

# Remove PDM CSS theme overrides
remove_pdm_themes() {
    if [[ -d "$PDM_THEMES_DIR" ]]; then
        rm -rf "$PDM_THEMES_DIR"
        print_info "Removed PDM theme overrides directory"
    fi
    if [[ -d "$PDM_JS_PATCHES_DIR" ]]; then
        rm -rf "$PDM_JS_PATCHES_DIR"
        print_info "Removed PDM JS patches directory"
    fi
    if [[ -f "$INDEX_TEMPLATE" ]] && grep -q "$PDM_CSS_MARKER" "$INDEX_TEMPLATE"; then
        local esc_start=$(printf '%s\n' "$PDM_CSS_MARKER" | sed 's/[]\/$*.^[]/\\&/g')
        local esc_end=$(printf '%s\n' "$PDM_CSS_MARKER_END" | sed 's/[]\/$*.^[]/\\&/g')
        sed -i "\|${esc_start}|,\|${esc_end}|d" "$INDEX_TEMPLATE"
        print_info "Removed PDM theme links from $(basename "$INDEX_TEMPLATE")"
    fi
}

# APT hook configuration for persistence across updates
APT_HOOK_FILE="/etc/apt/apt.conf.d/99proxmorph"
POST_INVOKE_SCRIPT="${INSTALL_DIR}/post-update.sh"

# Install apt hook for automatic re-patching after updates
install_apt_hook() {
    print_info "Installing apt hook for automatic re-patching..."
    
    mkdir -p "${INSTALL_DIR}"
    cat > "${POST_INVOKE_SCRIPT}" << SCRIPT
#!/bin/bash
# ProxMorph post-update hook - automatically re-patches after updates

PRODUCT="${PRODUCT}"
INSTALL_DIR="${INSTALL_DIR}"
PROXMOXLIB_JS="${PROXMOXLIB_JS}"
WIDGET_TOOLKIT_DIR="${WIDGET_TOOLKIT_DIR}"
INDEX_TEMPLATE="${INDEX_TEMPLATE}"
JS_PATCHES_DIR="${JS_PATCHES_DIR}"
PROXY_SERVICE="${PROXY_SERVICE}"
LOG_FILE="/var/log/proxmorph.log"
JS_PATCH_MARKER="${JS_PATCH_MARKER}"
JS_PATCH_MARKER_END="${JS_PATCH_MARKER_END}"
PDM_CSS_MARKER="${PDM_CSS_MARKER}"
PDM_CSS_MARKER_END="${PDM_CSS_MARKER_END}"
PDM_THEMES_DIR="${PDM_THEMES_DIR}"

# Set themes source based on product
if [ "\$PRODUCT" = "PDM" ]; then
    THEMES_SOURCE="\${INSTALL_DIR}/themes/pdm"
else
    THEMES_SOURCE="\${INSTALL_DIR}/themes"
fi

log() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] \$1" >> "\$LOG_FILE"
}

# Only proceed if themes are installed
if [ ! -d "\$THEMES_SOURCE" ]; then
    exit 0
fi

needs_repatch=false

# PDM repatch check: see if CSS injection is still in index.hbs
if [ "\$PRODUCT" = "PDM" ]; then
    if ! grep -q "\$PDM_CSS_MARKER" "\$INDEX_TEMPLATE" 2>/dev/null; then
        needs_repatch=true
    fi
else
    # PVE/PBS: check if proxmoxlib.js needs patching
    for css_file in "\${THEMES_SOURCE}"/theme-*.css; do
        if [ -f "\$css_file" ]; then
            theme_key=\$(basename "\$css_file" .css | sed 's/^theme-//')
            if ! grep -q "\"\${theme_key}\":" "\$PROXMOXLIB_JS" 2>/dev/null; then
                needs_repatch=true
            fi
            break
        fi
    done
fi

# Check if template needs JS patch (PVE/PBS only)
if [ "\$PRODUCT" != "PDM" ] && [ -d "\${THEMES_SOURCE}/patches" ] && ! grep -q "\$JS_PATCH_MARKER" "\$INDEX_TEMPLATE" 2>/dev/null; then
    needs_repatch=true
fi

if [ "\$needs_repatch" = "true" ]; then
    log "Detected \$PRODUCT update, re-applying ProxMorph patches..."

    if [ "\$PRODUCT" = "PDM" ]; then
        # PDM: Re-inject CSS overrides into index.hbs
        mkdir -p "\$PDM_THEMES_DIR"
        mkdir -p "\$PDM_JS_PATCHES_DIR"

        # Copy base component CSS
        base_css="\${THEMES_SOURCE}/proxmorph-pdm-base.css"
        if [ -f "\$base_css" ]; then
            cp "\$base_css" "\${PDM_THEMES_DIR}/"
            chmod 644 "\${PDM_THEMES_DIR}/proxmorph-pdm-base.css"
        fi

        for css_file in "\${THEMES_SOURCE}"/theme-*.css; do
            if [ -f "\$css_file" ]; then
                cp "\$css_file" "\${PDM_THEMES_DIR}/"
                chmod 644 "\${PDM_THEMES_DIR}/\$(basename "\$css_file")"
                log "Installed PDM theme: \$(basename "\$css_file")"
            fi
        done

        # Copy theme selector JS patch
        selector_js="\${INSTALL_DIR}/themes/patches/pdm-theme-selector.js"
        if [ -f "\$selector_js" ]; then
            cp "\$selector_js" "\${PDM_JS_PATCHES_DIR}/"
            chmod 644 "\${PDM_JS_PATCHES_DIR}/pdm-theme-selector.js"
        fi

        # Re-inject CSS link tags + JS
        if [ -f "\$INDEX_TEMPLATE" ] && ! grep -q "\$PDM_CSS_MARKER" "\$INDEX_TEMPLATE"; then
            tmpblock=\$(mktemp)
            echo "\$PDM_CSS_MARKER" > "\$tmpblock"

            # Base CSS (always enabled when theme active)
            echo "<link rel=\"stylesheet\" href=\"/proxmorph-themes/proxmorph-pdm-base.css\" class=\"proxmorph-base\" disabled>" >> "\$tmpblock"

            for css_file in "\${PDM_THEMES_DIR}"/theme-*.css; do
                if [ -f "\$css_file" ]; then
                    css_name=\$(basename "\$css_file")
                    echo "<link rel=\"stylesheet\" href=\"/proxmorph-themes/\${css_name}\" class=\"proxmorph-theme\" disabled>" >> "\$tmpblock"
                fi
            done
            cat >> "\$tmpblock" << 'JSBLK'
<script>
(function() {
    var saved = localStorage.getItem('proxmorph-theme');
    if (!saved) return;
    var base = document.querySelector('link.proxmorph-base');
    if (base) base.removeAttribute('disabled');
    var links = document.querySelectorAll('link.proxmorph-theme');
    links.forEach(function(l) {
        if (l.href.indexOf(saved) !== -1) l.removeAttribute('disabled');
    });
})();
</script>
JSBLK
            echo "<script src=\"/js/proxmorph/pdm-theme-selector.js\"></script>" >> "\$tmpblock"
            echo "\$PDM_CSS_MARKER_END" >> "\$tmpblock"
            tmpout=\$(mktemp)
            awk -v blockfile="\$tmpblock" 'BEGIN{done=0; while((getline line < blockfile)>0) block=block (block?"\n":"") line} !done && /<\/head>/{print block; done=1} {print}' "\$INDEX_TEMPLATE" > "\$tmpout"
            mv "\$tmpout" "\$INDEX_TEMPLATE"
            chmod 644 "\$INDEX_TEMPLATE"
            rm -f "\$tmpblock"
            log "Re-injected PDM theme CSS into \$(basename "\$INDEX_TEMPLATE")"
        fi
    else
        # PVE/PBS: Re-register all themes in proxmoxlib.js
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
                if [ "\$PRODUCT" = "PVE" ]; then
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

        # Re-apply Nodes.pm sensor patch if enabled
        SENSORS_CONFIG="\${INSTALL_DIR}/.sensors-enabled"
        NODES_PM="/usr/share/perl5/PVE/API2/Nodes.pm"
        SENSORS_PATCH_MARKER="# ProxMorph Sensors"
        if [ -f "\$SENSORS_CONFIG" ] && [ -f "\$NODES_PM" ]; then
            sensor_needs_patch=false
            if ! grep -q "\$SENSORS_PATCH_MARKER" "\$NODES_PM" 2>/dev/null; then
                sensor_needs_patch=true
            elif ! grep -q "safe_ups_name" "\$NODES_PM" 2>/dev/null || ! grep -q "/usr/bin/timeout -k 1 3 /usr/bin/upsc" "\$NODES_PM" 2>/dev/null; then
                sed -i "/\${SENSORS_PATCH_MARKER}/,/\${SENSORS_PATCH_MARKER} END/d" "\$NODES_PM"
                sensor_needs_patch=true
                log "Detected legacy Nodes.pm sensor patch, refreshing"
            fi

            if [ "\$sensor_needs_patch" = "true" ]; then
                sed -i "/^[[:space:]]*my \\\$dinfo = df/i\\
    \${SENSORS_PATCH_MARKER}\\
    local \\\$ENV{PATH} = '/usr/bin:/bin';\\
    \\\$res->{sensorsOutput} = \\\`sensors -j 2>/dev/null\\\`;\\
    if (-x '/usr/bin/upsc') {\\
        my \@ups_list = \\\`if [ -x /usr/bin/timeout ]; then /usr/bin/timeout -k 1 3 /usr/bin/upsc -l; else /usr/bin/upsc -l; fi 2>/dev/null\\\`;\\
        if (\@ups_list) {\\
            chomp(my \\\$ups_name = \\\$ups_list[0]);\\
            if (\\\$ups_name && \\\$ups_name =~ /^([A-Za-z0-9_.:-]+)$/) {\\
                my \\\$safe_ups_name = \\\$1;\\
                \\\$res->{upsData} = \\\`if [ -x /usr/bin/timeout ]; then /usr/bin/timeout -k 1 3 /usr/bin/upsc \\\$safe_ups_name; else /usr/bin/upsc \\\$safe_ups_name; fi 2>/dev/null\\\`;\\
            }\\
        }\\
    }\\
    \${SENSORS_PATCH_MARKER} END" "\$NODES_PM"
                log "Re-patched Nodes.pm for sensor data"
            fi
        fi
    fi  # end PVE/PBS else branch

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

# ─── Hardware Sensor Support (PVE only) ─────────────────────────

# Check if lm-sensors is available and what sensors exist
detect_sensors() {
    if [[ "$PRODUCT" != "PVE" ]]; then
        print_warning "Hardware sensor support is only available for Proxmox VE"
        return 1
    fi

    if ! command -v sensors &> /dev/null; then
        print_warning "lm-sensors is not installed"
        print_info "Install with: apt install lm-sensors && sensors-detect"
        return 1
    fi

    local sensor_output
    sensor_output=$(sensors -j 2>/dev/null) || true

    if [[ -z "$sensor_output" ]]; then
        print_warning "No sensor data available. Run 'sensors-detect' first."
        return 1
    fi

    # Report detected sensors
    local has_cpu=false has_nvme=false has_hdd=false has_fan=false has_ups=false

    echo "$sensor_output" | grep -q '"coretemp-isa-\|"k10temp-pci-' && has_cpu=true
    echo "$sensor_output" | grep -q '"nvme-pci-' && has_nvme=true
    echo "$sensor_output" | grep -q '"drivetemp-scsi-' && has_hdd=true
    echo "$sensor_output" | grep -q 'fan[0-9]*_input' && has_fan=true
    command -v upsc &> /dev/null && has_ups=true

    echo ""
    print_info "Detected hardware sensors:"
    [[ "$has_cpu"  == "true" ]] && echo -e "  ${GREEN}●${NC} CPU temperature (coretemp/k10temp)"
    [[ "$has_nvme" == "true" ]] && echo -e "  ${GREEN}●${NC} NVMe drive temperature"
    [[ "$has_hdd"  == "true" ]] && echo -e "  ${GREEN}●${NC} HDD drive temperature (drivetemp)"
    [[ "$has_fan"  == "true" ]] && echo -e "  ${GREEN}●${NC} Fan speed"
    [[ "$has_ups"  == "true" ]] && echo -e "  ${GREEN}●${NC} UPS monitoring (NUT)"

    [[ "$has_cpu" == "false" && "$has_nvme" == "false" && "$has_hdd" == "false" && "$has_fan" == "false" ]] && {
        print_warning "No supported sensors found in lm-sensors output"
        return 1
    }
    echo ""
    return 0
}

# Patch Nodes.pm to expose sensor data via the API
patch_nodes_pm() {
    if [[ ! -f "$NODES_PM" ]]; then
        print_error "Nodes.pm not found at $NODES_PM"
        return 1
    fi

    # Refresh legacy sensor patches so old installs get the taint-safe logic.
    if grep -q "$SENSORS_PATCH_MARKER" "$NODES_PM" 2>/dev/null; then
          if grep -q "local \$ENV{PATH} = '/usr/bin:/bin';" "$NODES_PM" 2>/dev/null && \
              grep -q "safe_ups_name" "$NODES_PM" 2>/dev/null && \
              grep -q "/usr/bin/timeout -k 1 3 /usr/bin/upsc" "$NODES_PM" 2>/dev/null; then
            print_info "Nodes.pm already patched for sensors"
            return 0
        fi

        print_warning "Legacy sensor patch detected in Nodes.pm, refreshing to current version"
        sed -i "/${SENSORS_PATCH_MARKER}/,/${SENSORS_PATCH_MARKER} END/d" "$NODES_PM"
    fi

    # Backup Nodes.pm
    if [[ ! -f "${BACKUP_DIR}/Nodes.pm.original" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$NODES_PM" "${BACKUP_DIR}/Nodes.pm.original"
        print_info "Backed up Nodes.pm"
    fi

    # Insert sensor data collection before 'my $dinfo = df('/', 1);'
    sed -i "/^\s*my \$dinfo = df/i\\
    ${SENSORS_PATCH_MARKER}\\
    local \$ENV{PATH} = '/usr/bin:/bin';\\
    \$res->{sensorsOutput} = \`sensors -j 2>/dev/null\`;\\
    if (-x '/usr/bin/upsc') {\\
        my \@ups_list = \`if [ -x /usr/bin/timeout ]; then /usr/bin/timeout -k 1 3 /usr/bin/upsc -l; else /usr/bin/upsc -l; fi 2>/dev/null\`;\\
        if (\@ups_list) {\\
            chomp(my \$ups_name = \$ups_list[0]);\\
            if (\$ups_name && \$ups_name =~ /^([A-Za-z0-9_.:-]+)$/) {\\
                my \$safe_ups_name = \$1;\\
                \$res->{upsData} = \`if [ -x /usr/bin/timeout ]; then /usr/bin/timeout -k 1 3 /usr/bin/upsc \$safe_ups_name; else /usr/bin/upsc \$safe_ups_name; fi 2>/dev/null\`;\\
            }\\
        }\\
    }\\
    ${SENSORS_PATCH_MARKER} END" "$NODES_PM"

    print_status "Patched Nodes.pm to expose hardware sensor data"
    return 0
}

# Remove sensor patches from Nodes.pm
unpatch_nodes_pm() {
    if [[ ! -f "$NODES_PM" ]]; then
        return 0
    fi

    if ! grep -q "$SENSORS_PATCH_MARKER" "$NODES_PM" 2>/dev/null; then
        return 0
    fi

    # Remove lines between our markers (inclusive)
    sed -i "/${SENSORS_PATCH_MARKER}/,/${SENSORS_PATCH_MARKER} END/d" "$NODES_PM"
    print_status "Removed sensor patches from Nodes.pm"
}

# Get list of remote cluster node hostnames (excludes local node)
get_remote_nodes() {
    if ! command -v pvecm &>/dev/null; then
        return 0
    fi

    # pvecm nodes can include a Qdevice status column (e.g. NR, NA,NV,NMW).
    # Use the last field as node name, skip local and qdevice rows.
    pvecm nodes 2>/dev/null | awk '$1 ~ /^[0-9]+$/ && $3 != "Qdevice" && $NF != "(local)" {print $NF}'
}

# Deploy sensor API patch to remote cluster nodes via scp
patch_cluster_sensors() {
    local remote_nodes
    remote_nodes=$(get_remote_nodes)

    if [[ -z "$remote_nodes" ]]; then
        return 0
    fi

    # Get local PVE version for comparison
    local local_version
    local_version=$(dpkg -l pve-manager 2>/dev/null | awk '/^ii/{print $3}')

    echo ""
    print_info "Cluster detected. Remote nodes need the API patch for sensors to work."
    echo ""
    for node in $remote_nodes; do
        echo -e "  ${CYAN}●${NC} ${node}"
    done
    echo ""

    read -p "Deploy sensor patch to remote nodes? [Y/n]: " deploy_choice
    case "$deploy_choice" in
        [Nn]|[Nn][Oo])
            print_info "Skipping remote nodes. Run 'install.sh manage-sensors enable' on each node individually."
            return 0
            ;;
    esac

    for node in $remote_nodes; do
        print_info "Deploying to ${node}..."

        # Verify same PVE version before copying Nodes.pm
        local remote_version
        remote_version=$(ssh -o ConnectTimeout=5 "root@${node}" "dpkg -l pve-manager 2>/dev/null | awk '/^ii/{print \$3}'" 2>/dev/null)

        if [[ -n "$local_version" && -n "$remote_version" && "$local_version" != "$remote_version" ]]; then
            print_warning "Version mismatch on ${node} (local: ${local_version}, remote: ${remote_version}) — skipping"
            print_info "Run install.sh on ${node} directly to enable sensors"
            continue
        fi

        if scp -o ConnectTimeout=5 -q "$NODES_PM" "root@${node}:${NODES_PM}" 2>/dev/null; then
            if ssh -o ConnectTimeout=5 "root@${node}" "systemctl restart pveproxy" 2>/dev/null; then
                print_status "Sensors deployed to ${node}"
            else
                print_warning "Patched ${node} but failed to restart pveproxy"
            fi
        else
            print_warning "Failed to deploy to ${node} — run install.sh on that node directly"
        fi
    done
}

# Remove sensor API patch from remote cluster nodes
unpatch_cluster_sensors() {
    local remote_nodes
    remote_nodes=$(get_remote_nodes)

    if [[ -z "$remote_nodes" ]]; then
        return 0
    fi

    for node in $remote_nodes; do
        print_info "Removing sensor patch from ${node}..."
        if ssh -o ConnectTimeout=5 "root@${node}" \
            "sed -i '/# ProxMorph Sensors/,/# ProxMorph Sensors END/d' /usr/share/perl5/PVE/API2/Nodes.pm 2>/dev/null && systemctl restart pveproxy" 2>/dev/null; then
            print_status "Sensors removed from ${node}"
        else
            print_warning "Failed to unpatch ${node}"
        fi
    done
}

# Install sensor support interactively
install_sensors() {
    if [[ "$PRODUCT" != "PVE" ]]; then
        return 0
    fi

    if ! detect_sensors; then
        return 0
    fi

    read -p "Enable hardware sensor monitoring in the dashboard? [y/N]: " sensor_choice
    case "$sensor_choice" in
        [Yy]|[Yy][Ee][Ss])
            patch_nodes_pm || return 1
            mkdir -p "$INSTALL_DIR"
            echo "enabled" > "$SENSORS_CONFIG"
            print_status "Hardware sensor monitoring enabled!"
            patch_cluster_sensors
            ;;
        *)
            print_info "Skipping sensor integration (can be enabled later with: install.sh sensors enable)"
            ;;
    esac
}

# Remove sensor support
remove_sensors() {
    unpatch_nodes_pm
    unpatch_cluster_sensors
    if [[ -f "$SENSORS_CONFIG" ]]; then
        rm -f "$SENSORS_CONFIG"
        print_info "Sensor configuration removed"
    fi
}

# Check if sensors are enabled
check_sensors() {
    if [[ -f "$SENSORS_CONFIG" ]] && grep -q "$SENSORS_PATCH_MARKER" "$NODES_PM" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Manage sensors subcommand
manage_sensors() {
    local action="${1:-status}"

    case "$action" in
        enable)
            if [[ "$PRODUCT" != "PVE" ]]; then
                print_error "Sensor support is only available for Proxmox VE"
                exit 1
            fi
            detect_sensors || exit 1
            patch_nodes_pm || exit 1
            mkdir -p "$INSTALL_DIR"
            echo "enabled" > "$SENSORS_CONFIG"
            print_status "Hardware sensor monitoring enabled!"
            print_info "Restarting ${PROXY_SERVICE}..."
            nohup systemctl restart "${PROXY_SERVICE}" &>/dev/null &
            patch_cluster_sensors
            ;;
        disable)
            remove_sensors
            print_status "Hardware sensor monitoring disabled"
            print_info "Restarting ${PROXY_SERVICE}..."
            nohup systemctl restart "${PROXY_SERVICE}" &>/dev/null &
            ;;
        detect)
            detect_sensors
            ;;
        status|*)
            if check_sensors; then
                echo -e "  Sensors:    ${GREEN}Enabled${NC}"
            else
                echo -e "  Sensors:    ${YELLOW}Disabled${NC}"
            fi
            ;;
    esac
}

# Interactive sensors management menu (called from show_menu option 7)
manage_sensors_menu() {
    if [[ "$PRODUCT" != "PVE" ]]; then
        print_error "Sensor support is only available for Proxmox VE"
        return
    fi
    
    echo ""
    echo "=== Hardware Sensor Management ==="
    echo ""
    manage_sensors status
    echo ""
    echo "  1) Enable sensors"
    echo "  2) Disable sensors"
    echo "  3) Detect available sensors"
    echo "  0) Back to main menu"
    echo ""
    read -p "Enter choice [0-3]: " sensor_choice
    
    case $sensor_choice in
        1) manage_sensors enable ;;
        2) manage_sensors disable ;;
        3) manage_sensors detect ;;
        0) show_menu ;;
        *) print_error "Invalid option" ; manage_sensors_menu ;;
    esac
}

# Get themes source directory - prioritizes local script directory, then /opt/proxmorph
# For PDM, looks for themes/pdm/ subdirectory first
get_themes_source() {
    # 1. Check local script directory (prioritize local execution/development)
    local script_dir=""
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null)"
    fi

    # Handle piped execution where BASH_SOURCE might be /dev/fd/*
    if [[ -n "$script_dir" && "$script_dir" != /dev/fd* && "$script_dir" != /proc/* && -d "${script_dir}/themes" ]]; then
        # PDM uses a separate theme subdirectory
        if [[ "$PRODUCT" == "PDM" && -d "${script_dir}/themes/pdm" ]]; then
            echo "${script_dir}/themes/pdm"
            return 0
        fi
        echo "${script_dir}/themes"
        return 0
    fi

    # 2. Check /opt/proxmorph (fallback to installed cache)
    if [[ -d "${INSTALL_DIR}/themes" ]]; then
        if [[ "$PRODUCT" == "PDM" && -d "${INSTALL_DIR}/themes/pdm" ]]; then
            echo "${INSTALL_DIR}/themes/pdm"
            return 0
        fi
        echo "${INSTALL_DIR}/themes"
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
    
    # PDM uses a completely different installation approach (CSS injection via index.hbs)
    if [[ "$PRODUCT" == "PDM" ]]; then
        # Sync to local cache
        if [[ "$themes_source" != "${INSTALL_DIR}/themes/pdm" ]]; then
            mkdir -p "${INSTALL_DIR}/themes/pdm"
            cp "$themes_source"/theme-*.css "${INSTALL_DIR}/themes/pdm/" 2>/dev/null || true
        fi
        
        install_pdm_themes "$themes_source"
        install_apt_hook
        echo "$VERSION" > "${INSTALL_DIR}/.version"
        
        echo ""
        print_status "ProxMorph PDM themes installed successfully!"
        echo ""
        print_info "To activate a theme:"
        print_info "  1. Open browser console (F12) on your PDM web UI"
        print_info "  2. Run: localStorage.setItem('proxmorph-theme', 'theme-dracula.css')"
        print_info "  3. Reload the page (Ctrl+Shift+R)"
        print_info ""
        print_info "Available themes:"
        for css_file in "$themes_source"/theme-*.css; do
            if [[ -f "$css_file" ]]; then
                local pname=$(basename "$css_file")
                local ptitle=$(get_theme_title "$css_file")
                print_theme "  ${ptitle}: localStorage.setItem('proxmorph-theme', '${pname}')"
            fi
        done
        print_info ""
        print_info "To disable: localStorage.removeItem('proxmorph-theme') + reload"
        
        # Restart service
        print_info "Restarting ${PROXY_SERVICE} service in background..."
        nohup systemctl restart "${PROXY_SERVICE}" &>/dev/null &
        return 0
    fi
    
    # PVE/PBS standard installation path
    # Create themes directory if not exists
    mkdir -p "$THEMES_DIR"
    mkdir -p "${INSTALL_DIR}/themes"
    
    # Process each theme
    for css_file in "$themes_source"/theme-*.css; do
        if [[ -f "$css_file" ]]; then
            theme_key=$(get_theme_key "$css_file")
            theme_title=$(get_theme_title "$css_file")
            
            # Copy CSS file to live Proxmox web directory
            cp "$css_file" "${THEMES_DIR}/"
            chmod 644 "${THEMES_DIR}/$(basename "$css_file")"
            
            # Sync to local cache so apt hook uses the newest files on update
            if [[ "$themes_source" != "${INSTALL_DIR}/themes" && "$themes_source" != "${INSTALL_DIR}/themes/pdm" ]]; then
                if [[ "$PRODUCT" == "PDM" ]]; then
                    mkdir -p "${INSTALL_DIR}/themes/pdm"
                    cp "$css_file" "${INSTALL_DIR}/themes/pdm/"
                else
                    cp "$css_file" "${INSTALL_DIR}/themes/"
                fi
            fi
            
            # Register in theme_map (PDM may not use proxmoxlib.js theme_map)
            if [[ -f "$PROXMOXLIB_JS" ]]; then
                patch_theme_map "$theme_key" "$theme_title"
            elif [[ "$PRODUCT" == "PDM" ]]; then
                print_info "PDM detected — skipping proxmoxlib.js theme_map (not applicable)"
            fi
        fi
    done
    
    # Sync JavaScript patches to cache if installing locally
    if [[ -d "${themes_source}/patches" && "$themes_source" != "${INSTALL_DIR}/themes" ]]; then
        mkdir -p "${INSTALL_DIR}/themes/patches"
        cp "${themes_source}/patches"/*.js "${INSTALL_DIR}/themes/patches/" 2>/dev/null || true
    fi
    
    # Install apt hook for persistence across updates
    install_apt_hook
    
    # Install JavaScript patches (chart colors, etc.)
    install_js_patches
    
    # Write version file
    echo "$VERSION" > "${INSTALL_DIR}/.version"
    
    # Offer hardware sensor integration (PVE only)
    if [[ "$PRODUCT" == "PVE" ]]; then
        echo ""
        install_sensors
    fi
    
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
    
    # PDM-specific uninstall
    if [[ "$PRODUCT" == "PDM" ]]; then
        remove_pdm_themes
        remove_apt_hook
        if [[ -d "$INSTALL_DIR" ]]; then
            rm -rf "$INSTALL_DIR"
            print_status "Removed install directory: $INSTALL_DIR"
        fi
        echo ""
        print_status "ProxMorph PDM themes uninstalled!"
        print_info "Clear your browser cache and localStorage to see the changes."
        print_info "Restarting ${PROXY_SERVICE}..."
        nohup systemctl restart "${PROXY_SERVICE}" &>/dev/null &
        return 0
    fi
    
    # PVE/PBS uninstall
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
    
    # Remove sensor patches
    remove_sensors
    
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
    
    # Dynamically check if our themes are registered in proxmoxlib.js
    local themes_source=$(get_themes_source)
    local is_patched=false
    if [[ -n "$themes_source" ]]; then
        for css_file in "${themes_source}"/theme-*.css; do
            if [[ -f "$css_file" ]]; then
                local theme_key=$(get_theme_key "$css_file")
                if grep -q "\"${theme_key}\":" "$PROXMOXLIB_JS" 2>/dev/null; then
                    is_patched=true
                    break
                fi
            fi
        done
    fi

    if [[ "$is_patched" == "true" ]]; then
        echo -e "  Theme Map:  ${GREEN}Patched${NC}"
    else
        echo -e "  Theme Map:  ${YELLOW}Not patched${NC}"
    fi
    
    # Count installed themes
    local installed=0
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
    
    # Sensor status (PVE only)
    if [[ "$PRODUCT" == "PVE" ]]; then
        manage_sensors status
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
    [[ "$PRODUCT" == "PVE" ]] && echo "  7) Manage sensors"
    echo "  0) Exit"
    echo ""
    read -p "Enter choice [0-7]: " choice
    
    case $choice in
        1) install_themes ;;
        2) download_release && install_themes ;;
        3) reinstall_themes ;;
        4) uninstall_themes ;;
        5) list_themes ;;
        6) show_status ;;
        7) manage_sensors_menu ;;
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
        sensors)
            manage_sensors "${2:-status}"
            ;;
        *)
            show_menu
            ;;
    esac
}

main "$@"
