import { LightningElement, track } from 'lwc';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { formatDate, toastMessageHandler } from "c/pmc_dh_utilityJs";
import basePath from '@salesforce/community/basePath';
import DisableAddtoOrder from '@salesforce/customPermission/DisableAddtoOrder';
import Hide_Contract from '@salesforce/customPermission/Hide_Contract';
import Quote_ViewOnlyAccess from '@salesforce/customPermission/Quote_ViewOnlyAccess';
import DisableRecentUpdateWdg from '@salesforce/customPermission/DisableRecentUpdateWdg';
import Finance_Manager from '@salesforce/customPermission/Finance_Manager';
import getActiveContracts from "@salesforce/apex/PMC_DH_HomePageController.getActiveContracts";
import getRecentQuotes from "@salesforce/apex/PMC_DH_HomePageController.getRecentQuotes";
import getOrdersInTransit from "@salesforce/apex/PMC_DH_HomePageController.getOrdersinTransit";
import getRecentUpdates from "@salesforce/apex/PMC_DH_HomePageController.fetchRecentUpdates";

import pmc_requestToDeliver_contractNumber from "@salesforce/label/c.pmc_requestToDeliver_contractNumber";
import pmc_contractDetails_availableQty from "@salesforce/label/c.pmc_contractDetails_availableQty";
import pmc_contractDetails_poNumber from "@salesforce/label/c.pmc_contractDetails_poNumber";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_quoteHistory_quoteNumber from "@salesforce/label/c.pmc_quoteHistory_quoteNumber";
import pmc_quoteDetailsFlow_requestedDate from "@salesforce/label/c.pmc_quoteDetailsFlow_requestedDate";
import pmc_homepage_viewMyContracts from "@salesforce/label/c.pmc_homepage_viewMyContracts";
import pmc_homepage_activeContracts from "@salesforce/label/c.pmc_homepage_activeContracts";
import pmc_homepage_product from "@salesforce/label/c.pmc_homepage_product";
import pmc_homepage_recentQuotes from "@salesforce/label/c.pmc_homepage_recentQuotes";
import pmc_homepage_viewMyQuotes from "@salesforce/label/c.pmc_homepage_viewMyQuotes";
import pmc_homepage_recentUpdates from "@salesforce/label/c.pmc_homepage_recentUpdates";
import pmc_homepage_actionPendingQuotes from "@salesforce/label/c.pmc_homepage_actionPendingQuotes";
import pmc_homepage_newLeads from "@salesforce/label/c.pmc_homepage_newLeads";
import pmc_homepage_signaturePendingContracts from "@salesforce/label/c.pmc_homepage_signaturePendingContracts";
import pmc_homepage_caseComments from "@salesforce/label/c.pmc_homepage_caseComments";
import pmc_requestToDeliver_orderNumber from "@salesforce/label/c.pmc_requestToDeliver_orderNumber";
import pmc_homepage_ordersInTransit from "@salesforce/label/c.pmc_homepage_ordersInTransit";
import pmc_requestToDeliver_viewMyOrders from "@salesforce/label/c.pmc_requestToDeliver_viewMyOrders";
import pmc_requestToDeliverShippingInformation_deliveryMode from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_deliveryMode";
import pmc_quoteCheckoutFlow_products from "@salesforce/label/c.pmc_quoteCheckoutFlow_products";
import pmc_homepage_nextShipment from "@salesforce/label/c.pmc_homepage_nextShipment";
import pmc_orderDetails_statusPlaced from "@salesforce/label/c.pmc_orderDetails_statusPlaced";
import PMC_DH_InProgress from "@salesforce/label/c.PMC_DH_InProgress";
import pmc_orderDetails_inactive from "@salesforce/label/c.pmc_orderDetails_inactive";
import pmc_quoteDetailsFlow_statusActionPending from "@salesforce/label/c.pmc_quoteDetailsFlow_statusActionPending";

const ORDER = "order";
const QUOTE = "quote";
const BADGE_STATUS_WARNING = "warning";
const BADGE_STATUS_ERROR = "error";
const PERSONA_BUYER_OR_SUPER_BUYER = "Buyer Or Super Buyer";
const PERSONA_CONTRACT_MANAGER = "Contract Manager";
const PERSONA_FINANCE_MANAGER = "Finance Manager";
const PERSONA_LOGISTIC_MANAGER = "Logistic Manager";
const PERSONA_KNOWLEDGE_USER = "Knowledge User";

/**
 * A custom LWC to display the contract details page.
 * @alias Pmc_dh_homepageWidgetSection
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant
 * @example
 * <c-pmc_dh_homepage-widget-section></c-pmc_dh_homepage-widget-section>
 */

export default class Pmc_dh_homepageWidgetSection extends LightningElement {
  @track labels = {
    pmc_requestToDeliver_contractNumber,
    pmc_contractDetails_availableQty,
    pmc_contractDetails_poNumber,
    pmc_quoteCheckoutFlow_shipTo,
    pmc_quoteHistory_quoteNumber,
    pmc_quoteDetailsFlow_requestedDate,
    pmc_homepage_viewMyContracts,
    pmc_homepage_activeContracts,
    pmc_homepage_product,
    pmc_homepage_recentQuotes,
    pmc_homepage_viewMyQuotes,
    pmc_homepage_recentUpdates,
    pmc_homepage_actionPendingQuotes,
    pmc_homepage_newLeads,
    pmc_homepage_signaturePendingContracts,
    pmc_homepage_caseComments,
    pmc_requestToDeliver_orderNumber,
    pmc_homepage_ordersInTransit,
    pmc_requestToDeliver_viewMyOrders,
    pmc_requestToDeliverShippingInformation_deliveryMode,
    pmc_quoteCheckoutFlow_products,
    pmc_homepage_nextShipment,
    pmc_orderDetails_statusPlaced,
    PMC_DH_InProgress,
    pmc_orderDetails_inactive,
    pmc_quoteDetailsFlow_statusActionPending
  }
  @track pageObj = {
    activeContracts: [],
    recentQuotes: [],
    orders: [],
    recentUpdates: {},
    documents: [
      { id: 1 },
      { id: 2 }
    ]
  };
  @track templateSelectorObj = {
    hideContractsQuotesOrderWrapper: false,
    isActiveContractsWidget: false,
    isRecentQuotesWidget: false,
    isOrdersWidget: false,
    isRecentUpdatesWidget: true,
    isRecentUpdatesWidget_quotes: false,
    isRecentUpdatesWidget_contracts: false,
    isRecentUpdatesWidget_leads: false,
    isContractManager: false
  };
  @track iconUrlObj = {
    download: `${PMC_BrandingAssetsStaticResource}/icons/icon-download.svg`,
    ribbon: `${PMC_BrandingAssetsStaticResource}/icons/icon-ribbon.svg`
  };
  isSpinner = true;
  pageLoaded = false;
  pageRendered = false;
  userPersona;
  contractListPageUrl;
  quoteListPageUrl;
  caseListPageUrl;
  orderListPageUrl;
  leadManagementPageUrl;
  effectiveAccountId;
  error;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    let baseUrl = window.location.origin;
    this.contractListPageUrl = `${baseUrl}${basePath}/contracts`;
    this.quoteListPageUrl = `${baseUrl}${basePath}/quotes`;
    this.caseListPageUrl = `${baseUrl}${basePath}/support`;
    this.orderListPageUrl = `${baseUrl}${basePath}/orders?activeTab=Shipments?menu=InTransit`;
    this.leadManagementPageUrl = `${baseUrl}${basePath}/my-accounts?activeTab=lead-management`;
    this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    this.handleUserPersonaValidations();
  }

  /**
   * Handles validations for different user personas
   * @function handleUserPersonaValidations
   */
  handleUserPersonaValidations() {
    if (!DisableAddtoOrder) {
      this.userPersona = PERSONA_BUYER_OR_SUPER_BUYER
    }
    else if (Quote_ViewOnlyAccess) {
      this.userPersona = PERSONA_CONTRACT_MANAGER
    }
    else if (Hide_Contract) {
      this.userPersona = PERSONA_LOGISTIC_MANAGER
    }
    else if (Finance_Manager) {
      this.userPersona = PERSONA_FINANCE_MANAGER
    }
    else if (DisableRecentUpdateWdg) {
      this.userPersona = PERSONA_KNOWLEDGE_USER
    }
    switch (this.userPersona) {
      case PERSONA_BUYER_OR_SUPER_BUYER:
        this.templateSelectorObj.isRecentQuotesWidget = true;
        this.templateSelectorObj.isActiveContractsWidget = true;
        this.templateSelectorObj.isOrdersWidget = true;
        this.templateSelectorObj.isRecentUpdatesWidget_quotes = true;
        this.templateSelectorObj.isRecentUpdatesWidget_contracts = true;
        this.templateSelectorObj.isRecentUpdatesWidget_leads = true;
        break;
      case PERSONA_CONTRACT_MANAGER:
        this.templateSelectorObj.isContractManager = true;
        this.templateSelectorObj.isRecentQuotesWidget = true;
        this.templateSelectorObj.isRecentUpdatesWidget_quotes = true;
        this.templateSelectorObj.isRecentUpdatesWidget_contracts = true;
        break;
      case PERSONA_FINANCE_MANAGER:
        this.templateSelectorObj.isRecentUpdatesWidget_contracts = true;
        this.templateSelectorObj.hideContractsQuotesOrderWrapper = true;
        break;
      case PERSONA_LOGISTIC_MANAGER:
        this.templateSelectorObj.isOrdersWidget = true;
        break;
      case PERSONA_KNOWLEDGE_USER:
        this.templateSelectorObj.isRecentUpdatesWidget = false;
        this.templateSelectorObj.hideContractsQuotesOrderWrapper = true;
        break;
      default:
        break;
    }
    this.fetchWidgetsData();
  }

  /**
   * Fetches data for homepage widgets
   * @function fetchWidgetsData
   */
  fetchWidgetsData() {
    const promise1 = new Promise((resolve, reject) => {
      if (this.templateSelectorObj.isRecentQuotesWidget) {
        getRecentQuotes({
          strEffectiveAccountId: this.effectiveAccountId,
        })
          .then((data) => {
            if (data && Object.keys(data).length) {
              if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
                toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
              }
              if (data.lstQuotes) {
                this.pageObj.recentQuotes = JSON.parse(JSON.stringify(data.lstQuotes))
              }
            }
            resolve();
          })
          .catch((error) => {
            reject(error);
          })
      }
      else {
        resolve();
      }
    });

    const promise2 = new Promise((resolve, reject) => {
      if (this.templateSelectorObj.isActiveContractsWidget) {
        getActiveContracts({
          strEffectiveAccountId: this.effectiveAccountId,
        })
          .then((data) => {
            if (data && Object.keys(data).length) {
              if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
                toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
              }
              this.pageObj.activeContracts = JSON.parse(JSON.stringify(data?.lstContracts));
            }
            resolve();
          })
          .catch((error) => {
            reject(error);
          })
      }
      else {
        resolve();
      }
    });

    const promise3 = new Promise((resolve, reject) => {
      if (this.templateSelectorObj.isOrdersWidget) {
        getOrdersInTransit({
          strEffectiveAccountId: this.effectiveAccountId,
        })
          .then((data) => {
            if (data && Object.keys(data).length) {
              if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
                toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
              }
              if (data?.lstInTransitOrders?.length) {
                this.pageObj.orders = JSON.parse(JSON.stringify(data)).lstInTransitOrders;
              }
            }
            resolve();
          })
          .catch((error) => {
            reject(error);
          })
      }
      else {
        resolve();
      }
    });

    const promise4 = new Promise((resolve, reject) => {
      if (this.templateSelectorObj.isRecentUpdatesWidget) {
        getRecentUpdates({
          strEffectiveAccountId: this.effectiveAccountId,
        })
          .then((data) => {
            if (data && Object.keys(data).length) {
              if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
                toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
              }
              this.pageObj.recentUpdates = JSON.parse(JSON.stringify(data));
              if (this.templateSelectorObj.isRecentUpdatesWidget_leads && !data.boolIsRetailersType) {
                this.templateSelectorObj.isRecentUpdatesWidget_leads = false
              }
            }
            resolve();
          })
          .catch((error) => {
            reject(error);
          })
      }
      else {
        resolve();
      }
    });
    const allPromise = Promise.all([promise1, promise2, promise3, promise4]);
    allPromise.then(() => {
      this.pageLoaded = true;
      this.isSpinner = false;
    })
      .catch((error) => {
        toastMessageHandler();
        this.pageLoaded = true;
        this.isSpinner = false;
        this.error = error;
      });
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    if (this.pageLoaded) {
      let baseUrl = window.location.origin;
      if (this.pageObj?.activeContracts.length) {
        this.pageObj.activeContracts.forEach((contract) => {
          contract.contractDetailsUrl = `${baseUrl}${basePath}${contract?.strContractHistoryUrl}`;
        })
      }
      if (this.pageObj?.recentQuotes.length) {
        this.pageObj.recentQuotes.forEach((quote, quoteIndex) => {
          this.statusBadgeHandler(quote?.strQuoteStatus, quoteIndex, QUOTE);
          quote.quoteDetailsUrl = `${baseUrl}${basePath}/${quote?.strQuoteUrl}`;
          quote.datRequestedDate = formatDate(quote?.datRequestedDate);
        })
      }
      if (this.pageObj?.orders.length) {
        this.pageObj.orders.forEach((order, orderIndex) => {
          this.statusBadgeHandler(order.strStatus, orderIndex, ORDER);
          order.orderDetailsUrl = `${baseUrl}${basePath}/${order?.strDetailPageUrl}`;
          order.datShipment = formatDate(order?.datShipment);
        });
      }
      if (Object.keys(this.pageObj.recentUpdates).length) {
        Object.keys(this.pageObj.recentUpdates).forEach(el => {
          this.pageObj.recentUpdates[el] = this.padZeroAtStart(this.pageObj.recentUpdates[el])
        });
      }
      this.pageRendered = true;
    }
  }

  /**
   * Handles status badges
   * @function statusBadgeHandler
   * @param {string} status 
   * @param {number} index 
   * @param {string} cardName 
   */
  statusBadgeHandler(status, index, cardName) {
    let element = '';
    this.template.querySelectorAll(`.${cardName}-card .badge`).forEach(badge => {
      if (+badge.getAttribute('data-index') === index)
        element = badge;
    });
    let badgeStatus = '';
    switch (status) {
      case this.labels.pmc_orderDetails_inactive:
        badgeStatus = BADGE_STATUS_ERROR;
        break;
      case this.labels.pmc_quoteDetailsFlow_statusActionPending:
        badgeStatus = BADGE_STATUS_WARNING;
        break;
      case this.labels.pmc_orderDetails_statusPlaced:
        badgeStatus = BADGE_STATUS_WARNING;
        break;
      case this.labels.PMC_DH_InProgress:
        badgeStatus = BADGE_STATUS_WARNING;
        break;
      default:
        break;
    }
    element.setAttribute("data-status", badgeStatus)
  }

  /**
   * Pads zero at start
   * @function padZeroAtStart
   * @param {number} number 
   */
  padZeroAtStart(number) {
    if (+number < 10) {
      number = `0${number}`
    }
    return number;
  }
}