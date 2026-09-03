import { LightningElement, wire, track } from "lwc";
import { formatPhoneNumber, toastMessageHandler } from 'c/pmc_dh_utilityJs';
import { getRecord } from "lightning/uiRecordApi";
import Id from "@salesforce/user/Id";
import USER_ACCOUNT_FIELD from "@salesforce/schema/User.AccountId";
import getAccountDetail from "@salesforce/apex/PMC_DH_AccountDetailController.getAccountDetail";

import pmc_accountDetails_accountInformation from "@salesforce/label/c.pmc_accountDetails_accountInformation";
import pmc_accountDetails_contactInformation from "@salesforce/label/c.pmc_accountDetails_contactInformation";
import pmc_accountDetails_accName from "@salesforce/label/c.pmc_accountDetails_accName";
import pmc_accountDetails_accNumber from "@salesforce/label/c.pmc_accountDetails_accNumber";
import pmc_accountDetails_phone from "@salesforce/label/c.pmc_accountDetails_phone";
import pmc_accountDetails_email from "@salesforce/label/c.pmc_accountDetails_email";
import pmc_accountDetails_accManager from "@salesforce/label/c.pmc_accountDetails_accManager";
import pmc_accountDetails_SSR from "@salesforce/label/c.pmc_accountDetails_SSR";

/**
 * A custom LWC to display account details.
 * @alias Pmc_dh_accountDetail
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_account-detail></c-pmc_dh_account-detail>
 */

export default class Pmc_dh_accountDetail extends LightningElement {
  error;
  isLoading = false;
  @track accountInformation = [];
  @track contactInformation = [];
  ssrPhoneNumber;
  accPhoneNumber;
  accManagerPhoneNumber;

  /**
   * Custom Label Object
   */
  @track labels = {
    pmc_accountDetails_accountInformation,
    pmc_accountDetails_contactInformation
  };

  /** 
   * Fetching Effective Account Id 
   */
  @wire(getRecord, { recordId: Id, fields: [USER_ACCOUNT_FIELD] })
  currentUserInfo({ error, data }) {
    if (data) {
      this.loadAccountDetail(data.fields.AccountId.value);
    } else if (error) {
      this.error = error;
    }
  }

  /**
   * Fetch account details
   * @function loadAccountDetail
   * @param {string} effectiveAccountId
   */
  loadAccountDetail(effectiveAccountId) {
    this.isLoading = true;
    if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
      effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    }
    getAccountDetail({
      effAccId: effectiveAccountId
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
        if (response.lstAccounts?.length > 0) { this.setData(response.lstAccounts[0]); }
        this.isLoading = false;
        if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
        }
      }
      })
      .catch((err) => {
        this.isLoading = false;
        toastMessageHandler();
        this.error = err;
      });
  }

  /** 
   * Set data for accountInformation, contactInformation
   * @function setData
   * @param {Object} result
   */
  setData(result) {
    this.accountInformation = [
      { label: pmc_accountDetails_accName, value: result.strAccName },
      { label: pmc_accountDetails_accNumber, value: result.strAccNumber },
      { label: pmc_accountDetails_phone, value: result.strAccPhoneNo },
      { label: pmc_accountDetails_email, value: result.strAccEmail }
    ];
    this.contactInformation = [
      { label: pmc_accountDetails_accManager, value: result.strAccManagerName },
      { label: pmc_accountDetails_phone, value: result.strAccManagerPhoneNo },
      { label: pmc_accountDetails_email, value: result.strAccManagerEmail },
      { label: pmc_accountDetails_SSR, value: result.strSSRName },
      { label: pmc_accountDetails_phone, value: result.strSSRPhone },
      { label: pmc_accountDetails_email, value: result.strSSREmail }
    ];
    this.formatSSRPhoneNumber(result);
    this.formatAccManagerPhoneNumber(result);
    this.formatAccPhoneNumber(result);
  }

  /**
   * Format SSRPhoneNumber
   * @function formatSSRPhoneNumber
   * @param {Object} result
   */
  formatSSRPhoneNumber = (result) => {
    if (result.strSSRPhone !== null && result.strSSRPhone !== undefined && result.strSSRCountry !== null && result.strSSRCountry !== undefined) {
      const BRAZIL_COUNTRY = 'Brazil';
      const US_COUNTRY = 'United States';
      const CA_COUNTRY = 'Canada';
      let code;
      if (result.strSSRCountry === BRAZIL_COUNTRY) {
        code = "+55";
      } else if (result.strSSRCountry === US_COUNTRY || result.strSSRCountry === CA_COUNTRY) {
        code = "+1";
      }
      const contactInformationObj = this.contactInformation.find(item => item.label === pmc_accountDetails_phone && item.value === result.strSSRPhone);
      if (contactInformationObj) {
        contactInformationObj.value = `${code.replace(/[a-zA-Z]/g, "")} ${formatPhoneNumber(result.strSSRPhone, result.strSSRCountry)}`;
      }
    }
  }

  /**
  * Format AccManagerPhoneNumber
  * @function formatAccManagerPhoneNumber
  * @param {Object} result
  */
  formatAccManagerPhoneNumber = (result) => {
    if (result.strAccManagerPhoneNo !== null && result.strAccManagerPhoneNo !== undefined && result.strAccManagerCountry !== null && result.strAccManagerCountry !== undefined) {
      const BRAZIL_COUNTRY = 'Brazil';
      const US_COUNTRY = 'United States';
      const CA_COUNTRY = 'Canada';
      let code;
      if (result.strAccManagerCountry === BRAZIL_COUNTRY) {
        code = "+55";
      } else if (result.strAccManagerCountry === US_COUNTRY || result.strAccManagerCountry === CA_COUNTRY) {
        code = "+1";
      }
      const contactInformationObj = this.contactInformation.find(item => item.label === pmc_accountDetails_phone && item.value === result.strAccManagerPhoneNo);
      if (contactInformationObj) {
        contactInformationObj.value = `${code.replace(/[a-zA-Z]/g, "")} ${formatPhoneNumber(result.strAccManagerPhoneNo, result.strAccManagerCountry)}`;
      }
    }
  }

  /**
  * Format AccPhoneNumber
  * @function formatAccPhoneNumber
  * @param {Object} result
  */
  formatAccPhoneNumber = (result) => {
    if (result.strAccPhoneNo !== null && result.strAccPhoneNo !== undefined && result.strAccCountry !== null && result.strAccCountry !== undefined) {
      const BRAZIL_COUNTRY = 'Brazil';
      const US_COUNTRY = 'United States';
      const CA_COUNTRY = 'Canada';
      let code;
      if (result.strAccCountry === BRAZIL_COUNTRY) {
        code = "+55";
      } else if (result.strAccCountry === US_COUNTRY || result.strAccCountry === CA_COUNTRY) {
        code = "+1";
      }
      const accountInformationObj = this.accountInformation.find(item => item.label === pmc_accountDetails_phone && item.value === result.strAccPhoneNo);
      if (accountInformationObj) {
        accountInformationObj.value = `${code.replace(/[a-zA-Z]/g, "")} ${formatPhoneNumber(result.strAccPhoneNo, result.strAccCountry)}`;
      }
    }
  }
}