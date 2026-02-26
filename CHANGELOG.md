# Changelog

All notable changes to ProxMorph will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **All Themes (19 files)** — Ported FontAwesome tool icon replacements from UniFi v5.86:
  - Replaced sprite-based ExtJS tool icons (close, gear, refresh, collapse/expand, maximize/restore, zoom) with crisp FontAwesome glyphs
  - Added hover, disabled, and inline FontAwesome states for consistent tool icon theming

### Fixed
- **All Themes (19 files)** — Issue [#23](https://github.com/IT-BAER/proxmorph/issues/23):
  - Fixed summary panel data values (Status, CPU, Memory, etc.) being invisible on node/VM/storage summary pages — removed `max-width: calc(50% - 10px)` constraint on `.x-panel.x-column` that clipped ExtJS-calculated inner widths, restoring native stacked vertical layout
- **UniFi Theme** (v5.94):
  - Fixed PBS summary panel clipping after "Boot Mode" row — reduced widget padding (5px→3px) and added PBS-specific body padding rule
  - Fixed CPU/RAM icons not loading on PBS — changed absolute paths (`/pve2/`, `/pwt/`) to relative paths (`../images/`) for PVE+PBS compatibility
  - Fixed grid status icons (`.good`/`.warning`/`.critical`) showing grey instead of green/yellow/red — added specificity-matched color overrides after the broad `.fa` color rule
  - Increased navigation tree icon-to-label gap (margin-left 20px→28px) for better readability

## [2.4.0] - 2026-02-25

### Added
- **7 New Theme Collections** — contributed by [@W0CHP](https://github.com/W0CHP) ([PR #12](https://github.com/IT-BAER/proxmorph/pull/12)):
  - Gruvbox Dark — warm retro groove colors with yellow accent
  - Gruvbox Light — light variant of Gruvbox palette
  - Nord Dark — arctic, bluish-cold palette from Nord
  - Nord Light — light variant of Nord palette
  - Solarized Dark — dark variant of precision colors for machines
  - Solarized Light — light variant of Solarized palette
  - Tokyo Night — dark theme inspired by Tokyo's neon lights

### Changed
- **Installer** (`install.sh`) — contributed by [@W0CHP](https://github.com/W0CHP):
  - Now prioritizes local script directory over `/opt/proxmorph` cache for development workflows
  - Syncs themes and JS patches to `/opt/proxmorph/` cache when installing from local source
  - Improved theme discovery for dynamic registration

### Fixed
- **Light Themes** (Nord/Gruvbox/Solarized Light):
  - Removed dark mode icon inversions (`filter: invert(90%)`) that caused icons to appear washed out
  - Removed logo inversion (`filter: invert(1) hue-rotate(180deg)`) for proper display on light backgrounds
  - Removed brightness filters designed for dark backgrounds
- **Variable Prefixes** (all new themes):
  - Replaced inherited `--drac-*` prefix with theme-specific prefixes (`--grv-*`, `--nord-*`, `--sol-*`, `--tn-*`)

## [2.3.0] - 2026-02-21

### Added
- **Catppuccin Theme Collection** (5 themes):
  - Catppuccin Mocha — darkest flavor with mauve accent
  - Catppuccin Macchiato — mid-dark flavor with blue-tinted base
  - Catppuccin Frappé — lightest dark flavor with muted blue base
  - Catppuccin Latte — official light variant with purple accent
  - Catppuccin Mocha Teal — Mocha palette with teal accent
- **Dracula Theme Collection** (6 themes):
  - Dracula — classic dark with purple accent
  - Dracula Pink — pink accent variant
  - Dracula Cyan — cyan accent variant
  - Dracula Midnight — near-black backgrounds from Dracula UI spec
  - Dracula Green — forest-tinted backgrounds with green accent
  - Dracula Orange — warm-tinted backgrounds with orange accent
- **Variant Generator** (`generate-variants.ps1`) for creating theme variants from templates
- Screenshots for all 14 themes in README gallery

### Fixed
- **Chart Layout** (all new themes + GitHub Dark):
  - Fixed RRD chart panels stacking in single column instead of 2-column grid
  - Root cause: `padding: 0 !important` on `.x-panel` overrode ExtJS inline `padding: 5px`, triggering a scrollbar-induced sub-pixel overflow feedback loop (2×790px panels > 1579.6px container)
  - Solution: Added `.x-panel.x-column` rule with `max-width: calc(50% - 10px)`, `margin: 5px`, and `padding: 5px` to prevent overflow
  - Removed `:not(.x-draw-container)` from column border selector — chart panels (proxmoxRRDChart) have the `.x-draw-container` class and were incorrectly excluded from card styling

## [2.2.5] - 2026-01-26

### Fixed
- **UniFi Theme (v5.93)**:
  - Fixed task viewer/log viewer issues: content not visible on open, scrollbar not clickable, no auto-scroll to bottom
  - Root cause: `overflow: visible !important` rule on `.x-window .x-panel-body` completely broke native ExtJS scroll handling
  - Solution: **Removed the problematic overflow rule entirely** - the rule was added for "modal clipping" but caused more issues than it solved
  - Increased scrollbar width from 8px to 12px for better clickability (was hard to click near window edge)
- **UniFi Theme (v5.90)**:
  - Fixed migrate icon missing in resource tree when VM/CT is being migrated
  - Root cause: `.running::after` rule (green status dot) has `content: "\f111" !important` which overrides `.lock-migrate::after` content when both classes are present
  - Solution: Added more specific `.running.lock-migrate::after` selector that shows the migrate icon (paper-plane) with amber color
  - Also added rules for `.lock-backup` and `.lock-suspending` states
- **UniFi Theme (v5.89)**:
  - Fixed delete dialog warning text "Referenced disks will always be destroyed." being cut off
  - Root cause: ExtJS box layout set narrow container width (236px) causing text wrap, then 0px height due to absolute positioning
  - Solution: Added `white-space: nowrap` to `.pmx-hint` to keep text on single line

## [2.2.4] - 2026-01-21

### Fixed
- **Installer**:
  - Fixed `sed` delimiter issue during uninstall that caused "extra characters after command" error (PR #6 by @jiriteach)
  - Root cause: Marker text `<!-- /ProxMorph JS Patches -->` contained `/` which conflicted with sed's default delimiter
  - Solution: Use `|` as alternate delimiter and properly escape special regex characters
- **UniFi Theme (v5.88)**:
  - Fixed "Finish Edit" checkmark button appearing on tags when not in edit mode
  - Root cause: `.x-btn-default-small { display: flex !important }` overrode Proxmox's inline `display: none`
  - Solution: Added rule to respect inline `display: none` styles for dynamically hidden buttons
  - Fixed dark text on tags in edit mode (e.g., teal `testesteste` tag had black text)
  - Tags now always use light text (#F9FAFA) when in edit mode, regardless of `proxmox-tag-dark` classification
  - Fixed "More" button position in IPs section not visible (was positioned off-screen)
  - Corrected transform value from -430px to -242px to align with current PVE 9.x layout

## [2.2.3] - 2026-01-20

### Fixed
- **Installer**:
  - Improved PVE version detection to report specific manager version (e.g., v9.1.4) instead of metapackage version (v9.1.0)
  - Suppressed misleading "Themes directory not found" error during one-liner (`curl | bash`) installations
  - Added robust guards for script path detection via `BASH_SOURCE`

## [2.2.2] - 2026-01-20

### Added
- **Proxmox Backup Server (PBS) Support**:
  - The installer now officially supports PBS (v3.x/4.x)
  - Auto-detects product (PVE or PBS) and adjusts paths automatically
  - Native integration with PBS theme selector
  - Persistence across PBS updates via apt hook
  - JavaScript patches support for PBS template format (.hbs)

## [2.2.1] - 2026-01-20

### Fixed
- **Apt Hook**:
  - Fixed `[[: not found` syntax error in `post-update.sh` by enforcing POSIX compliance (ensures compatibility with `dash`/`sh`)
- **GitHub Dark Theme**:
  - **Tree/Toolbox Highlights**:
    - Ported authentic UniFi highlight mechanism (using pseudo-elements) to fix "double background" and text artifacts
  - **Structural Alignment**:
    - Ported UniFi border structures (radius, padding, layout) to Windows, Panels, and Fieldsets while preserving GitHub colors
  - **Resource Tree**:
    - Removed default blue focus borders
    - Aligned cell padding with UniFi standards
- **UniFi Theme (v5.85)**:
  - Fixed horizontal scrollbar in resource tree (1px overflow caused by CSS specificity conflict)
  - Added scrollbar corner styling to eliminate white square artifact at corner intersection
- **UniFi Theme (v5.87)**:
  - Fixed "More" button position in IPs section of Summary panel for variable IP count
  - Button now correctly positioned next to "IPs" label regardless of whether 1, 2, or more IPs are displayed
  - Root cause: ExtJS dynamically sets button's `top` based on container height
  - Solution: Anchor to `top: 0` then use consistent transform for fine positioning
  - Added overflow:visible to parent containers to prevent clipping

### Added
- **UniFi Theme (v5.86)**:
  - Replaced sprite-based ExtJS tool icons with crisp FontAwesome icons:
    - Zoom out (undo zoom), collapse/expand panel chevrons
    - Maximize/restore window icons
    - Gear (settings) and refresh icons
  - Distinct icons for collapse vs expand states (chevron direction indicates action)
  - Added styling for generic inline FontAwesome tool icons (e.g., "Reset form data" button)
  - Fixed disabled tool icon mask overlay (transparent background, non-blocking pointer events)
- **Chart Hover Dots**:
  - Added subtle white border (1px) to chart data point dots when hovered
  - Improves visibility of hover state against colored fills

## [2.2.0] - 2026-01-18

### Added
- **JavaScript Chart Patching**:
  - Implemented `unifi-charts.js` to dynamically patch Proxmox RRD charts
  - Adds true UniFi color palette validation (Green/Blue) to charts
  - Solves "Network Traffic" chart blending issues by layering areas correctly
- **Installation**:
  - `install.sh` now installs JavaScript patches to `/usr/share/pve-manager/js/proxmorph/`
  - persistence across PVE updates via APT hook (post-update re-patching)

## [2.1.1] - 2026-01-18

### Fixed
- **UniFi Theme**: 
  - Fixed "More" button alignment in guest summary panel
  - Corrected width and layout of confirmation dialogs (message boxes)
  - Fixed window header close icon positioning
  - Fixed checkbox label visibility and alignment in dialogs

## [2.0.2] - 2026-01-14

### Fixed
- Column panel gap in dialog forms (Edit Network Device, etc.)
  - Added visible 25px gap between left and right form columns
  - Removed width override that was forcing columns to full width
  - Removed padding reset that was eliminating the gap

## [2.0.1] - 2026-01-13

### Fixed
- Resource grid labels (Memory, Cores) no longer appear dark gray
  - Root cause: `filter: invert(90%)` on TD cells was inverting both icons AND text
  - Solution: Isolated filter to icons via `::before` pseudo-elements
- FontAwesome icons in resource grid (Swap, Root Disk) now use bright color (#DEE0E3)

## [2.0.0] - 2026-01-13

### Changed
- **BREAKING**: Removed SASS build system in favor of direct CSS patching
- Theme creation now uses PowerShell scripts that patch the original Proxmox CSS
- GitHub Dark theme completely rewritten using official GitHub CSS variables

### Added
- `generate_github_dark.ps1` - PowerShell script to generate GitHub Dark theme
- `themes/original-proxmox-dark.css` - Base Proxmox Dark CSS for patching

### Removed
- SASS source files (`sass/` directory)
- `build.sh` - No longer needed
- Emerald Night theme (deprecated)

## [1.1.1] - 2026-01-13

### Fixed
- LXC/QEMU container icons in treelist navigation now have transparent background
- Grid table headers no longer clipped on panels with title bars (VNets, etc.)
- Summary page widget panels (Health, Guests, Resources) now have rounded borders

## [1.1.0] - 2026-01-12

### Added
- Modal dialog open animations with background blur effect
- Custom FontAwesome tree expander arrows (chevrons)
- Custom checkboxes and radio buttons (UniFi-style)
- FontAwesome close button icons (replacing pixelated sprites)
- Smooth scrolling throughout the interface

### Changed
- Resource tree tags now match search table tag height (19px)
- Grid table cells now vertically center text
- Treelist items use consistent 4px border-radius
- Reduced window shadow intensity for cleaner look
- Improved status panel padding alignment
- Login modal form fields now use full width
- Login modal footer uses flexbox for proper spacing

### Fixed
- Hidden ExtJS shadow element causing hard shadow edges
- Boundlist dropdown clipping issues
- Icon-only button width issues
- Segmented button text visibility on pressed state
- Modal dialog content being cut off
- Tab focus border removed for cleaner look
- Bulk Actions dropdown button styling
- Floating grid picker border-radius

## [1.0.0] - 2026-01-08

### Added
- Initial release of ProxMorph theme collection
- UniFi-inspired dark theme for Proxmox VE 8.x/9.x
- Blue Slate minimal baseline theme
- Automatic integration with Proxmox Color Theme selector
- Install/uninstall script with backup functionality
