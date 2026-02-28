/**
 * ProxMorph Chart Patcher (UniFi Light)
 * Applies custom colors to Proxmox RRD charts for light theme
 *
 * Features:
 *   - Custom UniFi color palette for chart lines/areas
 *   - Special handling for Network Traffic (blue/green layering)
 *   - Dark border on hover dots for visibility on light backgrounds
 *
 * Color Palette (same as dark - UniFi uses identical colors):
 *   Primary:   #3ACC65 (UniFi green)
 *   Secondary: #006FFF (UniFi blue)
 *   Tertiary:  #5DC0E0 (Cyan/teal)
 *   Warning:   #F6B94F (Amber/orange)
 *   Critical:  #F36165 (Red)
 */

(function () {
    'use strict';

    const PROXMORPH_CHART_COLORS = [
        '#3ACC65',  // UniFi green (PRIMARY)
        '#006FFF',  // UniFi blue (SECONDARY)
        '#5DC0E0',  // UniFi cyan/teal
        '#F6B94F',  // UniFi amber/orange
        '#F36165',  // UniFi red
        '#4797FF',  // UniFi light blue
    ];

    // Hover dot stroke color - dark for visibility on light backgrounds
    const HOVER_STROKE_COLOR = '#1A1C21';

    /**
     * Apply custom colors to a single chart
     */
    function patchChart(chart) {
        if (!chart || !chart.getSeries) return;

        try {
            const series = chart.getSeries();
            if (!series || series.length === 0) return;

            // Special handling for Network Traffic chart to avoid color blending
            if (chart.title === 'Network Traffic') {
                // Swap colors: Blue (bottom layer), Green (top layer)
                chart.setColors(['#006FFF', '#3ACC65']);
                series.forEach((s, idx) => {
                    if (idx === 0) {
                        // Incoming - Blue area (bottom)
                        // Slightly lower opacity for light backgrounds
                        s.setStyle({
                            fillStyle: 'rgba(0, 111, 255, 0.4)',
                            strokeStyle: '#006FFF',
                            lineWidth: 2
                        });
                    } else if (idx === 1) {
                        // Outgoing - Green area (top)
                        s.setStyle({
                            fillStyle: 'rgba(58, 204, 101, 0.5)',
                            strokeStyle: '#3ACC65',
                            lineWidth: 2
                        });
                    }
                    // Add dark border to hover dots for visibility on light background
                    s.setHighlight({
                        opacity: 1,
                        scaling: 1.5,
                        strokeStyle: HOVER_STROKE_COLOR,
                        lineWidth: 1
                    });
                });
            } else {
                // Standard color application for all other charts
                chart.setColors(PROXMORPH_CHART_COLORS);
                series.forEach((s, idx) => {
                    const color = PROXMORPH_CHART_COLORS[idx % PROXMORPH_CHART_COLORS.length];
                    s.setStyle({
                        fillStyle: color,
                        strokeStyle: color
                    });
                    // Add dark border to hover dots for visibility on light background
                    s.setHighlight({
                        opacity: 1,
                        scaling: 1.5,
                        strokeStyle: HOVER_STROKE_COLOR,
                        lineWidth: 1
                    });
                });
            }

            chart.redraw();
        } catch (e) {
            console.warn('[ProxMorph] Chart patch error:', e);
        }
    }

    /**
     * Check if UniFi Light theme is active
     */
    function isUnifiLightThemeActive() {
        // Check for the presence of the UniFi Light theme stylesheet
        return !!document.querySelector('link[href*="theme-unifi-light.css"]');
    }

    /**
     * Find and patch all RRD charts on the page
     */
    function patchAllCharts() {
        // Only patch if UniFi Light theme is active
        if (!isUnifiLightThemeActive()) return;

        if (typeof Ext === 'undefined' || !Ext.ComponentQuery) return;

        const charts = Ext.ComponentQuery.query('proxmoxRRDChart');
        if (charts && charts.length > 0) {
            charts.forEach(patchChart);
        }
    }

    /**
     * Initialize the chart patcher with delayed start and periodic refresh
     */
    function init() {
        // Initial patch after page load
        if (document.readyState === 'complete') {
            setTimeout(patchAllCharts, 500);
        } else {
            window.addEventListener('load', function () {
                setTimeout(patchAllCharts, 500);
            });
        }

        // Periodic re-patch to catch dynamically loaded charts
        // Charts can be reloaded when switching views or refreshing data
        setInterval(patchAllCharts, 2000);

        console.log('[ProxMorph] UniFi Light chart patcher initialized');
    }

    // Start initialization
    init();

})();
