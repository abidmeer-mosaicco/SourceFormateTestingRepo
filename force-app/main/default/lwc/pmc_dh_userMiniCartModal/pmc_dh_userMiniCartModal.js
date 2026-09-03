import { LightningElement, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import USER_ACCOUNT_FIELD from '@salesforce/schema/User.AccountId';
import communityId from '@salesforce/community/Id';
import { urlRedirect, toastMessageHandler } from "c/pmc_dh_utilityJs";
import fetchMiniCartItems from '@salesforce/apex/PMC_DH_MiniCart.fetchMiniCartItems';
import validateCart from '@salesforce/apex/PMC_DH_CartValidationController.validateCart';
import deleteProductFromCart from '@salesforce/apex/PMC_DH_MiniCart.deleteCartItems';
import getActiveCartId from '@salesforce/apex/PMC_DH_QuoteUtils.getActiveCartId';
import { NavigationMixin } from 'lightning/navigation';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

import pmc_miniCartModal_emptyCart from '@salesforce/label/c.pmc_miniCartModal_emptyCart';
import pmc_miniCartModal_cart from '@salesforce/label/c.pmc_miniCartModal_cart';
import pmc_miniCartModal_btnLabel from '@salesforce/label/c.pmc_miniCartModal_btnLabel';
import pmc_miniCartModal_closeLabel from '@salesforce/label/c.pmc_miniCartModal_closeLabel';
import pmc_miniCartModal_deleteLabel from '@salesforce/label/c.pmc_miniCartModal_deleteLabel';
import pmc_header_cart from "@salesforce/label/c.pmc_header_cart";

/**
 * A Custom Mini Cart Modal.
 * @alias Pmc_dh_userMiniCartModal
 * @description    : To show added products in mini cart
 * @author Himanshu Rathore
 * @example
 * <c-pmc_dh_user-mini-cart-modal></c-pmc_dh_user-mini-cart-modal>
 */

export default class Pmc_dh_userMiniCartModal extends NavigationMixin(LightningElement) {
  @track effectiveAccountId;
  @track error;
  @track showCartData = false;
  @track labels = {
    pmc_miniCartModal_emptyCart,
    pmc_miniCartModal_cart,
    pmc_miniCartModal_btnLabel,
    pmc_miniCartModal_closeLabel,
    pmc_miniCartModal_deleteLabel,
    pmc_header_cart
  }
  @track iconUrlObj = {
    cartUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-cart.svg`,
  };
  showMiniCart = false;
  isSpinner = false;
  _showEmptyCart = false;
  cartId;
  cartItemsList = [];

  @wire(getRecord, { recordId: Id, fields: [USER_ACCOUNT_FIELD] })
  currentUserInfo({ error, data }) {
    if (data) {
      if(localStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
        this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID");
      } else {
        this.effectiveAccountId = data.fields.AccountId.value;
      }
      if(!sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
        sessionStorage.setItem("EFFECTIVE_ACCOUNT_ID", data.fields.AccountId.value);
      }
    } else if (error) {
      this.error = error;
    }
  }

  /**
   * Opens cart on enter key
   * @function openCartOnEnter
   * @param {Event} event 
   */
  openCartOnEnter(event) {
    if (event.keyCode === 13) {
      this.cartClickHandler(event);
    }
  }

  /**
   * Handles click on cart
   * @function cartClickHandler
   * @param {Event} event 
   */
  cartClickHandler(event) {
    if (this.showMiniCart) {
      event.stopPropagation();
    }
    clearTimeout(this.clickTimer);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.clickTimer = setTimeout(() => {
      this.showMiniCart = !this.showMiniCart;
      if (this.showMiniCart) {
        this.fetchActiveCartId(this.effectiveAccountId);
      }
    }, 500);
  }

  /* 
   * Hide mini cart when a click occurs outside of mini cart.
   */
  _handler;
  connectedCallback() {
    document.addEventListener('click', this._handler = this.close.bind(this));
  }
  disconnectedCallback() {
    document.removeEventListener('click', this._handler);
  }
  ignore(event) {
    event.stopPropagation();
    return false;
  }
  close() {
    this.showMiniCart = false;
  }

  /** 
   * Function to Fetch Cart Data inside Mini Cart 
   * @function fetchMiniCartItems
   * @param {string} effAccId 
   */
  fetchMiniCartItems(effAccId) {
    this.isSpinner = true;
    fetchMiniCartItems({
      strEffectiveAccountId: effAccId,
      strCommunityId: communityId,
    })
      .then(result => {
        if (result && Object.keys(result).length) {
          if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
          }
          if (result.cartItemsList && result.cartItemsList.length >= 0) {
            this.showMiniCartData(result);
          }
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  }

  /**
   * To Show/Open Mini Cart Modal after fetchMiniCartItems Method Call
   * @function showMiniCartData
   * @param {object} result 
   */
  showMiniCartData(result) {
    this.cartItemsList = result.cartItemsList;
    this.showCartData = this.cartItemsList.length > 0 ? true : false;
    this._showEmptyCart = !this.showCartData;
    this.isSpinner = false;
  }

  /**
   * Closes cart on enter key
   * @function closeMiniCartOnEnter
   * @param {Event} event 
   */
  closeMiniCartOnEnter(event) {
    if (event.keyCode === 13) {
      this.closeMiniCartHandler();
    }
  }

  /**
   * To Close Mini Cart Modal 
   * @function closeMiniCartHandler
   */
  closeMiniCartHandler = () => {
    this.showMiniCart = false;
  }

  /**
   * Delete icon Key Press in Mini Cart Modal 
   * @function deleteIconKeypressHandler
   * @param {Event} event 
   */
  deleteIconKeypressHandler(event) {
    if (event.keyCode === 13) {
      event.preventDefault();
      this.handleRemoveItem(event);
    }
  }

  /**
   * To Remove Products from mini cart modal 
   * @function handleRemoveItem
   * @param {Event} event 
   */
  handleRemoveItem(event) {
    this.isSpinner = true;
    let productSku = event.target.dataset.sku;
    this.deleteProduct(productSku);
  }

  /**
   * Backend method to remove product  
   * @function deleteProduct
   * @param {string} sku 
   */
  deleteProduct(sku) {
    deleteProductFromCart({
      strCartId: this.cartId,
      strCartItemSKU: sku
    })
      .then(() => {
        this.fetchMiniCartItems(this.effectiveAccountId);
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      });
  }

  /**
   * Fetches active cart id  
   * @function fetchActiveCartId
   * @param {string} effAccId 
   */
  fetchActiveCartId(effAccId) {
    getActiveCartId({
      strEffectiveAccountId: effAccId,
      strCommunityId: communityId
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
          }
          this.cartId = response.strCartId;
          sessionStorage.setItem('CART_ID', this.cartId);
          if (this.cartId) this.fetchMiniCartItems(this.effectiveAccountId);
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
      });
  }

  /**
   * Validates cart for error
   * @function validateActiveCart
   */
  validateActiveCart() {
    let targetUrl = '';
    validateCart({
      strCartId: this.cartId
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
            sessionStorage.setItem('CHECKOUT_FLAG', data.strSource);
            if (data.strContractId) {
              sessionStorage.setItem('CONTRACT_ID', data.strContractId);
            }
          }
          this.closeMiniCartHandler();
          this[NavigationMixin.GenerateUrl]({
            type: "standard__webPage",
            attributes: {
              url: targetUrl
            }
          }).then((generatedUrl) => {
            urlRedirect(generatedUrl);
          })
        }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
      });
  }

  /** 
   * To Navigate Cart Page on Btn Click
   * @function cartCheckoutHandler
   */
  cartCheckoutHandler() {
    if (this.cartId) {
      this.validateActiveCart();
    }
  }
}