"""Resource-tree toggle preserves selection and returns space to the workspace."""
import os
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox'])
    page=b.new_page(viewport={'width':1600,'height':1050})
    page.goto(os.environ.get('PREVIEW_URL','http://127.0.0.1:8769/preview/'),wait_until='networkidle')
    page.wait_for_function('window.previewReady')
    button=page.get_by_role('button',name='Hide resource tree',exact=True)
    assert button.count()==1, 'Resource-tree toggle missing'
    before=page.evaluate("() => {const w=preview.root.down('[region=west]'); w.getSelectionModel().select(w.getRootNode().firstChild); return {width:w.getWidth(),selected:w.getSelectionModel().getSelection()[0].id,center:preview.root.down('[region=center]').getWidth()};}")
    button.click()
    assert page.evaluate("preview.root.down('[region=west]').hidden")
    assert page.evaluate("preview.root.down('[region=center]').getWidth()")>before['center']
    page.get_by_role('button',name='Show resource tree',exact=True).click()
    after=page.evaluate("() => {const w=preview.root.down('[region=west]');return {width:w.getWidth(),selected:w.getSelectionModel().getSelection()[0].id,hidden:w.hidden};}")
    assert after['width']==before['width'] and after['selected']==before['selected'] and not after['hidden']
    page.get_by_role('button',name='Hide resource tree',exact=True).click()
    page.evaluate('preview.switchTheme(true)')
    page.wait_for_function("!preview.root.down('[region=west]').hidden")
    assert not page.locator('#pm-esxi-tree-toggle').is_visible()
    page.evaluate('preview.switchTheme(false)')
    page.wait_for_function("!Ext.getCmp('pm-esxi-tree-toggle').hidden")
    page.get_by_role('button',name='Hide resource tree',exact=True).focus()
    assert page.locator('#pm-esxi-tree-toggle').evaluate("e=>parseFloat(getComputedStyle(e).outlineOffset)")<0
    page.keyboard.press('Enter')
    assert page.evaluate("preview.root.down('[region=west]').hidden")
    print('PASS: hide/show, workspace expansion, width/selection preserved, stock-theme restoration, keyboard activation')
    b.close()
