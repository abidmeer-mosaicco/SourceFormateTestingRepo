import { LightningElement, track, wire } from "lwc";
import PMC_BrandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { CurrentPageReference } from "lightning/navigation";
import {
  fireEvent,
  sortData,
  formatDate,
  getTodayDate,
  isBrazilRegion,
  formatPhoneNumber,
  formatLabel,
  toastMessageHandler
} from "c/pmc_dh_utilityJs";
import getRecord from "@salesforce/apex/PMC_DH_LeadManagementController.getRecord";
import rejectLead from "@salesforce/apex/PMC_DH_LeadManagementController.rejectLead";
import updateAcceptedLeads from "@salesforce/apex/PMC_DH_LeadManagementController.updateAcceptedLeads";
import getLostOpportunityModal from "@salesforce/apex/PMC_DH_LeadManagementController.getLostOpportunityModal";
import updateOpportunitytoLost from "@salesforce/apex/PMC_DH_LeadManagementUtil.updateOpportunitytoLost";
import leadConversion from "@salesforce/apex/PMC_DH_LeadManagementController.leadConversion";

import pmc_orderHistory_noResultsMsg from "@salesforce/label/c.pmc_orderHistory_noResultsMsg";
import pmc_addresses_searchFilters from "@salesforce/label/c.pmc_addresses_searchFilters";
import pmc_searchFilters_filter from "@salesforce/label/c.pmc_searchFilters_filter";
import pmc_searchInput_search from "@salesforce/label/c.pmc_searchInput_search";
import pmc_addresses_apply from "@salesforce/label/c.pmc_addresses_apply";
import pmc_addresses_clear from "@salesforce/label/c.pmc_addresses_clear";
import pmc_leadManagement_acceptedLeads from "@salesforce/label/c.pmc_leadManagement_acceptedLeads";
import pmc_leadManagement_newLeads from "@salesforce/label/c.pmc_leadManagement_newLeads";
import pmc_leadManagement_searchLists from "@salesforce/label/c.pmc_leadManagement_searchLists";
import pmc_leadManagement_sortBy from "@salesforce/label/c.pmc_leadManagement_sortBy";
import pmc_leadManagement_creationDateAsc from "@salesforce/label/c.pmc_leadManagement_creationDateAsc";
import pmc_leadManagement_creationDateDesc from "@salesforce/label/c.pmc_leadManagement_creationDateDesc";
import pmc_leadManagement_farmSizeAsc from "@salesforce/label/c.pmc_leadManagement_farmSizeAsc";
import pmc_leadManagement_farmSizeDesc from "@salesforce/label/c.pmc_leadManagement_farmSizeDesc";
import pmc_leadManagement_lastNameAsc from "@salesforce/label/c.pmc_leadManagement_lastNameAsc";
import pmc_leadManagement_lastNameDesc from "@salesforce/label/c.pmc_leadManagement_lastNameDesc";
import pmc_userDetails_firstName from "@salesforce/label/c.pmc_userDetails_firstName";
import pmc_userDetails_lastName from "@salesforce/label/c.pmc_userDetails_lastName";
import pmc_userDetails_email from "@salesforce/label/c.pmc_userDetails_email";
import pmc_userDetails_phone from "@salesforce/label/c.pmc_userDetails_phone";
import pmc_leadManagement_region from "@salesforce/label/c.pmc_leadManagement_region";
import pmc_leadManagement_creationDate from "@salesforce/label/c.pmc_leadManagement_creationDate";
import pmc_leadManagement_stage from "@salesforce/label/c.pmc_leadManagement_stage";
import pmc_leadManagement_acceptLead from "@salesforce/label/c.pmc_leadManagement_acceptLead";
import pmc_leadManagement_rejectLead from "@salesforce/label/c.pmc_leadManagement_rejectLead";
import pmc_addresses_city from "@salesforce/label/c.pmc_addresses_city";
import pmc_leadManagement_stateProvince from "@salesforce/label/c.pmc_leadManagement_stateProvince";
import pmc_leadManagement_product from "@salesforce/label/c.pmc_leadManagement_product";
import pmc_leadManagement_crop from "@salesforce/label/c.pmc_leadManagement_crop";
import pmc_requestToDeliver_qty from "@salesforce/label/c.pmc_requestToDeliver_qty";
import pmc_leadManagement_dealOwner from "@salesforce/label/c.pmc_leadManagement_dealOwner";
import pmc_leadManagement_farmSize from "@salesforce/label/c.pmc_leadManagement_farmSize";
import pmc_caseMgmt_reopenComments from "@salesforce/label/c.pmc_caseMgmt_reopenComments";
import pmc_leadManagement_contactPreference from "@salesforce/label/c.pmc_leadManagement_contactPreference";
import pmc_leadManagement_lastContacted from "@salesforce/label/c.pmc_leadManagement_lastContacted";
import pmc_leadManagement_contactMethod from "@salesforce/label/c.pmc_leadManagement_contactMethod";
import pmc_userDetails_edit from "@salesforce/label/c.pmc_userDetails_edit";
import pmc_addressDetails_cancel from "@salesforce/label/c.pmc_addressDetails_cancel";
import pmc_userDetails_saveChanges from "@salesforce/label/c.pmc_userDetails_saveChanges";
import pmc_leadManagement_rejectReason from "@salesforce/label/c.pmc_leadManagement_rejectReason";
import pmc_leadManagement_confirmEdits from "@salesforce/label/c.pmc_leadManagement_confirmEdits";
import pmc_leadManagement_editChangeMsg from "@salesforce/label/c.pmc_leadManagement_editChangeMsg";
import pmc_leadManagement_confirm from "@salesforce/label/c.pmc_leadManagement_confirm";
import pmc_leadManagement_lostLead from "@salesforce/label/c.pmc_leadManagement_lostLead";
import pmc_leadManagement_lostLeadText from "@salesforce/label/c.pmc_leadManagement_lostLeadText";
import pmc_leadManagement_comment from "@salesforce/label/c.pmc_leadManagement_comment";
import pmc_inputElement_patternMismatchError from "@salesforce/label/c.pmc_inputElement_patternMismatchError";
import pmc_deleteAddress_no from "@salesforce/label/c.pmc_deleteAddress_no";
import pmc_leadManagement_yes from "@salesforce/label/c.pmc_leadManagement_yes";
import pmc_leadManagement_acceptLeadMsg from "@salesforce/label/c.pmc_leadManagement_acceptLeadMsg";
import pmc_leadManagement_contactedDateErrorMsg from "@salesforce/label/c.pmc_leadManagement_contactedDateErrorMsg";
import pmc_leadManagement_accordion from "@salesforce/label/c.pmc_leadManagement_accordion";

const BORDER_RAD_CLASS = "brdr-rad";
const CLOSEDLOST = "Closed Lost";
const OTHER = "Other";

/**
 * A custom LWC to display the Lead Details.
 * @alias Pmc_dh_leadsManagement
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 * @example
 * <c-pmc_dh_leads-management></c-pmc_dh_leads-management>
 */

export default class Pmc_dh_leadsManagement extends LightningElement {
  @wire(CurrentPageReference) pageRef;
  effAccId = "";
  isSpinner = false;
  isResultSetEmpty = false;
  sortByField = "";
  sortDir = "";
  pageLoaded = false;
  isNewLeadsList = true;
  showFilter = true;
  isRejectLeadModalOpen = false;
  disableRejectCTA = true;
  disableConfirmCTA = true;
  disableStageComment = true;
  selectedLeadId = "";
  isConfirmEditModalOpen = false;
  isClosedLostModal = false;
  isAcceptModalOpen = false;
  rejectModalWidth = "537px";
  editModalWidth = "400px";
  recordsPerPage = 3;
  maxDate;
  lostLeadComment = "";
  countryCode;
  @track searchFormObject = {
    strSearchInput: null
  };
  @track iconUrlObj = {
    arrowRightIconUrl: `${PMC_BrandingStaticResource}/icons/icon-arrowright.svg`
  };
  @track labels = {
    pmc_orderHistory_noResultsMsg,
    pmc_addresses_searchFilters,
    pmc_searchFilters_filter,
    pmc_searchInput_search,
    pmc_addresses_apply,
    pmc_addresses_clear,
    pmc_leadManagement_acceptedLeads,
    pmc_leadManagement_newLeads,
    pmc_leadManagement_searchLists,
    pmc_leadManagement_sortBy,
    pmc_leadManagement_creationDateAsc,
    pmc_leadManagement_creationDateDesc,
    pmc_leadManagement_farmSizeAsc,
    pmc_leadManagement_farmSizeDesc,
    pmc_leadManagement_lastNameAsc,
    pmc_leadManagement_lastNameDesc,
    pmc_userDetails_firstName,
    pmc_userDetails_lastName,
    pmc_userDetails_email,
    pmc_userDetails_phone,
    pmc_leadManagement_region,
    pmc_leadManagement_creationDate,
    pmc_leadManagement_stage,
    pmc_leadManagement_acceptLead,
    pmc_leadManagement_rejectLead,
    pmc_addresses_city,
    pmc_leadManagement_stateProvince,
    pmc_leadManagement_product,
    pmc_leadManagement_crop,
    pmc_requestToDeliver_qty,
    pmc_leadManagement_dealOwner,
    pmc_leadManagement_farmSize,
    pmc_caseMgmt_reopenComments,
    pmc_leadManagement_contactPreference,
    pmc_leadManagement_lastContacted,
    pmc_leadManagement_contactMethod,
    pmc_userDetails_edit,
    pmc_addressDetails_cancel,
    pmc_userDetails_saveChanges,
    pmc_leadManagement_rejectReason,
    pmc_leadManagement_confirmEdits,
    pmc_leadManagement_editChangeMsg,
    pmc_leadManagement_confirm,
    pmc_leadManagement_lostLead,
    pmc_leadManagement_lostLeadText,
    pmc_leadManagement_comment,
    pmc_deleteAddress_no,
    pmc_leadManagement_yes,
    pmc_leadManagement_acceptLeadMsg,
    pmc_leadManagement_contactedDateErrorMsg,
    pmc_leadManagement_accordion
  };
  @track sortByPicklist = [
    {
      label: this.labels.pmc_leadManagement_creationDateAsc,
      value: "datCreatedDate_asc"
    },
    {
      label: this.labels.pmc_leadManagement_creationDateDesc,
      value: "datCreatedDate_desc"
    },
    {
      label: this.labels.pmc_leadManagement_farmSizeAsc,
      value: "intFarmSize_asc"
    },
    {
      label: this.labels.pmc_leadManagement_farmSizeDesc,
      value: "intFarmSize_desc"
    },
    {
      label: this.labels.pmc_leadManagement_lastNameAsc,
      value: "strLastName_asc"
    },
    {
      label: this.labels.pmc_leadManagement_lastNameDesc,
      value: "strLastName_desc"
    }
  ];
  @track leadObj = {};
  @track leadsList = [];
  @track leadsFilteredList = [];
  @track lstClosedLost = [];

  /**
   * Lifecycle hook
   */
  connectedCallback() {
    this.countryCode = (isBrazilRegion()) ? "BR +55" : "US +1";
    this.maxDate = getTodayDate();
    this.effAccId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    if (window.innerWidth < 768) {
      this.showFilter = false;
    }
    this.fetchLeadRecords();
  }

  /**
   * Lifecycle hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    if (window.innerWidth < 768 && !this.showFilter) {
      this.template
        .querySelector(".card-header")
        .classList.add(BORDER_RAD_CLASS);
    }
    this.pageRendered = true;
  }

  /**
   * Get all the leads records on the basis of selected tab
   * @function fetchLeadRecords
   */
  fetchLeadRecords() {
    this.isResultSetEmpty = false;
    this.isSpinner = true;
    this.pageLoaded = false;
    this.leadsList = { lstRecordsData: [] };
    this.leadsFilteredList = { lstRecordsData: [] };
    this.leadObj = [];
    const tabSelected = this.isNewLeadsList ? "New" : "Opportunities";
    getRecord({ strTabType: tabSelected, strAccountid: this.effAccId })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
          }
          this.leadsList = JSON.parse(JSON.stringify(response));
          this.displayLeadRecords();
        }
        this.isSpinner = false;
        this.pageLoaded = true;
      })
      .catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
        this.pageLoaded = true;
      });
  }

  /**
   * Update lead records to be displayed
   * @function displayLeadRecords
   */
  displayLeadRecords() {
    this.leadsList?.lstRecordsData.forEach((lead) => {
      lead.datCreatedDate = lead.datCreatedDate
        ? formatDate(lead.datCreatedDate)
        : "";
      lead.strPhone = lead.strPhone ? formatPhoneNumber(lead.strPhone, this.countryCode) : "";
      lead.isMultipleProductAvailable = lead.lstProductFamiles?.length > 1;
      lead.isMultipleCropAvailable = lead.lstCrops?.length > 1;
      lead.intFarmSize = lead.strFarmSize?.split(" ")[0];
      lead.isEditDisabled = true;
    });
    this.leadsList?.lstRejectionResons.forEach((reason) => {
      if (reason.value === "Unresponsive") {
        reason.value = reason.label;
      }
    });
    this.leadsFilteredList = JSON.parse(JSON.stringify(this.leadsList));
    this.leadObj = JSON.parse(
      JSON.stringify(this.leadsFilteredList)
    ).lstRecordsData;
    this.getDefaultSortedView();
  }

  /**
   * Show/Hide search filters in mobile device
   * @function showSearchFilters
   */
  showSearchFilters() {
    this.showFilter = !this.showFilter;
    if (this.showFilter) {
      this.template
        .querySelector(".card-header")
        .classList.remove(BORDER_RAD_CLASS);
    } else {
      this.template
        .querySelector(".card-header")
        .classList.add(BORDER_RAD_CLASS);
    }
  }

  /**
   * Returns data type of the field
   * @param {string} field
   * @returns {string}
   */
  getDataType(field) {
    let dataType;
    switch (field) {
      case "datCreatedDate":
        dataType = "date";
        break;
      case "intFarmSize":
        dataType = "number";
        break;
      case "strLastName":
        dataType = "text";
        break;
      default:
        dataType = "text";
    }
    return dataType;
  }

  /** 
   * On input change event handler 
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    if (
      event.detail.value !== "undefined" &&
      event.target &&
      event.target.dataset
    ) {
      this.searchFormObject[event.target.dataset.id] =
        event.detail.value.trim();
    }
  }

  /**
   * On sort options change event handler
   * @function sortEventHandler
   * @param {Event} event
   */
  sortEventHandler(event) {
    if (event.detail.value && event.target.dataset.id === "sortBy") {
      const [fieldNm, sortDir] = event.detail.value.split("_");
      this.sortByField = fieldNm;
      this.sortDir = sortDir;
      fireEvent(this.pageRef, "colSortEv", {
        sortBy: fieldNm,
        datatype: this.getDataType(fieldNm),
        sortDirection: sortDir
      });
    }
  }

  /**
   * Handler for data change of lead info
   * @function handleLeadDataChange
   * @param {Event} event
   */
  handleLeadDataChange(event) {
    const recordId = event.target.dataset.recordIndex || this.selectedLeadId;
    const leadRecord = this.leadsFilteredList.lstRecordsData.find((lead) => lead.strRecordId === recordId);
    const leadTempRecord = this.leadObj.find((lead) => lead.strRecordId === recordId);
    if (event.detail.value !== "undefined" && event.target && event.target.dataset) {
      leadRecord[event.target.dataset.id] = event.target.type === "text" ? event.detail.value.trim() : event.detail.value;
      leadTempRecord[event.target.dataset.id] = event.target.type === "text" ? event.detail.value.trim() : event.detail.value;
    }
    if ((event.target.dataset.id === "strComments" || event.target.dataset.id === "rejectionReason" || event.target.dataset.id === "closedLost" || event.target.dataset.id === "strStageComments") &&
      (event.target.value !== "undefined" || event.target.value !== "null")) {
      leadRecord[event.target.dataset.id] = event.target.value.trim();
    }
    if (event.target.dataset.id === "rejectionReason" && event.target.value) {
      this.disableRejectCTA = false;
    }
    if (event.target.dataset.id === "strStage" && event.detail.value === CLOSEDLOST) {
      this.fetchLostLeadDetails();
      this.isClosedLostModal = true;
      this.selectedLeadId = event.target.dataset.recordIndex;
    }
    if (event.target.dataset.id === "closedLost" && event.target.value !== OTHER) {
      this.disableConfirmCTA = false;
      this.disableStageComment = true;
      this.lostLeadComment = "";
    } else if (event.target.dataset.id === "closedLost" && event.target.value === OTHER) {
      this.disableConfirmCTA = true;
      this.disableStageComment = false;
    }
    if (event.target.dataset.id === "strStageComments" && event.detail.value) {
      this.disableConfirmCTA = false;
      this.lostLeadComment = event.detail.value;
    } else if (event.detail.value === "") {
      this.disableConfirmCTA = true;
    }
    if (event.target.dataset.id === "strComments") {
      const inputValue = event.detail.value;
      const regex = /^[A-Za-z0-9#,./ -]*$/
      if (!regex.test(inputValue)) {
        event.target.setCustomValidity(formatLabel(pmc_inputElement_patternMismatchError, [event.target.label]));
      } else {
        event.target.setCustomValidity('');
      }
      event.target.reportValidity();
    }
  }

  /**
   * Sends the selected closed lost reason to BE and fetches lead records
   * @function confirmClosedLost
   */
  confirmClosedLost() {
    this.isSpinner = true;
    const updatedLeadInfo = this.leadObj.find(
      (lead) => lead.strRecordId === this.selectedLeadId
    );
    updateOpportunitytoLost({
      strOpportunityId: this.selectedLeadId,
      strLostReason: updatedLeadInfo.closedLost,
      strComment: this.lostLeadComment ? this.lostLeadComment : null
    }).then((response) => {
      if (response && Object.keys(response).length) {
        if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
        }
        if (response?.strStatusCode === "000") {
          this.closeLostModal();
          this.fetchLeadRecords();
        }
      }
      this.isSpinner = false;
    }).catch(() => {
      toastMessageHandler();
      this.isSpinner = false;
    })
  }

  /**
   * Closes the Lost Lead popup when cancel or 'X' is clicked
   * @function cancelClosedLostModel
   */
  cancelClosedLostModel() {
    const leadRecord = this.leadsFilteredList.lstRecordsData.find(
      (lead) => lead.strRecordId === this.selectedLeadId
    );
    const origionalLeadRecord = this.leadsList.lstRecordsData.find(
      (lead) => lead.strRecordId === this.selectedLeadId
    );
    const leadIndex = this.leadObj.findIndex((lead) => lead.strRecordId === this.selectedLeadId);
    this.leadObj[leadIndex].strStage = leadRecord.strStage = origionalLeadRecord.strStage;
    this.template.querySelector(`[data-id='strStage'][data-record-index="${this.selectedLeadId}"]`)?.resetValue(origionalLeadRecord.strStage);
    this.closeLostModal();
  }

  /**
   * Closes the Lost Lead popup
   * @function closeLostModal
   */
  closeLostModal() {
    this.template.querySelector(`[data-name='closedLost']`).value = "";
    this.lostLeadComment = "";
    this.isClosedLostModal = false;
    this.disableConfirmCTA = true;
    this.disableStageComment = true;
    this.selectedLeadId = "";
  }

  /**
   * Fetches reasons for closed lost
   * @function fetchLostLeadDetails
   */
  fetchLostLeadDetails() {
    this.isSpinner = true;
    getLostOpportunityModal()
      .then((response) => {
        if (response?.length) {
          this.lstClosedLost = JSON.parse(JSON.stringify(response));
        }
        this.isSpinner = false;
      }).catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
      })
  }

  /** 
   * On key up event from search input 
   * @function handleEnterKeyUp
   * @param {Event} event 
   */
  handleEnterKeyUp(event) {
    if (event.detail.keyCode === 13) {
      this.searchDataHandler(event);
    }
  }

  /**
   * Reset search inputs
   * @function clearSearchInputs
   */
  clearSearchInputs() {
    this.isResultSetEmpty = false;
    this.searchFormObject = {};
    this.leadsFilteredList = JSON.parse(JSON.stringify(this.leadsList));
    this.getDefaultSortedView();
  }

  /**
   * If Sort By option is selected, sort accordingly
   * @function getDefaultSortedView
   */
  getDefaultSortedView() {
    if (this.sortByField && this.sortDir) {
      this.leadsFilteredList.lstRecordsData = sortData(
        this.leadsFilteredList.lstRecordsData,
        this.sortByField,
        this.getDataType(this.sortByField),
        this.sortDir
      );
    }
    this.template
      .querySelector("c-pmc_dh_pagination")
      ?.setDataOnSearch(this.leadsFilteredList.lstRecordsData);
  }

  /**
   * Function Handler on selection of New Lead tab
   * @function newLeadsHandler
   */
  newLeadsHandler() {
    this.isNewLeadsList = true;
    this.refreshLeads();
  }

  /**
   * Function Handler on selection of Accepted Lead tab
   * @function acceptedLeadsHandler
   */
  acceptedLeadsHandler() {
    this.isNewLeadsList = false;
    this.refreshLeads();
  }

  /**
   * Refreshes the lead records
   * @function refreshLeads
   */
  refreshLeads() {
    this.sortByField = "";
    this.sortDir = "";
    this.template.querySelector(`[data-id='sortBy']`)?.resetInput();
    this.clearSearchInputs();
    this.highlightTab();
    this.fetchLeadRecords();
  }

  /**
   * Highlight the selected tab
   * @function highlightTab
   */
  highlightTab() {
    if (this.isNewLeadsList) {
      this.template.querySelector(".new").classList.add("dynamic-border");
      this.template
        .querySelector(".accepted")
        .classList.remove("dynamic-border");
    } else {
      this.template.querySelector(".new").classList.remove("dynamic-border");
      this.template.querySelector(".accepted").classList.add("dynamic-border");
    }
  }

  /**
   * Reject Lead Modal open handler
   * @function openRejectLeadModal
   * @param {Event} event 
   */
  openRejectLeadModal(event) {
    this.isRejectLeadModalOpen = !this.isRejectLeadModalOpen;
    this.selectedLeadId = event.target.dataset.recordIndex;
  }

  /**
   * Reject Lead Modal close handler
   * @function closeRejectLeadModal
   */
  closeRejectLeadModal() {
    this.template.querySelector(`[data-name='rejectionReason']`).value = "";
    this.disableRejectCTA = true;
    this.isRejectLeadModalOpen = false;
    this.selectedLeadId = "";
  }

  /**
   * Open the confirm Edit Modal on click of 'Save Changes' CTA
   * @function openConfirmEditModal
   * @param {Event} event
   */
  openConfirmEditModal(event) {
    this.isConfirmEditModalOpen = !this.isConfirmEditModalOpen;
    this.selectedLeadId = event.target.dataset.recordIndex;
  }

  /**
   * Close the confirm Edit Modal
   * @function cancelEdit
   */
  cancelEdit() {
    this.isConfirmEditModalOpen = false;
    this.selectedLeadId = "";
  }

  /**
   * Save updated lead info changes
   * @function confirmEdit
   */
  confirmEdit() {
    this.isSpinner = true;
    const updatedLeadInfo = this.leadObj.find(
      (lead) => lead.strRecordId === this.selectedLeadId
    );
    updateAcceptedLeads({
      strOpporId: this.selectedLeadId,
      wrpUpdate: {
        strStage: updatedLeadInfo.strStage,
        datContactedDate: updatedLeadInfo.datContactedDate,
        strContactMethod: updatedLeadInfo.strContactMethod,
        strComments: updatedLeadInfo.strComments
      }
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
        if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
        }
        if (response?.strStatusCode === "000") {
          this.updateLeadRecords();
          this.cancelEdit();
        }
      }
        this.isSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
      });
  }

  /**
   * Update Lead records with the updated data
   * @function updateLeadRecords
   */
  updateLeadRecords() {
    const updatedLeadInfo = this.leadObj.find(
      (lead) => lead.strRecordId === this.selectedLeadId
    );
    const filteredLead = this.leadsFilteredList.lstRecordsData.find(
      (lead) => lead.strRecordId === this.selectedLeadId
    );
    const selectedLead = this.leadsList.lstRecordsData.find(
      (lead) => lead.strRecordId === this.selectedLeadId
    );
    const fields = [
      "strContactMethod",
      "datContactedDate",
      "strComments",
      "strStage"
    ];
    fields.forEach((field) => {
      selectedLead[field] = updatedLeadInfo[field];
      filteredLead[field] = updatedLeadInfo[field];
    });
    selectedLead.isEditDisabled = true;
    filteredLead.isEditDisabled = true;
  }

  /**
   * Check if mandatory rejection reason is selected or not
   * @function isFormInvalid
   */
  isFormInvalid() {
    this.disableRejectCTA = false;
    const updatedLeadInfo = this.leadObj.find(
      (lead) => lead.strRecordId === this.selectedLeadId
    );
    if (!updatedLeadInfo.rejectionReason) {
      this.disableRejectCTA = true;
    }
    return this.disableRejectCTA;
  }


  /**
   * Function to handle reject lead
   * @function rejectLead
   */
  rejectLead() {
    if (this.isFormInvalid()) return;
    this.isSpinner = true;
    const updatedLeadInfo = this.leadObj.find(
      (lead) => lead.strRecordId === this.selectedLeadId
    );
    rejectLead({
      strLeadId: this.selectedLeadId,
      stRejectionReason:
        updatedLeadInfo.rejectionReason === "Unresponsive - Email" ||
          updatedLeadInfo.rejectionReason === "Unresponsive - Phone"
          ? "Unresponsive"
          : updatedLeadInfo.rejectionReason
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
        if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
        }
        if (response?.strStatusCode === "000") {
          this.closeRejectLeadModal();
          this.searchFormObject = {};
          this.fetchLeadRecords();
        }
      }
        this.isSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
      });
  }

  /**
   * Opens Accept Lead Modal
   * @function openAcceptLeadModal
   * @param {Event} event 
   */
  openAcceptLeadModal(event) {
    this.isAcceptModalOpen = true;
    this.selectedLeadId = event.target.dataset.recordIndex;
  }

  /**
   * Closes Accept Lead Modal
   * @function closeAcceptModalHandler
   */
  closeAcceptModalHandler() {
    this.isAcceptModalOpen = false;
    this.selectedLeadId = "";
  }

  /**
   * Accept Lead Handler
   * @function acceptLeadHandler
   */
  acceptLeadHandler() {
    this.isSpinner = true;
    leadConversion({
      strRecordId: this.selectedLeadId
    }).then((response) => {
      if (response && Object.keys(response).length) {
      if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
        toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
      }
      if (response?.strStatusCode === "000") {
        this.closeAcceptModalHandler();
        this.fetchLeadRecords();
      }
    }
      this.isSpinner = false;
    }).catch(() => {
      toastMessageHandler();
      this.isSpinner = false;
    })
  }

  /**
   * Check if the contacted date is valid
   * @function validateContactedDate
   * @param {string} recordId 
   */
  validateContactedDate(recordId) {
    if (
      this.template
        .querySelector(
          `[data-id='datContactedDate'][data-record-index='${recordId}']`
        )
        .reportValidity()
    ) {
      return true;
    }
    return false;
  }

  /**
   * Check if stage and contacted date is valid
   * @function validateMandatoryFields
   * @param {string} recordId
   * @returns
   */
  validateMandatoryFields(recordId) {
    if (
      this.template
        .querySelector(
          `[data-id='datContactedDate'][data-record-index='${recordId}']`
        )
        .reportValidity() &&
      this.template
        .querySelector(`[data-id='strStage'][data-record-index='${recordId}']`)
        .reportValidity()
      &&
      this.template
        .querySelector(`[data-id='strComments'][data-record-index='${recordId}']`)
        .reportValidity()
    ) {
      return true;
    }
    return false;
  }

  /**
   * 'Save Changes' CTA click handler
   * @function submitLeadInfo
   * @param {Event} event
   */
  submitLeadInfo(event) {
    if (this.validateMandatoryFields(event.target.dataset.recordIndex)) {
      this.openConfirmEditModal(event);
    }
  }

  /**
   * Enable the input fields on click of 'Edit'
   * @function editLeadInfo
   * @param {Event} event
   */
  editLeadInfo(event) {
    const recordIndex = event.target.dataset.recordIndex;
    const leadRecord = this.leadsFilteredList.lstRecordsData.find(
      (lead) => lead.strRecordId === recordIndex
    );
    leadRecord.isEditDisabled = false;
  }

  /**
   * Cancel Lead info editing
   * @function cancelLeadEdit
   * @param {Event} event
   */
  cancelLeadEdit(event) {
    const recordIndex = event.target.dataset.recordIndex;
    this.setDefaultValues(recordIndex);
    const leadRecord = this.leadsFilteredList.lstRecordsData.find(
      (lead) => lead.strRecordId === recordIndex
    );
    leadRecord.isEditDisabled = true;
  }

  /**
   * Reset field values
   * @function setDefaultValues
   * @param {string} recordId
   */
  setDefaultValues(recordId) {
    const leadRecord = this.leadsFilteredList.lstRecordsData.find(
      (lead) => lead.strRecordId === recordId
    );
    const origionalLeadRecord = this.leadsList.lstRecordsData.find(
      (lead) => lead.strRecordId === recordId
    );
    const tempLeadRecord = this.leadObj.find((lead) => lead.strRecordId === recordId);
    const fields = [
      "strContactMethod",
      "datContactedDate",
      "strComments",
      "strStage"
    ];

    fields.forEach((field) => {
      tempLeadRecord[field] = leadRecord[field] = origionalLeadRecord[field];
      if (field === "strComments" && this.template.querySelector(`[data-id='strComments']`)) {
        this.template.querySelector(`[data-id='strComments'][data-record-index="${recordId}"]`).value = origionalLeadRecord[field];
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
          this.template.querySelector(`[data-id='strComments'][data-record-index="${recordId}"]`).reportValidity();
        });
      }
      else {
        this.template.querySelector(`[data-id='${field}'][data-record-index="${recordId}"]`)?.resetValue(origionalLeadRecord[field]);
      }
    });
  }

  /**
   * Open Accordion on click of '>'
   * @function openAccordion
   * @param {Event} event
   */
  openAccordion(event) {
    const recordIndex = event.target.dataset.recordIndex;
    const accordionContent = this.template.querySelector(
      `.accordion-content[data-record-index="${recordIndex}"]`
    );
    const accordionIcon = this.template.querySelector(
      `.accordion-icon a img[data-record-index="${recordIndex}"]`
    );
    accordionContent.style.display =
      accordionContent.style.display === "block" ? "none" : "block";
    accordionIcon.classList.toggle("down");
    this.cancelLeadEdit(event);
  }

  /**
   * Search input handler
   * @function searchDataHandler
   */
  searchDataHandler() {
    this.isResultSetEmpty = false;
    if (
      this.searchFormObject.strSearchInput &&
      this.searchFormObject.strSearchInput.length > 2
    ) {
      let filteredList = JSON.parse(
        JSON.stringify(this.leadsList.lstRecordsData)
      ).filter((lead) => {
        if (lead.strSearchdata) {
          return lead.strSearchdata
            .toLowerCase()
            .includes(this.searchFormObject.strSearchInput.toLowerCase());
        }
        return false;
      });
      this.leadsFilteredList.lstRecordsData = filteredList;
      if (this.leadsFilteredList.lstRecordsData.length === 0) {
        this.isResultSetEmpty = true;
      }
    } else {
      this.leadsFilteredList.lstRecordsData = JSON.parse(
        JSON.stringify(this.leadsList.lstRecordsData)
      );
    }
    this.getDefaultSortedView();
  }

  /**
   * Updating filtered data to display only current page details
   * @function updatePaginatedData
   * @param {Event} event
   */
  updatePaginatedData(event) {
    this.leadsFilteredList.lstRecordsData = event.detail;
  }
}