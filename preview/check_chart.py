from playwright.sync_api import sync_playwright
import json, os
from pathlib import Path
OUT=Path(__file__).parent/'evidence';OUT.mkdir(exist_ok=True)
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox'])
    page=browser.new_page(viewport={'width':1600,'height':1050})
    errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.goto(os.environ.get('PREVIEW_URL','http://127.0.0.1:8769/preview/')+'?theme=stock',wait_until='networkidle')
    try: page.wait_for_function('window.previewReady === true',timeout=10000)
    except Exception:
        print(json.dumps({'errors':errors}));page.screenshot(path=str(OUT/'error.png'));raise
    assert not errors,errors
    before=page.evaluate("Array.from(document.querySelectorAll('.x-legend-item-marker'), e=>getComputedStyle(e).backgroundColor)")
    page.evaluate('preview.switchTheme(false)')
    page.wait_for_function("Array.from(document.querySelectorAll('.x-legend-item-marker'), e=>getComputedStyle(e).backgroundColor)[0] === 'rgb(0, 121, 166)'",timeout=3000)
    after=page.evaluate("Array.from(document.querySelectorAll('.x-legend-item-marker'), e=>getComputedStyle(e).backgroundColor)")
    page.screenshot(path=str(OUT/'summary.png'))
    assert after[0]=='rgb(0, 121, 166)', f'Theme palette not applied: {after}'
    page.evaluate('preview.switchTheme(true)')
    page.wait_for_function("Array.from(document.querySelectorAll('.x-legend-item-marker'), e=>getComputedStyle(e).backgroundColor)[0] !== 'rgb(0, 121, 166)'",timeout=3000)
    restored=page.evaluate("Array.from(document.querySelectorAll('.x-legend-item-marker'), e=>getComputedStyle(e).backgroundColor)")
    assert restored==before, (before,restored)
    assert not errors,errors
    print(json.dumps({'chart_palette':'PASS','restore':'PASS','page_errors':errors}))
    browser.close()
