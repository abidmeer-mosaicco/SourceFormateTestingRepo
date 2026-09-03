// mosaicDirectListPlace.js (modo 100% manual)
import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext, publish } from "lightning/messageService";
import ACCOUNT_SELECTION_CHANNEL from "@salesforce/messageChannel/AccountSelectionChannel__c";
import ToastContainer from "lightning/toastContainer";
import Toast from "lightning/toast";
// import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { updateRecord } from "lightning/uiRecordApi";
import getQuoteLinesForAllowedAccountsPaged from "@salesforce/apex/MosaicDirectListControllerPlace.getQuoteLinesForAllowedAccountsPaged";
import resolveAccountNamesToIds from "@salesforce/apex/AccountNameResolver.resolveAccountNamesToIds";
import { getValueFromPath, applyAllFilters as applyAllFiltersHelper } from "./helper";
import USER_ID from '@salesforce/user/Id';

// mínimo de caracteres para delegar a busca ao servidor
const MIN_SEARCH_LENGTH = 3;

// Helper: formata Date ou string ISO para MM/DD/YYYY
function pad2(n) {
  return n < 10 ? '0' + n : String(n);
}

function formatDateMMDDYYYY(d) {
  if (!d) return '';
  try {
    let dt = d;
    if (typeof dt === 'string') {
      // tenta parse de YYYY-MM-DD ou ISO
      const parts = dt.split('T')[0].split('-');
      if (parts.length === 3) {
        const y = parseInt(parts[0], 10);
        const m = parseInt(parts[1], 10) - 1;
        const day = parseInt(parts[2], 10);
        dt = new Date(Date.UTC(y, m, day));
      } else {
        dt = new Date(dt);
      }
    }
    if (!(dt instanceof Date) || isNaN(dt)) return '';
    // usar UTC date parts para evitar timezone shifting
    const year = dt.getUTCFullYear();
    const month = pad2(dt.getUTCMonth() + 1);
    const day = pad2(dt.getUTCDate());
    return month + '/' + day + '/' + year;
  } catch (e) {
    return '';
  }
}

export default class mosaicDirectListPlace extends NavigationMixin(LightningElement) {
  @api objectApiName;
  @api manualFieldApiNames = [];
  @api manualFieldLabelNames = [];
  @api filterFieldName;
  @api dateFilterFieldName;
  @api endDateFilterFieldName;
  @api baseWhereClause = "";
  @api pageSize = 50;
  @api accountNamePath = "";
  @track columns = [];
  @track data = [];
  @track draftValues = [];
  @track errorMessage = '';
  // Inline per-row error overlay
  @track inlineErrorVisible = false;
  @track inlineErrorMessage = '';
  inlineErrorStyle = '';
  @track searchTerm = "";
  @track dateFromValue = "";
  @track dateToValue = "";
  @track tempDateFrom = "";
  @track tempDateFromRaw = "";
  @track tempDateTo = "";
  @track tempDateToRaw = "";
  @track pageButtons = [];
  @track page1Variant = 'neutral';
  @track lastPageVariant = 'neutral';

  isLoading = false;
  subscription;

  @track pageNumber = 1;
  @track totalSize = 0;
  @track totalPages = 1;

  @wire(MessageContext)
  setMessageContext(messageContext) {
    this.messageContext = messageContext;
    if (this.messageContext && !this.subscription) {
      try {
        this.subscription = subscribe(this.messageContext, ACCOUNT_SELECTION_CHANNEL, (message) => { this.handleMessage(message); }, { scope: APPLICATION_SCOPE });
      } catch (e) {
      }
    }
  }

  // flag para indicar que estamos resolvendo nomes para Ids via Apex
  _resolvingNames = false;
  selectedAccountIds = [];
  // nomes recebidos (quando componentes emitem nomes em vez de Ids)
  _selectedAccountNames = [];
  originalData = [];
  // private manual field caches removed — component will use JS-defined columns only
  // Mantemos compatibilidade com diferentes componentes/versões que gravam em chaves distintas
  storageKey = "mosaic:selectedAccounts";
  storageKeys = [
    "mosaic:selectedAccounts",
    "mosaic:selectedAccountIds",
    "selectedAccountIds",
    "selectedAccounts",
    "selectedAccountsIds"
  ];
  noResults = false;
  noResultsMessage = "No records found.";
  sortField = "LastModifiedDate";
  sortDir = "DESC";
  // apexSortField is the server-side field name used in ORDER BY
  apexSortField = "LastModifiedDate";

  get hasRecords() {
    return this.totalSize > 0;
  }

  get isPrevDisabled() {
    return this.isLoading || this.pageNumber <= 1;
  }

  get isNextDisabled() {
    return this.isLoading || this.pageNumber >= this.totalPages;
  }

  get showFirstPage() {
    return this.totalPages > 1;
  }

  get showLastPage() {
    return this.totalPages > 1;
  }

  get showLeftEllipsis() {
    return this.pageNumber > 4;
  }

  get showRightEllipsis() {
    return this.pageNumber < this.totalPages - 3;
  }

  // Lê seleção persistida (localStorage -> sessionStorage) e normaliza para array de strings
  _readSelectedAccountsFromStorage() {
    try {
      // tentar todas as chaves conhecidas no localStorage e sessionStorage
      for (const key of (this.storageKeys || [this.storageKey])) {
        try {
          const raw = localStorage.getItem(`${key}:${USER_ID}`) || localStorage.getItem(key) || sessionStorage.getItem(`${key}:${USER_ID}`) || sessionStorage.getItem(key);
          if (!raw) continue;
          try {
            const parsed = JSON.parse(raw);
            if (Array.isArray(parsed)) return parsed.map((s) => String(s));
            if (typeof parsed === 'string' && parsed) return [String(parsed)];
          } catch (e) {
            if (typeof raw === 'string' && raw.trim()) {
              // pode ser CSV ou único id
              const list = raw.split(',').map((s) => s.trim()).filter(Boolean);
              if (list.length) return list;
            }
          }
        } catch (eKey) {
          // ignora problemas em chaves individuais
          continue;
        }
      }
    } catch (e) {
      // noop
    }
    return [];
  }

  handleSort(event) {
    const { fieldName, sortDirection } = event.detail;
    // sortField = coluna clicada (mostra indicador no datatable)
    this.sortField = fieldName;
    // apexSortField = campo real no servidor (para datas display mapear para campos do Quote)
    if (fieldName === 'StartDate_display') {
      this.apexSortField = 'PMC_CPQ_ContractStart__c';
    } else if (fieldName === 'EndDate_display') {
      this.apexSortField = 'PMC_CPQ_ContractEnd__c';
    } else {
      this.apexSortField = fieldName;
    }
    this.sortDir = (sortDirection || "asc").toUpperCase();
    this.fetchPage(1);
  }

  _composeWhereClause() {
    const parts = [];
    if (this.baseWhereClause) parts.push("(" + this.baseWhereClause + ")");

    if (this.selectedAccountIds?.length && this.accountNamePath) {
      const ids = this.selectedAccountIds.map((id) => `'${String(id).replace(/'/g, "\\'")}'`).join(",");
      parts.push(`${this.accountNamePath} IN (${ids})`);
    }

    return parts.join(" AND ");
  }

  updatePageButtons() {
    const total = this.totalPages;
    const current = this.pageNumber;

    this.page1Variant = current === 1 ? 'brand' : 'neutral';
    this.lastPageVariant = current === total ? 'brand' : 'neutral';

    const middlePages = this.calculateMiddlePages(total, current);

    const pageButtons = [];
    for (const page of middlePages) {
      if (page > 1 && page < total) {
        pageButtons.push({
          page: page,
          label: page.toString(),
          variant: current === page ? 'brand' : 'neutral',
          active: current === page
        });
      }
    }

    this.pageButtons = pageButtons;
  }

  calculateMiddlePages(total, current) {
    const pages = new Set();

    pages.add(1);

    if (total <= 7) {
      for (let i = 2; i <= total; i++) {
        pages.add(i);
      }

      return Array.from(pages).sort((a, b) => a - b);
    }

    if (current <= 4) {
      for (let i = 2; i <= 6; i++) {
        pages.add(i);
      }

      pages.add(total);

      return Array.from(pages).sort((a, b) => a - b);
    }

    if (current >= total - 3) {
      for (let i = total - 5; i <= total; i++) {
        if (i > 1) pages.add(i);
      }

      return Array.from(pages).sort((a, b) => a - b);
    }

    let start = Math.max(2, current - 3);
    let end = Math.min(total - 1, current + 3);

    for (let i = start; i <= end; i++) {
      pages.add(i);
    }

    pages.add(total);

    return Array.from(pages).sort((a, b) => a - b);
  }

  async fetchPage(page = 1) {
    try {
      this.isLoading = true;

      // Sanitiza e loga selectedAccountIds antes da chamada ao Apex
      const sanitizedIds = (this.selectedAccountIds || [])
        .filter((id) => id != null && (typeof id === 'string' || typeof id === 'number'))
        .map((id) => String(id).trim())
        .filter((s) => s.length > 0);
      // Função utilitária: verifica se é um Salesforce Id (15 ou 18 chars alfanuméricos)
      const isSfId = (s) => typeof s === 'string' && /^[0-9A-Za-z]{15,18}$/.test(s);

      // Se tivermos itens que não são SF Ids, tentamos resolver como nomes via Apex
      let accountIdsForApex = null;
      try {
        const validIds = sanitizedIds.filter(isSfId);
        const possibleNames = sanitizedIds.filter((s) => !isSfId(s));

        if (possibleNames.length) {
          // Chama o Apex que resolve nomes -> Ids. O Apex agora retorna Map<String, List<Id>>
          const resolvedMap = await resolveAccountNamesToIds({ accountNames: possibleNames });
          const resolvedIds = [];
          if (resolvedMap) {
            for (const k in resolvedMap) {
              const v = resolvedMap[k];
              if (Array.isArray(v)) {
                v.forEach((id) => { if (id) resolvedIds.push(id); });
              } else if (v) {
                resolvedIds.push(v);
              }
            }
          }
          // unir ids válidos com os ids resolvidos e deduplicar
          accountIdsForApex = Array.from(new Set([...(validIds || []), ...resolvedIds])).filter((v) => !!v);
        } else {
          accountIdsForApex = validIds.length ? validIds : null;
        }
      } catch (e) {
        // eslint-disable-next-line no-console
        console.warn('Erro ao resolver nomes para Ids, prosseguindo sem filtro por conta', e);
        accountIdsForApex = null;
      }

      // Coluna fixa: Contract Number + MOT
      this.columns = [
        { label: 'Contract Number', fieldName: 'ContractNumber', type: 'text', initialWidth: 135, sortable: true },
        { label: 'Account', fieldName: 'AccountName', type: 'text', sortable: false, initialWidth: 150, wrapText: true },
        { label: 'PO Number', fieldName: 'PONumber', type: 'text', sortable: false, initialWidth: 100 },
        { label: 'Product', fieldName: 'Product', type: 'text', sortable: false, initialWidth: 150, wrapText: true },
        { label: 'MOT', fieldName: 'MOT', type: 'text', initialWidth: 100, sortable: false, wrapText: true },
        { label: 'Incoterm', fieldName: 'Incoterm', type: 'text', initialWidth: 100, sortable: false, wrapText: true },
        { label: 'Origin', fieldName: 'Origin', type: 'text', sortable: false, initialWidth: 150, wrapText: true },
        { label: 'Ship to', fieldName: 'ShipTo', type: 'text', sortable: false, wrapText: true },
        { label: 'Start Date', fieldName: 'StartDate_display', type: 'text', sortable: true, initialWidth: 100, wrapText: true },
        { label: 'End Date', fieldName: 'EndDate_display', type: 'text', sortable: true, initialWidth: 100, wrapText: true },
        { label: 'Price per ton', fieldName: 'PricePerTon_display', type: 'text', sortable: false, initialWidth: 100, wrapText: true },
        { label: 'Qty Available', fieldName: 'QtyAvailable', type: 'number', sortable: false, wrapText: true }
      ];
      this._makeContractNumberClickable();

      // Chama o método server-side que já retorna quoteName no DTO
      // ids que serão enviados ao Apex
      // Reutiliza helper do componente para normalizar datas (evita duplicação)
      const normalizeDateForApex = (v) => this._normalizeDateForApex(v);

      // Decide enviar searchTerm ao servidor somente quando for significativo (>= MIN_SEARCH_LENGTH chars)
      const currentSearch = (this.searchTerm && String(this.searchTerm).trim().length >= MIN_SEARCH_LENGTH) ? String(this.searchTerm).trim() : null;

      const res = await getQuoteLinesForAllowedAccountsPaged({
        accountIds: (accountIdsForApex && accountIdsForApex.length) ? accountIdsForApex : null,
        pageSize: this.pageSize,
        pageNumber: page,
        orderByField: this.apexSortField || this.sortField,
        orderDir: this.sortDir,
        dateFrom: normalizeDateForApex(this.dateFromValue),
        dateTo: normalizeDateForApex(this.dateToValue),
        searchTerm: currentSearch
      });

      console.log({ res });


      // Mapear usando o DTO retornado: preferir nomes explícitos quando disponíveis
      const rows = (res.records || []).map((r) => {
        const originName = (r.productLocationName && String(r.productLocationName).trim())
          ? String(r.productLocationName).trim()
          : (r.origin && String(r.origin).trim()) ? String(r.origin).trim() : '';
        const shipToName = (r.shipToName && String(r.shipToName).trim())
          ? String(r.shipToName).trim()
          : (r.shipTo && String(r.shipTo).trim()) ? String(r.shipTo).trim() : '';
        // Detecta "Multiple" nos campos que o helper pode marcar
        const MULTIPLE = 'multiple';
        const fieldsToCheck = ['modeOfTransportation', 'productName', 'shippingType', 'incoterm', 'origin', 'shipTo'];
        const isMultiple = fieldsToCheck.some((f) => String(r[f] || '').toLowerCase() === MULTIPLE);
        return {
          Id: r.quoteId || r.quoteLineId || null,
          ContractNumber: r.quoteName || '',
          PONumber: r.poNumber || '',
          Product: r.productName || '',
          ShippingType: r.shippingType || '',
          Incoterm: r.incoterm || '',
          Origin: originName,
          ShipTo: (r && r.shipToDisplay) || '',
          MOT: r.modeOfTransportation || '',
          StartDate: r.contractStart || null,
          EndDate: r.contractEnd || null,
          StartDate_display: (r.contractStart ? formatDateMMDDYYYY(r.contractStart) : ''),
          EndDate_display: (r.contractEnd ? formatDateMMDDYYYY(r.contractEnd) : ''),
          AccountId: r.accountId || r.AccountId || null,
          AccountName: r.accountName || r.AccountName || '',
          QuoteLineId: isMultiple ? 'multiple' : r.quoteLineId || null,
          QtyAvailable: (r.qtyAvailable === null || typeof r.qtyAvailable === 'undefined') ? null : Number(r.qtyAvailable),
          PricePerTon: (typeof r.finalPricePerTon === 'undefined' || r.finalPricePerTon === null) ? null : Number(r.finalPricePerTon),
          PricePerTon_display: isMultiple ? 'Multiple' : ((typeof r.finalPricePerTon === 'undefined' || r.finalPricePerTon === null) ? '' : Number(r.finalPricePerTon).toFixed(2)),
          // sinaliza se o link do Contract Number deve ser bloqueado
          ContractLinkBlocked: !!r.contractLinkBlocked,
          // novos campos não exibidos (disponíveis na row)
          quoteId: r.quoteId,
          contractType: r.contractType || '',
          downloadUrl: r.downloadUrl || ''
        };
      });

      // Evita duplo-filtro de texto no client
      const current = this.searchTerm;
      this.searchTerm = "";
      this.originalData = rows;
      this.data = this.applyAllFilters(rows);
      this.searchTerm = current;

      this.pageNumber = res.pageNumber || page;
      this.totalSize = res.totalSize || 0;
      this.totalPages = Math.max(1, Math.ceil(this.totalSize / this.pageSize));

      // Atualiza botões de paginação
      this.updatePageButtons();

    } catch (err) {
      this.showToast("Erro ao paginar", err, 'error');
    } finally {
      this.isLoading = false;
    }
  }

  connectedCallback() {
    // subscription is handled in setMessageContext to avoid race conditions
    // Carrega seleção de contas do localStorage com tolerância a formatos diferentes
    try {
      const stored = this._readSelectedAccountsFromStorage();
      this.selectedAccountIds = Array.isArray(stored) ? stored : [];
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error("Error parsing stored account IDs:", e);
      this.selectedAccountIds = [];
    }

    try {
      const toastContainer = ToastContainer.instance();
      toastContainer.maxToasts = 5;
      toastContainer.toastPosition = "top-center";
    } catch (e) { }

    // Quando a página recebe foco (p.ex. após navegação/modal), reavalie storage e recarregue se mudou
    this._onWindowFocus = () => {
      try {
        if (this._resolvingNames) return;
        const stored = this._readSelectedAccountsFromStorage();
        const prev = (this.selectedAccountIds || []).slice().map(String);
        const same = JSON.stringify(prev) === JSON.stringify(stored || []);
        if (!same) {
          this.selectedAccountIds = stored || [];
          console.debug && console.debug('[mosaicDirectListPlace] window focus detected changed selection', this.selectedAccountIds);
          this.fetchPage(1);
        }
      } catch (e) {
        // noop
      }
    };
    window.addEventListener('focus', this._onWindowFocus);

    // Não usar colunas manuais: manter apenas as colunas definidas no JS (fetchPage)
    this.loadManual();

    // Fallback: listener em window para eventos customizados (reduz risco de race quando navegação rápida)
    this._onWindowAccountSelection = (evt) => {
      try {
        if (this._resolvingNames) return;
        console.debug && console.debug('[mosaicDirectListPlace] window event mosaic:accountSelectionChanged', evt && evt.detail);
        if (evt && evt.detail) this.handleMessage(evt.detail);
      } catch (e) {
        // noop
      }
    };
    window.addEventListener('mosaic:accountSelectionChanged', this._onWindowAccountSelection);

    // Escutar também o evento custom 'accountschange' disparado por accountAccessTable
    this._onAccountsChangeEvent = (evt) => {
      try {
        if (this._resolvingNames) return;
        console.debug && console.debug('[mosaicDirectListPlace] window event accountschange', evt && evt.detail);
        if (evt && evt.detail) {
          // aceita detalhe no formato { selectedAccountIds: [...] } ou array direto
          if (Array.isArray(evt.detail)) this.handleMessage(evt.detail);
          else this.handleMessage(evt.detail);
        }
      } catch (e) {
        // noop
      }
    };
    window.addEventListener('accountschange', this._onAccountsChangeEvent);

    // Listener 'storage' para detectar alterações feitas em outras janelas/frames
    this._onStorageEvent = (evt) => {
      try {
        console.debug && console.debug('[mosaicDirectListPlace] storage event', evt && { key: evt.key, newValue: evt && evt.newValue });
        if (this._resolvingNames) {
          console.debug && console.debug('[mosaicDirectListPlace] storage event ignored while resolving names');
          return;
        }
        if (evt && ((this.storageKeys && this.storageKeys.includes(evt.key)) || evt.key === this.storageKey)) {
          const stored = this._readSelectedAccountsFromStorage();
          this.selectedAccountIds = stored || [];
          console.debug && console.debug('[mosaicDirectListPlace] storage changed, new selection', this.selectedAccountIds);
          this.fetchPage(1);
        }
      } catch (e) {
        // noop
      }
    };
    window.addEventListener('storage', this._onStorageEvent);

    // Poll leve para detectar alterações no mesmo contexto (cobre casos em que o modal atualiza storage sem disparar events)
    try {
      this._lastStoredSelection = JSON.stringify(this._readSelectedAccountsFromStorage() || []);
      this._storagePollInterval = window.setInterval(() => {
        try {
          if (this._resolvingNames) return;
          const current = JSON.stringify(this._readSelectedAccountsFromStorage() || []);
          if (current !== this._lastStoredSelection) {
            console.debug && console.debug('[mosaicDirectListPlace] poll detected storage change', { before: this._lastStoredSelection, after: current });
            this._lastStoredSelection = current;
            let parsed = [];
            try { parsed = JSON.parse(current); } catch (e) { parsed = [] }
            this.selectedAccountIds = Array.isArray(parsed) ? parsed : [];
            this.fetchPage(1);
          }
        } catch (err) {
          // noop
        }
      }, 1000);
    } catch (e) {
      // noop
    }
  }

  // Helper local: normaliza para YYYY-MM-DD (usado antes de enviar ao Apex)
  _normalizeDateForApex(v) {
    if (!v && v !== 0) return null;
    if (v instanceof Date) {
      const y = v.getFullYear();
      const m = String(v.getMonth() + 1).padStart(2, '0');
      const day = String(v.getDate()).padStart(2, '0');
      return `${y}-${m}-${day}`;
    }
    if (typeof v === 'string') {
      if (/^\d{4}-\d{2}-\d{2}$/.test(v)) return v;
      if (/^\d{1,2}\/\d{1,2}\/\d{4}$/.test(v)) {
        const parts = v.split('/');
        const mm = String(parseInt(parts[0], 10)).padStart(2, '0');
        const dd = String(parseInt(parts[1], 10)).padStart(2, '0');
        const yyyy = parts[2];
        return `${yyyy}-${mm}-${dd}`;
      }
      const dt = new Date(v);
      if (isNaN(dt)) return null;
      const y2 = dt.getUTCFullYear();
      const m2 = String(dt.getUTCMonth() + 1).padStart(2, '0');
      const d2 = String(dt.getUTCDate()).padStart(2, '0');
      return `${y2}-${m2}-${d2}`;
    }
    return null;
  }

  // handleDateFromChange(event) {
  //   // Prefer event.detail.value from lightning-input; fallback to target.value
  //   const raw = event && event.detail && event.detail.value ? event.detail.value : (event && event.target && event.target.value ? event.target.value : "");
  //   this.tempDateFromRaw = raw;
  //   const iso = this._normalizeDateForApex(raw);
  //   // mantenha tempDateFrom sempre em ISO quando possível, senão vazio
  //   this.tempDateFrom = iso || "";
  // }

  handleDateChange(event) {
    let { value, dataset } = event.currentTarget;
    let dateIso = this._normalizeDateForApex(value) || '';

    if (dataset.name == 'from') {
      this.tempDateFromRaw = value;
      this.tempDateFrom = dateIso;
    }

    if (dataset.name == 'to') {
      this.tempDateToRaw = value;
      this.tempDateTo = dateIso;
    }

    this.handleDateSearch();
  }

  disconnectedCallback() {
    try {
      if (this.subscription) unsubscribe(this.subscription);
      this.subscription = null;
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn('[mosaicDirectListPlace] error unsubscribing', e);
    }
    try {
      if (this._onWindowAccountSelection) window.removeEventListener('mosaic:accountSelectionChanged', this._onWindowAccountSelection);
      if (this._onAccountsChangeEvent) window.removeEventListener('accountschange', this._onAccountsChangeEvent);
      if (this._onWindowFocus) window.removeEventListener('focus', this._onWindowFocus);
      // remover listener de storage e limpar interval polling
      if (this._onStorageEvent) window.removeEventListener('storage', this._onStorageEvent);
      if (this._storagePollInterval) {
        window.clearInterval(this._storagePollInterval);
        this._storagePollInterval = null;
      }
    } catch (e) {
      // noop
    }
  }

  getValueFromRow(row, path) {
    return getValueFromPath(row, path);
  }

  _makeContractNumberClickable() {
    const isContractCol = (col) => {
      const name = (col.fieldName || "").trim();
      const labelLc = (col.label || "").toLowerCase();
      return name === "Contract_Number__c" || name === "ContractNumber" || labelLc === "contract number";
    };

    this.columns = (this.columns || []).map((col) => {
      if (isContractCol(col)) {
        return {
          ...col,
          type: "button",
          typeAttributes: {
            label: { fieldName: col.fieldName },
            name: "navigateToRecord",
            variant: "base"
          },
          sortable: true,
          editable: false
        };
      }
      return col;
    });
  }

  applyAllFilters(baseRows) {
    // Antes de delegar ao helper, se o campo de exibição terminar com _display
    // convertemos para o nome raw correspondente para evitar parsing ambíguo de MM/DD/YYYY
    const normalizeField = (f) => {
      if (!f) return f;
      return f.endsWith('_display') ? f.replace(/_display$/, '') : f;
    };
    const startField = normalizeField(this.dateFilterFieldName);
    const endField = normalizeField(this.endDateFilterFieldName);

    return applyAllFiltersHelper({
      rows: baseRows,
      columns: this.columns,
      searchTerm: this.searchTerm,
      dateFilterFieldName: startField,
      endDateFilterFieldName: endField,
      dateFromValue: this.dateFromValue,
      dateToValue: this.dateToValue,
      selectedAccountIds: this.selectedAccountIds,
      selectedAccountNames: this._selectedAccountNames,
      accountNamePath: this.accountNamePath
    });
  }

  // ===== Mensageria (seleção de contas) =====
  async handleMessage(message) {
    // Debug inicial: verificar exatamente o que chega via LMS / window events
    try { console.debug && console.debug('[mosaicDirectListPlace] handleMessage received', message); } catch (e) { /* noop */ }

    // Aceita formatos variados: [ 'id', ... ] | { selectedAccountIds: [...] } | { selectedAccountNames: [...] } | eventos com detail
    let ids = null;
    let names = null;

    if (Array.isArray(message)) {
      ids = message;
    } else if (Array.isArray(message?.selectedAccountIds)) {
      ids = message.selectedAccountIds;
    } else if (message?.selectedAccountId) {
      ids = [message.selectedAccountId];
    } else if (Array.isArray(message?.selectedAccounts)) {
      ids = message.selectedAccounts;
    } else if (Array.isArray(message?.selectedAccountNames)) {
      names = message.selectedAccountNames;
    } else if (message?.selectedAccountKeys) {
      ids = message.selectedAccountKeys;
    } else if (message?.detail) {
      const d = message.detail;
      if (Array.isArray(d.selectedAccountIds)) ids = d.selectedAccountIds;
      else if (d.selectedAccountId) ids = [d.selectedAccountId];
      else if (Array.isArray(d.selectedAccounts)) ids = d.selectedAccounts;
      else if (Array.isArray(d.selectedAccountNames)) names = d.selectedAccountNames;
      else if (d.selectedAccountKeys) ids = d.selectedAccountKeys;
    }

    // If ids empty, try reading from storage fallback (covers race with modal/navigation)
    if ((!ids || !Array.isArray(ids) || ids.length === 0) && !names) {
      try {
        const fromStorage = this._readSelectedAccountsFromStorage();
        if (fromStorage && fromStorage.length) {
          ids = fromStorage;
        }
      } catch (e) {
        // noop
      }
    }

    // Caso especial: se recebemos somente names (outro componente pode publicar names),
    // verifique se o storage já contém ids (ex.: modal atualizou storage antes de publicar)
    // e, se houver ids válidos no storage, prefira-os para evitar sobrescrita por nomes.
    try {
      const isSfIdLocal = (s) => typeof s === 'string' && /^[0-9A-Za-z]{15,18}$/.test(s);
      if ((!ids || !Array.isArray(ids) || ids.length === 0) && Array.isArray(names) && names.length) {
        const fromStorage2 = this._readSelectedAccountsFromStorage();
        const sfIds = Array.isArray(fromStorage2) ? fromStorage2.filter((v) => isSfIdLocal(v)) : [];
        if (sfIds && sfIds.length) {
          ids = sfIds;
          names = null; // prefer ids from storage
          console.debug && console.debug('[mosaicDirectListPlace] preferred ids from storage over incoming names to avoid race', ids);
        }
      }
    } catch (e) {
      // noop
    }

    // Normaliza elementos individuais (string | number | object contendo id/accountId/value)
    if (Array.isArray(ids)) {
      ids = ids
        .map((it) => {
          if (!it) return null;
          if (typeof it === 'string' || typeof it === 'number') return String(it).trim();
          if (typeof it === 'object') return String(it.id || it.accountId || it.accountId__c || it.value || '').trim();
          return null;
        })
        .filter(Boolean);
    }
    if (Array.isArray(names)) {
      names = names.map((n) => (n ? String(n).trim() : '')).filter(Boolean);
    }

    // Se houver nomes e sem ids, tentar resolver para Ids via Apex antes de persistir
    // NOTA: para evitar expansão indesejada quando um Name corresponde a múltiplos Accounts,
    // não vamos automaticamente "explodir" um name em todas as ids retornadas.
    // Estratégia:
    //  - se o resolve retornar exatamente 1 Id para um name -> usamos esse Id
    //  - se retornar >1 Ids -> tentamos desambiguar usando EFFECTIVE_ACCOUNT_ID (storage)
    //    se não for possível desambiguar, NÃO adicionamos todas as ids automaticamente;
    //    mantemos o name em _selectedAccountNames para sinalizar ambiguidade
    const isSfId = (s) => typeof s === 'string' && /^[0-9A-Za-z]{15,18}$/.test(s);
    let resolvedIds = ids || [];
    try {
      if ((names && names.length) || (resolvedIds || []).some((v) => !isSfId(v))) {
        this._resolvingNames = true;
      }
      const nonIds = (resolvedIds || []).filter((v) => !isSfId(v));
      const toResolve = [...(names || []), ...nonIds];
      if (toResolve.length) {
        try {
          const mapRes = await resolveAccountNamesToIds({ accountNames: toResolve });
          const lookup = mapRes || {};
          const finalResolved = [];
          const unresolvedNames = [];
          // incluir ids válidos já presentes
          if (Array.isArray(resolvedIds) && resolvedIds.length) {
            for (const v of resolvedIds) { if (isSfId(v)) finalResolved.push(v); }
          }

          const preferredFromStorage = sessionStorage.getItem('EFFECTIVE_ACCOUNT_ID') || localStorage.getItem('EFFECTIVE_ACCOUNT_ID');

          // substituir entradas não-id por valores vindos do lookup (sem expandir ambigüidades)
          for (const v of (resolvedIds || [])) {
            if (!isSfId(v)) {
              const got = lookup[v];
              if (Array.isArray(got) && got.length === 1) {
                finalResolved.push(got[0]);
              } else if (Array.isArray(got) && got.length > 1) {
                // tenta desambiguar com EFFECTIVE_ACCOUNT_ID
                let chosen = null;
                if (preferredFromStorage) {
                  const f = got.find((i) => String(i) === String(preferredFromStorage));
                  if (f) chosen = f;
                }
                if (chosen) finalResolved.push(chosen);
                else {
                  unresolvedNames.push(v);
                  console.warn && console.warn('[mosaicDirectListPlace] ambiguous account name resolution for', v, 'returned', got.length, 'ids; not expanding automatically');
                }
              } else if (got) {
                finalResolved.push(got);
              } else {
                unresolvedNames.push(v);
              }
            }
          }

          // incluir resultados da resolução de names (sem expandir ambigüidades)
          for (const n of (names || [])) {
            const got = lookup[n];
            if (Array.isArray(got) && got.length === 1) {
              finalResolved.push(got[0]);
            } else if (Array.isArray(got) && got.length > 1) {
              let chosen = null;
              if (preferredFromStorage) {
                const f = got.find((i) => String(i) === String(preferredFromStorage));
                if (f) chosen = f;
              }
              if (chosen) finalResolved.push(chosen);
              else {
                unresolvedNames.push(n);
                console.warn && console.warn('[mosaicDirectListPlace] ambiguous account name resolution for', n, 'returned', got.length, 'ids; not expanding automatically');
              }
            } else if (got) {
              finalResolved.push(got);
            } else {
              unresolvedNames.push(n);
            }
          }

          // deduplicar e manter apenas ids válidos
          resolvedIds = Array.from(new Set(finalResolved.map(String))).filter(isSfId);

          // manter nomes não resolvidos para posteriores desambiguações (ou UX)
          if (unresolvedNames.length) {
            names = Array.from(new Set([...(names || []), ...unresolvedNames]));
          } else {
            names = [];
          }
        } catch (resolveErr) {
          // se falhar, manter apenas SF Ids já presentes
          resolvedIds = (resolvedIds || []).filter((v) => isSfId(v));
        }
      } else {
        // nenhum nome para resolver
        resolvedIds = (resolvedIds || []).filter((v) => isSfId(v));
      }
    } catch (e) {
      // fallback: manter apenas ids válidos
      resolvedIds = (resolvedIds || []).filter((v) => isSfId(v));
    }

    // sempre limpar a flag de resolução após o bloco de resolução (se algo falhar,
    // manteremos comportamento defensivo e permitiremos que storage/poll reajam)
    try { this._resolvingNames = false; } catch (e) { this._resolvingNames = false; }

    // DEBUG: log incoming/resolve steps
    try { console.debug && console.debug('[mosaicDirectListPlace] incoming raw ids', ids, 'incoming names', names); } catch (e) { /* noop */ }
    try { console.debug && console.debug('[mosaicDirectListPlace] resolvedIds', resolvedIds); } catch (e) { /* noop */ }

    // Evita publicar/fetch se a seleção não mudou (prevenção de loop)
    try {
      const prevIds = Array.isArray(this.selectedAccountIds) ? [...this.selectedAccountIds].sort() : [];
      const currIds = Array.isArray(resolvedIds) ? [...resolvedIds].sort() : [];
      const idsSame = JSON.stringify(prevIds) === JSON.stringify(currIds);
      const prevNames = Array.isArray(this._selectedAccountNames) ? [...this._selectedAccountNames].sort() : [];
      const currNames = Array.isArray(names) ? [...names].sort() : [];
      const namesSame = JSON.stringify(prevNames) === JSON.stringify(currNames);
      if (idsSame && namesSame) {
        try { console.debug && console.debug('[mosaicDirectListPlace] selection unchanged, skipping persist/publish/fetch'); } catch (e) { /* noop */ }
        // aplica filtro local apenas para garantir feedback visual
        try { this.data = this.applyAllFilters(this.originalData || []); } catch (e) { /* noop */ }
        return;
      }
    } catch (e) {
      // noop
    }

    // Persistir seleção no storage (fallback para consumidores que leem storage)
    try {
      const keys = this.storageKeys && this.storageKeys.length ? this.storageKeys : [this.storageKey];
      for (const key of keys) {
        try {
          const serial = (resolvedIds && Array.isArray(resolvedIds) && resolvedIds.length) ? JSON.stringify(resolvedIds) : ((names && names.length) ? JSON.stringify(names) : null);
          if (serial) {
            try { localStorage.setItem(key, serial); } catch (e) { }
            try { sessionStorage.setItem(key, serial); } catch (e) { }
            try { localStorage.setItem(`${key}:${USER_ID}`, serial); } catch (e) { }
            try { sessionStorage.setItem(`${key}:${USER_ID}`, serial); } catch (e) { }
          } else {
            try { localStorage.removeItem(key); } catch (e) { }
            try { sessionStorage.removeItem(key); } catch (e) { }
            try { localStorage.removeItem(`${key}:${USER_ID}`); } catch (e) { }
            try { sessionStorage.removeItem(`${key}:${USER_ID}`); } catch (e) { }
          }
        } catch (e) {
          // ignora falhas por chave
        }
      }
    } catch (e) {
      console.warn('Could not persist selected accounts to storage', e);
    }

    // Publicar via LMS o payload normalizado (Ids quando disponíveis, senão names)
    try {
      const payload = (resolvedIds && resolvedIds.length) ? { selectedAccountIds: resolvedIds } : (names && names.length ? { selectedAccountNames: names } : {});
      if (this.messageContext && typeof publish === 'function' && Object.keys(payload).length) {
        publish(this.messageContext, ACCOUNT_SELECTION_CHANNEL, payload);
        console.debug && console.debug('[mosaicDirectListPlace] published normalized selection via LMS', payload);
      }
    } catch (e) {
      // noop
    }

    // Atualiza estado local com valores normalizados (IDs ou names)
    this._selectedAccountNames = (resolvedIds && resolvedIds.length) ? [] : (names || []);
    this.selectedAccountIds = Array.isArray(resolvedIds) ? resolvedIds : [];
    this.selectedAccountIds = (this.selectedAccountIds || []).map((s) => String(s)).filter((s) => s.trim().length > 0);

    // Aplicação imediata do filtro no cliente para feedback instantâneo
    try {
      this.data = this.applyAllFilters(this.originalData || []);
    } catch (e) {
      // noop
    }

    // Debounce para evitar múltiplas chamadas server-side quando o usuário
    // seleciona/deseleciona várias contas rapidamente no modal.
    try {
      if (this._selectionDebounce) window.clearTimeout(this._selectionDebounce);
      this._selectionDebounce = window.setTimeout(() => {
        try {
          this.fetchPage(1);
        } catch (e) {
          // noop
        }
      }, 300);
    } catch (e) {
      // fallback: chamada direta
      try { this.fetchPage(1); } catch (err) { /* noop */ }
    }
  }

  handleSearchInput(event) {
    // Atualiza dinamicamente enquanto o usuário digita.
    // Não remover espaços internos — apenas trim nas bordas.
    let tempElement = this.template.querySelector('input[name="search"]');

    this.searchTerm = (tempElement.value || "").toString().trim();
    // this.searchTerm = (event.target.value || "").toString().trim();

    // Sem texto: restaurar conjunto original
    if (!this.searchTerm) {
      if (this._searchDebounce) window.clearTimeout(this._searchDebounce);
      this.data = this.originalData || [];
      return;
    }

    // Para termos curtos, aplicar filtro local imediatamente para feedback rápido
    if (this.searchTerm.length < MIN_SEARCH_LENGTH) {
      const normalizeField = (f) => (f && f.endsWith('_display') ? f.replace(/_display$/, '') : f);
      const startField = normalizeField(this.dateFilterFieldName);
      const endField = normalizeField(this.endDateFilterFieldName);

      this.data = applyAllFiltersHelper({
        rows: this.originalData || [],
        columns: this.columns,
        searchTerm: this.searchTerm,
        searchFieldName: ['ContractNumber', 'PONumber', 'Product'],
        dateFilterFieldName: startField,
        endDateFilterFieldName: endField,
        dateFromValue: this.dateFromValue,
        dateToValue: this.dateToValue,
        selectedAccountIds: this.selectedAccountIds,
        accountNamePath: this.accountNamePath
      });
      return;
    }

    // Termo suficientemente longo: debounce e delegar ao servidor (recarrega página 1)
    try {
      if (this._searchDebounce) window.clearTimeout(this._searchDebounce);
      this._searchDebounce = window.setTimeout(() => {
        try {
          this.fetchPage(1);
        } catch (e) {
          // noop
        }
      }, 300);
    } catch (e) {
      // fallback imediato
      try { this.fetchPage(1); } catch (err) { /* noop */ }
    }
  }

  // Ao clicar em Search: aplicamos o filtro de datas delegando ao helper central
  handleDateSearch() {
    // atualiza valores oficiais (estado persistente) usando valores normalizados (ISO) quando possível
    // garantimos que dateFromValue/dateToValue sejam strings no formato YYYY-MM-DD ou vazias
    this.dateFromValue = this.tempDateFrom || this._normalizeDateForApex(this.tempDateFromRaw) || "";
    this.dateToValue = this.tempDateTo || this._normalizeDateForApex(this.tempDateToRaw) || "";

    // 1) Recarrega dados do servidor com os parâmetros de data (garante filtro server-side)
    //    fetchPage irá normalizar as datas antes de chamar o Apex (normalizeDateForApex existe em fetchPage)
    try {
      this.fetchPage(1);
    } catch (e) {
      // fetchPage handles/logs errors
    }

    // 2) Aplica filtro local imediatamente sobre originalData para feedback rápido (opcional)
    try {
      const normalizeField = (f) => (f && f.endsWith('_display') ? f.replace(/_display$/, '') : f);
      const startField = normalizeField(this.dateFilterFieldName);
      const endField = normalizeField(this.endDateFilterFieldName);

      this.data = applyAllFiltersHelper({
        rows: this.originalData || [],
        columns: this.columns,
        searchTerm: this.searchTerm,
        dateFilterFieldName: startField,
        endDateFilterFieldName: endField,
        dateFromValue: this.dateFromValue,
        dateToValue: this.dateToValue,
        selectedAccountIds: this.selectedAccountIds,
        accountNamePath: this.accountNamePath
      });
    } catch (e) {
      // error applying local filters
    }
  }

  handleClearFilters() {
    this.selectedAccountIds = [];

    this.searchTerm = "";
    // Limpar todos os valores relacionados a filtros de data (FROM / TO)
    // Usar null para garantir que bindings em inputs sejam atualizados sem valores residuais
    this.dateFromValue = null;
    this.dateToValue = null;
    this.tempDateFrom = null;
    this.tempDateFromRaw = null;
    this.tempDateTo = null;
    this.tempDateToRaw = null;
    this.noResults = false;
    // this.noResultsMessage = "";
    this.data = this.applyAllFilters(this.originalData || []);
    try {
      const keys = this.storageKeys && this.storageKeys.length ? this.storageKeys : [this.storageKey];
      for (const key of keys) {
        try { localStorage.removeItem(key); } catch (e) { /* noop */ }
        try { sessionStorage.removeItem(key); } catch (e) { /* noop */ }
        try { localStorage.removeItem(`${key}:${USER_ID}`); } catch (e) { /* noop */ }
        try { sessionStorage.removeItem(`${key}:${USER_ID}`); } catch (e) { /* noop */ }
      }
    } catch (e) {
      console.error("Error removing stored account IDs:", e);
    }
    // Recarrega a primeira página no servidor para garantir remoção de filtros server-side
    try {
      this.fetchPage(1);
    } catch (e) {
      // noop - fetchPage já trata e loga erros internamente
    }
  }

  handleRowAction(event) {
    const actionName = event.detail?.action?.name;
    const row = event.detail?.row;
    console.debug && console.debug('[mosaicDirectListPlace] handleRowAction invoked', { actionName, row });

    if (actionName === "navigateToRecord") {
      const msg = "Action Blocked: It is not possible to proceed with this contract to place the order";
      try {
        const contractBlocked = !!row?.ContractLinkBlocked;

        let qtyZero = false;
        try {
          const q = row?.QtyAvailable;
          if (q === null || typeof q === 'undefined' || (typeof q === 'string' && q.trim() === '')) {
            qtyZero = false;
          } else {
            const qnum = Number(q);
            qtyZero = Number.isFinite(qnum) && qnum === 0;
          }
        } catch (e) { qtyZero = false; }

        let endExpired = false;
        try {
          const endVal = row?.EndDate || row?.EndDate_display || row?.EndDateDisplay || null;
          const parseDate = (v) => {
            if (!v) return null;
            if (v instanceof Date) return new Date(Date.UTC(v.getFullYear(), v.getMonth(), v.getDate()));
            if (typeof v === 'string') {
              const m = v.match(/^(\d{4})-(\d{2})-(\d{2})$/);
              if (m) return new Date(Date.UTC(parseInt(m[1], 10), parseInt(m[2], 10) - 1, parseInt(m[3], 10)));
              const m2 = v.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
              if (m2) return new Date(Date.UTC(parseInt(m2[3], 10), parseInt(m2[1], 10) - 1, parseInt(m2[2], 10)));
              const d = new Date(v);
              if (!isNaN(d)) return new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
            }
            return null;
          };
          const endDateObj = parseDate(endVal);
          const now = new Date();
          const todayUtc = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
          endExpired = !!(endDateObj && endDateObj < todayUtc);
        } catch (e) { endExpired = false; }

        const blocked = contractBlocked || qtyZero || endExpired;

        // LOG detalhado para diagnóstico de porque um registro é bloqueado (ou não)
        try { console.debug && console.debug('[mosaicDirectListPlace] row block check', { id: row?.Id, ContractLinkBlocked: contractBlocked, QtyAvailable: row?.QtyAvailable, qtyZero, EndDate: row?.EndDate || row?.EndDate_display, endExpired, blocked }); } catch (e) { /* noop */ }

        if (blocked) {
          // build specific messages per rules and show inline near the clicked row
          const contractMsg = 'The contract is currently being amended.';
          const qtyMsg = 'There isn\u2019t enough balance available.';
          const endMsg = 'Contract validity date has expired.';

          let inlineMsg = '';
          const msgs = [];
          if (qtyZero) msgs.push(qtyMsg);
          if (endExpired) msgs.push(endMsg);
          if (contractBlocked) msgs.push(contractMsg);

          if (msgs.length === 3) {
            inlineMsg = msgs[0] + ', ' + msgs[1] + ' and ' + msgs[2];
          } else if (msgs.length === 2) {
            inlineMsg = msgs.join(' and ');
          } else if (msgs.length === 1) {
            inlineMsg = msgs[0];
          } else {
            inlineMsg = msg; // fallback
          }

          // show toast (LEX) and overlay near the row that triggered the action
          try {
            this.showToast('Action Blocked', inlineMsg, 'error');
          } catch (e) {
            // noop
          }

          this.showInlineError(inlineMsg, event);
          return;
        }
      } catch (e) {
        // se algo falhar na checagem, seguimos com a navegação normal (não bloquear por falha na checagem)
        console.warn('[mosaicDirectListPlace] error evaluating block conditions', e);
      }

      try {
        // LOG antes de navegar
        console.debug && console.debug('[mosaicDirectListPlace] navigating to contract details', { quoteId: row?.quoteId, quoteName: row?.ContractNumber });
        try {
          const contractData = {
            quoteName: row.ContractNumber,
            quoteId: row.quoteId,
            contractPO: row.PONumber,
            startDate: row.StartDate,
            endDate: row.EndDate,
            MOT: row.MOT,
            shipmentType: row.ShippingType,
            incoterm: row.Incoterm,
            contractType: row.contractType,
            downloadUrl: row.downloadUrl
          };
          sessionStorage.setItem("contractData", JSON.stringify(contractData));
        } catch (e) {
          console.warn('Could not write contractData to sessionStorage', e);
        }

        this[NavigationMixin.Navigate]({
          type: "comm__namedPage",
          attributes: {
            name: "contractdetails1__c"
          },
          state: {
            quoteName: row.ContractNumber,
            quoteId: row.quoteId,
            contractPO: row.PONumber,
            startDate: row.StartDate,
            endDate: row.EndDate,
            MOT: row.MOT,
            shipmentType: row.ShippingType,
            incoterm: row.Incoterm,
            contractType: row.contractType,
            downloadUrl: row.downloadUrl
          }
        });
      } catch (err) {
        this.showToast("Erro ao abrir Contrato", err, 'error');
      }
    }
  }

  // limpa a mensagem de erro do banner (fechar manual)
  clearError() {
    this.errorMessage = '';
    try {
      window.clearTimeout(this._errorTimeout);
    } catch (e) {
      // noop
    }
  }

  showInlineError(message, event) {
    try {
      // clear previous
      this.inlineErrorVisible = false;
      window.clearTimeout(this._inlineErrorTimeout);

      // try to locate a DOM element for the clicked row from composedPath
      let rect = null;
      try {
        const path = event && typeof event.composedPath === 'function' ? event.composedPath() : [];
        for (const el of path) {
          if (!el || !el.dataset) continue;
          if (el.dataset.rowKeyValue || el.dataset.rowKey) {
            rect = el.getBoundingClientRect();
            break;
          }
        }
      } catch (e) {
        rect = null;
      }

      if (!rect) {
        try { rect = (event && event.target && event.target.getBoundingClientRect) ? event.target.getBoundingClientRect() : null; } catch (e) { rect = null; }
      }

      let top = 80;
      let left = 24;
      if (rect) {
        top = rect.top + window.scrollY + rect.height + 6;
        left = Math.max(12, rect.left + window.scrollX + 12);
      } else if (event && event.clientY) {
        top = event.clientY + 8 + window.scrollY;
        left = event.clientX + 8 + window.scrollX;
      }

      this.inlineErrorMessage = message;
      this.inlineErrorStyle = `position: absolute; top: ${top}px; left: ${left}px; z-index: 1200;`;
      this.inlineErrorVisible = true;
      this._inlineErrorTimeout = window.setTimeout(() => { this.inlineErrorVisible = false; }, 6000);
    } catch (e) {
      // fallback to top banner
      try {
        this.errorMessage = message;
        window.clearTimeout(this._errorTimeout);
        this._errorTimeout = window.setTimeout(() => { this.errorMessage = ''; }, 6000);
      } catch (err) { /* noop */ }
    }
  }

  clearInlineError() {
    this.inlineErrorVisible = false;
    try { window.clearTimeout(this._inlineErrorTimeout); } catch (e) { /* noop */ }
  }

  async loadManual() {
    try {
      this.isLoading = true;

      // Não construir colunas manuais. Usar apenas as colunas fixas definidas em fetchPage.
      await this.fetchPage(1);
    } catch (err) {
      this.showToast("Erro (modo manual)", err, 'error');
    } finally {
      this.isLoading = false;
    }
  }

  handleNextPage() {
    if (this.isNextDisabled) return;
    this.fetchPage(this.pageNumber + 1);
  }

  handlePrevPage() {
    if (this.isPrevDisabled) return;
    this.fetchPage(this.pageNumber - 1);
  }

  handlePageClick(event) {
    const page = parseInt(event.currentTarget.dataset.page, 10);
    if (!isNaN(page) && page >= 1 && page <= this.totalPages && page !== this.pageNumber) {
      this.fetchPage(page);
    }
  }

  handleSave(event) {
    const updates = event.detail.draftValues.map((draft) => {
      const fields = { Id: draft.Id, ...draft };
      return updateRecord({ fields });
    });

    Promise.all(updates)
      .then(() => {
        this.showToast('Sucesso', "Registros atualizados", 'success');
        this.draftValues = [];
        return this.loadManual();
      })
      .catch((err) => this.showToast("Erro ao salvar", err, 'error'));
  }

  showToast(label, message, variant = "info") {
    Toast.show({ label, message, variant, mode: 'dismissible' }, this);
  }
}