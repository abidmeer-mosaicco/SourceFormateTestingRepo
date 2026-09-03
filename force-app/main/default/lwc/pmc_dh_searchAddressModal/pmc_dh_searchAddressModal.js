import { LightningElement, api, track, wire } from 'lwc';
import { fireEvent } from "c/pmc_dh_utilityJs";
import { CurrentPageReference } from "lightning/navigation";
import pmc_address_searchAddressTitle from "@salesforce/label/c.pmc_address_searchAddressTitle";
import pmc_address_selectAddress from "@salesforce/label/c.pmc_address_selectAddress";
import pmc_address_confirmSelection from "@salesforce/label/c.pmc_address_confirmSelection";
import pmc_address_cancel from "@salesforce/label/c.pmc_address_cancel";
import pmc_address_searchPlaceholder from "@salesforce/label/c.pmc_address_searchPlaceholder";

export default class Pmc_dh_searchAddressModal extends LightningElement {
  @wire(CurrentPageReference) pageRef;

  @track labels = {
    pmc_address_searchAddressTitle,
    pmc_address_selectAddress,
    pmc_address_confirmSelection,
    pmc_address_cancel,
    pmc_address_searchPlaceholder
  }

  modalWidth = "700px";
  @track searchInput = '';
  @track filteredShipToLst = [];
  @track _selectedShipTo = '';

  @track _openSearchAddressModal = false;
  @api
  get openSearchAddressModal() {
    return this._openSearchAddressModal;
  }
  set openSearchAddressModal(value) {
    this._openSearchAddressModal = value;
  }

  @track _indexProduct;
  @api
  set indexProduct(value) {
    this._indexProduct = value;
  }
  get indexProduct() {
    return this._indexProduct;
  }

  @track _indexShipment;
  @api
  set indexShipment(value) {
    this._indexShipment = value;
  }
  get indexShipment() {
    return this._indexShipment;
  }

  @track _listShipToOptions;
  @api
  set listShipToOptions(value) {
    this._listShipToOptions = JSON.parse(JSON.stringify(value));
    
  }
  get listShipToOptions() {
    return this._listShipToOptions;
  }

  @track _lstCartItems;
  @api
  set lstCartItems(value) {
    this._lstCartItems = value;
  }
  get lstCartItems() {
    return this._lstCartItems;
  }

  /**
   * Close Switch Account Modal
   * @function closeSwitchAccountModal
   */
  closeSearchAddressModal(event, selectionChanged = false) {
    this.searchInput = '';
    this._openSearchAddressModal = false;
    let detail = {
      indexProduct: this._indexProduct,
      indexShipment: this._indexShipment,
      selectedShipTo: this._selectedShipTo,
      selectionChanged: !!selectionChanged,
    };
    fireEvent(this.pageRef, "selectedShipToEvent", detail);
    this.dispatchEvent(new CustomEvent('closesearchaddressmodal', {
      detail
    }));
  }

  /**
   * Close Switch Account Modal
   * @function closeSwitchAccountModal
   */
  confirmSearchAddressModal(event) {
    let targetValue = this.template.querySelector('input[name="options"]:checked')?.value;
    !!targetValue && (this._selectedShipTo = targetValue);
    this.closeSearchAddressModal(event, true);
  }

  /** 
   * Set the value of searchInput on input change 
   * @function handleDataChange
   * @param {Event} event 
   * */
  handleDataChange(event) {
    if(event.detail.value !== "undefined") {
      this.searchInput = event.detail.value.trim();
    }
  }

  searchAddressHandler() {
    if(this.searchInput.length > 2) {
      this.filteredShipToLst = this._listShipToOptions.filter((shipTo) => 
        (shipTo.label.toLowerCase()).includes(this.searchInput.toLowerCase())
      )
    }
    else {
      this.filteredShipToLst = JSON.parse(JSON.stringify(this._listShipToOptions));
    }
  }

  searchAddressKeypressHandler() {
    this.searchAddressHandler();
  }

  connectedCallback() {
    this._selectedShipTo = this._lstCartItems[this._indexShipment].strShipTo;
    this._listShipToOptions.forEach((item) => {
      item.isChecked = (item.value === this._selectedShipTo) ? true : false;
    });
    this.filteredShipToLst = JSON.parse(JSON.stringify(this._listShipToOptions));
  }

}