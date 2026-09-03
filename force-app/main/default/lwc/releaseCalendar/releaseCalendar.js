import { LightningElement, track } from 'lwc';
import getEvents from '@salesforce/apex/ReleaseCalendarController.getEvents';
import getYearBounds from '@salesforce/apex/ReleaseCalendarController.getYearBounds';

const COLORS = {
    Mosaic:   '#9bbb59',
    Blackout: '#ff0000',
    Seasonal: '#95b3d7'
};
const PRIORITY = ['Blackout', 'Seasonal', 'Mosaic'];
const DOW = ['S','M','T','W','T','F','S']; // static header

export default class ReleaseCalendar extends LightningElement {
    @track year = new Date().getUTCFullYear();
    @track months = [];
    @track yearOptions = [];

    _byDate = new Map();
    _boundsLoaded = false;

    get yearString() { return String(this.year); }
    get dowLabels()  { return DOW.map((l,i)=>({ id:i, label:l })); }

    connectedCallback() { this.init(); }

    async init() {
        if (!this._boundsLoaded) {
            try {
                const { minYear, maxYear } = await getYearBounds();
                const buf = 1;
                const startY = Math.min(minYear ?? this.year, this.year);
                const endY   = Math.max(maxYear ?? this.year, this.year) + buf;
                const opts = [];
                for (let y = startY; y <= endY; y++) {
                    opts.push({ label: String(y), value: String(y) });
                }
                this.yearOptions = opts;
                this._boundsLoaded = true;
            } catch (e) {
                const base = new Date().getUTCFullYear();
                this.yearOptions = Array.from({ length: 7 }, (_, i) => {
                    const y = base - 1 + i;
                    return { label: String(y), value: String(y) };
                });
            }
        }
        await this.load();
    }

    onYearChange(e) {
        this.year = parseInt(e.detail.value, 10);
        this.load();
    }

    async load() {
        const events = await getEvents({ year: this.year });

        // Build a per-day map in UTC
        const byDate = new Map();
        for (const e of events) {
            const sUTC = strToUtcDate(e.startDate);                                   // Date (UTC)
            const eUTC = strToUtcDate(e.endDate || e.startDate);
            for (let d = new Date(sUTC.getTime()); d.getTime() <= eUTC.getTime(); d = addUtcDays(d, 1)) {
                const iso = ymdFromUtc(d);                                            // 'YYYY-MM-DD'
                const entry = { type: e.type, color: pickColor(e.type), desc: e.description || '' };
                if (!byDate.has(iso) || higherPriority(entry, byDate.get(iso))) {
                    byDate.set(iso, entry);
                }
            }
        }
        this._byDate = byDate;
        this.months = this.buildMonths(byDate);
    }

    buildMonths(byDate) {
        const months = [];
        for (let m = 0; m < 12; m++) {
            const firstUTC = new Date(Date.UTC(this.year, m, 1));
            const label = firstUTC.toLocaleString('default', { month: 'long' });
            const daysInMonth = new Date(Date.UTC(this.year, m + 1, 0)).getUTCDate();

            // blanks until the first day-of-week (UTC)
            const startDow = firstUTC.getUTCDay(); // 0..6, Sun..Sat
            const cells = [];
            for (let i = 0; i < startDow; i++) cells.push({ key: `b${m}-${i}`, text: '', className: 'blank' });

            for (let day = 1; day <= daysInMonth; day++) {
                const dUTC = new Date(Date.UTC(this.year, m, day));
                const iso  = ymdFromUtc(dUTC);
                const evt  = byDate.get(iso);

                cells.push({
                    key: iso,
                    text: String(day),
                    className: 'day' + (evt ? ' has-event' : ''),
                    style: evt ? `background:${evt.color};` : '',
                    tooltip: evt ? `${evt.type}${evt.desc ? ' — ' + evt.desc : ''}` : ''
                });
            }
            months.push({ index: m, label, cells });
        }
        return months;
    }
}

/* ---------- helpers (UTC-safe) ---------- */
function strToUtcDate(yyyyMmDd) {
    // '2025-08-01' -> Date at UTC midnight (no TZ shift)
    const [y, m, d] = yyyyMmDd.split('-').map(Number);
    return new Date(Date.UTC(y, m - 1, d));
}
function addUtcDays(dateUtc, n) {
    const d = new Date(dateUtc.getTime());
    d.setUTCDate(d.getUTCDate() + n);
    return d;
}
function ymdFromUtc(dateUtc) {
    const y = dateUtc.getUTCFullYear();
    const m = String(dateUtc.getUTCMonth() + 1).padStart(2, '0');
    const d = String(dateUtc.getUTCDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
}
function pickColor(type) {
    if (!type) return '';
    const t = type.toLowerCase();
    if (t.includes('blackout')) return COLORS.Blackout;
    if (t.includes('seasonal')) return COLORS.Seasonal;
    return COLORS.Mosaic;
}
function higherPriority(a, b) {
    const ia = PRIORITY.findIndex(p => a.type && a.type.toLowerCase().includes(p.toLowerCase()));
    const ib = PRIORITY.findIndex(p => b.type && b.type.toLowerCase().includes(p.toLowerCase()));
    return (ia !== -1 ? ia : 99) < (ib !== -1 ? ib : 99);
}