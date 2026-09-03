/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, api } from 'lwc';
import { formatLabel } from 'c/pmc_dh_utilityJs';
import { inputDatePlaceholderHandler } from "c/pmc_dh_utilityJs";
import pmc_inputElement_placeholder from "@salesforce/label/c.pmc_inputElement_placeholder";
import pmc_inputElement_maxLengthError from "@salesforce/label/c.pmc_inputElement_maxLengthError";
import inputElement_patternMismatchError from "@salesforce/label/c.inputElement_patternMismatchError";
import pmc_inputElement_requiredCheck from "@salesforce/label/c.pmc_inputElement_requiredCheck";

export default class Pmc_dh_inputElement extends LightningElement {
  CONSTANT = {
    EVENT_TYPE_BLUR: 'onblur',
    EVENT_TYPE_CHANGE: 'onchange',
    EVENT_TYPE_KEYUP: 'onkeyup',
    EVENT_TYPE_FOCUS: 'onfocus',
    EVENT_TYPE_KEYPRESS: 'onkeypress',
    EVENT_TYPE_CHANGE_NAME: 'inputdatachange',
    EVENT_TYPE_BLUR_NAME: 'inputdatablur',
    EVENT_TYPE_KEYUP_NAME: 'inputdatakeyup',
    EVENT_TYPE_KEYPRESS_NAME: 'inputdatakeypress',
    EVENT_TYPE_FOCUS_NAME: 'inputfocus'
  }
  @api className;
  @api textName;
  @api variant = "standard";
  @api textPlaceholder;
  @api isRequired = false;
  @api isReadOnly = false;
  @api isNumber = false;
  @api parentName;
  @api pattern;
  @api minLength;
  @api maxLength;
  @api minValue;
  @api maxValue;
  @api messageWhenPatternMismatch;
  @api messageWhenTooShort;
  @api messageWhenTooLong;
  @api messageWhenValueMissing;
  @api messageWhenTypeMismatch;
  @api messageWhenRangeLow;
  @api messageWhenRangeHigh;
  @api type = "text";
  @api helpText;
  _errorMsg = "";
  _isDisabled = false;
  _textPlaceholder = '';
  errorClassName = 'slds-form-element slds-has-error';
  _defaultValue;
  _textLabel = '';
  _messageWhenTooLong;
  _messageWhenPatternMismatch;
  _messageWhenValueMissing;
  PlaceholderForEnter = pmc_inputElement_placeholder;
  MaxLengthError = pmc_inputElement_maxLengthError;
  Pattern_Mismatch_Error = inputElement_patternMismatchError;
  RequiredErrorMesssageForInput = pmc_inputElement_requiredCheck;
  isRequiredCheck = false;

  @api labelParentClass;
  get _labelParentClass() {
    return this.labelParentClass ? this.labelParentClass + ' slds-grid slds-wrap' : 'slds-grid slds-wrap';
  }

  @api
  get isDisabled() {
    return this._isDisabled;
  }
  set isDisabled(value) {
    this._isDisabled = value;
    if (value) {
      setTimeout(() => this.template.querySelector('lightning-input').reportValidity());
    }
  }

  @api
  get defaultValue() {
    return this._defaultValue;
  }

  set defaultValue(value) {
    this._defaultValue = value;
  }

  @api
  get errorMsg() {
    return this._errorMsg;
  }
  set errorMsg(value) {
    if (value) {
      this._errorMsg = value;
    }
    this.checkError();
  }

  @api
  get textLabel() {
    return this._textLabel;
  }
  set textLabel(value) {
    if (value) {
      this._textLabel = value;
      this.updatePlaceholderLabel();
    }
  }

  @api
  reportValidity() {
    const allValid = [...this.template.querySelectorAll('[data-name="' + this.parentName + '"]')]
      .reduce((validSoFar, inputCmp) => {
        inputCmp.value = inputCmp.value?.trim();
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
    selectEl?.setCustomValidity('');
    selectEl?.reportValidity();
  }

  @api
  checkValidity() {
    return this.parentName ? this.template.querySelector(`[data-name=${this.parentName}]`)?.checkValidity() : true;
  }

  @api
  resetInput() {
    const inputEl = this.template.querySelector('[data-name="' + this.parentName + '"]');
    inputEl.value = null;
    this.isRequiredCheck = false;
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
  }

  @api
  focus() {
    const inputField = this.template.querySelector('lightning-input');
    if (inputField) {
      inputField.focus();
    }
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this._messageWhenTooLong = this.messageWhenTooLong;
    this._messageWhenPatternMismatch = this.messageWhenPatternMismatch;
    this._messageWhenValueMissing = this.messageWhenValueMissing;
    this.isRequiredCheck = this.isRequired;
    if (!this._messageWhenTooLong) {
      this._messageWhenTooLong = formatLabel(this.MaxLengthError, [this.textLabel, this.maxLength]);
    }
    if (!this._messageWhenPatternMismatch) {
      this._messageWhenPatternMismatch = formatLabel(this.Pattern_Mismatch_Error, [this.textLabel]);
    }
    if (!this._messageWhenValueMissing) {
      this._messageWhenValueMissing = formatLabel(this.RequiredErrorMesssageForInput, [this.textLabel]);
    }
    this.updatePlaceholderLabel();
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.type === 'date') {
      inputDatePlaceholderHandler(this.defaultValue, this.template.querySelector('lightning-input'));
    }
  }

  /**
   * Updates placeholder as title
   * @function updatePlaceholderLabel
   */
  updatePlaceholderLabel() {
    if (!this.textPlaceholder) {
      this._textPlaceholder = formatLabel(this.PlaceholderForEnter, [this._textLabel?.toLowerCase()]);
    } else if (this.textPlaceholder && this.textPlaceholder.length) {
      this._textPlaceholder = this.textPlaceholder;
    }
  }

  /**
   * Handles onblur event
   * @function handleBlur
   * @param {Event} event 
   */
  handleBlur(event) {
    this.reportValidity();
    this.handleEvent(event, this.CONSTANT.EVENT_TYPE_BLUR);
  }

  /**
   * Handles onchange event
   * @function handleChange
   * @param {Event} event 
   */
  handleChange(event) {
    this.handleEvent(event, this.CONSTANT.EVENT_TYPE_CHANGE)
  }

  /**
   * Handles onkeyup event
   * @function handleKeyup
   * @param {Event} event 
   */
  handleKeyup(event) {
    this.handleEvent(event, this.CONSTANT.EVENT_TYPE_KEYUP);
  }

  /**
   * Handles onfocus event
   * @function handleFocus
   * @param {Event} event 
   */
  handleFocus(event) {
    this.handleEvent(event, this.CONSTANT.EVENT_TYPE_FOCUS);
  }

  /**
   * Handles onkeypress event
   * @function handleKeyPress
   * @param {Event} event 
   */
  handleKeyPress(event) {
    if (this.isNumber) {
      event.target.value = event.target.value.replace(/[^0-9]/g, '');
    }
    this.handleEvent(event, this.CONSTANT.EVENT_TYPE_KEYPRESS);
  }

  /**
   * Handles all the events
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
      case this.CONSTANT.EVENT_TYPE_KEYUP:
        eventName = this.CONSTANT.EVENT_TYPE_KEYUP_NAME;
        break;
      case this.CONSTANT.EVENT_TYPE_KEYPRESS:
        eventName = this.CONSTANT.EVENT_TYPE_KEYPRESS_NAME;
        break;
      case this.CONSTANT.EVENT_TYPE_FOCUS:
        eventName = this.CONSTANT.EVENT_TYPE_FOCUS_NAME;
        break;
      default:
        eventName = this.CONSTANT.EVENT_TYPE_CHANGE_NAME;
    }
    this.dispatchEvent(new CustomEvent(eventName, {
      detail: {
        name: event.target.dataset.name,
        value: event.target.value,
        oldvalue: event.target.dataset.value,
        keyCode: event.keyCode
      }
    }));
  }

  /**
   * Check for errors
   * @function checkError
   */
  checkError() {
    let inputCmp = this.template.querySelector('lightning-input');
    if (this._errorMsg) {
      inputCmp.setCustomValidity(this._errorMsg)
    } else {
      inputCmp?.setCustomValidity('');
    }
    inputCmp?.reportValidity();
  }

  /**
   * Setting custom validity
   * @function setCustomValidity
   */
  @api
  setCustomValidity(msg) {
    let inputCmp = this.template.querySelector('lightning-input');
    if (msg) {
      inputCmp.setCustomValidity(msg)
    } 
    inputCmp?.reportValidity();
  }
}