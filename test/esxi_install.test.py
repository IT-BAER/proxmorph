"""Exercise additive install and exact rollback in a disposable filesystem."""
import pathlib, subprocess, sys, tempfile, json
PROJECT=pathlib.Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as tmp:
    root=pathlib.Path(tmp)
    original={
        'usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js':b'const theme_map: {\n "unifi": "UniFi",\n};\n',
        'usr/share/pve-manager/index.html.tpl':b'<html><body>\n<!-- ProxMorph JS Patches -->\n<script src="/pve2/js/proxmorph/unifi-charts.js"></script>\n<!-- /ProxMorph JS Patches -->\n</body></html>\n',
        'opt/proxmorph/.version':b'2.8.4\n',
        'opt/proxmorph/.sensors-enabled':b'yes\n',
    }
    for rel,data in original.items():
        dest=root/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
    command=[sys.executable,str(PROJECT/'tools/install-esxi-light.py'),'--root',str(root)]
    dry=subprocess.run(command,check=True,capture_output=True,text=True)
    assert all((root/p).read_bytes()==v for p,v in original.items())
    applied=json.loads(subprocess.run(command+['--apply'],check=True,capture_output=True,text=True).stdout)
    assert len(applied['changed'])==6
    tpl=(root/'usr/share/pve-manager/index.html.tpl').read_text()
    assert tpl.count('esxi-light-charts.js')==1 and tpl.count('unifi-charts.js')==1
    assert (root/'opt/proxmorph/.sensors-enabled').read_bytes()==b'yes\n'
    assert (root/'opt/proxmorph/.version').read_bytes()==b'2.8.4\n'
    again=json.loads(subprocess.run(command+['--apply'],check=True,capture_output=True,text=True).stdout)
    assert again['changed']==[]
    subprocess.run(command+['--rollback',applied['backup']],check=True,capture_output=True,text=True)
    assert all((root/p).read_bytes()==v for p,v in original.items())
    assert not (root/'usr/share/javascript/proxmox-widget-toolkit/themes/theme-esxi-light.css').exists()
    # A later independent edit must not be silently lost during rollback.
    applied=json.loads(subprocess.run(command+['--apply'],check=True,capture_output=True,text=True).stdout)
    dest=root/'usr/share/pve-manager/index.html.tpl';dest.write_text(dest.read_text()+'<!-- later edit -->')
    refused=subprocess.run(command+['--rollback',applied['backup']],capture_output=True,text=True)
    assert refused.returncode!=0 and 'changed since installation' in refused.stderr
    assert 'later edit' in dest.read_text()
    print('PASS: dry run, six-file additive install, existing hooks preserved, idempotence, exact rollback, later-edit protection')
