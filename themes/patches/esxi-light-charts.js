/* ProxMorph ESXi Light 1.1.3. Native RRD palette, vector tools and resource-tree toggle, no polling or API calls. */
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
            const west = Ext.ComponentQuery.query('viewport > [region=west]')[0];
            const header = Ext.getCmp('userinfo')?.ownerCt;
            if (!west || !header || !west.rendered) return;
            // Set the guard before insert() can trigger another layout.
            sidebar = { west };
            const button = header.insert(0, {
                xtype: 'button', baseCls: 'x-btn', id: 'pm-esxi-tree-toggle',
                iconCls: 'fa fa-bars', margin: '0 8 0 0',
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
