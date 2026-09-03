import { LightningElement, track } from 'lwc';
import basePath from "@salesforce/community/basePath";
import { SORT_DIRECTION, sortData, formatDate, toastMessageHandler, setWithExpirationFromSession, getWithExpirationFromSession } from "c/pmc_dh_utilityJs";
import fetchDocumentRecords from "@salesforce/apex/PMC_DH_DocumentListViewController.fetchDocumentRecords";
import getDocDownload from "@salesforce/apex/PMC_DH_DocumentDownloadController.getDocDownload";

import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";
import pmc_documentsList_myDocument from "@salesforce/label/c.pmc_documentsList_myDocument";
import pmc_documentsList_documentText from "@salesforce/label/c.pmc_documentsList_documentText";
import pmc_documentsList_searchDocuments from "@salesforce/label/c.pmc_documentsList_searchDocuments";
import pmc_documentsList_documentList from "@salesforce/label/c.pmc_documentsList_documentList";
import pmc_documentsList_documentName from "@salesforce/label/c.pmc_documentsList_documentName";
import pmc_documentsList_type from "@salesforce/label/c.pmc_documentsList_type";
import pmc_caseDetails_docDateAdded from "@salesforce/label/c.pmc_caseDetails_docDateAdded";
import pmc_documentsList_relatedTo from "@salesforce/label/c.pmc_documentsList_relatedTo";
import pmc_orderHistory_download from "@salesforce/label/c.pmc_orderHistory_download";
import pmc_documentsList_view from "@salesforce/label/c.pmc_documentsList_view";
import pmc_documentsList_documentType from "@salesforce/label/c.pmc_documentsList_documentType";
import pmc_orderDetails_order from "@salesforce/label/c.pmc_orderDetails_order";
import pmc_orderHistory_noResultsMsg from "@salesforce/label/c.pmc_orderHistory_noResultsMsg";

const datAddedField = "datDocumentAddedDate";
const typePicklist = "type";

const defaultActions = [
  { label: pmc_orderHistory_download, value: "download" },
  { label: pmc_documentsList_view, value: "view" }
];

const columns = [
  {
    label: pmc_documentsList_documentName,
    fieldName: "strDocumentName",
    type: "text",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_documentsList_type,
    fieldName: "strDocumentType",
    type: "text",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_caseDetails_docDateAdded,
    fieldName: "datDocumentAddedDate",
    type: "text",
    dataType: "date",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_documentsList_relatedTo,
    fieldName: "strOrderNumber",
    type: "text",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    type: "action",
    cellAttributes: {
      class: "rightAlignedButton"
    },
    typeAttributes: {
      rowActions: defaultActions,
      menuAlignment: "auto",
      iconName: "utility:down",
      iconSize: "medium",
      variant: "border"
    }
  }
];

/**
 * A custom LWC to view and download documents.
 * @alias Pmc_dh_documentList
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_document-list></c-pmc_dh_document-list>
 */

export default class Pmc_dh_documentList extends LightningElement {
  @track crumbs = [
    { label: pmc_breadcrumb_homepage, url: `${basePath}/`, isActive: false },
    { label: pmc_documentsList_myDocument, url: "", isActive: true },
  ];

  @track labels = {
    pmc_documentsList_myDocument,
    pmc_documentsList_documentText,
    pmc_documentsList_searchDocuments,
    pmc_documentsList_documentList,
    pmc_orderDetails_order,
    pmc_orderHistory_noResultsMsg
  }
  
   @track showOnlyApprovedCoA = true;

  columns = columns;
  defaultSortOrder = SORT_DIRECTION.ASC;
  recordsPerPage = 10;
  @track docList = [];
  @track filteredData = [];
  @track searchData = [];
  effAccId;
  isResultSetEmpty = false;
  pageLoaded = false;
  isSpinner = false;

  @track filters = [
    {
      label: pmc_documentsList_documentType,
      name: typePicklist,
      options: []
    }
  ];
  
  handleCheckboxChange(event) {
    this.showOnlyApprovedCoA = event.target.checked;
    this.filterDocuments();
  }
  
  filterDocuments(objToFilter = 'docList') {
    if (this.showOnlyApprovedCoA) {
        this[objToFilter] = this[objToFilter].filter(doc => {
          // Check if the document is one of the specified types
          const isCOA = ['CertificateOfAnalysis', 'COA', 'Certificate of Analysis', 'CoA'].includes(doc.strDocumentType);
      
          // If it is a COA-type document, ensure it is approved; otherwise, keep it
          return !isCOA || doc?.inspLotUsageDecision === 'Approved';
      });
    }
   // this.template.querySelector("c-pmc_dh_pagination")?.setDataOnSearch(this.filteredData);
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.fetchDocList();
  }

  /**
   * Fetches entire document list
   * @function fetchDocList
   */
  fetchDocList() {
    if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
      this.effAccId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    }
    this.isSpinner = true;
    fetchDocumentRecords({
      searchParams: {
        strSearchTerm: '',
        datFromDate: null,
        datToDate: null,
      },
      strEffectiveAccId: this.effAccId,
    }).then((doc) => {
      if (doc && Object.keys(doc).length) {
        if (JSON.parse(JSON.stringify(doc)).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(doc)).statusCodeMessage.strStatusMessage)
        }
        if (doc?.lstDocuments && doc?.lstDocumentTypes) {
          this.docList = JSON.parse(JSON.stringify(doc.lstDocuments));
          if (this.docList.length > 1000) {
            this.docList.length = 1000;
          }
          let docTypeArr = JSON.parse(JSON.stringify(doc.lstDocumentTypes))
          this.setDocTypeFilters(docTypeArr);
          this.filterDocuments();
          this.updateDocRecords(JSON.parse(JSON.stringify(this.docList)));
          this.pageLoaded = true;
        }
      }
      this.isSpinner = false;
    }).catch(() => {
      toastMessageHandler();
      this.pageLoaded = true;
      this.isSpinner = false;
    })
  }

  /**
   * Updates document records
   * @function updateDocRecords
   * @param {Array} docs
   * @param {boolean} fetchAll  
   */
  updateDocRecords(docs, fetchAll = true) {
    docs.forEach((item) => {
      item.Id = item.strInvoiceNumber;
      item.datDocumentAddedDate = item.datDocumentAddedDate ? formatDate(item.datDocumentAddedDate) : "";
      item.strOrderNumber = item.strOrderNumber ? `${this.labels.pmc_orderDetails_order} ${item.strOrderNumber}` : "";
    });
    if (fetchAll) {
      this.docList = JSON.parse(JSON.stringify(docs));
      this.filterDocuments();
    }
    this.filteredData = sortData(JSON.parse(JSON.stringify(docs)), datAddedField, "date", SORT_DIRECTION.ASC);
    this.filterDocuments('filteredData');
    this.searchData = JSON.parse(JSON.stringify(this.filteredData));
    this.setColumnSortOrder();
    
    this.template.querySelector("c-pmc_dh_pagination")?.setDataOnSearch(this.filteredData);
  }

  
  // handleSearch(event) {
  //   let targetEl = event.detail.targetId;
  //   let searchJSON = JSON.parse(JSON.stringify(event.detail.searchObj));
  //   let type = (event.detail.type || "invoice").toLowerCase();
  //   let documentType = type === 'invoice' ? `${type}_` : "";

  //   if (
  //       searchJSON?.strSearchInput?.length > 2 ||
  //       searchJSON?.fromDate ||
  //       searchJSON?.toDate
  //   ) {
  //       let contractWrapper = {
  //           strSearchTerm:
  //               searchJSON?.strSearchInput?.length > 2
  //                   ? `${documentType}${searchJSON?.strSearchInput}`
  //                   : null,
  //           datFromDate: targetEl === "strSearchInput" ? null : searchJSON?.fromDate,
  //           datToDate: targetEl === "strSearchInput" ? null : searchJSON?.toDate
  //       };
  //       this.getContractList(false, contractWrapper);
  //   } else {
  //       this.getContractList(true);
  //   }
  // }
  
  mapDocumentType(inputType) {
      // Define the mapping
      const eventTypeMap = {
          "Bill of Lading": "BillOfLading",
          "Certificate of Analysis": "CertificateOfAnalysis",
          "Credit Memo": "CreditMemo",
          "Debit Memo": "DebitMemo",
          "Invoice": "Invoice",
          "Nota Fiscal": "NotaFiscal"
      };

      // Return the mapped value or the transformed input without spaces
      return eventTypeMap[inputType] || inputType?.replace(/\s+/g, '');
  }
  /**
   * Returns Search Results based on user inputs
   * @function handleSearch
   * @param {event} event 
   */
  handleSearch(event) {
    
    const targetEl = event.detail.targetId;
    //let type = this.mapDocumentType(event.detail.type) || "Invoice";
    let type = this.mapDocumentType(event.detail.type);
    let documentType = type ? `${type}_` : "";
    let searchJSON = JSON.parse(JSON.stringify(event.detail.searchObj));
    this.isResultSetEmpty = false;
    
    if (searchJSON?.strSearchInput?.length > 2 || searchJSON?.fromDate || searchJSON?.toDate) {
      this.isSpinner = true;
      fetchDocumentRecords({
        searchParams: {
          strSearchTerm:
                searchJSON?.strSearchInput?.length > 2
                    ? `${documentType}${searchJSON?.strSearchInput}`
                    : null,
          datFromDate: targetEl === "strSearchInput" ? null : searchJSON?.fromDate,
          datToDate: targetEl === "strSearchInput" ? null : searchJSON?.toDate,
          documentType:documentType
        },
        strEffectiveAccId: this.effAccId
      })
        .then((docs) => {
          if (docs && Object.keys(docs).length) {
            if (JSON.parse(JSON.stringify(docs)).statusCodeMessage?.strStatusMessage) {
              toastMessageHandler(JSON.parse(JSON.stringify(docs)).statusCodeMessage.strStatusMessage)
            }
            if (docs.lstDocuments.length > 1000) {
              docs.lstDocuments.length = 1000;
            }
            if (docs.lstDocuments.length === 0) {
              this.isResultSetEmpty = true;
            }
            this.updateDocRecords(JSON.parse(JSON.stringify(docs.lstDocuments)), true);
            this.setDocTypeFilters(JSON.parse(JSON.stringify(docs.lstDocumentTypes)));
          }
          this.pageLoaded = true;
          this.isSpinner = false;
        })
        .catch(() => {
          toastMessageHandler();
          this.pageLoaded = true;
          this.isSpinner = false;
        });
    } else {
      this.fetchDocList();
    }
  }

  /**
   * Set the document type filters
   * @function setDocTypeFilters
   * @param {Array} docTypes 
   */
  setDocTypeFilters(docTypes) {
    // Check if document_filters exists in session storage
    const currAccID = sessionStorage.getItem('EFFECTIVE_ACCOUNT_ID');
   const storedFilters = sessionStorage.getItem(`document_filters_${currAccID}`);
    
    // if (storedFilters) {
    //     // If exists, assign it to this.filters after parsing
    //     this.filters = JSON.parse(storedFilters);
    // } else {
        // If not, process the docTypes and set it in session storage
        let uniqueType = [...new Map(docTypes.map(item => [item.value, item])).values()];
        
        this.filters.forEach((el) => {
            if (el.name === typePicklist) {
                el.options = uniqueType;
            }
        });
        
        this.filters = JSON.parse(JSON.stringify(this.filters));
        sessionStorage.setItem(`document_filters_${currAccID}`, JSON.stringify(this.filters));
   // }
  }

  /**
   * Returns filter results based on document type picklist selection
   * @function handleApplyFilter
   * @param {event} event 
   */
  handleApplyFilter(event) {
    this.isResultSetEmpty = false;
    let searchJSON = JSON.parse(JSON.stringify(event.detail.searchObj));
    if (searchJSON?.type) {
      this.filteredData = this.searchData.filter((data) => {
        return data.strDocumentType.includes(searchJSON.type)
      });
    } else {
      this.filteredData = JSON.parse(JSON.stringify(this.searchData));
    }
    if (this.filteredData.length === 0) {
      this.isResultSetEmpty = true;
    }
    this.setDefaultMode();
  }

  /**
   * View and Downloads the Documents
   * @function rowActionHandler
   * @param {event} event 
   */
  rowActionHandler(event) {
    this.isSpinner = true;
    let recId = event.detail.id;
    const selectedDocRecord = this.filteredData.find((el) => el.strInvoiceNumber === recId);
    let headerDetails = JSON.parse(sessionStorage.getItem('HEADER_DETAILS'));
    let languageSelected=headerDetails.langPrefeWrapper.strUserLanguage;
    getDocDownload({
      objData: {
        strDocumentCode: selectedDocRecord.strDocumentCode,
        strDeliveryNumber: selectedDocRecord.mapDocumentIdentifier.strDeliveryNumber ? selectedDocRecord.mapDocumentIdentifier.strDeliveryNumber : "",
        strItemNumber: selectedDocRecord.mapDocumentIdentifier.strItemNumber ? selectedDocRecord.mapDocumentIdentifier.strItemNumber : "",
        strBillingDocNumber: selectedDocRecord.mapDocumentIdentifier.strBillingDocNumber ? selectedDocRecord.mapDocumentIdentifier.strBillingDocNumber : "",
     strDocLanguage:languageSelected
      }
    }).then((response) => {
      if (response && Object.keys(response).length) {
        if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
        }
        if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusCode === "100") {
          toastMessageHandler("PMC_DH_GenericTechnicalError")
        }
        if (response?.objData && response.objData.strStatusCode === "S") {
          const blob = this.base64toBlob(JSON.parse(JSON.stringify(response.objData)).strData, "application/pdf");
          const blobUrl = URL.createObjectURL(blob);
          if (event.detail.value === "view") {
            this.previewOrDownloadDoc(blobUrl);
          }
          if (event.detail.value === "download") {
            this.previewOrDownloadDoc(blobUrl, selectedDocRecord.strDocumentName);
          }
        }
      }
      this.isSpinner = false;
    }).catch(() => {
      toastMessageHandler();
      this.isSpinner = false;
    })

  }

  /**
   * Preview or Download document in system
   * @function previewOrDownloadDoc
   * @param {string} docName 
   * @param {string} url 
   */
  previewOrDownloadDoc(url, docName) {
    var link = document.createElement('a');
    link.href = url;
    if (!docName) {
      link.target = '_blank';
    } else {
      link.download = docName;
    }
    link.click();
  }

  /**
   * Convert base64 data to Blob
   * @function base64toBlob
   * @param {string} b64Data 
   * @param {string} contentType 
   * @param {number} sliceSize 
   */
  base64toBlob(b64Data, contentType = "", sliceSize = 512) {
    const byteCharacters = window.atob(b64Data);
    const byteArrays = [];
    for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
      const slice = byteCharacters.slice(offset, offset + sliceSize);

      const byteNumbers = new Array(slice.length);
      for (let i = 0; i < slice.length; i++) {
        byteNumbers[i] = slice.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      byteArrays.push(byteArray);
    }
    const blob = new Blob(byteArrays, { type: contentType });
    return blob;
  }

  /**
   * Setting column sort order once sorting is applied
   * @function setColumnSortOrder
   */
  setColumnSortOrder() {
    this.columns = this.columns.map((col) => {
      if (col.fieldName === datAddedField) {
        col.isAscSort = false;
      }
      return col;
    });
  }

  /**
   * Set default state of quote list
   * @function setDefaultMode
   */
  setDefaultMode() {
    this.filteredData = sortData(this.filteredData, datAddedField, "date", SORT_DIRECTION.ASC);
    this.setColumnSortOrder();
    this.template.querySelector("c-pmc_dh_pagination")?.setDataOnSearch(this.filteredData);
  }

  /**
   * Resets the filter results
   * @function clearFilters
   */
  clearFilters() {
    this.isResultSetEmpty = false;
    if (this.searchData.length === 0) {
      this.isResultSetEmpty = true;
    }
    this.filteredData = JSON.parse(JSON.stringify(this.searchData));
    this.setDefaultMode();
  }

  /**
   * Resets the search results
   * @function clearSearchInputs
   */
  clearSearchInputs() {
    this.isResultSetEmpty = false;
    this.fetchDocList();
  }

  /**
   * Updating filtered data to display only current page details
   * @function updatePaginatedData
   * @param {event} event 
   */
  updatePaginatedData(event) {
    this.filteredData = event.detail;
  }
}