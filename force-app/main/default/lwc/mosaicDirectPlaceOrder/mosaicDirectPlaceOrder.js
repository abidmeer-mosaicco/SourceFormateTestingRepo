// mosaicDirectList.js (modo 100% manual)
import { LightningElement, track, wire , api  } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from "lightning/messageService";
import ACCOUNT_SELECTION_CHANNEL from "@salesforce/messageChannel/AccountSelectionChannel__c";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { updateRecord } from "lightning/uiRecordApi";
import listRecordsPaged from "@salesforce/apex/MosaicDirectListController.listRecordsPaged";
import { getValueFromPath, mapRecordsToRows, applyAllFilters as applyAllFiltersHelper } from "./helper";



export default class MosaicDirectList extends NavigationMixin(LightningElement) {
  @api objectApiName;
  @api filterFieldName;
  @api dateFilterFieldName;
  @api endDateFilterFieldName;
  @api accountNamePath;
  @api manualFieldApiNames;
  @api manualFieldLabelNames;
  @api baseWhereClause;
  @api pageSize;
  @track columns = [
    {
      label: "Contract Number",
      fieldName: "SBQQ__Quote__r.Name",
      type: "text"
    },
    {
      label: "MOT",
      fieldName: "PMC_CPQ_ModeofTransportation__c",
      type: "text"
    }
  ];
  @track data = [];
  @track draftValues = [];
  @track searchTerm = "";
  @track dateFromValue = "";
  @track dateToValue = "";
  isLoading = false;
  subscription;
  selectedAccountIds = [];
  originalData = [];
  storageKey = "mosaic:selectedAccounts";
  noResults = false;
  noResultsMessage = "Nenhum registro encontrado.";
  pageNumber = 1;
  totalSize = 0;
  totalPages = 1;
  sortField = "LastModifiedDate";
  sortDir = "DESC";
  pageSize = 50;
  objectApiName = "SBQQ__QuoteLine__c";
  accountNamePath = "SBQQ__Quote__r.AccountId";

  @wire(MessageContext) messageContext;

  get isPrevDisabled() {
    return this.isLoading || this.pageNumber <= 1;
  }
  get isNextDisabled() {
    return this.isLoading || this.pageNumber >= this.totalPages;
  }

  _composeWhereClause() {
    const parts = [];
    if (this.selectedAccountIds?.length && this.accountNamePath) {
      const ids = this.selectedAccountIds.map((id) => `'${String(id).replace(/'/g, "\\'")}'`).join(",");
      parts.push(`${this.accountNamePath} IN (${ids})`);
    }
  // Filtro para o objeto relacionado SBQQ__Quote__c
  parts.push(
    "SBQQ__Quote__r.SBQQ__Type__c = 'Quote'",
    "SBQQ__Quote__r.SBQQ__Primary__c = true",
    "SBQQ__Quote__r.SBQQ__Status__c = 'Accepted'"
  );
    return parts.join(" AND ");
  }

  async fetchPage(page = 1) {
    try {
      this.isLoading = true;

      const fieldApiNames = [
        "SBQQ__Quote__r.Name",
        "PMC_CPQ_ModeofTransportation__c"
      ];

      const searchFieldApiNames = ["PMC_CPQ_ModeofTransportation__c"];

      const res = await listRecordsPaged({
        objectApiName: this.objectApiName,
        fieldApiNames,
        whereClause: this._composeWhereClause(),
        orderByField: this.sortField,
        orderDir: this.sortDir,
        pageSize: this.pageSize,
        pageNumber: page,
        searchTerm: this.searchTerm || null,
        searchFieldApiNames
      });

      const rows = mapRecordsToRows(res.records, this.columns, []);

      // Evita "duplo filtro" pelo helper: aplica filtros NÃO-textuais apenas
      const current = this.searchTerm;
      this.searchTerm = "";
      this.originalData = rows;
      this.data = this.applyAllFilters(rows);
      this.searchTerm = current;

      this.pageNumber = res.pageNumber || page;
      this.totalSize = res.totalSize || 0;
      this.totalPages = Math.max(1, Math.ceil(this.totalSize / this.pageSize));
    } catch (err) {
      this.showError("Erro ao paginar", err);
    } finally {
      this.isLoading = false;
    }
  }

  connectedCallback() {
    this.subscription = subscribe(this.messageContext, ACCOUNT_SELECTION_CHANNEL, (msg) => this.handleMessage(msg), { scope: APPLICATION_SCOPE });

    try {
      const stored = JSON.parse(localStorage.getItem(this.storageKey) || "[]");
      if (Array.isArray(stored) && stored.length) {
        this.selectedAccountIds = stored;
      }
    } catch (e) {
      console.error("Error parsing stored account IDs:", e);
      this.selectedAccountIds = [];
    }

    this.loadManual();
  }

  disconnectedCallback() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  getValueFromRow(row, path) {
    return getValueFromPath(row, path);
  }

  applyAllFilters(baseRows) {
    return applyAllFiltersHelper({
      rows: baseRows,
      columns: this.columns,
      searchTerm: this.searchTerm,
      dateFilterFieldName: null,
      endDateFilterFieldName: null,
      dateFromValue: this.dateFromValue,
      dateToValue: this.dateToValue,
      selectedAccountIds: this.selectedAccountIds,
      accountNamePath: this.accountNamePath
    });
  }

  // ===== Mensageria (seleção de contas) =====
  handleMessage(message) {
    this.selectedAccountIds = message.selectedAccountIds || [];

    if (!this.selectedAccountIds.length) {
      this.data = this.applyAllFilters(this.originalData || []);
      try {
        localStorage.removeItem(this.storageKey);
      } catch (e) {
        // eslint-disable-next-line no-console
        console.error("Error removing stored account IDs:", e);
      }
      return;
    }

    try {
      localStorage.setItem(this.storageKey, JSON.stringify(this.selectedAccountIds));
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error("Error storing selected account IDs:", e);
    }

    this.data = this.applyAllFilters(this.originalData || []);
  }

  handleSearchInput(event) {
    this.searchTerm = (event.target.value || "").toString().trim();
    this.fetchPage(1);
  }

  handleDateFromChange(event) {
    this.dateFromValue = event.target.value || "";
    this.data = this.applyAllFilters(this.originalData || []);
  }

  handleDateToChange(event) {
    this.dateToValue = event.target.value || "";
    this.data = this.applyAllFilters(this.originalData || []);
  }

  handleClearFilters() {
    this.selectedAccountIds = [];
    this.searchTerm = "";
    this.dateFromValue = "";
    this.dateToValue = "";
    this.noResults = false;
    this.noResultsMessage = "";
    this.data = this.applyAllFilters(this.originalData || []);
    try {
      localStorage.removeItem(this.storageKey);
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error("Error removing stored account IDs:", e);
    }
  }

  handleRowAction(event) {
    // Se quiser ação de navegação, ajuste aqui
  }

  async loadManual() {
    try {
      this.isLoading = true;
      await this.fetchPage(1);
    } catch (err) {
      this.showError("Erro (modo manual)", err);
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

  handleSave(event) {
    const updates = event.detail.draftValues.map((draft) => {
      const fields = { Id: draft.Id, ...draft };
      return updateRecord({ fields });
    });

    Promise.all(updates)
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Sucesso",
            message: "Registros atualizados",
            variant: "success"
          })
        );
        this.draftValues = [];
        return this.loadManual();
      })
      .catch((err) => this.showError("Erro ao salvar", err));
  }

  showError(title, error) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message: error?.body?.message || error?.message || String(error),
        variant: "error"
      })
    );
  }
}