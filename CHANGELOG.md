# Changelog

All notable changes to ProxMorph will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
