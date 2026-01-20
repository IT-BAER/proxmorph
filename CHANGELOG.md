# Changelog

All notable changes to ProxMorph will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [2.0.2] - 2025-01-14

### Fixed
- Column panel gap in dialog forms (Edit Network Device, etc.)
  - Added visible 25px gap between left and right form columns
  - Removed width override that was forcing columns to full width
  - Removed padding reset that was eliminating the gap

## [2.0.1] - 2025-01-14

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

## [1.1.1] - 2025-01-12

### Fixed
- LXC/QEMU container icons in treelist navigation now have transparent background
- Grid table headers no longer clipped on panels with title bars (VNets, etc.)
- Summary page widget panels (Health, Guests, Resources) now have rounded borders

## [1.1.0] - 2025-01-12

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

## [1.0.0] - 2025-01-08

### Added
- Initial release of ProxMorph theme collection
- UniFi-inspired dark theme for Proxmox VE 8.x/9.x
- Blue Slate minimal baseline theme
- Automatic integration with Proxmox Color Theme selector
- Install/uninstall script with backup functionality
