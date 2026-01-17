# ProxMorph

Custom themes for Proxmox VE that integrate with the native Color Theme selector.

## Features

- **Native Integration** - Themes appear in Proxmox's built-in Color Theme dropdown
- **Auto-Patch on Updates** - Automatically re-applies themes after Proxmox package updates
- **Pure CSS** - No JavaScript required, minimal footprint
- **Easy Installation** - Single command installation

## Screenshot

Comparison between default Proxmox Dark theme and UniFi theme:

![Proxmox Dark vs UniFi Theme](Screenshot.png)

## Available Themes

| Theme | Description |
|-------|-------------|
| **UniFi** | Dark theme inspired by Ubiquiti UniFi Network Application |
| **Github Dark** | In Progress|

More themes inspired by other vendor UIs are in development.

## Installation

### One-Liner Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IT-BAER/proxmorph/main/install.sh) install
```

### Manual Install

```bash
git clone https://github.com/IT-BAER/proxmorph.git
cd proxmorph
chmod +x install.sh
./install.sh install
```

### Apply Theme

1. Hard refresh browser (Ctrl+Shift+R)
2. Click username → Color Theme
3. Select a ProxMorph theme

## Commands

| Command | Description |
|---------|-------------|
| `./install.sh install` | Install themes |
| `./install.sh uninstall` | Remove themes |
| `./install.sh status` | Show installation status |

## Creating Themes

1. Copy an existing theme from `themes/`
2. Rename to `theme-yourname.css`
3. Edit the first line: `/*!Your Theme Name*/`
4. Modify CSS styles
5. Run `./install.sh install`

Theme files must start with `/*!Display Name*/` - this sets the name in Proxmox's dropdown.

## How It Works

1. Theme CSS files are copied to `/usr/share/javascript/proxmox-widget-toolkit/themes/`
2. `proxmoxlib.js` is patched to register themes in `theme_map`
3. An apt hook automatically re-patches after `proxmox-widget-toolkit` updates
4. Themes appear in Proxmox's native Color Theme selector

## Supported Versions

- Proxmox VE 9.x
- Proxmox VE 8.x

## License

MIT License

<br>

## 💜 Support

If you like my themes, consider supporting this and future work, which heavily relies on coffee:

<div align="center">
<a href="https://www.buymeacoffee.com/itbaer" target="_blank"><img src="https://github.com/user-attachments/assets/64107f03-ba5b-473e-b8ad-f3696fe06002" alt="Buy Me A Coffee" style="height: 60px; max-width: 217px;"></a>
<br>
<a href="https://www.paypal.com/donate/?hosted_button_id=5XXRC7THMTRRS" target="_blank">Donate via PayPal</a>
</div>

<br>
