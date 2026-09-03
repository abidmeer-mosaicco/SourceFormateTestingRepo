import { LightningElement, track } from 'lwc';
import cartPageValidation from '@salesforce/apex/PMC_DH_CartValidationController.cartPageValidation';
import { NavigationMixin } from 'lightning/navigation';
import { toastMessageHandler } from "c/pmc_dh_utilityJs";
import basePath from "@salesforce/community/basePath";
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { deleteItemFromCart } from 'commerce/cartApi';
import DisableAddtoOrder from '@salesforce/customPermission/DisableAddtoOrder';
import communityId from '@salesforce/community/Id';
import getActiveCartId from '@salesforce/apex/PMC_DH_QuoteUtils.getActiveCartId';

import pmc_cartCheckout_validation from '@salesforce/label/c.pmc_cartCheckout_validation';
import pmc_cartCheckout_cartValidation from '@salesforce/label/c.pmc_cartCheckout_cartValidation';
import pmc_cartCheckout_checkout from '@salesforce/label/c.pmc_cartCheckout_checkout';
import pmc_cartCheckout_sku from '@salesforce/label/c.pmc_cartCheckout_sku';
import pmc_cartCheckout_rfq from '@salesforce/label/c.pmc_cartCheckout_rfq';
import pmc_cartCheckout_rtd from '@salesforce/label/c.pmc_cartCheckout_rtd';
import pmc_proceed from '@salesforce/label/c.pmc_proceed';
import pmc_cartCheckout_backToCart from '@salesforce/label/c.pmc_cartCheckout_backToCart';
import pmc_accountDetails_delete from '@salesforce/label/c.pmc_accountDetails_delete';
import pmc_cartCheckout_productsUnavailable from '@salesforce/label/c.pmc_cartCheckout_productsUnavailable';
import pmc_cartCheckout_proceedToQuoteRequest from '@salesforce/label/c.pmc_cartCheckout_proceedToQuoteRequest';
import pmc_cartCheckout_proceedToOrderRequest from '@salesforce/label/c.pmc_cartCheckout_proceedToOrderRequest';
import pmc_cartCheckout_productsUnavailable2 from '@salesforce/label/c.pmc_cartCheckout_productsUnavailable2';

const RFQ = "RFQ";
const RTD = "RTD";

export default class Pmc_dh_cartCheckout extends NavigationMixin(LightningElement) {
  @track labels = {
    pmc_cartCheckout_validation,
    pmc_cartCheckout_cartValidation,
    pmc_cartCheckout_checkout,
    pmc_cartCheckout_sku,
    pmc_cartCheckout_rfq,
    pmc_cartCheckout_rtd,
    pmc_proceed,
    pmc_cartCheckout_backToCart,
    pmc_accountDetails_delete,
    pmc_cartCheckout_proceedToQuoteRequest,
    pmc_cartCheckout_proceedToOrderRequest
  };

  @track invalidProducts = [];
  isValidationModal = false;
  error;
  validationType = null;
  validationError = null;
  isCheckoutDisabled = DisableAddtoOrder;
  webStoreId;
  effectiveAccountId;
  modalHeading;
  hasWarnings = false;
  isLoading = false;
  isUnavailableProductsError = false;

  @track iconUrlObj = {
    deleteIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-delete.svg`,
  };

  // firstVisit variable will be used when user visits cart page form mini-cart widget.
  firstVisit = true;

  /**
   * Lifecycle hook
   */
  connectedCallback() {
    if (sessionStorage.getItem('EFFECTIVE_ACCOUNT_ID')) {
      this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    }
    this.isLoading = true;
    getActiveCartId({
      strEffectiveAccountId: this.effectiveAccountId,
      strCommunityId: communityId
    })
      .then((response) => {
        if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
        }
        this.cartId = response.strCartId;
        if (this.cartId) {
          sessionStorage.setItem('CART_ID', this.cartId);
        }
        if (sessionStorage.getItem('CART_VALIDATION_ERROR')) {
          this.firstVisit = false;
          sessionStorage.removeItem('CART_VALIDATION_ERROR');
        }
        this.validateCartPage();
        this.isLoading = false
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isLoading = false
      });
  }

  /**
   * validate cart errors from Backend
   * @function validateCartPage
   */
  validateCartPage() {
    this.isLoading = true;
    cartPageValidation({
      strCartId: this.cartId
    })
      .then((data) => {
        if (data && Object.keys(data).length) {
          if(!(data?.boolHasErrors)) {
            this.labels.pmc_cartCheckout_checkout = (data.strSource === "RFQ") ? this.labels.pmc_cartCheckout_proceedToQuoteRequest : this.labels.pmc_cartCheckout_proceedToOrderRequest;
          }
          if (this.firstVisit && !(data?.boolHasErrors)) {
            if (data.strSource) {
              this.firstVisit = false;
              return;
            }
          }
          if(!this.firstVisit){
            if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
              toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
            }
            if (data.boolHasErrors || data.boolHasWarnings) {
              this.isValidationModal = true;
              this.invalidProducts = JSON.parse(JSON.stringify(data.lstCartValidationWrapper));
              this.invalidProducts.forEach(item => {
                if (item.strFlow === RFQ) item.strFlow = this.labels.pmc_cartCheckout_rfq;
                if (item.strFlow === RTD) item.strFlow = this.labels.pmc_cartCheckout_rtd;
              });
              this.validationType = JSON.parse(JSON.stringify(data.strSubjError));
              this.validationError = data.strFooterErr ? JSON.parse(JSON.stringify(data.strFooterErr)) : null;
              if (data.strSource) sessionStorage.setItem('CHECKOUT_FLAG', data.strSource);
              this.isUnavailableProductsError = this.validationType === pmc_cartCheckout_productsUnavailable;
              if (this.isUnavailableProductsError){
                this.modalHeading = pmc_cartCheckout_productsUnavailable2;
              }
              else{
                this.modalHeading = data.boolHasErrors ? this.labels.pmc_cartCheckout_validation : this.labels.pmc_cartCheckout_cartValidation;
              }
              this.hasWarnings = data.boolHasWarnings;
            } else {
              if (data.strContractId) sessionStorage.setItem('CONTRACT_ID', data.strContractId);
              if (data.strSource) sessionStorage.setItem('CHECKOUT_FLAG', data.strSource);
              this.handleProceed();
            }
          }
          this.firstVisit = false;
        }
        this.isLoading = false
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isLoading = false
      });
  }

  /**
   * Handle Request to Checkout
   * @function handleRequestToCheckout
   */
  handleRequestToCheckout() {
    this.validateCartPage();
  }

  /**
   * Close Modal
   * @function handleCloseModal
   */
  handleCloseModal() {
    this.isValidationModal = false;
  }

  /**
   * Backend Method to delete item from cart
   * @function deleteFromCartHandler
   * @param {string} itemId
   */
  async deleteFromCartHandler(itemId) {
    try {
      await deleteItemFromCart(itemId);
      this.validateCartPage();
    } catch (error) {
      this.error = error;
    }
  }

  /**
   * delete a cart item on click
   * @function deleteCartItem
   * @param {event} event 
   */
  deleteCartItem(event) {
    let cartItemId = event.currentTarget.dataset.cartItemId;
    this.deleteFromCartHandler(cartItemId);

    // deleteItemFromCart(cartItemId)
    // .then(() => {
    //   this.validateCartPage();
    // })
    // .catch((error) => {
    //   toastMessageHandler();
    //   this.error = error;
    // });
  }

  /**
   * Handle Proceed
   * @function handleProceed
   */
  handleProceed() {
    let baseUrl = window.location.origin;
    let url = `${baseUrl}${basePath}/checkout`;
    var link = document.createElement('a');
    link.href = url;
    link.click();
  }
}