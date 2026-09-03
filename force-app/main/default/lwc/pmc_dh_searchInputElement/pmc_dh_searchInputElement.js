import { LightningElement, api, track } from "lwc";
import pmc_searchInput_search from "@salesforce/label/c.pmc_searchInput_search";

const EVENTS = {
  CHANGE_EVENT: "inputdatachange",
  KEYUP_EVENT: "inputkeyup",
  SEARCH_EVENT: "searchclick"
};

/**
 * A custom LWC for search input element.
 * @alias Pmc_dh_searchInputElement
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_search-input-element></c-pmc_dh_search-input-element>
 */

export default class Pmc_dh_searchInputElement extends LightningElement {
  @track labels = {
    pmc_searchInput_search
  };
  _defaultValue;
  @api textLabel;
  @api textPlaceholder = "";
  @api textName;
  @api
  get defaultValue() {
    return this._defaultValue;
  }
  set defaultValue(value) {
    this._defaultValue = value;
  }

  /** 
   * On input change event handler 
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    let changeEv = new CustomEvent(EVENTS.CHANGE_EVENT, {
      detail: {
        name: event.target.dataset.name,
        value: event.target.value
      }
    });
    this.dispatchEvent(changeEv);
  }

  /** 
   * On key up event handler 
   * @function handleKeyUp
   * @param {Event} event 
   */
  handleKeyUp(event) {
    let keyUpEv = new CustomEvent(EVENTS.KEYUP_EVENT, {
      detail: {
        keyCode: event.keyCode
      }
    });
    this.dispatchEvent(keyUpEv);
  }

  /** 
   * On search btn click handler 
   * @function handleSearchInput
   */
  handleSearchInput() {
    let searchClickEv = new CustomEvent(EVENTS.SEARCH_EVENT);
    this.dispatchEvent(searchClickEv);
  }
}