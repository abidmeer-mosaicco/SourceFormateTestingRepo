import { LightningElement, track } from "lwc";
import getAddressDetails from "@salesforce/apex/PMC_DH_AddressesDetailController.getAddressDetails";
import deleteAddresses from "@salesforce/apex/PMC_DH_AddressesDetailController.deleteAddresses";
import editAddressAccess from '@salesforce/customPermission/DH_Edit_Address';
import {
  registerListener,
  unregisterAllListeners,
  SORT_DIRECTION,
  sortData,
  isBrazilRegion,
  toastMessageHandler
} from "c/pmc_dh_utilityJs";

import pmc_addresses_addressName from "@salesforce/label/c.pmc_addresses_addressName";
import pmc_addresses_CNPJ_CPF from "@salesforce/label/c.pmc_addresses_CNPJ_CPF";
import pmc_addresses_addressType from "@salesforce/label/c.pmc_addresses_addressType";
import pmc_addresses_address from "@salesforce/label/c.pmc_addresses_address";
import pmc_addresses_zipCode from "@salesforce/label/c.pmc_addresses_zipCode";
import pmc_addresses_cep from "@salesforce/label/c.pmc_addresses_cep";
import pmc_addresses_city from "@salesforce/label/c.pmc_addresses_city";
import pmc_addresses_state from "@salesforce/label/c.pmc_addresses_state";
import pmc_addresses_status from "@salesforce/label/c.pmc_addresses_status";
import pmc_accountDetails_viewEdit from "@salesforce/label/c.pmc_accountDetails_viewEdit";
import pmc_accountDetails_delete from "@salesforce/label/c.pmc_accountDetails_delete";
import pmc_accountDetails_viewDetails from "@salesforce/label/c.pmc_accountDetails_viewDetails";
import pmc_addresses_searchFilters from "@salesforce/label/c.pmc_addresses_searchFilters";
import pmc_addresses_searchAddresses from "@salesforce/label/c.pmc_addresses_searchAddresses";
import pmc_searchFilters_filter from "@salesforce/label/c.pmc_searchFilters_filter";
import pmc_addresses_apply from "@salesforce/label/c.pmc_addresses_apply";
import pmc_addresses_clear from "@salesforce/label/c.pmc_addresses_clear";
import pmc_deleteAddress_title from "@salesforce/label/c.pmc_deleteAddress_title";
import pmc_deleteAddress_confirmation from "@salesforce/label/c.pmc_deleteAddress_confirmation";
import pmc_deleteAddress_text from "@salesforce/label/c.pmc_deleteAddress_text";
import pmc_deleteAddress_no from "@salesforce/label/c.pmc_deleteAddress_no";
import pmc_deleteAddress_delete from "@salesforce/label/c.pmc_deleteAddress_delete";
import pmc_deleteAddress_success from "@salesforce/label/c.pmc_deleteAddress_success";
import pmc_deleteAddress_successText from "@salesforce/label/c.pmc_deleteAddress_successText";
import pmc_deleteAddress_successMessage from "@salesforce/label/c.pmc_deleteAddress_successMessage";
import pmc_orderHistory_noResultsMsg from "@salesforce/label/c.pmc_orderHistory_noResultsMsg";
import pmc_addressDetails_inAnalysis from "@salesforce/label/c.pmc_addressDetails_inAnalysis";
import pmc_addressDetails_inValid from "@salesforce/label/c.pmc_addressDetails_in";
import pmc_addressDetails_validated from "@salesforce/label/c.pmc_addressDetails_validated";
import pmc_addresses_stateSubscription from "@salesforce/label/c.pmc_addresses_stateSubscription";

const SUCCESS_BADGE_CLASS = "success";
const BORDER_RAD_CLASS = "brdr-rad";
const STATE_SUBSCRIPTION_FIELD_NAME = "strStateSubscription";
const CNPJ_CPF_FIELD_NAME = "strCnpjCpf"
const ADDRESS_NAME_FIELD = "strAddressName";
const ZIPCODE_FIELD_NAME = "strZipcode";
const MASK_CPF = /^(\d{3})(\d{3})(\d{3})(\d{2})$/;
const MASK_CNPJ =  /^([A-Z0-9]{2})([A-Z0-9]{3})([A-Z0-9]{3})([A-Z0-9]{4})([A-Z0-9]{2})$/i;


const defaultActions = [
  { label: pmc_accountDetails_viewEdit, value: "view_edit-details" },
  { label: pmc_accountDetails_delete, value: "delete" }
];

const otherActions = [
  { label: pmc_accountDetails_viewDetails, value: "view_details" }
];

const columns = [
  {
    label: pmc_addresses_addressName,
    fieldName: "strAddressName",
    type: "text",
    sortable: true,
    defaultSortDirection: "desc",
    isAscSort: false
  },
  {
    label: pmc_addresses_CNPJ_CPF,
    fieldName: "strCnpjCpf",
    type: "text",
    dataType: "alphanumeric",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_addresses_addressType,
    fieldName: "strAddressType",
    type: "text",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_addresses_address,
    fieldName: "strAddress",
    type: "text",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_addresses_stateSubscription,
    fieldName: "strStateSubscription",
    type: "text",
    dataType: "number",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_addresses_zipCode,
    fieldName: "strZipcode",
    type: "text",
    dataType: "number",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_addresses_city,
    fieldName: "strCity",
    type: "text",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_addresses_state,
    fieldName: "strState",
    type: "text",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true
  },
  {
    label: pmc_addresses_status,
    fieldName: "strStatus",
    type: "badge",
    sortable: true,
    defaultSortDirection: "asc",
    isAscSort: true,
    typeAttributes: {
      variant: "slds-badge_lightest"
    }
  },
  {
    type: "action",
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
 * A custom LWC to display addresses list.
 * @alias Pmc_dh_addressesList
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_addresses-list></c-pmc_dh_addresses-list>
 */

export default class Pmc_dh_addressesList extends LightningElement {
  @track statusOptions = [];
  @track searchFormObject = {};
  @track addressData = [];
  @track filteredData = [];
  isDeleteAddressModal = false;
  isDeleteSuccess = false;
  isAddressDetailsVisible = false;
  editAddress = editAddressAccess;
  columns = columns;
  effectiveAccountId;
  @track labels = {
    pmc_addresses_searchFilters,
    pmc_addresses_searchAddresses,
    pmc_searchFilters_filter,
    pmc_addresses_apply,
    pmc_addresses_clear,
    pmc_addresses_status,
    pmc_deleteAddress_confirmation,
    pmc_deleteAddress_text,
    pmc_deleteAddress_no,
    pmc_deleteAddress_title,
    pmc_deleteAddress_delete,
    pmc_deleteAddress_success,
    pmc_deleteAddress_successText,
    pmc_deleteAddress_successMessage,
    pmc_orderHistory_noResultsMsg,
    pmc_addressDetails_inAnalysis,
    pmc_addressDetails_validated,
    pmc_addressDetails_inValid
  };
  showFilter = true;
  pageLoaded = false;
  pageRendered = false;
  defaultSortOrder = SORT_DIRECTION.ASC;
  recId = "";
  deletedAddress = "";
  shipTo = "";
  soldTo = "";
  junctionObjId = "";
  recordsPerPage = 5;
  isResultSetEmpty = false;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if (window.innerWidth < 768) {
      this.showFilter = false;
    }
    if (isBrazilRegion()) {
      this.columns.find((col) => col.fieldName === ZIPCODE_FIELD_NAME).label =
        pmc_addresses_cep;
    } else {
      this.columns = this.columns.filter((col) => {
        return !(col.fieldName === CNPJ_CPF_FIELD_NAME || col.fieldName === STATE_SUBSCRIPTION_FIELD_NAME);
      });
    }
    this.fetchAddressDetails(true);
    registerListener("newAddressDetails", this.displayNewAddress, this);
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return
    if (window.innerWidth < 768 && !this.showFilter) {
      this.template
        .querySelector(".card-header")
        .classList.add(BORDER_RAD_CLASS);
    }
    this.pageRendered = true;
  }

  /**
   * @function fetchAddressDetails
   * Gets all the addresses associated with the user
   * @param {boolean} defaultSort - True if default sorting on "Address Name" needs to be applied
   */
  fetchAddressDetails(defaultSort = false) {
    this.pageLoaded = false;
    if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
      this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    }
    getAddressDetails({
      strAccountId: this.effectiveAccountId
    })
      .then((data) => {
        if (data && Object.keys(data).length) {
          this.addressData = JSON.parse(JSON.stringify(data)).addressData;
          this.statusOptions = JSON.parse(JSON.stringify(data)).lstPickList;
          if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
          }
          this.addressData.forEach((address) => {
            console.log('this.editAddress', this.editAddress);
            console.log('address.strStatus', address.strStatus);
            // console.log('this.labels.pmc_addressDetails_inAnalysis', this.labels.pmc_addressDetails_inAnalysis);
            // console.log('this.labels.pmc_addressDetails_inValid', this.labels.pmc_addressDetails_inValid);

            if (address.strStatus === this.labels.pmc_addressDetails_inAnalysis || !this.editAddress ) {
              address.rowLevelActions = otherActions;
            }
            if (address.strStatus === this.labels.pmc_addressDetails_inValid ) {
              address.rowLevelActions = defaultActions;
            }
            if (address.strStatus === this.labels.pmc_addressDetails_validated) {
              address.badgeStyleClass = SUCCESS_BADGE_CLASS;
            }
            if (isBrazilRegion()) {
              if (address.strCnpj) {
                address.strCnpjCpf = address.strCnpj.replace(MASK_CNPJ, '$1.$2.$3/$4-$5');
              }
              if (address.strCPF) {
                address.strCnpjCpf = address.strCPF.replace(MASK_CPF, '$1.$2.$3-$4');
              }
            }
          });
          const addressNameColumn = this.columns.find(
            (col) => col.fieldName === ADDRESS_NAME_FIELD
          );
          if (defaultSort) {
            this.filteredData = sortData(
              this.addressData,
              ADDRESS_NAME_FIELD,
              "string",
              SORT_DIRECTION.ASC
            );
            addressNameColumn.isAscSort = false;
            addressNameColumn.defaultSortDirection = SORT_DIRECTION.DESC;
            this.addressData = JSON.parse(JSON.stringify(this.filteredData));
          } else {
            this.filteredData = JSON.parse(JSON.stringify(this.addressData));
            addressNameColumn.defaultSortDirection = SORT_DIRECTION.ASC;
            addressNameColumn.isAscSort = true;
          }
        }

        this.searchFormObject.strStatus = null;
        this.searchFormObject.strSearchInput = null;
        this.pageLoaded = true;
      })
      .catch((err) => {
        toastMessageHandler();
        console.log("Error while fetching user details", err);
        this.addressData = [];
        this.filteredData = [];
        this.pageLoaded = true;
      });
  }

  /**
   * @function showSearchFilters
   * Hide or show Search Filters in mobile device
   */
  showSearchFilters() {
    this.showFilter = !this.showFilter;
    if (this.showFilter) {
      this.template
        .querySelector(".card-header")
        .classList.remove(BORDER_RAD_CLASS);
    }
    else {
      this.template
        .querySelector(".card-header")
        .classList.add(BORDER_RAD_CLASS);
    }
  }

  /**
   * @function displayNewAddress
   * Fetches the address details and display it in the addresses list once a new address gets added
   * @param {object} newAddress
   */
  displayNewAddress(newAddress) {
    if (newAddress) {
      this.fetchAddressDetails();
    }
  }

  /** On key up event from search input 
   * @function handleEnterKeyUp
   * @param {event} event
   */
  handleEnterKeyUp(event) {
    if (event.detail.keyCode === 13) {
      this.applyFilterHandler();
    }
  }

  /** On input change event handler 
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    if (
      event.detail.value !== "undefined" &&
      event.target &&
      event.target.dataset
    ) {
      this.searchFormObject[event.target.dataset.id] = event.detail.value;
    }
  }

  /**
   * @funtion applyFilterHandler
   * Search input handler and apply filter handler
   */
  applyFilterHandler() {
    this.isResultSetEmpty = false;
    if (
      this.searchFormObject.strSearchInput &&
      this.searchFormObject.strSearchInput.length > 2
    ) {
      this.filteredData = this.addressData.filter((data) => {
        if (data.strSearchString) {
          return data.strSearchString
            .toLowerCase()
            .includes(this.searchFormObject.strSearchInput.toLowerCase());
        }
        return false;
      });
      if (this.filteredData.length === 0) {
        this.isResultSetEmpty = true;
      }
    } else {
      this.filteredData = JSON.parse(JSON.stringify(this.addressData));
    }
    if (this.searchFormObject.strStatus) {
      this.filteredData = this.filteredData.filter((data) => {
        return data.strStatus === this.searchFormObject.strStatus;
      });
      if (this.filteredData.length === 0) {
        this.isResultSetEmpty = true;
      }
    }
    this.filteredData = sortData(
      this.filteredData,
      ADDRESS_NAME_FIELD,
      "string",
      SORT_DIRECTION.ASC
    );
    this.setColumnSortOrder();
    this.template.querySelector("c-pmc_dh_pagination")?.setDataOnSearch(this.filteredData);
  }

  /**
   * @function clearFilterHandler
   * Clears all the filter values
   */
  clearFilterHandler() {
    this.isResultSetEmpty = false;
    this.searchFormObject.strStatus = null;
    this.searchFormObject.strSearchInput = null;
    this.filteredData = sortData(
      JSON.parse(JSON.stringify(this.addressData)),
      ADDRESS_NAME_FIELD,
      "string",
      SORT_DIRECTION.ASC
    );
    this.setColumnSortOrder();
    this.template.querySelector("c-pmc_dh_pagination")?.setDataOnSearch(this.filteredData);
  }

  /** 
   * Setting column sort order once sorting is applied
   * @function setColumnSortOrder
   */
  setColumnSortOrder() {
    this.columns = this.columns.map(
      (col) => {
        if (col.fieldName === ADDRESS_NAME_FIELD) {
          col.isAscSort = false;
        }
        return col;
      });
  }

  /**
   * @function rowActionsHandler
   * Address row action handler
   * @param {Event} event 
   */
  rowActionsHandler(event) {
    this.recId = event.detail.id;

    if (
      event.detail.value === "view_details" ||
      event.detail.value === "view_edit-details"
    ) {
      this.isAddressDetailsVisible = true;
      this.addressData.forEach((el) => {
        if (el.strRecId === this.recId) {
          this.junctionObjId = el.strJunctionRecId;
        }
      })
    }

    if (event.detail.value === "delete") {
      this.isDeleteAddressModal = true;
      this.isDeleteSuccess = false;
      this.addressData.forEach((el) => {
        if (el.strRecId === this.recId) {
          let address = `${el.strAddressName || ''} ${el.strAddress || ''} ${el.strCity || ''}${el.strState ? ',' : ''} ${el.strState || ''} ${el.strZipcode || ''}`;
          this.deletedAddress = address;
          this.shipTo = el.strRecId;
        }
      })
    }
  }

  /**
   * Deleting the selected address
   * @function deleteAddressHandler
   */
  deleteAddressHandler() {
    this.pageLoaded = false;
    deleteAddresses({
      shipTo: this.shipTo,
    }).then((response) => {
      if (response && Object.keys(response).length) {
        if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
        }
        if (response?.strStatusCode === "000") {
          this.isDeleteSuccess = true;
          this.fetchAddressDetails(true);
        }
      }
      this.pageLoaded = true
    }).catch(error => {
      toastMessageHandler();
      console.log('error', error);
      this.pageLoaded = true
    })
  }

  /**
   * Closing the Delete Address popup
   * @function closeDeleteAddressHandler
   */
  closeDeleteAddressHandler() {
    this.isDeleteAddressModal = false;
  }

  /**
   * @function handleAddressDetail
   * Handler to display updated addresses list
   * @param {Event} event 
   */
  handleAddressDetail(event) {
    this.isAddressDetailsVisible = event.detail;
    this.fetchAddressDetails(true);
  }

  /**
   * Updating filtered data to display only current page details
   * @function updatePaginatedData
   * @param {Event} event 
   */
  updatePaginatedData(event) {
    this.filteredData = event.detail;
  }

  /**
   * Lifecycle Hook
   */
  disconnectedCallback() {
    unregisterAllListeners(this);
  }
}