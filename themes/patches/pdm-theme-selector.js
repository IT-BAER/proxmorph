/*
 * ProxMorph PDM Theme Selector Patch
 * Version: 1.0.0
 *
 * Injects ProxMorph theme options into PDM's native Theme dialog dropdown.
 * Uses MutationObserver to detect when the dialog opens and adds custom
 * theme entries alongside the built-in Desktop/Crisp options.
 *
 * Theme guard: only runs if proxmorph-theme CSS links are present.
 */
(function() {
    'use strict';

    if (!document.querySelector('link.proxmorph-theme')) return;

    var themeLinks = document.querySelectorAll('link.proxmorph-theme');
    var themes = [];
    for (var i = 0; i < themeLinks.length; i++) {
        var href = themeLinks[i].getAttribute('href');
        var filename = href.split('/').pop();
        var name = filename.replace('theme-', '').replace('.css', '')
            .split('-').map(function(w) { return w.charAt(0).toUpperCase() + w.slice(1); }).join(' ');
        themes.push({ filename: filename, display: 'PM: ' + name, link: themeLinks[i] });
    }

    function activateTheme(filename) {
        for (var i = 0; i < themeLinks.length; i++) {
            themeLinks[i].setAttribute('disabled', '');
        }
        if (filename) {
            localStorage.setItem('proxmorph-theme', filename);
            var base = document.querySelector('link.proxmorph-base');
            if (base) base.removeAttribute('disabled');
            for (var j = 0; j < themeLinks.length; j++) {
                if (themeLinks[j].href.indexOf(filename) !== -1) {
                    themeLinks[j].removeAttribute('disabled');
                }
            }
        } else {
            localStorage.removeItem('proxmorph-theme');
            var base = document.querySelector('link.proxmorph-base');
            if (base) base.setAttribute('disabled', '');
        }
    }

    function deactivateProxmorph() {
        for (var i = 0; i < themeLinks.length; i++) {
            themeLinks[i].setAttribute('disabled', '');
        }
        var base = document.querySelector('link.proxmorph-base');
        if (base) base.setAttribute('disabled', '');
        localStorage.removeItem('proxmorph-theme');
    }

    var patched = false;

    function setupObserver() {
        var observer = new MutationObserver(function() {
            if (patched) return;
            tryInject();
        });
        observer.observe(document.documentElement, { childList: true, subtree: true });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', setupObserver);
    } else {
        setupObserver();
    }

    function tryInject() {
        var dialog = document.querySelector('dialog');
        if (!dialog) { patched = false; return; }

        var combo = dialog.querySelector('[aria-label="Select Theme"]');
        if (!combo) return;

        /* Early combo fix: override value as soon as dialog appears, before dropdown is expanded */
        var currentThemeEarly = localStorage.getItem('proxmorph-theme');
        if (currentThemeEarly && combo.tagName === 'INPUT' && !combo.__proxmorphPatched) {
            for (var ei = 0; ei < themes.length; ei++) {
                if (themes[ei].filename === currentThemeEarly) {
                    var origDesc = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value');
                    origDesc.set.call(combo, themes[ei].display);
                    Object.defineProperty(combo, 'value', {
                        get: function() { return origDesc.get.call(this); },
                        set: function(v) {
                            var active = localStorage.getItem('proxmorph-theme');
                            if (active && (v === 'Desktop' || v === 'Crisp' || v === 'Material')) {
                                return;
                            }
                            origDesc.set.call(this, v);
                        },
                        configurable: true
                    });
                    combo.__proxmorphPatched = true;
                    break;
                }
            }
        }

        var tables = dialog.querySelectorAll('.pwt-datatable-content');
        var themeTable = null;

        for (var t = 0; t < tables.length; t++) {
            var rows = tables[t].querySelectorAll('tr[role="row"]');
            for (var r = 0; r < rows.length; r++) {
                var cellText = rows[r].textContent.trim();
                if (cellText === 'Desktop' || cellText === 'Crisp' || cellText === 'Material') {
                    themeTable = tables[t];
                    break;
                }
            }
            if (themeTable) break;
        }

        if (!themeTable) return;
        if (themeTable.querySelector('[data-proxmorph-theme]')) { patched = true; return; }

        var nativeRows = themeTable.querySelectorAll('tr[role="row"]');
        var existingCount = nativeRows.length;

        var idPrefix = 'ProxMorph';
        if (nativeRows.length > 0 && nativeRows[0].id) {
            idPrefix = nativeRows[0].id.split('-item-')[0];
        }

        var sepRow = document.createElement('tr');
        sepRow.setAttribute('role', 'none');
        sepRow.className = 'proxmorph-separator';
        var sepTd = document.createElement('td');
        sepTd.setAttribute('role', 'none');
        sepTd.setAttribute('colspan', '2');
        sepTd.style.cssText = 'padding:4px 0;border-top:1px solid var(--pwt-color-neutral-40,#555);';
        var sepDiv = document.createElement('div');
        sepDiv.style.cssText = 'font-size:11px;color:var(--pwt-color-neutral-60,#999);padding:2px 8px;';
        sepDiv.textContent = 'ProxMorph Themes';
        sepTd.appendChild(sepDiv);
        sepRow.appendChild(sepTd);
        themeTable.appendChild(sepRow);

        var currentTheme = localStorage.getItem('proxmorph-theme');

        for (var i = 0; i < themes.length; i++) {
            var theme = themes[i];
            var rowIndex = existingCount + i + 1;
            var isSelected = currentTheme === theme.filename;

            var row = document.createElement('tr');
            row.setAttribute('role', 'row');
            row.setAttribute('aria-rowindex', String(rowIndex));
            row.setAttribute('aria-selected', isSelected ? 'true' : 'false');
            row.id = idPrefix + '-item-PM-' + theme.filename;
            row.className = isSelected ? 'row-cursor selected' : '';
            row.setAttribute('data-proxmorph-theme', theme.filename);

            var td = document.createElement('td');
            td.setAttribute('role', 'gridcell');
            td.setAttribute('data-column-num', '0');
            td.setAttribute('tabindex', '-1');
            td.className = 'pwt-datatable-cell pwt-pointer' + (isSelected ? ' cell-cursor' : '');
            td.style.cssText = 'vertical-align:baseline;text-align:start;';

            var div = document.createElement('div');
            div.setAttribute('role', 'none');
            div.textContent = theme.display;
            td.appendChild(div);

            var td2 = document.createElement('td');
            td2.setAttribute('role', 'none');
            td2.style.cssText = 'vertical-align:top;height:22px;';

            row.appendChild(td);
            row.appendChild(td2);
            themeTable.appendChild(row);

            (function(themeObj, rowEl) {
                rowEl.addEventListener('click', function(e) {
                    e.stopPropagation();
                    var allRows = themeTable.querySelectorAll('tr[role="row"]');
                    for (var k = 0; k < allRows.length; k++) {
                        allRows[k].className = '';
                        allRows[k].setAttribute('aria-selected', 'false');
                        var cells = allRows[k].querySelectorAll('.pwt-datatable-cell');
                        for (var c = 0; c < cells.length; c++) {
                            cells[c].classList.remove('cell-cursor');
                        }
                    }
                    rowEl.className = 'row-cursor selected';
                    rowEl.setAttribute('aria-selected', 'true');
                    var myCell = rowEl.querySelector('.pwt-datatable-cell');
                    if (myCell) myCell.classList.add('cell-cursor');

                    activateTheme(themeObj.filename);

                    var combo = dialog.querySelector('[aria-label="Select Theme"]');
                    if (combo) {
                        if (combo.tagName === 'INPUT') {
                            /* Remove override temporarily to set the new value */
                            var origDesc = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value');
                            delete combo.value;
                            origDesc.set.call(combo, themeObj.display);
                            /* Re-install override to block PWT resets */
                            Object.defineProperty(combo, 'value', {
                                get: function() { return origDesc.get.call(this); },
                                set: function(v) {
                                    var active = localStorage.getItem('proxmorph-theme');
                                    if (active && (v === 'Desktop' || v === 'Crisp' || v === 'Material')) {
                                        return;
                                    }
                                    origDesc.set.call(this, v);
                                },
                                configurable: true
                            });
                        } else {
                            var valueSpan = combo.querySelector('.pwt-text-truncate') || combo;
                            if (valueSpan) valueSpan.textContent = themeObj.display;
                        }
                    }
                });
            })(theme, row);
        }

        /* If a ProxMorph theme is active, deselect native rows and update combo */
        if (currentTheme) {
            for (var d = 0; d < nativeRows.length; d++) {
                nativeRows[d].className = '';
                nativeRows[d].setAttribute('aria-selected', 'false');
                var dCells = nativeRows[d].querySelectorAll('.pwt-datatable-cell');
                for (var dc = 0; dc < dCells.length; dc++) {
                    dCells[dc].classList.remove('cell-cursor');
                }
            }
            /* Update combo display text to active PM theme name */
            var activeCombo = dialog.querySelector('[aria-label="Select Theme"]');
            if (activeCombo) {
                for (var at = 0; at < themes.length; at++) {
                    if (themes[at].filename === currentTheme) {
                        if (activeCombo.tagName === 'INPUT') {
                            activeCombo.value = themes[at].display;
                            /* Override value setter to prevent PWT from resetting to native theme name */
                            var pmDisplay = themes[at].display;
                            var origDescriptor = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value');
                            Object.defineProperty(activeCombo, 'value', {
                                get: function() { return origDescriptor.get.call(this); },
                                set: function(v) {
                                    var active = localStorage.getItem('proxmorph-theme');
                                    if (active && (v === 'Desktop' || v === 'Crisp' || v === 'Material')) {
                                        return;
                                    }
                                    origDescriptor.set.call(this, v);
                                },
                                configurable: true
                            });
                        } else {
                            var valSpan = activeCombo.querySelector('.pwt-text-truncate') || activeCombo;
                            if (valSpan) valSpan.textContent = themes[at].display;
                        }
                        break;
                    }
                }
            }
        }

        for (var nr = 0; nr < nativeRows.length; nr++) {
            (function(nativeRow) {
                nativeRow.addEventListener('click', function() {
                    deactivateProxmorph();
                    /* Remove value override so PWT can set native theme name */
                    var cmb = dialog.querySelector('[aria-label="Select Theme"]');
                    if (cmb && cmb.tagName === 'INPUT') {
                        delete cmb.value;
                    }
                    var pmRows = themeTable.querySelectorAll('[data-proxmorph-theme]');
                    for (var p = 0; p < pmRows.length; p++) {
                        pmRows[p].className = '';
                        pmRows[p].setAttribute('aria-selected', 'false');
                        var cells = pmRows[p].querySelectorAll('.pwt-datatable-cell');
                        for (var c = 0; c < cells.length; c++) {
                            cells[c].classList.remove('cell-cursor');
                        }
                    }
                });
            })(nativeRows[nr]);
        }

        patched = true;

        var closeCheck = setInterval(function() {
            if (!document.contains(themeTable)) {
                patched = false;
                clearInterval(closeCheck);
            }
        }, 500);
    }
})();
