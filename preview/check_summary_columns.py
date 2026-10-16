"""Fractional summary width must not wrap two columns into a half-empty page."""
import os
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox'])
 page=b.new_page(viewport={'width':1800,'height':1100},device_scale_factor=1.8)
 page.goto(os.environ.get('PREVIEW_URL','http://127.0.0.1:8769/preview/'),wait_until='networkidle');page.wait_for_function('window.previewReady')
 page.evaluate("window.columnProbe=Ext.create('Ext.container.Container',{renderTo:Ext.getBody(),width:1411.33,style:'position:absolute;top:150px',layout:'column',items:[{xtype:'panel',title:'Status',height:180},{xtype:'panel',title:'CPU',height:180}]});Proxmox.Utils.updateColumnWidth(columnProbe)")
 before=page.evaluate('columnProbe.items.items.map(i=>({width:i.getWidth(),column:i.columnWidth}))')
 page.get_by_role('button',name='Hide resource tree',exact=True).click()
 page.evaluate('Proxmox.Utils.updateColumnWidth(columnProbe)')
 expanded=page.evaluate('columnProbe.items.items.map(i=>({width:i.getWidth(),column:i.columnWidth}))')
 assert all(i['width']>=1410 and i['column']==1 for i in expanded),expanded
 page.evaluate('columnProbe.setWidth(1100.33);Proxmox.Utils.updateColumnWidth(columnProbe)')
 assert page.evaluate('columnProbe.items.first().getWidth()')>=1099
 page.evaluate('columnProbe.setWidth(1411.33);Proxmox.Utils.updateColumnWidth(columnProbe)')
 page.get_by_role('button',name='Show resource tree',exact=True).click()
 page.evaluate('Proxmox.Utils.updateColumnWidth(columnProbe)')
 restored=page.evaluate('columnProbe.items.items.map(i=>({width:i.getWidth(),column:i.columnWidth}))')
 assert restored==before,(before,restored)
 print('PASS: full-width cards while hidden, fractional resize, native widths and columns restored')
 b.close()
