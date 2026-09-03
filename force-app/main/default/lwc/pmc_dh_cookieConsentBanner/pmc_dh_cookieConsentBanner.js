import { LightningElement, track } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import userId from '@salesforce/user/Id';

import CookieConsentHeaderLabel from '@salesforce/label/c.pmc_cookie_consentHeader';
import CookieConsentMessageLabel from '@salesforce/label/c.pmc_cookie_consentMessage';
import AcceptButtonLabel from '@salesforce/label/c.pmc_cookie_acceptCookies';
import RejectButtonLabel from '@salesforce/label/c.pmc_cookie_rejectCookies';

/**
 * A custom LWC to display cookie consent banner.
 * @alias Pmc_dh_cookieConsentBanner
 * @extends LightningElement
 * @hideconstructor
 * @author Raghu Mothukapally
 *
 * @example
 * <c-pmc_dh_cookie-consent-banner></c-pmc_dh_cookie-consent-banner>
 */

export default class Pmc_dh_cookieConsentBanner extends LightningElement {
  openConsentModal;
  User = isGuest;
  currentCookieId = userId;

  /**
   * Label details
   */
  @track labels = {
    CookieConsentHeaderLabel,
    CookieConsentMessageLabel,
    AcceptButtonLabel,
    RejectButtonLabel,
  };

  /** 
   * Lifecycle hook 
   */
  connectedCallback() {
    let LS = localStorage;
    if (this.isGuestUser) {
      this.openConsentModal = !(LS.getItem('guestCookieAcceptStatus') === "accepted" || LS.getItem('guestCookieAcceptStatus') === "rejected");
    }
    else {
      let mycookie = 'userCookieAcceptStatus' + this.currentCookieId + 'mdcookies';
      this.openConsentModal = !(LS.getItem(mycookie) === "accepted" || LS.getItem(mycookie) === "rejected");
    }
  }

  /**
   * On Accpet button click event handler
   * @function handleAccept
   */
  handleAccept() {
    let LS = localStorage;
    if (this.isGuestUser) {
      LS.setItem('guestCookieAcceptStatus', 'accepted');
    } else {
      LS.setItem('userCookieAcceptStatus' + this.currentCookieId + 'mdcookies', 'accepted');
    }

    this.openConsentModal = false;
  }

  /**
   * On Reject button click event handler
   * @function handleReject
   */
  handleReject() {
    let LS = localStorage;
    this.openConsentModal = false;
    if (this.isGuestUser) {
      LS.setItem('guestCookieAcceptStatus', 'rejected');
    } else {
      LS.setItem('userCookieAcceptStatus' + this.currentCookieId + 'mdcookies', 'rejected');
    }
  }
}