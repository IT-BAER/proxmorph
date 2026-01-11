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

## Installation

### Quick Install

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

1. Copy an existing theme from `themes/`
2. Rename to `theme-yourname.css`
3. Edit the first line: `/*!Your Theme Name*/`
4. Modify CSS variables and styles
5. Run `./install.sh install`

Theme files must start with `/*!Display Name*/` - this sets the name in Proxmox's dropdown.

## Supported Versions

- Proxmox VE 9.x
- Proxmox VE 8.x

## Project Structure

```
ProxMorph/
├── themes/                   # Theme CSS files
│   ├── theme-unifi.css      # UniFi dark theme
│   └── theme-blue-slate.css # Blue Slate theme
├── sass/                     # SCSS templates (optional)
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
