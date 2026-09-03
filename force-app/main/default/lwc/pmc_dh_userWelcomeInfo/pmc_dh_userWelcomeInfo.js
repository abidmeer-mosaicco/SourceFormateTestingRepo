import { LightningElement, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import isGuest from "@salesforce/user/isGuest";
import FIRST_NAME from '@salesforce/schema/User.FirstName';
import { toastMessageHandler } from "c/pmc_dh_utilityJs";

import pmc_home_hello from "@salesforce/label/c.pmc_home_hello";
import pmc_home_welcome from "@salesforce/label/c.pmc_home_welcome";
import pmc_home_accountManager from "@salesforce/label/c.pmc_home_accountManager";

import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import getAccountManagerName from "@salesforce/apex/PMC_DH_AccountDetailController.getAccountManagerName";
import getEffectiveAccountDetails from "@salesforce/apex/PMC_DH_AccountSwitcherController.getEffectiveAccountDetails";

export default class Pmc_dh_userWelcomeInfo extends LightningElement {
  @track userId = Id;
  @track accountManagerName;

  @track labels = {
    pmc_home_hello,
    pmc_home_welcome,
    pmc_home_accountManager
  };

  isWidgetSection = false;
  isLoading = false;

  @wire(getRecord, { recordId: "$userId", fields: [FIRST_NAME] }) user;
  get firstName() {
    return getFieldValue(this.user.data, FIRST_NAME);
  }

  @track iconUrlObj = {
    personAccountUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-person-account.svg`
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.isGuestUser = isGuest;
    if (this.isGuestUser) return;
    if (!sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID") && !sessionStorage.getItem("EFFECTIVE_ACCOUNT_NAME")) {
      this.getAccountDetails();
    }
    else {
      this.fetchEffectiveAccountId(sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID"))
    }
  }

  /**
   * Fetches account details
   * @function getAccountDetails
   */
  getAccountDetails() {
    this.isLoading = true;
    getEffectiveAccountDetails()
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          if (!sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID") && !sessionStorage.getItem("EFFECTIVE_ACCOUNT_NAME")) {
            sessionStorage.setItem("EFFECTIVE_ACCOUNT_ID", result.strAccountId);
            sessionStorage.setItem("EFFECTIVE_ACCOUNT_NAME", result.strAccountName); 
          }
          this.fetchEffectiveAccountId(result.strAccountId);
        }
        this.isLoading = false;
      }).catch((error) => {
        toastMessageHandler();
        this.isLoading = false;
        this.error = error;
      });
  }

  /**
   * Fetches EffectiveAccountId to use as parameter for another mothod
   * @function fetchEffectiveAccountId
   * @param {string} effAccId
   */
  fetchEffectiveAccountId(effAccId) {
    this.isWidgetSection = true;
    getAccountManagerName({
      strEffAccId: effAccId
    }).then((data) => {
      if (data && Object.keys(data).length) {
        if (JSON.parse(JSON.stringify(data)).strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(data)).strStatusMessage)
        }
        this.accountManagerName = data.strData;
      }
      this.isLoading = false;
    }).catch((error) => {
      toastMessageHandler();
      this.error = error;
      this.isLoading = false;
    })
  }
}