/**
 * ProxMorph GitHub Dark — Checkbox/Radio Init Patch
 *
 * Problem: ExtJS pre-selects checkboxes/radios by setting background-position
 * to "0px -15px" (sprite selected state) WITHOUT adding the .x-form-cb-checked
 * class to the .x-form-item ancestor. Our CSS relies on that class.
 *
 * Fix: Scan all .x-form-cb spans, detect the -15px sprite offset, and add
 * .x-form-cb-checked to the nearest .x-form-item ancestor so our CSS rules fire.
 *
 * Runs on load + via MutationObserver whenever new dialogs are added to the DOM.
 */
(function () {
    'use strict';

    function isGithubDarkActive() {
        return !!document.querySelector('link[href*="theme-github-dark.css"]');
    }

    function fixInitialCbState() {
        if (!isGithubDarkActive()) return;

        document.querySelectorAll('.x-form-cb').forEach(function (span) {
            var bgPos = window.getComputedStyle(span).backgroundPosition;
            if (bgPos && bgPos.indexOf('-15px') !== -1) {
                var fieldItem = span.closest('.x-form-item');
                if (fieldItem && !fieldItem.classList.contains('x-form-cb-checked')) {
                    fieldItem.classList.add('x-form-cb-checked');
                }
            }
        });
    }

    // Run once after the page is fully loaded
    if (document.readyState === 'complete') {
        setTimeout(fixInitialCbState, 100);
    } else {
        window.addEventListener('load', function () {
            setTimeout(fixInitialCbState, 100);
        });
    }

    // Re-run whenever new nodes are added (dialog opens, panel navigation, etc.)
    var observer = new MutationObserver(function (mutations) {
        var hasNew = false;
        for (var i = 0; i < mutations.length; i++) {
            if (mutations[i].addedNodes.length) {
                hasNew = true;
                break;
            }
        }
        if (hasNew) {
            setTimeout(fixInitialCbState, 50);
        }
    });

    observer.observe(document.body, { childList: true, subtree: true });

})();
