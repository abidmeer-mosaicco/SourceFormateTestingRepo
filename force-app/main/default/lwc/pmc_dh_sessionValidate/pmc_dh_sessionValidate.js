import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import isGuestUser from "@salesforce/user/isGuest";
import validateUserSession from '@salesforce/apex/PMC_DH_SignInController.validateUserSession';
import basePath from '@salesforce/community/basePath';
import { urlRedirect, toastMessageHandler } from "c/pmc_dh_utilityJs";

export default class Pmc_dh_sessionValidate extends NavigationMixin(LightningElement) {
  isGuest = isGuestUser;

  connectedCallback() {
    // this.checkIfSessionHasExpired();
    console.log('isGuest ++' + this.isGuest);
    let url = `${basePath}/login`;
    const pageRef = {
      type: 'standard__webPage',
      attributes: {
        url: url,
      }
    };
    if (this.isGuest) {
      this[NavigationMixin.GenerateUrl](pageRef)
        .then(generatedUrl => {
          urlRedirect(generatedUrl);
        });
    }


  }

  /**
* @function getEffectiveAccountDetails - Backend Method to get EFFECTIVE_ACCOUNT_ID and EFFECTIVE_ACCOUNT_NAME in Session Storage
*/
  checkIfSessionHasExpired() {
    validateUserSession()
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          console.log('Session Data ++' + result.mapSession);
          console.log('isGuest ++' + this.isGuest);
          let url = `${basePath}/login`;
          this.generateUrl(url)
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        console.log('Session Data ++' + JSON.stringify(error));
      });
  }


  generateUrl(url) {
    const pageRef = {
      type: 'standard__webPage',
      attributes: {
        url: url,
      }
    };
    this[NavigationMixin.GenerateUrl](pageRef)
      .then(generatedUrl => {
        urlRedirect(generatedUrl);
      });
  }

}