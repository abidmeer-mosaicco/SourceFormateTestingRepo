/* eslint-disable no-useless-escape */
import { LightningElement, track } from "lwc";
import basePath from "@salesforce/community/basePath";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { formatDate, unFormatDate, handleError, isBrazilRegion, getTodayDate, urlRedirect, toastMessageHandler } from "c/pmc_dh_utilityJs";
import getOrderDetails from "@salesforce/apex/PMC_DH_OrderManagementController.getOrderDetails";
import getBRRequestedOrderDetails from '@salesforce/apex/PMC_DH_RequestedOrderDetails.getOrderDetails';
import saveUpdatedOrderDetails from '@salesforce/apex/PMC_DH_RequestedOrderEditController.getUpdatedDetails';
import reorderFromOrderDetails from "@salesforce/apex/PMC_DH_OrderManagementController.reorderFromOrderDetails";
import updateCustomerCallPriceDate from "@salesforce/apex/PMC_DH_OrderManagementController.updateCustomerCallPriceDate";
import getActiveCartId from "@salesforce/apex/PMC_DH_QuoteUtils.getActiveCartId";
import validateCart from '@salesforce/apex/PMC_DH_CartValidationController.validateCart';
import communityId from "@salesforce/community/Id";
import DisableAddtoOrder from '@salesforce/customPermission/DisableAddtoOrder';
import Hide_Contract from '@salesforce/customPermission/Hide_Contract';

import pmc_orderHistory_myOrderHistory from "@salesforce/label/c.pmc_orderHistory_myOrderHistory";
import pmc_orderDetails_request from "@salesforce/label/c.pmc_orderDetails_request";
import pmc_orderHistory_requested from "@salesforce/label/c.pmc_orderHistory_requested";
import pmc_orderDetails_confirmationMsg from "@salesforce/label/c.pmc_orderDetails_confirmationMsg";
import pmc_orderHistory_confirmed from "@salesforce/label/c.pmc_orderHistory_confirmed";
import pmc_orderDetails_summary from "@salesforce/label/c.pmc_orderDetails_summary";
import pmc_quoteDetailsFlow_customerName from "@salesforce/label/c.pmc_quoteDetailsFlow_customerName";
import pmc_orderDetails_orderPlacedBy from "@salesforce/label/c.pmc_orderDetails_orderPlacedBy";
import pmc_orderDetails_salesChannel from "@salesforce/label/c.pmc_orderDetails_salesChannel";
import pmc_orderDetails_datePlaced from "@salesforce/label/c.pmc_orderDetails_datePlaced";
import pmc_userManagement_userStatus from "@salesforce/label/c.pmc_userManagement_userStatus";
import pmc_requestForQuote_productsInformation from "@salesforce/label/c.pmc_requestForQuote_productsInformation";
import pmc_orderDetails_itemNumber from "@salesforce/label/c.pmc_orderDetails_itemNumber";
import pmc_orderDetails_requestedQty from "@salesforce/label/c.pmc_orderDetails_requestedQty";
import pmc_orderDetails_confirmedQty from "@salesforce/label/c.pmc_orderDetails_confirmedQty";
import pmc_quoteCheckoutFlow_deliveryMode from "@salesforce/label/c.pmc_quoteCheckoutFlow_deliveryMode";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_quoteCheckoutFlow_shipFrom from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipFrom";
import pmc_requestToDeliver_contractInformation from "@salesforce/label/c.pmc_requestToDeliver_contractInformation";
import pmc_contractMgmt_viewContract from "@salesforce/label/c.pmc_contractMgmt_viewContract";
import pmc_requestToDeliver_contractNumber from "@salesforce/label/c.pmc_requestToDeliver_contractNumber";
import pmc_contractDetails_poNumber from "@salesforce/label/c.pmc_contractDetails_poNumber";
import pmc_contractDetails_validityPeriod from "@salesforce/label/c.pmc_contractDetails_validityPeriod";
import pmc_contractDetails_contractType from "@salesforce/label/c.pmc_contractDetails_contractType";
import pmc_quoteCheckoutFlow_paymentTerms from "@salesforce/label/c.pmc_quoteCheckoutFlow_paymentTerms";
import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";
import pmc_cartCheckout_sku from "@salesforce/label/c.pmc_cartCheckout_sku";
import pmc_quoteDetailsFlow_statusSubmitted from "@salesforce/label/c.pmc_quoteDetailsFlow_statusSubmitted";
import pmc_orderDetails_getInTouchMsg from "@salesforce/label/c.pmc_orderDetails_getInTouchMsg";
import pmc_addressDetails_cancel from "@salesforce/label/c.pmc_addressDetails_cancel";
import pmc_orderDetails_order from "@salesforce/label/c.pmc_orderDetails_order";
import pmc_orderDetails_confirmedMessage from "@salesforce/label/c.pmc_orderDetails_confirmedMessage";
import pmc_quoteDetailsFlow_statusNotApplicable from "@salesforce/label/c.pmc_quoteDetailsFlow_statusNotApplicable";
import pmc_addresses_status from "@salesforce/label/c.pmc_addresses_status";
import pmc_orderDetails_shipmentInformation from "@salesforce/label/c.pmc_orderDetails_shipmentInformation";
import pmc_orderDetails_grouping from "@salesforce/label/c.pmc_orderDetails_grouping";
import PMC_CPQ_SAPOrderLineID from "@salesforce/label/c.PMC_CPQ_SAPOrderLineID";
import pmc_orderDetails_pendingQty from "@salesforce/label/c.pmc_orderDetails_pendingQty";
import pmc_orderDetails_shippedQty from "@salesforce/label/c.pmc_orderDetails_shippedQty";
import pmc_orderDetails_deliveredQty from "@salesforce/label/c.pmc_orderDetails_deliveredQty";
import pmc_orderDetails_reorder from "@salesforce/label/c.pmc_orderDetails_reorder";
import pmc_orderDetails_reorderProducts from "@salesforce/label/c.pmc_orderDetails_reorderProducts";
import pmc_orderDetails_reorderText from "@salesforce/label/c.pmc_orderDetails_reorderText";
import pmc_fpd_callPriceDate from "@salesforce/label/c.pmc_fpd_callPriceDate";
import pmc_fpd_callPrice from "@salesforce/label/c.pmc_fpd_callPrice";
import pmc_fpd_requestCallPrice from "@salesforce/label/c.pmc_fpd_requestCallPrice";
import pmc_fpd_whichOrderLine from "@salesforce/label/c.pmc_fpd_whichOrderLine";
import pmc_fpd_callPriceForTotalQty from "@salesforce/label/c.pmc_fpd_callPriceForTotalQty";
import pmc_fpd_callPriceSpecificLine from "@salesforce/label/c.pmc_fpd_callPriceSpecificLine";
import pmc_fpd_callPriceNow from "@salesforce/label/c.pmc_fpd_callPriceNow";
import pmc_fpd_callPriceRequested from "@salesforce/label/c.pmc_fpd_callPriceRequested";
import pmc_shipmentDetails_orderLineNumber from "@salesforce/label/c.pmc_shipmentDetails_orderLineNumber";
import pmc_orderDetails_active from "@salesforce/label/c.pmc_orderDetails_active";
import pmc_orderDetails_statusPlaced from "@salesforce/label/c.pmc_orderDetails_statusPlaced";
import pmc_userDetails_edit from "@salesforce/label/c.pmc_userDetails_edit";
import pmc_miniCartModal_closeLabel from "@salesforce/label/c.pmc_miniCartModal_closeLabel";
import pmc_quoteDetailsFlow_check from "@salesforce/label/c.pmc_quoteDetailsFlow_check";
import pmc_requestForQuote_unitOfMeasure from "@salesforce/label/c.pmc_requestForQuote_unitOfMeasure";
import pmc_requestForQuote_packType from "@salesforce/label/c.pmc_requestForQuote_packType";
import pmc_requestForQuote_packagingType from "@salesforce/label/c.pmc_requestForQuote_packagingType";
import pmc_orderDetails_validityPeriodErrorMsg from "@salesforce/label/c.pmc_orderDetails_validityPeriodErrorMsg";
import pmc_orderDetails_requestedQtyErrorMsg from "@salesforce/label/c.pmc_orderDetails_requestedQtyErrorMsg";
import pmc_orderDetails_duplicateShipmentErrorMsg from "@salesforce/label/c.pmc_orderDetails_duplicateShipmentErrorMsg";
import pmc_orderDetails_yourChangesNotSaved from "@salesforce/label/c.pmc_orderDetails_yourChangesNotSaved";
import pmc_orderDetails_dateValidationErrMsg from "@salesforce/label/c.pmc_orderDetails_dateValidationErrMsg";
import pmc_unauthorizedAccess_restrictedAccessText2 from "@salesforce/label/c.pmc_unauthorizedAccess_restrictedAccessText2";
import PMC_DH_InProgress from "@salesforce/label/c.PMC_DH_InProgress";
import pmc_orderDetails_orderLine from "@salesforce/label/c.pmc_orderDetails_orderLine";
import pmc_requestToDeliver_qty from "@salesforce/label/c.pmc_requestToDeliver_qty";
import pmc_fpd_callDate from "@salesforce/label/c.pmc_fpd_callDate";
import pmc_fpd_shipmentDate from "@salesforce/label/c.pmc_fpd_shipmentDate";
import pmc_fpd_shipToAddress from "@salesforce/label/c.pmc_fpd_shipToAddress";
import pmc_fpd_unpriced from "@salesforce/label/c.pmc_fpd_unpriced";
import pmc_fpd_priced from "@salesforce/label/c.pmc_fpd_priced";
import pmc_fpd_pending from "@salesforce/label/c.pmc_fpd_pending";
import pmc_requestToDeliver_expectedShipmentDate from "@salesforce/label/c.pmc_requestToDeliver_expectedShipmentDate";
import PMC_DH_StatusHold from "@salesforce/label/c.PMC_DH_StatusHold";
import PMC_DH_Cancelled from "@salesforce/label/c.PMC_DH_Cancelled";
import pmc_orderHistory_protocolId from "@salesforce/label/c.pmc_orderHistory_protocolId";
import pmc_orderHistory_salesOrder from "@salesforce/label/c.pmc_orderHistory_salesOrder";
import pmc_orderHistory_requestId from "@salesforce/label/c.pmc_orderHistory_requestId";

const callPriceModalColumns = [
  {
    label: "",
    fieldName: "Checkbox",
    type: "checkbox",
  },
  {
    label: pmc_fpd_shipToAddress,
    fieldName: "ShipToAddress",
    type: "text",
  },
  {
    label: pmc_orderDetails_orderLine,
    fieldName: "OrderLine",
    type: "text",
  },
  {
    label: pmc_fpd_shipmentDate,
    fieldName: "ShipmentDate",
    type: "text",
    dataType: "date",
  },
  {
    label: pmc_requestToDeliver_qty,
    fieldName: "Quantity",
    type: "text",
  },
  {
    label: pmc_fpd_callDate,
    fieldName: "CallDate",
    type: "text",
    dataType: "date",
  }
];

const ORDER_STATUS = {
  DRAFT: "Draft",
};

const BADGE_STATUS_WARNING = "warning";
const BADGE_STATUS_ERROR = "error";
const SOURCE_RTD = "RTD";
const CONTRACT_STATUS_FPD = "FPD";
const REQUESTED = 'Requested';

/**
 * A custom LWC to display order details.
 * @alias Pmc_dh_orderDetails
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_order-details></c-pmc_dh_order-details>
 */

export default class Pmc_dh_orderDetails extends NavigationMixin(LightningElement) {
  callPriceModalColumns = callPriceModalColumns;
  @track labels = {
    pmc_orderHistory_myOrderHistory,
    pmc_orderDetails_request,
    pmc_orderHistory_requested,
    pmc_orderHistory_confirmed,
    pmc_orderDetails_confirmationMsg,
    pmc_orderDetails_summary,
    pmc_quoteDetailsFlow_customerName,
    pmc_orderDetails_orderPlacedBy,
    pmc_orderDetails_salesChannel,
    pmc_orderDetails_datePlaced,
    pmc_userManagement_userStatus,
    pmc_requestForQuote_productsInformation,
    pmc_orderDetails_itemNumber,
    pmc_orderDetails_requestedQty,
    pmc_orderDetails_confirmedQty,
    pmc_quoteCheckoutFlow_deliveryMode,
    pmc_quoteCheckoutFlow_shipTo,
    pmc_quoteCheckoutFlow_shipFrom,
    pmc_requestToDeliver_contractInformation,
    pmc_contractMgmt_viewContract,
    pmc_requestToDeliver_contractNumber,
    pmc_contractDetails_poNumber,
    pmc_contractDetails_validityPeriod,
    pmc_contractDetails_contractType,
    pmc_quoteCheckoutFlow_paymentTerms,
    pmc_breadcrumb_homepage,
    pmc_cartCheckout_sku,
    pmc_quoteDetailsFlow_statusSubmitted,
    pmc_orderDetails_getInTouchMsg,
    pmc_addressDetails_cancel,
    pmc_orderDetails_order,
    pmc_orderDetails_confirmedMessage,
    pmc_quoteDetailsFlow_statusNotApplicable,
    pmc_addresses_status,
    pmc_orderDetails_shipmentInformation,
    pmc_orderDetails_grouping,
    PMC_CPQ_SAPOrderLineID,
    pmc_orderDetails_pendingQty,
    pmc_orderDetails_shippedQty,
    pmc_orderDetails_deliveredQty,
    pmc_orderDetails_reorder,
    pmc_orderDetails_reorderProducts,
    pmc_orderDetails_reorderText,
    pmc_fpd_callPriceDate,
    pmc_fpd_callPrice,
    pmc_fpd_requestCallPrice,
    pmc_fpd_whichOrderLine,
    pmc_fpd_callPriceNow,
    pmc_shipmentDetails_orderLineNumber,
    pmc_orderDetails_active,
    pmc_orderDetails_statusPlaced,
    pmc_userDetails_edit,
    pmc_miniCartModal_closeLabel,
    pmc_quoteDetailsFlow_check,
    pmc_requestForQuote_unitOfMeasure,
    pmc_requestForQuote_packType,
    pmc_requestForQuote_packagingType,
    pmc_orderDetails_validityPeriodErrorMsg,
    pmc_orderDetails_requestedQtyErrorMsg,
    pmc_orderDetails_duplicateShipmentErrorMsg,
    pmc_orderDetails_dateValidationErrMsg,
    pmc_unauthorizedAccess_restrictedAccessText2,
    PMC_DH_InProgress,
    pmc_fpd_unpriced,
    pmc_fpd_priced,
    pmc_fpd_pending,
    pmc_requestToDeliver_expectedShipmentDate,
    PMC_DH_StatusHold,
    pmc_orderHistory_protocolId,
    pmc_orderHistory_salesOrder,
    pmc_orderHistory_requestId
  };

  @track callPriceObj = {
    btnLabel: pmc_fpd_callPrice,
    isCallPrice: false,
    isCallPriceBtn: false,
    isBtnDisabled: false,
    isModalCTADisabled: false,
    selectedProduct: '',
    modalData: [],
    calledPriceSummaryWrapper: {}
  };

  @track crumbs = [
    {
      label: this.labels.pmc_breadcrumb_homepage,
      url: `${basePath}/`,
      isActive: false
    },
    {
      label: this.labels.pmc_orderHistory_myOrderHistory,
      url: `${basePath}/orders`,
      isActive: false
    },
    { label: ``, url: "", isActive: true }
  ];

  @track stepsData = [
    {
      title: this.labels.pmc_orderHistory_requested,
      status: "",
      complete: true
    },
    {
      title: this.labels.pmc_orderHistory_confirmed,
      status: "",
      complete: false
    }
  ];

  @track orderDetails = {};
  @track orderLineItems = [];
  @track iconUrlObj = {
    mosaicLogoUrl: `${PMC_BrandingAssetsStaticResource}/images/logo-mosaic.png`,
    infoIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-info.svg`
  };

  @track cartItemObj = [];
  @track tempData = [];
  isStepperText = true;
  isLocationBrazil = false;
  isProductRedirected = DisableAddtoOrder;
  isBuyerOrSuperBuyer = !DisableAddtoOrder;
  isContractHidden = Hide_Contract;
  orderDetailsPageTitle = "";
  orderDetailsMessageBanner = "";
  communityId;
  effectiveAccountId;
  orderId;
  activeCartId;
  pageLoaded = false;
  pageRendered = false;
  isReorderModal = false;
  isCallPriceModal = false;
  isContractNotAvail = false;
  messageBannerType = "info";
  orderLineId = "";
  isOrderDetailView = true;
  isOrderLineDetailView = false;
  isCreateCaseEnabled = false;
  isReorderDisabled = false;
  isDeliveryTracking = false;
  selectedOrderLineNumber = "";
  vehicleId = "";
  isSpinner = false;
  isEditDateAndQuantityAllowed = false;
  brRequestedOrderData;
  queryString = window.location.search;
  todayDate;
  minRequestedShipmentDate;
  maxRequestedShipmentDate;
  orderNum = '';
  isUnauthorizedAccess = false;
  isPackageFieldVisible = false;
  qtyMaxLength;
  qtyPattern;
  strLstRequestIds = null;

  get steps() {
    return this.stepsData;
  }

  get getStrCustomerName() {
    return this.orderDetails?.orderSummaryWrapper?.strCustomerName;
  }
  get getStrOrderPlacedBy() {
    return this.orderDetails?.orderSummaryWrapper?.strOrderPlacedBy;
  }
  get getStrRequestIds() {
    return this.isLocationBrazil && this.orderDetails?.orderSummaryWrapper?.lstRequestNo;
  }
  get getStrProtocolNo() {
    return this.isLocationBrazil && this.orderDetails?.orderSummaryWrapper?.strProtocolNo;
  }
  get getStrSalesChannel() {
    return this.isLocationBrazil && this.orderDetails?.orderSummaryWrapper?.strSalesChannel;
  }
  get getDatDatePlaced() {
    return this.orderDetails?.orderSummaryWrapper?.datDatePlaced;
  }

  /**
   * Gets orderId from query params
   * @function queryParamsHandler
   * @param {boolean} reload 
   */
  queryParamsHandler(reload) {
    if (this.queryString) {
      let params = new URLSearchParams(this.queryString);
      let startURLTemp = params.get("orderId");
      if (startURLTemp) {
        this.orderId = startURLTemp;
        this.fetchOrderDetails(this.orderId, reload);
      }
      else {
        this.fetchOrderDetails()
      }
    }
    else {
      this.fetchOrderDetails()
    }
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    let that = this;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.intervalId = setInterval(() => {
      if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
        this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
        clearInterval(that.intervalId);
        this.queryParamsHandler(false);
      }
    }, 100);
    if (isBrazilRegion()) {
      this.isLocationBrazil = true;
    }
  }

  /** 
   * Change title of order details page when focusing on tab
   * @function setTitle
   */
  setTitle() {
    document.title = this.orderDetails.strOrderStatus ? (this.orderDetails.strOrderStatus === this.labels.pmc_orderHistory_requested ? `${this.labels.pmc_orderDetails_order}: ${this.orderDetails.strWebReferenceNumber}` : `${this.labels.pmc_orderDetails_order}: ${this.orderDetails.strOrderNumber}`) : document.title;
  }

  /** 
   * Opens create case modal
   * @function openCreateCaseModal
   */
  openCreateCaseModal() {
    this.isCreateCaseEnabled = !this.isCreateCaseEnabled;
  }

  /**
   * Get order details
   * @function fetchOrderDetails
   * @param {string} orderId
   * @param {boolean} reload
   */
  fetchOrderDetails(orderId, reload = false) {
    this.communityId = communityId;
    let LS = localStorage;
    if (LS.getItem("BR_REQUESTED_ORDER")) {
      let strOrderItemsDecryption = LS.getItem("BR_REQUESTED_ORDER");
      this.brRequestedOrderData = strOrderItemsDecryption;
    }
    this.isSpinner = true;
    if (sessionStorage.getItem("ORDER_STATUS") === REQUESTED) {
      getBRRequestedOrderDetails({
        strCommunityId: this.communityId,
        strEffectiveAccountId: this.effectiveAccountId,
        responseDetails: this.brRequestedOrderData
      }).then((data) => {
        if (data && Object.keys(data).length) {
          if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusCode && JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusCode === '999') {
            this.isUnauthorizedAccess = true;
            this.isSpinner = false;
            return;
          }
          else if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
          }
          this.orderDetails = JSON.parse(JSON.stringify(data));
          if (!this.isObjectEmpty(this.orderDetails)) {
            window.onblur = this.setTitle.bind(this);
            window.onfocus = this.setTitle.bind(this);
            if (this.isBuyerOrSuperBuyer) {
              this.isEditDateAndQuantityAllowed = true
            }
            this.updateOrderDetails();
            this.crumbs = this.crumbs.map((breadcrumb, indx) => {
              if (indx === 2) {
                breadcrumb.label = this.orderDetails.strOrderStatus === this.labels.pmc_orderHistory_requested ? `${this.labels.pmc_orderDetails_request} ${this.orderDetails.strWebReferenceNumber}` : `${this.labels.pmc_orderDetails_order} ${this.orderDetails.strOrderNumber}`
                this.orderDetailsPageTitle = breadcrumb.label;
              }
              return breadcrumb;
            });
            this.orderNum = this.orderDetails.strOrderStatus === this.labels.pmc_orderHistory_requested ? this.orderDetails.strWebReferenceNumber : this.orderDetails.strOrderNumber;
            this.orderDetailsMessageBanner = this.orderDetails.strOrderStatus === this.labels.pmc_orderHistory_requested ? this.labels.pmc_orderDetails_confirmationMsg : this.labels.pmc_orderDetails_confirmedMessage;
            this.isOrderStatusRequested = this.orderDetails.strOrderStatus === this.labels.pmc_orderHistory_requested ? true : false;
            this.stepChangeHandler();
          }
        }
        this.pageLoaded = true;
        this.isSpinner = false;
      }).catch(() => {
        toastMessageHandler()
        this.pageRendered = true;
        this.pageLoaded = true;
        this.isSpinner = false;
      })
    } else {
      getOrderDetails({
        strCommunityId: this.communityId,
        strEffectiveAccountId: this.effectiveAccountId,
        strOrderId: orderId
      }).then((data) => {
        if (data && Object.keys(data).length) {
          if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusCode && JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusCode === '999') {
            this.isUnauthorizedAccess = true;
            this.isSpinner = false;
            return;
          }
          else if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
          }
          this.orderDetails = JSON.parse(JSON.stringify(data));
          if (!this.isObjectEmpty(this.orderDetails)) {
            window.onblur = this.setTitle.bind(this);
            window.onfocus = this.setTitle.bind(this);
            this.updateOrderDetails();
            this.crumbs = this.crumbs.map((breadcrumb, indx) => {
              if (indx === 2) {
                breadcrumb.label = this.orderDetails.strOrderStatus === this.labels.pmc_orderHistory_requested ? `${this.labels.pmc_orderDetails_request} ${this.orderDetails.strWebReferenceNumber}` : `${this.labels.pmc_orderDetails_order} ${this.orderDetails.strOrderNumber}`
                this.orderDetailsPageTitle = breadcrumb.label;
              }
              return breadcrumb;
            });
            this.orderNum = this.orderDetails.strOrderStatus === this.labels.pmc_orderHistory_requested ? this.orderDetails.strWebReferenceNumber : this.orderDetails.strOrderNumber;
            this.orderDetailsMessageBanner = this.orderDetails.strOrderStatus === this.labels.pmc_orderHistory_requested ? this.labels.pmc_orderDetails_confirmationMsg : this.labels.pmc_orderDetails_confirmedMessage;
            this.isOrderStatusRequested = this.orderDetails.strOrderStatus === this.labels.pmc_orderHistory_requested ? true : false;
            this.stepChangeHandler();
            if (!this.isBuyerOrSuperBuyer || this.orderDetails.contractInfoWrapper?.strContractStatus !== this.labels.pmc_orderDetails_active) {
              this.isReorderDisabled = true;
            }
            if (reload && !this.isOrderStatusRequested && !this.isLocationBrazil && this.orderDetails?.contractInfoWrapper?.strContractType === CONTRACT_STATUS_FPD) {
              this.buildCallPriceDetails();
            }
          }
          let params = new URLSearchParams(window.location.search);
          this.orderLineId = params.get('orderLineId');
          this.vehicleId = params.get('vehicleId');
          if (this.vehicleId) {
            this.landToDeliveryTrackingView(params.get('orderLineNumber'));
          } else if (this.orderLineId) {
            this.landToOrderLineDetailsView(this.orderLineId);
          }
        }
        this.pageLoaded = true;
        this.isSpinner = false;
      }).catch(() => {
        toastMessageHandler();
        this.pageRendered = true;
        this.pageLoaded = true;
        this.isSpinner = false;
      });
    }
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) {
      return;
    }
    if (this.pageLoaded) {
      if (this.orderDetails?.orderSummaryWrapper?.lstRequestNo) {
        this.orderDetails?.orderSummaryWrapper?.lstRequestNo.forEach(id => {
          if (this.strLstRequestIds === null) {
            this.strLstRequestIds = id;
          }
          else {
            this.strLstRequestIds = `${this.strLstRequestIds}, ${id}`;
          }
        })
      }
      if (!this.isOrderStatusRequested && !this.isLocationBrazil && this.orderDetails?.contractInfoWrapper?.strContractType === CONTRACT_STATUS_FPD) {
        this.buildCallPriceDetails();
      }
      this.pageRendered = true;
    }
  }


  /**
   * Lands to order line details
   * @function landToOrderLineDetailsView
   * @param {string} lineId 
   */
  landToOrderLineDetailsView(lineId) {
    this.isOrderDetailView = false;
    this.isOrderLineDetailView = true;
    this.isDeliveryTracking = false;
    this.orderLineItems = [];
    this.orderDetails.productInfoWrapper.forEach(product => {
      product.lstShipmentItems?.forEach((item) => {
        item.lstOrderLines?.forEach((plan) => {
          this.orderLineItems.push({ strOrderItemId: plan.strOrderItemId, strOrderItemNumber: plan.strOrderItemNumber })
        })
      });
    })
    this.orderLineId = lineId;
  }

  /**
   * Check if the object is empty or not
   * @function isObjectEmpty
   * @param {object} objectName
   * @returns boolean
   */
  isObjectEmpty = (objectName) => {
    return (
      !objectName || (objectName &&
        Object.keys(objectName).length === 0 &&
        objectName.constructor === Object) || (objectName && (Object.values(objectName)?.every(val => (val === '' || val === 'TBD'))))
    );
  };

  /**
   * Format order details data
   * @function updateOrderDetails
   */
  updateOrderDetails() {
    if (!this.isObjectEmpty(this.orderDetails.contractInfoWrapper)) {
      this.orderDetails.contractInfoWrapper.datContractStartDate = this.orderDetails.contractInfoWrapper.datContractStartDate ? formatDate(
        this.orderDetails.contractInfoWrapper.datContractStartDate) : ""
        ;
      this.orderDetails.contractInfoWrapper.datContractEndDate = this.orderDetails.contractInfoWrapper.datContractEndDate ? formatDate(
        this.orderDetails.contractInfoWrapper.datContractEndDate
      ) : "";
      this.orderDetails.contractInfoWrapper.validityPeriod =
        this.orderDetails.contractInfoWrapper.datContractStartDate &&
          this.orderDetails.contractInfoWrapper.datContractEndDate
          ? this.orderDetails.contractInfoWrapper.datContractStartDate +
          "-" +
          this.orderDetails.contractInfoWrapper.datContractEndDate
          : "";
    } else {
      this.isContractNotAvail = true;
      this.orderDetails.contractInfoWrapper = {
        strContractNumber: 'TBD',
        strPoNumber: 'TBD',
        validityPeriod: 'TBD',
        strContractType: 'TBD',
        strPaymentTerms: 'TBD'
      };
    }
    if (!this.isObjectEmpty(this.orderDetails.orderSummaryWrapper)) {
      this.orderDetails.orderSummaryWrapper.datDatePlaced = this.orderDetails.orderSummaryWrapper.datDatePlaced ? formatDate(
        this.orderDetails.orderSummaryWrapper.datDatePlaced
      ) : "";
      this.orderDetails.orderSummaryWrapper.strSummaryStatus =
        this.orderDetails.orderSummaryWrapper.strSummaryStatus ===
          ORDER_STATUS.DRAFT
          ? this.labels.pmc_orderDetails_statusPlaced
          : this.orderDetails.orderSummaryWrapper.strSummaryStatus;
      if ([this.labels.pmc_orderDetails_statusPlaced, this.labels.PMC_DH_InProgress, this.labels.PMC_DH_StatusHold].includes(this.orderDetails.orderSummaryWrapper.strSummaryStatus)) {
        this.orderDetails.orderSummaryWrapper.strSummaryBadgeStatus = BADGE_STATUS_WARNING;
      }
      else if (this.orderDetails.orderSummaryWrapper.strSummaryStatus === PMC_DH_Cancelled) {
        this.orderDetails.orderSummaryWrapper.strSummaryBadgeStatus = BADGE_STATUS_ERROR;
      }
    }
    this.isPackageFieldVisible = this.orderDetails.boolVCOFlag;
    this.orderDetails.productInfoWrapper?.forEach((prod) => {
      prod.pdpUrl = `${basePath}/product/${prod.strProductId}`;
      prod.intRequestedQty = prod.intRequestedQty ? Math.round(prod.intRequestedQty * 100) / 100 : prod.intRequestedQty;
      prod.intConfirmedQty = prod.intConfirmedQty ? Math.round(prod.intConfirmedQty * 100) / 100 : prod.intConfirmedQty;
      prod.lstShipmentItems?.forEach((item) => {
        item.lstShipmentPlan?.forEach((plan) => {
          if (this.isLocationBrazil) {
            plan.strSalesOrder = plan.strSalesOrder === "" ? this.labels.pmc_fpd_pending : plan.strSalesOrder;
          }
          plan.intRequestedQty = plan.intRequestedQty ? Math.round(plan.intRequestedQty * 100) / 100 : plan.intRequestedQty;
          plan.intConfirmedQty = plan.intConfirmedQty ? Math.round(plan.intConfirmedQty * 100) / 100 : plan.intConfirmedQty;
          plan.strFormattedRequestedShipmentDate = plan.strRequestedShipmentDate ? formatDate(plan.strRequestedShipmentDate) : "";
          this.showDateWarning(plan.strRequestedShipmentDate);
          if (this.isEditDateAndQuantityAllowed) {
            plan.isEditDateAndQuantityDisabled = true;
            this.todayDate = new Date().toISOString().slice(0, 10);
            this.minRequestedShipmentDate = this.todayDate; 
            this.maxRequestedShipmentDate = '';
          }

        })
      });
      prod.lstShipmentItems?.forEach((item) => {
                  /*GSMD-1867*/
        if(item.lstOrderLines && Array.isArray(item.lstOrderLines)){
          item.lstOrderLines.sort((a,b) => {
            const lineA = a.strSapOrderLine || '';
            const lineB = b.strSapOrderLine || '';
            return lineA.localeCompare(lineB, undefined,{ numeric : true});
          });
        /*GSMD-1867*/
        item.lstOrderLines?.forEach((plan) => {
          plan.strOrderItemNumber = plan.strOrderItemNumber ? plan.strOrderItemNumber.padStart(2, '0') : "-";
          plan.strSapOrderLine = plan.strSapOrderLine ? plan.strSapOrderLine: ""; // GSMD-1867
          plan.datRequestedShipmentDate = plan.datRequestedShipmentDate ? formatDate(plan.datRequestedShipmentDate) : "";
          plan.strPendingQuantity = plan.strPendingQuantity ? Math.round(plan.strPendingQuantity * 1000) / 1000 : "-";
          plan.strShippedQuantity = plan.strShippedQuantity ? Math.round(plan.strShippedQuantity * 1000) / 1000 : "-";
          plan.strDeliverQuantity = plan.strDeliverQuantity ? Math.round(plan.strDeliverQuantity * 1000) / 1000 : "-";
          if ([this.labels.pmc_orderDetails_statusPlaced, this.labels.PMC_DH_InProgress].includes(plan.strDeliveryStatus)) {
            plan.strOrderLineBadgeStatus = BADGE_STATUS_WARNING;
          }
          else if (plan.strDeliveryStatus === PMC_DH_Cancelled) {
            plan.strOrderLineBadgeStatus = BADGE_STATUS_ERROR;
          }
        })
        }
      });
    });
  }

  /** 
   * Stepper Logic 
   * @function stepChangeHandler
   */
  stepChangeHandler() {
    const matchedStep = this.stepsData.find(
      (step) => step.title === this.orderDetails.strOrderStatus
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
   * Navigate to Contract Details Page
   * @function navigateToContractDetails
   */
  navigateToContractDetails() {
    if (
      !this.isObjectEmpty(this.orderDetails) &&
      !this.isObjectEmpty(this.orderDetails.contractInfoWrapper)
    ) {
      let url = `/contracts/contract-details?contractId=${this.orderDetails.contractInfoWrapper.strContractId}`;
      this[NavigationMixin.GenerateUrl]({
        type: "standard__webPage",
        attributes: {
          url: `${basePath}${url}`
        }
      }).then((generatedUrl) => {
        urlRedirect(generatedUrl);
      });
    }
  }

  /**
   * Fetches active cart Id
   * @function fetchActiveCartId
   */
  fetchActiveCartId() {
    this.pageLoaded = false;
    this.isSpinner = true;
    getActiveCartId({
      strEffectiveAccountId: this.effectiveAccountId,
      strCommunityId: this.communityId
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
   * Adds shipment info and redirects to RTD flow
   * @function addshipmentInfo
   * @param {string} cartId 
   */
  addshipmentInfo(cartId) {
    let cartObj = {
      strCommunityId: this.communityId,
      strEffectiveAccountId: this.effectiveAccountId,
      strOrderId: this.orderId,
      strCartId: cartId,
      strContractId: this.orderDetails.contractInfoWrapper?.strContractId
    }
    reorderFromOrderDetails({
      objReorderDetailsWrapper: cartObj
    }).then((response) => {
      if (response && Object.keys(response).length) {
        if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
        }
        if (response.strStatusCode === "000") {
          this.validateCart(cartId);
        }
      }
    }).catch(() => {
      toastMessageHandler();
    })
  }

  /**
   * Cart page validation
   * @function validateCart
   * @param {string} cartId 
   */
  validateCart(cartId) {
    let targetUrl = '';
    validateCart({
      strCartId: cartId
    })
      .then((data) => {
        if (data && Object.keys(data).length) {
          if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
          }
          if (data.boolHasErrors || data.boolHasWarnings) {
            targetUrl = '/cart';
            sessionStorage.setItem('CART_VALIDATION_ERROR', true);
          } else {
            targetUrl = '/checkout';
            sessionStorage.setItem("CONTRACT_ID", this.orderDetails.contractInfoWrapper?.strContractId);
            sessionStorage.setItem("CART_ID", cartId);
            sessionStorage.setItem("CHECKOUT_FLAG", SOURCE_RTD);
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
      });
  }

  /**
   * Method to redirect to ShipmentInfoPage on Reorder Products button click
   * @function handleReorderProducts
   */
  handleReorderProducts() {
    this.fetchActiveCartId();
  }

  /**
   * Reorder Modal open handler
   * @function openReorderModalHandler
   */
  openReorderModalHandler() {
    this.isReorderModal = true;
  }

  /**
   * Reorder Modal close handler
   * @function handleCloseReorderModal
   */
  handleCloseReorderModal() {
    this.isReorderModal = false;
  }

  /**
   * Call Price Modal open handler
   * @function openCallPriceModalHandler
   */
  openCallPriceModalHandler() {
    this.isCallPriceModal = true;
    this.buildCallPriceModalDetails();
  }

  /**
   * Reorder Modal close handler
   * @function handleCloseCallPriceModal
   */
  handleCloseCallPriceModal() {
    this.isCallPriceModal = false;
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
   * Create Case Modal close handler
   * @function closeCreateCaseModal
   * @param {Event} event 
   */
  closeCreateCaseModal(event) {
    this.isCreateCaseEnabled = event.detail.value;
  }

  /**
   * Navigate to Order Line Details Page
   * @function navigateToOrderLineDetails
   * @param {Event} event 
   */
  navigateToOrderLineDetails(event) {
    const urlParams = new URLSearchParams(window.location.search);
    urlParams.set('orderLineId', event.target.dataset.id);
    window.location.search = urlParams;
    this.isOrderDetailView = false;
    this.isOrderLineDetailView = true;
    this.isDeliveryTracking = false;
    this.orderLineItems = [];
    this.orderDetails.productInfoWrapper.forEach(product => {
      product.lstShipmentItems?.forEach((item) => {
        item.lstOrderLines?.forEach((plan) => {
          this.orderLineItems.push({ strOrderItemId: plan.strOrderItemId, strOrderItemNumber: plan.strOrderItemNumber })
        })
      });
    })
    this.orderLineId = event.target.dataset.id;
  }

  /**
   * Navigate to Order Details Page
   * @function landToOrderDetailsView
   */
  landToOrderDetailsView() {
    this.isOrderDetailView = true;
    this.isOrderLineDetailView = false;
    this.isDeliveryTracking = false;
    this.queryParamsHandler(true);
  }

  /**
   * Arranging the call price obj
   * @function buildCallPriceDetails
   */
  buildCallPriceDetails() {
    this.today = new Date(getTodayDate());
    this.callPriceObj.isCallPrice = true;
    this.callPriceObj.isCallPriceBtn = !DisableAddtoOrder;
    let callPriceEnabled = false;
    let isCallPriceRequestedBySystem = true;
    this.template.querySelectorAll(`.grouping-section .slds-col`).forEach((col) => {
      col.classList.add('slds-size_1-of-8');
    });
    this.callPriceObj.productList = [...this.orderDetails.productInfoWrapper].map((product) => {
      return { label: product.strProductName, value: product.strProductId };
    });
    this.buildCallPriceSummaryWrapper();
    this.orderDetails?.productInfoWrapper?.forEach((product) => {
      product.lstShipmentItems?.forEach((item) => {
        item.lstOrderLines?.forEach((plan) => {
          if (!plan.boolCallPriceRequestedBySystem) {
            isCallPriceRequestedBySystem = false;
          }
          if (plan.boolCustomerCallPriceDate && plan.boolAMFPDPrice) {
            plan.callPriceStatus = this.labels.pmc_fpd_priced;
            plan.isPriceCalledOrPending = true;
            plan.formattedCallPriceDate = "-";
          }
          else if (plan.boolCustomerCallPriceDate || plan.boolAMFPDPrice) {
            plan.callPriceStatus = this.labels.pmc_fpd_pending;
            plan.callPriceBadgeStatus = BADGE_STATUS_WARNING;
            plan.formattedCallPriceDate = plan?.datCallPriceDate ? formatDate(plan?.datCallPriceDate) : '';
            plan.isPriceCalledOrPending = true;
          }
          else {
            plan.callPriceStatus = this.labels.pmc_fpd_unpriced;
            plan.callPriceBadgeStatus = BADGE_STATUS_ERROR;
            plan.formattedCallPriceDate = plan?.datCallPriceDate ? formatDate(plan?.datCallPriceDate) : '';
            plan.isPriceCalledOrPending = false;
          }
          let callDate = new Date(plan?.datCallPriceDate);
          if ((callDate >= this.today) && !plan?.isPriceCalledOrPending) {
            callPriceEnabled = true;
          }
        })
      })
    });
    if (!callPriceEnabled) {
      this.callPriceObj.isBtnDisabled = true;
      if (!isCallPriceRequestedBySystem) {
        this.callPriceObj.btnLabel = pmc_fpd_callPriceRequested
      }
    }
  }

  /**
   * Building the call price modal details
   * @function buildCallPriceModalDetails
   */
  buildCallPriceModalDetails() {
    this.callPriceObj.modalData = [...this.orderDetails.productInfoWrapper].map((product) => {
      return { id: product.strProductId, isSelected: false, isOrderLines: false, orderLinesData: [] };
    });
    this.callPriceObj.isModalCTADisabled = true;
    this.callPriceObj.selectedProduct = this.callPriceObj?.productList[0]?.value;
    this.callPriceObj.modalData.forEach((product) => {
      if (product.id === this.callPriceObj.selectedProduct) {
        product.isSelected = true;
      }
      product.radioBtnOptions = [
        { id: 'radio-1', checked: false, label: pmc_fpd_callPriceForTotalQty, disabled: false },
        { id: 'radio-2', checked: false, label: pmc_fpd_callPriceSpecificLine, disabled: false }
      ];
      const PRODUCT = this.orderDetails?.productInfoWrapper?.find((prod) => prod.strProductId === product.id);
      PRODUCT.lstShipmentItems?.forEach((item) => {
        item.lstOrderLines?.forEach((plan) => {
          let obj = {
            OrderLine: `${this.labels.pmc_shipmentDetails_orderLineNumber} #${plan.strOrderItemNumber}`,
            ShipToAddress: item.wrpShipTo.label,
            ShipmentDate: plan.datRequestedShipmentDate,
            CallDate: plan.formattedCallPriceDate,
            Quantity: plan.strPendingQuantity,
            Checkbox: false,
            isPriceCalledOrPending: plan.isPriceCalledOrPending,
            strOrderItemId: plan.strOrderItemId
          };
          product.orderLinesData.push(obj);
        })
      });
      let isAllOrdersDisabled = true;
      product.orderLinesData.forEach((plan, index) => {
        plan.Id = index;
        let isPastDate = false;
        let callDate = new Date(plan.datCallPriceDate);
        if (this.today > callDate) {
          isPastDate = true
        }
        if (plan.isPriceCalledOrPending || isPastDate) {
          plan.isDisabled = true;
          product.radioBtnOptions[0].disabled = true;
        }
        else {
          isAllOrdersDisabled = false
        }
      });
      product.radioBtnOptions[1].disabled = isAllOrdersDisabled;
    })
  }

  /**
   * Building the call price summary wrapper
   * @function buildCallPriceSummaryWrapper
   */
  buildCallPriceSummaryWrapper() {
    this.callPriceObj.calledPriceSummaryWrapper.strCurrencyISOCode = this.orderDetails.orderSummaryWrapper.strCurrencyIsoCode;
    this.callPriceObj.calledPriceSummaryWrapper.productWrapper = [];
    this.orderDetails?.productInfoWrapper?.forEach((prod) => {
      let prodOBj = {
        strprodId: prod.strProductId,
        strprodName: prod.strProductName,
        strunpricedQty: prod.intTotalUnpricedQty,
        strpricedQty: prod.intTotalPricedQty,
        lstOrderLineData: []
      };
      prod.lstShipmentItems?.forEach((item) => {
        item.lstOrderLines?.forEach((plan) => {
          let obj = {
            strOrderId: plan.strOrderItemId,
            strOrderLineNo: `${this.labels.pmc_shipmentDetails_orderLineNumber}#${plan.strOrderItemNumber}`,
            strVolume: plan.strTotalQuantity,
            strPricePerTon: plan.strPricePerTon,
            strTotalPrice: plan.strTotalPrice,
            strUOM: plan.strUnitOfMeasure
          };
          prodOBj.lstOrderLineData.push(obj);
        })
      });
      this.callPriceObj.calledPriceSummaryWrapper.productWrapper.push(prodOBj);
    });
  }

  /**
   * On change of call price product
   * @function handleCallPriceProductChange
   * @param {Event} event 
   */
  handleCallPriceProductChange(event) {
    this.callPriceObj.selectedProduct = event.detail.value;
    this.callPriceObj.modalData.forEach((product) => {
      if (product.id === event.detail.value) {
        product.isSelected = true
      }
      else {
        product.isSelected = false
      }
    })
  }

  /**
   * On change of call price radio button
   * @function handleCallPriceRadioOptionChange
   * @param {Event} event 
   */
  handleCallPriceRadioOptionChange(event) {
    const PRODUCT = this.callPriceObj.modalData?.find((prod) => prod.id === this.callPriceObj.selectedProduct);
    PRODUCT.radioBtnOptions.forEach((btn) => {
      if (btn.id === event.target.dataset.id) {
        btn.checked = true;
      }
      else {
        btn.checked = false;
      }
      if (event.target.dataset.id === 'radio-2') {
        PRODUCT.isOrderLines = true;
        this.checkIfCallPriceModalCTADisabled();
      }
      else {
        PRODUCT.isOrderLines = false;
        PRODUCT.orderLinesData.forEach((record) => {
          record.Checkbox = false;
        })
        this.callPriceObj.isModalCTADisabled = false;
      }
    })
  }

  /**
   * On change of call price checkbox 
   * @function handleCallPriceCheckboxChange
   * @param {Event} event 
   */
  handleCallPriceCheckboxChange(event) {
    const PRODUCT = this.callPriceObj.modalData?.find((prod) => prod.id === this.callPriceObj.selectedProduct);
    PRODUCT.orderLinesData.forEach((plan) => {
      if (plan.Id === +event.detail.id) {
        plan.Checkbox = !plan.Checkbox
      }
    });
    this.checkIfCallPriceModalCTADisabled();
  }

  /**
   * Checking if call price button on call price modal is disabled 
   * @function checkIfCallPriceModalCTADisabled
   */
  checkIfCallPriceModalCTADisabled() {
    this.callPriceObj.isModalCTADisabled = true;
    this.callPriceObj.modalData.forEach((product) => {
      if (product.radioBtnOptions[0].checked) {
        this.callPriceObj.isModalCTADisabled = false;
        return
      }
      product.orderLinesData.forEach((plan) => {
        if (plan.Checkbox) {
          this.callPriceObj.isModalCTADisabled = false;
        }
      })
    })
  }

  /**
   * on click of call price button on call price modal 
   * @function callPriceNowHandler
   */
  callPriceNowHandler() {
    let lstOrderItemIDs = [];
    this.callPriceObj.modalData.forEach((product) => {
      if (product.radioBtnOptions[0].checked) {
        product.orderLinesData.forEach((plan) => {
          lstOrderItemIDs.push(plan.strOrderItemId)
        })
      }
      else if (product.radioBtnOptions[1].checked) {
        product.orderLinesData.forEach((plan) => {
          if (plan.Checkbox) {
            lstOrderItemIDs.push(plan.strOrderItemId);
          }
        })
      }
    });
    this.updateCustomerCallPriceDate(lstOrderItemIDs);
    this.handleCloseCallPriceModal();
  }

  /**
   * upadting call price date in BE 
   * @function callPriceNowHandler
   * @param {string} lstOrderItemIDs 
   */
  updateCustomerCallPriceDate(lstOrderItemIDs) {
    this.isSpinner = true;
    updateCustomerCallPriceDate({
      lstOrderItemIDs: lstOrderItemIDs,
      boolIsCustomerRequested: true
    })
      .then((responseString) => {
        if (responseString && Object.keys(responseString).length) {
          if (JSON.parse(JSON.stringify(responseString)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(responseString)).strStatusMessage)
          }
          const response = JSON.parse(JSON.stringify(responseString));
          if (response.strStatusCode === '000') {
            window.location.reload();
          }
          else if (response.strStatusCode === '100') {
            this.error = handleError(response.strStatusMessage);
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
   * Navigates to delivery tracking page
   * @function navigateToDeliveryTracking
   * @param {Event} event 
   */
  navigateToDeliveryTracking(event) {
    this.isSpinner = true;
    const urlParams = new URLSearchParams(window.location.search);
    urlParams.set('vehicleId', event.detail.vehicleId);
    urlParams.set('orderLineNumber', event.detail.orderLineNum);
    this.selectedOrderLineNumber = event.detail.orderLineNum;
    this.vehicleId = event.detail.vehicleId;
    window.location.search = urlParams;
  }

  /**
   * Lands on delivery tracking page
   * @function landToDeliveryTrackingView
   * @param {string} orderLineNum 
   */
  landToDeliveryTrackingView(orderLineNum) {
    this.selectedOrderLineNumber = orderLineNum;
    this.isOrderDetailView = false;
    this.isOrderLineDetailView = false;
    this.isDeliveryTracking = true;
  }

  /**
   * On click of edit button 
   * @function handleEditInfo
   * @param {Event} event 
   */
  handleEditInfo(event) {
    let index1 = event.target.dataset.productIndex;
    let index2 = event.target.dataset.shipmentIndex;
    let index3 = event.target.dataset.planIndex;
    this.orderDetails.productInfoWrapper[index1].lstShipmentItems[index2].lstShipmentPlan[index3].isEditDateAndQuantityDisabled =
      !this.orderDetails.productInfoWrapper[index1].lstShipmentItems[index2].lstShipmentPlan[index3].isEditDateAndQuantityDisabled;
    this.tempData = JSON.parse(JSON.stringify(this.orderDetails.productInfoWrapper));
  }

  /**
   * On click of cancel edit button 
   * @function handleCloseEdit
   * @param {Event} event 
   */
  handleCloseEdit(event) {
    let index1 = parseInt(event.target.dataset.productIndex, 10);
    let index2 = parseInt(event.target.dataset.shipmentIndex, 10);
    let index3 = parseInt(event.target.dataset.planIndex, 10);
    this.orderDetails.productInfoWrapper = JSON.parse(JSON.stringify(this.tempData));
    this.orderDetails.productInfoWrapper[index1].lstShipmentItems[index2].lstShipmentPlan[index3].isEditDateAndQuantityDisabled =
      !this.orderDetails.productInfoWrapper[index1].lstShipmentItems[index2].lstShipmentPlan[index3].isEditDateAndQuantityDisabled;
    const plan = this.orderDetails.productInfoWrapper[index1].lstShipmentItems[index2].lstShipmentPlan[index3];
    this.validateAvailableQuantity(index1, index2, index3, parseFloat(plan.intRequestedQty, 10));
  }

  /**
   * On click of save changes button 
   * @function handleSaveEditInfo
   * @param {Event} event 
   */
  handleSaveEditInfo(event) {
    console.log('>>>handleSaveEditInfo', event);
    let index1 = event.target.dataset.productIndex;
    let index2 = event.target.dataset.shipmentIndex;
    let index3 = event.target.dataset.planIndex;
    if (this.checkRequestedDateError(index1, index2, index3) || this.handleErrorOnSave(index1, index2, index3)) return;
    const plan = this.orderDetails.productInfoWrapper[index1].lstShipmentItems[index2].lstShipmentPlan[index3];
    this.saveUpdatedOrderDetails(plan.strOrderItemId, plan.intRequestedQty, plan.strRequestedShipmentDate);
  }

  /**
   * Saving changes to BE 
   * @function saveUpdatedOrderDetails
   * @param {string} orderItemId
   * @param {string} requestedQty
   * @param {date} requestedShipmentDate
   */
  saveUpdatedOrderDetails(orderItemId, requestedQty, requestedShipmentDate) {
    console.log('>>>saveUpdatedOrderDetails', orderItemId, requestedQty, requestedShipmentDate);
    this.isSpinner = true;
    let wrapper = { responseData: this.brRequestedOrderData, strOrderLineId: orderItemId, strReqQty: requestedQty, strReqShipmentDate: requestedShipmentDate };
    let LS = localStorage;
    saveUpdatedOrderDetails({
      editRequestWrapper: wrapper
    }).then((data) => {
      if (data && Object.keys(data).length) {
        if (JSON.parse(data).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(data).statusCodeMessage.strStatusMessage)
        }
        if (JSON.parse(data).strMessage === 'Success') {
          let responseData = JSON.parse(this.brRequestedOrderData);
          responseData.lstData.forEach((item) => {
            if (item.strReqId === orderItemId) {
              item.strReqDelDate = requestedShipmentDate;
              item.strRequestQty = requestedQty;
            }
          })
          this.brRequestedOrderData = JSON.stringify(responseData);
          LS.setItem("BR_REQUESTED_ORDER", this.brRequestedOrderData);
          window.location.reload();
        }
        if (JSON.parse(data).strMessage === 'Error') {
          toastMessageHandler(pmc_orderDetails_yourChangesNotSaved)
        }
        this.isSpinner = false;
      }
    }).catch(() => {
      toastMessageHandler();
      this.isSpinner = false;
    })
  }

  /**
   * On Blur of requesty quantity input field 
   * @function handleBlur
   * @param {event} event
   */
  handleBlur(event) {
    console.log('handleBlur', event);
    let index1 = event.target.dataset.productIndex;
    let index2 = event.target.dataset.shipmentIndex;
    const fieldToHighlight = 'intRequestedQty';
    const prod = this.orderDetails.productInfoWrapper[index1];
    const shipment = prod.lstShipmentItems[index2];
    shipment.lstShipmentPlan.forEach((plan, planIndex) => {
      if (!plan.isEditDateAndQuantityDisabled && plan.isAvailableQuantityError) {
        let element = this.template.querySelector(`[data-id="${fieldToHighlight}"][data-product-index="${index1}"][data-shipment-index="${index2}"][data-plan-index="${planIndex}"]`)
        element.reportErrorValidity()
      }
      else {
        let element = this.template.querySelector(`[data-id="${fieldToHighlight}"][data-product-index="${index1}"][data-shipment-index="${index2}"][data-plan-index="${planIndex}"]`)
        element.removeReportErrorValidity()
      }
    })
  }

  /**
   * On Data Change of editable fields 
   * @function handleDataChange
   * @param {event} event
   */
  handleDataChange(event) {
    console.log('handleDataChange', event);
    // Limiting charecter length to max of 10 charecters when a dot present in input field value.
    // if(event.detail.value?.includes(".")){
    //     let textLength = event.detail.value?.split(".")[0].length;
    //     if(textLength > 10){
    //       let productIndex = event.currentTarget.dataset.productIndex;
    //       let shipmentIndex = event.currentTarget.dataset.shipmentIndex;
    //       let planIndex = event.currentTarget.dataset.planIndex;
    //       this.orderDetails.productInfoWrapper[productIndex].lstShipmentItems[shipmentIndex].lstShipmentPlan[planIndex].intRequestedQty = this.rqCurrentValue;
    //       event.detail.value = this.rqCurrentValue;
    //       this.rqCurrentValue = null;
    //       return;
    //     }
    // }
    let index1 = parseInt(event.target.dataset.productIndex, 10);
    let index2 = parseInt(event.target.dataset.shipmentIndex, 10);
    let index3 = parseInt(event.target.dataset.planIndex, 10);
    const plan = this.orderDetails.productInfoWrapper[index1].lstShipmentItems[index2].lstShipmentPlan[index3];
    plan[event.target.dataset.id] = event.detail.value;
    if (event.target.dataset.id === 'intRequestedQty') {
      if (+event.detail.value) {
        if (event.detail.value.includes('.')) {
          this.qtyMaxLength = 13;
          this.qtyPattern = "^[0-9]{1,10}\.[0-9]{1,2}$";
        } else {
          this.qtyMaxLength = 10;
          this.qtyPattern = "^[0-9]*$";
        }
        this.validateAvailableQuantity(index1, index2, index3, parseFloat(event.detail.value, 10));
        plan.isSaveFieldsBtnDisabled = false;
      }
      else {
        plan.isSaveFieldsBtnDisabled = true
      }
    }

    console.log(`>>>`,event.target.dataset.id);

    if (event.target.dataset.id === 'strRequestedShipmentDate') {
      const inpDate = event.detail.value;
      const today = this.todayDate;
      const endDate = this.orderDetails?.contractInfoWrapper?.datContractEndDate
        ? unFormatDate(this.orderDetails.contractInfoWrapper.datContractEndDate)
        : '';

      plan.isRequestedShipmentDateError = !(inpDate && inpDate >= today);

      if (plan.isRequestedShipmentDateError) {
        plan.isSaveFieldsBtnDisabled = true;
      } else {
        plan.isSaveFieldsBtnDisabled = false;
      }

      plan.isValidityWarning = Boolean(endDate && inpDate > endDate);
    }
  }

  /**
   * On key press of Requested Qty field
   * @function handleOnKeyPress
   * @param {event} event
   */
  handleOnKeyPress(event) {
    if (this.qtyMaxLength === 10 && event.key === '.') {
      this.qtyMaxLength = 13;
      this.qtyPattern = "^[0-9]{1,10}\.[0-9]{1,2}$";
    }
    // this.rqCurrentValue = event.target.dataset.value;
  }

  /**
  * Validating if requested quantity is less than available quantity
  * @function validateAvailableQuantity
  * @param {string} indexProduct
  * @param {string} indexShipment
  * @param {string} indexPlan
  * @param {string} requestedQtyForPlan
  */
  validateAvailableQuantity(indexProduct, indexShipment, indexPlan, requestedQtyForPlan) {
    console.log('validateAvailableQuantity');
    const fieldToHighlight = 'intRequestedQty';
    const prod = this.orderDetails.productInfoWrapper[indexProduct];
    const shipment = prod.lstShipmentItems[indexShipment];
    let isThirdPartyOrder = this.orderDetails.boolVCOFlag;
    let totalAvailableQty = this.orderDetails.lstContractWrapper?.find(
      (contract) =>
      (((!isThirdPartyOrder && contract.strShipTo === shipment.wrpShipTo.value) || isThirdPartyOrder) &&
        contract.strDeliveryMode === shipment.strDeliveryMode &&
        contract.strShipFrom === shipment.wrpShipFrom.value &&
        contract.strSku === prod.strSku)
    )?.strAvailableQty;
    let requestedQty = 0;
    let totalAvailableQtyInt = parseFloat(totalAvailableQty, 10);
    shipment.lstShipmentPlan.forEach((plan, index) => {
      if (index !== indexPlan) {
        requestedQty = requestedQty + plan.intRequestedQty
      }
    });
    let availableQtyForPlan = +totalAvailableQtyInt - parseFloat(requestedQty, 10);
    if (requestedQtyForPlan > availableQtyForPlan) {
      shipment.lstShipmentPlan.forEach((plan) => {
        plan.isAvailableQuantityError = true;
        plan.isSaveFieldsBtnDisabled = true;
      });
      this.template.querySelectorAll(`[data-id="${fieldToHighlight}"][data-product-index="${indexProduct}"][data-shipment-index="${indexShipment}"]`).forEach((plan) => {
        plan.reportErrorValidity();
        plan.setCustomValidity("error");
      })
    }
    else {
      shipment.lstShipmentPlan.forEach((plan) => {
        plan.isAvailableQuantityError = false;
        plan.isSaveFieldsBtnDisabled = false;
      });
      this.template.querySelectorAll(`[data-id="${fieldToHighlight}"][data-product-index="${indexProduct}"][data-shipment-index="${indexShipment}"]`).forEach((plan) => {
        plan.removeReportErrorValidity();
      })
    }
  }

  /**
   * Validating editable input fields
   * @function handleErrorOnSave
   * @param {string} indexProduct
   * @param {string} indexShipment
   * @param {string} indexPlan
   */
  handleErrorOnSave(indexProduct, indexShipment, indexPlan) {
    console.log('handleErrorOnSave');
    let allValid = true;
    const fields = ['strRequestedShipmentDate', 'intRequestedQty'];
    fields?.forEach(field => {
      const element = this.template.querySelector(`[data-id="${field}"][data-product-index="${indexProduct}"][data-shipment-index="${indexShipment}"][data-plan-index="${indexPlan}"]`)
      if (!element.reportValidity()) {
        allValid = false;
      }
    });
    if (!allValid) {
      return true;
    }
    return false;
  }

  /**
   * Checking error on requested date input field
   * @function checkRequestedDateError
   * @param {string} indexProduct
   * @param {string} indexShipment
   * @param {string} indexPlan
   */
  checkRequestedDateError(indexProduct, indexShipment, indexPlan) {
    console.log('checkRequestedDateError');
    let isDuplicate = false;
    const prod = this.orderDetails.productInfoWrapper[indexProduct];
    const shipment = prod.lstShipmentItems[indexShipment];
    const plan = shipment.lstShipmentPlan[indexPlan];
    isDuplicate = prod.lstShipmentItems.some((el, indexShipment2) => {
      return el.lstShipmentPlan.some((item, indexPlan2) => {
        return (
          +indexShipment !== +indexShipment2 &&
          +indexPlan !== +indexPlan2 &&
          shipment.strDeliveryMode === el.strDeliveryMode &&
          shipment.wrpShipTo.value === el.wrpShipTo.value &&
          shipment.wrpShipFrom.value === el.wrpShipFrom.value &&
          plan.strRequestedShipmentDate === item.strRequestedShipmentDate
        )
      })
    })
    plan.isDuplicate = isDuplicate;
    prod.isDuplicateShippingInfo = isDuplicate;
    const fieldToHighlight = 'strRequestedShipmentDate';
    const element = this.template.querySelector(`[data-id="${fieldToHighlight}"][data-product-index="${indexProduct}"][data-shipment-index="${indexShipment}"][data-plan-index="${indexPlan}"]`);
    if (plan.isDuplicate) {
      element.reportErrorValidity();
    } else {
      element.removeReportErrorValidity()
    }
    if (plan.strRequestedShipmentDate && plan.strRequestedShipmentDate < this.todayDate) {
      plan.isRequestedShipmentDateError = true;
    } else {
      plan.isRequestedShipmentDateError = false;
    }
    return isDuplicate;
  }

  showDateWarning(selectedDate) {
    const minDate = this.minRequestedShipmentDate;
    const maxDate = this.maxRequestedShipmentDate;

    if (!selectedDate || !minDate || !maxDate) return;

    const selected = new Date(selectedDate);
    const min = new Date(minDate);
    const max = new Date(maxDate);

    if (selected < min || selected > max) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Attention',
                message:
                    'The selected date is beyond the contract validity period. Penalties may apply according to contractual terms.',
                variant: 'info',
                mode: 'dismissable'
            })
        );
    }
  }
}