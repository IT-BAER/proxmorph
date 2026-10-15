"""Check the PVE 9 chart aggregation selector's complete segmented outline."""
import os
from pathlib import Path
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox'])
 page=b.new_page(viewport={'width':1600,'height':1050})
 page.goto(os.environ.get('PREVIEW_URL','http://127.0.0.1:8769/preview/'),wait_until='networkidle');page.wait_for_function('window.previewReady')
 page.evaluate('''() => {window.toggleProbe=Ext.create('Ext.toolbar.Toolbar',{renderTo:Ext.getBody(),floating:true,width:420,x:500,y:80,items:[{xtype:'segmentedbutton',defaults:{cls:'x-btn-default-toolbar-small proxmox-inline-button'},items:[{text:'Maximum',style:{'border-top-right-radius':'0px','border-bottom-right-radius':'0px','border-right-width':'0px'}},{text:'Average',pressed:true,style:{'border-top-left-radius':'0px','border-bottom-left-radius':'0px','border-left-width':'0px'}}]}]});toggleProbe.show();}''')
 group=page.locator('.x-segmented-button').last
 assert group.evaluate("e=>getComputedStyle(e).borderLeftWidth")=='1px', 'Chart selector lacks its left outline'
 avg=page.get_by_role('button',name='Average',exact=True)
 maximum=page.get_by_role('button',name='Maximum',exact=True)
 avg.hover()
 assert float(avg.evaluate("e=>parseFloat(getComputedStyle(e).borderLeftWidth)"))>0
 maximum.click()
 assert page.evaluate("toggleProbe.down('segmentedbutton').items.first().pressed")
 avg.click()
 assert page.evaluate("toggleProbe.down('segmentedbutton').items.last().pressed")
 a=avg.bounding_box();m=maximum.bounding_box()
 assert abs(a['y']-m['y'])<0.1 and abs(a['height']-m['height'])<0.1 and abs(a['x']-(m['x']+m['width']))<0.1, (a,m)
 for button in (avg,maximum):
  assert button.evaluate("e=>{let r=e.getBoundingClientRect(),p=e.parentElement.getBoundingClientRect();return r.left>=p.left&&r.right<=p.right+1&&r.top>=p.top&&r.bottom<=p.bottom+1}")
 out=Path(__file__).parent/'evidence';out.mkdir(exist_ok=True)
 page.locator('#'+page.evaluate('toggleProbe.id')).screenshot(path=str(out/'chart-toggle.png'))
 print('PASS: complete selector outline, selected divider, both aggregation actions, unclipped bounds')
 b.close()
