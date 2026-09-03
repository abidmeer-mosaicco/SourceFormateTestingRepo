import { LightningElement, track, wire } from 'lwc';
import basePath from '@salesforce/community/basePath';
import { SORT_DIRECTION, sortData, formatLabel, isBrazilRegion, toastMessageHandler } from 'c/pmc_dh_utilityJs';
import communityId from '@salesforce/community/Id';
import { getNavigationMenu } from 'experience/navigationMenuApi';
import { deleteItemFromCart } from 'commerce/cartApi';
import getShipmentInfo from "@salesforce/apex/PMC_DH_RequestForQuoteController.getQuoteCheckOutShipmentInfo";
import addShipmentInfo from "@salesforce/apex/PMC_DH_QuoteUtils.addCartItems";
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

import pmc_quoteCheckoutFlow_proceed from "@salesforce/label/c.pmc_quoteCheckoutFlow_proceed";
import pmc_quoteCheckoutFlow_products from "@salesforce/label/c.pmc_quoteCheckoutFlow_products";
import pmc_quoteCheckoutFlow_quantity from "@salesforce/label/c.pmc_quoteCheckoutFlow_quantity";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_quoteCheckoutFlow_incoterms from "@salesforce/label/c.pmc_quoteCheckoutFlow_incoterms";
import pmc_quoteCheckoutFlow_deliveryMode from "@salesforce/label/c.pmc_quoteCheckoutFlow_deliveryMode";
import pmc_quoteCheckoutFlow_deliveryInformation from "@salesforce/label/c.pmc_quoteCheckoutFlow_deliveryInformation";
import pmc_quoteCheckoutFlow_totalQuantity from "@salesforce/label/c.pmc_quoteCheckoutFlow_totalQuantity";
import pmc_quoteCheckoutFlow_tons from "@salesforce/label/c.pmc_quoteCheckoutFlow_tons";
import pmc_quoteCheckoutFlow_addNewShip from "@salesforce/label/c.pmc_quoteCheckoutFlow_addNewShip";
import pmc_quoteCheckoutFlow_createNewAddress from "@salesforce/label/c.pmc_quoteCheckoutFlow_createNewAddress";
import pmc_quoteCheckoutFlow_enterQuantity from "@salesforce/label/c.pmc_quoteCheckoutFlow_enterQuantity";
import pmc_accountDetails_delete from "@salesforce/label/c.pmc_accountDetails_delete";
import pmc_quoteCheckoutFlow_noProductsMessage from "@salesforce/label/c.pmc_quoteCheckoutFlow_noProductsMessage";
import pmc_quoteCheckoutFlow_duplicateProductsMessage from "@salesforce/label/c.pmc_quoteCheckoutFlow_duplicateProductsMessage";
import pmc_requestForQuote_packType from "@salesforce/label/c.pmc_requestForQuote_packType";
import pmc_requestForQuote_unit from "@salesforce/label/c.pmc_requestForQuote_unit";
import pmc_quoteCheckoutFlow_preferredShipFrom from "@salesforce/label/c.pmc_quoteCheckoutFlow_preferredShipFrom";
import pmc_contractDetails_products from "@salesforce/label/c.pmc_contractDetails_products";

const LABEL = "label";
const INCOTERM_CPT = "CPT";

/**
 * A custom LWC to display the delivery information step in checkout flow.
 * @alias Pmc_dh_quoteCheckoutDeliveryInfo
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant
 * @example
 * <c-pmc_dh_quote-checkout-delivery-info></c-pmc_dh_quote-checkout-delivery-info>
 */

export default class Pmc_dh_quoteCheckoutDeliveryInfo extends LightningElement {
  @track productInfoArray = [];
  @track labels = {
    pmc_quoteCheckoutFlow_proceed,
    pmc_quoteCheckoutFlow_products,
    pmc_quoteCheckoutFlow_quantity,
    pmc_quoteCheckoutFlow_shipTo,
    pmc_quoteCheckoutFlow_incoterms,
    pmc_quoteCheckoutFlow_deliveryMode,
    pmc_quoteCheckoutFlow_deliveryInformation,
    pmc_quoteCheckoutFlow_totalQuantity,
    pmc_quoteCheckoutFlow_tons,
    pmc_quoteCheckoutFlow_addNewShip,
    pmc_quoteCheckoutFlow_createNewAddress,
    pmc_quoteCheckoutFlow_enterQuantity,
    pmc_accountDetails_delete,
    pmc_quoteCheckoutFlow_noProductsMessage,
    pmc_quoteCheckoutFlow_duplicateProductsMessage,
    pmc_requestForQuote_unit,
    pmc_requestForQuote_packType,
    pmc_quoteCheckoutFlow_preferredShipFrom
  };

  @track iconUrlObj = {
    deleteIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-delete.svg`,
    mosaicLogoUrl: `${PMC_BrandingAssetsStaticResource}/images/logo-mosaic.png`,
  };

  @track saveToCartItems = [];
  @track pageItems = [];
  @track isLocationBrazil = false;
  isProceedDisabled = true;
  isPageLoaded = false;
  isSpinner = true;
  pageRendered = false;
  effectiveAccountId;
  communityId;
  cartId;
  error;
  lstProductFamilies;

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
    this.labels.pmc_quoteCheckoutFlow_noProductsMessage = formatLabel(this.labels.pmc_quoteCheckoutFlow_noProductsMessage, [productPageUrl]);
  }

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    let baseUrl = window.location.origin;
    let loginUrl = `${baseUrl}${basePath}/my-accounts?activeTab=addresses`;
    this.labels.pmc_quoteCheckoutFlow_createNewAddress = formatLabel(this.labels.pmc_quoteCheckoutFlow_createNewAddress, [loginUrl]);
    if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
      this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    }
    if (sessionStorage.getItem('CART_ID')) {
      this.cartId = sessionStorage.getItem('CART_ID');
    }
    if (isBrazilRegion()) {
      this.isLocationBrazil = !this.isLocationBrazil;
    }
    this.communityId = communityId;
    this.fetchShipmentInfo();
  }

  /**
   * fetch shipment details from backend method
   * @function fetchShipmentInfo
   */
  fetchShipmentInfo() {
    getShipmentInfo({
      strCommunityId: this.communityId,
      strEffectiveAccountId: this.effectiveAccountId,
      strCartId: this.cartId
    })
      .then((data) => {
        if (data && Object.keys(data).length) {
          if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
          }
          this.productInfoArray = JSON.parse(JSON.stringify(data.lstCartWrapper));
          this.productInfoArray.forEach(el => {
            el.isDuplicate = false;
          });
          this.lstProductFamilies = data.lstProductFamilies;
        }
        this.isPageLoaded = true;
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isPageLoaded = true;
        this.isSpinner = false;
      });
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    if (this.isPageLoaded) {
      if (!this.isLocationBrazil) {
        this.template.querySelectorAll('.shipment-col').forEach(el => {
          el.classList.add('isNAUser');
        })
      }
      let baseUrl = window.location.origin;
      // Giving respective PDP links to each product 
      this.productInfoArray.forEach(el => {
        let href = `${baseUrl}${basePath}/product/${el.strProductId}`;
        el.href = href;
        el.lstIncoterms = sortData(el.lstIncoterms, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
        el.lstPackType = sortData(el.lstPackType, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
        el.lstProductUOM = sortData(el.lstProductUOM, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
        el.lstShipFrom = sortData(el.lstShipFrom, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
        el.lstShipTo = sortData(el.lstShipTo, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
        el.lstCartItems.forEach(item => {
          if (!item.strShipTo && !item.strIncoterms) {
            item.isIncotermsDisabled = true;
          }
          if (!item.strIncoterms && !item.strDeliveryMode) {
            item.isDeliveryModeDisabled = true;
          }
          if (!item.strDeliveryMode && !item.strShipFrom) {
            item.isShipFromDisabled = true;
          }
          if (item.strIncoterms && item.strIncoterms === INCOTERM_CPT) {
            item.lstDeliveryModes = sortData(el.lstDeliveryModesCPT, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
          }
          else {
            item.lstDeliveryModes = sortData(el.lstDeliveryModes, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
          }
          if (item.strSkuPackType) {
            item.isPackTypeDisabled = true;
            item.strPackType = item.strSkuPackType;
          }
          else {
            item.isPackTypeDisabled = false;
          }

          // Setting up ship to value to default if selected shipTo is not available in shipTo picklist
          let selectedShipToFound = false;
          el.lstShipTo.forEach((shipTo) => {
            if (shipTo.value === item.strShipTo) {
              selectedShipToFound = true;
            }
          });
          item.strShipTo = selectedShipToFound ? item.strShipTo : "";
        });
      });
      this.productInfoArray.forEach((el, i) => {
        this.getTotalQuantity(i);
      });
      if (this.productInfoArray.length) {
        this.checkEmptyStatus();
      }
      this.pageRendered = true;
    }
  }

  /** 
   * Add new shipment details for the respective product on click 
   * @function addShipment
   * @param {Event} event 
   */
  addShipment(event) {
    let index = parseInt(event.target.dataset.productIndex, 10);
    if (!this.checkDuplicateRows(index)) return;
    this.productInfoArray.forEach((el, i) => {
      if (i === index) {
        el.lstCartItems = [...el.lstCartItems,
        { strQuantity: 25, strCartItemId: '', strShipTo: null, strShipFrom: null, strIncoterms: null, strDeliveryMode: null, isIncotermsDisabled: true, isDeliveryModeDisabled: true, isShipFromDisabled: true }];
        if (this.isLocationBrazil) {
          el.lstCartItems[el.lstCartItems.length - 1].strPackType = el.lstCartItems[0].strSkuPackType ? el.lstCartItems[0].strSkuPackType : null;
          el.lstCartItems[el.lstCartItems.length - 1].strSkuPackType = el.lstCartItems[0].strSkuPackType;
          el.lstCartItems[el.lstCartItems.length - 1].isPackTypeDisabled = el.lstCartItems[0].strSkuPackType ? true : false;
        }
      }
    });
    this.getTotalQuantity(index);
    this.isProceedDisabled = true;
  }

  /**
   * Delete a shipment details row on click and product in case of one shipment row
   * @function deleteShipment
   * @param {Event} event 
   */
  deleteShipment(event) {
    let index1 = parseInt(event.currentTarget.dataset.productIndex, 10);
    let index2 = parseInt(event.currentTarget.dataset.shipmentIndex, 10);
    let cartItemId = event.currentTarget.dataset.cartId;
    this.productInfoArray[index1].lstCartItems.splice(index2, 1);
    if (!this.productInfoArray[index1].lstCartItems.length) {
      this.productInfoArray.splice(index1, 1);
    }
    else {
      this.getTotalQuantity(index1);
    }
    if (cartItemId !== '') {
      this.deleteFromCartHandler(cartItemId);
    }
    this.checkEmptyStatus();
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      if (this.productInfoArray[index1] && this.productInfoArray[index1].isDuplicate) {
        this.checkDuplicateRows(index1);
      }
      this.validateInputFields(index1, index2);
    });
  }

  /**
   * Backend Method to delete item from cart
   * @function deleteFromCartHandler
   * @param {string} itemId 
   */
  async deleteFromCartHandler(itemId) {
    try {
      await deleteItemFromCart(itemId);
    } catch (error) {
      this.error = error;
    }
  }

  /**
   * On input change event handler
   * @function handleDataChange
   * @param {Event} event 
   */
  handleDataChange(event) {
    let index1 = event.target.dataset.productIndex;
    let index2 = event.target.dataset.shipmentIndex;
    if (event.target.dataset.id === 'strProductUOM') {
      this.productInfoArray[index1][event.target.dataset.id] = event.detail.value;
    }
    else {
      this.productInfoArray[index1].lstCartItems[index2][event.target.dataset.id] = event.detail.value;
    }

    if (event.target.dataset.id === 'strQuantity') {
      this.getTotalQuantity(index1);
    }

    if (event.target.dataset.id === 'strShipTo') {
      this.productInfoArray[index1].lstCartItems[index2].strIncoterms = null;
      this.productInfoArray[index1].lstCartItems[index2].strDeliveryMode = null;
      this.productInfoArray[index1].lstCartItems[index2].strShipFrom = null;
      if (event.detail.value) {
        this.productInfoArray[index1].lstCartItems[index2].isIncotermsDisabled = false;
      }
      else {
        this.productInfoArray[index1].lstCartItems[index2].isIncotermsDisabled = true;
        this.productInfoArray[index1].lstCartItems[index2].isDeliveryModeDisabled = true;
        this.productInfoArray[index1].lstCartItems[index2].isShipFromDisabled = true;
      }
    }

    if (event.target.dataset.id === 'strIncoterms') {
      this.productInfoArray[index1].lstCartItems[index2].strDeliveryMode = null;
      this.productInfoArray[index1].lstCartItems[index2].strShipFrom = null;
      if (event.detail.value) {
        if (event.detail.value === INCOTERM_CPT) {
          this.productInfoArray[index1].lstCartItems[index2].lstDeliveryModes = sortData(this.productInfoArray[index1].lstDeliveryModesCPT, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
        }
        else {
          this.productInfoArray[index1].lstCartItems[index2].lstDeliveryModes = sortData(this.productInfoArray[index1].lstDeliveryModes, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
        }
        this.productInfoArray[index1].lstCartItems[index2].isDeliveryModeDisabled = false;
      }
      else {
        this.productInfoArray[index1].lstCartItems[index2].isDeliveryModeDisabled = true;
        this.productInfoArray[index1].lstCartItems[index2].isShipFromDisabled = true;
      }
    }

    if (event.target.dataset.id === 'strDeliveryMode') {
      this.productInfoArray[index1].lstCartItems[index2].strShipFrom = null;
      if (event.detail.value) {
        this.productInfoArray[index1].lstCartItems[index2].isShipFromDisabled = false;
      }
      else {
        this.productInfoArray[index1].lstCartItems[index2].isShipFromDisabled = true;
      }
    }
    this.checkEmptyStatus();
  }

  /**
   * On key up for Quantity Field
   * @function handleKeyUp
   * @param {Event} event 
   */
  handleKeyUp(event) {
    let index1 = event.target.dataset.productIndex;
    let index2 = event.target.dataset.shipmentIndex;
    event.target.value = event.target.value.replace(/[^0-9]/g, '');
    this.productInfoArray[index1].lstCartItems[index2][event.target.dataset.id] = event.target.value;
    this.getTotalQuantity(index1);
  }

  /**
   * passing field values to backend and giving next step details to parent component
   * @function proceedButtonHandler
   */
  proceedButtonHandler() {
    if (this.checkDuplicateRows()) {
      this.productInfoArray.forEach(ele => {
        let productInfoObj = { strProductId: ele.strProductId, strProductName: ele.strProductName, strSku: ele.strSku, strTotalQty: ele.strTotalQty, strImgSrc: ele.strImgSrc, href: ele.href, lstShipTo: ele.lstShipTo, lstShipFrom: ele.lstShipFrom, lstDeliveryModes: ele.lstDeliveryModes, lstDeliveryModesCPT: ele.lstDeliveryModesCPT, lstPackType: ele.lstPackType, strProductUOM: ele.strProductUOM, shipmentInfoArray: [] };
        ele.lstCartItems.forEach(item => {
          let obj = { strProductId: ele.strProductId, strProductName: ele.strProductName, strProductUOM: ele.strProductUOM, strSku: ele.strSku, strCartItemId: item.strCartItemId, strQuantity: item.strQuantity, strShipTo: item.strShipTo, strIncoterms: item.strIncoterms, strDeliveryMode: item.strDeliveryMode, strShipFrom: item.strShipFrom }
          let shipmentInfoObj = { strQuantity: item.strQuantity, strShipTo: item.strShipTo, strIncoterms: item.strIncoterms, strDeliveryMode: item.strDeliveryMode, strShipFrom: item.strShipFrom };
          if (this.isLocationBrazil) {
            obj.strPackType = item.strPackType;
            shipmentInfoObj.strPackType = item.strPackType;
          }
          obj.strProductUOM = ele.strProductUOM;
          this.saveToCartItems.push(obj);
          productInfoObj.shipmentInfoArray.push(shipmentInfoObj);
        })
        this.pageItems.push(productInfoObj);
      });
      this.isSpinner = true;
      addShipmentInfo({
        strCartId: this.cartId,
        strInputJSON: JSON.stringify(this.saveToCartItems),
      }).then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
          }
          if (response?.strStatusCode === "002") {
            this.dispatchEvent(
              new CustomEvent("buttonclick", {
                detail: {
                  value: "isPaymentInfo",
                  step: 2,
                  cartId: this.cartId,
                  productInfoArray: this.pageItems,
                  lstProductFamilies: this.lstProductFamilies
                }
              })
            );
          }
        }
        this.isSpinner = false;
      }).catch(error => {
        toastMessageHandler();
        this.error = error;
        this.isSpinner = false;
      })
    }
  }

  /**
   * Inability Method for a user to add a duplicate product line in RFQ flow.
   * @function checkDuplicateRows
   * @param {null} indexProduct
   */
  checkDuplicateRows = (indexProduct = null) => {
    let allValid = true;
    this.productInfoArray.forEach((el, index) => {
      if (indexProduct !== null && index !== indexProduct) return;
      let productIndex = +index;
      let duplicateCount = 0;
      el.lstCartItems?.forEach((item, itemIndex, arr) => {
        if (!item.strShipTo || !item.strDeliveryMode || !item.strIncoterms || !item.strShipFrom) return;
        const isDuplicate = arr.some((otherItem, otherIndex) => {
          return (
            itemIndex !== otherIndex &&
            item.strDeliveryMode === otherItem.strDeliveryMode &&
            item.strIncoterms === otherItem.strIncoterms &&
            item.strShipFrom === otherItem.strShipFrom &&
            item.strShipTo === otherItem.strShipTo
          );
        });
        el.isDuplicate = isDuplicate;
        if (isDuplicate) {
          duplicateCount++;
        }
        const fieldsToHighlight = ['strShipTo', 'strIncoterms', 'strDeliveryMode', 'strShipFrom'];
        fieldsToHighlight?.forEach(field => {
          const element = this.template.querySelectorAll(`.card-body>.details-section[data-product-index="${productIndex}"] .shipment-col [data-id="${field}"]`)[itemIndex];
          if (el.isDuplicate) {
            element.reportErrorValidity();
            allValid = false;
          } else {
            element.removeReportErrorValidity();
          }
        });
      });
      if (duplicateCount > 0) {
        el.isDuplicate = true;
      }
    });
    return allValid;
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
   * Return total quantity for the given product
   * @function getTotalQuantity
   * @param {number} productIndex 
   */
  getTotalQuantity(productIndex) {
    const quantities = this.productInfoArray[productIndex].lstCartItems.map((ele) => (ele.strQuantity ? +ele.strQuantity : 0));
    if (quantities) {
      const total = quantities.reduce((acc, curr) => acc + curr);
      this.productInfoArray[productIndex].strTotalQty = total;
    }
  }

  /**
   * Check if all the fields are filled
   * @function checkEmptyStatus
   */
  checkEmptyStatus() {
    let allValid = true;
    this.productInfoArray.forEach(el => {
      if (!el.strProductUOM) {
        allValid = false;
      }
      el.lstCartItems.forEach(item => {
        let obj = { strShipTo: item.strShipTo, strIncoterms: item.strIncoterms, strDeliveryMode: item.strDeliveryMode, strShipFrom: item.strShipFrom }
        if (Object.values(obj).includes('') || Object.values(obj).includes(null) || item.strQuantity === ('') || +item.strQuantity === 0) {
          allValid = false;
        }
        if (this.isLocationBrazil && (!item.strPackType)) {
          allValid = false;
        }
      })
    });
    this.isProceedDisabled = !allValid;
  }

  /**
   * Report Validity for line item of the deleted row
   * @function validateInputFields
   * @param {number} productIndex 
   * @param {number} shipmentIndex 
   */
  validateInputFields(productIndex, shipmentIndex) {
    let shipmentSelector = +shipmentIndex + 1
    this.template.querySelectorAll(`.card-body>.details-section[data-product-index="${productIndex}"] .shipment-col>div:nth-child(${shipmentSelector}) [data-id]`).forEach((inputComponent) => {
      inputComponent.reportValidity();
    });
  }
}