import { LightningElement, track, wire } from "lwc";
import getUserDetail from "@salesforce/apex/PMC_DH_UserDetailController.getUserDetail";
import { getRecord } from "lightning/uiRecordApi";
import Id from "@salesforce/user/Id";
import { formatLabel } from "c/pmc_dh_utilityJs";
import USER_ACCOUNT_FIELD from "@salesforce/schema/User.AccountId";
import { formatPhoneNumber, toastMessageHandler } from 'c/pmc_dh_utilityJs';
import {
  SORT_DIRECTION,
  sortData,
  registerListener,
  unregisterAllListeners
} from "c/pmc_dh_utilityJs";
import deactivateUserAndDisablePartner from "@salesforce/apex/PMC_DH_UserInfoController.deactivateUserAndDisablePartner";

import pmc_userManagement_userName from "@salesforce/label/c.pmc_userManagement_userName";
import pmc_userManagement_userType from "@salesforce/label/c.pmc_userManagement_userType";
import pmc_userManagement_userPhone from "@salesforce/label/c.pmc_userManagement_userPhone";
import pmc_userManagement_userEmail from "@salesforce/label/c.pmc_userManagement_userEmail";
import pmc_userManagement_userLocal from "@salesforce/label/c.pmc_userManagement_userLocal";
import pmc_userManagement_userStatus from "@salesforce/label/c.pmc_userManagement_userStatus";
import pmc_accountDetails_delete from "@salesforce/label/c.pmc_accountDetails_delete";
import pmc_user_deleteUserText from "@salesforce/label/c.pmc_user_deleteUserText";
import pmc_user_deleteText from "@salesforce/label/c.pmc_user_deleteText";
import pmc_user_deleteUser from "@salesforce/label/c.pmc_user_deleteUser";
import pmc_user_doNotDelete from "@salesforce/label/c.pmc_user_doNotDelete";

const USER_NAME_FIELD = "struserName";
const actions = [
  { label: pmc_accountDetails_delete, value: "delete" }
];

const columns = [
  {
    label: pmc_userManagement_userName,
    fieldName: "struserName",
    type: "text"
  },
  {
    label: pmc_userManagement_userType,
    fieldName: "strUserType",
    type: "text"
  },
  {
    label: pmc_userManagement_userEmail,
    fieldName: "strUserEmail",
    type: "text"
  },
  {
    label: pmc_userManagement_userPhone,
    fieldName: "strPhone",
    type: "text"
  },
  {
    label: pmc_userManagement_userLocal,
    fieldName: "strLocal",
    type: "text"
  },
  {
    label: pmc_userManagement_userStatus,
    fieldName: "strStatus",
    type: "badge",
    typeAttributes: {
      variant: "slds-badge_lightest"
    }
  },
  {
    label: "",
    fieldName: "",
    type: "action",
    cellAttributes: {
      class: "rightAlignedButton"
    },
    typeAttributes: {
      rowActions: actions,
      menuAlignment: "auto",
      iconName: "utility:down",
      iconSize: "medium",
      variant: "border"
    }
  }
];

/**
 * A custom LWC to display user datatable.
 * @alias Pmc_dh_myUserList
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_my-user-list></c-pmc_dh_my-user-list>
 */

export default class Pmc_dh_myUserList extends LightningElement {
  @track labels = {
    pmc_user_deleteUserText,
    pmc_user_deleteText,
    pmc_user_deleteUser,
    pmc_user_doNotDelete
  };
  @track myUserData = [];
  @track columns = columns;

  pageLoaded = false;
  isDeleteUserModal = false;
  error = "";
  userId;
  userDeleteText;
  isSpinner = true;
  newPhoneNumber;

  @wire(getRecord, { recordId: Id, fields: [USER_ACCOUNT_FIELD] })
  currentUserInfo({ error, data }) {
    if (data) {
      this.effectiveAccountId = data.fields.AccountId.value;
      this.fetchUserDetails();
    } else if (error) {
      this.error = error;
    }
  }

  /**
   * Fetch user management details
   * @function fetchUserDetails
   * @param {string} effAccId
   */
  fetchUserDetails() {
    if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
      this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    }
    getUserDetail({ effAccId: this.effectiveAccountId })
      .then((data) => {
        if (data && Object.keys(data).length) {
          if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
          }
          if (data?.userList?.length >= 0) {
            const parsedData = this.formatUserPhone(JSON.parse(JSON.stringify(data)));
            this.myUserData = sortData(
              JSON.parse(JSON.stringify(parsedData)).userList,
              USER_NAME_FIELD,
              "string",
              SORT_DIRECTION.DESC
            );
          }
          this.closeHandler();
        }
        this.pageLoaded = true;
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.myUserData = [];
        this.pageLoaded = true;
        this.isSpinner = false;
      });
  }

  /** 
   * Format User Management Phone Number 
   * @function formatUserPhone
   * @param {object} result 
   */
  formatUserPhone = (result) => {
    for (let user of result.userList) {
      if (user.strPhone !== null && user.strPhone !== undefined && user.strLocal !== null && user.strLocal !== undefined) {
        const BRAZIL_CODE = 'BR +55';
        const CA_CODE = 'CA +1';
        const US_CODE = 'US +1';
        let code = '';
        if (user.strCountryCode === BRAZIL_CODE) {
          code = "+55";
        } else if (user.strCountryCode === US_CODE || user.strCountryCode === CA_CODE) {
          code = "+1";
        }
        user.strPhone = `${code.replace(/[a-zA-Z]/g, "")} ${formatPhoneNumber(user.strPhone, user.strCountryCode)}`;
      }
    }
    return result;
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    registerListener("newUserDetails", this.displayNewUserDetails, this);
  }

  /**
   * Reloads the page when new user is added
   * @function displayNewUserDetails
   * @param {string} newUser 
   */
  displayNewUserDetails(newUser) {
    if (newUser) {
      this.fetchUserDetails();
    }
  }

  /**
   * User row action handler
   * @function rowActionsHandler
   * @param {Event} event 
   */
  rowActionsHandler(event) {
    if (event.detail.value === "delete") {
      this.userId = event.detail.id;
      let userName = this.myUserData.find(
        (el) => el.strRecId === this.userId
      )?.struserName;
      this.userDeleteText = formatLabel(this.labels.pmc_user_deleteText, [
        userName
      ]);
      this.isDeleteUserModal = true;
    }
  }

  /**
   * Deletes the user from list
   * @function deleteUserHandler
   */
  deleteUserHandler() {
    this.isSpinner = true;
    deactivateUserAndDisablePartner({
      userId: this.userId
    })
      .then((response) => {
        if (JSON.parse(JSON.stringify(response))?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
        }
        this.fetchUserDetails();
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  }

  /**
   * Closes delete user modal
   * @function closeHandler
   */
  closeHandler() {
    this.isDeleteUserModal = false;
  }

  /**
   * Lifecycle Hook
   */
  disconnectedCallback() {
    unregisterAllListeners(this);
  }
}