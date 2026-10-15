# ESXi Light for ProxMorph

A standalone light theme for the native Proxmox VE interface, inspired by the ESXi 8 Host Client. Slate-blue geometric header, cool gray workspaces, compact striped tables, outlined resource icons, Clarity City typography, clear focus states and coordinated charts. The visual reference is the ESXi 8 Update 3 host summary, VM list and settings dialog. Proxmox branding and native navigation remain intact.

## Files

- `themes/theme-esxi-light.css`: complete theme, with two embedded Clarity City font weights; no imports or network font requests.
- `themes/patches/esxi-light-charts.js`: optional UI adapter, using the native RRD theme callback, marking edit/reset glyph tools for vector styling, and adding a resource-tree toggle. No polling, API calls or metric changes. Inactive with other themes.
- `tools/install-esxi-light.py`: additive installer for an existing PVE Proxmorph installation, with dry-run and exact rollback.
- `preview/`: interactive native-widget fixture with synthetic data, browser checks and version/hash evidence.

## Resource-tree toggle

With ESXi Light active, the menu icon at the left of the application header hides or shows the Datacenter resource tree. The center workspace expands into the freed space. Summary cards and charts use the full available width while the tree is hidden. Showing the tree restores the native responsive column layout. The tree stays alive, preserving its selection and width. The button is keyboard accessible and remains available while the tree is hidden. Visibility resets on page reload. Switching away from ESXi Light restores the tree and removes the control.

The Maximum/Average chart selector has a continuous outer border and divider, including the PVE 9 inline-button variant.

## Coverage

Header and search, resource tree, nested section navigation, panel headers, grids and sorting, selected/hover/disabled states, tabs, toolbars, split buttons, segmented controls, text fields and triggers, form validation, fieldsets, menus and pickers, modal windows, wizards, login, task log viewers, progress bars, health indicators, RRD charts, tooltips, splitters, scrollbars and repository/Markdown surfaces.

The theme deliberately preserves native sizing and positioning, scrolling, terminal ANSI colors, user tag colors, authentication and operation semantics. It does not add dashboard data or move native workflows. The chart adapter changes series colors, preserving names, values, order and native interactions.

## Install on an existing Proxmorph PVE host

From this directory as root, inspect the planned six-file change:

```sh
python3 tools/install-esxi-light.py
```

Apply when ready:

```sh
python3 tools/install-esxi-light.py --apply
```

The installer adds the CSS and chart adapter to the live web directories and Proxmorph's update cache. It registers `esxi-light` in the existing theme map and inserts one script into the existing Proxmorph loader block. It does not restart services, modify sensors, change Proxmorph's version, set a default theme, or install dependencies. Original files are saved below `/root/.proxmorph-esxi-backup/` and the precise directory is printed.

Hard-refresh the browser, then select **username → Color Theme → ESXi Light**. Proxmox's own theme selector reloads the interface. Each browser keeps its selection.

Proxmorph's existing APT hook can restore the cached theme after a Proxmox package update. A future full Proxmorph upgrade should be checked for retention of custom themes; keep this source package available.

## Rollback

Switch to another theme in the native selector first. To remove the installation and restore the exact original files:

```sh
python3 tools/install-esxi-light.py --rollback /root/.proxmorph-esxi-backup/TIMESTAMP
```

Use the actual backup directory printed by the installer. Rollback refuses to overwrite files changed by another operation since installation. This avoids restoring stale UI files after a package upgrade. In that situation, select a stock theme and reconcile the theme registration against the updated files instead.

## Validation

Primary fixture uses the host's public assets: **PVE 8.4.21, proxmox-widget-toolkit 4.3.18, Ext JS 7.0.0-7**, alongside Proxmorph 2.8.4 at `b81bbde1698160f881ff85e92b2e2264ab57fc52`. Exact asset hashes are in `preview/host-assets.json`.

The fixture renders actual Ext JS controls and actual Proxmox RRD charts and information widgets. Its inventory, dialogs and records are synthetic; it is not an authenticated live-host regression suite. Public assets under `preview/live/` are local and ignored by Git, not distributed in the theme ZIP.

Checks cover charts and palette restoration, nested navigation, grids, floating dropdowns, wizard validation and tab bounds, task-log scrolling, login, native warning/critical thresholds, keyboard focus, reduced motion and JavaScript errors. Sixteen browser check groups, chart activation/restoration, and enabled/disabled vector-tool behavior pass. Screenshots are in `preview/evidence/`. Chrome 155 emits a native Ext JS unload-permissions warning in the connected browser; the interaction suite has no JavaScript page exceptions. This warning is in the unmodified vendor runtime.

Desktop-first, best at 1366px or wider. At 1024px the native multi-column summary becomes cramped; this theme does not redesign Proxmox for phones. PBS shares many widgets but is not validated. PDM uses a different frontend and is not supported by this stylesheet.

The theme has also been deployed on PVE 9.2.21. The automated fixture below uses PVE 8.4 assets; this is not a claim of complete automated PVE 9 coverage.

Before running the preview, copy these public UI assets from a PVE host you administer into `preview/live/`, retaining their absolute-path directory structure:

- `/usr/share/javascript/extjs/`
- `/usr/share/javascript/proxmox-widget-toolkit/`
- `/usr/share/fonts-font-awesome/`
- `/usr/share/pve-manager/css/`
- `/usr/share/pve-manager/images/`

For example, from the checkout (replace `root@PVE_HOST` with your host):

```sh
mkdir -p preview/live
ssh root@PVE_HOST 'tar -C / -cf - usr/share/javascript/extjs usr/share/javascript/proxmox-widget-toolkit usr/share/fonts-font-awesome usr/share/pve-manager/css usr/share/pve-manager/images' | tar -C preview/live -xf -
```

Only public static UI files are needed. These vendor files stay ignored and are not part of this contribution. Install Python Playwright and its Chromium browser locally, then serve the checkout:

```sh
python3 -m http.server 8769 --bind 127.0.0.1
# Open http://127.0.0.1:8769/preview/
```

With Python Playwright available:

```sh
CHROMIUM_PATH=/path/to/chromium python3 preview/check_ui.py
python3 preview/check_chart.py
python3 preview/check_tool_icons.py
python3 preview/check_chart_toggle.py
python3 preview/check_sidebar.py
python3 preview/check_summary_columns.py
python3 test/esxi_install.test.py
```

The Preview menu switches between the theme and native Proxmox, and opens login/task-viewer examples. No operations in this fixture contact or change a host.

## Font provenance

Clarity City is the VMware open-source derivative of Metropolis. Regular and Semibold WOFF2 files were obtained from `vmware-archive/clarity-city` at revision `f2ecc978bb5048cf8c3508ea61ec66ca2014ee19`. Original files, full license, notices and hashes are in `third_party/clarity-city/`. The stylesheet embeds the fonts and license so the existing six-file install and update hook remain sufficient. No VMware application code or branding assets are included in this theme.
