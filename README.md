# ProxMorph

Custom themes for Proxmox VE (PVE) and Proxmox Backup Server (PBS) that integrate with the native Color Theme selector.

## ✨ Features

- **Native Integration** - Themes appear in built-in Color Theme dropdown (PVE and PBS)
- **Auto-Patch on Updates** - Automatically re-applies themes after product updates
- **Hybrid Engine** - CSS for styling + JavaScript for dynamic chart patching
- **Easy Installation** - Single command installation for both PVE and PBS

## 📸 Screenshot

Comparison between default Proxmox Dark theme and UniFi theme:

![Proxmox Dark vs UniFi Theme](screenshots/Screenshot.png)

## 🎨 Themes

### Catppuccin Collection

<table>
  <tr>
    <td width="50%" align="center">
      <h3>Catppuccin Mocha</h3>
      <img src="screenshots/catppuccin-mocha.png" alt="Catppuccin Mocha Theme" width="100%">
      <br>
      <i>Darkest Catppuccin flavor — deep warm tones with mauve accent</i>
    </td>
    <td width="50%" align="center">
      <h3>Catppuccin Mocha Teal</h3>
      <img src="screenshots/catppuccin-mocha-teal.png" alt="Catppuccin Mocha Teal Theme" width="100%">
      <br>
      <i>Mocha palette with teal accent</i>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <h3>Catppuccin Macchiato</h3>
      <img src="screenshots/catppuccin-macchiato.png" alt="Catppuccin Macchiato Theme" width="100%">
      <br>
      <i>Mid-dark Catppuccin flavor with blue-tinted base</i>
    </td>
    <td width="50%" align="center">
      <h3>Catppuccin Frappé</h3>
      <img src="screenshots/catppuccin-frappe.png" alt="Catppuccin Frappé Theme" width="100%">
      <br>
      <i>Lightest dark Catppuccin flavor with muted blue base</i>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <h3>Catppuccin Latte</h3>
      <img src="screenshots/catppuccin-latte.png" alt="Catppuccin Latte Theme" width="100%">
      <br>
      <i>Official light variant — warm off-white with purple accent</i>
    </td>
    <td width="50%"></td>
  </tr>
</table>

### Dracula Collection

<table>
  <tr>
    <td width="50%" align="center">
      <h3>Dracula</h3>
      <img src="screenshots/dracula.png" alt="Dracula Theme" width="100%">
      <br>
      <i>Classic Dracula dark with purple accent</i>
    </td>
    <td width="50%" align="center">
      <h3>Dracula Midnight</h3>
      <img src="screenshots/dracula-midnight.png" alt="Dracula Midnight Theme" width="100%">
      <br>
      <i>Near-black backgrounds from the Dracula UI spec</i>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <h3>Dracula Pink</h3>
      <img src="screenshots/dracula-pink.png" alt="Dracula Pink Theme" width="100%">
      <br>
      <i>Dracula palette with pink accent</i>
    </td>
    <td width="50%" align="center">
      <h3>Dracula Cyan</h3>
      <img src="screenshots/dracula-cyan.png" alt="Dracula Cyan Theme" width="100%">
      <br>
      <i>Dracula palette with cyan accent</i>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <h3>Dracula Green</h3>
      <img src="screenshots/dracula-green.png" alt="Dracula Green Theme" width="100%">
      <br>
      <i>Forest-tinted backgrounds with green accent</i>
    </td>
    <td width="50%" align="center">
      <h3>Dracula Orange</h3>
      <img src="screenshots/dracula-orange.png" alt="Dracula Orange Theme" width="100%">
      <br>
      <i>Warm-tinted backgrounds with orange accent</i>
    </td>
  </tr>
</table>

### Other Themes

<table>
  <tr>
    <td width="50%" align="center">
      <h3>UniFi</h3>
      <img src="screenshots/unifi.png" alt="UniFi Theme" width="100%">
      <br>
      <i>Inspired by Ubiquiti UniFi Network Application</i>
    </td>
    <td width="50%" align="center">
      <h3>GitHub Dark</h3>
      <img src="screenshots/github-dark.png" alt="GitHub Dark Theme" width="100%">
      <br>
      <i>Based on GitHub Dark Dimmed theme</i>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <h3>Blue Slate</h3>
      <img src="screenshots/blue-slate.png" alt="Blue Slate Theme" width="100%">
      <br>
      <i>Cool blue-gray tones with slate accent</i>
    </td>
    <td width="50%"></td>
  </tr>
</table>

## 🚀 Installation

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

## 💻 Commands

| Command | Description |
|---------|-------------|
| `./install.sh install` | Install themes |
| `./install.sh uninstall` | Remove themes |
| `./install.sh update` or `bash <(curl -fsSL https://raw.githubusercontent.com/IT-BAER/proxmorph/main/install.sh) update` | Updates (latest from GitHub) and install the latest themes |
| `./install.sh status` | Show installation status |

## 🛠️ Creating Themes

1. Copy an existing theme from `themes/`
2. Rename to `theme-yourname.css`
3. Edit the first line: `/*!Your Theme Name*/`
4. Modify CSS styles
5. Run `./install.sh install`

Theme files must start with `/*!Display Name*/` - this sets the name in Proxmox's dropdown.

## ℹ️ How It Works

1. Theme CSS files are copied to shared `/usr/share/javascript/proxmox-widget-toolkit/themes/`
2. JavaScript patches (for charts) are installed to product-specific JS directories
3. `proxmoxlib.js` is patched to register themes, and product index templates (`.tpl` or `.hbs`) are patched to load JS patches
4. An apt hook automatically re-patches after product updates (widget-toolkit, pve-manager, or proxmox-backup-server)
5. Themes appear in the native Color Theme selector of both PVE and PBS

## 📦 Supported Versions

- Proxmox VE 9.x / 8.x
- Proxmox Backup Server 4.x / 3.x

## 📄 License

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
