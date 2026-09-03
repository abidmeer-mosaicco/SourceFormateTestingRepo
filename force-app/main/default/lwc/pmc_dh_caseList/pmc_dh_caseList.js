import { LightningElement, track } from "lwc";
import { SORT_DIRECTION } from "c/pmc_dh_utilityJs";
import { NavigationMixin } from "lightning/navigation";
import { sortData, formatDate, urlRedirect, toastMessageHandler } from "c/pmc_dh_utilityJs";
import basePath from "@salesforce/community/basePath";
import searchCaseRecords from "@salesforce/apex/PMC_DH_CaseListViewController.searchCaseRecords";

import pmc_caseMgmt_caseNumber from "@salesforce/label/c.pmc_caseMgmt_caseNumber";
import pmc_caseMgmt_caseStatus from "@salesforce/label/c.pmc_caseMgmt_caseStatus";
import pmc_caseMgmt_issueReason from "@salesforce/label/c.pmc_caseMgmt_issueReason";
import pmc_caseMgmt_dateOpened from "@salesforce/label/c.pmc_caseMgmt_dateOpened";
import pmc_caseMgmt_lastUpdated from "@salesforce/label/c.pmc_caseMgmt_lastUpdated";
import pmc_caseMgmt_subject from "@salesforce/label/c.pmc_caseMgmt_subject";
import pmc_accountDetails_viewDetails from "@salesforce/label/c.pmc_accountDetails_viewDetails";
import pmc_caseMgmt_searchCases from "@salesforce/label/c.pmc_caseMgmt_searchCases";
import pmc_caseMgmt_filterStatus from "@salesforce/label/c.pmc_caseMgmt_filterStatus";
import pmc_caseMgmt_filterReason from "@salesforce/label/c.pmc_caseMgmt_filterReason";
import pmc_orderHistory_noResultsMsg from "@salesforce/label/c.pmc_orderHistory_noResultsMsg";
import pmc_caseHistory_open from "@salesforce/label/c.pmc_caseHistory_open";
import pmc_caseHistory_closed from "@salesforce/label/c.pmc_caseHistory_closed";
import PMC_DH_InProgress from "@salesforce/label/c.PMC_DH_InProgress";

const columns = [
  {
    label: pmc_caseMgmt_caseNumber,
    fieldName: "CaseNumber",
    type: "text",
    dataType: "number",
    sortable: true,
    defaultSortDirection: "desc",
    isAscSort: false
  },
  {
    label: pmc_caseMgmt_dateOpened,
    fieldName: "CreatedDate",
    type: "text",
    dataType: "date",
    sortable: true,
    defaultSortDirection: "desc",
    isAscSort: false
  },
  {
    label: pmc_caseMgmt_issueReason,
    fieldName: "PMC_SS_IssueReason__c",
    type: "text",
    sortable: true,
    defaultSortDirection: "desc",
    isAscSort: false
  },
  {
    label: pmc_caseMgmt_subject,
    fieldName: "Subject",
    type: "text",
    cellAttributes: {
      class: "fixedWidthCol"
    },
    sortable: true,
    defaultSortDirection: "desc",
    isAscSort: false
  },
  {
    label: pmc_caseMgmt_lastUpdated,
    fieldName: "LastModifiedDate",
    type: "text",
    dataType: "date",
    sortable: true,
    defaultSortDirection: "desc",
    isAscSort: false
  },
  {
    label: pmc_caseMgmt_caseStatus,
    fieldName: "PMC_SS_CaseStatus__c",
    type: "badge",
    sortable: true,
    defaultSortDirection: "desc",
    isAscSort: false,
    typeAttributes: {
      variant: "slds-badge_lightest"
    }
  },
  {
    label: "",
    fieldName: "",
    type: "link",
    typeAttributes: {
      rowActionName: pmc_accountDetails_viewDetails
    }
  }
];

const caseCreationDateField = "CreatedDate";
const topicPicklist = "topic";
const statusPicklist = "status";
const STATUS_BADGE_SUCCESS = "success";
const STATUS_BADGE_FINISHED = "finished";

/**
 * A custom LWC to display cases
 * @alias Pmc_dh_caseList
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_case-list></c-pmc_dh_case-list>
 */

export default class Pmc_dh_caseList extends NavigationMixin(LightningElement) {
  defaultSortOrder = SORT_DIRECTION.ASC;
  recordsPerPage = 10;
  pageLoaded = false;
  isSpinner = true;
  effAccId = "";
  isResultSetEmpty = false;
  @track columns = columns;
  @track caseList = [];
  @track filteredData = [];
  @track searchData = [];
  @track labels = {
    pmc_caseMgmt_searchCases,
    pmc_orderHistory_noResultsMsg,
    pmc_caseHistory_open,
    pmc_caseHistory_closed,
    PMC_DH_InProgress
  };
  @track filters = [
    {
      label: pmc_caseMgmt_filterReason,
      name: topicPicklist,
      options: []
    },
    {
      label: pmc_caseMgmt_filterStatus,
      name: statusPicklist,
      options: []
    }
  ];

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    let that = this;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.intervalId = setInterval(() => {
      if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
        this.effAccId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
        clearInterval(that.intervalId);
        this.getCaseList(true);
      }
    }, 100);
  }

  /**
   * Fetch all the cases
   * @function getCaseList
   * @param {object} caseWrapper - Request payload in case of search
   * @param {boolean} fetchAll - true if all records needs to be fetched, false for search case
   */
  getCaseList(fetchAll, caseWrapper) {
    this.isSpinner = true;
    searchCaseRecords({ caseWrapper, effAccId: this.effAccId })
      .then((cases) => {
        if (cases && Object.keys(cases).length) {
          if (JSON.parse(JSON.stringify(cases)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(cases)).statusCodeMessage.strStatusMessage)
          }
          this.updateCaseDetails(JSON.parse(JSON.stringify(cases.lstCases)), fetchAll);
        }
        
        this.pageLoaded = true;
        this.isSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.pageLoaded = true;
        this.isSpinner = false;
      });
  }

  /**
   * Updates case records
   * @function updateCaseDetails
   * @param {Object[]} cases
   */
  updateCaseDetails(cases, fetchAll = true) {
    let statusArr = [],
      topicArr = [];
    this.isResultSetEmpty = false;
    if (!fetchAll && cases.length === 0) {
      this.isResultSetEmpty = true;
    }
    cases.forEach((item) => {
      item.CreatedDate = formatDate(item.CreatedDate.split("T")[0]);
      item.LastModifiedDate = formatDate(item.LastModifiedDate.split("T")[0]);
      if (item.PMC_SS_IssueReason__c) {
        topicArr.push(item.PMC_SS_IssueReason__c);
      }
      if (item.PMC_SS_CaseStatus__c === "Open") {
        item.PMC_SS_CaseStatus__c = this.labels.pmc_caseHistory_open;
        item.badgeStyleClass = STATUS_BADGE_SUCCESS;
      } else if (item.PMC_SS_CaseStatus__c === "Closed") {
        item.PMC_SS_CaseStatus__c = this.labels.pmc_caseHistory_closed;
        item.badgeStyleClass = STATUS_BADGE_FINISHED;
      }
      else {
        item.PMC_SS_CaseStatus__c = this.labels.PMC_DH_InProgress;
      }
      if (item.PMC_SS_CaseStatus__c) {
        statusArr.push(item.PMC_SS_CaseStatus__c);
      }
    });
    if (fetchAll) {
      this.caseList = JSON.parse(JSON.stringify(cases));
    }
    this.filteredData = sortData(
      JSON.parse(JSON.stringify(cases)),
      caseCreationDateField,
      "date",
      SORT_DIRECTION.DESC
    );
    this.searchData = JSON.parse(JSON.stringify(this.filteredData));
    this.setColumnSortOrder();
    this.template
      .querySelector("c-pmc_dh_pagination")
      ?.setDataOnSearch(this.filteredData);
    this.setCaseFilters(statusArr, topicArr);
  }

  /**
   * Set the Case filters(Status and Issue Reason)
   * @function setCaseFilters
   * @param {Array} statuses
   * @param {Array} topics
   */
  setCaseFilters(statuses, topics) {
    this.filters.forEach((fltr) => {
      let dataArr = [];
      if (fltr.name === topicPicklist) {
        fltr.options = Array.from(new Set(topics));
      }
      if (fltr.name === statusPicklist) {
        fltr.options = Array.from(new Set(statuses));
      }
      fltr.options.forEach((opt) => {
        let option = {
          label: opt,
          value: opt
        };
        dataArr.push(option);
      });
      fltr.options = dataArr;
    });
    this.filters = JSON.parse(JSON.stringify(this.filters));
  }

  /**
   * Setting column sort order once sorting is applied
   * @function setColumnSortOrder
   */
  setColumnSortOrder() {
    this.columns = this.columns.map((col) => {
      if (col.fieldName === caseCreationDateField) {
        col.isAscSort = true;
      }
      return col;
    });
  }

  /**
   * Set default state of cases list
   * @function setDefaultMode
   */
  setDefaultMode() {
    this.filteredData = sortData(
      this.filteredData,
      caseCreationDateField,
      "date",
      SORT_DIRECTION.DESC
    );
    this.setColumnSortOrder();
    this.template
      .querySelector("c-pmc_dh_pagination")
      ?.setDataOnSearch(this.filteredData);
  }

  /**
   * Returns Search Results based on user inputs
   * @function handleSearch
   * @param {event} event
   */
  handleSearch(event) {
    let targetEl = event.detail.targetId;
    let searchJSON = JSON.parse(JSON.stringify(event.detail.searchObj));
    if (
      searchJSON?.strSearchInput?.length > 2 ||
      searchJSON?.fromDate ||
      searchJSON?.toDate
    ) {
      let caseWrapper = {
        strSearchTerm:
          searchJSON?.strSearchInput?.length > 2
            ? searchJSON?.strSearchInput
            : null,
        strFromDate:
          targetEl === "strSearchInput" ? null : searchJSON?.fromDate,
        strToDate: targetEl === "strSearchInput" ? null : searchJSON?.toDate
      };
      this.getCaseList(false, caseWrapper);
    } else {
      this.getCaseList(true);
    }
  }

  /**
   * Returns filter Results based on picklist selection
   * @function
   * @param {Event} event
   */
  handleApplyFilter(event) {
    this.isResultSetEmpty = false;
    let searchJSON = JSON.parse(JSON.stringify(event.detail.searchObj));
    if (searchJSON?.topic || searchJSON?.status) {
      this.filteredData = this.searchData.filter((data) => {
        if (searchJSON.status && searchJSON.topic) {
          return (
            data.PMC_SS_CaseStatus__c === searchJSON.status &&
            data.PMC_SS_IssueReason__c === searchJSON.topic
          );
        } else if (searchJSON.status) {
          return data.PMC_SS_CaseStatus__c === searchJSON.status;
        }
        return data.PMC_SS_IssueReason__c === searchJSON.topic;
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
   * Resets the case results
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
    this.getCaseList(true);
  }

  /**
   * Navigate to Case Details Page
   * @function navigateToCaseDetails
   * @param {Event} event
   */
  navigateToCaseDetails(event) {
    let caseId = event.detail.id;
    let caseItem = this.caseList.find((el) => el.Id === caseId);
    let url = `/case/${caseId}/${caseItem.Subject}?caseNumber=${caseItem.CaseNumber}`;
    this[NavigationMixin.GenerateUrl]({
      type: "standard__webPage",
      attributes: {
        url: `${basePath}${url}`
      }
    }).then((generatedUrl) => {
      urlRedirect(generatedUrl);
    });
  }

  /**
   * Updating filtered data to display only current page details
   * @function updatePaginatedData
   * @param {Event} event
   */
  updatePaginatedData(event) {
    this.filteredData = event.detail;
  }
}