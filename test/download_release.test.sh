#!/usr/bin/env bash
# Regression test for download_release() in install.sh (`install.sh update`).
#
# The release cache ${INSTALL_DIR} holds post-update.sh, which the apt hook runs
# after every Proxmox package update. If extraction fails after the cache was
# already wiped, the host keeps a broken cache and the hook silently does nothing.
#
# Runnable anywhere with bash + coreutils + curl: `bash test/download_release.test.sh`.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../install.sh
source "${HERE}/../install.sh" >/dev/null 2>&1   # guard skips main() when sourced
set +e                                            # install.sh sets -e; tests manage rc themselves

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
ver="9.9.9"
arch="proxmorph-${ver}.tar.gz"
INSTALL_DIR="${work}/opt"
mkdir -p "${work}/rel" "${work}/payload/themes"

# curl on Git for Windows wants file:///C:/..., on Linux file:///tmp/...
rel="$(cygpath -m "${work}/rel" 2>/dev/null || echo "${work}/rel")"
[[ "$rel" == /* ]] && export PROXMORPH_RELEASE_BASE="file://${rel}" || export PROXMORPH_RELEASE_BASE="file:///${rel}"

seed_cache() {
    rm -rf "$INSTALL_DIR"; mkdir -p "${INSTALL_DIR}/themes"
    echo "old" > "${INSTALL_DIR}/post-update.sh"
    printf '/*!Stale*/\n' > "${INSTALL_DIR}/themes/theme-stale.css"
    echo "enabled" > "${INSTALL_DIR}/.sensors-enabled"
    echo "1.0.0" > "${INSTALL_DIR}/.version"
}
publish() { ( cd "${work}/rel" && sha256sum "$arch" > SHA256SUMS ); }

# --- 1. Archive passes the checksum but cannot be extracted -> keep the cache ----
seed_cache
echo "not a tarball" > "${work}/rel/${arch}"; publish
( download_release "$ver" ) >/dev/null 2>&1; rc=$?
check "unextractable release fails" "1" "$rc"
check "cache keeps post-update.sh after failed extract" "old" "$(cat "${INSTALL_DIR}/post-update.sh" 2>/dev/null)"
check "version not bumped after failed extract" "1.0.0" "$(cat "${INSTALL_DIR}/.version" 2>/dev/null)"

# --- 2. Good release replaces the cache, keeps dotfile settings ------------------
seed_cache
echo "new" > "${work}/payload/post-update.sh"
printf '/*!Fresh*/\n' > "${work}/payload/themes/theme-fresh.css"
tar -czf "${work}/rel/${arch}" -C "${work}/payload" .; publish
( download_release "$ver" ) >/dev/null 2>&1; rc=$?
check "good release installs" "0" "$rc"
check "post-update.sh replaced" "new" "$(cat "${INSTALL_DIR}/post-update.sh" 2>/dev/null)"
check "stale theme removed" "no" "$([[ -f "${INSTALL_DIR}/themes/theme-stale.css" ]] && echo yes || echo no)"
check "fresh theme present" "yes" "$([[ -f "${INSTALL_DIR}/themes/theme-fresh.css" ]] && echo yes || echo no)"
check "sensor setting kept" "enabled" "$(cat "${INSTALL_DIR}/.sensors-enabled" 2>/dev/null)"
check "version recorded" "$ver" "$(cat "${INSTALL_DIR}/.version" 2>/dev/null)"

echo ""
if [[ "$fail" -eq 0 ]]; then echo "ALL PASS"; else echo "FAILURES PRESENT"; fi
exit "$fail"
