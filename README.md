# ProxMorph

A theme collection for Proxmox VE that integrates with the native Color Theme selector.

## Features

- **Native Integration** - Themes appear in Proxmox's built-in Color Theme dropdown
- **Pure CSS** - No JavaScript, minimal footprint
- **Easy Installation** - Single script handles everything
- **Update Friendly** - Simple reinstall after Proxmox updates

## Available Themes

| Theme | Description |
|-------|-------------|
| **UniFi** | Dark theme inspired by Ubiquiti UniFi Network Application |
| **Blue Slate** | Modern dark theme with blue accents (Tailwind Slate palette) |
| **GitHub Dark** | Dark theme based on GitHub's dark mode colors |

## Screenshot

Comparison between default Proxmox Dark theme and UniFi theme:

![Proxmox Dark vs UniFi Theme](Screenshot.png)

## Installation

### One-Liner Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IT-BAER/proxmorph/main/install.sh) update
```

### Manual Install

```bash
git clone https://github.com/IT-BAER/proxmorph.git
cd proxmorph
chmod +x install.sh
./install.sh install
```

### Apply Theme

1. Clear browser cache (Ctrl+Shift+R)
2. Click username → Color Theme
3. Select a ProxMorph theme

## After Proxmox Updates

Reinstall themes after `proxmox-widget-toolkit` updates:

```bash
./install.sh reinstall
```

## Uninstall

```bash
./install.sh uninstall
```

## Commands

| Command | Description |
|---------|-------------|
| `./install.sh install` | Install all themes |
| `./install.sh reinstall` | Reinstall after PVE update |
| `./install.sh uninstall` | Remove all themes |
| `./install.sh list` | List available themes |
| `./install.sh status` | Show installation status |

## Creating Themes

### Quick Method (CSS only)

1. Copy an existing theme from `themes/`
2. Rename to `theme-yourname.css`
3. Edit the first line: `/*!Your Theme Name*/`
4. Modify CSS variables and styles
5. Run `./install.sh install`

Theme files must start with `/*!Display Name*/` - this sets the name in Proxmox's dropdown.

### Using SASS (Recommended)

The SASS system provides a consistent, maintainable way to create themes:

1. **Copy the template:**
   ```bash
   cp sass/_template.scss sass/themes/theme-yourname.scss
   ```

2. **Edit your theme variables:**
   ```scss
   $theme-name: "Your Theme Name";
   
   // Primary Accent Color
   $accent: #your-color;
   
   // Background Colors
   $bg-base: #your-dark-bg;
   $bg-surface: #your-panel-bg;
   $bg-elevated: #your-hover-bg;
   
   // Text Colors
   $text-primary: #your-text;
   // ... etc
   ```

3. **Build CSS from SASS:**
   ```bash
   chmod +x build.sh
   ./build.sh
   ```
   Or manually: `sass sass/themes/theme-yourname.scss themes/theme-yourname.css`

4. **Install:**
   ```bash
   ./install.sh install
   ```

### SASS Structure

```
sass/
├── _template.scss           # Template to copy for new themes
├── base/                    # Shared style partials
│   ├── _variables.scss      # CSS custom properties
│   ├── _base.scss           # Body and panel styles
│   ├── _navigation.scss     # Tree nav and tabs
│   ├── _buttons.scss        # Button styles
│   ├── _forms.scss          # Form inputs and menus
│   ├── _tables.scss         # Grid and table styles
│   ├── _status.scss         # Status icons and progress
│   └── _misc.scss           # Windows, tooltips, scrollbars
└── themes/                  # Your theme SCSS files
    ├── theme-blue-slate.scss
    └── theme-emerald-night.scss
```

## Supported Versions

- Proxmox VE 9.x
- Proxmox VE 8.x

## Project Structure

```
ProxMorph/
├── themes/                   # Compiled theme CSS files
│   ├── theme-unifi.css      # UniFi dark theme
│   └── theme-blue-slate.css # Blue Slate theme
├── sass/                     # SCSS source files
│   ├── _template.scss       # Theme template
│   ├── base/                # Shared partials
│   └── themes/              # Theme sources
├── build.sh                 # SASS build script
├── install.sh               # Installation script
└── patch_theme_map.sh       # Manual theme registration
```

## How It Works

1. Theme CSS files are copied to `/usr/share/javascript/proxmox-widget-toolkit/themes/`
2. `proxmoxlib.js` is patched to register themes in `theme_map`
3. Themes appear in Proxmox's native Color Theme selector
4. CSS uses `!important` to override ExtJS inline styles

## License

MIT License
