#!/usr/bin/env bash
# Custom UI font (issue #58): `install.sh font <family> [file|url]` must write
# the setting, generate an icon-safe stylesheet (no `*`, no `!important`, no
# icon classes), embed a given font file, link it after the theme <link>, be
# idempotent, survive the apt hook, and `font none` must take everything out.
#
# Runnable anywhere with bash + coreutils: `bash test/font.test.sh`.
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
THEME_WEB_PATH="/pwt/themes"
THEME_COOKIE="PVEThemeCookie"
WIDGET_TOOLKIT_DIR="${work}/live"
THEMES_DIR="${WIDGET_TOOLKIT_DIR}/themes"
PROXMOXLIB_JS="${WIDGET_TOOLKIT_DIR}/proxmoxlib.js"
INSTALL_DIR="${work}/opt"
POST_INVOKE_SCRIPT="${INSTALL_DIR}/post-update.sh"
INDEX_TEMPLATE="${work}/live/index.html.tpl"
FONT_FILE="${work}/etc/font"
FONT_CSS="${work}/etc/font.css"
systemctl() { :; }   # install.sh restarts the proxy; nothing to restart here
mkdir -p "$THEMES_DIR" "${INSTALL_DIR}/themes"
printf 'Ext.define("x", {\n        theme_map: {\n\t"blue-slate": "Blue Slate",\n        },\n});\n' > "$PROXMOXLIB_JS"
printf '/*!Blue Slate*/\n' > "${THEMES_DIR}/theme-blue-slate.css"
cat > "$INDEX_TEMPLATE" << 'TPL'
<html>
  <head>
    <link rel="stylesheet" type="text/css" href="/pwt/themes/theme-[% theme %].css?ver=[% wtversion %]" />
  </head>
  <body>
  </body>
</html>
TPL
fixture="${work}/Fixture-Variable.woff2"
printf 'wOF2fake-font-bytes' > "$fixture"
fixture_b64="$(base64 -w0 "$fixture")"

# --- 1. font <family> <file>: setting, stylesheet, embedding, link ----------
manage_font "Inter" "$fixture" >/dev/null 2>&1
check "setting records the family" "Inter" "$(cat "$FONT_FILE" 2>/dev/null)"
check "generated stylesheet is kept in /etc" "yes" "$([[ -f "$FONT_CSS" ]] && echo yes || echo no)"
check "live stylesheet is served from the themes dir" "yes" \
      "$([[ -f "${THEMES_DIR}/proxmorph-font.css" ]] && echo yes || echo no)"
check "live and kept stylesheet are identical" "yes" \
      "$(cmp -s "$FONT_CSS" "${THEMES_DIR}/proxmorph-font.css" && echo yes || echo no)"
check "font file is embedded as base64 woff2" "1" \
      "$(grep -c "src: url(\"data:font/woff2;base64,${fixture_b64}\") format(\"woff2\")" "$FONT_CSS")"
check "@font-face declares the family" "1" "$(grep -c '@font-face { font-family: "Inter";' "$FONT_CSS")"
check "typography rule names the family first" "1" "$(grep -c 'font-family: "Inter", ' "$FONT_CSS")"

# --- 2. icon safety -----------------------------------------------------------
check "no universal selector" "0" "$(grep -c '^\*\|, \*\|^\s*\*\s*{' "$FONT_CSS")"
check "no !important" "0" "$(grep -c '!important' "$FONT_CSS")"
check "no icon classes targeted" "0" "$(grep -c '\.fa\b\|\.x-fa\|fa-\|font-logos\|\.x-tree-icon\|\.x-tree-expander\|x-grid-filters' "$FONT_CSS")"
# ExtJS crisp sets the text font on these; everything else inherits.
for sel in '.x-body' '.x-panel-body-default' '.x-panel-body-default-framed' '.x-window-body-default' \
           '.x-panel-header-title-default' '.x-panel-header-title-default-framed' \
           '.x-window-header-title-default' '.x-progress-default .x-progress-text' \
           '.x-accordion-hd .x-panel-header-title' '.x-treelist-item-text' '.x-form-field' \
           '.x-btn-inner' '.x-grid-cell-inner' '.x-menu-item-text' '.x-tab-inner'; do
    check "targets ${sel}" "yes" "$(grep -qF "${sel}" "$FONT_CSS" && echo yes || echo no)"
done

# --- 3. template: one link block, after the theme link, before </head> --------
check "one font marker block" "1" "$(grep -c '<!-- ProxMorph Font -->' "$INDEX_TEMPLATE")"
check "link points at the served stylesheet" "1" \
      "$(grep -c 'href="/pwt/themes/proxmorph-font.css?v=' "$INDEX_TEMPLATE")"
theme_line="$(grep -n 'theme-\[% theme %\]' "$INDEX_TEMPLATE" | cut -d: -f1)"
font_line="$(grep -n 'proxmorph-font.css' "$INDEX_TEMPLATE" | cut -d: -f1)"
head_line="$(grep -n '</head>' "$INDEX_TEMPLATE" | cut -d: -f1)"
check "font link follows the theme link" "yes" "$([[ "$font_line" -gt "$theme_line" ]] && echo yes || echo no)"
check "font link precedes </head>" "yes" "$([[ "$font_line" -lt "$head_line" ]] && echo yes || echo no)"

# --- 4. idempotent re-run and family change -------------------------------------
manage_font "Inter" "$fixture" >/dev/null 2>&1
check "second run keeps one marker block" "1" "$(grep -c '<!-- ProxMorph Font -->' "$INDEX_TEMPLATE")"
manage_font "Segoe UI" >/dev/null 2>&1
check "system font: setting updated" "Segoe UI" "$(cat "$FONT_FILE")"
check "system font: no @font-face" "0" "$(grep -c '@font-face' "$FONT_CSS")"
check "system font: typography rule present" "1" "$(grep -c 'font-family: "Segoe UI", ' "$FONT_CSS")"
check "system font: still one marker block" "1" "$(grep -c '<!-- ProxMorph Font -->' "$INDEX_TEMPLATE")"

# --- 5. input validation (run in subshells: the CLI exits on error) -----------
( manage_font 'Bad"Name' >/dev/null 2>&1 ); check "family with quote is rejected" "1" "$?"
( manage_font 'Fine' "${work}/missing.woff2" >/dev/null 2>&1 ); check "missing font file is rejected" "1" "$?"
( manage_font 'Fine' "${work}/proxmoxlib.js.txt" >/dev/null 2>&1 ); check "unknown extension is rejected" "1" "$?"
check "rejected calls do not change the setting" "Segoe UI" "$(cat "$FONT_FILE")"

# --- 6. apt hook restores the link and the live file after a template reset ----
printf '#!/bin/bash\n# stale hook from an older installer\n' > "$POST_INVOKE_SCRIPT"
manage_font "Inter" "$fixture" >/dev/null 2>&1
check "setting a font refreshes an existing hook" "yes" \
      "$(grep -q 'FONT_MARKER=' "$POST_INVOKE_SCRIPT" && echo yes || echo no)"
sed -i "s|^LOG_FILE=.*|LOG_FILE=\"${work}/hook.log\"|" "$POST_INVOKE_SCRIPT"
remove_font_injection >/dev/null 2>&1
rm -f "${THEMES_DIR}/proxmorph-font.css"
check "precondition: marker gone" "0" "$(grep -c '<!-- ProxMorph Font -->' "$INDEX_TEMPLATE")"
bash "$POST_INVOKE_SCRIPT" >/dev/null 2>&1
check "hook re-injects the font link" "1" "$(grep -c '<!-- ProxMorph Font -->' "$INDEX_TEMPLATE")"
check "hook restores the live stylesheet" "yes" \
      "$(cmp -s "$FONT_CSS" "${THEMES_DIR}/proxmorph-font.css" && echo yes || echo no)"
bash "$POST_INVOKE_SCRIPT" >/dev/null 2>&1
check "hook run without damage adds nothing" "1" "$(grep -c '<!-- ProxMorph Font -->' "$INDEX_TEMPLATE")"

# --- 7. font none: everything out, template otherwise intact ----------------------
manage_font none >/dev/null 2>&1
check "none removes the setting" "no" "$([[ -f "$FONT_FILE" ]] && echo yes || echo no)"
check "none removes the kept stylesheet" "no" "$([[ -f "$FONT_CSS" ]] && echo yes || echo no)"
check "none removes the live stylesheet" "no" "$([[ -f "${THEMES_DIR}/proxmorph-font.css" ]] && echo yes || echo no)"
check "none removes the marker block" "0" "$(grep -c 'ProxMorph Font' "$INDEX_TEMPLATE")"
check "theme link survives" "1" "$(grep -c 'theme-\[% theme %\]' "$INDEX_TEMPLATE")"
check "template line count back to original" "7" "$(wc -l < "$INDEX_TEMPLATE" | tr -d ' ')"
check "font_configured reports off" "1" "$(font_configured; echo $?)"

# --- 8. status never writes ----------------------------------------------------------
manage_font >/dev/null 2>&1
check "status does not configure a font" "no" "$([[ -f "$FONT_FILE" ]] && echo yes || echo no)"

# --- 9. PDM: selectors extracted from the Yew stylesheets, link in the PDM block ---
PRODUCT="PDM"
PROXY_SERVICE="proxmorph-test-noop"   # nohup bypasses the systemctl stub
DEFAULT_THEME_FILE="${work}/etc/default-theme"
THEME_WEB_PATH=""
THEME_COOKIE=""
PDM_MANAGER_DIR="${work}/pdm"
PDM_THEMES_DIR="${PDM_MANAGER_DIR}/proxmorph-themes"
PDM_JS_PATCHES_DIR="${PDM_MANAGER_DIR}/js/proxmorph"
INDEX_TEMPLATE="${PDM_MANAGER_DIR}/index.hbs"
JS_PATCHES_DIR="$PDM_JS_PATCHES_DIR"
mkdir -p "$PDM_MANAGER_DIR"
cat > "$INDEX_TEMPLATE" << 'HBS'
<html>
  <head>
    <link href="/fontawesome/css/font-awesome.css" rel="stylesheet">
  </head>
  <body>
  </body>
</html>
HBS
cat > "${PDM_MANAGER_DIR}/desktop-yew-style.css" << 'YEW'
@font-face{font-family:"Roboto Flex";src:url("../fonts/RobotoFlexVariableFont.woff2") format("woff2")}
:root{--pwt-x:1;font-family:"Roboto Flex"}
.pwt-dialog{color:red;font-family:"Roboto Flex"}
h1,.h1{font-family:"Roboto Flex";font-size:2rem}
.pwt-table {
  font-family: "Roboto Flex";
  /* disabled for now
.pwt-commented-out,
.pwt-also-commented { cursor: none; }
  */
}
.pwt-font-body-large{font-family:"Roboto Flex" !important;font-variation-settings:"opsz" 16,"wdth" 100 !important}
.pwt-font-monospace{font-family:monospace}
.fa{font-family:FontAwesome}
YEW
printf '.pwt-dialog{font-family:"Roboto Flex"}\n.pwt-only-crisp{font-family:"Roboto Flex"}\n' \
    > "${PDM_MANAGER_DIR}/crisp-yew-style.css"
mkdir -p "${INSTALL_DIR}/themes/pdm"
printf '/*!UniFi*/\n' > "${INSTALL_DIR}/themes/pdm/theme-unifi.css"
pdm_live="${PDM_THEMES_DIR}/proxmorph-font.css"

( manage_font "Inter" "$fixture" >/dev/null 2>&1 )
check "PDM without theme block: link falls back to </head>" "1" "$(grep -c '<!-- ProxMorph Font -->' "$INDEX_TEMPLATE")"
install_pdm_themes "$(get_themes_source)" >/dev/null 2>&1   # a real PDM host has the theme block
manage_font "Inter" "$fixture" >/dev/null 2>&1
check "PDM: font is accepted" "0" "$?"
check "PDM: setting records the family" "Inter" "$(cat "$FONT_FILE" 2>/dev/null)"
check "PDM: live stylesheet served from proxmorph-themes" "yes" \
      "$(cmp -s "$FONT_CSS" "$pdm_live" && echo yes || echo no)"
check "PDM: font file embedded" "1" "$(grep -c '@font-face { font-family: "Inter";' "$FONT_CSS")"
for sel in 'html:root' 'html .pwt-dialog' 'html h1' 'html .h1' 'html .pwt-font-body-large' 'html .pwt-only-crisp'; do
    check "PDM: targets ${sel}" "yes" "$(grep -qE "(^|, |,\$)${sel}(,|\$| \{)" "$FONT_CSS" && echo yes || echo no)"
done
check "PDM: targets html .pwt-table (multi-line rule)" "1" "$(grep -c '^html .pwt-table,$' "$FONT_CSS")"
check "PDM: selectors inside comments ignored" "0" "$(grep -c 'commented' "$FONT_CSS")"
check "PDM: every selector is html-prefixed" "0" \
      "$(sed -n '/^html/,/{/p' "$FONT_CSS" | tr ',' '\n' | sed 's/ *{.*//; s/^ *//' | grep -v '^$' | grep -vc '^html')"
check "PDM: @font-face of the stock font not targeted" "0" "$(grep -c 'Roboto Flex' "$FONT_CSS")"
check "PDM: monospace and icons not targeted" "0" "$(grep -c 'monospace\|\.fa\b' "$FONT_CSS")"
check "PDM: family wins over !important rules" "1" "$(grep -c 'font-family: "Inter", .* !important;' "$FONT_CSS")"
check "PDM: variable-font settings reset" "1" "$(grep -c 'font-variation-settings: normal !important;' "$FONT_CSS")"
check "PDM: one font marker block" "1" "$(grep -c '<!-- ProxMorph Font -->' "$INDEX_TEMPLATE")"
check "PDM: link points at proxmorph-themes" "1" \
      "$(grep -c '<link rel="stylesheet" type="text/css" href="/proxmorph-themes/proxmorph-font.css?v=[0-9]*">' "$INDEX_TEMPLATE")"
pdm_start="$(grep -n '<!-- ProxMorph PDM Theme -->' "$INDEX_TEMPLATE" | cut -d: -f1)"
pdm_end="$(grep -n '<!-- /ProxMorph PDM Theme -->' "$INDEX_TEMPLATE" | cut -d: -f1)"
font_line="$(grep -n 'proxmorph-font.css' "$INDEX_TEMPLATE" | cut -d: -f1)"
check "PDM: font link sits inside the PDM block" "yes" \
      "$([[ -n "$pdm_start" && "$font_line" -gt "$pdm_start" && "$font_line" -lt "$pdm_end" ]] && echo yes || echo no)"

manage_default_theme unifi >/dev/null 2>&1
check "PDM: rebuilding the theme block keeps one font link" "1" "$(grep -c '<!-- ProxMorph Font -->' "$INDEX_TEMPLATE")"

mv "${PDM_MANAGER_DIR}/desktop-yew-style.css" "${work}/desktop.bak"
mv "${PDM_MANAGER_DIR}/crisp-yew-style.css" "${work}/crisp.bak"
( manage_font "Roboto" >/dev/null 2>&1 ); check "PDM: no Yew selectors found is rejected" "1" "$?"
check "PDM: rejected call keeps the setting" "Inter" "$(cat "$FONT_FILE")"
mv "${work}/desktop.bak" "${PDM_MANAGER_DIR}/desktop-yew-style.css"
mv "${work}/crisp.bak" "${PDM_MANAGER_DIR}/crisp-yew-style.css"

# apt hook after a PDM UI update: stock index.hbs, changed Yew selectors
check "PDM: hook knows the PDM manager dir" "yes" \
      "$(grep -q "^PDM_MANAGER_DIR=\"${PDM_MANAGER_DIR}\"" "$POST_INVOKE_SCRIPT" && echo yes || echo no)"
sed -i "s|^LOG_FILE=.*|LOG_FILE=\"${work}/hook.log\"|" "$POST_INVOKE_SCRIPT"
sed -i '/<!-- ProxMorph PDM Theme -->/,/<!-- \/ProxMorph PDM Theme -->/d' "$INDEX_TEMPLATE"
rm -f "$pdm_live"
printf '.pwt-new-in-update{font-family:"Roboto Flex"}\n' >> "${PDM_MANAGER_DIR}/crisp-yew-style.css"
bash "$POST_INVOKE_SCRIPT" >/dev/null 2>&1
check "PDM hook: theme block back" "1" "$(grep -c '<!-- ProxMorph PDM Theme -->' "$INDEX_TEMPLATE")"
check "PDM hook: font link back" "1" "$(grep -c '<!-- ProxMorph Font -->' "$INDEX_TEMPLATE")"
check "PDM hook: live stylesheet back" "yes" "$(cmp -s "$FONT_CSS" "$pdm_live" && echo yes || echo no)"
check "PDM hook: new Yew selector picked up" "1" "$(grep -c 'html .pwt-new-in-update' "$FONT_CSS")"
check "PDM hook: embedded font kept" "1" "$(grep -c '@font-face { font-family: "Inter";' "$FONT_CSS")"

manage_font none >/dev/null 2>&1
check "PDM: none removes the font link" "0" "$(grep -c 'ProxMorph Font' "$INDEX_TEMPLATE")"
check "PDM: none removes the live stylesheet" "no" "$([[ -f "$pdm_live" ]] && echo yes || echo no)"
check "PDM: none keeps the theme block" "1" "$(grep -c '<!-- ProxMorph PDM Theme -->' "$INDEX_TEMPLATE")"

echo ""
if [[ "$fail" -eq 0 ]]; then echo "ALL PASS"; else echo "FAILURES PRESENT"; fi
exit "$fail"
