# ProxMorph

Custom themes for Proxmox VE (PVE), Proxmox Backup Server (PBS), and Proxmox Datacenter Manager (PDM) that integrate with the native Color Theme selector.

## ✨ Features

- **Native Integration** - Themes appear in built-in Color Theme dropdown (PVE, PBS, and PDM)
- **Auto-Patch on Updates** - Automatically re-applies themes after product updates
- **Hybrid Engine** - CSS for styling + JavaScript for dynamic chart patching
- **Hardware Sensor Monitoring** - Optional CPU/storage temps, fan speeds, and UPS status on node Summary dashboard (PVE)
- **Easy Installation** - Single command installation for PVE, PBS, and PDM

## 📸 Screenshot

Comparison between default Proxmox Dark theme and UniFi theme:

![Proxmox Dark vs UniFi vs UniFi OLED Theme](screenshots/Screenshot.png)

## 🎨 Themes

**23 themes** across 9 collections. Featured themes below — [**View Full Gallery →**](THEMES.md)

<table>
  <tr>
    <td width="50%" align="center">
      <h3>UniFi</h3>
      <img src="screenshots/unifi.png" alt="UniFi Theme" width="100%">
      <br>
      <i>Inspired by Ubiquiti UniFi Network Application</i>
    </td>
    <td width="50%" align="center">
      <h3>Dracula</h3>
      <img src="screenshots/dracula.png" alt="Dracula Theme" width="100%">
      <br>
      <i>Classic Dracula dark with purple accent</i>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <h3>Catppuccin Mocha</h3>
      <img src="screenshots/catppuccin-mocha.png" alt="Catppuccin Mocha Theme" width="100%">
      <br>
      <i>Darkest Catppuccin flavor — deep warm tones</i>
    </td>
    <td width="50%" align="center">
      <h3>Nord Dark</h3>
      <img src="screenshots/nord-dark.png" alt="Nord Dark Theme" width="100%">
      <br>
      <i>Arctic dark palette with polar blue accent</i>
    </td>
  </tr>
</table>

<details>
<summary><strong>All Available Collections</strong></summary>

| Collection | Themes |
|------------|--------|
| Catppuccin | Mocha, Mocha Teal, Macchiato, Frappé, Latte |
| Dracula | Classic, Midnight, Pink, Cyan, Green, Orange |
| Nord | Dark, Light |
| Gruvbox | Dark, Light |
| Solarized | Dark, Light |
| Tokyo Night | — |
| UniFi | Dark, Light, OLED |
| GitHub Dark | — |
| Blue Slate | — |

</details>

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

### Verify before you run

Every release ships a `SHA256SUMS` manifest and a GitHub build-provenance attestation. The installer verifies the downloaded tarball against `SHA256SUMS` automatically and refuses to install on a mismatch, or if the manifest is missing (fail closed). That runs on the Proxmox host with tools already present (`sha256sum`), so normal install and update stay a single command with no extra setup.

For stronger, provenance-level checks, verify a release **on your workstation** before you roll it out (a stock Proxmox host has no `gh` CLI, so this step belongs on your machine, not the node):

```bash
# integrity: do the bytes match the published manifest?
curl -fsSLO https://github.com/IT-BAER/proxmorph/releases/download/v<ver>/proxmorph-<ver>.tar.gz
curl -fsSLO https://github.com/IT-BAER/proxmorph/releases/download/v<ver>/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing

# provenance: was it built by this repo's release workflow?
gh attestation verify proxmorph-<ver>.tar.gz --repo IT-BAER/proxmorph
```

What each gives you: `SHA256SUMS` proves the bytes match what was published with the release (integrity). The attestation gives you a Sigstore/OIDC chain tying the artifact to this repository's Actions build, so you can check origin against something other than the transport. It is a check you opt into, not something the host enforces; neither replaces reading `install.sh` before running it as root. The [What the installer changes](#-what-the-installer-changes-on-your-system) section lists exactly what it touches.

### Install from a clone (review first)

```bash
git clone https://github.com/IT-BAER/proxmorph.git
cd proxmorph
git checkout v<ver>          # pin a release
less install.sh              # read it
./install.sh install         # installs from the local files, no download
```

### Install from an internal mirror

For air-gapped or policy-controlled environments, point the installer at your own copy of the release artifacts. `PROXMORPH_RELEASE_BASE` is the directory that directly contains `proxmorph-<ver>.tar.gz` and `SHA256SUMS`:

```bash
PROXMORPH_RELEASE_BASE=https://mirror.example.internal/proxmorph \
  ./install.sh update <ver>
```

Checksum verification still runs, against your mirrored `SHA256SUMS`.

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
| `./install.sh default-theme <key\|none>` | Set a server-side default theme for new browsers (user choice always wins) |
| `./install.sh` | Shows Menu to manage|

## 🔍 What the installer changes on your system

Run as root, `install.sh` makes only these changes, all reversible with `./install.sh uninstall`:

- **Themes:** copies `theme-*.css` into the product's widget-toolkit themes directory.
- **Theme registration:** `sed`-patches the `theme_map` in `proxmoxlib.js` so the themes appear in the native Color Theme selector.
- **Index template:** injects `<script>` / `<link>` tags into the product index template for the JS patches and (PDM) theme links.
- **Persistence:** installs an APT hook at `/etc/apt/apt.conf.d/99proxmorph` that runs `/opt/proxmorph/post-update.sh` to re-apply the patches after a Proxmox update. The hook re-patches from the local `/opt/proxmorph` copy only; it downloads nothing.
- **Sensors (PVE, optional):** if you enable sensor display, edits `Nodes.pm` to expose `lm-sensors` data.

Originals are backed up to `/root/.proxmorph-backup` before any file is modified. `./install.sh uninstall` restores them and removes the hook.

## 🛠️ Creating Themes

1. Copy an existing theme from `themes/`
2. Rename to `theme-yourname.css`
3. Edit the first line: `/*!Your Theme Name*/`
4. Modify CSS styles
5. Run `./install.sh install`

Theme files must start with `/*!Display Name*/` - this sets the name in Proxmox's dropdown.

### Generated themes

The UniFi OLED themes are not edited by hand. They are derived from the UniFi
bases by `tools/gen-oled.sh`, which applies a per-product substitution table
(`tools/oled-palette-pve.tsv`, `tools/oled-palette-pdm.tsv`).

```bash
bash tools/gen-oled.sh          # rewrite the OLED stylesheets
bash tools/gen-oled.sh --check  # fail if they are stale
bash test/oled_sync.test.sh     # same check, plus regression guards
```

After changing `themes/theme-unifi.css` or `themes/pdm/theme-unifi.css`, re-run the
generator and commit the result. PVE/PBS and PDM need separate tables because PDM
stores its palette in `rgb()` while PVE/PBS uses hex.

## ❓ Troubleshooting

### Themes not appearing in Color Theme dropdown

If themes don't appear after installation:

1. **Clear browser cache** — Press Ctrl+Shift+R (hard refresh)
2. **Run verify check** — Run `./install.sh` and select option 7 (Verify installation)
3. **Check installation status** — Run `./install.sh status`
4. **Restart proxy service** — Run `systemctl restart pveproxy` (PVE), `systemctl restart proxmox-backup-proxy` (PBS), or `systemctl restart proxmox-datacenter-api` (PDM)

### Cloudflare Tunnel caching issues

If you access Proxmox through a **Cloudflare Tunnel**, themes may not load due to aggressive caching. To fix:

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/) and select your domain
2. Navigate to **Caching → Cache Rules**
3. Click **Create rule**
4. Set **Hostname** to your Proxmox subdomain (e.g., `proxmox.example.com`)
5. Set **Cache eligibility** to **Bypass cache**
6. Save and deploy the rule

See [Issue #13](https://github.com/IT-BAER/proxmorph/issues/13) for more details — thanks to [@gioxx](https://github.com/gioxx) for the solution!

## ℹ️ How It Works

**PVE / PBS:**
1. Theme CSS files are copied to `/usr/share/javascript/proxmox-widget-toolkit/themes/`
2. JavaScript patches (for charts) are installed to product-specific JS directories
3. `proxmoxlib.js` is patched to register themes, and product index templates (`.tpl` or `.hbs`) are patched to load JS patches
4. An apt hook automatically re-patches after product updates
5. Themes appear in the native Color Theme selector

**PDM:**
1. PDM-specific CSS override themes are installed to `/usr/share/javascript/proxmox-datacenter-manager/proxmorph-themes/`
2. `<link>` tags are injected into `index.hbs` (disabled by default, activated by JavaScript)
3. A theme selector JS patch adds ProxMorph themes to PDM's native Theme dialog
4. Selected theme is persisted in `localStorage` and activated before WASM loads

## 📦 Supported Versions

- Proxmox VE 9.x / 8.x
- Proxmox Backup Server 4.x / 3.x
- Proxmox Datacenter Manager 1.x

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
