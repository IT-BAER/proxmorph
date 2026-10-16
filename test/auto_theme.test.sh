#!/usr/bin/env bash
# Automatic light/dark themes (issue #53): `install.sh auto-theme enable` must
# generate one theme-<key>-auto.css per collection pair, register it in the
# native theme_map, survive a second run without duplicates, and `disable` must
# take every trace back out while leaving other themes alone.
#
# Runnable anywhere with bash + coreutils: `bash test/auto_theme.test.sh`.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${HERE}/../install.sh"

fail=0
check() { # desc, expected, actual
    if [[ "$2" == "$3" ]]; then
        echo "PASS: $1"
    else
        echo "FAIL: $1 (expected '$2', got '$3')"
        fail=1
    fi
}

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# shellcheck source=../install.sh
source "$SRC" >/dev/null 2>&1   # guard skips main() when sourced
set +e                          # install.sh sets -e; tests manage rc themselves

# Sandbox every path the feature touches.
PRODUCT="PVE"
PROXY_SERVICE="pveproxy"
THEMES_DIR="${work}/live/themes"
INSTALL_DIR="${work}/opt"
PROXMOXLIB_JS="${work}/live/proxmoxlib.js"
AUTO_THEME_FILE="${work}/etc/auto-themes"
systemctl() { :; }   # install.sh restarts the proxy; nothing to restart here
mkdir -p "$THEMES_DIR" "${INSTALL_DIR}/themes"
printf 'Ext.define("x", {\n        theme_map: {\n\t"blue-slate": "Blue Slate",\n        },\n});\n' > "$PROXMOXLIB_JS"
for key in unifi unifi-light unifi-oled nord-light nord-dark gruvbox-light gruvbox-dark \
           solarized-light solarized-dark catppuccin-latte catppuccin-mocha blue-slate; do
    printf '/*!%s*/\n' "$key" > "${THEMES_DIR}/theme-${key}.css"
done

# --- 1. generate_auto_themes writes one importing stylesheet per pair -------
gen="${work}/gen"
cp -r "$THEMES_DIR" "$gen"
keys="$(generate_auto_themes "$gen" | sort | tr '\n' ' ')"
check "six auto themes generated" \
      "catppuccin-auto gruvbox-auto nord-auto solarized-auto unifi-auto unifi-oled-auto " "$keys"
check "dropdown title comes from the pair table" "/*!UniFi (Auto)*/" \
      "$(head -1 "${gen}/theme-unifi-auto.css")"
check "light import is media-conditioned" \
      "@import url(\"theme-nord-light.css?ver=${VERSION}\") (prefers-color-scheme: light);" \
      "$(sed -n 2p "${gen}/theme-nord-auto.css")"
check "dark import is media-conditioned" \
      "@import url(\"theme-nord-dark.css?ver=${VERSION}\") (prefers-color-scheme: dark);" \
      "$(sed -n 3p "${gen}/theme-nord-auto.css")"
check "generated file has no fourth line" "3" "$(wc -l < "${gen}/theme-nord-auto.css" | tr -d ' ')"

# Every key must pass pveproxy's cookie filter: ^[a-z]{1,10}(-[a-z]{1,10}){0,5}$
bad=""
for k in $keys; do
    [[ "$k" =~ ^[a-z]{1,10}(-[a-z]{1,10}){0,5}$ ]] || bad="${bad}${k} "
done
check "every auto key fits the PVEThemeCookie pattern" "" "$bad"

# --- 2. A pair with a missing counterpart is skipped, not half-written ------
partial="${work}/partial"
mkdir -p "$partial"
printf '/*!Nord Light*/\n' > "${partial}/theme-nord-light.css"
printf '/*!UniFi*/\n' > "${partial}/theme-unifi.css"
printf '/*!UniFi Light*/\n' > "${partial}/theme-unifi-light.css"
keys2="$(generate_auto_themes "$partial" 2>/dev/null | sort | tr '\n' ' ')"
check "only complete pairs are generated" "unifi-auto " "$keys2"
check "incomplete pair leaves no file" "no" \
      "$([[ -e "${partial}/theme-nord-auto.css" ]] && echo yes || echo no)"

# --- 3. enable: setting, live files, cache files, theme_map entries ----------
manage_auto_theme enable >/dev/null 2>&1
check "enable records the setting" "yes" "$([[ -f "$AUTO_THEME_FILE" ]] && echo yes || echo no)"
check "enable writes the live stylesheet" "yes" \
      "$([[ -f "${THEMES_DIR}/theme-unifi-auto.css" ]] && echo yes || echo no)"
check "enable writes the cache stylesheet for the apt hook" "yes" \
      "$([[ -f "${INSTALL_DIR}/themes/theme-unifi-auto.css" ]] && echo yes || echo no)"
check "enable registers the dropdown entry" "1" "$(grep -c '"unifi-auto": "UniFi (Auto)"' "$PROXMOXLIB_JS")"
check "enable registers all six" "6" "$(grep -c -- '-auto": ' "$PROXMOXLIB_JS")"

# --- 4. enable twice: no duplicate registrations -----------------------------
manage_auto_theme enable >/dev/null 2>&1
check "second enable does not duplicate theme_map entries" "6" "$(grep -c -- '-auto": ' "$PROXMOXLIB_JS")"
check "auto_themes_enabled reports on" "0" "$(auto_themes_enabled; echo $?)"

# --- 5. disable: everything back out, other themes untouched -----------------
manage_auto_theme disable >/dev/null 2>&1
check "disable removes the setting" "no" "$([[ -f "$AUTO_THEME_FILE" ]] && echo yes || echo no)"
check "disable removes live stylesheets" "0" "$(ls "${THEMES_DIR}"/theme-*-auto.css 2>/dev/null | wc -l | tr -d ' ')"
check "disable removes cache stylesheets" "0" "$(ls "${INSTALL_DIR}/themes"/theme-*-auto.css 2>/dev/null | wc -l | tr -d ' ')"
check "disable removes theme_map entries" "0" "$(grep -c -- '-auto": ' "$PROXMOXLIB_JS")"
check "disable keeps other registrations" "1" "$(grep -c '"blue-slate": "Blue Slate"' "$PROXMOXLIB_JS")"
check "disable keeps the base stylesheets" "12" "$(ls "${THEMES_DIR}"/theme-*.css | wc -l | tr -d ' ')"
check "auto_themes_enabled reports off" "1" "$(auto_themes_enabled; echo $?)"

# --- 6. status never writes -------------------------------------------------
manage_auto_theme status >/dev/null 2>&1
check "status does not enable" "no" "$([[ -f "$AUTO_THEME_FILE" ]] && echo yes || echo no)"

echo ""
if [[ "$fail" -eq 0 ]]; then echo "ALL PASS"; else echo "FAILURES PRESENT"; fi
exit "$fail"
