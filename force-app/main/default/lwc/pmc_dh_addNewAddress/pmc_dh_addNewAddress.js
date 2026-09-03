import { LightningElement, track, wire, api } from "lwc";
import pmc_brandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { getRecord } from "lightning/uiRecordApi";
import Id from "@salesforce/user/Id";
import USER_ACCOUNT_FIELD from "@salesforce/schema/User.AccountId";

import { fireEvent, isBrazilRegion, formatLabel, toastMessageHandler } from "c/pmc_dh_utilityJs";
import { CurrentPageReference } from "lightning/navigation";

import getNewAddressStateDetails from "@salesforce/apex/PMC_DH_ShipToAddressCreationController.getNewAddressStateDetails";
import createShipToAddress from "@salesforce/apex/PMC_DH_ShipToAddressCreationController.createShipToAddress";

import pmc_addNewAddress_title from "@salesforce/label/c.pmc_addNewAddress_title";
import pmc_addNewAddress_addressName from "@salesforce/label/c.pmc_addNewAddress_addressName";
//MSD-1056
//import pmc_addNewAddress_CustomerNameHelpText from '@salesforce/label/c.pmc_addNewAddress_CustomerNameHelpText';
import pmc_addNewAddress_personOrOrganization from "@salesforce/label/c.pmc_addNewAddress_personOrOrganization";
import pmc_addNewAddress_person from "@salesforce/label/c.pmc_addNewAddress_person";
import pmc_addNewAddress_organization from "@salesforce/label/c.pmc_addNewAddress_organization";
import pmc_addNewAddress_propertyFarmName from "@salesforce/label/c.pmc_addNewAddress_propertyFarmName";
import pmc_addNewAddress_contactPhone from "@salesforce/label/c.pmc_addNewAddress_contactPhone";
import pmc_addNewAddress_contactEmail from '@salesforce/label/c.pmc_addNewAddress_contactEmail';
import pmc_addNewAddress_cpf from '@salesforce/label/c.pmc_addNewAddress_cpf';
import pmc_addNewAddress_country from '@salesforce/label/c.pmc_addNewAddress_country';
import pmc_addNewAddress_district from '@salesforce/label/c.pmc_addNewAddress_district'
import pmc_addNewAddress_addressNumber from '@salesforce/label/c.pmc_addNewAddress_addressNumber';
import pmc_addNewAddress_addressType from "@salesforce/label/c.pmc_addNewAddress_addressType";
import pmc_addNewAddress_cnpj from "@salesforce/label/c.pmc_addNewAddress_cnpj";
import pmc_addNewAddress_address from "@salesforce/label/c.pmc_addNewAddress_address";
import pmc_addressDetails_addressLine from "@salesforce/label/c.pmc_addressDetails_addressLine";
import pmc_addNewAddress_city from "@salesforce/label/c.pmc_addNewAddress_city";
import pmc_addNewAddress_state from "@salesforce/label/c.pmc_addNewAddress_state";
import pmc_addNewAddress_zipCode from "@salesforce/label/c.pmc_addNewAddress_zipCode";
import pmc_addNewAddress_cep from "@salesforce/label/c.pmc_addNewAddress_cep";
import pmc_addNewAddress_deliveryInstructions from "@salesforce/label/c.pmc_addNewAddress_deliveryInstructions";
import inputElement_patternMismatchError from "@salesforce/label/c.inputElement_patternMismatchError";
import pmc_requestToDeliverShippingInformation_deliveryInstructions from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_deliveryInstructions";
import pmc_addressDetails_cepError from "@salesforce/label/c.pmc_addressDetails_cepError";
import pmc_addressDetails_zipcodeError from "@salesforce/label/c.pmc_addressDetails_zipcodeError";
import pmc_addresses_CNPJ_CPF from "@salesforce/label/c.pmc_addresses_CNPJ_CPF";
import pmc_addresses_stateSubscription from "@salesforce/label/c.pmc_addresses_stateSubscription";
import pmc_addresses_cnpjErrorMsg from "@salesforce/label/c.pmc_addresses_cnpjErrorMsg";
import pmc_addNewAddress_duplicateAddressError from "@salesforce/label/c.pmc_addNewAddress_duplicateAddressError";
import pmc_addNewAddress_duplicateShipToRelationError from "@salesforce/label/c.pmc_addNewAddress_duplicateShipToRelationError";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import pmc_addNewAddress_phoneError from "@salesforce/label/c.pmc_addNewAddress_phoneError";

import COUNTRY_CODE from '@salesforce/schema/Account.BillingCountryCode';
import BILLING_STATE_CODE from '@salesforce/schema/Account.BillingStateCode';
const CPF = "CPF";
const CNPJ = "CNPJ";
const MASK_CPF = /^(\d{3})(\d{3})(\d{3})(\d{2})$/;
const MASK_CNPJ = /^([A-Z0-9]{2})([A-Z0-9]{3})([A-Z0-9]{3})([A-Z0-9]{4})([A-Z0-9]{2})$/i;
const MASK_ZIP = /^(\d{5})(\d{3})$/;
const DUPLICATE_ADDRESS = "pmc_address_duplicateDetected";

/**
 * A custom LWC to add new address.
 * @alias Pmc_dh_addNewAddress
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_add-new-address></c-pmc_dh_add-new-address>
 */

export default class Pmc_dh_addNewAddress extends LightningElement {
  @api isAddNewAddressModal = false;
  isNewAddressAdded = false;
  isLocationBrazil = false;
  isMouseOver = false;
  isPerson = false;
  isOrganization = false;
  effectiveAccountId;
  buttonUrl = `${pmc_brandingStaticResource}/icons/icon-add-address.svg`;
  @track addressOptions = {};
  @track pageObject = {};
  zipCodeMixLength = 5;
  zipCodeMaxLength = 10;
  stateSubscriptionMaxLength = 14;
  addressNameMaxLength = 35;
  propertyFarmNameMaxLength = 40;
  cepMaxLength = 8;
contactMinLength=8;
  contactMaxLength = 10;
  contactEmailMaxLength = 60;
  addressMaxLength = 60;
  cnpjMaxLength = 14;
  cpfMaxLength = 15;
  addressNumberMaxLength = 10;
  isLoading = false;
  error;
  cnpjCpfSelector = "";
  isDuplicateAddress = false;
  cpfMandate = false;
  cnpjMandate = false;

  /** 
   * Calling pageref 
   */
  @wire(CurrentPageReference) pageRef;

  /** 
   * Fetching Effective Account Id 
   */
  @wire(getRecord, { recordId: Id, fields: [USER_ACCOUNT_FIELD] })
  currentUserInfo({ error, data }) {
    if (data) {
      this.effectiveAccountId = data.fields.AccountId.value;
    } else if (error) {
      this.error = error;
    }
  }
  /**
   * Help Text Details
   */
  /** 
   * Label Details 
   
  @track helpTexts=
  {
    pmc_addNewAddress_CustomerNameHelpText
  };*/
  @track labels = {
    pmc_addNewAddress_title,
    pmc_addNewAddress_addressName,
    pmc_addNewAddress_addressType,
    pmc_addNewAddress_cnpj,
    pmc_addNewAddress_address,
    pmc_addressDetails_addressLine,
    pmc_addNewAddress_city,
    pmc_addNewAddress_state,
    pmc_addNewAddress_zipCode,
    pmc_addNewAddress_cep,
    pmc_addNewAddress_deliveryInstructions,
    pmc_addressDetails_cepError,
    pmc_addressDetails_zipcodeError,
    pmc_addresses_CNPJ_CPF,
    pmc_addresses_stateSubscription,
    pmc_addNewAddress_duplicateAddressError,
    pmc_addNewAddress_personOrOrganization,
    pmc_addNewAddress_propertyFarmName,
    pmc_addNewAddress_contactPhone,
    pmc_addNewAddress_contactEmail,
    pmc_addNewAddress_cpf,
    pmc_addNewAddress_country,
    pmc_addNewAddress_district,
    pmc_addNewAddress_addressNumber,
    pmc_addNewAddress_person,
    pmc_addNewAddress_organization,
    pmc_addNewAddress_duplicateShipToRelationError,pmc_addNewAddress_phoneError
  };

  /** 
   * Lifecycle Hook 
   */
  connectedCallback() {
    this.isNewAddressAdded = this.isAddNewAddressModal;
    this.loadAddressDetail();
    if (isBrazilRegion()) {
      this.isLocationBrazil = !this.isLocationBrazil;
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
    console.log('data?.values : ', data?.values);
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
    this.statesAll = this._countryToStates[this.selectedCountry] || [];;
    return this._countryToStates[this.selectedCountry] || [];
  }



  /** 
   * Fetch Picklist Values 
   * @function loadAddressDetail
   */
  loadAddressDetail() {
    this.isLoading = true;
    getNewAddressStateDetails()
      .then((result) => {
        if (result && Object.keys(JSON.parse(result)).length) {
          let resultFiltered = result
            .replaceAll('"strLabel":', '"label":')
            .replaceAll('"strValue":', '"value":');
          this.addressOptions = JSON.parse(resultFiltered);
          console.log('OUTPUT : ', this.addressOptions.statusCodeMessage?.strStatusMessage);
          if (this.addressOptions.statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(this.addressOptions.statusCodeMessage.strStatusMessage)
          }
        }
        this.isLoading = false
      })
      .catch((e) => {
        console.log('OUTPUT : ', e);
        toastMessageHandler();
        this.error = e;
        this.isLoading = false
      });
  }

  /** On input blur event handler 
  * @function handleBlur
  * @param {event} event
  */
  handleBlur(event) {
    if (
      event.detail.value !== "undefined" &&
      event.detail.value !== null &&
      event.detail.value !== "" &&
      event.target &&
      event.target.dataset
    ) {
      const inputValue = event.detail.value;

      if (event.target.dataset.id === 'strZipcode') {
        const regex1 = /^[0-9]*$/;

        if (!regex1.test(event.detail.value)) {
          event.target.setCustomValidity(pmc_addressDetails_cepError);
          console.log('OUTPUT : here1');
        }
        else if ((event.detail.value).length === 8) {
          event.target.removeReportErrorValidity();
          let valtemp = event.detail.value;
          this.pageObject.strZipcode = valtemp.replace(MASK_ZIP, '$1-$2');
          console.log('OUTPUT : here2');
        }
        else {
          event.target.setCustomValidity(pmc_addressDetails_cepError);
          console.log('OUTPUT : here3');
        }
      }
      const regex = /^(\d{3}).(\d{3}).(\d{3})-(\d{2})$/;
      const regex3 = /^(\d{2}).(\d{3}).(\d{3})\/(\d{4})-(\d{2})$/;
      if (event.target.dataset.id === 'strCpf' || event.target.dataset.id === 'strCnpj') {

        if (event.target.dataset.id === 'strCpf') {
          if (regex.test(inputValue)) {
            console.log('OUTPUT :1 2',);
event.target.removeReportErrorValidity();
           // event.target.setCustomValidity(pmc_addresses_cnpjErrorMsg);
            this.cnpjCpfSelector = '';
          }
          else if (event.target.dataset.id === 'strCpf' && inputValue.length === 11) {
            console.log('OUTPUT :2 ',);
            event.target.removeReportErrorValidity();
            this.pageObject.strCnpjCpf = event.detail.value;
            if (inputValue.length === 11) {
              this.cnpjCpfSelector = CPF;
              this.pageObject.strCpf = this.pageObject.strCnpjCpf.replace(MASK_CPF, '$1.$2.$3-$4');
            }
          }
          else {
            event.target.setCustomValidity(pmc_addresses_cnpjErrorMsg);
            console.log('OUTPUT :3 ',);
            this.cnpjCpfSelector = '';
          }
        }
        if (event.target.dataset.id === 'strCnpj') {
          console.log('OUTPUT :13 ',);

          if (regex3.test(inputValue)) {
            console.log('OUTPUT :1 5',);
event.target.removeReportErrorValidity();
          //  event.target.setCustomValidity(pmc_addresses_cnpjErrorMsg);
            this.cnpjCpfSelector = '';
          }
          else if (event.target.dataset.id === 'strCnpj' && inputValue.length === 14) {
            console.log('OUTPUT :2 ',);

            event.target.removeReportErrorValidity();
            this.pageObject.strCnpjCpf = event.detail.value;

            if (inputValue.length === 14) {
              this.cnpjCpfSelector = CNPJ;
              this.pageObject.strCnpj = this.pageObject.strCnpjCpf.replace(MASK_CNPJ, '$1.$2.$3/$4-$5');
            }
          }
          else {
            event.target.setCustomValidity(pmc_addresses_cnpjErrorMsg);
            console.log('OUTPUT :3 ',);
            this.cnpjCpfSelector = '';
          }
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
    this.pageObject.strCnpjCpf = this.pageObject.strCnpjCpf.replace(/[-,.,/]/g, '');
  }
}

/** On input change event handler 
 * @function handleDataChange
 * @param {event} event
 */
handleDataChange(event) {
  if (
    event.detail.value !== "undefined" &&
    event.target &&
    event.target.dataset
  ) {
    this.pageObject[event.target.dataset.id] = event.detail.value
    this.isDuplicateAddress = false;

    if (event.target.dataset.id === 'strcountry') {
      this.selectedCountry = event.detail.value;

    }

    if (event.target.dataset.id === 'strState') {
      this.selectedState = event.detail.value;

    }
    if (event.target.dataset.id === 'strZipcode') {
      this.template.querySelector('[data-id="strZipcode"]').errorMsg = [''];
    }
    if (event.target.dataset.id === "strPersonOrOrganization") {

      if (event.detail.value === 'Person') {

        this.cpfMandate = true;
        this.cnpjMandate = false;
      }
      if (event.detail.value === 'Organization') {

        this.cnpjMandate = true;
        this.cpfMandate = false;
      }

    }
    if (event.target.dataset.id === "strDeliveryInstructions") {
      const inputValue = event.detail.value;
      const regex = /^[A-Za-z0-9#,./ -]*$/;
      if (!regex.test(inputValue)) {
        event.target.setCustomValidity(
          formatLabel(inputElement_patternMismatchError, [
            pmc_requestToDeliverShippingInformation_deliveryInstructions
          ])
        );
      } else {
        event.target.setCustomValidity("");
      }
      event.target.reportValidity();
    }
  }
}

/** 
 * On button click event handler
 * Saving the data on 'Add New Address' button click
 * @function addAddressHandler
 */
addAddressHandler() {
  if (this.handleErrorOnSave()) return;
  const tempCountry = this.pageObject?.strcountry;
  const tempState = this.pageObject?.strState;
  // if (this.pageObject?.strcountry) {

  //   const selectedOption = this.pageObject?.strcountry;
  //   var currentLabel = this._countries.filter(function (option) {
  //     return option.value == selectedOption;
  //   })
  //   if (currentLabel)
  //     this.pageObject.strcountry = currentLabel[0]?.label;
  // }

  // if (this.pageObject?.strState) {

  //   const selectedOption = this.pageObject?.strState
  //   var currentLabel = this.statesAll.filter(function (option) {
  //     return option.value == selectedOption;
  //   })
  //   if (currentLabel)
  //     this.pageObject.strState = currentLabel[0]?.label;
  // }
  if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
    this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
  }
  if (this.pageObject?.strCpf) {
    this.pageObject.strCpf = this.pageObject.strCpf.replace(/[-,.,/]/g, '');
  }
  if (this.pageObject?.strCnpj) {
    this.pageObject.strCnpj = this.pageObject.strCnpj.replace(/[-,.,/]/g, '');
  }



  if (this.pageObject.strcountry === 'BR') {
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
  console.log('OUTPUT : ', this.pageObject.strcontactPhone);
  this.isLoading = true;
  createShipToAddress({
    strEffectiveAccountId: this.effectiveAccountId,
    addressDetailsJSON: JSON.stringify(this.pageObject)
  })
    .then((result) => {
      if (result && Object.keys(result).length) {
        fireEvent(this.pageRef, "newAddressDetails", result.objAccount);
        if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage === DUPLICATE_ADDRESS) {
            this.isDuplicateAddress = true;
            this.isLoading = false;
            return;
          }
          console.log('OUTPUT : ', JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage);
          toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
        }
        this.isLoading = false;
        this.pageObject.strcountry = tempCountry;
        this.pageObject.strState = tempState;
      }
      this.handleCloseNewAddressModal();
    })
    .catch((err) => {
      console.log('OUTPUT : ', err);
      toastMessageHandler();
      this.error = err;
      this.isLoading = false;
    });
}

/** 
 * Reset all the input fields of the new address detail form 
 * @function clearForm
 */
clearForm() {
  this.isDuplicateAddress = false;
  this.template.querySelectorAll(`[data-name]`).forEach((inputComponent) => {
    inputComponent.resetInput();
  });
  if (this.isLocationBrazil) {
    if (this.cnpjMandate === true) {
      this.template.querySelector(`[data-name="strCnpj"]`).removeReportErrorValidity();
      this.pageObject.strCnpj = null;
    }
    if (this.cpfMandate === true) {
      this.template.querySelector(`[data-name="strCpf"]`).removeReportErrorValidity();
      this.pageObject.strCpf = null;
    }

  }
  this.pageObject.strDeliveryInstructions = "";
}

/** 
 * Form fields validation 
 * @function handleErrorOnSave
 */
handleErrorOnSave() {
  let allValid = true;
  let focusRef;
  this.template.querySelectorAll(`[data-id]`).forEach((inputComponent) => {
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

/** 
 * Modal open handler 
 * @function openNewAddressModal
 */
openNewAddressModal() {
  this.isNewAddressAdded = true;
  this.template.querySelectorAll(`[data-name]`).forEach((inputComponent) => {
    inputComponent.updateIsRequired();
  });
}

/** 
 * Modal close handler 
 * @function handleCloseNewAddressModal
 */
handleCloseNewAddressModal() {
  this.isNewAddressAdded = false;
  this.clearForm();
}

/** 
 * Modal accessibility handler 
 * @function handleIconKeyDown
 * @param {event} event
 */
handleIconKeyDown(event) {
  if (event.keyCode === 13) {
    this.openNewAddressModal();
  }
}

/** 
 * Mouse over Icon Handler 
 * @function handleMouseEnter
 */
handleMouseEnter() {
  this.isMouseOver = true;
}

/** 
 * Mouse Leave Handler 
 * @function handleMouseLeave
 */
handleMouseLeave() {
  this.isMouseOver = false;
}
}