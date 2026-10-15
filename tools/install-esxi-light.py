#!/usr/bin/env python3
"""Add ESXi Light to an existing PVE Proxmorph installation; dry run by default."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sys
from datetime import datetime, timezone

PROJECT = Path(__file__).resolve().parents[1]
LIB = 'usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js'
TPL = 'usr/share/pve-manager/index.html.tpl'
FILES = {
    'usr/share/javascript/proxmox-widget-toolkit/themes/theme-esxi-light.css': 'themes/theme-esxi-light.css',
    'opt/proxmorph/themes/theme-esxi-light.css': 'themes/theme-esxi-light.css',
    'usr/share/pve-manager/js/proxmorph/esxi-light-charts.js': 'themes/patches/esxi-light-charts.js',
    'opt/proxmorph/themes/patches/esxi-light-charts.js': 'themes/patches/esxi-light-charts.js',
}

def sha(data):
    return hashlib.sha256(data).hexdigest()

def write(path, data, mode=0o644):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + '.esxi-new')
    try:
        with tmp.open('xb') as out:
            out.write(data)
            out.flush()
            os.fsync(out.fileno())
        os.chmod(tmp, mode)
        os.replace(tmp, path)
    finally:
        if tmp.exists():
            tmp.unlink()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('/'), help='Filesystem root (test fixtures only)')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--apply', action='store_true')
    mode.add_argument('--rollback', type=Path, help='Backup directory printed by a successful apply')
    args = parser.parse_args()
    root = args.root.resolve()
    allowed = set(FILES) | {LIB, TPL}
    if args.rollback:
        backup = args.rollback.resolve()
        manifest = json.loads((backup / 'manifest.json').read_text())
        if manifest['root'] != str(root):
            raise ValueError('Backup root does not match this installation')
        for rel, item in manifest['files'].items():
            if rel not in allowed:
                raise ValueError('Unexpected backup path')
            target = root / rel
            if not target.is_file() or sha(target.read_bytes()) != item['installed_sha256']:
                raise ValueError(f'{rel} changed since installation; refusing to overwrite later edits')
        for rel, item in manifest['files'].items():
            if item['existed']:
                write(root / rel, (backup / rel).read_bytes(), item['mode'])
            else:
                (root / rel).unlink()
        print(json.dumps({'restored': list(manifest['files']), 'backup': str(backup)}))
        return
    if not (root / 'opt/proxmorph/.version').is_file():
        raise ValueError('An existing Proxmorph installation is required')
    desired = {rel: (PROJECT / src).read_bytes() for rel, src in FILES.items()}
    lib = (root / LIB).read_text()
    if not re.search(r'''["']esxi-light["']\s*:''', lib):
        if lib.count('theme_map: {') != 1:
            raise ValueError('Expected one native theme_map registration point')
        lib = lib.replace('theme_map: {', 'theme_map: {\n            "esxi-light": "ESXi Light",', 1)
    desired[LIB] = lib.encode()
    tpl = (root / TPL).read_text()
    tag = '<script src="/pve2/js/proxmorph/esxi-light-charts.js"></script>'
    if tag not in tpl:
        marker = '<!-- ProxMorph JS Patches -->'
        if tpl.count(marker) != 1:
            raise ValueError('Expected one existing Proxmorph script block')
        tpl = tpl.replace(marker, marker + '\n' + tag, 1)
    desired[TPL] = tpl.encode()
    changes = {rel: data for rel, data in desired.items()
               if not (root / rel).exists() or (root / rel).read_bytes() != data}
    result = {'mode': 'apply' if args.apply else 'dry-run', 'changed': list(changes)}
    if args.apply and changes:
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
        backup = root / 'root/.proxmorph-esxi-backup' / stamp
        backup.mkdir(parents=True, mode=0o700)
        manifest = {'root': str(root), 'files': {}}
        for rel, data in changes.items():
            target = root / rel
            existed = target.exists()
            mode = (target.stat().st_mode & 0o777) if existed else 0o644
            manifest['files'][rel] = {'existed': existed, 'mode': mode, 'installed_sha256': sha(data)}
            if existed:
                write(backup / rel, target.read_bytes(), mode)
        write(backup / 'manifest.json', (json.dumps(manifest, indent=2) + '\n').encode(), 0o600)
        applied = []
        try:
            for rel, data in changes.items():
                write(root / rel, data, manifest['files'][rel]['mode'])
                applied.append(rel)
        except Exception:
            for rel in reversed(applied):
                item = manifest['files'][rel]
                if item['existed']:
                    write(root / rel, (backup / rel).read_bytes(), item['mode'])
                else:
                    (root / rel).unlink()
            raise
        result['backup'] = str(backup)
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError) as exc:
        sys.exit(str(exc))
