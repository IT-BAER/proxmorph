/* ProxMorph ESXi Light 1.1.4. Native RRD palette, vector tools and resource-tree toggle, no polling or API calls. */
(function () {
    'use strict';
    if (!window.Ext || window.ProxmorphESXiChartsLoaded) return;
    // Identify the two native glyph tools by codepoint, independent of UI language.
    // Classes are inert unless this theme's CSS is loaded; handlers remain native.
    const Tool = Ext.ClassManager.get('Ext.panel.Tool');
    const markTool = tool => {
        const codepoint = tool.glyph && tool.glyph.codepoint;
        if (codepoint === 0xf044) tool.addCls('pm-esxi-tool-edit');
        if (codepoint === 0xf0e2) tool.addCls('pm-esxi-tool-reset');
    };
    if (Tool) {
        const afterRender = Tool.prototype.afterRender;
        Ext.override(Tool, {
            afterRender: function () {
                const result = afterRender.apply(this, arguments);
                markTool(this);
                return result;
            }
        });
        Ext.ComponentQuery.query('tool').forEach(markTool);
    }
    // Use the existing border-layout region; hiding it preserves tree selection
    // and width, and Ext JS manages its splitter and the reclaimed center space.
    let sidebar;
    function syncSidebar() {
        const active = getComputedStyle(document.documentElement)
            .getPropertyValue('--pm-esxi-active').trim() === '1';
        if (!sidebar && active) {
            // PVE's workspace is a viewport; PBS's main view is a plain container
            // with the viewport plugin, so fall back to the only west/north regions.
            const CQ = Ext.ComponentQuery;
            const west = CQ.query('viewport > [region=west]')[0] || CQ.query('[region=west]')[0];
            const header = CQ.query('viewport > [region=north]')[0] || CQ.query('[region=north]')[0];
            if (!west || !header || !west.rendered) return;
            // Set the guard before insert() can trigger another layout.
            sidebar = { west };
            const button = header.insert(0, {
                xtype: 'button', baseCls: 'x-btn', id: 'pm-esxi-tree-toggle',
                iconCls: 'fa fa-bars', width: 30, height: 30, margin: '0 8 0 0',
                tooltip: 'Hide resource tree', ariaLabel: 'Hide resource tree',
                handler: function () {
                    west.setHidden(!west.hidden);
                    const label = west.hidden ? 'Show resource tree' : 'Hide resource tree';
                    this.setTooltip(label);
                    this.getEl().set({ 'aria-label': label, 'aria-expanded': String(!west.hidden) });
                },
                listeners: { afterrender: function () {
                    this.getEl().set({ 'aria-controls': west.id, 'aria-expanded': 'true' });
                } }
            });
            sidebar.button = button;
            Ext.GlobalEvents.un('afterlayout', syncSidebar);
        }
        if (!sidebar?.button) return;
        sidebar.button.setVisible(active);
        if (!active && sidebar.west.hidden) {
            sidebar.west.show();
            sidebar.button.setTooltip('Hide resource tree');
            sidebar.button.getEl().set({ 'aria-label': 'Hide resource tree', 'aria-expanded': 'true' });
        }
    }
    Ext.onReady(function () {
        if (!sidebar && getComputedStyle(document.documentElement).getPropertyValue('--pm-esxi-active').trim() === '1') {
            Ext.GlobalEvents.on('afterlayout', syncSidebar);
            syncSidebar();
        }
    });
    // Collapsing the tree is a request for wider information and charts, not
    // more columns. Use one full-width column while hidden, then let the native
    // responsive layout regain control when the tree returns.
    if (window.Proxmox?.Utils?.updateColumnWidth) {
        const updateColumnWidth = Proxmox.Utils.updateColumnWidth;
        const originalLimits = new WeakMap();
        const expandedContainers = new WeakSet();
        Proxmox.Utils.updateColumnWidth = function (container) {
            const expanded = sidebar?.west.hidden && getComputedStyle(document.documentElement)
                .getPropertyValue('--pm-esxi-active').trim() === '1';
            if (!expanded && expandedContainers.has(container)) {
                container.items.each(function (item) {
                    if (!originalLimits.has(item)) return;
                    const saved = originalLimits.get(item);
                    item.setMaxWidth(saved.maxWidth);
                    item.setWidth(saved.width);
                    originalLimits.delete(item);
                });
                container.oldFactor = undefined;
                expandedContainers.delete(container);
            }
            const result = updateColumnWidth.apply(this, arguments);
            if (!expanded || !container.rendered) return result;
            const el = container.getEl().dom;
            const inner = el.querySelector(':scope > .x-autocontainer-outerCt > .x-autocontainer-innerCt') || el;
            const style = getComputedStyle(inner);
            const width = Math.floor(inner.getBoundingClientRect().width
                - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight)
                - parseFloat(style.borderLeftWidth) - parseFloat(style.borderRightWidth));
            expandedContainers.add(container);
            Ext.suspendLayouts();
            try {
                container.items.each(function (item) {
                    if (!item.columnWidth) return;
                    if (!originalLimits.has(item)) originalLimits.set(item, {maxWidth: item.maxWidth, width: item.width});
                    item.columnWidth = 1;
                    item.setMaxWidth(width);
                    item.setWidth(width);
                });
                container.updateLayout();
            } finally {
                Ext.resumeLayouts(true);
            }
            return result;
        };
    }
    const className = 'Proxmox.widget.RRDChart';
    function install() {
        const Chart = Ext.ClassManager.get(className);
        if (!Chart || typeof Chart.prototype.checkThemeColors !== 'function') return;
        window.ProxmorphESXiChartsLoaded = true;
        const original = Chart.prototype.checkThemeColors;
        const palettes = new WeakMap();
        Ext.override(Chart, {
            checkThemeColors: function () {
                syncSidebar();
                const style = getComputedStyle(document.documentElement);
                const active = style.getPropertyValue('--pm-esxi-active').trim() === '1';
                if (active) {
                    const colors = Array.from({length: 6}, (_, i) =>
                        style.getPropertyValue('--pm-chart-' + (i + 1)).trim());
                    if (colors.every(Boolean)) {
                        if (!palettes.has(this)) palettes.set(this, this.getColors().slice());
                        this.setColors(colors);
                    }
                } else if (palettes.has(this)) {
                    this.setColors(palettes.get(this));
                    palettes.delete(this);
                }
                // The native method owns axes, grid, background and redraw.
                return original.apply(this, arguments);
            }
        });
        // Covers script injection after charts have already rendered.
        Ext.ComponentQuery.query('proxmoxRRDChart').forEach(chart => chart.checkThemeColors());
    }
    if (Ext.ClassManager.get(className)) install();
    else Ext.ClassManager.onCreated(install, null, className);
})();
