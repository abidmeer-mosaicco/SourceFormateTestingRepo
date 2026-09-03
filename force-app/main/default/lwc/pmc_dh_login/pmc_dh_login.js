import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { urlRedirect, toastMessageHandler } from 'c/pmc_dh_utilityJs';
import basePath from '@salesforce/community/basePath';
import login from '@salesforce/apex/PMC_DH_SignInController.login';
import isGuest from '@salesforce/user/isGuest';

import pmc_login_text from "@salesforce/label/c.pmc_login_text";
import pmc_login_title from "@salesforce/label/c.pmc_login_title";
import pmc_login_userName from "@salesforce/label/c.pmc_login_userName";
import pmc_login_password from "@salesforce/label/c.pmc_login_password";
import pmc_login_forgotPassword from "@salesforce/label/c.pmc_login_forgotPassword";
import pmc_login_registerNow from "@salesforce/label/c.pmc_login_registerNow";
import pmc_login_newToDigitalHub from "@salesforce/label/c.pmc_login_newToDigitalHub";
import pmc_login_credentialsDoNotMatch from "@salesforce/label/c.pmc_login_credentialsDoNotMatch";

/**
 * A custom LWC to display user datatable.
 * @alias Pmc_dh_login
 * @extends LightningElement
 * @hideconstructor
 * @author Raghu Mothukapally
 *
 * @example
 * <c-pmc_dh_login></c-pmc_dh_login>
 */

const COOKIE_PREFERREDLANGUAGE = "PreferredLanguage";

export default class Pmc_dh_login extends NavigationMixin(LightningElement) {
  queryString = window.location.search;
  email;
  activeTab;
  startURL; 

  @track loginObject = {};
  formErrorMessage = "";
  isSpinner = false;
  @track labels = {
    pmc_login_text,
    pmc_login_title,
    pmc_login_userName,
    pmc_login_password,
    pmc_login_forgotPassword,
    pmc_login_registerNow,
    pmc_login_newToDigitalHub,
    pmc_login_credentialsDoNotMatch
  }

  /**
   * On input change event handler
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    if (event.detail.value !== 'undefined' && event.target && event.target.dataset) {
      this.loginObject[event.target.dataset.id] = event.detail.value;
    }
    this.formErrorMessage = "";
  }

  /**
   * On login button click event handler
   * @function loginHandler
   */
  loginHandler() {
    if (this.handleErrorOnSave()) return;
    this.handleLogin();
  }

  /**
   * Form fields validation
   * @function handleErrorOnSave
   */
  handleErrorOnSave() {
    let allValid = true;
    let focusRef;
    this.template.querySelectorAll(`[data-id]`).forEach(inputComponent => {
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
   * Handle login function
   * @function handleLogin
   */
  handleLogin() {
    this.isSpinner = true;
    let strRedirectURL = null;
    // Contract details redirection
    strRedirectURL = this.startURL;
    // New user is registered, then Super buyer receive email to assign persona for newly registered user.
    // Redirecting to My Accounts page with specific tab (User Mangement)
    if (this.email && this.activeTab) {
      let baseUrl = window.location.origin;
      strRedirectURL = `${baseUrl}${basePath}/my-accounts?email=${this.email}&activeTab=${this.activeTab}`;
    }

    let paramsObj = {
      strUserName: this.loginObject.userName,
      strPassWord: this.loginObject.password,
    }
    if (strRedirectURL) {
      paramsObj.strRedirectURL = strRedirectURL;
    }
    login(paramsObj).then(response => {
      if (response && Object.keys(response).length) {
        if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
        }
        this.deleteCookie(COOKIE_PREFERREDLANGUAGE);
        this.generateUrl(response.strReturnURL);
      }
      this.isSpinner = false;
    }).catch((error) => {
      if (error.body.message) {
        this.formErrorMessage = this.labels.pmc_login_credentialsDoNotMatch
      }
      else {
        toastMessageHandler()
      }
      this.isSpinner = false;
    });
  }

  /**
   * Handle cookie delete: Removing guest's preferred language cookie for auto replace it with the user's preferred language.
   * @function deleteCookie
   * @param {string} cookieName 
   */
  deleteCookie(cookieName) {
    let cookieArray = document.cookie.split(';');
    for (let i = 0; i < cookieArray.length; i++) {
      if (cookieArray[i].includes(cookieName)) {
        let cookieKey = cookieArray[i].split('=')[0];
        let d = new Date();
        d.setDate(d.getDate() - 1);
        let expires = "; expires=" + d;
        let value = "";
        document.cookie = cookieKey + "=" + value + expires + "; path=/";
      }
    }
  }

  /**
   * Generate url handler
   * @function generateUrl
   * @param {string} url 
   */
  generateUrl(url) {
    const pageRef = {
      type: 'standard__webPage',
      attributes: {
        url: url,
      }
    };
    this[NavigationMixin.GenerateUrl](pageRef)
      .then(generatedUrl => {
        if(!window.location.href.includes("app=commeditor")){
          urlRedirect(generatedUrl);
        }
      });
  }

  /**
   * Page navigation handler
   * @function handleNavigation
   * @param {Event} event 
   */
  handleNavigation(event) {
    let target = event.target.dataset.name;
    let url = "";
    switch (target) {
      case "forgotpassword": url = `${basePath}/ForgotPassword`; break;
      case "selfregister": url = `${basePath}/SelfRegister`; break;
      default: break;
    }
    this.generateUrl(url)
  }

  /**
   * Navigation mixin : navigate to another page
   * @function navigateUrl
   * @param {string} url 
   */
  navigateUrl(url) {
    const pageRef = {
      type: 'standard__webPage',
      attributes: {
        url: url
      }
    };
    this[NavigationMixin.Navigate](pageRef)
  }

  /**
   * Submit form on key down handler (Enter key)
   * @function handleKeyDown
   * @param {Event} event
   */
  handleKeyDown(event) {
    if (event.keyCode === 13) {
      event.preventDefault();
      this.loginHandler();
    }
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if(isGuest){
      localStorage.removeItem("EFFECTIVE_ACCOUNT_ID");
      localStorage.removeItem("EFFECTIVE_ACCOUNT_NAME");
    }

    let params = new URLSearchParams(this.queryString);
    this.startURL = params.get('startURL');
    if(window.location.pathname.includes('/login')){
      //redirecting authenticated user to default page
      if(!isGuest) {
        if(!this.startURL) {
          this.generateUrl("/");
        } else {
          this.generateUrl(this.startURL);
        }
      }
    } else {
      //reading redirection/start url params
      if (this.startURL) {
        let startURLArray = this.startURL?.split('?');
        if (!!startURLArray && startURLArray.length > 0) {
          let params2 = new URLSearchParams("?" + startURLArray[1]);
          this.email = params2.get('email');
          this.activeTab = params2.get('activeTab');
        }
      }
    }
  }
}