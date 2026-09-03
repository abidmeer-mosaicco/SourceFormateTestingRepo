import { LightningElement, track, wire } from "lwc";
import basePath from "@salesforce/community/basePath";
import { formatDate, isBrazilRegion, urlRedirect, toastMessageHandler, formatLabel, getLineItemDataFromSessionStorage, upsertLineItemData, setWithExpirationFromSession } from "c/pmc_dh_utilityJs";
import { getNavigationMenu } from 'experience/navigationMenuApi';
import communityId from "@salesforce/community/Id";
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

import addCartItems from "@salesforce/apex/PMC_DH_ContractDetailController.addCartItem";
import addRequoteCartItems from "@salesforce/apex/PMC_DH_QuoteUtils.addCartItems";
import getActiveCartId from "@salesforce/apex/PMC_DH_QuoteUtils.getActiveCartId";
import validateCart from "@salesforce/apex/PMC_DH_CartValidationController.validateCart";
import getContractDetails from "@salesforce/apex/PMC_DH_ContractManagementController.getContractDetails";
import updatePoNumber from "@salesforce/apex/PMC_DH_ContractManagementController.updateContractPoNumber";
import contractRequestSignature from "@salesforce/apex/PMC_DH_ContractManagementController.contractRequestSignature";
import getContractDocInfo from "@salesforce/apex/PMC_DH_ContractDocumentController.getContractDocInfo";
import getContractDocData from "@salesforce/apex/PMC_DH_ContractDocumentController.getContractDocData";

import DisableAddtoOrder from "@salesforce/customPermission/DisableAddtoOrder";
import viewOnlyAccess from "@salesforce/customPermission/Quote_ViewOnlyAccess";
import DH_Edit_Address from '@salesforce/customPermission/DH_Edit_Address';
import DisableRequestContractSignature from "@salesforce/customPermission/DisableRequestContractSignature";
import { NavigationMixin } from "lightning/navigation";

import pmc_addresses_status from "@salesforce/label/c.pmc_addresses_status";
import pmc_quoteCheckoutFlow_paymentMethod from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentMethod";
import pmc_requestForQuote_productsInformation from "@salesforce/label/c.pmc_requestForQuote_productsInformation";
import pmc_requestForQuote_totalQty from "@salesforce/label/c.pmc_requestForQuote_totalQty";
import pmc_requestForQuote_qty from "@salesforce/label/c.pmc_requestForQuote_qty";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_quoteCheckoutFlow_incoterms from "@salesforce/label/c.pmc_quoteCheckoutFlow_incoterms";
import pmc_userDetails_edit from "@salesforce/label/c.pmc_userDetails_edit";
import pmc_quoteCheckoutFlow_paymentInfo from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentInfo";
import pmc_quoteCheckoutFlow_paymentTerms from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentTerms";
import pmc_quoteCheckoutFlow_deliveryMode from "@salesforce/label/c.pmc_quoteCheckoutFlow_deliveryMode";
import pmc_quoteCheckoutFlow_shipFrom from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipFrom";
import pmc_quoteCheckoutFlow_currency from "@salesforce/label/c.pmc_quoteCheckoutFlow_currency";
import pmc_quoteDetailsFlow_customerName from "@salesforce/label/c.pmc_quoteDetailsFlow_customerName";
import pmc_miniCartModal_closeLabel from "@salesforce/label/c.pmc_miniCartModal_closeLabel";
import pmc_quoteDetailsFlow_check from "@salesforce/label/c.pmc_quoteDetailsFlow_check";
import pmc_contractDetails_contract from "@salesforce/label/c.pmc_contractDetails_contract";
import pmc_contractDetails_contractSummary from "@salesforce/label/c.pmc_contractDetails_contractSummary";
import pmc_contractDetails_poNumber from "@salesforce/label/c.pmc_contractDetails_poNumber";
import pmc_contractDetails_contractType from "@salesforce/label/c.pmc_contractDetails_contractType";
import pmc_contractDetails_validityPeriod from "@salesforce/label/c.pmc_contractDetails_validityPeriod";
import pmc_contractDetails_reason from "@salesforce/label/c.pmc_contractDetails_reason";
import pmc_contractDetails_requote from "@salesforce/label/c.pmc_contractDetails_requote";
import pmc_contractDetails_totalAvailableQty from "@salesforce/label/c.pmc_contractDetails_totalAvailableQty";
import pmc_contractDetails_totalOrderedQty from "@salesforce/label/c.pmc_contractDetails_totalOrderedQty";
import pmc_contractDetails_availableQty from "@salesforce/label/c.pmc_contractDetails_availableQty";
import pmc_contractDetails_orderedQty from "@salesforce/label/c.pmc_contractDetails_orderedQty";
import pmc_contractDetails_price from "@salesforce/label/c.pmc_contractDetails_price";
import pmc_contractDetails_productName from "@salesforce/label/c.pmc_contractDetails_productName";
import pmc_contractDetails_quoteOfOrigin from "@salesforce/label/c.pmc_contractDetails_quoteOfOrigin";
import pmc_contractDetails_coupon from "@salesforce/label/c.pmc_contractDetails_coupon";
import pmc_contractDetails_itemNumber from "@salesforce/label/c.pmc_contractDetails_itemNumber";
import pmc_contractDetails_averagePricePerUnit from "@salesforce/label/c.pmc_contractDetails_averagePricePerUnit";
import pmc_contractDetails_requoteProducts from "@salesforce/label/c.pmc_contractDetails_requoteProducts";
import pmc_addressDetails_cancel from "@salesforce/label/c.pmc_addressDetails_cancel";
import pmc_contractDetails_generateBoleto from "@salesforce/label/c.pmc_contractDetails_generateBoleto";
import pmc_contractDetails_addToOrder from "@salesforce/label/c.pmc_contractDetails_addToOrder";
import pmc_contractDetails_messageBannerActive from "@salesforce/label/c.pmc_contractDetails_messageBannerActive";
import pmc_contractDetails_messageBannerActionPending from "@salesforce/label/c.pmc_contractDetails_messageBannerActionPending";
import pmc_contractDetails_messageBannerOnHold from "@salesforce/label/c.pmc_contractDetails_messageBannerOnHold";
import pmc_contractDetails_messageBannerInactiveCompleted from "@salesforce/label/c.pmc_contractDetails_messageBannerInactiveCompleted";
import pmc_contractDetails_messageBannerInactiveExpired from "@salesforce/label/c.pmc_contractDetails_messageBannerInactiveExpired";
import pmc_contractDetails_messageBannerInactiveUnderreview from "@salesforce/label/c.pmc_contractDetails_messageBannerInactiveUnderreview";
import pmc_contractDetails_addedToCart from "@salesforce/label/c.pmc_contractDetails_addedToCart";
import pmc_contractDetails_continueShopping from "@salesforce/label/c.pmc_contractDetails_continueShopping";
import pmc_contractDetails_viewCart from "@salesforce/label/c.pmc_contractDetails_viewCart";
import pmc_contractDetails_myContractsHistory from "@salesforce/label/c.pmc_contractDetails_myContractsHistory";
import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";
import pmc_contractDetails_contractRequoteMessage from "@salesforce/label/c.pmc_contractDetails_contractRequoteMessage";
import pmc_caseDetails_docName from "@salesforce/label/c.pmc_caseDetails_docName";
import pmc_contractDetails_contractDocuments from "@salesforce/label/c.pmc_contractDetails_contractDocuments";
import pmc_orderHistory_download from "@salesforce/label/c.pmc_orderHistory_download";
import pmc_contractDetails_requestSignature from "@salesforce/label/c.pmc_contractDetails_requestSignature";
import pmc_contractDetails_requestSignatureMessage from "@salesforce/label/c.pmc_contractDetails_requestSignatureMessage";
import pmc_contractDetails_accountManagerNotified from "@salesforce/label/c.pmc_contractDetails_accountManagerNotified";
import pmc_contractDetails_requestSignatureSuccessMessage from "@salesforce/label/c.pmc_contractDetails_requestSignatureSuccessMessage";
import pmc_orderDetails_active from "@salesforce/label/c.pmc_orderDetails_active";
import pmc_orderDetails_inactive from "@salesforce/label/c.pmc_orderDetails_inactive";
import pmc_quoteDetailsFlow_statusActionPending from "@salesforce/label/c.pmc_quoteDetailsFlow_statusActionPending";
import pmc_requestForQuote_unitOfMeasure from "@salesforce/label/c.pmc_requestForQuote_unitOfMeasure";
import pmc_requestForQuote_packType from "@salesforce/label/c.pmc_requestForQuote_packType";
import pmc_requestForQuote_packagingType from "@salesforce/label/c.pmc_requestForQuote_packagingType";
import pmc_cadenceSuggestion_viewCadenceDelivery from "@salesforce/label/c.pmc_cadenceSuggestion_viewCadenceDelivery";
import pmc_deleteAddress_success from "@salesforce/label/c.pmc_deleteAddress_success";
import pmc_unauthorizedAccess_restrictedAccessText2 from "@salesforce/label/c.pmc_unauthorizedAccess_restrictedAccessText2";
import pmc_registration_proceed from "@salesforce/label/c.pmc_registration_proceed";
import pmc_contractDetails_completed from "@salesforce/label/c.pmc_contractDetails_completed";
import pmc_contractDetails_expired from "@salesforce/label/c.pmc_contractDetails_expired";
import pmc_contractDetails_underreview from "@salesforce/label/c.PMC_DH_Underreview";
import pmc_contractDetails_activeContractWarningMsg from "@salesforce/label/c.pmc_contractDetails_activeContractWarningMsg";
import pmc_contractDetails_duplicateProductAddition from "@salesforce/label/c.pmc_contractDetails_duplicateProductAddition";
import pmc_contractDetails_messageBannerActionPendingAmendment from "@salesforce/label/c.pmc_contractDetails_messageBannerActionPendingAmendment";
import pmc_contractDetails_products from "@salesforce/label/c.pmc_contractDetails_products";
import Replaced_Reason from "@salesforce/label/c.Replaced_Reason";
import Contract_Inactive from "@salesforce/label/c.Contract_Inactive";


/**
 * A custom LWC to display the contract details page.
 * @alias Pmc_dh_contractDetails
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant
 * @example
 * <c-pmc_dh_contract-details></c-pmc_dh_contract-details>
 */

const STATUS_ON_HOLD = "On Hold";
const MESSAGE_TYPE_WARNING = "warning";
const MESSAGE_TYPE_INFO = "info";
const BADGE_STATUS_WARNING = "warning";
const BADGE_STATUS_ERROR = "error";
const SOURCE_RTD = "RTD";
const SOURCE_RFQ = "RFQ";

export default class Pmc_dh_contractDetails extends NavigationMixin(LightningElement) {
  @track labels = {
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
    pmc_quoteCheckoutFlow_shipFrom,
    pmc_userDetails_edit,
    pmc_quoteDetailsFlow_customerName,
    pmc_miniCartModal_closeLabel,
    pmc_quoteDetailsFlow_check,
    pmc_contractDetails_contract,
    pmc_contractDetails_contractSummary,
    pmc_contractDetails_poNumber,
    pmc_contractDetails_contractType,
    pmc_contractDetails_validityPeriod,
    pmc_contractDetails_reason,
    pmc_contractDetails_requote,
    pmc_contractDetails_totalAvailableQty,
    pmc_contractDetails_totalOrderedQty,
    pmc_contractDetails_availableQty,
    pmc_contractDetails_orderedQty,
    pmc_contractDetails_price,
    pmc_contractDetails_productName,
    pmc_contractDetails_quoteOfOrigin,
    pmc_contractDetails_coupon,
    pmc_contractDetails_itemNumber,
    pmc_contractDetails_averagePricePerUnit,
    pmc_contractDetails_requoteProducts,
    pmc_addressDetails_cancel,
    pmc_contractDetails_generateBoleto,
    pmc_contractDetails_addToOrder,
    pmc_contractDetails_messageBannerActive,
    pmc_contractDetails_messageBannerActionPending,
    pmc_contractDetails_messageBannerOnHold,
    pmc_contractDetails_messageBannerInactiveCompleted,
    pmc_contractDetails_messageBannerInactiveExpired,
    pmc_contractDetails_messageBannerInactiveUnderreview,
    pmc_contractDetails_addedToCart,
    pmc_contractDetails_continueShopping,
    pmc_contractDetails_viewCart,
    pmc_contractDetails_contractRequoteMessage,
    pmc_caseDetails_docName,
    pmc_contractDetails_contractDocuments,
    pmc_orderHistory_download,
    pmc_contractDetails_requestSignature,
    pmc_contractDetails_requestSignatureMessage,
    pmc_contractDetails_accountManagerNotified,
    pmc_contractDetails_requestSignatureSuccessMessage,
    pmc_orderDetails_inactive,
    pmc_orderDetails_active,
    pmc_quoteDetailsFlow_statusActionPending,
    pmc_requestForQuote_unitOfMeasure,
    pmc_requestForQuote_packType,
    pmc_requestForQuote_packagingType,
    pmc_cadenceSuggestion_viewCadenceDelivery,
    pmc_deleteAddress_success,
    pmc_unauthorizedAccess_restrictedAccessText2,
    pmc_registration_proceed,
    pmc_contractDetails_completed,
    pmc_contractDetails_expired,
    pmc_contractDetails_underreview,
    pmc_contractDetails_activeContractWarningMsg,
    pmc_contractDetails_duplicateProductAddition,
    Contract_Inactive,
    Replaced_Reason,
    pmc_contractDetails_messageBannerActionPendingAmendment
  };

  @track iconUrlObj = {
    edit: `${PMC_BrandingAssetsStaticResource}/icons/icon-edit-stroke-table.svg`,
    close: `${PMC_BrandingAssetsStaticResource}/icons/icon-close-stroke-table.svg`,
    check: `${PMC_BrandingAssetsStaticResource}/icons/icon-check-stroke-table.svg`,
    mosaicLogoUrl: `${PMC_BrandingAssetsStaticResource}/images/logo-mosaic.png`,
    cart: `${PMC_BrandingAssetsStaticResource}/icons/icon-cart-solid.svg`,
    cartDisabled: `${PMC_BrandingAssetsStaticResource}/icons/icon-cart-solid-disabled.svg`,
    arrowDownUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-arrowdown.svg`,
    download: `${PMC_BrandingAssetsStaticResource}/icons/icon-download.svg`,
    circleCheck: `${PMC_BrandingAssetsStaticResource}/icons/icon-circle-check-active.svg`
  };

  @track crumbs = [
    { label: pmc_breadcrumb_homepage, url: `${basePath}/`, isActive: false },
    {
      label: pmc_contractDetails_myContractsHistory,
      url: `${basePath}/contracts`,
      isActive: false
    },
    { label: ``, url: "", isActive: true }
  ];

  @track pageObj = {};
  @track productDetails = [];
  @track cartItemObj = [];
  @track lineItemData = {}; // Tracked object to store retrieved line item data

  cssDropdownIcon = "dropdown-icon down";
  contractNumber;
  isContractDocument = true;
  contractDocuments = [
    {
      strDocName: "Doc1",
      strContractType: "FBD",
      strDeliveryMode: "Train",
      strDocId: "1222222",
      strDownloadURL:
        "/digitalhubvforcesite/sfc/servlet.shepherd/document/download/069DT000001mB3VYAU"
    },
    {
      strDocName: "Doc2",
      strContractType: "FOB",
      strDeliveryMode: "Container",
      strDocId: "1222322",
      strDownloadURL:
        "/digitalhubvforcesite/sfc/servlet.shepherd/document/download/069DT000001mB3WYAU"
    },
    {
      strDocName: "Doc3",
      strContractType: "Third-Party",
      strDeliveryMode: "Barge",
      strDocId: "1222622",
      strDownloadURL:
        "/digitalhubvforcesite/sfc/servlet.shepherd/document/download/069DT000001mB3XYAU"
    }
  ];
  isStatusInactive = false;
  isStatusActive = false;
  isActionPending = false;
  isEditDisabled = true;
  isRequoteModal = false;
  isAddedToCartModal = false;
  isRequestSignatureModal = false;
  isSignatureRequested = false;
  isRequestSignatureAllowed = false;
  isRequestSignatureDisabled = false;
  isBoletoVisible = false;
  pageRendered = false;
  pageLoaded = false;
  isSpinner = true;
  isAddToOrderVisible = !DisableAddtoOrder;
  isRequoteVisible = !DisableAddtoOrder;
  isProductLinkClickable = !DisableAddtoOrder;
  isQuoteWidgetVisible = !DisableRequestContractSignature;
  queryString = window.location.search;
  contractId;
  messageForBanner;
  messageBannerType;
  showBanner = true; // controls visibility of the top message banner
  showInactiveReason = false; // controls visibility of the "reason" field
  poNumber;
  activeCartId;
  quotePageUrl;
  error;
  isDocAvail = false;
  isLocationBrazil = false;
  isCadenceSuggestionAllowed = false;
  isCadenceSuggestionModal = false;
  isUnauthorizedAccess = false;
  addedToCartTitle;

  @wire(getNavigationMenu)
  navMenu({ error, data }) {
    if (data) {
      this.fetchProductLink(data.menuItems);
    } else if (error) {
      this.error = error;
    }
  }

  /**
   * Generates product page link
   * @function fetchProductLink
   * @param {Array} menuItems
   */
  fetchProductLink(menuItems) {
    let baseUrl = window.location.origin;
    const productsItem = menuItems.find(item => item.label === pmc_contractDetails_products);
    let productPageUrl = `${baseUrl}${productsItem.actionValue}`;
    this.labels.pmc_contractDetails_messageBannerInactiveCompleted = formatLabel(this.labels.pmc_contractDetails_messageBannerInactiveCompleted, [productPageUrl]);
    this.labels.pmc_contractDetails_messageBannerInactiveExpired = formatLabel(this.labels.pmc_contractDetails_messageBannerInactiveExpired, [productPageUrl]);
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.isSuperBuyerOrContractManager = viewOnlyAccess || (!DisableAddtoOrder && DH_Edit_Address);
    let that = this;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.intervalId = setInterval(() => {
      if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
        this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
        clearInterval(that.intervalId);
        this.fetchContractInfo();
      }
    }, 100);
    this.isLocationBrazil = isBrazilRegion();
    this.queryParamsHandler();
    this.getContractDocInfo();
  }

  /**
   * Reading query params
   * @function queryParamsHandler
   */
  queryParamsHandler() {
    if (this.queryString) {
      let params = new URLSearchParams(this.queryString);
      let startURLTemp = params.get("contractId") || params.get("quoteId");
      if (startURLTemp) {
        this.contractId = startURLTemp;
      }
    }
  }

  /**
   * fetch shipment details from backend method
   * @function fetchContractInfo
   */
  fetchContractInfo() {
    getContractDetails({
      strCommunityId: communityId,
      strEffectiveAccountId: this.effectiveAccountId,
      strContractId: this.contractId
    })
      .then((data) => {
        if (data && Object.keys(data).length) {
          if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusCode && JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusCode === '999') {
            this.isUnauthorizedAccess = true;
            return;
          }
          else if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
          }
          this.pageObj = JSON.parse(JSON.stringify(data));
          this.contractNumber = this.pageObj.strContractNumber;
          this.crumbs = this.crumbs.map((elem, index) => {
            if (index === 2) {
              elem.label = `${this.labels.pmc_contractDetails_contract} ${this.contractNumber}`;
            }
            return elem;
          });
          this.cartItemObj = [];
          if (this.pageObj?.productInfoWrapper?.lstCartWrapper) {
            this.pageObj.productInfoWrapper.lstCartWrapper.forEach((e1) => {
              setWithExpirationFromSession(`lstContractItems_${e1.strProductId}`, e1.lstContractItems, 3600);

              e1.lstContractItems.forEach((e2) => {

                if(!getLineItemDataFromSessionStorage(`${e1.strProductId}_${this.contractId}_${e2.strContractItemId}`)) {
                  // Use the upsert method to store intAvailableQty and intOrderedQty in sessionStorage
                  upsertLineItemData(`${e1.strProductId}_${this.contractId}_${e2.strContractItemId}`, e2.intAvailableQty, e2.intOrderedQty);
                } else {
                  this.lineItemData = getLineItemDataFromSessionStorage(`${e1.strProductId}_${this.contractId}_${e2.strContractItemId}`);
                  e2.intAvailableQty = parseInt(this.lineItemData.intAvailableQty, 10);
                  e2.intOrderedQty = parseInt(this.lineItemData.intOrderedQty, 10);
                }

                this.cartItemObj.push({
                  strQuantity: e2.intQty,
                  strDeliveryMode: e2.strDeliveryMode,
                  strIncoterms: e2.strIncoterm,
                  strShipFrom: e2.wrpShipFrom.value,
                  strShipTo: e2.wrpShipTo.value,
                  strProductId: e1.strProductId,
                  strProductName: e1.strProductName,
                  strSku: e1.strSku,
                  strSource: SOURCE_RFQ
                });
              });
            });
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
  }

  /**
   * Fetches contract documents
   * @function getContractDocInfo
   */
  getContractDocInfo() {
    this.isSpinner = true;
    getContractDocInfo({ strContractId: this.contractId })
      .then((res) => {
        if (res && Object.keys(res).length) {
          if (JSON.parse(JSON.stringify(res)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(res)).statusCodeMessage.strStatusMessage)
          }
          this.contractDocuments = JSON.parse(JSON.stringify(res));
          this.isDocAvail =
            this.contractDocuments.lstContractDoc &&
            this.contractDocuments.lstContractDoc.length > 0 &&
            Object.keys(this.contractDocuments.lstContractDoc[0].length > 0);
        }
        this.isSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
      });
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    if (this.pageLoaded) {
      this.isPOEditable = this.pageObj.boolIsPOEditable ? this.pageObj.boolIsPOEditable : false;
      this.poNumber = this.pageObj?.contractSummaryWrapper?.strPoNumber;
      if (this.pageObj?.contractSummaryWrapper?.strSummaryStatus && this.pageObj?.contractSummaryWrapper?.strQuoteType  && this.pageObj?.contractSummaryWrapper?.strQuoteType == 'Amendment') {
          this.template
          .querySelector(".badge")
          .setAttribute("data-status", BADGE_STATUS_ERROR);
        this.messageForBanner =
          this.labels.pmc_contractDetails_messageBannerActionPendingAmendment;
        this.messageBannerType = MESSAGE_TYPE_WARNING;
      }else if(this.pageObj?.contractSummaryWrapper?.strSummaryStatus) {
        this.contractStatusHandler(
          this.pageObj.contractSummaryWrapper.strSummaryStatus
        );
      }
      // Hide banner/reason when contract is Inactive or explicitly Expired to avoid showing
      // the "contrato inativo/expirado" messages to the user. This keeps warnings hidden
      // while preserving other UI behavior (e.g., blocked/replaced still handled elsewhere).
      const summaryStatus = this.pageObj?.contractSummaryWrapper?.strSummaryStatus;
      const inactiveReason = this.pageObj?.contractSummaryWrapper?.strInactiveReason;
      const isInactive = summaryStatus === this.labels.pmc_orderDetails_inactive;
      const isExpired = inactiveReason === this.labels.pmc_contractDetails_expired;
      this.showBanner = !(isInactive || isExpired);
      // Only show the "reason" field when the contract is inactive for reasons other than Expired
      this.showInactiveReason = isInactive && !isExpired;
      let baseUrl = window.location.origin;
      if (this.pageObj?.productInfoWrapper?.lstCartWrapper) {
        this.pageObj.productInfoWrapper.lstCartWrapper.forEach((product) => {
          let url = `${baseUrl}${basePath}/product/${product.strProductId}`;
          product.pdpUrl = url;

          product.lstContractItems.forEach((el) => {
            if (this.isAddToOrderVisible) {
              // Allow add-to-order when contract is active OR when item has available quantity,
              // even if contract is shown as inactive due to end date. Do NOT allow when contract
              // is explicitly blocked/replaced (business rule).
              const isBlockedReason = this.pageObj?.contractSummaryWrapper?.strInactiveReason === this.labels.Replaced_Reason;
              const hasAvailableQty = el.intAvailableQty && el.intAvailableQty > 0;
              const allowAdd = this.isStatusActive || (hasAvailableQty && !isBlockedReason);

              el.isAddToOrder = allowAdd;
              el.cartIconUrl = allowAdd ? this.iconUrlObj.cart : this.iconUrlObj.cartDisabled;
            }
          });
        });
      }
      if (this.pageObj.contractSummaryWrapper.datContractStartDate)
        this.pageObj.contractSummaryWrapper.datContractStartDate = this.pageObj
          ?.contractSummaryWrapper?.datContractStartDate
          ? formatDate(this.pageObj.contractSummaryWrapper.datContractStartDate)
          : "";
      if (this.pageObj.contractSummaryWrapper.datContractEndDate)
        this.pageObj.contractSummaryWrapper.datContractEndDate = this.pageObj
          ?.contractSummaryWrapper?.datContractEndDate
          ? formatDate(this.pageObj.contractSummaryWrapper.datContractEndDate)
          : "";
      this.pageObj?.lstQuoteOfOriginWrapper?.forEach(quote => {
        let quoteId = quote.strQuoteId;
        let quoteNumber = quote.strQuoteNumber;
        quote.quotePageUrl = `${baseUrl}${basePath}/quote?quoteNumber=${quoteNumber}?quoteId=${quoteId}`;
      })
      if (this.pageObj?.quoteOfOriginWrapper) {
        this.pageObj.quoteOfOriginWrapper.quotePageUrl = `${baseUrl}${basePath}/quote?quoteNumber=${this.pageObj.quoteOfOriginWrapper.strQuoteNumber}?quoteId=${this.pageObj.quoteOfOriginWrapper.strQuoteId}`;
      }
      this.pageRendered = true;
    }
  }

  /**
   * Handles Summary Status and Message
   * @function contractStatusHandler
   * @param {string} summaryStatus
   */
  contractStatusHandler(summaryStatus) {
    switch (summaryStatus) {
      case this.labels.pmc_orderDetails_inactive:
        this.template
          .querySelector(".badge")
          .setAttribute("data-status", BADGE_STATUS_ERROR);
        this.isStatusInactive = true;
        this.messageBannerType = MESSAGE_TYPE_WARNING;
        if (
          this.pageObj.contractSummaryWrapper.strInactiveReason ===
          this.labels.pmc_contractDetails_completed
        ) {
          this.messageForBanner =
            this.labels.pmc_contractDetails_messageBannerInactiveCompleted;
        }
        if (
          this.pageObj.contractSummaryWrapper.strInactiveReason ===
          this.labels.pmc_contractDetails_expired
        ) {
          this.messageForBanner =
            this.labels.pmc_contractDetails_messageBannerInactiveExpired;
        }
        if (
          this.pageObj.contractSummaryWrapper.strInactiveReason ===
          this.labels.Replaced_Reason
        ) {
          this.messageForBanner =
            this.labels.Contract_Inactive;
        }
        break;

      case this.labels.pmc_orderDetails_active:
        this.isStatusActive = true;
        if (this.isSuperBuyerOrContractManager) {
          this.isCadenceSuggestionAllowed = true
        }
        this.messageForBanner =
          this.labels.pmc_contractDetails_messageBannerActive;
        this.messageBannerType = MESSAGE_TYPE_INFO;
        break;

      case STATUS_ON_HOLD:
        this.template
          .querySelector(".badge")
          .setAttribute("data-status", BADGE_STATUS_WARNING);
        this.messageForBanner =
          this.labels.pmc_contractDetails_messageBannerOnHold;
        this.messageBannerType = MESSAGE_TYPE_INFO;
        break;

      case this.labels.pmc_quoteDetailsFlow_statusActionPending:
        this.isActionPending = true;
        if (this.isSuperBuyerOrContractManager) {
          this.isCadenceSuggestionAllowed = true
        }
        if (!DisableRequestContractSignature) {
          this.isRequestSignatureAllowed = true;
        }
        if (!this.pageObj?.contractSummaryWrapper?.boolIsEligibleForReqSign) {
          this.isRequestSignatureDisabled = true;
        }
        this.template
          .querySelector(".badge")
          .setAttribute("data-status", BADGE_STATUS_WARNING);
        this.messageForBanner =
          this.labels.pmc_contractDetails_messageBannerActionPending;
        this.messageBannerType = MESSAGE_TYPE_INFO;
        break;

      default:
        break;
    }
  }

  /**
   * On input change event handle for PO Number
   * @function handleDataChange
   * @param {event} event
   */
  handleDataChange(event) {
    this.poNumber = event.target.value;
  }

  /**
   * Add to Order Handler
   * @function handleAddToOrder
   * @param {event} event
   */
  handleAddToOrder(event) {
    let productIndex = event.target.dataset.productIndex;
    let shipmentIndex = event.target.dataset.shipmentIndex;
    let prod = this.pageObj.productInfoWrapper.lstCartWrapper[productIndex];
    let item = prod.lstContractItems[shipmentIndex];
    let obj = {
      strProductId: prod.strProductId,
      strProductName: prod.strProductName,
      strSku: prod.strSku,
      strContractItemId: item.strContractItemId,
      strDeliveryMode: item.strDeliveryMode,
      strQuantity: item.intAvailableQty,
      strShipTo: item.wrpShipTo.value,
      strIncoterms: item.strIncoterm,
      strShipFrom: item.wrpShipFrom.value,
      strContractType: item.strContractType,
      strSource: SOURCE_RTD
    };
    this.productDetails = [];
    this.productDetails.push(obj);
    this.fetchActiveCartId();
  }

  /**
   * Expands and Collapse the Contract Document Widget
   * @function expandContractDocument
   * @param {event} event
   */
  expandContractDocument(event) {
    if (event.target.dataset.target === "dropdown-icon") {
      this.isContractDocument = !this.isContractDocument;
      this.cssDropdownIcon = this.isContractDocument
        ? "dropdown-icon down"
        : "dropdown-icon";
    }
  }

  /**
   * Fetches Active Cart Id
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
          if (this.isRequoteModal) {
            this.addshipmentInfo(this.activeCartId);
            return;
          }
          this.addItemToCart(this.activeCartId);
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  }

  /**
   * Adds shipment info and redirects to RFQ flow
   * @function addshipmentInfo
   * @param {string} cartId
   */
  addshipmentInfo(cartId) {
    addRequoteCartItems({
      strCartId: cartId,
      strInputJSON: JSON.stringify(this.cartItemObj)
    })
      .then((response) => {
        if (response) {
          this.validateCart(cartId);
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  }

  /**
   * Cart page validation
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
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  }

  /**
   * Adds product to cart from contract
   * @function addItemToCart
   * @param {string} activeCartId
   */
  addItemToCart(activeCartId) {
    let objWrapper = {
      strCartId: activeCartId,
      strCurrency: this.pageObj.paymentInfoWrapper.strCurrencySelected,
      strContractId: this.contractId
    };
    addCartItems({
      strInputJSON: JSON.stringify(this.productDetails),
      objCartItemWrapper: objWrapper
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
          }
          if (response?.strStatusCode === "000" || response?.strStatusCode === "111") {
            this.isAddedToCartModal = true;
            this.addedToCartTitle = response.strStatusCode === "111" ? this.labels.pmc_contractDetails_duplicateProductAddition : this.labels.pmc_contractDetails_addedToCart;
          }
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
   * Edit icon handler
   * @function handleEditInfo
   */
  handleEditInfo() {
    this.isEditDisabled = false;
  }

  /**
   * Cancel edit handler
   * @function handleCloseEdit
   */
  handleCloseEdit() {
    this.poNumber = this.pageObj.contractSummaryWrapper.strPoNumber;
    this.isEditDisabled = true;
  }

  /**
   * Saves the updated PO Number
   * @function handleSaveInfo
   */
  handleSaveInfo() {
    this.pageObj.contractSummaryWrapper.strPoNumber = this.poNumber;
    this.isEditDisabled = true;
    this.addPoNumber();
  }

  /**
   * Adds updated PO number to BE
   * @function addPoNumber
   */
  addPoNumber() {
    this.isSpinner = true;
    updatePoNumber({
      strQuoteId: this.pageObj.strQuoteId,
      strPoNumber: this.poNumber
    })
      .then(() => {
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  }

  /**
   * If product image doesn't load, display default image
   * @function handleImageError
   * @param {event} event
   */
  handleImageError(event) {
    event.currentTarget.src = this.iconUrlObj.mosaicLogoUrl;
    event.currentTarget.style.height = "unset";
    event.currentTarget.onerror = null;
  }

  /**
   * Requote Modal open handler
   * @function openRequoteModalHandler
   */
  openRequoteModalHandler() {
    this.isRequoteModal = true;
  }

  /**
   * Request Signature Modal open handler
   * @function openRequestSignatureModalHandler
   */
  openRequestSignatureModalHandler() {
    this.isRequestSignatureModal = true;
  }

  /**
   * Requote Modal close handler
   * @function handleCloseRequoteModal
   */
  handleCloseRequoteModal() {
    this.isRequoteModal = false;
  }

  /**
   * Request Signature Modal close handler
   * @function handleCloseRequestSignatureModal
   */
  handleCloseRequestSignatureModal() {
    this.isRequestSignatureModal = false;
  }

  /**
   * on click of Confirm on Request Signature Modal
   * @function handleConfirmSignatureRequest
   */
  handleConfirmSignatureRequest() {
    this.isModalSpinner = true;
    contractRequestSignature({
      strQuoteId: this.pageObj?.strQuoteId,
      strEffectiveAccountId: this.effectiveAccountId
    })
      .then((result) => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).strStatusMessage)
          }
          if (result.strStatusCode === "000") {
            this.isSignatureRequested = true;
            this.isRequestSignatureDisabled = true;
          }
        }
        this.isModalSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isModalpinner = false;
      });
  }

  /**
   * Method to redirect to ShipmentInfoPage on Requote Products button click
   * @function handleRequoteProducts
   */
  handleRequoteProducts() {
    this.fetchActiveCartId();
  }

  /**
   * AddToCart Modal close handler
   * @function handleCloseAddedToCartModal
   */
  handleCloseAddedToCartModal() {
    this.isAddedToCartModal = false;
  }

  /**
   * Redirects to cart
   * @function handleViewCart
   */
  handleViewCart() {
    let baseUrl = window.location.origin;
    this[NavigationMixin.GenerateUrl]({
      type: "standard__webPage",
      attributes: {
        url: `${baseUrl}${basePath}/cart`
      }
    }).then((generatedUrl) => {
      urlRedirect(generatedUrl);
    });
  }

  /**
   * Handle enter key press on Document Name
   * @function handleDocViewOnEnter
   * @param {Event} event
   */
  handleDocViewOnEnter(event) {
    if (event.keyCode === 13) {
      this.docViewHandler(event);
    }
  }

  /**
   * Preview Document in a new tab
   * @function previewDoc
   * @param {string} url
   */
  previewDoc(url) {
    var link = document.createElement('a');
    link.target = '_blank';
    link.href = url;
    link.click();
  }

  /**
   * Download the document on 'Download' icon click
   * @function docDownloadHandler
   * @param {Event} event
   */
  docDownloadHandler(event) {
    this.isSpinner = true;
    const docId = event.target.dataset.docId;
    getContractDocData({ strAction: "Download", strDocId: docId })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
          }
          else if (JSON.parse(JSON.stringify(response)).strDownloadLink) {
            const _url = JSON.parse(JSON.stringify(response)).strDownloadLink;
            urlRedirect(_url);
          }
        }
        this.isSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
      });
  }

  /**
   * Convert base64 data to Blob
   * @function base64toBlob
   * @param {string} b64Data
   * @param {string} contentType
   * @param {number} sliceSize
   * @returns BLOB
   */
  base64toBlob(b64Data, contentType = "", sliceSize = 512) {
    const byteCharacters = window.atob(b64Data);
    const byteArrays = [];

    for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
      const slice = byteCharacters.slice(offset, offset + sliceSize);

      const byteNumbers = new Array(slice.length);
      for (let i = 0; i < slice.length; i++) {
        byteNumbers[i] = slice.charCodeAt(i);
      }

      const byteArray = new Uint8Array(byteNumbers);
      byteArrays.push(byteArray);
    }
    const blob = new Blob(byteArrays, { type: contentType });
    return blob;
  }

  /**
   * Preview the document handler
   * @function docViewHandler
   * @param {Event} event
   */
  docViewHandler(event) {
    this.isSpinner = true;
    const docId = event.target.dataset.docId;
    getContractDocData({ strAction: "View", strDocId: docId })
      .then((res) => {
        if (res && Object.keys(res).length) {
          if (JSON.parse(JSON.stringify(res)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(res)).statusCodeMessage.strStatusMessage)
          }
          const blob = this.base64toBlob(
            JSON.parse(JSON.stringify(res)).strViewData,
            "application/pdf"
          );
          const blobUrl = URL.createObjectURL(blob);
          this.previewDoc(blobUrl);
        }
        this.isSpinner = false;
      })
      .catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
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
}