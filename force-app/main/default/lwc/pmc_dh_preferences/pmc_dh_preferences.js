import { LightningElement, track } from 'lwc';
import getUserNotificationPreferences from "@salesforce/apex/PMC_DH_UserDetailController.getUserNotificationPreferences";
import updateUserNotificationPreferences from "@salesforce/apex/PMC_DH_UserDetailController.updateUserNotificationPreferences";
import { toastMessageHandler } from "c/pmc_dh_utilityJs";

import pmc_preferences_notifyMeFor from "@salesforce/label/c.pmc_preferences_notifyMeFor";
import pmc_preferences_whatsApp from "@salesforce/label/c.pmc_preferences_whatsApp";
import pmc_preferences_text from "@salesforce/label/c.pmc_preferences_text";
import pmc_preferences_email from "@salesforce/label/c.pmc_preferences_email";
import pmc_preferences_marketingContent from "@salesforce/label/c.pmc_preferences_marketingContent";

const WHATSAPP = "Whatsapp";

/**
 * A custom LWC to change Notification Preferences.
 * @alias Pmc_dh_preferences
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_preferences></c-pmc_dh_preferences>
 */

export default class Pmc_dh_preferences extends LightningElement {
  @track preferenceObj = [];
  pageLoaded = false;
  isSpinner = true;
  error;

  /**
   * Custom Label Details
   */
  @track labels = {
    pmc_preferences_notifyMeFor,
    pmc_preferences_whatsApp,
    pmc_preferences_text,
    pmc_preferences_email,
    pmc_preferences_marketingContent
  };

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.fetchNotificationPreferences();
  }

  /**
   * Fetches Notification List
   * @function fetchNotificationPreferences
   */
  fetchNotificationPreferences() {
    getUserNotificationPreferences()
      .then((response) => {
        if (response?.lstAllUserNofications) {
          this.preferenceObj = JSON.parse(JSON.stringify(response.lstAllUserNofications));
          this.updatePreferences();
          this.pageLoaded = true;
          this.isSpinner = false;
        }
      }).catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.pageLoaded = true;
        this.isSpinner = false;
      })
  }

  /**
   * Updates notification preference list
   * @function updatePreferences
   */
  updatePreferences() {
    this.preferenceObj.forEach(pref => {
      pref.lstChildNotifications.sort((a, b) => {
        return a.intSequence - b.intSequence
      });
      pref.lstChildNotifications.forEach(type => {
        type.lstChannelTypes.forEach(channel => {
          channel.isWhatsApp = (type.lstChannelTypes.length === 2 && channel.strNotificationChannelType === WHATSAPP) ? true : false;
        });
        type.mobileView = (type.lstChannelTypes.length > 1) ? true : false;
      })
    });
  }

  /**
   * Updates preference on toggle switch
   * @function handleCheckbox
   * @param {Event} event 
   */
  handleCheckbox(event) {
    this.isSpinner = true;
    if (event.currentTarget.dataset.id && event.currentTarget.name && event.currentTarget.value) {
      let toggleWrapper = {
        strNotificationId: event.currentTarget.dataset.id,
        boolSelectedValue: event.currentTarget.checked
      }
      let channelType = event.currentTarget.name
      let isMarketingComm = (event.currentTarget.value === this.labels.pmc_preferences_marketingContent) ? true : false;
      updateUserNotificationPreferences({
        objChannelTypeWrap: toggleWrapper,
        isMarketingComm: isMarketingComm,
        strNotificationChannelType: channelType
      }).then((response) => {
        if (response && Object.keys(response).length) {
          this.fetchNotificationPreferences();
        }
        this.isSpinner = false;
      }).catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      })
    }
  }
}