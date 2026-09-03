import { LightningElement, track, wire } from "lwc";
import Id from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";
import UserNameFIELD from "@salesforce/schema/User.Username";
import pmc_userDetails_loginInformation from "@salesforce/label/c.pmc_userDetails_loginInformation";
import pmc_userDetails_username from "@salesforce/label/c.pmc_userDetails_username";

export default class Pmc_dh_userLoginInfo extends LightningElement {
  @track labels = {
    pmc_userDetails_loginInformation,
    pmc_userDetails_username
  };
  currentUserName;
  @wire(getRecord, { recordId: Id, fields: [UserNameFIELD] })
  currentUserInfo({ error, data }) {
    if (data) {
      this.currentUserName = data.fields.Username.value;
      console.log("User Info:", data.fields.Username.value);
    } else if (error) {
      console.log("Error Info:", error);
    }
  }
}