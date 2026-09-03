import { LightningElement, track, api } from 'lwc';
import { formatLabel, registerListener } from "c/pmc_dh_utilityJs";

import pmc_addresses_searchAddresses from "@salesforce/label/c.pmc_addresses_searchAddresses";
import pmc_picklistElement_placeholder from "@salesforce/label/c.pmc_picklistElement_placeholder";

export default class Pmc_dh_customPicklist extends LightningElement {
  CONSTANT = {
    EVENT_TYPE_BLUR: "onblur",
    EVENT_TYPE_CHANGE: "onchange",
    EVENT_TYPE_CHANGE_NAME: "inputdatachange",
    EVENT_TYPE_BLUR_NAME: "inputdatablur"
  };

	@track labels = {
		pmc_addresses_searchAddresses
	}

  _placeholder = "";
  @track picklistOptions = [];
  selectedLabel;
  selectedValue;
  optionItemClass = 'slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_term';
  @track options = [];

  
  @track _textLabel;
  @api
  get textLabel() {
    return this._textLabel;
  }
  set textLabel(value) {
    if (value) {
      this._textLabel = value;
      this._placeholder = formatLabel(pmc_picklistElement_placeholder, [
        this._textLabel?.toLowerCase()
      ]);
    }
  }

  @track _linkName;
  @api
  get linkName() {
    return this._linkName;
  }
  set linkName(value) {
    this._linkName = value;
  }
  
  @track _dropdownOptions;
  @api
  set dropdownOptions(data) {
    if (data) {
      this._dropdownOptions = data;
    }
  }
  get dropdownOptions() {
    return JSON.parse(JSON.stringify(this._dropdownOptions));
  }

  @track _isDisabled = false;
  @api
  get isDisabled() {
    return this._isDisabled;
  }
  set isDisabled(value) {
        console.log('value is '+value);
    this._isDisabled = value;
  }

  @track _defaultValue;
  @api
  set defaultValue(value) {
    this._defaultValue = value;
    this.selectedValue = this._defaultValue;
  }
  get defaultValue() {
    return this._defaultValue;
  }

  @track _parentName;
  @api
  set parentName(value) {
    this._parentName = value;
  }
  get parentName() {
    return this._parentName;
  }

  @track _indexProduct
  @api
  set indexProduct(value) {
    this._indexProduct = value;
  }
  get indexProduct() {
    return this._indexProduct;
  }

  @api
  reportValidity() {
    const allValid = [
      ...this.template.querySelectorAll('[data-name="' + this.parentName + '"]')
    ].reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);
    return allValid;
  }

  @api
  reportErrorValidity() {
    this.template.querySelector('.slds-combobox__input').classList.add('show-custom-error');
  }

  @api
  removeReportErrorValidity() {
    let selectEl = this.template.querySelector('.slds-combobox__input');
    if (selectEl.classList.contains('show-custom-error')) {
      selectEl.classList.remove('show-custom-error');
    }
  }

  @api
  checkValidity() {
    return this.parentName
      ? this.template
        .querySelector(`[data-name=${this.parentName}]`)
        ?.checkValidity()
      : true;
  }


  connectedCallback() {
    window.addEventListener('click', () => {
      this.hideDropdownSection();
    });
    this.processOptionsData();

    registerListener("selectedShipToEvent", this.handleSelectedShipTo, this);
    
  }

  // handling selectedShipToEvent
  handleSelectedShipTo(detail) {
    this.selectedValue = detail.selectedShipTo;
  }

  // description To hide dropdown when option is selected and change the class of selected option
  hideDropdownSection() {
    const dropdownElm = this.template.querySelector('.slds-dropdown-trigger_click');
    if (dropdownElm) {
      dropdownElm.classList.remove('slds-is-open');
      if (!this.selectedValue) {
        dropdownElm.classList.add('show-slds-error');
      } else {
        dropdownElm.classList.remove('show-slds-error');
      }
    }
  }

  //description To select ony option by default if only one option is available
  @api
  processOptionsData() {
    this.picklistOptions = JSON.parse(JSON.stringify(this._dropdownOptions));
    this.picklistOptions.forEach((item) => {
      if(item.value == this._defaultValue) {
        this.selectedLabel = item.label;
        this.selectedValue = item.value;
      }
    });

    let options = [], options2 = [];
    if (this._placeholder && !this.optionsWithoutPlaceholder) {
      options.push({
        label: this._placeholder,
        value: null
      });
    }
    if (this.picklistOptions) {
      this.picklistOptions.forEach(item => {
        options2.push({label: item.label, value: item.value});
      });
    }
    this.picklistOptions = [...options, ...options2];

    this.updateSelectedOption();
  }

  //description To update selected option
  @api
  updateSelectedOption() {
    let selectedValue = this.selectedValue || null;
    this.picklistOptions.forEach((item) => {
      if(item.value === selectedValue) {
        item.isSelected = true;
        this.selectedLabel = item.label;
      }else{
        item.isSelected = false;
      }
      item.class = (item.value === this.selectedValue) ? `${this.optionItemClass} slds-has-focus` : this.optionItemClass;
    });
  }

  // description To handle open and close of dropdown
  toggleDropdown(e) {
     if (this.isDisabled) {
      return; // Prevent toggling if disabled
    }
    e.stopPropagation();
    if (e.target.name !== 'type-ahead') {
      const classList = e.currentTarget.classList;
      classList.toggle('slds-is-open');
      if (!classList.contains('slds-is-open') && !this.selectedValue) {
        classList.add('show-slds-error');
      } else {
        classList.remove('show-slds-error');
      }
    }
  }

  //description To handle option request
  handleOptionSelect(event) {
   
    event.stopPropagation();
    this.selectedValue = event.currentTarget.dataset.value ? event.currentTarget.dataset.value : null;
    this.updateSelectedOption();
    this.hideDropdownSection();

    this.handleEvent(event, this.CONSTANT.EVENT_TYPE_CHANGE);
  }

  /** 
   * Handles event
   * @function handleEvent
   * @param {Event} event 
   * @param {string} eventType  
   */
  handleEvent(event, eventType) {
    let eventName;
    switch (eventType) {
      case this.CONSTANT.EVENT_TYPE_CHANGE:
        eventName = this.CONSTANT.EVENT_TYPE_CHANGE_NAME;
        break;
      case this.CONSTANT.EVENT_TYPE_BLUR:
        eventName = this.CONSTANT.EVENT_TYPE_BLUR_NAME;
        break;
      default:
        eventName = this.CONSTANT.EVENT_TYPE_CHANGE_NAME;
    }
    this.dispatchEvent(
      new CustomEvent(eventName, {
        detail: {
          name: event.target.dataset.parentname,
          value: event.target.dataset.value,
          oldvalue: event.target.dataset.value,
          index: event.target.dataset.index
        }
      })
    );
  }


	handleModalClick() {
    this.dispatchEvent(new CustomEvent('opensearchaddressmodel', {
      detail: {
        indexproduct: this._indexProduct,
      }
    }));
	}

}