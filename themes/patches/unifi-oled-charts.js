/**
 * ProxMorph Chart Patcher (UniFi OLED)
 * Applies custom colors to Proxmox RRD charts
 *
 * Features:
 *   - Custom UniFi OLED color palette for chart lines/areas
 *   - Special handling for Network Traffic (blue/green layering)
 *   - Subtle white border on hover dots for visibility
 *
 * Color Palette:
 *   Primary:   #30AD55 (UniFi green)
 *   Secondary: #1E85FF (UniFi OLED blue)
 *   Tertiary:  #5DC0E0 (Cyan/teal)
 *   Warning:   #D08D1E (Amber/orange)
 *   Critical:  #CC3135 (Red)
 */

(function () {
    'use strict';

    const PROXMORPH_CHART_COLORS = [
        '#30AD55',  // UniFi green (PRIMARY)
        '#1E85FF',  // UniFi blue (SECONDARY)
        '#5DC0E0',  // UniFi cyan/teal
        '#D08D1E',  // UniFi amber/orange
        '#CC3135',  // UniFi red
        '#4797FF',  // UniFi light blue
    ];

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
                chart.setColors(['#1E85FF', '#30AD55']);
                series.forEach((s, idx) => {
                    if (idx === 0) {
                        // Incoming - Blue area (bottom)
                        s.setStyle({
                            fillStyle: 'rgba(30, 133, 255, 0.7)',
                            strokeStyle: '#1E85FF',
                            lineWidth: 2
                        });
                    } else if (idx === 1) {
                        // Outgoing - Green area (top)
                        s.setStyle({
                            fillStyle: 'rgba(48, 173, 85, 0.8)',
                            strokeStyle: '#30AD55',
                            lineWidth: 2
                        });
                    }
                    // Add subtle white border to hover dots
                    s.setHighlight({
                        opacity: 1,
                        scaling: 1.5,
                        strokeStyle: '#FFFFFF',
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
                    // Add subtle white border to hover dots
                    s.setHighlight({
                        opacity: 1,
                        scaling: 1.5,
                        strokeStyle: '#FFFFFF',
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
     * Check if UniFi theme is active
     */
    function isUnifiThemeActive() {
        // Check for the presence of the UniFi theme stylesheet
        return !!document.querySelector('link[href*="theme-unifi-oled.css"]')
            // UniFi OLED (Auto) imports this theme while the OS prefers a dark scheme
            || (!!document.querySelector('link[href*="theme-unifi-oled-auto.css"]')
                && window.matchMedia('(prefers-color-scheme: dark)').matches);
    }

    /**
     * Find and patch all RRD charts on the page
     */
    function patchAllCharts() {
        // Only patch if UniFi theme is active
        if (!isUnifiThemeActive()) return;

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

        console.log('[ProxMorph] Chart patcher initialized');
    }

    // Start initialization
    init();

})();
