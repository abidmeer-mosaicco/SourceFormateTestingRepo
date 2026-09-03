import { LightningElement, api, track } from "lwc";
import { formatLabel } from "c/pmc_dh_utilityJs";

import pmc_picklistElement_placeholder from "@salesforce/label/c.pmc_picklistElement_placeholder";
import pmc_inputElement_requiredCheck from "@salesforce/label/c.pmc_inputElement_requiredCheck";

export default class Pmc_dh_selectionPicklist extends LightningElement {
  CONSTANT = {
    EVENT_TYPE_BLUR: "onblur",
    EVENT_TYPE_CHANGE: "onchange",
    EVENT_TYPE_CHANGE_NAME: "inputdatachange",
    EVENT_TYPE_BLUR_NAME: "inputdatablur"
  };

  @api name;
  @api value;
  @api options;
  @api parentName;
  @api className;
  @api isRequired;
  @api optionsWithoutPlaceholder;
  @api errorClassName = "slds-form-element slds-has-error";

  @track picklistOptions = [];
  @track _errorMsg = [];
  _isDisabled = false;
  isRequiredCheck = false;
  PlaceholderForPicklist = pmc_picklistElement_placeholder;


  _defaultValue = "";
  @api
  get defaultValue() {
    return this._defaultValue;
  }

  set defaultValue(value) {
    this._defaultValue = value;
  }

  _messageWhenValueMissing = "";
  @api
  get messageWhenValueMissing() {
    return this._messageWhenValueMissing;
  }
  set messageWhenValueMissing(value) {
    this._messageWhenValueMissing = value;
  }

  _placeholder = "";
  @api
  get placeholder() {
    return this._placeholder;
  }
  set placeholder(value) {
    this._placeholder = value;
  }

  @api
  get textLabel() {
    return this._textLabel;
  }

  set textLabel(value) {
    if (value) {
      this._textLabel = value;
      this._placeholder = formatLabel(this.PlaceholderForPicklist, [
        this._textLabel?.toLowerCase()
      ]);
    }
  }

  @api
  get errorMsg() {
    return this._errorMsg;
  }
  set errorMsg(value) {
    if (value) {
      this._errorMsg = value;
      this.checkError();
    }
  }

  @api
  get isDisabled() {
    return this._isDisabled;
  }

  set isDisabled(value) {
    this._isDisabled = value;
  }

  @api
  get comboboxListJson() {
    return this.picklistOptions;
  }

  set comboboxListJson(value) {
    if (value) {
      if (this._placeholder) {
        this.picklistOptions = [
          ...(this.IsJsonString(value) ? JSON.parse(value) : value)
        ];
      } else {
        this.picklistOptions = value;
      }
    }
  }

  @api
  focus() {
    const inputField = this.template.querySelector("lightning-combobox");
    if (inputField) {
      inputField.focus();
    }
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
    this.template.querySelector('[data-name="' + this.parentName + '"]').classList.add('slds-has-error');
  }

  @api
  removeReportErrorValidity() {
    let selectEl = this.template.querySelector('[data-name="' + this.parentName + '"]');
    if (selectEl.classList.contains('slds-has-error')) {
      selectEl.classList.remove('slds-has-error');
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

  @api
  resetInput() {
    const inputEl = this.template.querySelector('[data-name="' + this.parentName + '"]');
    inputEl.value = null;
    this.isRequiredCheck = false;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      inputEl.reportValidity();
      this.isRequiredCheck = this.isRequired;
    })
  }

  @api
  updateIsRequired() {
    this.isRequiredCheck = this.isRequired;
  }

  @api
  resetValue(value) {
    const inputEl = this.template.querySelector('[data-name="' + this.parentName + '"]');
    inputEl.value = value;
    inputEl.reportValidity();
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.isRequiredCheck = this.isRequired;
    if (!this._messageWhenValueMissing) {
      this._messageWhenValueMissing = formatLabel(
        pmc_inputElement_requiredCheck,
        [this.textLabel]
      );
    }
    if (!this._placeholder && this.textLabel) {
      this._placeholder = formatLabel(this.PlaceholderForPicklist, [
        this.textLabel?.toLowerCase()
      ]);
    }

    // Set default selected value if it's defined
    if (this.value) {
      this._defaultValue = this.value;
    }
  }

  /**
   * Handles onblur event
   * @function handleBlur
   * @param {Event} event
   */
  handleBlur(event) {
    this.handleEvent(event, this.CONSTANT.EVENT_TYPE_BLUR);
  }

  /**
   * Handles onchange event
   * @function handleChange
   * @param {Event} event
   */
  handleChange(event) {
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
          name: event.target.dataset.name,
          value: event.target.value,
          oldvalue: event.target.dataset.value,
          index: event.target.dataset.index
        }
      })
    );
  }

  /**
   * Checks for error
   * @function checkError
   */
  checkError() {
    let inputCmp = this.template.querySelector("lightning-input");
    if (this._errorMsg.length > 0) {
      inputCmp.setCustomValidity(this._errorMsg[0]);
    } else {
      inputCmp.setCustomValidity("");
    }
    inputCmp.reportValidity();
  }

  /**
   * valid JSON String
   * @function IsJsonString
   * @param {string} str
   */
  IsJsonString(str) {
    try {
      JSON.parse(str);
    } catch (e) {
      return false;
    }
    return true;
  }

  get picklistOptionsWithOrWthoutPlaceholder() {
    let options = [];
    if (this._placeholder && !this.optionsWithoutPlaceholder) {
      options.push({
        label: this._placeholder,
        value: null
      });
    }
    if (this.picklistOptions) {
      options = [
        ...options,
        ...(this.IsJsonString(this.picklistOptions)
          ? JSON.parse(this.picklistOptions)
          : this.picklistOptions)
      ];
    }
    return options;
  }
}