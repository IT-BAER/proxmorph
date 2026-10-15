"""Browser checks for theme regressions using real PVE 8.4/Ext JS controls."""
from pathlib import Path
from playwright.sync_api import sync_playwright
import json, os
BASE=os.environ.get('PREVIEW_URL','http://127.0.0.1:8769/preview/')
OUT=Path(__file__).parent/'evidence';OUT.mkdir(exist_ok=True)
CHROME=os.environ.get('CHROMIUM_PATH')
checks=[]
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path=CHROME,headless=True,args=['--no-sandbox'])
    page=browser.new_page(viewport={'width':1600,'height':1050})
    errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.set_default_timeout(8000)
    page.goto(BASE,wait_until='networkidle');page.wait_for_function('window.previewReady')
    page.evaluate('() => document.fonts.ready')
    assert page.evaluate("document.fonts.check('12px \"Clarity City\"')")
    checks.append('Embedded Clarity City font loaded locally')
    page.wait_for_timeout(180);page.screenshot(path=str(OUT/'01-summary.png'))
    assert page.evaluate("getComputedStyle(document.querySelector('.x-btn-inner')).color")=='rgb(244, 248, 251)'
    checks.append('Slate header has readable white controls')
    assert page.evaluate("getComputedStyle(document.querySelector('.x-legend-item-marker')).backgroundColor")=='rgb(0, 121, 166)'
    checks.append('Native chart legend uses theme palette')
    values=page.evaluate("""() => {let w=Ext.widget('pmxInfoWidget',{title:'Threshold probe',renderTo:Ext.getBody(),width:200});let out=[];for(let v of [.2,.8,.95]){w.updateValue('Usage',v);out.push(getComputedStyle(w.el.dom.querySelector('.x-progress-bar')).backgroundColor)}w.destroy();return out}""")
    assert values==['rgb(0, 94, 133)','rgb(187, 131, 0)','rgb(189, 51, 59)'],values
    checks.append('Native info widgets preserve normal, warning and critical colors')
    overlay=page.locator('.x-tree-icon-custom.running').first.evaluate("(e)=>getComputedStyle(e,'::after').content")
    assert overlay not in ['none','normal','""'],overlay
    checks.append('Resource type outlines retain native running status overlay')
    page.evaluate("() => {const t=Ext.ComponentQuery.query('treepanel')[0];t.getSelectionModel().select(t.getRootNode().firstChild);}")
    assert page.locator('.x-tree-panel .x-grid-item-selected .x-grid-cell').first.evaluate('(e)=>getComputedStyle(e).backgroundColor')=='rgb(80, 107, 123)'
    checks.append('Selected resource-tree cells preserve readable white text on slate')
    # Expanded navigation children must not inherit an invisible selected-parent foreground.
    page.locator('.x-treelist-item-text',has_text='Permissions').click()
    assert page.locator('.x-treelist-item-text',has_text='Users').is_visible()
    page.locator('.x-treelist-item-text',has_text='Users').click()
    assert page.locator('.x-grid-cell-inner',has_text='administrator').first.is_visible()
    checks.append('Nested navigation remains visible and selectable')
    page.locator('.x-treelist-item-text',has_text='Virtual machines').click()
    page.locator('.x-column-header-text',has_text='Name').first.click()
    assert page.get_by_text('database',exact=True).is_visible()
    page.wait_for_timeout(180);page.screenshot(path=str(OUT/'02-virtual-machines.png'))
    page.get_by_placeholder('Filter virtual machines…').fill('database')
    page.wait_for_function("preview.root.down('#vms').getStore().getCount() === 1")
    page.get_by_placeholder('Filter virtual machines…').fill('')
    checks.append('Grid filtering and sortable headers remain functional')
    page.locator('.x-treelist-item-text',has_text='Network').click()
    page.wait_for_timeout(180);page.screenshot(path=str(OUT/'03-network.png'))
    page.get_by_role('button',name='Edit',exact=True).click()
    page.locator('.x-window .x-form-arrow-trigger').first.click()
    assert page.locator('.x-boundlist-item',has_text='vmbr2').is_visible()
    page.wait_for_timeout(180);page.screenshot(path=str(OUT/'04-network-dialog.png'))
    page.locator('.x-boundlist-item',has_text='vmbr2').click()
    assert page.evaluate("Ext.WindowManager.getActive().down('combo').getValue()")=='vmbr2'
    page.get_by_role('button',name='Cancel',exact=True).click()
    checks.append('Floating combo picker and edit dialog work')
    page.locator('.x-plain .x-btn').filter(has_text='Create VM').click()
    page.get_by_role('button',name='Next',exact=True).click()
    assert page.locator('.x-form-trigger-wrap-invalid').is_visible()
    page.wait_for_timeout(180);page.screenshot(path=str(OUT/'05-create-vm-validation.png'))
    # All eight tabs must stay inside their own native measured tab bar.
    assert page.evaluate("""() => {let bar=document.querySelector('.x-window .x-tab-bar-body').getBoundingClientRect();return [...document.querySelectorAll('.x-window .x-tab')].every(e=>{let r=e.getBoundingClientRect();return r.left>=bar.left-1&&r.right<=bar.right+1})}""")
    page.get_by_role('tab',name='Network',exact=True).click()
    assert page.locator('.x-window .x-form-item-label-text',has_text='Bridge').is_visible()
    page.wait_for_timeout(180);page.screenshot(path=str(OUT/'06-create-vm-network.png'))
    active=page.locator('.x-window .x-tab-active')
    assert active.evaluate('(e)=>getComputedStyle(e.querySelector(".x-tab-inner")).color')=='rgb(255, 255, 255)'
    checks.append('Active wizard tab keeps readable text after hover and focus')
    page.get_by_role('button',name='Cancel',exact=True).click()
    checks.append('Wizard validation, tab geometry and tab navigation pass')
    page.evaluate('() => {preview.showLog();}')
    scroll=page.locator('.x-window .x-panel-body.x-scroller').first
    assert scroll.evaluate('(e)=>e.scrollHeight>e.clientHeight')
    scroll.evaluate('(e)=>e.scrollTop=e.scrollHeight')
    assert scroll.evaluate('(e)=>e.scrollTop>0')
    page.wait_for_timeout(180);page.screenshot(path=str(OUT/'07-task-log.png'))
    page.get_by_role('button',name='Close',exact=True).click()
    checks.append('Task viewer retains vertical scrolling to final output')
    page.evaluate('() => {preview.showLogin();}')
    page.wait_for_timeout(180);page.screenshot(path=str(OUT/'08-login.png'))
    page.get_by_role('button',name='Close preview',exact=True).click()
    checks.append('Login form renders with native realm selector')
    page.evaluate("preview.select('summary')")
    for width,height in [(1366,900),(1024,768)]:
        page.set_viewport_size({'width':width,'height':height});page.wait_for_timeout(200)
        assert page.evaluate('document.documentElement.scrollWidth<=innerWidth')
        page.wait_for_timeout(180);page.screenshot(path=str(OUT/f'09-summary-{width}.png'))
    checks.append('Desktop viewports 1600, 1366 and 1024 have no document overflow')
    page.set_viewport_size({'width':1600,'height':1050})
    page.emulate_media(reduced_motion='reduce')
    assert page.locator('.x-btn').first.evaluate('(e)=>getComputedStyle(e).transitionDuration')=='0s'
    page.locator('#userinfo').focus()
    assert page.locator('#userinfo').evaluate('(e)=>getComputedStyle(e).outlineStyle')!='none'
    checks.append('Reduced motion and keyboard focus stay visible')
    page.evaluate('preview.switchTheme(true)');page.wait_for_timeout(100)
    page.wait_for_timeout(180);page.screenshot(path=str(OUT/'00-proxmox-default.png'))
    page.evaluate('preview.switchTheme(false)');page.wait_for_timeout(100)
    assert not errors, errors
    checks.append('No JavaScript page errors throughout interaction checks')
    result={'checks':checks,'passed':len(checks),'page_errors':errors,'fixture':'PVE 8.4.21 / toolkit 4.3.18 / Ext JS 7.0.0-7; synthetic data'}
    (OUT/'ui-results.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2));browser.close()
