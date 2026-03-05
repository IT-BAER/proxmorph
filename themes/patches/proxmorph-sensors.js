/**
 * ProxMorph Hardware Sensors
 * Adds hardware sensor monitoring to the Proxmox VE node status panel.
 * Displays CPU, NVMe, HDD temperatures, fan speeds, and UPS status
 * in a compact single-row layout.
 *
 * Requires:
 *   - lm-sensors installed on the Proxmox host
 *   - Nodes.pm patched to expose sensor data via API
 *   - Enabled via ProxMorph installer (--sensors flag)
 *
 * Data flow:
 *   1. Nodes.pm runs `sensors -j` and exposes sensorsOutput in API
 *   2. PVE.node.StatusView fetches /api2/json/nodes/{node}/status
 *   3. Our override injects a single "Sensors" item reading that field
 *   4. Combined renderer parses JSON and produces compact themed HTML
 *
 * Supports:
 *   - Intel (coretemp-isa-*) and AMD (k10temp-pci-*) CPU temperatures
 *   - NVMe drive temperatures (nvme-pci-*)
 *   - HDD/SATA drive temperatures (drivetemp-scsi-*)
 *   - Fan speeds (recursive detection of fan*_input keys)
 *   - UPS status via NUT (upsc) — optional, shown inline when present
 *
 * Version: 1.1.0
 */
(function () {
    'use strict';

    // ─── Configuration ─────────────────────────────────────────────
    var SENSOR_UNIT = 'C'; // 'C' or 'F'

    // ─── CSS Variable Reader ───────────────────────────────────────
    function getThemeColors() {
        var cs = getComputedStyle(document.documentElement);
        return {
            text:    cs.getPropertyValue('--pm-text').trim()    || '#e5e7eb',
            textDim: cs.getPropertyValue('--pm-text-dim').trim() || '#9ca3af',
            warning: cs.getPropertyValue('--pm-warning').trim() || '#f5a623',
            error:   cs.getPropertyValue('--pm-error').trim()   || '#f03a3e',
            success: cs.getPropertyValue('--pm-success').trim() || '#37be5f',
            accent:  cs.getPropertyValue('--pm-accent').trim()  || '#006eff'
        };
    }

    // ─── Temperature Helpers ───────────────────────────────────────
    function formatTemp(celsius) {
        if (celsius === null || celsius === undefined || isNaN(celsius)) return '—';
        var val = SENSOR_UNIT === 'F' ? (celsius * 9 / 5) + 32 : celsius;
        return Ext.util.Format.number(val, '0.#') + '°' + SENSOR_UNIT;
    }

    function tempColor(temp, max, crit, colors) {
        if (crit !== null && temp >= crit) return colors.error;
        if (max !== null && temp >= max)  return colors.warning;
        return colors.text;
    }

    // ─── JSON Parser ───────────────────────────────────────────────
    function parseSensorsJSON(raw) {
        if (!raw || typeof raw !== 'string') return null;
        try {
            var cleaned = raw
                .replace(/,(\s*[}\]])/g, '$1')
                .replace(/\bNaN\b/g, 'null')
                .replace(/\bERROR\b[^\n]*/g, '');
            return JSON.parse(cleaned);
        } catch (e) {
            console.warn('[ProxMorph Sensors] JSON parse error:', e.message);
            return null;
        }
    }

    // ─── Inline HTML Helpers ───────────────────────────────────────
    function tag(text, color, bold) {
        var s = 'color:' + color + ';';
        if (bold) s += 'font-weight:600;';
        return '<span style="' + s + '">' + text + '</span>';
    }

    function sep(colors) {
        return '<span style="color:' + colors.textDim + ';opacity:0.4;margin:0 6px;">|</span>';
    }

    // ─── Combined Sensors Renderer ─────────────────────────────────
    // Produces a compact single-line output: CPU | NVMe | Fan
    // Only sections with data are shown — no "No X detected" clutter.
    function renderSensors(value) {
        var data = parseSensorsJSON(value);
        var colors = getThemeColors();
        if (!data) return tag('N/A', colors.textDim);

        var sections = [];

        // ── CPU Temperature ─────────────────────────────────────
        var cpuChips = Object.keys(data).filter(function (k) {
            return k.indexOf('coretemp-isa-') === 0 ||
                   k.indexOf('k10temp-pci-')  === 0;
        });

        cpuChips.forEach(function (chipKey) {
            var chip = data[chipKey];
            var pkgTemp = null, pkgMax = null, pkgCrit = null;
            var coreTemps = [];

            Object.keys(chip).forEach(function (label) {
                if (label === 'Adapter') return;
                var sensor = chip[label];
                if (!sensor || typeof sensor !== 'object') return;

                var inputKey = null, maxKey = null, critKey = null;
                Object.keys(sensor).forEach(function (k) {
                    if (/^temp\d+_input$/.test(k))     inputKey = k;
                    else if (/^temp\d+_max$/.test(k))  maxKey = k;
                    else if (/^temp\d+_crit$/.test(k)) critKey = k;
                });
                if (!inputKey) return;

                var temp = sensor[inputKey];
                if (temp === null || temp === undefined) return;

                if (/Package|Tctl|Tdie/i.test(label)) {
                    pkgTemp = temp;
                    pkgMax  = maxKey  ? sensor[maxKey]  : null;
                    pkgCrit = critKey ? sensor[critKey] : null;
                } else {
                    coreTemps.push({
                        temp: temp,
                        max:  maxKey  ? sensor[maxKey]  : null,
                        crit: critKey ? sensor[critKey] : null
                    });
                }
            });

            if (pkgTemp !== null) {
                var color = tempColor(pkgTemp, pkgMax, pkgCrit, colors);
                var txt = 'CPU: ' + formatTemp(pkgTemp);
                if (coreTemps.length > 0) txt += ' (' + coreTemps.length + ' cores)';
                sections.push(tag(txt, color));
            } else if (coreTemps.length > 0) {
                var maxT = Math.max.apply(null, coreTemps.map(function (c) { return c.temp; }));
                var color = tempColor(maxT, 80, 95, colors);
                sections.push(tag('CPU: ' + formatTemp(maxT) + ' peak (' + coreTemps.length + ' cores)', color));
            }
        });

        // ── NVMe Temperature (composite only) ───────────────────
        var nvmeKeys = Object.keys(data).filter(function (k) {
            return k.indexOf('nvme-pci-') === 0;
        });
        nvmeKeys.forEach(function (chipKey, idx) {
            var chip = data[chipKey];
            var compositeTemp = null, compMax = null, compCrit = null;

            Object.keys(chip).forEach(function (label) {
                if (label !== 'Composite') return;
                var sensor = chip[label];
                if (!sensor || typeof sensor !== 'object') return;

                Object.keys(sensor).forEach(function (k) {
                    if (/^temp\d+_input$/.test(k) && compositeTemp === null) {
                        compositeTemp = sensor[k];
                    }
                    if (/^temp\d+_max$/.test(k)) {
                        var m = sensor[k];
                        if (m !== null && m < 200) compMax = m;
                    }
                    if (/^temp\d+_crit$/.test(k)) compCrit = sensor[k];
                });
            });

            if (compositeTemp !== null) {
                var color = tempColor(compositeTemp, compMax || 70, compCrit || 80, colors);
                var lbl = nvmeKeys.length > 1 ? 'NVMe' + idx : 'NVMe';
                sections.push(tag(lbl + ': ' + formatTemp(compositeTemp), color));
            }
        });

        // ── SATA/HDD Temperature ────────────────────────────────
        var hddKeys = Object.keys(data).filter(function (k) {
            return k.indexOf('drivetemp-scsi-') === 0;
        });
        hddKeys.forEach(function (chipKey, idx) {
            var chip = data[chipKey];
            Object.keys(chip).forEach(function (label) {
                if (label === 'Adapter') return;
                var sensor = chip[label];
                if (!sensor || typeof sensor !== 'object') return;

                var inputKey = null;
                Object.keys(sensor).forEach(function (k) {
                    if (/^temp\d+_input$/.test(k)) inputKey = k;
                });
                if (!inputKey) return;

                var temp = sensor[inputKey];
                if (temp !== null && temp !== undefined) {
                    var color = tempColor(temp, 45, 55, colors);
                    var lbl = hddKeys.length > 1 ? 'HDD' + idx : 'HDD';
                    sections.push(tag(lbl + ': ' + formatTemp(temp), color));
                }
            });
        });

        // ── Fan Speeds ──────────────────────────────────────────
        var fans = [];
        function findFans(obj, parentLabel) {
            if (!obj || typeof obj !== 'object') return;
            Object.keys(obj).forEach(function (key) {
                if (/^fan\d+_input$/.test(key)) {
                    fans.push({
                        label: parentLabel || key.replace('_input', ''),
                        rpm: obj[key]
                    });
                } else if (typeof obj[key] === 'object' && key !== 'Adapter') {
                    findFans(obj[key], key);
                }
            });
        }
        Object.keys(data).forEach(function (chipKey) {
            findFans(data[chipKey], '');
        });

        if (fans.length > 0) {
            fans.forEach(function (fan) {
                var rpm = fan.rpm || 0;
                var color = rpm === 0 ? colors.warning : colors.text;
                sections.push(tag(fan.label + ': ' + rpm + ' RPM', color));
            });
        }

        // ── Join all sections ───────────────────────────────────
        if (sections.length === 0) return tag('No sensors detected', colors.textDim);
        return sections.join(sep(colors));
    }

    // ─── UPS Renderer (compact inline) ─────────────────────────────
    function renderUps(value) {
        var colors = getThemeColors();
        if (!value || typeof value !== 'string' || value.trim() === '') {
            return '';
        }

        var fields = {};
        value.split('\n').forEach(function (line) {
            var idx = line.indexOf(':');
            if (idx > 0) {
                fields[line.substring(0, idx).trim()] = line.substring(idx + 1).trim();
            }
        });
        if (Object.keys(fields).length === 0) return '';

        var parts = [];

        // Status
        var status = fields['ups.status'] || '';
        var sColor = colors.success, sText = 'Online';
        if (status.indexOf('OB') !== -1) { sColor = colors.error;   sText = 'On Battery'; }
        else if (status.indexOf('LB') !== -1) { sColor = colors.error;   sText = 'Low Battery'; }
        else if (status.indexOf('CHRG') !== -1) { sColor = colors.warning; sText = 'Charging'; }
        else if (status.indexOf('OL') === -1 && status) { sColor = colors.warning; sText = status; }
        parts.push(tag(sText, sColor, true));

        // Battery
        var charge = parseFloat(fields['battery.charge']);
        if (!isNaN(charge)) {
            var cColor = charge < 20 ? colors.error : charge < 50 ? colors.warning : colors.success;
            parts.push(tag(charge + '%', cColor));
        }

        // Load
        var load = parseFloat(fields['ups.load']);
        if (!isNaN(load)) {
            var lColor = load > 80 ? colors.error : load > 60 ? colors.warning : colors.text;
            parts.push(tag('Load ' + load + '%', lColor));
        }

        // Runtime
        var runtime = parseFloat(fields['battery.runtime']);
        if (!isNaN(runtime)) {
            var mins = Math.floor(runtime / 60);
            var secs = Math.floor(runtime % 60);
            var rText = mins > 0 ? mins + 'm' : secs + 's';
            parts.push(tag(rText, mins < 5 ? colors.warning : colors.textDim));
        }

        return parts.join(sep(colors));
    }

    // ─── StatusView Override ───────────────────────────────────────
    function applyOverride() {
        if (typeof Ext === 'undefined' || !Ext.ClassManager) {
            setTimeout(applyOverride, 500);
            return;
        }

        var cls = Ext.ClassManager.get('PVE.node.StatusView');
        if (!cls) {
            setTimeout(applyOverride, 500);
            return;
        }

        var origInitComponent = cls.prototype.initComponent;

        cls.prototype.initComponent = function () {
            // Single compact sensor row — CPU + Storage + Fan inline
            var sensorItems = [
                {
                    itemId: 'sensors',
                    colspan: 2,
                    printBar: false,
                    title: gettext('Sensors'),
                    textField: 'sensorsOutput',
                    renderer: renderSensors
                }
            ];

            // Inject after 'cpus'
            if (Ext.isArray(this.items)) {
                var insertIdx = -1;
                for (var i = 0; i < this.items.length; i++) {
                    if (this.items[i].itemId === 'cpus') {
                        insertIdx = i + 1;
                        break;
                    }
                }

                if (insertIdx >= 0) {
                    Ext.Array.insert(this.items, insertIdx, sensorItems);
                } else {
                    this.items = this.items.concat(sensorItems);
                }
            }

            // Call original initComponent
            if (origInitComponent) {
                origInitComponent.apply(this, arguments);
            }

            // After render: conditionally add UPS row if data exists,
            // then trigger layout recalculation so the panel expands.
            var me = this;
            me.on('afterrender', function () {
                var store = me.getStore ? me.getStore() : null;
                if (!store) return;

                store.on('load', function (s, records) {
                    if (!records || !records.length) return;

                    // Hide sensor row entirely when API doesn't include sensorsOutput
                    var sensorWidget = me.down('#sensors');
                    if (sensorWidget) {
                        var hasSensorData = s.findRecord('key', 'sensorsOutput') !== null;
                        sensorWidget.setVisible(hasSensorData);
                    }

                    // Check for UPS data in the store
                    var upsRec = s.findRecord('key', 'upsData');
                    var upsData = upsRec ? upsRec.get('value') : null;

                    // Only inject UPS item once, and only if there is data
                    if (upsData && upsData.trim() !== '' && !me.down('#upsStatus')) {
                        me.add({
                            xtype: 'pmxInfoWidget',
                            itemId: 'upsStatus',
                            colspan: 2,
                            printBar: false,
                            title: gettext('UPS'),
                            iconCls: 'fa fa-fw fa-battery-half',
                            textField: 'upsData',
                            renderer: renderUps
                        });
                        me.updateLayout();
                    }

                    // Recalculate layout to accommodate sensor row
                    Ext.defer(function () {
                        me.updateLayout();
                        var parent = me.ownerCt;
                        if (parent && parent.updateLayout) {
                            parent.updateLayout();
                        }
                    }, 100);
                });
            });
        };

        console.log('[ProxMorph] Sensor widget initialized (v1.1.0)');
    }

    // ─── Init ──────────────────────────────────────────────────────
    function init() {
        try {
            applyOverride();
            window.ProxMorphSensors = { version: '1.1.0' };
        } catch (e) {
            console.error('[ProxMorph Sensors] Init error:', e);
        }
    }

    if (document.readyState === 'complete' || document.readyState === 'interactive') {
        init();
    } else {
        window.addEventListener('DOMContentLoaded', init);
    }

})();
