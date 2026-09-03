import { LightningElement, track, api, wire } from 'lwc';
import { isBrazilRegion, formatLabel, toastMessageHandler } from 'c/pmc_dh_utilityJs';
import viewAddressDetails from "@salesforce/apex/PMC_DH_AddressesDetailController.viewAddressDetails";
import updateAddressDetails from "@salesforce/apex/PMC_DH_AddressesDetailController.updateAddressDetails";
import editAddressAccess from '@salesforce/customPermission/DH_Edit_Address';
import pmc_addNewAddress_addressName from "@salesforce/label/c.pmc_addNewAddress_addressName";
import pmc_addNewAddress_addressType from "@salesforce/label/c.pmc_addNewAddress_addressType";
import pmc_addNewUser_soldToAccount from "@salesforce/label/c.pmc_addNewUser_soldToAccount";
import pmc_addresses_status from "@salesforce/label/c.pmc_addresses_status";
import pmc_addNewAddress_zipCode from "@salesforce/label/c.pmc_addNewAddress_zipCode";
import pmc_addNewAddress_cep from "@salesforce/label/c.pmc_addNewAddress_cep";
import pmc_addNewAddress_address from "@salesforce/label/c.pmc_addNewAddress_address";
import pmc_addressDetails_addressLine from "@salesforce/label/c.pmc_addressDetails_addressLine";
import pmc_addNewAddress_city from "@salesforce/label/c.pmc_addNewAddress_city";
import pmc_addNewAddress_state from "@salesforce/label/c.pmc_addNewAddress_state";
import pmc_addNewAddress_cnpj from "@salesforce/label/c.pmc_addNewAddress_cnpj";
import pmc_addNewAddress_deliveryInstructions from "@salesforce/label/c.pmc_addNewAddress_deliveryInstructions";
import pmc_addressDetails_backToAds from "@salesforce/label/c.pmc_addressDetails_backToAds";
import pmc_addressDetails_edit from "@salesforce/label/c.pmc_addressDetails_edit";
import pmc_addressDetails_cancel from "@salesforce/label/c.pmc_addressDetails_cancel";
import pmc_addressDetails_update from "@salesforce/label/c.pmc_addressDetails_update";
import pmc_addressDetails_zipcodeError from "@salesforce/label/c.pmc_addressDetails_zipcodeError";
import pmc_addressDetails_cepError from "@salesforce/label/c.pmc_addressDetails_cepError";
import pmc_addressDetails_inAnalysis from "@salesforce/label/c.pmc_addressDetails_inAnalysis";
import pmc_addressDetails_validated from "@salesforce/label/c.pmc_addressDetails_validated";
import pmc_addressDetails_inValid from "@salesforce/label/c.pmc_addressDetails_in";
import pmc_inputElement_patternMismatchError from "@salesforce/label/c.pmc_inputElement_patternMismatchError";
import pmc_requestToDeliverShippingInformation_deliveryInstructions from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_deliveryInstructions";
import pmc_addresses_CNPJ_CPF from "@salesforce/label/c.pmc_addresses_CNPJ_CPF";
import pmc_addresses_stateSubscription from "@salesforce/label/c.pmc_addresses_stateSubscription";
import pmc_addresses_cnpjErrorMsg from "@salesforce/label/c.pmc_addresses_cnpjErrorMsg";
import pmc_addressDetails_duplicateAddressError from "@salesforce/label/c.pmc_addressDetails_duplicateAddressError";
import pmc_addNewAddress_phoneError from "@salesforce/label/c.pmc_addNewAddress_phoneError";
import pmc_addNewAddress_personOrOrganization from "@salesforce/label/c.pmc_addNewAddress_personOrOrganization";
import pmc_addNewAddress_cpf from '@salesforce/label/c.pmc_addNewAddress_cpf';
import pmc_addNewAddress_propertyFarmName from "@salesforce/label/c.pmc_addNewAddress_propertyFarmName";
import pmc_addNewAddress_country from '@salesforce/label/c.pmc_addNewAddress_country';
import pmc_addNewAddress_district from '@salesforce/label/c.pmc_addNewAddress_district'
import pmc_addNewAddress_addressNumber from '@salesforce/label/c.pmc_addNewAddress_addressNumber';
import pmc_addNewAddress_contactPhone from "@salesforce/label/c.pmc_addNewAddress_contactPhone";
import pmc_addNewAddress_contactEmail from '@salesforce/label/c.pmc_addNewAddress_contactEmail';
import pmc_addNewAddress_person from "@salesforce/label/c.pmc_addNewAddress_person";
import pmc_addNewAddress_organization from "@salesforce/label/c.pmc_addNewAddress_organization";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import COUNTRY_CODE from '@salesforce/schema/Account.BillingCountryCode';
import BILLING_STATE_CODE from '@salesforce/schema/Account.BillingStateCode';
const CPF = "CPF";
const CNPJ = "CNPJ";
const MASK_CPF = /^(\d{3})(\d{3})(\d{3})(\d{2})$/;
const MASK_CNPJ = /^([A-Z0-9]{2})([A-Z0-9]{3})([A-Z0-9]{3})([A-Z0-9]{4})([A-Z0-9]{2})$/i;
const MASK_ZIP = /^(\d{5})(\d{3})$/;
const DUPLICATE_ADDRESS = "pmc_address_duplicateDetected";
/**
 * A custom LWC for view/edit address details.
 * @alias Pmc_dh_addressDetails
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 * 
 * @example
 * <c-pmc_dh_address-details></c-pmc_dh_address-details>
 */
export default class Pmc_dh_addressDetails extends LightningElement {
  @track picklistData = {};
  @track pageObject = {};
  @track pageObjectCopy = {};
  isLocationBrazil = false;
  isValidated = false;
  isDisabled = true;
  isDisabledPermently = true;
  pageLoaded = false;
  isSpinner = true;
  isFieldMandatory = false;
  editAccess = editAddressAccess;
  strOldSoldToAcc = '';
  zipCodeMixLength = 5;
  zipCodeMaxLength = 10;
  propertyFarmNameMaxLength = 40;
  cepMaxLength = 9;
contactMinLength=8;
  contactMaxLength = 10;
  contactEmailMaxLength = 40;
  cnpjMaxLength = 14;
  cpfMaxLength = 11;
  addressNumberMaxLength = 10;
  error;
  stateSubscriptionMaxLength = 18;
  cnpjCpfSelector = "";
  isDuplicateAddress = false;
  cpfMandate = false;
  cnpjMandate = false;
  @api
  get recId() {
    return this._recId;
  }
  set recId(value) {
    if (value) {
      this._recId = value;
    }
  }
  _recId = '';
  /**
   * Label Details
   */
  @track labels = {
    pmc_addNewAddress_addressName,
    pmc_addNewAddress_addressType,
    pmc_addNewUser_soldToAccount,
    pmc_addresses_status,
    pmc_addNewAddress_zipCode,
    pmc_addNewAddress_cep,
    pmc_addNewAddress_address,
    pmc_addressDetails_addressLine,
    pmc_addNewAddress_city,
    pmc_addNewAddress_state,
    pmc_addNewAddress_cnpj,
    pmc_addNewAddress_deliveryInstructions,
    pmc_addressDetails_backToAds,
    pmc_addressDetails_edit,
    pmc_addressDetails_cancel,
    pmc_addressDetails_update,
    pmc_addressDetails_zipcodeError,
    pmc_addressDetails_cepError,
    pmc_addressDetails_validated,
    pmc_addressDetails_inAnalysis,
    pmc_addresses_CNPJ_CPF,
    pmc_addresses_stateSubscription,
    pmc_addressDetails_duplicateAddressError,
    pmc_addNewAddress_personOrOrganization,
    pmc_addNewAddress_cpf,
    pmc_addNewAddress_propertyFarmName,
    pmc_addNewAddress_district,
    pmc_addNewAddress_country,
    pmc_addNewAddress_addressNumber,
    pmc_addNewAddress_contactPhone,
    pmc_addNewAddress_contactEmail,
    pmc_addNewAddress_person,
    pmc_addNewAddress_organization,
    pmc_addressDetails_inValid,
    pmc_addNewAddress_phoneError
  }
  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if (isBrazilRegion()) {
      this.isLocationBrazil = !this.isLocationBrazil;
    }
    this.fetchAddressDetails();
  }
  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    // console.log('this.pageObject.strStatus: ',this.pageObject.strStatus );
    // console.log('edit access: ',this.editAccess );
    if (this.pageObject.strStatus === pmc_addressDetails_validated && this.editAccess) {
      this.isValidated = true;
    } else if (this.pageObject.strStatus === pmc_addressDetails_inValid) {
      this.isValidated = true;
    }
    else {
      this.isValidated = false;
    }
    // console.log(' this.isValidateds: ', this.isValidated );
    if (this.template.querySelector('.badge-style')) {
      this.template.querySelector('.badge-style').classList = ['slds-badge badge-style'];
    }
    if (this.pageObject.strStatus === pmc_addressDetails_inAnalysis) {
      this.template.querySelectorAll(".badge-style").forEach(item => item.classList.add("analysis"));
    } else if (this.pageObject.strStatus === pmc_addressDetails_validated) {
      this.template.querySelectorAll(".badge-style").forEach(item => item.classList.add("validated"));
    } else {
      this.template.querySelectorAll(".badge-style").forEach(item => item.classList.add("invalid"));
    }
  }
  _countries = [];
  statesAll = [];
  _countryToStates = {};
  selectedCountry;
  selectedState;
  @wire(getPicklistValues, {
    recordTypeId: '012000000000000AAA',
    fieldApiName: COUNTRY_CODE
  })
  wiredCountires({ data }) {
    this._countries = data?.values;
  }
  @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: BILLING_STATE_CODE })
  wiredStates({ data }) {
    if (!data) {
      return;
    }
    const validForNumberToCountry = Object.fromEntries(Object.entries(data.controllerValues).map(([key, value]) => [value, key]));
    this._countryToStates = data.values.reduce((accumulatedStates, state) => {
      const countryIsoCode = validForNumberToCountry[state.validFor[0]];
      return { ...accumulatedStates, [countryIsoCode]: [...(accumulatedStates?.[countryIsoCode] || []), state] };
    }, {});
  }
  get countries() {
    return this._countries;
  }
  get states() {
    this.statesAll = this._countryToStates[this.selectedCountry] || [];
    return this._countryToStates[this.selectedCountry] || [];
  }

  /**
   * Fetching Address Details 
   * @function fetchAddressDetails
   */
  fetchAddressDetails() {
    viewAddressDetails({
      strJunctionId: this._recId
    }).then(result => {
      if (result && Object.keys(result).length) {
        // console.log('OUTPUT : ',JSON.stringify(result));
        this.picklistData = result;
        this.pageObject = { ...result.addressData };
        if (this.pageObject?.strCountry) {
          this.selectedCountry = this.pageObject.strCountry;
        }


        if (this.pageObject.strPersonOrOrganization === 'Person') {

          this.cpfMandate = true;
          this.cnpjMandate = false;
        }
        if (this.pageObject.strPersonOrOrganization === 'Organization') {

          this.cnpjMandate = true;
          this.cpfMandate = false;
        }

        if (this.isLocationBrazil) {
          if (this.pageObject.strCnpj) {
            this.cnpjCpfSelector = CNPJ;
            this.pageObject.strCnpj = this.pageObject.strCnpj.replace(MASK_CNPJ, '$1.$2.$3/$4-$5');
          }
          if (this.pageObject.strCPF) {
            this.cnpjCpfSelector = CPF;
            this.pageObject.strCPF = this.pageObject.strCPF.replace(MASK_CPF, '$1.$2.$3-$4');
          }
        }
        this.pageObjectCopy = { ...this.pageObject };
        if (this.pageObject.strSoldToAcc) {
          this.strOldSoldToAcc = this.pageObject.strSoldToAcc;
        } else {
          this.strOldSoldToAcc = '';
        }
        if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
        }
      }
      this.pageLoaded = true;
      this.isSpinner = false;
    }).catch(error => {
      toastMessageHandler();
      this.error = error;
      this.pageLoaded = true;
      this.isSpinner = false;
    })
  }

  /**
   * On input change event handler 
   * @function handleDataChange
   * @param {event} event
   */
  handleDataChange(event) {

    if (event.detail.value !== 'undefined' && event.target && event.target.dataset) {
      this.pageObject[event.target.dataset.id] = event.detail.value;
      this.isDuplicateAddress = false;
    }
    // if (event.target.dataset.id === 'strZipcode')
    // {
    //    let rawValue = event.target.value.replace(/\D/g, ''); // Remove non-numeric characters
    //    if (rawValue.length > 8) {
    //        rawValue = rawValue.substring(0, 8);
    //    }
    //    if (rawValue.length > 5) {
    //        this.pageObject.strZipcode = `${rawValue.slice(0, 5)}-${rawValue.slice(5)}`;
    //    } else {
    //       this.pageObject.strZipcode = rawValue;
    //    }
    // }
    if (event.target.dataset.id === 'strCountry') {
      this.selectedCountry = event.detail.value;

    }
    if (event.target.dataset.id === 'strState') {
      this.selectedState = event.detail.value;

    }
    if (event.target.dataset.id === 'strZipcode') {
      this.template.querySelector('[data-id="strZipcode"]').errorMsg = [''];
    }
    if (event.target.dataset.id === "strDeliveryInstructions" || event.target.dataset.id === "strNumber") {
      if (event.target.dataset.id === "strDeliveryInstructions") {
        const inputValue = event.detail.value;
        const regex = /^[A-Za-z0-9#,./ -]*$/
        if (!regex.test(inputValue)) {
          event.target.setCustomValidity(formatLabel(pmc_inputElement_patternMismatchError, [pmc_requestToDeliverShippingInformation_deliveryInstructions]));
        } else {
          event.target.setCustomValidity('');
        }
        event.target.reportValidity();
      }
    }
    else {
      this.isFieldMandatory = true;
    }
  }

  /** On input blur event handler 
  * @function handleBlur
  * @param {event} event
  */
  handleBlur(event) {
    if (
      event.detail.value !== "undefined" &&
      event.target &&
      event.target.dataset
    ) {


      const inputValue = event.detail.value;
      if (event.target.dataset.id === 'strZipcode') {
        const regex1 = /^\d{5}-\d{3}$/;

        if (!regex1.test(event.detail.value)) {
          event.target.setCustomValidity(pmc_addressDetails_cepError);
          console.log('OUTPUT : here1');
        }
        if ((event.detail.value).length === 8) {
          event.target.removeReportErrorValidity();
          let valtemp = event.detail.value;
          this.pageObject.strZipcode = valtemp.replace(MASK_ZIP, '$1-$2');
          console.log('OUTPUT : here2');
        }

      }
      if (event.target.dataset.id === 'strCpf' || event.target.dataset.id === 'strCnpj') {

        if (inputValue.length === 11 || inputValue.length === 14) {
          event.target.removeReportErrorValidity();
          this.pageObject.strCnpjCpf = event.detail.value;
          if (inputValue.length === 11) {
            this.cnpjCpfSelector = CPF;
            this.pageObject.strCPF = this.pageObject.strCPF.replace(MASK_CPF, '$1.$2.$3-$4');
          }
          if (inputValue.length === 14) {
            this.cnpjCpfSelector = CNPJ;
            this.pageObject.strCnpj = this.pageObject.strCnpj.replace(MASK_CNPJ, '$1.$2.$3/$4-$5');
          }
        }
        else {
          event.target.setCustomValidity(pmc_addresses_cnpjErrorMsg);
          this.cnpjCpfSelector = '';
        }
      }
    }
  }
  /**
   * Unformat CNPJ/CPF fields on focus
   * @function handleInputFocus
   */
  handleInputFocus() {
    if (this.pageObject.strCnpjCpf) {
      this.pageObject.strCnpjCpf = this.pageObject.strCnpjCpf.replace(/\D/g, '');
    }
  }
  /**
   * Update address details save icon click
   * @function handleSaveInfo
   */
  handleSaveInfo() {
    if (this.handleErrorOnSave()) return;
    let zipcodeFlag = false;
    const regex1 = /^\d{5}-?\d{3}$/;
    if (this.isLocationBrazil) {
      if (!regex1.test(this.pageObject.strZipcode)) {
        this.template.querySelector('[data-id="strZipcode"]').errorMsg = [pmc_addressDetails_cepError];
      }
      else {
        this.zipcodeFlag = true;
      }
    }
    if (!this.isLocationBrazil) {
      const regex2 = /^\d{5}$/;
      if (!regex2.test(this.pageObject.strZipcode)) {
        this.template.querySelector('[data-id="strZipcode"]').errorMsg = [pmc_addressDetails_zipcodeError];
      }
      else {
        this.zipcodeFlag = true;
      }
    }
    if (this.zipcodeFlag) {
      if (this.pageObject.strCountry === 'BR') {
        this.pageObject.strcontactPhone = this.pageObject.strcontactPhone || "00000000000";
        this.pageObject.strcontactPhone = '(' + this.pageObject.strcontactPhone
          .match(/\d*/g).join('')
          .match(/(\d{0,2})(\d{0,5})(\d{0,4})/).slice(1)
          .map((a, i) => (a + [') ', '-', ''][i])).join('');
      }
      else {
        this.pageObject.strcontactPhone = this.pageObject.strcontactPhone || "0000000000";
        this.pageObject.strcontactPhone = '(' + this.pageObject.strcontactPhone
          .match(/\d*/g).join('')
          .match(/(\d{0,3})(\d{0,3})(\d{0,4})/).slice(1)
          .map((a, i) => (a + [') ', '-', ''][i])).join('');
      }
      console.log('this.pageObject.strcontactPhone : ', this.pageObject.strcontactPhone);
      if (this.pageObject?.strCPF) {
        this.pageObject.strCPF = this.pageObject.strCPF.replace(/\D/g, '');
      }


      if (this.pageObject?.strCnpj) {
        this.pageObject.strCnpj = this.pageObject.strCnpj.replace(/\D/g, '');
      }
      this.isSpinner = true;
      const pageObjectTemp = { ...this.pageObject };
      pageObjectTemp.boolMandatoryChanged = this.isFieldMandatory;
      pageObjectTemp.strStatus = this.isFieldMandatory ? 'In Analysis' : 'Validated';
      if (pageObjectTemp.strCnpjCpf) {
        delete pageObjectTemp.strCnpjCpf
      }
      updateAddressDetails({
        strOldSoldToAcc: this.strOldSoldToAcc,
        objAddressWrapper: pageObjectTemp
      }).then((response) => {
        if (response && Object.keys(response).length) {
          if (response.strStatusCode === "000") {
            this.isDisabled = !this.isDisabled;
            this.pageObject.strStatus = this.isFieldMandatory ? pmc_addressDetails_inAnalysis : pmc_addressDetails_validated;
            this.pageObjectCopy = { ...this.pageObject };
          }
          if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
            if (JSON.parse(JSON.stringify(response)).strStatusMessage === DUPLICATE_ADDRESS) {
              this.isDuplicateAddress = true;
            } else {
              toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
            }
          }
        }
        this.isSpinner = false;

      }).catch(error => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      })
    }

  }
  /**
   * Cancel icon handler
   * @function handleCloseEdit
   */
  handleCloseEdit() {
    this.isDisabled = !this.isDisabled;
    this.isDuplicateAddress = false;
    this.pageObject = {};
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      this.pageObject = { ...this.pageObjectCopy }
      this.template.querySelector(`[data-id='strDeliveryInstructions']`).reportValidity();
    })
    this.template.querySelectorAll(`[data-name]`).forEach((inputComponent) => {
      inputComponent.resetInput();
      inputComponent.updateIsRequired();
    })
  }
  /**
   * Edit icon handler
   * @function handleEditInfo
   */
  handleEditInfo() {
    this.isDisabled = !this.isDisabled;

  }
  /**
   * Redirecting to address list page
   * @function backToAddressHandler
   */
  backToAddressHandler() {
    const backBtn = false;
    const backEvent = new CustomEvent("backtoaddress",
      {
        detail: backBtn
      });
    this.dispatchEvent(backEvent);
  }
  /** 
   * Form fields validation 
   * @function handleErrorOnSave
   */
  handleErrorOnSave() {
    let allValid = true;
    let focusRef;
    this.template.querySelectorAll(`[data-id]`).forEach(inputComponent => {
      if (!inputComponent.reportValidity()) {
        allValid = false;
        if (!focusRef) focusRef = inputComponent;
      }
    });
    if (!allValid) {
      focusRef.focus();
      focusRef.scrollIntoView({ behavior: "smooth", block: "center" });
      return true;
    }
    return false;
  }
}