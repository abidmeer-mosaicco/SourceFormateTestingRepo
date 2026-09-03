/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import {
  formatLabel,
  formatDate,
  handleError,
  getCurrencyAndPrice,
  isBrazilRegion,
  urlRedirect,
  toastMessageHandler,
  sortData,
  SORT_DIRECTION,
  getRawDateUtil
} from "c/pmc_dh_utilityJs";
import basePath from "@salesforce/community/basePath";
import communityId from "@salesforce/community/Id";
import getQuoteDetails from "@salesforce/apex/PMC_DH_QuoteManagementControllerClass.getQuoteDetails";
import updateQuote from "@salesforce/apex/PMC_DH_QuoteManagementControllerClass.updateQuote";
import updateQuoteLineItem from "@salesforce/apex/PMC_DH_QuoteManagementControllerClass.updateQuoteLineItem";
import updateQuoteLineProdInfo from "@salesforce/apex/PMC_DH_QuoteManagementHelper.updateQuoteLineProdInfo";
import getCancelReasons from "@salesforce/apex/PMC_DH_QuoteMgmtActionController.getCancelReasons";
import getRejectReasons from "@salesforce/apex/PMC_DH_QuoteMgmtActionController.getRejectReasons";
import updateQuoteStatus from "@salesforce/apex/PMC_DH_QuoteMgmtActionController.updateQuoteStatus";
import getCountryValidation from "@salesforce/apex/PMC_DH_QuoteListViewController.getCountryValidation";
import getPricingSummary from "@salesforce/apex/PMC_DH_GetPriceResponseParsing.getPricingSummaryForQuote";
import getActiveCartId from "@salesforce/apex/PMC_DH_QuoteUtils.getActiveCartId";
import addCartItems from "@salesforce/apex/PMC_DH_QuoteUtils.addCartItems";
import getConversationHistory from "@salesforce/apex/PMC_DH_QuoteMgmtRelatedItemsClass.getConversationHistory";
import validateCart from "@salesforce/apex/PMC_DH_CartValidationController.validateCart";
import createCadence from "@salesforce/apex/PMC_DH_CadenceUtil.createCadence";
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import viewOnlyAccess from "@salesforce/customPermission/Quote_ViewOnlyAccess";
import DisableAddtoOrder from '@salesforce/customPermission/DisableAddtoOrder';
import DH_Edit_Address from '@salesforce/customPermission/DH_Edit_Address';

import pmc_requestForQuote_quoteId from "@salesforce/label/c.pmc_requestForQuote_quoteId";
import pmc_addNewUser_soldToAccount from "@salesforce/label/c.pmc_addNewUser_soldToAccount";
import pmc_addresses_status from "@salesforce/label/c.pmc_addresses_status";
import pmc_quoteCheckoutFlow_paymentMethod from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentMethod";
import pmc_requestForQuote_productsInformation from "@salesforce/label/c.pmc_requestForQuote_productsInformation";
import pmc_requestForQuote_totalQty from "@salesforce/label/c.pmc_requestForQuote_totalQty";
import pmc_requestForQuote_qty from "@salesforce/label/c.pmc_requestForQuote_qty";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_quoteCheckoutFlow_incoterms from "@salesforce/label/c.pmc_quoteCheckoutFlow_incoterms";
import pmc_userDetails_edit from "@salesforce/label/c.pmc_userDetails_edit";
import pmc_requestForQuote_requestedContractInfo from "@salesforce/label/c.pmc_requestForQuote_requestedContractInfo";
import pmc_quoteCheckoutFlow_startingFrom from "@salesforce/label/c.pmc_quoteCheckoutFlow_startingFrom";
import pmc_quoteCheckoutFlow_paymentInfo from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentInfo";
import pmc_quoteCheckoutFlow_paymentTerms from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentTerms";
import pmc_quoteCheckoutFlow_deliveryMode from "@salesforce/label/c.pmc_quoteCheckoutFlow_deliveryMode";
import pmc_quoteCheckoutFlow_currency from "@salesforce/label/c.pmc_quoteCheckoutFlow_currency";
import pmc_quoteCheckoutFlow_endDate from "@salesforce/label/c.pmc_quoteCheckoutFlow_endDate";
import pmc_quoteDetailsFlow_quoteSummary from "@salesforce/label/c.pmc_quoteDetailsFlow_quoteSummary";
import pmc_quoteDetailsFlow_customerName from "@salesforce/label/c.pmc_quoteDetailsFlow_customerName";
import pmc_quoteDetailsFlow_requestedDate from "@salesforce/label/c.pmc_quoteDetailsFlow_requestedDate";
import pmc_quoteDetailsFlow_expiresIn from "@salesforce/label/c.pmc_quoteDetailsFlow_expiresIn";
import pmc_quoteDetailsFlow_contracts from "@salesforce/label/c.pmc_quoteDetailsFlow_contracts";
import pmc_miniCartModal_closeLabel from "@salesforce/label/c.pmc_miniCartModal_closeLabel";
import pmc_quoteDetailsFlow_quoteSubmitted from "@salesforce/label/c.pmc_quoteDetailsFlow_quoteSubmitted";
import pmc_quoteDetailsFlow_inProgress from "@salesforce/label/c.pmc_quoteDetailsFlow_inProgress";
import pmc_quoteDetailsFlow_accepted from "@salesforce/label/c.pmc_quoteDetailsFlow_accepted";
import pmc_quoteDetailsFlow_cancelQuote from "@salesforce/label/c.pmc_quoteDetailsFlow_cancelQuote";
import pmc_quoteDetailsFlow_contractInfoText from "@salesforce/label/c.pmc_quoteDetailsFlow_contractInfoText";
import pmc_quoteDetailsFlow_quoteLabel from "@salesforce/label/c.pmc_quoteDetailsFlow_quoteLabel";
import pmc_quoteDetailsFlow_check from "@salesforce/label/c.pmc_quoteDetailsFlow_check";
import pmc_quoteDetailsFlow_statusNotApplicable from "@salesforce/label/c.pmc_quoteDetailsFlow_statusNotApplicable";
import pmc_quoteDetailsFlow_acceptQuote from "@salesforce/label/c.pmc_quoteDetailsFlow_acceptQuote";
import pmc_quoteDetailsFlow_rejectQuote from "@salesforce/label/c.pmc_quoteDetailsFlow_rejectQuote";
import pmc_quoteDetailsFlow_requote from "@salesforce/label/c.pmc_quoteDetailsFlow_requote";
import pmc_quoteDetailsFlow_reason from "@salesforce/label/c.pmc_quoteDetailsFlow_reason";
import pmc_quoteDetailsFlow_reasonForRejection from "@salesforce/label/c.pmc_quoteDetailsFlow_reasonForRejection";
import pmc_quoteDetailsFlow_reasonForCancellation from "@salesforce/label/c.pmc_quoteDetailsFlow_reasonForCancellation";
import pmc_quoteDetailsFlow_reasonForCanceling from "@salesforce/label/c.pmc_quoteDetailsFlow_reasonForCanceling";
import pmc_quoteDetailsFlow_reasonForRejecting from "@salesforce/label/c.pmc_quoteDetailsFlow_reasonForRejecting";
import pmc_quoteDetailsFlow_cancelAndRequote from "@salesforce/label/c.pmc_quoteDetailsFlow_cancelAndRequote";
import pmc_quoteDetailsFlow_rejectAndRequote from "@salesforce/label/c.pmc_quoteDetailsFlow_rejectAndRequote";
import pmc_addressDetails_cancel from "@salesforce/label/c.pmc_addressDetails_cancel";
import pmc_requote_title from "@salesforce/label/c.pmc_requote_title";
import pmc_requote_text from "@salesforce/label/c.pmc_requote_text";
import pmc_caseMgmt_commentPlaceholder from "@salesforce/label/c.pmc_caseMgmt_commentPlaceholder";
import pmc_caseMgmt_reopenComments from "@salesforce/label/c.pmc_caseMgmt_reopenComments";
import pmc_quoteDetailsFlow_messageBannerInactive from "@salesforce/label/c.pmc_quoteDetailsFlow_messageBannerInactive";
import pmc_quoteDetailsFlow_messageBannerAcceptedByManager from "@salesforce/label/c.pmc_quoteDetailsFlow_messageBannerAcceptedByManager";
import pmc_contractDetails_contract from "@salesforce/label/c.pmc_contractDetails_contract";
import pmc_quote_acceptQuote from "@salesforce/label/c.pmc_quote_acceptQuote";
import pmc_quote_aceptQuoteText from "@salesforce/label/c.pmc_quote_aceptQuoteText";
import pmc_quoteDetailsFlow_changeInfo from "@salesforce/label/c.pmc_quoteDetailsFlow_changeInfo";
import pmc_quoteDetailsFlow_changeRequesterInfo from "@salesforce/label/c.pmc_quoteDetailsFlow_changeRequesterInfo";
import pmc_quoteDetailsFlow_noUpdateMsg from "@salesforce/label/c.pmc_quoteDetailsFlow_noUpdateMsg";
import pmc_quoteDetailsFlow_changeMadeByInfo from "@salesforce/label/c.pmc_quoteDetailsFlow_changeMadeByInfo";
import pmc_contractDetails_averagePricePerUnit from "@salesforce/label/c.pmc_contractDetails_averagePricePerUnit";
import pmc_contractDetails_pricePerUnit from "@salesforce/label/c.pmc_contractDetails_pricePerUnit";
import pmc_quoteCheckoutFlow_duplicateProductsMessage from "@salesforce/label/c.pmc_quoteCheckoutFlow_duplicateProductsMessage";
import pmc_quoteCheckoutFlow_maxEndDateError from "@salesforce/label/c.pmc_quoteCheckoutFlow_maxEndDateError";
import pmc_requestForQuote_unitOfMeasure from "@salesforce/label/c.pmc_requestForQuote_unitOfMeasure";
import pmc_requestForQuote_packagingType from "@salesforce/label/c.pmc_requestForQuote_packagingType";
import pmc_requestForQuote_packType from "@salesforce/label/c.pmc_requestForQuote_packType";
import pmc_quoteDetails_updates from "@salesforce/label/c.pmc_quoteDetails_updates";
import pmc_cadenceSuggestion_suggestCadenceDelivery from "@salesforce/label/c.pmc_cadenceSuggestion_suggestCadenceDelivery";
import pmc_cadenceSuggestion_viewCadenceDelivery from "@salesforce/label/c.pmc_cadenceSuggestion_viewCadenceDelivery";
import pmc_unauthorizedAccess_restrictedAccessText2 from "@salesforce/label/c.pmc_unauthorizedAccess_restrictedAccessText2";
import pmc_quoteHistory_requestedQuotes from "@salesforce/label/c.pmc_quoteHistory_requestedQuotes";
import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";
import pmc_orderDetails_active from "@salesforce/label/c.pmc_orderDetails_active";
import pmc_orderDetails_inactive from "@salesforce/label/c.pmc_orderDetails_inactive";
import pmc_quoteDetailsFlow_statusActionPending from "@salesforce/label/c.pmc_quoteDetailsFlow_statusActionPending";
import pmc_quoteDetailsFlow_statusSubmitted from "@salesforce/label/c.pmc_quoteDetailsFlow_statusSubmitted";
import pmc_quoteDetailsFlow_statusUnderReviewByAccountManager from "@salesforce/label/c.pmc_quoteDetailsFlow_statusUnderReviewByAccountManager";
import pmc_quoteDetailsFlow_statusAcceptedByAccountManager from "@salesforce/label/c.pmc_quoteDetailsFlow_statusAcceptedByAccountManager";
import pmc_quoteCheckoutFlow_preferredShipFrom from "@salesforce/label/c.pmc_quoteCheckoutFlow_preferredShipFrom";
import pmc_quoteCheckout_endDateErrorMsg from "@salesforce/label/c.pmc_quoteCheckout_endDateErrorMsg";
import pmc_quouteDetails_contractsValidTo from "@salesforce/label/c.pmc_quouteDetails_contractsValidTo";
import pmc_quouteDetails_contractsValidFrom from "@salesforce/label/c.pmc_quouteDetails_contractsValidFrom";
import pmc_quoteCheckoutFlow_paymentDate from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentDate";
import pmc_quoteCheckoutFlow_paymentDateErrorMsg1 from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentDateErrorMsg1";
import pmc_quoteCheckoutFlow_paymentDateErrorMsg2 from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentDateErrorMsg2";

const STATUS_SUBMITTED = "Submitted";
const STATUS_IN_PROGRESS = "In Progress";
const UNDER_REVIEW_STATUS = "Under Review By Account Manager";
const ACTION_PENDING_STATUS = "Action Pending";
const STATUS_INACTIVE = "Inactive";
const STATUS_ACCEPTED = "Accepted";
const STATUS_ACCEPTED_BY_MANAGER = "Accepted by Account Manager";
const STATUS_REJECTED = "Rejected";
const STATUS_CANCELLED = "Cancelled";
const STATUS_EXPIRED = "Expired";
const MESSAGE_TYPE_WARNING = "warning";
const MESSAGE_TYPE_INFO = "info";
const BADGE_STATUS_WARNING = "warning";
const BADGE_STATUS_ERROR = "error";
const SOURCE_RFQ = "RFQ";
const LABEL = "label";
const INCOTERM_CPT = "CPT";

/**
 * A custom LWC to display the Quote Details Information.
 * @alias Pmc_dh_quoteDetailsInfo
 * @extends LightningElement
 * @hideconstructor
 * @author Himanshu Rathore
 * @example
 * <c-pmc_dh_quote-details-info></c-pmc_dh_quote-details-info>
 */

export default class Pmc_dh_quoteDetailsInfo extends NavigationMixin(LightningElement) {
  @track historyLoaded = false;
  @track effectiveAccountId;
  @track activeCartId;
  @track isRequoteModal = false;
  @track isCancelQuoteModal = false;
  @track isRejectQuoteModal = false;
  @track isAcceptQuoteModal = false;
  @track isEditDisabled = {
    contractInfo: true,
    quoteSummary: true,
    paymentInfo: true
  };
  @track labels = {
    pmc_requestForQuote_quoteId,
    pmc_addNewUser_soldToAccount,
    pmc_addresses_status,
    pmc_quoteCheckoutFlow_paymentInfo,
    pmc_quoteCheckoutFlow_paymentTerms,
    pmc_quoteCheckoutFlow_paymentMethod,
    pmc_quoteCheckoutFlow_currency,
    pmc_requestForQuote_productsInformation,
    pmc_requestForQuote_totalQty,
    pmc_requestForQuote_qty,
    pmc_quoteCheckoutFlow_shipTo,
    pmc_quoteCheckoutFlow_incoterms,
    pmc_quoteCheckoutFlow_deliveryMode,
    pmc_userDetails_edit,
    pmc_requestForQuote_requestedContractInfo,
    pmc_quoteCheckoutFlow_startingFrom,
    pmc_quoteCheckoutFlow_endDate,
    pmc_quoteDetailsFlow_quoteSummary,
    pmc_quoteDetailsFlow_customerName,
    pmc_quoteDetailsFlow_requestedDate,
    pmc_quoteDetailsFlow_expiresIn,
    pmc_quoteDetailsFlow_contracts,
    pmc_miniCartModal_closeLabel,
    pmc_quoteDetailsFlow_cancelQuote,
    pmc_quoteDetailsFlow_contractInfoText,
    pmc_quoteDetailsFlow_quoteLabel,
    pmc_quoteDetailsFlow_check,
    pmc_quoteDetailsFlow_acceptQuote,
    pmc_quoteDetailsFlow_rejectQuote,
    pmc_quoteDetailsFlow_requote,
    pmc_quoteDetailsFlow_reason,
    pmc_quoteDetailsFlow_reasonForCanceling,
    pmc_quoteDetailsFlow_reasonForRejecting,
    pmc_quoteDetailsFlow_cancelAndRequote,
    pmc_quoteDetailsFlow_rejectAndRequote,
    pmc_addressDetails_cancel,
    pmc_requote_title,
    pmc_requote_text,
    pmc_caseMgmt_commentPlaceholder,
    pmc_caseMgmt_reopenComments,
    pmc_quoteDetailsFlow_messageBannerInactive,
    pmc_quoteDetailsFlow_messageBannerAcceptedByManager,
    pmc_contractDetails_contract,
    pmc_quote_aceptQuoteText,
    pmc_quote_acceptQuote,
    pmc_quoteDetailsFlow_statusNotApplicable,
    pmc_quoteDetailsFlow_changeRequesterInfo,
    pmc_quoteDetailsFlow_changeInfo,
    pmc_quoteDetailsFlow_noUpdateMsg,
    pmc_quoteDetailsFlow_changeMadeByInfo,
    pmc_contractDetails_averagePricePerUnit,
    pmc_contractDetails_pricePerUnit,
    pmc_quoteCheckoutFlow_duplicateProductsMessage,
    pmc_quoteCheckoutFlow_maxEndDateError,
    pmc_requestForQuote_unitOfMeasure,
    pmc_requestForQuote_packagingType,
    pmc_requestForQuote_packType,
    pmc_quoteDetails_updates,
    pmc_unauthorizedAccess_restrictedAccessText2,
    pmc_quoteHistory_requestedQuotes,
    pmc_breadcrumb_homepage,
    pmc_orderDetails_active,
    pmc_orderDetails_inactive,
    pmc_quoteDetailsFlow_statusActionPending,
    pmc_quoteDetailsFlow_statusSubmitted,
    pmc_quoteDetailsFlow_statusUnderReviewByAccountManager,
    pmc_quoteDetailsFlow_statusAcceptedByAccountManager,
    pmc_quoteDetailsFlow_quoteSubmitted,
    pmc_quoteDetailsFlow_accepted,
    pmc_quoteCheckoutFlow_preferredShipFrom,
    pmc_quoteCheckout_endDateErrorMsg,
    pmc_quouteDetails_contractsValidTo,
    pmc_quouteDetails_contractsValidFrom,
    pmc_quoteCheckoutFlow_paymentDate
  };
  @track iconUrlObj = {
    mosaicLogoUrl: `${PMC_BrandingAssetsStaticResource}/images/logo-mosaic.png`
  };
  @track pageObj = {};
  @track quoteCaseObject = {};
  @track paymentTermsOptions = [];
  @track currencyOptions = [];
  @track shipToOptions = [];
  @track incotermsOptions = [];
  @track deliveryModeOptions = [];
  @track shipFromOptions = [];
  @track remainingTime = this.labels.pmc_quoteDetailsFlow_statusNotApplicable;
  @track pageLoaded = false;
  @track isSpinner = true;
  @track setIntervalTime = 1000;
  @track errorCaseTimer = 3000;
  @track showExpiresInField = true;
  @track cancelQuotePicklistOptions = [];
  @track rejectQuotePicklistOptions = [];
  @track formattedRequestedDate;
  @track formattedStartingFromDate;
  @track formattedEndDate;
  @track reasonForLabel;
  @track conversationHistoryResults = [];
  isEndDateDisabled = true;
  quoteNumber;
  queryString = window.location.search;
  pageRendered = false;
  isQuoteSubmittedScreen = false;
  isInProgressScreen = false;
  showCancelQuoteBtn = false;
  actionPendingStatusBtns = false;
  showProgressBarTracker = true;
  isQuoteApproved = false;
  priceLoaded = false;
  showPriceDetails = false;
  isCadenceSuggestionAllowed = false;
  isCadenceSuggestionModal = false;
  isCadenceReadOnly = false;
  isBuyerOrSuperBuyer = !DisableAddtoOrder;
  cadenceHyperLinkText;
  expirationDate;
  currentDateTime;
  tempObj = {};
  error;
  today;
  minEndDate;
  quoteId;
  errorMessage;
  disableQuoteBtn = true;
  showMessageBanner = false;
  messageForBanner;
  messageBannerType;
  showRequoteOnlyBtn = false;
  isLocationBrazil = false;
  isUnauthorizedAccess = false;
  isPrepaymentAllowed = false;
  isPrepaymentDateField = false;
  maxPrepaymentDate;
  minPrepaymentDate;
  formattedPrePayementDate;
  paymentDateErrorMsg;

  @track crumbs = [
    { label: this.labels.pmc_breadcrumb_homepage, url: `${basePath}/`, isActive: false },
    {
      label: this.labels.pmc_quoteHistory_requestedQuotes,
      url: `${basePath}/quotes`,
      isActive: false
    },
    { label: ``, url: "", isActive: true }
  ];

  @track cartItemObj = [];

  @track stepsData = [
    {
      value: STATUS_SUBMITTED,
      title: pmc_quoteDetailsFlow_quoteSubmitted,
      status: "",
      complete: false
    },
    {
      value: STATUS_IN_PROGRESS,
      title: pmc_quoteDetailsFlow_inProgress,
      status: "",
      complete: false
    },
    {
      value: STATUS_ACCEPTED,
      title: pmc_quoteDetailsFlow_accepted,
      status: "",
      complete: false
    }
  ];

  get steps() {
    return this.stepsData;
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.isSuperBuyerOrContractManager = viewOnlyAccess || (!DisableAddtoOrder && DH_Edit_Address);
    this.today = new Date().toISOString().slice(0, 10);
    this.isLocationBrazil = isBrazilRegion();
    this.isPrepaymentAllowed = this.isLocationBrazil && this.isBuyerOrSuperBuyer;
    this.queryParamsHandler();
    // this.countryValidation();
    this.showPriceDetails = true;
    this.getConversationHistoryDetails();
    this.loadCancelQuotePicklistDetails();
    this.loadRejectQuotePicklistDetails();

    let that = this;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.intervalId = setInterval(() => {
      if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
        this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
        clearInterval(that.intervalId);
        this.loadQuoteDetails();
      }
    }, 100);
  }

  /**
   * Reading query params
   * @function queryParamsHandler
   */
  queryParamsHandler() {
    if (this.queryString) {
      let params = new URLSearchParams(this.queryString);
      let startURLTemp = params.get("quoteNumber");
      if (startURLTemp) {
        let startURLArray = startURLTemp?.split("?");
        this.quoteId = startURLArray[1].split("=")[1];
        this.quoteNumber = startURLTemp.split("?")[0];
        this.crumbs = this.crumbs.map((elem, index) => {
          if (index === 2) {
            elem.label = `${this.labels.pmc_quoteDetailsFlow_quoteLabel} ${this.quoteNumber}`;
          }
          return elem;
        });
      }
    }
  }

  /**
   * Method to show Expiry in Quote Summary
   * @function updateCounter
   * @param {DateTime} expirationDate
   * @param {DateTime} currentDateTime
   */
  updateCounter = (expirationDate, currentDateTime) => {
    if (expirationDate && currentDateTime) {
      let timeDifference = expirationDate - currentDateTime;
      const timerInterval = setInterval(() => {
        const millisecondsPerSecond = 1000;
        const millisecondsPerMinute = millisecondsPerSecond * 60;
        const millisecondsPerHour = millisecondsPerMinute * 60;
        let remainingHours = Math.floor(timeDifference / millisecondsPerHour);
        let remainingMinutes = Math.floor(
          (timeDifference % millisecondsPerHour) / millisecondsPerMinute
        );
        let remainingSeconds = Math.floor(
          (timeDifference % millisecondsPerMinute) / millisecondsPerSecond
        );
        if (timeDifference <= 0) {
          clearInterval(timerInterval);
          this.remainingTime = "00:00:00";
        } else {
          if (remainingHours < 10) {
            remainingHours = `0${remainingHours}`;
          }
          if (remainingMinutes < 10) {
            remainingMinutes = `0${remainingMinutes}`;
          }
          if (remainingSeconds < 10) {
            remainingSeconds = `0${remainingSeconds}`;
          }
          this.remainingTime = `${remainingHours}:${remainingMinutes}:${remainingSeconds}`;
        }
        timeDifference -= this.setIntervalTime;
      }, this.setIntervalTime);
    } else {
      this.remainingTime = this.labels.pmc_quoteDetailsFlow_statusNotApplicable;
    }
  };

  /**
   * Fetching Quote Details Page Data from Backend Method
   * @function loadQuoteDetails
   */
  loadQuoteDetails = () => {
    getQuoteDetails({
      strCommunityId: communityId,
      strEffectiveAccountId: this.effectiveAccountId,
      strQuoteId: this.quoteId
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusCode && JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusCode === '999') {
            this.isUnauthorizedAccess = true;
            this.isSpinner = false;
            return;
          }
          else if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          this.pageObj = JSON.parse(JSON.stringify(result));
          this.cartItemObj = [];
          if (this.pageObj?.productInfoWrapper?.lstCartWrapper) {
            this.pageObj.productInfoWrapper.lstCartWrapper.forEach((e1) => {
              e1.lstCartItems.forEach((e2) => {
                this.cartItemObj.push({
                  strQuantity: e2.strQuantity,
                  strDeliveryMode: e2.strDeliveryMode,
                  strIncoterms: e2.strIncoterms,
                  strShipFrom: e2.strShipFrom,
                  strShipTo: e2.strShipTo,
                  strProductId: e1.strProductId,
                  strProductName: e1.strProductName,
                  strSku: e1.strSku,
                  strSource: SOURCE_RFQ
                });
              });
            });
          }
          this.buildPaymentInformationData(this.pageObj);
          this.buildProductInformationData(this.pageObj);
          this.stepChangeHandler();
          this.buildQuoteSummaryData();
          this.quoteStatusHandler(this.pageObj.quoteSummaryWrapper.strSummaryStatus);
          this.buildRequestedContractInformationData();
          if (this.showPriceDetails) {
            this.loadPricingDetails();
          }
        }
        this.pageLoaded = true;
        this.isSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.pageRendered = true;
        this.isSpinner = false;
      });
  };

  /**
   * Handles translations for quote status
   * @function quoteStatusHandler
   * @param {string} summaryStatus 
   */
  quoteStatusHandler(summaryStatus) {
    switch (summaryStatus) {
      case STATUS_SUBMITTED:
        this.pageObj.quoteSummaryWrapper.updatedStatus = this.labels.pmc_quoteDetailsFlow_statusSubmitted;
        break;

      case UNDER_REVIEW_STATUS:
        this.pageObj.quoteSummaryWrapper.updatedStatus = this.labels.pmc_quoteDetailsFlow_statusUnderReviewByAccountManager;
        break;

      case ACTION_PENDING_STATUS:
        this.pageObj.quoteSummaryWrapper.updatedStatus = this.labels.pmc_quoteDetailsFlow_statusActionPending;
        break;

      case STATUS_INACTIVE:
        this.pageObj.quoteSummaryWrapper.updatedStatus = this.labels.pmc_orderDetails_inactive;
        break;

      case STATUS_ACCEPTED:
        this.pageObj.quoteSummaryWrapper.updatedStatus = this.labels.pmc_quoteDetailsFlow_accepted;
        break;

      case STATUS_ACCEPTED_BY_MANAGER:
        this.pageObj.quoteSummaryWrapper.updatedStatus = this.labels.pmc_quoteDetailsFlow_statusAcceptedByAccountManager;
        break;

      default:
        break;
    }
  }

  /**
   * Get country validation for price summary section
   * @function countryValidation
   */
  countryValidation() {
    if (sessionStorage.getItem("userRegion")) {
      this.countryRegion = sessionStorage.getItem("userRegion");
    }
    this.isSpinner = true;
    getCountryValidation({
      strcountryRegion: this.countryRegion
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          this.showPriceDetails = result.boolFlag;
        }
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  }

  /**
   * Fetching Price Summary Details
   * @function loadPricingDetails
   */
  loadPricingDetails = () => {
    this.isSpinner = true;
    getPricingSummary({
      strQuoteId: this.quoteId
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          this.priceSummaryData = result;
          this.buildPriceSummaryData();
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  };

  /**
   * Getting conversation history details
   * @function getConversationHistoryDetails
   */
  getConversationHistoryDetails() {
    this.conversationHistoryResults = [];
    this.historyLoaded = false;
    getConversationHistory({
      strQuoteId: this.quoteId
    })
      .then((results) => {
        if (results && Object.keys(results).length) {
          if (JSON.parse(JSON.stringify(results)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(results)).statusCodeMessage.strStatusMessage)
          }
          this.conversationHistoryResults = JSON.parse(JSON.stringify(results.lstQtHistory));
          this.conversationHistoryResults.forEach((res, index) => {
            if (
              res.strFieldName === this.labels.pmc_quouteDetails_contractsValidTo ||
              res.strFieldName === this.labels.pmc_quouteDetails_contractsValidFrom
            ) {
              res.strOriginalValue = res.strOriginalValue
                ? formatDate(res.strOriginalValue)
                : null;
              res.strNewValue = res.strNewValue
                ? formatDate(res.strNewValue)
                : null;
            }
            res.changeRequesterInfo =
              res.strUsrName === "Mosaic"
                ? formatLabel(this.labels.pmc_quoteDetailsFlow_changeMadeByInfo, [
                  res.strUsrName,
                  formatDate(res.datModifiedDate.split("T")[0])
                ])
                : formatLabel(
                  this.labels.pmc_quoteDetailsFlow_changeRequesterInfo,
                  [
                    res.strUsrName,
                    formatDate(res.datModifiedDate.split("T")[0])
                  ]
                );
            res.changeInfo = formatLabel(
              this.labels.pmc_quoteDetailsFlow_changeInfo,
              [res.strFieldName, res.strOriginalValue, res.strNewValue]
            );
            res.id = index;
          });
        }
        this.historyLoaded = true;
      })
      .catch(() => {
        toastMessageHandler();
        this.historyLoaded = true;
      });
  }

  /**
   * Fetch Picklist Values for Cancel Quote Modal
   * @function loadCancelQuotePicklistDetails
   */
  loadCancelQuotePicklistDetails = () => {
    getCancelReasons()
      .then((options) => {
        if (options?.length) {
          this.cancelQuotePicklistOptions = JSON.parse(JSON.stringify(options));
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
      });
  };

  /**
   * Fetch Picklist Values for Reject Quote Modal
   * @function loadRejectQuotePicklistDetails
   */
  loadRejectQuotePicklistDetails = () => {
    getRejectReasons()
      .then((options) => {
        if (options?.length) {
          this.rejectQuotePicklistOptions = JSON.parse(JSON.stringify(options));
        }
      })
      .catch(() => {
        toastMessageHandler();
      });
  };

  /** 
   * Stepper Logic
   * @function stepChangeHandler
   */
  stepChangeHandler() {
    const matchedStep = this.stepsData.find(
      (step) =>
        step.value === this.pageObj.quoteSummaryWrapper.strProgressIndicatorStatus
    );
    if (matchedStep) {
      matchedStep.complete = true;
    }
    this.stepsData.forEach((step) => {
      if (step !== matchedStep) {
        step.complete = false;
      }
    });
  }

  /**
   * Builds wrapper for price summary data
   * @function buildPriceSummaryData
   */
  buildPriceSummaryData = () => {
    this.pageObj.productInfoWrapper.lstCartWrapper.forEach((cartItem) => {
      let productItem;
      this.priceSummaryData.lstPriceSummary?.forEach((product) => {
        if (product?.strProductSKU === cartItem.strSku) {
          productItem = product;
        }
      });
      cartItem.avgPricePerUnit =
        productItem?.decPrice / productItem?.intQuantity;
      cartItem.lstCartItems.forEach((el) => {
        let shipmentItem;
        productItem.lstQuoteLine?.forEach((item) => {
          if (item?.strQuoteLineId === el.strCartItemId) {
            shipmentItem = item;
          }
        });
        el.pricePerUnit = shipmentItem?.decPrice;
      });
    });
    this.updatePriceCurrency();
    this.priceLoaded = true;
  };

  /**
   * Updates Price related values
   * @function updatePriceCurrency
   */
  updatePriceCurrency() {
    this.pageObj.productInfoWrapper.lstCartWrapper.forEach((prod) => {
      prod.lstCartItems.forEach((el) => {
        if (el.pricePerUnit !== undefined) {
          el.pricePerUnit = getCurrencyAndPrice(
            this.priceSummaryData.strCurrencyIsoCode,
            parseFloat(el.pricePerUnit).toFixed(2)
          );
        }
        else {
          el.pricePerUnit = getCurrencyAndPrice(this.priceSummaryData.strCurrencyIsoCode, 0);
        }
      });
      if (prod.avgPricePerUnit !== undefined) {
        prod.avgPricePerUnit = getCurrencyAndPrice(
          this.priceSummaryData.strCurrencyIsoCode,
          parseFloat(prod.avgPricePerUnit).toFixed(2)
        );
      }
      else {
        prod.avgPricePerUnit = getCurrencyAndPrice(this.priceSummaryData.strCurrencyIsoCode, 0);
      }
    });
  }

  /**
   * Fetching Picklist Options from BE method for Payment Information
   * @function buildPaymentInformationData
   * @param {object} result
   */
  buildPaymentInformationData = (result) => {
    this.minPrepaymentDate = this.today;
    this.paymentTermsOptions = [
      ...result.paymentInformationWrapper.lstPaymentTerms
    ];
    this.paymentTermsOptions = sortData(this.paymentTermsOptions, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
    this.currencyOptions = [...result.paymentInformationWrapper.lstCurrency];
    if (result.paymentInformationWrapper.datPrepaymentDate && this.isPrepaymentAllowed) {
      this.isFormattedPrepaymentDateField = true;
      this.formattedPrePayementDate = formatDate(
        result.paymentInformationWrapper.datPrepaymentDate
      );
    }

    let strPaymentTermSelectedLabel = this.paymentTermsOptions?.find(
      (data) => result.paymentInformationWrapper?.strPaymentTermSelected === data.value
    );
    this.strPaymentTermSelectedLabel = strPaymentTermSelectedLabel ? strPaymentTermSelectedLabel.label : "";



    if ((result.paymentInformationWrapper?.strPaymentTermSelected === "Fixed Date" || result.paymentInformationWrapper?.strPaymentTermSelected === "Prepayment") && this.isPrepaymentAllowed) {
      this.isPrepaymentDateField = true;
      this.paymentDateErrorMsg = result.paymentInformationWrapper.strPaymentTermSelected === "Prepayment" ? pmc_quoteCheckoutFlow_paymentDateErrorMsg1 : pmc_quoteCheckoutFlow_paymentDateErrorMsg2;
      this.setMinAndMaxPrepaymentDate();
    }
    else {
      delete this.pageObj.paymentInformationWrapper.datPrepaymentDate;
    }
  };

  /**
   * Fetching Picklist Options from BE method for Products Information
   * @function buildProductInformationData
   * @param {object} result
   */
  buildProductInformationData = (result) => {
    if (result) {
      result.productInfoWrapper.lstCartWrapper.forEach((cartItem) => {
        cartItem.lstIncoterms = sortData(cartItem.lstIncoterms, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
        cartItem.lstPackType = sortData(cartItem.lstPackType, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
        cartItem.lstProductUOM = sortData(cartItem.lstProductUOM, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
        cartItem.lstShipFrom = sortData(cartItem.lstShipFrom, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
        cartItem.lstShipTo = sortData(cartItem.lstShipTo, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
        cartItem.isEditDisabled = true;
        cartItem.lstCartItems.forEach((e) => {
          if (e.strIncoterms && e.strIncoterms === INCOTERM_CPT) {
            e.lstDeliveryModes = sortData(cartItem.lstDeliveryModesCPT, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
          }
          else {
            e.lstDeliveryModes = sortData(cartItem.lstDeliveryModes, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
          }
          e.isEditDisabled = true;
          e.isPackTypeDisabled = true;
          e.strPackageType = e.strPackageType ? e.strPackageType : "-";
        });
      });
    }
  }

  /**
   * Fetching Starting From and End Date from BE method for Requested Contract Information Section
   * @function buildRequestedContractInformationData
   */
  buildRequestedContractInformationData = () => {
    if (this.pageObj.requestedContractInfoWrapper.datStartDate) {
      this.formattedStartingFromDate = formatDate(
        this.pageObj.requestedContractInfoWrapper.datStartDate
      );
    }
    if (this.pageObj.requestedContractInfoWrapper.datEndDate) {
      this.formattedEndDate = formatDate(
        this.pageObj.requestedContractInfoWrapper.datEndDate
      );
    }
  };

  /**
   * Sending Data from BE Method to updateCounter method to show Expiry in Quote Summary section
   * @function buildQuoteSummaryData
   */
  buildQuoteSummaryData = () => {
    this.formattedRequestedDate = formatDate(
      this.pageObj.quoteSummaryWrapper.datRequestedDate
    );
    const progressIndicatorStatus = this.pageObj.quoteSummaryWrapper.strProgressIndicatorStatus;
    const summaryStatus = this.pageObj.quoteSummaryWrapper.strSummaryStatus;
    const isUnderReview = summaryStatus === UNDER_REVIEW_STATUS;
    const isActionPending = summaryStatus === ACTION_PENDING_STATUS;
    const isInactive = summaryStatus === STATUS_INACTIVE;
    const isAccepted = summaryStatus === STATUS_ACCEPTED;
    const isAcceptedByManager = summaryStatus === STATUS_ACCEPTED_BY_MANAGER;
    if (progressIndicatorStatus === STATUS_SUBMITTED) {
      this.isQuoteSubmittedScreen = true;
      if (this.isSuperBuyerOrContractManager) {
        this.isCadenceSuggestionAllowed = true;
        this.cadenceHyperLinkText = pmc_cadenceSuggestion_suggestCadenceDelivery;
      }
    } else if (
      progressIndicatorStatus === STATUS_IN_PROGRESS &&
      (isUnderReview || isActionPending)
    ) {
      if (this.isSuperBuyerOrContractManager) {
        this.isCadenceSuggestionAllowed = true;
        this.cadenceHyperLinkText = pmc_cadenceSuggestion_suggestCadenceDelivery;
      }
      this.expirationDate = Date.parse(
        this.pageObj.quoteSummaryWrapper.datTExpiresIn
      );
      this.currentDateTime = Date.parse(
        this.pageObj.quoteSummaryWrapper.datTCurrentDateTime
      );
      this.isQuoteSubmittedScreen = false;
      this.updateShippingInfo();
      this.isInProgressScreen = true;
      this.showCancelQuoteBtn = isUnderReview;
      this.actionPendingStatusBtns = isActionPending;
      if (isUnderReview) {
        this.remainingTime =
          this.labels.pmc_quoteDetailsFlow_statusNotApplicable;
      } else if (isActionPending) {
        this.updateCounter(this.expirationDate, this.currentDateTime);
        this.pageObj.quoteSummaryWrapper.strDataSummaryStatus = "warning";
      }
    } else if (progressIndicatorStatus === STATUS_REJECTED) {
      this.showProgressBarTracker = false;
      this.isQuoteSubmittedScreen = false;
      this.updateShippingInfo();
      this.isInProgressScreen = true;
      this.showCancelQuoteBtn = isUnderReview;
      this.actionPendingStatusBtns = isInactive;
      if (isInactive) {
        // this.reasonForLabel =
        //   this.pageObj.quoteSummaryWrapper.strSummaryReason === STATUS_CANCELLED
        //     ? pmc_quoteDetailsFlow_reasonForCancellation
        //     : pmc_quoteDetailsFlow_reasonForRejection;
        
        switch(this.pageObj.quoteSummaryWrapper.strSummaryReason) {
          case STATUS_CANCELLED:
            this.reasonForLabel = pmc_quoteDetailsFlow_reasonForCancellation;
            this.showMessageBanner = false;
            break;
          case STATUS_EXPIRED:
            this.reasonForLabel = pmc_quoteDetailsFlow_reasonForRejection;
            this.showMessageBanner = true;
            break;
          default:
            this.reasonForLabel = pmc_quoteDetailsFlow_reasonForRejection;
            this.showMessageBanner = false;
        }

        this.statusInactiveScreen();
      }
    } else if (progressIndicatorStatus === STATUS_ACCEPTED) {
      this.isQuoteSubmittedScreen = false;
      if (this.isSuperBuyerOrContractManager) {
        this.isCadenceSuggestionAllowed = true;
        if (this.pageObj.quoteSummaryWrapper.boolDocumentAvailable) {
          this.cadenceHyperLinkText = pmc_cadenceSuggestion_viewCadenceDelivery;
          this.isCadenceReadOnly = true;
        }
        else {
          this.cadenceHyperLinkText = pmc_cadenceSuggestion_suggestCadenceDelivery;
        }
      }
      this.updateShippingInfo();
      this.isInProgressScreen = true;
      this.showCancelQuoteBtn = isUnderReview;
      this.actionPendingStatusBtns = isAccepted;
      if (isAccepted) {
        this.showAcceptedScreen();
      } else if (isAcceptedByManager) {
        this.actionPendingStatusBtns = isAcceptedByManager;
        this.showAcceptedByAccountManagerScreen();
      }
    }
  };

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    if (this.pageLoaded) {
      let baseUrl = window.location.origin;
      if (this.pageObj.quoteSummaryWrapper.updatedStatus === this.labels.pmc_quoteDetailsFlow_statusActionPending) {
        this.template.querySelector('.quote-summary-scrollable-container').classList.add('status-action-pending')
      }
      if (this.pageObj?.productInfoWrapper?.lstCartWrapper) {
        this.pageObj.productInfoWrapper.lstCartWrapper.forEach((el, productIndex) => {
          let url = `${baseUrl}${basePath}/product/${el.strProductId}`;
          el.pdpUrl = url;
          this.getTotalQuantity(productIndex);
          el.lstCartItems.forEach((e, shipmentIndex) => {
            if (e.strPackageType === "-") {
              this.template.querySelector(`table div.strPackageTypeCol[data-product-index="${productIndex}"][data-shipment-index="${shipmentIndex}"]`)?.classList.add('text-align-center');
            }
          });
        });
      }
      if (this.pageObj?.requestedContractInfoWrapper?.datStartDate) {
        let date = new Date(
          this.pageObj.requestedContractInfoWrapper.datStartDate
        );
        this.minEndDate = new Date(date.setDate(date.getDate() + 29))
          .toISOString()
          .slice(0, 10);
      }
      if (this.pageObj?.lstContracts) {
        this.pageObj.lstContracts.forEach((contract) => {
          contract.contractDetailsUrl = `${baseUrl}${basePath}${contract.strContractUrl}`;
          switch (contract.strContractStatus) {
            case this.labels.pmc_orderDetails_inactive:
              contract.dataStatus = BADGE_STATUS_ERROR;
              break;

            case this.labels.pmc_quoteDetailsFlow_statusActionPending:
              contract.dataStatus = BADGE_STATUS_WARNING;
              break;

            default:
              break;
          }
        });
      }
      if (this.pageObj?.requestedContractInfoWrapper?.datStartDate) {
        this.setMinAndMaxDate(
          this.pageObj.requestedContractInfoWrapper.datStartDate
        );
      }
      if (
        this.pageObj?.requestedContractInfoWrapper?.datStartDate ||
        this.pageObj?.requestedContractInfoWrapper?.datEndDate
      ) {
        this.isEndDateDisabled = !this.isEndDateDisabled;
      }
      this.pageRendered = true;
    }
  }

  get isEndDateDisabl() {
    return this.isEditDisabled.contractInfo || this.isEndDateDisabled;
  }

  /**
   * Returns true/false if edit is enabled for all the sections except the currently edited item
   * @function isEditEnabledForOthers
   * @param {string} btnId 
   * @param {string} prodctIndx
   * @param {string} shipmentIndx 
   * @returns {boolean}
   */
  isEditEnabledForOthers(btnId, prodctIndx, shipmentIndx) {
    let isEnabled = false;
    this.pageObj.productInfoWrapper.lstCartWrapper.forEach((cartItem, ind) => {
      if ((!prodctIndx && !cartItem.isEditDisabled) || (prodctIndx && ind !== parseInt(prodctIndx, 10) && !cartItem.isEditDisabled)) {
        isEnabled = true;
      }
      cartItem.lstCartItems.forEach((e, indx) => {
        if ((!shipmentIndx && !e.isEditDisabled) || (shipmentIndx && !e.isEditDisabled && !(ind === parseInt(prodctIndx, 10) && indx === parseInt(shipmentIndx, 10)))) {
          isEnabled = true;
        }
      });
    });
    Object.keys(this.isEditDisabled).forEach(el => {
      if (btnId !== el && !this.isEditDisabled[el]) isEnabled = true;
    })
    return isEnabled;
  }

  /**
   * Edit icon handler
   * @function handleEditInfo
   * @param {Event} event 
   */
  handleEditInfo(event) {
    if (event.target.dataset.btnId === "productInfo") {
      let index1 = event.target.dataset.productIndex;
      let index2 = event.target.dataset.shipmentIndex;
      if (!index2) {
        this.pageObj.productInfoWrapper.lstCartWrapper[index1].isEditDisabled =
          !this.pageObj.productInfoWrapper.lstCartWrapper[index1]
            .isEditDisabled;
      } else {
        let quoteLineItem =
          this.pageObj.productInfoWrapper.lstCartWrapper[index1].lstCartItems[
          index2
          ];
        quoteLineItem.isEditDisabled = !quoteLineItem.isEditDisabled;
        if (quoteLineItem.strSkuPackType) {
          quoteLineItem.isPackTypeDisabled = true;
        } else {
          quoteLineItem.isPackTypeDisabled = false;
        }
      }
      if (!this.isEditEnabledForOthers(event.target.dataset.btnId, index1, index2))
        this.tempObj = JSON.parse(JSON.stringify(this.pageObj));
    } else {
      this.isEditDisabled[event.target.dataset.btnId] =
        !this.isEditDisabled[event.target.dataset.btnId];
      if (!this.isEditEnabledForOthers(event.target.dataset.btnId))
        this.tempObj = JSON.parse(JSON.stringify(this.pageObj));
    }
  }

  /**
   * Reset the values of editable fields to old ones
   * @function setDefaultValues
   * @param {string} btnId 
   * @param {string} prodIndx 
   * @param {string} shipmntLineIndx 
   */
  setDefaultValues(btnId, prodIndx, shipmntLineIndx) {
    if (btnId === 'productInfo') {
      if (!shipmntLineIndx) {
        this.pageObj.productInfoWrapper.lstCartWrapper[prodIndx].strProductUOM = this.tempObj.productInfoWrapper.lstCartWrapper[prodIndx].strProductUOM;
      }
      else {
        let quoteLineItem =
          this.pageObj.productInfoWrapper.lstCartWrapper[prodIndx].lstCartItems[
          shipmntLineIndx
          ];
        let tempLineItem = this.tempObj.productInfoWrapper.lstCartWrapper[prodIndx].lstCartItems[
          shipmntLineIndx
        ];
        let editableFields = ["strQuantity", "strShipTo", "strIncoterms", "strDeliveryMode", "strShipFrom"];
        editableFields.forEach(field => {
          quoteLineItem[field] = tempLineItem[field];
        })
        if (this.isLocationBrazil) {
          quoteLineItem.strPackType = tempLineItem.strPackType;
        }
      }
    }
    else {
      this.updateQuoteItems(btnId, this.pageObj, this.tempObj);
    }
  }

  /**
   * Reset the values of editable fields
   * @function updateQuoteItems
   * @param {string} btnId 
   * @param {Object} parentObj 
   * @param {Object} childObj 
   */
  updateQuoteItems(btnId, parentObj, childObj) {
    switch (btnId) {
      case 'quoteSummary': parentObj.quoteSummaryWrapper.strQuoteId = childObj.quoteSummaryWrapper.strQuoteId;
        break;
      case 'paymentInfo': parentObj.paymentInformationWrapper.strPaymentTermSelected = childObj.paymentInformationWrapper.strPaymentTermSelected;
        parentObj.paymentInformationWrapper.strCurrencySelected = childObj.paymentInformationWrapper.strCurrencySelected;
        parentObj.paymentInformationWrapper.datPrepaymentDate = childObj.paymentInformationWrapper.datPrepaymentDate;
        break;
      case 'contractInfo': parentObj.requestedContractInfoWrapper.datEndDate = childObj.requestedContractInfoWrapper.datEndDate;
        parentObj.requestedContractInfoWrapper.datStartDate = childObj.requestedContractInfoWrapper.datStartDate;
        break;
      default: parentObj = JSON.parse(JSON.stringify(childObj));
    }
  }

  /**
   * Close icon handler
   * @function handleCloseEdit
   * @param {Event} event 
   */
  handleCloseEdit(event) {
    this.setDefaultValues(event.target.dataset.btnId, event.target.dataset.productIndex, event.target.dataset.shipmentIndex);
    if (event.target.dataset.btnId === "productInfo") {
      let index1 = event.target.dataset.productIndex;
      let index2 = event.target.dataset.shipmentIndex;
      if (!index2) {
        this.pageObj.productInfoWrapper.lstCartWrapper[index1].isEditDisabled = this.tempObj.productInfoWrapper.lstCartWrapper[index1].isEditDisabled = true;
      } else {
        let quoteLineItem =
          this.pageObj.productInfoWrapper.lstCartWrapper[index1].lstCartItems[
          index2
          ];
        let tempLineItem = this.tempObj.productInfoWrapper.lstCartWrapper[index1].lstCartItems[
          index2
        ];
        quoteLineItem.isEditDisabled = tempLineItem.isEditDisabled = true;
        quoteLineItem.isPackTypeDisabled = tempLineItem.isPackTypeDisabled = true;
      }
    } else {
      this.isEditDisabled[event.target.dataset.btnId] =
        !this.isEditDisabled[event.target.dataset.btnId];
    }
    if ((this.pageObj.paymentInformationWrapper?.strPaymentTermSelected === "Fixed Date" || this.pageObj.paymentInformationWrapper?.strPaymentTermSelected === "Prepayment") && this.isPrepaymentAllowed) {
      this.isPrepaymentDateField = true;
    }
    else {
      delete this.pageObj.paymentInformationWrapper.datPrepaymentDate;
      this.isPrepaymentDateField = false;
    }
    setTimeout(() => {
      this.validateInputFields(event);
    });
  }

  /**
   * Save details icon handler
   * @function handleSaveEditInfo
   * @param {Event} event
   */
  handleSaveEditInfo(event) {
    if (!((this.pageObj.paymentInformationWrapper?.strPaymentTermSelected === "Fixed Date" || this.pageObj.paymentInformationWrapper?.strPaymentTermSelected === "Prepayment") && this.isPrepaymentAllowed)) {
      delete this.pageObj.paymentInformationWrapper.datPrepaymentDate;
    }
    if (
      (event.target.dataset.btnId === "productInfo" &&
        event.target.dataset.parentId === "productInfo-card" &&
        (this.checkDuplicateRows(
          event.target.dataset.productIndex,
          event.target.dataset.shipmentIndex
        ) ||
          this.validateQtyField(event) ||
          this.handleErrorOnSave(event))) ||
      this.handleProdError(event)
    )
      return;
    if (event.target.dataset.btnId === "productInfo") {
      let index1 = event.target.dataset.productIndex;
      let index2 = event.target.dataset.shipmentIndex;
      if (!index2) {
        this.pageObj.productInfoWrapper.lstCartWrapper[index1].isEditDisabled =
          !this.pageObj.productInfoWrapper.lstCartWrapper[index1]
            .isEditDisabled;
        this.updateSkuUOMOnSave(index1);
      } else {
        let quoteLineItem =
          this.pageObj.productInfoWrapper.lstCartWrapper[index1].lstCartItems[
          index2
          ];
        quoteLineItem.isEditDisabled = !quoteLineItem.isEditDisabled;
        quoteLineItem.isPackTypeDisabled = true;
        this.updateQuoteLineItemOnSave(index1, index2);
      }
    } else {
      this.isEditDisabled[event.target.dataset.btnId] =
        !this.isEditDisabled[event.target.dataset.btnId];
      this.updateQuoteOnSave(event.target.dataset.btnId);
    }
  }

  /**
   * Checks if contract period is changed
   * @function isContractYearMonthChanged
   * @param {string} btnId 
   */
  isContractYearMonthChanged(btnId) {
    let isValueModified = false;
    let startDate = new Date(this.pageObj.requestedContractInfoWrapper.datStartDate);
    let endDate = new Date(this.pageObj.requestedContractInfoWrapper.datEndDate);
    let tempstartDate = new Date(this.tempObj.requestedContractInfoWrapper.datStartDate);
    let tempEndDate = new Date(this.tempObj.requestedContractInfoWrapper.datEndDate);
    if (btnId === "contractInfo" &&
      ((startDate.getMonth() !== tempstartDate.getMonth() || startDate.getFullYear() !== tempstartDate.getFullYear()) || (endDate.getMonth() !== tempEndDate.getMonth() || endDate.getFullYear() !== tempEndDate.getFullYear()))) {
      isValueModified = true;
    }
    return isValueModified;
  }

  /**
   * Return total quantity for the given product
   * @function getTotalQuantity
   * @param {number} productIndex 
   */
  getTotalQuantity(productIndex) {
    const quantities = this.pageObj.productInfoWrapper.lstCartWrapper[
      productIndex
    ].lstCartItems.map((ele) => (ele.strQuantity ? +ele.strQuantity : 0));
    const total = quantities.reduce((acc, curr) => acc + curr);
    this.pageObj.productInfoWrapper.lstCartWrapper[productIndex].strTotalQty =
      total;
  }

  /**
   * On input change event handler
   * @function handleDataChange
   * @param {Event} event
   */
  handleDataChange = (event) => {
    if (event.detail.value !== "undefined" && event.target && event.target.dataset) {
      if (event.target.dataset.parentId === "productInfoWrapper") {
        let quoteLineItem =
          this.pageObj.productInfoWrapper.lstCartWrapper[
            event.target.dataset.productIndex
          ].lstCartItems[event.target.dataset.shipmentIndex];
        quoteLineItem[event.target.dataset.id] = event.detail.value;
        if (event.target.dataset.id === "strIncoterms") {
          if (event.detail.value && event.detail.value === INCOTERM_CPT) {
            quoteLineItem.lstDeliveryModes = sortData(this.pageObj.productInfoWrapper.lstCartWrapper[event.target.dataset.productIndex].lstDeliveryModesCPT, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
          }
          else {
            quoteLineItem.lstDeliveryModes = sortData(this.pageObj.productInfoWrapper.lstCartWrapper[event.target.dataset.productIndex].lstDeliveryModes, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
          }
          quoteLineItem.strDeliveryMode = null;
        }
      }
      else if (event.target.dataset.parentId === "skuInfoWrapper") {
        this.pageObj.productInfoWrapper.lstCartWrapper[
          event.target.dataset.productIndex
        ][event.target.dataset.id] = event.detail.value;
      }
      else if (event.target.dataset.id === "datStartDate") {
        this.pageObj[event.target.dataset.parentId][event.target.dataset.id] =
          event.detail.value;
        this.isEndDateDisabled = false;
        this.template
          .querySelector(`.inputDate[data-id="datEndDate"]`)
          .resetInput();
        this.pageObj.requestedContractInfoWrapper.datEndDate = "";
        if (event.detail.value) {
          this.setMinAndMaxDate(event.detail.value);
          if (this.pageObj.paymentInformationWrapper?.strPaymentTermSelected === "Prepayment") {
            this.setMinAndMaxPrepaymentDate()
          }
        }
        else {
          this.minEndDate = this.today;
        }
      }
      else if (event.target.dataset.id === "strPaymentTermSelected") {
        this.pageObj[event.target.dataset.parentId][event.target.dataset.id] =
          event.detail.value;
        if (this.isPrepaymentAllowed) {
          if (event.detail.value === "Fixed Date" || event.detail.value === "Prepayment") {
            this.isPrepaymentDateField = true;
            this.paymentDateErrorMsg = event.detail.value === "Prepayment" ? pmc_quoteCheckoutFlow_paymentDateErrorMsg1 : pmc_quoteCheckoutFlow_paymentDateErrorMsg2;
            this.setMinAndMaxPrepaymentDate();
          }
          else {
            this.isPrepaymentDateField = false;
          }
        }
      }
      else if (event.target.dataset.id === "datPrepaymentDate") {
        this.pageObj[event.target.dataset.parentId][event.target.dataset.id] = event.detail.value;
        let dayValue = getRawDateUtil(event.detail.value).getDay();
        if (dayValue === 6 || dayValue === 0) {
          event.target.setCustomValidity(this.paymentDateErrorMsg)
        }
        else {
          event.target.removeReportErrorValidity();
        }
      }
      else if (event.target.dataset.id === "cancelQuoteModal" || event.target.dataset.id === "rejectQuoteModal") {
        if (event.detail.value !== "undefined" && event.detail.name) {
          this.quoteCaseObject[event.detail.name] = event.detail.value;
          this.quoteCaseObject.boolOthersValidity = event.detail.validity;
          this.isCancelRejectFormInvalid();
        }
      }
      else {
        this.pageObj[event.target.dataset.parentId][event.target.dataset.id] =
          event.detail.value;
      }
    }
  };

  /**
   * Validates if quantity field is non-zero or not
   * @function validateQtyField
   * @param {Event} event
   * @returns {boolean}
   */
  validateQtyField(event) {
    let isInvalid = false;
    if (
      parseInt(
        this.pageObj.productInfoWrapper.lstCartWrapper[
          event.target.dataset.productIndex
        ].lstCartItems[event.target.dataset.shipmentIndex].strQuantity,
        10
      ) === 0
    ) {
      isInvalid = true;
    }
    return isInvalid;
  }

  /**
   * Sets min and max date on the basis of contract start date selected
   * @function setMinAndMaxDate
   * @param {string} startdate
   */
  setMinAndMaxDate(dateVal) {
    let startDate = getRawDateUtil(dateVal);
    let maxEndDate = new Date(startDate);
    let minEndDate = new Date(startDate);
    minEndDate.setDate(minEndDate.getDate() + 30);
    this.minEndDate = minEndDate.toISOString().slice(0, 10);
    maxEndDate.setDate(startDate.getDate() + 547);
    this.maxEndDate = maxEndDate.toISOString().slice(0, 10);
  }

  /**
   * Sets min and max preypayment date
   * @function setMinAndMaxPrepaymentDate
   */
  setMinAndMaxPrepaymentDate() {
    this.maxPrepaymentDate = this.pageObj?.paymentInformationWrapper?.strPaymentTermSelected === "Prepayment" && this.pageObj?.requestedContractInfoWrapper?.datStartDate ? this.pageObj?.requestedContractInfoWrapper?.datStartDate : null;
  }

  /**
   * Disables cancel button for reject quote 
   * @function isCancelRejectFormInvalid
   */
  isCancelRejectFormInvalid = () => {
    this.disableQuoteBtn = false;
    if (
      !this.quoteCaseObject.strReason ||
      (this.quoteCaseObject.strReason === "Other" &&
        (!this.quoteCaseObject.strOthersComment || !this.quoteCaseObject.boolOthersValidity))
    ) {
      this.disableQuoteBtn = true;
    }
  };

  /**
   * Report Validity for Dropdown input required fields
   * @function validateInputFields
   * @param {Event} event 
   */
  validateInputFields(event) {
    let validateSection = event.target.dataset.parentId === 'product-grid'
      ? this.template.querySelector(
        `.${event.target.dataset.parentId}[data-product-index='${event.target.dataset.productIndex}']`
      )
      : this.template.querySelector(`.${event.target.dataset.parentId}`);
    validateSection.querySelectorAll(`[data-id]`).forEach((inputComponent) => {
      inputComponent.reportValidity();
    });
  }

  /**
   * Checking validity of Product UOM, Payment terms, Quote ID, Contract Start and End date
   * @function handleProdError
   * @param {Event} event 
   */
  handleProdError(event) {
    let allValid = true;
    let validateSection = event.target.dataset.parentId === 'product-grid'
      ? this.template.querySelector(
        `.${event.target.dataset.parentId}[data-product-index='${event.target.dataset.productIndex}']`
      )
      : this.template.querySelector(`.${event.target.dataset.parentId}`);
    validateSection.querySelectorAll(`[data-id]`).forEach((inputComponent) => {
      if (!inputComponent.reportValidity()) {
        allValid = false;
      }
    });
    if (!allValid) {
      return true;
    }
    return false;
  }

  /**
   * checking validity of all required fields
   * @function handleErrorOnSave
   * @param {Event} event 
   */
  handleErrorOnSave(event) {
    let allValid = true;
    this.template.querySelector(`.${event.target.dataset.parentId}`//[data-product-index='${event.target.dataset.productIndex}']
    )
      .querySelectorAll(
        `[data-id][data-product-index='${event.target.dataset.productIndex}'][data-shipment-index='${event.target.dataset.shipmentIndex}']`
      )
      .forEach((inputComponent) => {
        if (!inputComponent.reportValidity()) {
          allValid = false;
        }
      });
    if (!allValid) {
      return true;
    }
    return false;
  }

  /**
   * Method to save Products Information data
   * @function updateQuoteLineItemOnSave
   * @param {number} productIndx
   * @param {number} lineItemIndx
   */
  updateQuoteLineItemOnSave = (productIndx, lineItemIndx) => {
    const cartItem =
      this.pageObj.productInfoWrapper.lstCartWrapper[productIndx].lstCartItems[
      lineItemIndx
      ];
    const tempLineItem = this.tempObj.productInfoWrapper.lstCartWrapper[productIndx].lstCartItems[
      lineItemIndx
    ];
    this.pageObj.productInfoWrapper.lstCartWrapper[productIndx].isEditSkuUOMDisabled = true;
    const editableFields = ["strQuantity", "strShipTo", "strIncoterms", "strDeliveryMode", "strShipFrom"];
    const requestObj = {
      strQuoteLineItemId: cartItem.strCartItemId,
      strQuoteLineItemQuantity: cartItem.strQuantity,
      strShipTo: cartItem.strShipTo,
      strIncoterms: cartItem.strIncoterms,
      strDeliveryMode: cartItem.strDeliveryMode,
      strShipFrom: cartItem.strShipFrom
    };
    if (this.isLocationBrazil) {
      requestObj.strPackType = cartItem.strPackType;
    }
    this.isSpinner = true;
    updateQuoteLineItem({
      quoteLineItemUpdateWrap: requestObj
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
          }
          if (response?.strStatusCode === "000") {
            editableFields.forEach(field => {
              tempLineItem[field] = cartItem[field];
            })
            if (this.isLocationBrazil) {
              tempLineItem.strPackType = cartItem.strPackType;
            }
            this.getConversationHistoryDetails();
          }
        }
        this.isSpinner = false;
        this.pageObj.productInfoWrapper.lstCartWrapper[productIndx].isEditSkuUOMDisabled = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
        this.pageObj.productInfoWrapper.lstCartWrapper[productIndx].isEditSkuUOMDisabled = false;
      });
  };

  /**
   * Method to save Product Unit of Measure(UOM) data
   * @function updateSkuUOMOnSave
   * @param {string} productIndx 
   */
  updateSkuUOMOnSave = (productIndx) => {
    const cartItem = this.pageObj.productInfoWrapper.lstCartWrapper[productIndx];
    const tempCartItem = this.tempObj.productInfoWrapper.lstCartWrapper[productIndx];
    let lstLineItemsIds = [];
    this.pageObj.productInfoWrapper.lstCartWrapper[productIndx].lstCartItems.forEach((line) => {
      lstLineItemsIds.push(line.strCartItemId)
    });
    this.isSpinner = true;
    updateQuoteLineProdInfo({
      strUOM: this.pageObj.productInfoWrapper.lstCartWrapper[productIndx].strProductUOM,
      lstLineItemsIds: lstLineItemsIds
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
          }
          if ((response?.strStatusCode === "000")) {
            tempCartItem.strProductUOM = cartItem.strProductUOM;
            tempCartItem.lstCartItems.forEach((line) => {
              line.strProductUOM = cartItem.strProductUOM;
            });
            this.getConversationHistoryDetails();
          }
        }
        this.isSpinner = false;
        this.pageObj.productInfoWrapper.lstCartWrapper[
          productIndx
        ].lstCartItems.forEach((line) => {
          line.isEditQuoteLineItemDisabled = false;
        });
      })
      .catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
        this.pageObj.productInfoWrapper.lstCartWrapper[
          productIndx
        ].lstCartItems.forEach((line) => {
          line.isEditQuoteLineItemDisabled = false;
        });
      });
  };

  /**
   * Method to save Quote Summary, Payment Information and Contract Information data
   * @function updateQuoteOnSave
   * @param {string} btnId
   */
  updateQuoteOnSave = (btnId) => {
    const contractYearMonthModified = this.isContractYearMonthChanged(btnId);
    const requestObj = {
      strFriendlyName: btnId === 'quoteSummary' ? this.pageObj.quoteSummaryWrapper.strQuoteId : this.tempObj.quoteSummaryWrapper.strQuoteId,
      strCurrencyIsoCode: btnId === 'paymentInfo' ?
        this.pageObj.paymentInformationWrapper.strCurrencySelected : this.tempObj.paymentInformationWrapper.strCurrencySelected,
      datContractStartDate:
        btnId === 'contractInfo' ? this.pageObj.requestedContractInfoWrapper.datStartDate : this.tempObj.requestedContractInfoWrapper.datStartDate,
      datContractEndDate: btnId === 'contractInfo' ? this.pageObj.requestedContractInfoWrapper.datEndDate : this.tempObj.requestedContractInfoWrapper.datEndDate,
      datPrepaymentDate: btnId === 'paymentInfo' ? this.pageObj.paymentInformationWrapper.datPrepaymentDate : this.tempObj.paymentInformationWrapper.datPrepaymentDate,
      strPaymentTerms:
        btnId === 'paymentInfo' ? this.pageObj.paymentInformationWrapper.strPaymentTermSelected : this.tempObj.paymentInformationWrapper.strPaymentTermSelected,
      strQuoteId: this.quoteId
    };
    updateQuote({
      quoteUpdateWrap: requestObj
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
          }
          if (response?.strStatusCode === "000") {
            this.updateQuoteItems(btnId, this.tempObj, this.pageObj);
            this.getConversationHistoryDetails();
          }
          if (btnId === 'contractInfo') {
            this.createCadence(contractYearMonthModified);
          }
        }
      })
      .catch(() => {
        toastMessageHandler();
      });
  };

  /**
   * Method to get Active Cart Id
   * @function fetchActiveCartId
   */
  fetchActiveCartId() {
    this.isSpinner = true;
    getActiveCartId({
      strEffectiveAccountId: this.effectiveAccountId,
      strCommunityId: communityId
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          this.activeCartId = result.strCartId;
          this.addshipmentInfo(this.activeCartId);
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  }

  /**
   * Validates cart for error
   * @function validateCart
   * @param {string} cartId 
   */
  validateCart(cartId) {
    let targetUrl = "";
    validateCart({
      strCartId: cartId
    })
      .then((data) => {
        if (data && Object.keys(data).length) {
          if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
          }
          if (data.boolHasErrors || data.boolHasWarnings) {
            targetUrl = "/cart";
            sessionStorage.setItem("CART_VALIDATION_ERROR", true);
          } else {
            targetUrl = "/checkout";
            sessionStorage.setItem("CART_ID", cartId);
            sessionStorage.setItem("CHECKOUT_FLAG", SOURCE_RFQ);
          }
          this[NavigationMixin.GenerateUrl]({
            type: "standard__webPage",
            attributes: {
              url: `${basePath}${targetUrl}`
            }
          }).then((generatedUrl) => {
            urlRedirect(generatedUrl);
          });
        }
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  }

  /**
   * Method to add Products to Active Cart
   * @function addshipmentInfo
   * @param {string} cartId 
   */
  addshipmentInfo(cartId) {
    addCartItems({
      strCartId: cartId,
      strInputJSON: JSON.stringify(this.cartItemObj)
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
          }
          if (response?.strStatusCode === "002") {
            this.validateCart(cartId);
          }
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
      });
  }

  /**
   * Opens cadence suggestion modal
   * @function openCadenceSuggestionModal
   */
  openCadenceSuggestionModal() {
    this.isCadenceSuggestionModal = true;
  }

  /**
   * Closes cadence suggestion modal
   * @function handleCloseCadenceSuggestionModal
   */
  handleCloseCadenceSuggestionModal() {
    this.isCadenceSuggestionModal = false;
  }

  /**
   * Method to redirect to ShipmentInfoPage on Requote Products button click
   * @function requoteProductHandler
   */
  requoteProductHandler() {
    this.fetchActiveCartId();
  }

  /**
   * Requote Modal open handler
   * @function openRequoteModalHandler
   */
  openRequoteModalHandler() {
    this.isRequoteModal = true;
  }

  /**
   * Requote Modal close handler
   * @function closeRequoteHandler
   */
  closeRequoteHandler() {
    this.isRequoteModal = false;
  }

  /**
   * If product image doesn't load, display default image
   * @function handleImageError
   * @param {Event} event 
   */
  handleImageError(event) {
    event.currentTarget.src = this.iconUrlObj.mosaicLogoUrl;
    event.currentTarget.style.height = "unset";
    event.currentTarget.onerror = null;
  }

  /**
   * Update ShipTo and ShipFrom values
   * @function updateShippingInfo
   */
  updateShippingInfo = () => {
    if (this.pageObj?.productInfoWrapper?.lstCartWrapper) {
      this.pageObj.productInfoWrapper.lstCartWrapper?.forEach((prod) => {
        prod.lstCartItems?.forEach((item) => {
          let shipTo = prod.lstShipTo?.find(
            (data) => item.strShipTo === data.value
          );
          item.strShipTo = shipTo ? shipTo.label : "";
          let shipFrom = prod.lstShipFrom?.find(
            (data) => item.strShipFrom === data.value
          );
          item.strShipFrom = shipFrom ? shipFrom.label : "";
          let packType = prod.lstPackType.find(
            (data) => item.strPackType === data.value
          );
          item.strPackType = packType ? packType.label : "";
          if (prod.lstPackagingType) {
            let packageType = prod.lstPackagingType.find(
              (data) => item.strPackageType === data.value
            );
            item.strPackageType = packageType ? packageType.label : "";
          }
          let deliveryMode = prod.lstDeliveryModes?.find(
            (data) => item.strDeliveryMode === data.value
          );
          if (deliveryMode) {
            item.strDeliveryMode = deliveryMode.label;
          }
          else {
            deliveryMode = prod.lstDeliveryModesCPT?.find(
              (data) => item.strDeliveryMode === data.value
            );
            item.strDeliveryMode = deliveryMode ? deliveryMode.label : "";
          }
        });
      });
    }
  };

  /** 
   * CANCEL QUOTE MODAL : To Open Cancel Quote Modal  
   * @function openCancelQuoteModalHandler
   */
  openCancelQuoteModalHandler = () => {
    this.isCancelQuoteModal = true;
  };

  /** 
   * CANCEL QUOTE MODAL : To Close Cancel Quote Modal From X icon 
   * @function closeCancelQuoteHandler
   */
  closeCancelQuoteHandler = () => {
    this.clearForm();
    this.isCancelQuoteModal = false;
  };

  /**
   * CANCEL QUOTE MODAL : When User Clicks on Cancel & Requote Button 
   * @function cancelAndRequoteHandler
   */
  cancelAndRequoteHandler = () => {
    this.isCancelQuoteModal = false;
    this.sendQuoteStatusAndRedirect(STATUS_CANCELLED);
  };

  /** 
   * CANCEL QUOTE MODAL : When User Clicks on Cancel Quote Button 
   * @function cancelQuoteHandler
   */
  cancelQuoteHandler = () => {
    this.isCancelQuoteModal = false;
    this.sendQuoteStatusAndReload(STATUS_CANCELLED);
  };

  /**
   * REJECT QUOTE MODAL : To Open Reject Quote Modal 
   * @function openRejectQuoteModalHandler
   */
  openRejectQuoteModalHandler = () => {
    this.isRejectQuoteModal = true;
  };

  /** 
   * REJECT QUOTE MODAL : To Close Reject Quote Modal From X icon 
   * @function closeRejectQuoteHandler
   */
  closeRejectQuoteHandler = () => {
    this.clearForm();
    this.isRejectQuoteModal = false;
  };

  /** 
   * REJECT QUOTE MODAL : When User Clicks on Reject & Requote Button
   * @function rejectAndRequoteHandler
   */
  rejectAndRequoteHandler = () => {
    this.isRejectQuoteModal = false;
    this.sendQuoteStatusAndRedirect(STATUS_REJECTED);
  };

  /** 
   * REJECT QUOTE MODAL : When User Clicks on Reject Quote Button 
   * @function rejectQuoteHandler
   */
  rejectQuoteHandler = () => {
    this.isRejectQuoteModal = false;
    this.sendQuoteStatusAndReload(STATUS_REJECTED);
  };

  /**
   * Reset all the input fields of the create case form
   * @function clearForm
   */
  clearForm = () => {
    this.quoteCaseObject = {};
    this.template.querySelectorAll("c-pmc_dh_feedback-form").forEach((el) => {
      el.resetInputs();
    });
    this.disableQuoteBtn = true;
  };

  /** 
   * BE Method to Update User Selected Data from Quote Modal and Refresh Page 
   * @function sendQuoteStatusAndReload
   * @param {string} status 
   */
  sendQuoteStatusAndReload = (status) => {
    this.isSpinner = true;
    const requestObj = {
      strQuoteId: this.quoteId,
      strSelectedReason: this.quoteCaseObject.strReason,
      strStatus: status,
      strReason: this.quoteCaseObject.strOthersComment
    };
    updateQuoteStatus({
      modelWrapper: requestObj
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).strStatusCode === "111") {
            this.errorMessage = handleError(JSON.parse(
              JSON.stringify(result)
            ).strStatusMessage);
            setTimeout(() => {
              window.location.reload();
            }, this.errorCaseTimer);
          } else if (JSON.parse(JSON.stringify(result)).strStatusCode === "100") {
            this.errorMessage = handleError(
              JSON.parse(JSON.stringify(result)).strStatusMessage
            );
          } else {
            window.location.reload();
          }
        }
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  };

  /** 
   * BE Method to Update User Selected Data from Quote Modal and Redirect to Shipment Information page 
   * @function sendQuoteStatusAndRedirect
   * @param {string} status 
   */
  sendQuoteStatusAndRedirect = (status) => {
    this.isSpinner = true;
    const requestObj = {
      strQuoteId: this.quoteId,
      strSelectedReason: this.quoteCaseObject.strReason,
      strStatus: status,
      strReason: this.quoteCaseObject.strOthersComment
    };
    updateQuoteStatus({
      modelWrapper: requestObj
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).strStatusCode === "111") {
            this.errorMessage = JSON.parse(
              JSON.stringify(result)
            ).strStatusMessage;
            setTimeout(() => {
              window.location.reload();
            }, this.errorCaseTimer);
          } else if (JSON.parse(JSON.stringify(result)).strStatusCode === "100") {
            this.errorMessage = handleError(
              JSON.parse(JSON.stringify(result)).strStatusMessage
            );
          } else {
            this.requoteProductHandler();
          }
        }
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  };

  /** 
   * Show only Requote Btn and Error Status 
   * @function statusInactiveScreen
   */
  statusInactiveScreen = () => {
    this.pageObj.quoteSummaryWrapper.strDataSummaryStatus = "error";
    this.showRequoteOnlyBtn = true;
    this.showExpiresInField = false;
    let baseUrl = window.location.origin;
    let loginUrl = `${baseUrl}${basePath}/my-accounts`;
    this.messageBannerType = MESSAGE_TYPE_WARNING;
    this.messageForBanner = formatLabel(
      this.labels.pmc_quoteDetailsFlow_messageBannerInactive,
      [loginUrl]
    );
  };

  /** 
   * Show only Requote Btn and Success Status 
   * @function showAcceptedScreen
   */
  showAcceptedScreen = () => {
    this.showRequoteOnlyBtn = true;
    this.showExpiresInField = true;
    this.isQuoteApproved = true;
    this.remainingTime = this.labels.pmc_quoteDetailsFlow_statusNotApplicable;
  };

  /** 
   * Show only Requote Btn and Success Status, and Message Banner for Accepted by Account Manager 
   * @function showAcceptedByAccountManagerScreen
   */
  showAcceptedByAccountManagerScreen = () => {
    this.showRequoteOnlyBtn = true;
    this.showExpiresInField = true;
    this.isQuoteApproved = true;
    this.remainingTime = this.labels.pmc_quoteDetailsFlow_statusNotApplicable;
    let baseUrl = window.location.origin;
    let loginUrl = `${baseUrl}${basePath}/my-accounts`;
    this.showMessageBanner = true;
    this.messageForBanner = formatLabel(
      this.labels.pmc_quoteDetailsFlow_messageBannerAcceptedByManager,
      [loginUrl]
    );
    this.messageBannerType = MESSAGE_TYPE_INFO;
  };

  /** 
   * ACCEPT QUOTE : When User Clicks on Accept Quote Button 
   * @function openAcceptQuoteModalHandler
   */
  openAcceptQuoteModalHandler = () => {
    this.isAcceptQuoteModal = true;
  };

  /**
   * Closes accept quote modal
   * @function closeHandler
   */
  closeHandler() {
    this.isAcceptQuoteModal = false;
  }

  /**
   * Handles accept quote
   * @function acceptQuoteHandler
   */
  acceptQuoteHandler() {
    this.isAcceptQuoteModal = false;
    this.sendQuoteStatusAndReload(STATUS_ACCEPTED);
  }

  /**
   * Check if duplicate shipment product lines are available for a row
   * @function checkDuplicateRows
   * @param {number} indexProduct
   * @param {number} shipmentIndx
   * @returns {boolean}
   */
  checkDuplicateRows = (indexProduct = null, shipmentIndx = null) => {
    let isInvalid = false;
    if (
      this.pageObj &&
      this.pageObj.productInfoWrapper &&
      this.pageObj.productInfoWrapper.lstCartWrapper
    ) {
      let prod = this.pageObj.productInfoWrapper.lstCartWrapper[indexProduct];
      let shipmentLineItem = prod.lstCartItems[shipmentIndx];
      if (
        !shipmentLineItem.strShipTo ||
        !shipmentLineItem.strDeliveryMode ||
        !shipmentLineItem.strIncoterms ||
        !shipmentLineItem.strShipFrom
      ) {
        return isInvalid;
      }
      const isDuplicate = prod.lstCartItems.some((el, i) => {
        return (
          +shipmentIndx !== +i &&
          shipmentLineItem.strDeliveryMode === el.strDeliveryMode &&
          shipmentLineItem.strIncoterms === el.strIncoterms &&
          shipmentLineItem.strShipFrom === el.strShipFrom &&
          shipmentLineItem.strShipTo === el.strShipTo
        );
      });
      prod.isDuplicate = isDuplicate;
      const fieldsToHighlight = [
        "strShipTo",
        "strIncoterms",
        "strDeliveryMode",
        "strShipFrom"
      ];
      fieldsToHighlight?.forEach((field) => {
        const element = this.template.querySelector(
          `[data-id="${field}"][data-product-index="${indexProduct}"][data-parent-id="productInfoWrapper"][data-shipment-index="${shipmentIndx}"]`
        );
        if (prod.isDuplicate) {
          element.reportErrorValidity();
          isInvalid = true;
        } else {
          element.removeReportErrorValidity();
        }
      });
    }
    return isInvalid;
  }

  /**
   * Creates cadence
   * @function createCadence
   * @param {boolean} contractYearMonthModified 
   */
  createCadence = (contractYearMonthModified) => {
    this.isSpinner = true;
    createCadence({
      strQuoteId: this.quoteId,
      boolIsContractPeriodChanged: contractYearMonthModified
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
          }
          if (response.strStatusCode === "000") {
            this.isSpinner = false
          }
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  }
}