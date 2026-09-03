import { LightningElement, track, api } from "lwc";

import pmc_registration_selectActivitiesDigitalHub from "@salesforce/label/c.pmc_registration_selectActivitiesDigitalHub";
import pmc_registration_proceed from "@salesforce/label/c.pmc_registration_proceed";
import pmc_registration_digitalHubTitle from "@salesforce/label/c.pmc_registration_digitalHubTitle";

export default class Pmc_dh_digitalHubProfile extends LightningElement {
  @track isDisabled = true;
  @track labels = { pmc_registration_proceed, pmc_registration_digitalHubTitle, pmc_registration_selectActivitiesDigitalHub };
  @track _preferenceList = [];

  @api
  get preferenceList() {
    return this._preferenceList;
  }
  set preferenceList(value) {
    if (value) {
      this._preferenceList = JSON.parse(JSON.stringify(value));
      this._preferenceList = this._preferenceList.map(item => {
        return {
          label: item.label,
          value: item.value,
          checked: false
        }
      });
    }
  }
  count = 0;

  /** 
   * Enable/Disable proceed button based on number of checkbox selection 
   * @function handleChangeCheckbox
   * @param {event} event 
   */
  handleChangeCheckbox(event) {
    const { value, checked } = event.target;
    const checkboxIndex = this._preferenceList.findIndex(
      (checkbox) => checkbox.value === value
    );
    if (checkboxIndex !== -1 && checked) {
      this._preferenceList[checkboxIndex].checked = checked;
      this.count++;
    } else {
      this._preferenceList[checkboxIndex].checked = checked;
      this.count--;
    }
    if (this.count >= 3) {
      this.isDisabled = false;
    } else {
      this.isDisabled = true;
    }
  }

  /** 
   * Send data to parent component on click of proceed 
   * @function handleProceed
   */
  handleProceed() {
    this.dispatchEvent(
      new CustomEvent("proceedbuttonclick", {
        detail: {
          value: "isThankYouForRegistration",
          data: {
            lstPreferences: this._preferenceList.filter(el => el.checked).map(el => el.value)
          }
        }
      })
    );
  }
}