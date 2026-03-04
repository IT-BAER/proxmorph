# ProxMorph Theme Component Inventory

> Generated from analysis of all four theme files. Use as reference when building new themes.

## File Summary

| Theme | File | Lines | Version Format | Version | Tier |
|-------|------|-------|----------------|---------|------|
| UniFi | `themes/theme-unifi.css` | 3,890 | `Version: X.XX` in header comment | 5.93 | 3 — Comprehensive |
| Catppuccin Mocha | `themes/theme-catppuccin-mocha.css` | 1,953 | `Version: X.X.X` in header comment | 1.2.1 | 2 — Production |
| GitHub Dark | `themes/theme-github-dark.css` | 2,215 | `Version: X.X.XX` in header + inline changelog | 2.2.23 | 2 — Production |
| Blue Slate | `themes/theme-blue-slate.css` | 877 | None (no version in header) | — | 1 — Minimal |

---

## Component Categories

### 1. Root CSS Variables (`:root`)

| Variable Namespace | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|--------------------|-------|------------------|-------------|------------|
| `--pm-*` (semantic: bg, text, accent, border, radius, success/warning/error) | ✅ | ✅ | ❌ | ✅ |
| `--pwt-*` (Proxmox Widget Toolkit: panel-background, text-color, chart/gauge colors) | ✅ | ✅ (+ `chart-grid-stroke`) | ✅ | ✅ |
| Theme-specific tokens | `--ubnt-*` | `--ctp-*` (full Catppuccin palette) | `--gh-*` (Primer palette) | None |
| Radius tokens | `--pm-radius-sm/md/lg` | `--pm-radius-sm/md/lg` | `--gh-radius-sm/md/lg` | `--pm-radius-sm/md/lg` |
| Extended semantic vars (hover, focus, text-bright, text-disabled, accent-hover) | ✅ (`--pm-hover-subtle`, `--pm-hover-medium`, `--pm-focus-ring-color`, `--pm-text-bright`, `--pm-text-disabled`, `--pm-accent-hover`) | Partial (`--ctp-hover-overlay`, `--ctp-select-overlay`, `--ctp-accent-muted`, `--ctp-accent-subtle`, `--ctp-on-accent`) | ❌ | ❌ |

**Required `--pwt-*` variables (all themes MUST define):**
- `--pwt-panel-background`
- `--pwt-text-color`
- `--pwt-chart-primary`
- `--pwt-gauge-default`
- `--pwt-gauge-back`
- `--pwt-gauge-warn`
- `--pwt-gauge-crit`

### 2. Base / Global

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| `border-box` global radius reset | ✅ | ✅ (ported) | ✅ (ported) | ❌ |
| Grid/table/legend/tool radius reset to 0 | ✅ | ✅ | ✅ | ❌ |
| Form element radius reset | ✅ | ✅ | ✅ | ❌ |
| Layout container radius reset (`.x-box-inner`, `.x-panel-bodyWrap`, etc.) | ✅ | ✅ | ✅ | ❌ |
| Window inner element radius reset + selective re-application | ✅ | ✅ | ✅ | ❌ |
| Chart canvas radius reset to 0 | ✅ | ✅ | ✅ | ❌ |
| Legend marker radius (`border-radius: 50%`) | ✅ | ✅ | ✅ | ❌ |
| Body/html background color | ✅ | ✅ | ✅ | ✅ |
| Global smooth scrolling (`scroll-behavior`) | ✅ | ❌ | ❌ | ❌ |
| `color-scheme: dark` | ✅ | ✅ | ❌ | ❌ |

### 3. Icons & Status Indicators

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| General icon inversion (`filter: invert`) | ✅ | ✅ | ✅ | ✅ |
| VM/CT type icons (`.fa-desktop`, `.fa-cube`) | ✅ | ✅ | ✅ | ✅ |
| Hardware icons (processor/memory/storage SVG pseudo-elements) | ✅ (v5.37) | ❌ (filter:invert only) | ❌ | ❌ |
| Summary panel icons (SVG pseudo-elements) | ✅ (v5.38) | ❌ | ❌ | ❌ |
| FontAwesome resource grid icons | ✅ | ❌ | ❌ | ❌ |
| Status icons: running (green dot `\f111`) | ✅ | ✅ (Catppuccin Green) | ✅ (green default) | ✅ |
| Status icons: stopped/paused/offline | ✅ | ✅ | ✅ | ✅ |
| Status icons: error states | ✅ | ✅ (Catppuccin Red) | ✅ | ❌ |
| Status icons: paused/suspended | ✅ | ✅ (Catppuccin Peach) | ✅ | ❌ |
| Status icons: pending/warning/io-error | ✅ | ✅ (Catppuccin Yellow) | ✅ | ❌ |
| Status icons: HA maintenance | ✅ | ✅ (Catppuccin Sky) | ✅ | ❌ |
| Lock icons (migrate/backup/suspend override running dot) | ✅ (v5.90) | ✅ (Overlay2) | ❌ | ❌ |
| LXC/QEMU type indicators | ✅ | ✅ | ✅ | ❌ |
| Tree expander arrows (FontAwesome chevrons + rotation) | ✅ (v5.6) | ✅ (brightness filter) | ✅ | ✅ |
| Treelist item icons | ✅ | ✅ | ✅ | ✅ |
| Tool icons (FontAwesome replacements: close, minus, collapse, gear, refresh, etc.) | ✅ (v5.86) | ✅ (ported from UniFi) | ✅ (ported from UniFi) | ❌ |
| Generic inline FontAwesome tool icons | ✅ (v5.86) | ✅ (ported from UniFi) | ✅ (ported from UniFi) | ❌ |
| Icon overlay color management (`.x-tree-icon-custom::after`) | ✅ | ✅ (with text-shadow) | ✅ | ❌ |
| IP view button positioning | ✅ (v5.88) | ❌ | ❌ | ❌ |

### 4. Navigation / Tree List

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Sidebar tree (`.x-treelist-*`) background | ✅ | ✅ | ✅ | ✅ |
| Pseudo-element (`::before`) hover/selected states | ✅ (v5.9) | ✅ (`::before` on `.x-treelist-row`) | ✅ (v2.2.4) | ✅ (with `scale` animation) |
| Selected = colored background + on-accent text/icon | ✅ (blue bg, white text) | ✅ (Mauve bg, Base text) | ✅ (GitHub green) | ✅ (accent) |
| Parent/child state management (`:has()`) | ✅ | ❌ | ❌ | ❌ |
| Expand/collapse animation (`max-height` transition) | ✅ (v5.7) | ❌ | ❌ | ❌ |
| Resource tree (grid-based, `.x-tree-panel`) | ✅ (extensive) | ✅ (row spacing, border removal) | ❌ | ✅ (basic) |
| Tree item spacing/padding | ✅ | ✅ | ✅ | ✅ |
| Tree item text margin (icon overlap fix) | ✅ | ✅ (`margin-left: 28px`) | ❌ | ❌ |
| Cursor: pointer on tree items | ✅ | ❌ | ❌ | ❌ |
| Font weight: datacenter/node items bold | ✅ | ❌ | ❌ | ❌ |
| Horizontal scrollbar fix (`overflow-x: hidden`) | ✅ (v5.84) | ❌ | ❌ | ❌ |
| PVE nav container styling (`.x-treelist-pve-nav`) | ✅ | ✅ | ✅ | ❌ |
| Nav tree right border (`.pve-toolbar-bg`) | ✅ | ✅ (`border-right`) | ✅ (v2.2.15/v2.2.16) | ❌ |
| Treelist radius overrides (consistent `sm` radius) | ✅ (v5.9, v5.54) | ✅ (`--pm-radius-sm` throughout) | ❌ | ❌ |

### 5. Tabs

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Tab bar background | ✅ | ✅ | ✅ | ✅ |
| Active tab style | Filled (blue) | Underline (`::after` Mauve 2px) | Underline (`::after` coral `#f47067`) | Accent line |
| Tab hover | ✅ | ✅ | ✅ | ✅ |
| Tab focus (outline/box-shadow removal) | ✅ (v5.46) | ✅ (extensive removal) | ✅ (v2.2.21+) | ❌ |
| Tab disabled | ✅ | ✅ (Overlay0 color) | ✅ | ❌ |
| Tab inner text colors | ✅ | ✅ | ✅ | ✅ |
| Compact tab bar for Tasks panel | ✅ (v5.43, 26px) | ❌ | ❌ | ❌ |
| Tab `overflow: visible` fixes | ❌ | ✅ (bar inner/target) | ✅ (v2.2.21) | ❌ |
| Tabpanel child radius | ❌ | ✅ (bottom radius) | ❌ | ❌ |

### 6. Buttons

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Primary buttons (colored fill) | ✅ (blue `#006EFF`) | ✅ (Mauve `#cba6f7`) | ✅ (GitHub green `#238636`) | ✅ (accent) |
| Toolbar buttons (transparent, bordered) | ✅ | ✅ (Surface0 bg, Surface1 border) | ✅ | ✅ |
| Button height consistency (28px) | ✅ | ✅ (ported from UniFi) | ❌ | ❌ |
| Button icon flex centering (`.x-btn-wrap`/`.x-btn-inner`) | ✅ | ✅ (ported from UniFi, Issue #17) | ❌ | ❌ |
| Icon-only buttons (hide `&nbsp;` inner) | ✅ | ✅ (ported from UniFi) | ❌ | ❌ |
| Segmented buttons (`.x-segmented-button`) | ✅ (v5.1) | ✅ | ✅ | ❌ |
| Disabled button state | ✅ | ✅ (opacity: 0.4) | ✅ | ✅ |
| Hover glow effect (`box-shadow`) | ✅ | ✅ (`accent-subtle` shadow) | ❌ | ✅ (transition) |
| Inline buttons (`.proxmox-inline-button`) | ✅ | ✅ (with pressed on-accent text) | ✅ | ❌ |
| Tag checkmark button (`.fa-check`) | ✅ (v5.29) | ❌ | ✅ | ❌ |
| Bulk action dropdown fix | ✅ (v5.42) | ❌ | ❌ | ❌ |
| Pressed segmented text color | ✅ (v5.25, white) | ✅ (on-accent/Base, v1.2.0) | ❌ | ❌ |
| `display: flex` with `:not([style*="display"])` guard | ✅ (v5.28) | ❌ | ❌ | ❌ |

### 7. Forms & Inputs

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Text input (`.x-form-text`) background/border | ✅ | ✅ | ✅ | ✅ |
| Focus ring color | ✅ | ✅ (Mauve ring) | ✅ | ✅ |
| Dropdown trigger (`.x-form-trigger`) | ✅ | ✅ | ✅ | ✅ |
| Custom checkboxes (SVG `::before` replacement) | ✅ | ✅ (Mauve bg, SVG checkmark) | ✅ | ❌ |
| Custom radio buttons | ✅ | ✅ | ✅ | ❌ |
| Spinner arrows | ✅ | ❌ | ❌ | ❌ |
| Fieldset legends (`<legend>`, `.x-fieldset-header-text`) | ✅ | ✅ | ✅ | ❌ |
| Dialog fixed-width text wrapping fix (`white-space: nowrap`) | ✅ (v5.24) | ❌ | ❌ | ❌ |
| Invalid field indicator | ✅ | ✅ | ✅ | ❌ |
| Bound list dropdown (`.x-boundlist-list-ct`) | ✅ | ✅ | ✅ | ✅ |
| Display/text field (read-only) | ✅ | ✅ | ✅ | ❌ |
| Tag editor (`.proxmox-tags-full`, `.proxmox-tag-dark/light`) | ✅ (v5.29+) | ✅ | ✅ | ❌ |

### 8. Grids & Tables

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Row hover + selected backgrounds | ✅ (`rgba` overlays) | ✅ (`--ctp-hover-overlay`, `--ctp-select-overlay`) | ✅ | ✅ |
| Column header styling | ✅ | ✅ | ✅ | ✅ |
| Column header hover/active/sort states | ✅ | ✅ | ✅ | ❌ |
| Grid cell borders | ✅ | ✅ | ✅ | ✅ |
| Alternating row stripes | ✅ | ✅ | ❌ | ❌ |
| Empty grid message (`.x-grid-empty`) | ✅ | ✅ | ✅ | ❌ |
| Float pickers (`.x-datepicker`) | ✅ | ✅ | ✅ | ❌ |
| Cell vertical alignment (`vertical-align: middle`) | ✅ (v5.53) | ❌ | ❌ | ❌ |
| Parent node focus removal (`outline: none` on `.x-grid-item`) | ✅ (v5.16) | ✅ | ❌ | ❌ |
| Summary row (`.x-grid-row-summary`) | ✅ | ✅ | ✅ | ❌ |
| Drag proxy (`.x-dd-drag-proxy`) | ✅ | ✅ | ❌ | ❌ |
| Grid group headers / group titles | ✅ | ✅ | ✅ | ❌ |
| Task compact rows (`.x-grid-row .x-grid-cell-inner` height) | ✅ (v5.43) | ❌ | ❌ | ❌ |
| Keyboard focus (`.x-grid-item-focused` outline) | ✅ | ✅ | ✅ | ❌ |

### 9. Menus & Context Menus

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Menu background | ✅ | ✅ (Crust) | ✅ | ✅ |
| Menu item hover/active | ✅ | ✅ | ✅ | ✅ |
| Menu separator (`.x-menu-item-separator`) | ✅ | ✅ | ✅ | ✅ |
| Menu icon column | ✅ | ✅ (flexbox layout with icon reordering) | ✅ | ❌ |
| Menu arrow (`.x-menu-item-arrow`) | ❌ | ✅ (`order: 2` for submenu arrows) | ❌ | ❌ |
| Slide/fade animation | ✅ | ❌ | ❌ | ❌ |
| Context menu radius | ✅ | ✅ | ✅ | ❌ |
| Disabled menu item | ✅ | ✅ | ✅ | ❌ |

### 10. Panels & Cards

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Panel header (`.x-panel-header`) | ✅ | ✅ | ✅ | ✅ |
| Panel body (`.x-panel-body`) background | ✅ | ✅ | ✅ | ✅ |
| Guest agent status border | ✅ (v5.31) | ✅ | ✅ | ❌ |
| Summary card icons (`.x-panel-header .x-tool-img`) brightness | ✅ | ✅ (brightness filter) | ❌ | ❌ |
| RRD chart view panels (`.proxmox-rrdchart-panel`) | ✅ | ✅ | ✅ | ❌ |
| Panel inner overflow fixes | ✅ (extensive) | ✅ | ✅ | ❌ |
| Info panel (`.pmx-info-column`) | ✅ | ✅ | ❌ | ❌ |

### 11. Progress Bars

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Progress bar fill (`.x-progress-bar`) | ✅ (blue) | ✅ (Mauve) | ✅ (GitHub green) | ✅ (accent gradient) |
| Progress text color | ✅ | ✅ (on-accent text, v1.2.0) | ✅ | ✅ |
| Warning threshold (`.warn`) | ✅ | ✅ (Catppuccin Yellow) | ✅ | ✅ |
| Critical threshold (`.critical`) | ✅ | ✅ (Catppuccin Red) | ✅ | ✅ |
| Container overflow fix (`overflow: visible` for radius) | ✅ | ❌ | ✅ | ❌ |

### 12. Splitters & Resizers

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Vertical splitter (`.x-splitter`) | ✅ | ✅ | ✅ | ✅ |
| Horizontal splitter | ✅ | ✅ | ✅ | ❌ |
| Splitter drag bar indicator | ✅ | ✅ | ❌ | ❌ |
| Splitter keyboard focus ring | ✅ | ✅ | ❌ | ❌ |
| Nav splitter border synchronization | ✅ (v5.80) | ✅ | ❌ | ❌ |
| Layout split bottom opacity | ❌ | ✅ (unique) | ❌ | ❌ |

### 13. Tooltips & Tips

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Tooltip background (`.x-tip`) | ✅ | ✅ (Mantle bg) | ✅ | ✅ |
| Tooltip text color | ✅ | ✅ | ✅ | ✅ |
| Tooltip border / box-shadow | ✅ | ✅ | ✅ | ❌ |
| Invalid tooltip (`.x-tip-form-invalid`) | ✅ | ✅ | ✅ | ❌ |
| Tool tip fade transition | ✅ | ✅ (`transition: opacity 0.15s`) | ❌ | ❌ |

### 14. Toolbars

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Toolbar background (`.x-toolbar`) | ✅ | ✅ | ✅ | ✅ |
| Toolbar border-bottom | ✅ | ✅ | ✅ | ✅ |
| Toolbar separator (`.x-toolbar-separator`) | ✅ | ✅ | ✅ | ❌ |
| Toolbar text items (`.x-toolbar-text`) | ✅ | ✅ | ✅ | ❌ |
| Toolbar scroll arrows (overflow buttons) | ✅ | ❌ | ❌ | ❌ |
| Vertical toolbar scroll (`.x-box-scroller-body-vertical`) | ✅ | ❌ | ❌ | ❌ |

### 15. Windows & Dialogs

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Window header (`.x-window-header`) | ✅ | ✅ (Crust bg) | ✅ | ✅ |
| Window body background | ✅ | ✅ | ✅ | ✅ |
| Window border/shadow | ✅ | ✅ | ✅ | ❌ |
| Dialog message box width fix | ✅ (v5.24) | ❌ | ✅ | ❌ |
| Wizard multi-step panels | ✅ (v5.40) | ❌ | ✅ | ❌ |
| Login dialog | ✅ (v5.19–5.85) | ❌ | ✅ (v2.2.11) | ❌ |
| Window open/close animation (`@keyframes`) | ✅ (`fadeSlideIn`/`fadeSlideOut`) | ❌ | ❌ | ❌ |
| Content area padding consistency | ✅ | ✅ | ✅ | ❌ |
| Window width consistency (`.x-window-body .x-panel`) | ✅ | ✅ | ❌ | ❌ |

### 16. Masks & Loading Overlays

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Mask background overlay (`.x-mask`) | ✅ | ✅ (`backdrop-filter: blur`) | ✅ | ✅ |
| Mask text/spinner color | ✅ | ✅ (explicit text color, v1.2.0) | ✅ | ❌ |
| Mask message box (`.x-mask-msg`) | ✅ | ✅ | ✅ | ❌ |
| Fade transition (opacity animation) | ✅ | ❌ | ❌ | ❌ |

### 17. Scrollbars

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| WebKit scrollbar (`::-webkit-scrollbar`) | ✅ (8px) | ✅ (8px) | ✅ | ✅ |
| Firefox scrollbar (`scrollbar-width`, `scrollbar-color`) | ✅ | ✅ (`scrollbar-width: thin`) | ❌ | ❌ |
| Scrollbar hover state | ✅ | ✅ | ❌ | ❌ |
| Scrollbar radius | ✅ | ✅ | ✅ | ❌ |

### 18. Proxmox-Specific Components

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Tags (`.proxmox-tags-full`, `.proxmox-tag-dark/light`) | ✅ (v5.29+) | ✅ | ✅ | ❌ |
| Markdown viewer (`.pmx-doc-section`, `.pmx-doc-rendered`) | ✅ | ✅ (Rosewater `<code>` accent) | ✅ | ❌ |
| Date picker (`.x-datepicker`) | ✅ | ✅ | ✅ | ❌ |
| Links (`a` elements) | ✅ | ✅ (Catppuccin Blue) | ✅ | ✅ |
| Status color overrides (running/stopped/warning) | ✅ | ✅ (Catppuccin Teal for status) | ✅ | ❌ |
| Usage/resource bars | ✅ | ✅ | ✅ | ❌ |
| APT repository/package styling | ✅ | ❌ | ✅ | ❌ |
| OSD (Ceph) status panels | ✅ | ❌ | ❌ | ❌ |
| VM migration dialog | ✅ | ❌ | ❌ | ❌ |
| Node summary statistics cards | ✅ (v5.38) | ✅ | ❌ | ❌ |
| `pmx-hint` text wrapping fix | ✅ (v5.24) | ❌ | ❌ | ❌ |

### 19. Console / Terminal

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| xterm.js background | ✅ | ❌ | ✅ (v2.2.13) | ❌ |
| Console toolbar | ✅ | ❌ | ✅ | ❌ |
| noVNC container | ✅ | ❌ | ✅ | ❌ |
| Console fullscreen fixes | ✅ | ❌ | ❌ | ❌ |

### 20. Charts & Gauges

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| `--pwt-*` chart variables | ✅ | ✅ | ✅ | ✅ |
| Chart text/label color | ✅ | ❌ | ✅ | ❌ |
| Chart panel backgrounds | ✅ | ❌ | ✅ | ❌ |
| Canvas element styling | ✅ | ✅ (radius reset) | ✅ | ❌ |
| Legend styling | ✅ | ✅ (marker border-radius 50%) | ✅ | ❌ |
| JavaScript chart patching (separate `.js` file) | ✅ (`unifi-charts.js`) | ❌ | ❌ | ❌ |

### 21. Transitions & Animations

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Grid row transitions | ✅ | ✅ | ✅ | ❌ |
| Menu fade/slide transitions | ✅ (slide) | ✅ (opacity transition) | ❌ | ❌ |
| Boundlist transitions | ✅ | ✅ | ✅ | ❌ |
| Tab transitions | ✅ | ✅ | ✅ | ❌ |
| Splitter hover transitions | ✅ | ✅ | ❌ | ❌ |
| Tooltip fade | ✅ | ✅ | ❌ | ❌ |
| Window animations (`@keyframes fadeSlideIn/Out`) | ✅ | ❌ | ❌ | ❌ |
| Button glow/hover transitions | ✅ | ✅ | ❌ | ✅ |
| Progress bar transitions | ✅ | ✅ | ✅ | ❌ |
| Scrollbar thumb transitions | ✅ | ✅ | ❌ | ❌ |
| Tool icon transitions | ✅ | ✅ (brightness) | ❌ | ❌ |

### 22. Selection & Miscellaneous

| Component | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|-----------|-------|------------------|-------------|------------|
| Text selection (`::selection`) | ✅ | ✅ (Overlay2 @ 30%) | ✅ | ❌ |
| Resource tree separator removal | ✅ | ✅ | ❌ | ❌ |
| General focus outline removal | ✅ | ✅ | ✅ | ❌ |
| Breadcrumb styling | ✅ | ❌ | ❌ | ❌ |
| Node info subscription alerts | ✅ (v5.46) | ❌ | ❌ | ❌ |

---

## Coverage Summary

| Category | UniFi | Catppuccin Mocha | GitHub Dark | Blue Slate |
|----------|-------|------------------|-------------|------------|
| 1. CSS Variables | ✅ Full | ✅ Full | Partial | ✅ Full |
| 2. Base / Global | ✅ Full | ✅ Mostly | ✅ Mostly | Partial |
| 3. Icons | ✅ Full | Moderate | Moderate | Basic |
| 4. Navigation | ✅ Full | Moderate | Moderate | Basic |
| 5. Tabs | ✅ Full | ✅ Good | ✅ Good | Basic |
| 6. Buttons | ✅ Full | ✅ Good | ✅ Good | Partial |
| 7. Forms | ✅ Full | ✅ Good | ✅ Good | Basic |
| 8. Grids | ✅ Full | ✅ Good | ✅ Good | Basic |
| 9. Menus | ✅ Most | ✅ Good | ✅ Good | Basic |
| 10. Panels | ✅ Full | ✅ Good | Moderate | Basic |
| 11. Progress Bars | ✅ Full | ✅ Mostly | ✅ Full | ✅ Mostly |
| 12. Splitters | ✅ Full | ✅ Full | Partial | Basic |
| 13. Tooltips | ✅ Full | ✅ Full | ✅ Mostly | Basic |
| 14. Toolbars | ✅ Full | ✅ Mostly | ✅ Mostly | Basic |
| 15. Windows | ✅ Full | Moderate | ✅ Good | Basic |
| 16. Masks | ✅ Full | ✅ Mostly | ✅ Good | Basic |
| 17. Scrollbars | ✅ Full | ✅ Full | Partial | Basic |
| 18. Proxmox-Specific | ✅ Full | ✅ Good | ✅ Good | Basic |
| 19. Console | ✅ Full | ❌ None | Moderate | ❌ None |
| 20. Charts | ✅ Full (CSS+JS) | Partial | ✅ Good | Basic |
| 21. Transitions | ✅ Full | ✅ Good | Partial | Minimal |
| 22. Selection/Misc | ✅ Full | ✅ Good | Partial | ❌ None |

---

## Tier Recommendations

### Tier 1 — Minimal (Blue Slate baseline)
Covers: CSS variables, body BG, basic icon inversion, sidebar tree, tab bar, buttons, inputs, grid rows, menus, panel headers, progress bars, splitters, tooltips, toolbars, window headers, masks, scrollbars.

### Tier 2 — Production (Catppuccin Mocha / GitHub Dark reference)
Adds: Border radius architecture, custom checkbox/radio SVGs, pseudo-element nav states, tab focus fixes, segmented buttons, grid hover/selected overlays, empty grid styling, menu icon layout, panel overflow fixes, progress thresholds, splitter indicators, Firefox scrollbars, Proxmox-specific components (tags, markdown, date picker, links, status, usage bars), transitions throughout, text selection highlighting.

**Catppuccin Mocha** is the recommended Tier 2 reference — it implements the `--pm-*` semantic variable system and border radius architecture from UniFi while maintaining a cleaner, more maintainable codebase (~1,950 lines vs UniFi's ~3,890).

### Tier 3 — Comprehensive (UniFi reference)
Adds: SVG hardware/summary icons, FA resource grid icons, parent/child `:has()` nav states, expand/collapse animations, compact task tabs, button height consistency, icon-only buttons, spinner arrows, dialog width fixes, cell vertical alignment, task compact rows, toolbar scroll arrows, wizard panels, login dialog, window animations, mask fade transitions, console/xterm.js, JS chart patching, keyframe animations, breadcrumbs, APT/OSD styling, IP view button positioning.
