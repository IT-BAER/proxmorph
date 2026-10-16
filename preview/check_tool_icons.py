from playwright.sync_api import sync_playwright
import os
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox'])
 page=b.new_page();page.goto(os.environ.get('PREVIEW_URL','http://127.0.0.1:8769/preview/'),wait_until='networkidle');page.wait_for_function('window.previewReady')
 page.evaluate('''() => {window.iconProbeClicks=0;window.iconProbe=Ext.create('Ext.panel.Panel',{title:'Notes',renderTo:Ext.getBody(),floating:true,width:300,height:120,tools:[{glyph:'xf044@FontAwesome',tooltip:'Edit notes',handler:()=>window.iconProbeClicks++},{type:'collapse-right',tooltip:'Collapse panel'},{glyph:'xf0e2@FontAwesome',tooltip:'Reset form data',disabled:true,handler:()=>window.iconProbeClicks+=100}]});iconProbe.show();}''')
 info=page.evaluate('''() => [...iconProbe.el.dom.querySelectorAll('.x-tool-tool-el')].map(e=>({bg:getComputedStyle(e).backgroundImage,mask:getComputedStyle(e,'::before').maskImage,font:getComputedStyle(e).fontSize}))''')
 assert all(i['bg']=='none' and 'svg+xml' in i['mask'] for i in info),info
 page.evaluate("() => iconProbe.el.dom.querySelector('.x-tool').click()")
 page.evaluate("() => iconProbe.el.dom.querySelector('.x-tool-disabled').click()")
 assert page.evaluate('window.iconProbeClicks')==1
 page.evaluate('() => {iconProbe.destroy();}')
 print('PASS: edit, collapse and reset use vector masks; edit action preserved');b.close()
