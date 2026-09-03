import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class MosaicDirectXlsDownloadBtn extends LightningElement {
  @api objectApiName;
  @api rows = [];
  @api allRows = [];
  @api manualFieldApiNames = [];
  @api manualFieldLabelNames = [];

  excludedFieldNames = new Set(["id", "orderid", "pmc_cpq_orderproduct__r.orderid"]);

  @track isLoading = false;
  _waitingForParent = false;

  showLoadingOverlay() {
    try {
      if (document.getElementById("mosaic-xls-download-overlay")) return;
      const overlay = document.createElement("div");
      overlay.id = "mosaic-xls-download-overlay";
      overlay.setAttribute(
        "style",
        "position:fixed;left:0;top:0;width:100%;height:100%;background:rgba(0,0,0,0.35);display:flex;align-items:center;justify-content:center;z-index:99999;"
      );

      overlay.innerHTML = `
        <div style="display:flex;align-items:center;justify-content:center;width:100%;height:100%;">
          <div style="display:flex;gap:8px;align-items:center;justify-content:center;">
            <div class=\"mosaic-dot\"></div>
            <div class=\"mosaic-dot\"></div>
            <div class=\"mosaic-dot\"></div>
            <div class=\"mosaic-dot\"></div>
          </div>
        </div>
        <style id="mosaic-xls-download-overlay-style">.mosaic-dot{width:10px;height:10px;background:#ffffff;border-radius:50%;opacity:0.85;transform:scale(0.8);animation:mosaicDots 1s infinite ease-in-out;}@keyframes mosaicDots{0%{transform:translateY(0) scale(0.8);opacity:0.5}25%{transform:translateY(-6px) scale(1);opacity:1}50%{transform:translateY(0) scale(0.9);opacity:0.8}75%{transform:translateY(-3px) scale(0.95);opacity:0.95}100%{transform:translateY(0) scale(0.8);opacity:0.5}}.mosaic-dot:nth-child(1){animation-delay:0s}.mosaic-dot:nth-child(2){animation-delay:0.12s}.mosaic-dot:nth-child(3){animation-delay:0.24s}.mosaic-dot:nth-child(4){animation-delay:0.36s}</style>
      `;

      document.body.appendChild(overlay);
    } catch (e) {
      // ignore DOM errors
    }
  }

  hideLoadingOverlay() {
    try {
      const el = document.getElementById("mosaic-xls-download-overlay");
      if (el) el.remove();
      const s = document.getElementById("mosaic-xls-download-overlay-style");
      if (s) s.remove();
    } catch (e) {
      // ignore
    }
  }

  stopGlobalLoader() {
    try {
      this.dispatchEvent(new CustomEvent('loadingEvent', { bubbles: true, composed: true, detail: { action: 'stop' } }));
    } catch (e) {
      // ignore
    }
    try {
      this.hideLoadingOverlay();
    } catch (e) {
      // ignore
    }
  }

  parseList(value) {
    if (!value && value !== 0) return [];
    if (Array.isArray(value)) return value;
    if (typeof value === "string") {
      const s = value.trim();
      if (!s) return [];

      const looksLikeJson = (s.startsWith("[") && s.endsWith("]")) || (s.startsWith("{") && s.endsWith("}"));
      if (looksLikeJson) {
        const parsed = JSON.parse(s);
        if (Array.isArray(parsed)) return parsed.map((v) => String(v));
      }

      const out = [];
      let cur = "";
      let inQuotes = false;
      for (let i = 0; i < s.length; i++) {
        const ch = s[i];
        if (ch === '"') {
          if (inQuotes && s[i + 1] === '"') {
            cur += '"';
            i++;
          } else {
            inQuotes = !inQuotes;
          }
          continue;
        }
        if ((ch === "," || ch === ";") && !inQuotes) {
          const trimmed = cur.trim();
          if (trimmed) out.push(trimmed);
          cur = "";
        } else {
          cur += ch;
        }
      }
      const last = cur.trim();
      if (last) out.push(last);
      return out;
    }
    return [];
  }

  escapeHtml(value) {
    return String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
  }

  normalizeCellValue(value) {
    if (value === null || value === undefined) return "";
    if (typeof value === "object") {
      try {
        return JSON.stringify(value);
      } catch {
        return String(value);
      }
    }
    return String(value);
  }

  isExcludedColumn(fieldName, label) {
    const normalizedFieldName = String(fieldName || "")
      .trim()
      .toLowerCase();
    const normalizedLabel = String(label || "")
      .trim()
      .toLowerCase();

    return this.excludedFieldNames.has(normalizedFieldName) || this.excludedFieldNames.has(normalizedLabel);
  }

  isTextColumn(fieldName, label) {
    const normalizedFieldName = String(fieldName || "")
      .trim()
      .toLowerCase();
    const normalizedLabel = String(label || "")
      .trim()
      .toLowerCase();

    if (normalizedLabel === "order number") return true;
    if (normalizedFieldName.endsWith(".ordernumber")) return true;
    if (normalizedFieldName.includes("sapordernumber")) return true;
    // also treat fields that contain both 'order' and 'number' or 'item' as text
    if (normalizedFieldName.includes("order") && (normalizedFieldName.includes("number") || normalizedFieldName.includes("item") || normalizedFieldName.includes("orderitem") || normalizedFieldName.includes("ordernumber"))) return true;
    return false;
  }

  getCellAttributes(column = {}) {
    if (!this.isTextColumn(column.fieldName, column.label)) return "";
    return " style=\"mso-number-format:'\\@'\"";
  }

  resolveExportColumns() {
    const fieldApiNames = this.parseList(this.manualFieldApiNames).filter(Boolean);
    const labelNames = this.parseList(this.manualFieldLabelNames);

    if (fieldApiNames.length) {
      return fieldApiNames.reduce((columns, fieldName, index) => {
        const label = labelNames[index] || fieldName;
        if (this.isExcludedColumn(fieldName, label)) return columns;

        columns.push({
          fieldName,
          label
        });
        return columns;
      }, []);
    }

    const firstRow = Array.isArray(this.allRows) && this.allRows.length
      ? this.allRows[0]
      : (Array.isArray(this.rows) && this.rows.length ? this.rows[0] : null);
    if (!firstRow) return [];

    return Object.keys(firstRow)
      .filter((key) => !this.isExcludedColumn(key, key) && !key.startsWith("__"))
      .map((fieldName) => ({ fieldName, label: fieldName }));
  }

  xmlEscape(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&apos;");
  }

  colIndexToLetter(index) {
    let s = "";
    while (index >= 0) {
      s = String.fromCharCode((index % 26) + 65) + s;
      index = Math.floor(index / 26) - 1;
    }
    return s;
  }

  getExportOrderValue(row = {}, columns = []) {
    try {
      const exportField = 'export_order_number';
      if (row && row[exportField]) return this.normalizeCellValue(row[exportField]);

      if (!Array.isArray(columns) || !columns.length) return "";

      const lower = (s) => String(s || "").toLowerCase();

      const orderCol = columns.find((c) => {
        const lf = lower(c.label);
        const fn = lower(c.fieldName);
        if (lf === 'order' || lf === 'order number') return true;
        if (fn.endsWith('.ordernumber')) return true;
        if (fn.includes('sapordernumber')) return true;
        if (fn.includes('order') && (fn.includes('number') || fn.includes('orderitem'))) return true;
        return false;
      });

      const orderItemCol = columns.find((c) => {
        const lf = lower(c.label);
        const fn = lower(c.fieldName);
        return lf === 'order item' || fn.includes('orderitem');
      });

      const getValueByPath = (obj, path) => {
        if (!obj || !path) return undefined;
        if (Object.prototype.hasOwnProperty.call(obj, path)) return obj[path];
        const parts = path.split('.');
        let cur = obj;
        for (const p of parts) {
          if (cur === null || cur === undefined) return undefined;
          if (!Object.prototype.hasOwnProperty.call(cur, p)) return undefined;
          cur = cur[p];
        }
        return cur;
      };

      const orderVal = orderCol ? getValueByPath(row, orderCol.fieldName) : undefined;
      const itemVal = orderItemCol ? getValueByPath(row, orderItemCol.fieldName) : undefined;

      const ov = orderVal === null || orderVal === undefined ? '' : String(orderVal).trim();
      const ivRaw = itemVal === null || itemVal === undefined ? '' : String(itemVal).trim();
      const iv = ivRaw ? ivRaw.padStart(4, '0') : '';

      if (!ov && !iv) return "";
      return this.normalizeCellValue(`${ov}${iv}`);
    } catch (e) {
      return "";
    }
  }

  buildSheetXml(columns, rows) {
    const rowsXml = [];
    // header row
    const headerCells = columns.map((c, ci) => {
      const addr = `${this.colIndexToLetter(ci)}1`;
      return `<c r="${addr}" t="inlineStr"><is><t>${this.xmlEscape(c.label)}</t></is></c>`;
    });
    rowsXml.push(`<row r="1">${headerCells.join("")}</row>`);

    for (let r = 0; r < rows.length; r++) {
      const rowIndex = r + 2; // data starts at row 2
      const cells = [];
      for (let c = 0; c < columns.length; c++) {
        const col = columns[c];
        
        const isOrderLabel = String(col.label || '').toLowerCase() === 'order number' || String(col.fieldName || '') === 'export_order_number';
        let raw = rows[r]?.[col.fieldName];
        let val;
        if (isOrderLabel) {
          val = this.getExportOrderValue(rows[r], columns);
          raw = val;
        } else {
          val = this.normalizeCellValue(raw);
        }
        const addr = `${this.colIndexToLetter(c)}${rowIndex}`;

        const forceText = this.isTextColumn(col.fieldName, col.label);

        const isNumber = !forceText && (typeof raw === 'number' || (!isNaN(val) && val !== '' && String(raw).trim() === String(Number(val))));
        if (isNumber) {
          cells.push(`<c r="${addr}"><v>${val}</v></c>`);
        } else if (forceText) {
        
          const escapedVal = this.xmlEscape(val);
          const attr = this.getCellAttributes(col) || "";
          cells.push(`<c r="${addr}"${attr} t="inlineStr"><is><t>${escapedVal}</t></is></c>`);
        } else {
          cells.push(`<c r="${addr}" t="inlineStr"><is><t>${this.xmlEscape(val)}</t></is></c>`);
        }
      }
      rowsXml.push(`<row r="${rowIndex}">${cells.join("")}</row>`);
    }

    return `<?xml version="1.0" encoding="UTF-8"?>\n<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">\n  <sheetData>\n    ${rowsXml.join("\n    ")}\n  </sheetData>\n</worksheet>`;
  }

  buildWorkbookXml() {
    return `<?xml version="1.0" encoding="UTF-8"?>\n<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\n  <sheets>\n    <sheet name="Sheet1" sheetId="1" r:id="rId1"/>\n  </sheets>\n</workbook>`;
  }
  buildRelsRels() {
    return `<?xml version="1.0" encoding="UTF-8"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>\n</Relationships>`;
  }

  buildWorkbookRels() {
    return `<?xml version="1.0" encoding="UTF-8"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>\n</Relationships>`;
  }

  buildContentTypes() {
    return `<?xml version="1.0" encoding="UTF-8"?>\n<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n  <Default Extension="xml" ContentType="application/xml"/>\n  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>\n  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>\n</Types>`;
  }

  crc32Table() {
    const table = new Uint32Array(256);
    for (let i = 0; i < 256; i++) {
      let c = i;
      for (let k = 0; k < 8; k++) c = (c & 1) ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      table[i] = c >>> 0;
    }
    return table;
  }

  crc32(buf) {
    const table = this._crc32Table || (this._crc32Table = this.crc32Table());
    let crc = 0xffffffff;
    for (let i = 0; i < buf.length; i++) crc = (table[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8)) >>> 0;
    return (crc ^ 0xffffffff) >>> 0;
  }

  strToU8(s) {
    return new TextEncoder().encode(s);
  }

  u32ToLE(n) {
    const b = new Uint8Array(4);
    b[0] = n & 0xff;
    b[1] = (n >>> 8) & 0xff;
    b[2] = (n >>> 16) & 0xff;
    b[3] = (n >>> 24) & 0xff;
    return b;
  }

  u16ToLE(n) {
    const b = new Uint8Array(2);
    b[0] = n & 0xff;
    b[1] = (n >>> 8) & 0xff;
    return b;
  }

  makeZip(files) {
    const localParts = [];
    const centralParts = [];
    let offset = 0;
    for (const f of files) {
      const nameU8 = this.strToU8(f.name);
      const dataU8 = f.data instanceof Uint8Array ? f.data : this.strToU8(f.data);
      const crc = this.crc32(dataU8);
      const compSize = dataU8.length;
      const uncompSize = dataU8.length;

      // local file header
      const lh = new Uint8Array(30 + nameU8.length);
      // signature
      lh.set([0x50,0x4b,0x03,0x04],0);
      // version needed (2)
      lh.set(this.u16ToLE(20),4);
      // gp bit flag (2)
      lh.set(this.u16ToLE(0),6);
      // compression (2)
      lh.set(this.u16ToLE(0),8);
      // mod time/date (4)
      lh.set(this.u16ToLE(0),10);
      lh.set(this.u16ToLE(0),12);
      // crc32
      lh.set(this.u32ToLE(crc),14);
      // comp size
      lh.set(this.u32ToLE(compSize),18);
      // uncomp size
      lh.set(this.u32ToLE(uncompSize),22);
      // name len
      lh.set(this.u16ToLE(nameU8.length),26);
      // extra len
      lh.set(this.u16ToLE(0),28);
      // name
      lh.set(nameU8,30);

      localParts.push(lh);
      localParts.push(dataU8);

      // central directory header
      const ch = new Uint8Array(46 + nameU8.length);
      ch.set([0x50,0x4b,0x01,0x02],0);
      // version made by
      ch.set(this.u16ToLE(20),4);
      // version needed
      ch.set(this.u16ToLE(20),6);
      // gp flag
      ch.set(this.u16ToLE(0),8);
      // compression
      ch.set(this.u16ToLE(0),10);
      // mod time/date
      ch.set(this.u16ToLE(0),12);
      ch.set(this.u16ToLE(0),14);
      // crc
      ch.set(this.u32ToLE(crc),16);
      // comp size
      ch.set(this.u32ToLE(compSize),20);
      // uncomp size
      ch.set(this.u32ToLE(uncompSize),24);
      // name len
      ch.set(this.u16ToLE(nameU8.length),28);
      // extra len
      ch.set(this.u16ToLE(0),30);
      // comment len
      ch.set(this.u16ToLE(0),32);
      // disk number start
      ch.set(this.u16ToLE(0),34);
      // internal attrs
      ch.set(this.u16ToLE(0),36);
      // external attrs
      ch.set(this.u32ToLE(0),38);
      // relative offset
      ch.set(this.u32ToLE(offset),42);
      // name
      ch.set(nameU8,46);

      centralParts.push(ch);

      offset += lh.length + dataU8.length;
    }

    // end of central dir
    let centralSize = 0;
    for (const p of centralParts) centralSize += p.length;
    let centralOffset = offset;

    const eocd = new Uint8Array(22);
    eocd.set([0x50,0x4b,0x05,0x06],0);
    // disk numbers
    eocd.set(this.u16ToLE(0),4);
    eocd.set(this.u16ToLE(0),6);
    // entries this disk
    eocd.set(this.u16ToLE(centralParts.length),8);
    // total entries
    eocd.set(this.u16ToLE(centralParts.length),10);
    // size of central dir
    eocd.set(this.u32ToLE(centralSize),12);
    // offset of central dir
    eocd.set(this.u32ToLE(centralOffset),16);
    // comment len
    eocd.set(this.u16ToLE(0),20);

    // concat all parts
    const parts = [...localParts, ...centralParts, eocd];
    let total = 0;
    for (const p of parts) total += p.length;
    const out = new Uint8Array(total);
    let pos = 0;
    for (const p of parts) {
      out.set(p, pos);
      pos += p.length;
    }
    return out;
  }

  buildXlsxBlob(columns, rows) {
    const files = [
      { name: '[Content_Types].xml', data: this.buildContentTypes() },
      { name: '_rels/.rels', data: this.buildRelsRels() },
      { name: 'xl/workbook.xml', data: this.buildWorkbookXml() },
      { name: 'xl/_rels/workbook.xml.rels', data: this.buildWorkbookRels() },
      { name: 'xl/worksheets/sheet1.xml', data: this.buildSheetXml(columns, rows) }
    ];

    const zipU8 = this.makeZip(files);
    return new Blob([zipU8], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
  }

  async handleDownload() {
    try {

      this._waitingForParent = false;
      this.isLoading = true;
      try {
        this.dispatchEvent(new CustomEvent('loadingEvent', { bubbles: true, composed: true, detail: { action: 'start' } }));
      } catch (e) {
        // ignore
      }
    
      if ((!Array.isArray(this.allRows) || this.allRows.length === 0) && Array.isArray(this.rows) && this.rows.length) {
        this._waitingForParent = true;
        try {
          this.dispatchEvent(new CustomEvent('loadingEvent', { bubbles: true, composed: true, detail: { action: 'start' } }));
        } catch (e) {
          // ignore
        }
        this.dispatchEvent(new CustomEvent('requestdownload', { bubbles: true, composed: true }));
        return;
      }

      const safeRows = Array.isArray(this.allRows) && this.allRows.length ? this.allRows : (Array.isArray(this.rows) ? this.rows : []);
      let columns = this.resolveExportColumns();

      // DEBUG: expose sample row and columns to console to help diagnose truncation issues
      try {

        console.log('XLS Export sample row:', safeRows && safeRows[0]);

        console.log('XLS Export columns:', columns);
      } catch (e) {
        // ignore
      }

      try {
        const orderCol = columns.find((c) => {
          const n = String(c.fieldName || '').toLowerCase();
          const l = String(c.label || '').toLowerCase();
          return l === 'order number' || n.endsWith('.ordernumber') || n.includes('sapordernumber') || (n.includes('order') && (n.includes('number') || n.includes('orderitem')));
        });
        const orderItemCol = columns.find((c) => {
          const n = String(c.fieldName || '').toLowerCase();
          const l = String(c.label || '').toLowerCase();
          return l === 'order item' || n.includes('orderitem') || n.includes('orderitemnumber');
        });

        if (orderCol) {
          for (const row of safeRows) {
            try {
            instead
              if (row && row['export_order_number']) {
                row[orderCol.fieldName] = row['export_order_number'];
                continue;
              }

              const ov = row[orderCol.fieldName];
              const ivRaw = orderItemCol ? row[orderItemCol.fieldName] : null;
              const iv = ivRaw === null || ivRaw === undefined ? '' : String(ivRaw).trim().padStart(4, '0');
              row[orderCol.fieldName] = `${String(ov ?? '')}${iv}`;
            } catch (e) {
              // ignore per-row errors
            }
          }
          // eslint-disable-next-line no-console
          console.log('XLS Export sample row AFTER merge:', safeRows && safeRows[0]);
        }
      } catch (e) {
        // ignore
      }

      


        try {
          // eslint-disable-next-line no-console
          console.log('XLS Export export_order_number sample:', (safeRows || []).slice(0, 10).map((r) => r['export_order_number']));
        } catch (e) {
          // ignore
        }

      try {
        const resolvedColumns = Array.isArray(columns) ? columns.slice() : [];
        for (const row of safeRows) {
          try {
            row['export_order_number'] = this.getExportOrderValue(row, resolvedColumns);
          } catch (e) {
            row['export_order_number'] = '';
          }
        }

        columns = (columns || []).filter((col) => {
          const lname = String(col.label || '').toLowerCase().trim();
          const fname = String(col.fieldName || '').toLowerCase().trim();
          return !(lname.includes('order item') || fname.includes('orderitem') || fname.includes('orderitemnumber') || fname === 'pmc_cpq_orderproduct__c');
        });

        for (const col of columns) {
          const lname = String(col.label || '').toLowerCase();
          const fname = String(col.fieldName || '').toLowerCase();
          if (lname === 'order number' || fname.endsWith('.ordernumber') || fname.includes('sapordernumber') || (fname.includes('order') && fname.includes('number'))) {
            col.fieldName = 'export_order_number';
          }
        }
      } catch (e) {
        // ignore
      }

      if (!safeRows.length || !columns.length) {
        // stop global loader before showing warning
        this.stopGlobalLoader();
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Warning",
            message: "No records to export.",
            variant: "warning",
            mode: "dismissable"
          })
        );
        return;
      }

      // rely on global loadingEvent instead of local overlay
      const blob = this.buildXlsxBlob(columns, safeRows);
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      const ts = new Date().toISOString().replace(/[:.]/g, "-");
      const filename = `${this.objectApiName || "export"}-${ts}.xlsx`;
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
      // delay stopping loader slightly to ensure browser started download
      setTimeout(() => {
        try { this.stopGlobalLoader(); } catch (e) { /* ignore */ }
        try { URL.revokeObjectURL(url); } catch (e) { /* ignore */ }
      }, 50);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "XLS file has been downloaded successfully.",
          variant: "success",
          mode: "dismissable"
        })
      );
    } catch (err) {
      console.error("Export error", err);
      // stop loader/overlay before reporting error
      this.stopGlobalLoader();
      const message = err?.body?.message || err?.message || String(err);
      const evt = new CustomEvent("error", { detail: { message } });
      this.dispatchEvent(evt);
    } finally {
      try {
        // always stop global loader and remove any local overlay
        try {
          this.dispatchEvent(new CustomEvent('loadingEvent', { bubbles: true, composed: true, detail: { action: 'stop' } }));
        } catch (e) {
          // ignore
        }
        try { this.hideLoadingOverlay(); } catch (e) { /* ignore */ }
      } catch (e) {
        // ignore
      }
      this.isLoading = false;
    }
  }

  @api
  async downloadTable() {
    await this.handleDownload();
  }
}