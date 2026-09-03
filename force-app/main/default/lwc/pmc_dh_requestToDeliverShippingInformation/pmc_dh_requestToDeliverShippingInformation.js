import { LightningElement, api, track } from "lwc";
import basePath from "@salesforce/community/basePath";
import { deleteItemFromCart } from "commerce/cartApi";

import communityId from "@salesforce/community/Id";
import { isBrazilRegion, formatLabel, formatDate, toastMessageHandler, sortData, SORT_DIRECTION, getRawDateUtil, getLineItemDataFromSessionStorage, getWithExpirationFromSession } from "c/pmc_dh_utilityJs";
import deleteProductFromCart from '@salesforce/apex/PMC_DH_RequestToDeliverController.deleteCartItems';
import getDeliverCheckOutShipmentInfo from "@salesforce/apex/PMC_DH_RequestToDeliverController.getDeliverCheckOutShipmentInfo";
import updateDeliverCheckOutShipmentInfo from "@salesforce/apex/PMC_DH_RequestToDeliverController.updateDeliverCheckOutShipmentInfo";
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import PMC_BrandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

import pmc_quoteCheckoutFlow_shippingInfo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shippingInfo";
import pmc_quoteCheckoutFlow_products from "@salesforce/label/c.pmc_quoteCheckoutFlow_products";
import pmc_quoteCheckoutFlow_totalQuantity from "@salesforce/label/c.pmc_quoteCheckoutFlow_totalQuantity";
import pmc_cartCheckout_sku from "@salesforce/label/c.pmc_cartCheckout_sku";
import pmc_quoteCheckoutFlow_proceed from "@salesforce/label/c.pmc_quoteCheckoutFlow_proceed";
import pmc_requestForQuote_totalQty from "@salesforce/label/c.pmc_requestForQuote_totalQty";
import pmc_quoteCheckoutFlow_incoterms from "@salesforce/label/c.pmc_quoteCheckoutFlow_incoterms";
import pmc_quoteCheckoutFlow_shipFrom from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipFrom";
import pmc_quoteCheckoutFlow_addNewShip from "@salesforce/label/c.pmc_quoteCheckoutFlow_addNewShip";
import pmc_accountDetails_delete from "@salesforce/label/c.pmc_accountDetails_delete";
import pmc_contractDetails_itemNumber from "@salesforce/label/c.pmc_contractDetails_itemNumber";
import pmc_requestToDeliverShippingInformation_contractPoNumber from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_contractPoNumber";
import pmc_rtdShippingInfo_bannerMessage from "@salesforce/label/c.pmc_rtdShippingInfo_bannerMessage";
import pmc_requestToDeliverShippingInformation_deliveryAddress from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_deliveryAddress";
import pmc_requestToDeliverShippingInformation_qty from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_qty";
import pmc_requestToDeliverShippingInformation_deliveryMode from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_deliveryMode";
import pmc_requestToDeliverShippingInformation_noProductsMessage from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_noProductsMessage";
import pmc_quoteCheckoutFlow_quantity from "@salesforce/label/c.pmc_quoteCheckoutFlow_quantity";
import pmc_requestToDeliverShippingInformation_requestedShipmentPlan from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_requestedShipmentPlan";
import pmc_requestToDeliverShippingInformation_frequency from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_frequency";

import pmc_requestToDeliverShippingInformation_startContractDate from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_startContractDate";
import pmc_requestToDeliverShippingInformation_endContractDate from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_endContractDate";
import pmc_requestToDeliverShippingInformation_deliveryPoNumber from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_deliveryPoNumber";
import pmc_requestToDeliverShippingInformation_poIncrementBy from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_poIncrementBy";
import pmc_requestToDeliverShippingInformation_qtyShipmentPlanError from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_qtyShipmentPlanError";
import pmc_requestToDeliverShippingInformation_addNewShipment from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_addNewShipment";
import pmc_requestToDeliverShippingInformation_required from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_required";
import pmc_requestToDeliver_availableQuantityError from "@salesforce/label/c.pmc_requestToDeliver_availableQuantityError";
import pmc_requestToDeliverVolumeError from "@salesforce/label/c.pmc_requestToDeliverVolumeError";
import pmc_requestToDeliverShippingInformation_poIncrementByError from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_poIncrementByError";
import pmc_requestToDeliverShippingInformation_multiple from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_multiple";
import pmc_requestToDeliverShippingInformation_deliveryInstructions from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_deliveryInstructions";
import pmc_requestToDeliverShippingInformation_sellOutPrice from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_sellOutPrice";
import pmc_requestToDeliverShippingInformation_enterNumericValueError from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_enterNumericValueError";
import pmc_requestToDeliverShippingInformation_notaFiscalNumberError from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_notaFiscalNumberError";
import pmc_requestToDeliverShippingInformation_notaFiscalNumber from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_notaFiscalNumber";
import pmc_requestToDeliverShippingInformation_dateValidityError from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_dateValidityError";
import pmc_attention from "@salesforce/label/c.pmc_attention";
import pmc_requestToDeliver_duplicateProductsMessage from "@salesforce/label/c.pmc_requestToDeliver_duplicateProductsMessage";
import pmc_requestToDeliverShippingInformation_shipmentPlanDateValidityError from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_shipmentPlanDateValidityError";
// import pmc_inputElement_patternMismatchError from "@salesforce/label/c.pmc_inputElement_patternMismatchError";
import pmc_requestToDeliverShippingInformation_notaFiscalBillingDate from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_notaFiscalBillingDate";
import pmc_requestForQuote_packType from "@salesforce/label/c.pmc_requestForQuote_packType";
import pmc_requestForQuote_packagingType from "@salesforce/label/c.pmc_requestForQuote_packagingType";
import pmc_modal_close from "@salesforce/label/c.pmc_modal_close";
import pmc_contractDetails_total from "@salesforce/label/c.pmc_contractDetails_total";
import pmc_requestToDeliver_expectedShipmentDate from "@salesforce/label/c.pmc_requestToDeliver_expectedShipmentDate";
import pmc_address_searchAddress from "@salesforce/label/c.pmc_address_searchAddress";
import locale from '@salesforce/i18n/locale';
/**
 * A custom LWC to display the Shipping Information in RTD flow.
 * @alias Pmc_dh_requestToDeliverShippingInformation
 * @extends LightningElement
 * @hideconstructor
 * @author Himanshu Rathore
 * @example
 * <c-pmc_dh_request-to-deliver-shipping-information> </c-pmc_dh_request-to-deliver-shipping-information>
 */

const LABEL = "label";
const MESSAGE_TYPE_WARNING = "warning";
const PACK_TYPES = {
  PACKED: 'Packed',
  BULK: 'Bulk'
}

export default class Pmc_dh_requestToDeliverShippingInformation extends LightningElement {
  @api flag;
  @track labels = {
    pmc_quoteCheckoutFlow_shippingInfo,
    pmc_quoteCheckoutFlow_products,
    pmc_quoteCheckoutFlow_totalQuantity,
    pmc_cartCheckout_sku,
    pmc_quoteCheckoutFlow_proceed,
    pmc_requestForQuote_totalQty,
    pmc_quoteCheckoutFlow_incoterms,
    pmc_quoteCheckoutFlow_shipFrom,
    pmc_quoteCheckoutFlow_addNewShip,
    pmc_accountDetails_delete,
    pmc_contractDetails_itemNumber,
    pmc_requestToDeliverShippingInformation_contractPoNumber,
    pmc_rtdShippingInfo_bannerMessage,
    pmc_requestToDeliverShippingInformation_deliveryAddress,
    pmc_requestToDeliverShippingInformation_qty,
    pmc_requestToDeliverShippingInformation_deliveryMode,
    pmc_requestToDeliverShippingInformation_noProductsMessage,
    pmc_modal_close,
    pmc_quoteCheckoutFlow_quantity,
    pmc_requestToDeliverShippingInformation_requestedShipmentPlan,
    pmc_requestToDeliverShippingInformation_frequency,
    pmc_requestToDeliverShippingInformation_startContractDate,
    pmc_requestToDeliverShippingInformation_endContractDate,
    pmc_requestToDeliverShippingInformation_deliveryPoNumber,
    pmc_requestToDeliverShippingInformation_poIncrementBy,
    pmc_requestToDeliverShippingInformation_qtyShipmentPlanError,
    pmc_requestToDeliverShippingInformation_addNewShipment,
    pmc_requestToDeliverShippingInformation_required,
    pmc_requestToDeliverShippingInformation_poIncrementByError,
    pmc_requestToDeliverShippingInformation_multiple,
    pmc_requestToDeliverShippingInformation_deliveryInstructions,
    pmc_requestToDeliverShippingInformation_sellOutPrice,
    pmc_requestToDeliverShippingInformation_enterNumericValueError,
    pmc_requestToDeliverShippingInformation_notaFiscalNumberError,
    pmc_requestToDeliverShippingInformation_notaFiscalNumber,
    pmc_requestToDeliverShippingInformation_dateValidityError,
    pmc_attention,
    pmc_requestToDeliver_duplicateProductsMessage,
    pmc_requestToDeliverShippingInformation_shipmentPlanDateValidityError,
    pmc_requestForQuote_packType,
    pmc_requestForQuote_packagingType,
    pmc_requestToDeliverShippingInformation_notaFiscalBillingDate,
    pmc_contractDetails_total,
    pmc_requestToDeliver_expectedShipmentDate,
    pmc_address_searchAddress
  };
  @track isLocationBrazil = false;
  @track pageItems = [];
  @track saveToCartItems = [];
  @track productInfoArray = [];
  @track productInfoArrayOrignal = [];
  @track fromSessionContractDetailsbyProduct = {};
  @track shipToArray = [];
  @track picklistObj = {};
  @track getDeliverCheckOutShipmentInfoObject = {};
  @track isCIF = false;
  @track isVCO = false;
  packTypeDisabled = true;
  @track isRemoveEnabled;
  @track isShipmentPlanAvailable;
  @track cssDropdownIcon = "acc-icon";
  @track iconUrlObj = {
    deleteIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-delete.svg`,
    arrowRightIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-arrowright.svg`,
    mosaicLogoUrl: `${PMC_BrandingAssetsStaticResource}/images/logo-mosaic.png`,
    closeIconUrl: `${PMC_BrandingStaticResource}/icons/icon-close.svg`
  };
  @track lineItemData = {}; // Tracked object to store retrieved line item data
  messageBannerType = MESSAGE_TYPE_WARNING;
  monthWeekCount = 0;
  shipmentSectionCount = 0;
  isProceedDisabled = true;
  isContentLoaded = false;
  isSpinner = false;
  pageRendered = false;
  availableQuantityErrorMsg = pmc_requestToDeliver_availableQuantityError;
  requestToDeliverVolumeError = pmc_requestToDeliverVolumeError;
  today;
  minShipmentDate;
  maxShipmentDate;
  effectiveAccountId;
  communityId;
  cartId;
  contractId;
  error;
  isThirdPartyScreen;
  userRegion;


  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.today = new Date().toISOString().split('T')[0];
    this.communityId = communityId;
    if (isBrazilRegion()) {
      this.isLocationBrazil = !this.isLocationBrazil;
    }
    if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
      this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    }
    if (sessionStorage.getItem("userRegion")) {
      this.userRegion = sessionStorage.getItem("userRegion");
    }
    if (sessionStorage.getItem("CONTRACT_ID")) {
      this.contractId = sessionStorage.getItem("CONTRACT_ID");
    }
    if (sessionStorage.getItem("CART_ID")) {
      this.cartId = sessionStorage.getItem("CART_ID");
    }
    this.getDeliverCheckOutShipmentInfoObject = {
      strCommunityId: this.communityId,
      strContractId: this.contractId,
      strCartId: this.cartId,
      strEffectiveAccountId: this.effectiveAccountId,
      strUserRegion: this.userRegion
    };
    this.fetchShipmentInfo();
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (this.pageRendered) return;
    if (this.isContentLoaded) {
      let baseUrl = window.location.origin;
      let contractPageUrl = `${baseUrl}${basePath}/contracts`;
      this.labels.pmc_requestToDeliverShippingInformation_noProductsMessage =
        formatLabel(
          this.labels.pmc_requestToDeliverShippingInformation_noProductsMessage,
          [contractPageUrl]
        );

      this.productInfoArray?.forEach((el, indexProduct) => {
        el.lstShipTo = el.lstShipTo && this.removeDuplicateRecords(el.lstShipTo);
        el.lstIncoterms = el.lstIncoterms && this.removeDuplicateRecords(el.lstIncoterms);


        el.lstDeliveryModes = el.lstDeliveryModes && this.removeDuplicateRecords(el.lstDeliveryModes);
        el.lstShipFrom = el.lstShipFrom && this.removeDuplicateRecords(el.lstShipFrom);
        let href = `${baseUrl}${basePath}/product/${el.strProductId}`;
        el.href = href;
        let datFormattedContractStartDate = el.datContractStartDate ? formatDate(el.datContractStartDate) : '';
        el.datFormattedContractStartDate = datFormattedContractStartDate;
        let datFormattedContractEndDate = el.datContractEndDate ? formatDate(el.datContractEndDate) : '';
        el.datFormattedContractEndDate = datFormattedContractEndDate;
        el.lstShipTo = this.getFieldListOptions(el.strSku, "strShipTo");
        el.lstDeliveryModes = this.getFieldListOptions(
          el.strSku,
          "strDeliveryMode"
        );
        el.lstCartItems.forEach((item, indexShipment) => {
          let shipmentQty = 0;
          item.lstShipmentPlan.forEach((plan, index) => {
            shipmentQty += parseInt(plan.intQuantity, 10);
            if (index === item.lstShipmentPlan.length - 1) {
              item.intQuantity = shipmentQty;
            }
          })
          item.lstIncoterms = this.getFieldListOptions(
            el.strSku,
            "strIncoterms",
            "strShipTo",
            item.strShipTo,
          );
          item.lstShipFrom = this.getFieldListOptions(
            el.strSku,
            "strShipFrom",
            "strIncoterms",
            item.strIncoterms,
            item.strShipTo
          );
          item.isDatNotaFiscalDateDisabled = (item.intFiscalNumber === '' || item.intFiscalNumber === undefined) ? true : false;
          item.isDatNotaFiscalDateRequired = !item.isDatNotaFiscalDateDisabled;
          if (item.isDatNotaFiscalDateRequired) {
            this.template.querySelector(`[data-product-index="${indexProduct}"][data-shipment-index="${indexShipment}"][data-id="datNotaFiscalDate"]`).updateIsRequired();
          }
          if (item.strSkuPackType) {
            item.isPackTypeDisabled = true;
            item.strPackType = item.strSkuPackType;
            if (el.boolThirdParty) {
              if (item.strPackType === PACK_TYPES.PACKED) {
                item.isPackageTypeDisabled = false;
                item.lstPackagingType = el.lstPackagingType;
              }
              else {
                item.isPackageTypeDisabled = true;
                item.strPackageType = '';
                item.lstPackagingType = [];
              }
            }
          }
          else {
            item.isPackTypeDisabled = false;
            if (el.boolThirdParty) item.isPackageTypeDisabled = true;
          }
          this.findAvailableQuantity(indexProduct, indexShipment);

          // Setting up ship to value to default if selected shipTo is not available in shipTo picklist
          let selectedShipToFound = false;
          el.lstShipTo?.forEach((shipTo) => {
            if (shipTo.value === item.strShipTo) {
              selectedShipToFound = true;
            }
          });

          item.strShipTo = selectedShipToFound ? item.strShipTo : "";

          if (item.strIncoterms === 'CIF') {
            this.isCIF = true;
          }

          // Start-GSMD-1297
          console.log('Brazil >>>', isBrazilRegion());
          console.log('item >>> ', item);
          console.log('item.strIncoterms >>> ', item.strIncoterms);
          console.log('item.strDeliveryMode >>> ', item.strDeliveryMode);

          if (!isBrazilRegion()) {//GSMD-1551
            if (item.strIncoterms === "FOB" || item.strIncoterms === "FCA") {
              if (item.strDeliveryMode === "Truck") {
                item.isShipToDisabled = false; // Allow edit
              } else {
                item.isShipToDisabled = true; // Disable
              }
            } else {
              item.isShipToDisabled = true; // Disable
            }
          }
          // End-GSMD-1297
          console.log('item.isShipToDisabled', item.isShipToDisabled);
          console.log('item.strShipTo', item.strShipTo);


        });
        this.getTotalQuantity(indexProduct);
      });
      if (this.isThirdPartyScreen) {
        this.updateShippingInfo();
      }
      this.checkEmptyStatus();
      this.pageRendered = true;
    }
  }

  /**
   * Update ShipTo and ShipFrom values
   * @function updateShippingInfo
   */
  updateShippingInfo = () => {
    if (this.productInfoArray) {
      this.productInfoArray?.forEach((prod) => {
        prod.lstCartItems?.forEach((item) => {
          let shipFrom = prod.lstShipFrom?.find((data) =>
            item.strShipFrom === data.value
          );
          /* if (!shipFrom && prod.lstShipFrom?.length > 0) {
                        shipFrom = prod.lstShipFrom[0];
            }*/
          item.strShipFrom = shipFrom;
        });
      });
    }
  };

  /**
   * Retrieves the stored package type from the session storage and returns a formatted string.
   * If the package type is not available, it returns an empty string.
   *
   * @returns {string} The default package type label or an empty string.
   */
  get getStoredPackageType() {
    if (!this.fromSessionContractDetailsbyProduct?.length) {
      return "";
    }

    return this.productInfoArray[0].lstCartItems[0].strPackageTypeOld;

    // return this.fromSessionContractDetailsbyProduct[0]?.strPackageType !== ""

    //   ? this.labels.pmc_requestForQuote_packagingType + ": " + this.fromSessionContractDetailsbyProduct[0]?.strPackageTypeLabel

    //   : "";
  }

  /**
  * Retrieves the stored pack type from the session storage and returns a formatted string.
  * If the pack type is not available, it returns an empty string.
  *
  * @returns {string} The default pack type label or an empty string.
  */
  get getStoredPackType() {
    if (!this.fromSessionContractDetailsbyProduct?.length) {
      return "";
    }

    return this.productInfoArray[0].lstCartItems[0].strPackType;

    // return this.fromSessionContractDetailsbyProduct[0]?.strPackType !== ""

    //   ? this.labels.pmc_requestForQuote_packType + ": " + this.fromSessionContractDetailsbyProduct[0]?.strPackTypeLabel

    //   : "";
  }

  /**
   * fetch shipment details from backend method
   * @function fetchShipmentInfo
   */
  fetchShipmentInfo = () => {
    this.isSpinner = true;
    getDeliverCheckOutShipmentInfo({
      deliverWrap: this.getDeliverCheckOutShipmentInfoObject
    })
      .then((data) => {
        console.log(' >>>', data);
        console.log('>>> ', Object.keys(data).length);
        console.log(' >>>', JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage);
        if (data && Object.keys(data).length) {
          if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
          }
          this.isVCO = data?.isVCO;
          this.productInfoArrayOrignal = JSON.parse(JSON.stringify(data.lstCartWrapper));
          this.productInfoArray = JSON.parse(JSON.stringify(data.lstCartWrapper));
          this.isThirdPartyScreen = this.productInfoArray?.some(e => e.boolThirdParty === true);
          this.productInfoArray.forEach((e, index) => {
            this.fromSessionContractDetailsbyProduct = JSON.parse(JSON.stringify(getWithExpirationFromSession(`lstContractItems_${e.strProductId}`)));
            e.lstCartItems.forEach(function (cartItem, cartItemIndex) {
              if (cartItem.strPackageType === "" && this.fromSessionContractDetailsbyProduct[0]?.strPackageType !== "") {
                this.productInfoArray[index].lstCartItems[cartItemIndex].strPackageType = this.fromSessionContractDetailsbyProduct[0]?.strPackageType;
                if (e.lstPackagingType) {
                  e.lstPackagingType.filter(item => item.value == `${this.fromSessionContractDetailsbyProduct[0]?.strPackageTypeLabel}`).forEach(item => {
                    item.label = `${this.fromSessionContractDetailsbyProduct[0]?.strPackageTypeLabel} *`;
                  });
                }
              }
              if (cartItem.strPackType === "" && this.fromSessionContractDetailsbyProduct[0]?.strPackType !== "") {
                this.productInfoArray[index].lstCartItems[cartItemIndex].strPackType = this.fromSessionContractDetailsbyProduct[0]?.strPackType;
                if (e.lstPackagingType) {
                  e.lstPackagingType.filter(item => item.value == `${this.fromSessionContractDetailsbyProduct[0]?.strPackTypeLabel}`).forEach(item => {
                    item.label = `${this.fromSessionContractDetailsbyProduct[0]?.strPackTypeLabel} *`;
                  });
                }
              }
            }.bind(this));
            e.lstDeliveryModes = sortData(e.lstDeliveryModes, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
            e.lstFrequency = sortData(e.lstFrequency, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
            e.lstIncoterms = sortData(e.lstIncoterms, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
            e.lstPackType = sortData(e.lstPackType, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
            if (e.lstPackagingType) e.lstPackagingType = sortData(e.lstPackagingType, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
            e.lstShipFrom = sortData(e.lstShipFrom, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
            if (this.isThirdPartyScreen) {
              e.lstDeliverAddressValidated = sortData(e.lstDeliverAddressValidated, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
            } else {
              e.lstShipTo = sortData(e.lstShipTo, LABEL, "alphanumeric", SORT_DIRECTION.ASC);
            }
            let ship = this.isThirdPartyScreen ? e.lstDeliverAddressValidated : e.lstShipTo;
            this.shipToArray.push(ship);
            this.picklistObj.mot = e.lstDeliveryModes;
            this.picklistObj.incoterms = e.lstIncoterms;
            this.picklistObj.packType = e.lstPackType;
            this.picklistObj.packagingType = e.lstPackagingType;
            // e['showSearchAddressModal'] = false;

          });
          this.minShipmentDate = this.productInfoArray[0].datContractStartDate;
          this.maxShipmentDate = this.productInfoArray[0].datContractEndDate;
          let shipmentStartDate = (new Date(this.minShipmentDate)).setHours(0, 0, 0, 0);
          if (shipmentStartDate > new Date(this.today)) {
            this.today = this.minShipmentDate;
          } else {
            this.today = new Date().toISOString().split('T')[0];
          }
        }
        this.isContentLoaded = true;
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
        this.isContentLoaded = true;
        this.isSpinner = false;
      });
  };

  /**
   * On key up for Quantity Field
   * @function handleKeyUp
   * @param {Event} event
   */
  handleKeyUp = (event) => {
    let index1 = event.target.dataset.productIndex;
    let index2 = event.target.dataset.shipmentIndex;
    event.detail.value = event.detail.value.replace(/[^0-9]/g, "");
    this.productInfoArray[index1].lstCartItems[index2][
      event.target.dataset.id
    ] = event.detail.value;
    this.getTotalQuantity(index1);
  };

  /**
   * On key up for Sell-Out Price
   * @function handleSellOutPriceKeyUp
   * @param {Event} event
   */

  handleSellOutPriceKeyUp = (event) => {
    const index1 = event.target.dataset.productIndex;
    const index2 = event.target.dataset.shipmentIndex;
    let formattedValue = event.detail.value.replace(/[^0-9,.]/g, '');
    formattedValue = formattedValue.replace(/,+/g, ',').replace(/\.{2,}/g, '.');
    if (formattedValue.includes(',') && formattedValue.includes('.')) {
      const commaIndex = formattedValue.indexOf(',');
      const dotIndex = formattedValue.indexOf('.');
      formattedValue = commaIndex < dotIndex ? formattedValue.replace(',', '') : formattedValue.replace('.', '');
    }
    formattedValue = formattedValue.replace(/,(?=.*[,.])/g, '').replace(/\.(?=.*[,.])/g, '');
    this.productInfoArray[index1].lstCartItems[index2][event.target.dataset.id] = formattedValue;
  };

  /**
   * On input change event handler
   * @function handleDataChange
   * @param {Event} event
   */
  handleDataChange(event) {
    let index1 = event.target.dataset.productIndex;
    let index2 = event.target.dataset.shipmentIndex;
    console.log(event);
    console.log('handleDataChange disparado — productIndex: ' + index1 + ' ' + index2);

    if (event.target.dataset.id === "strItemNumber") {
      this.productInfoArray[index1].strItemNumber = event.detail.value;
    } else {
      this.productInfoArray[index1].lstCartItems[index2][event.target.dataset.id] = event.target.dataset.id === "strDeliveryInstructions" ? event.target.value : event.detail.value;

      // Retrieve line item data from session storage
      const storedData = getLineItemDataFromSessionStorage(`${this.productInfoArray[index1].strProductId}_${sessionStorage.getItem("CONTRACT_ID")}_${this.productInfoArray[index1].lstCartItems[index2].strContractItemId}`);
      if (storedData) {
        // Update line item data with values from session storage if available
        this.productInfoArray[index1].lstCartItems[index2].intAvailableQty = parseInt(storedData.intAvailableQty, 10) || this.productInfoArray[index1].lstCartItems[index2].intAvailableQty;
        // this.productInfoArray[index1].lstCartItems[index2].intQuantity = parseInt(storedData.intOrderedQty, 10) || this.productInfoArray[index1].lstCartItems[index2].intQuantity;
      }

      if (event.target.dataset.id === "intQuantity") {
        if (
          this.productInfoArray[index1].lstCartItems[index2].intAvailableQty &&
          event.detail.value &&
          event.detail.value >
          this.productInfoArray[index1].lstCartItems[index2].intAvailableQty
        ) {
          this.productInfoArray[index1].lstCartItems[
            index2
          ].isErrorQuantity = true;
          this.productInfoArray[index1].lstCartItems[
            index2
          ].availableQuantityErrorMsg = formatLabel(
            this.availableQuantityErrorMsg,
            [
              this.productInfoArray[index1].lstCartItems[index2].intQuantity,
              this.productInfoArray[index1].lstCartItems[index2]
                .intAvailableQty || ""
            ]
          );

          toastMessageHandler(this.requestToDeliverVolumeError);
        } else {
          sessionStorage.setItem("currentCartSelectedQuantity", event.detail.value);

          this.productInfoArray[index1].lstCartItems[
            index2
          ].isErrorQuantity = false;
        }
        this.getTotalQuantity(index1);
      }
      if (event.target.dataset.id === "strShipTo") {
        if (!this.productInfoArray[index1].boolThirdParty) {
          this.productInfoArray[index1].lstCartItems[index2].strIncoterms = null;
          this.productInfoArray[index1].lstCartItems[index2].strShipFrom = null;
        }
        this.productInfoArray[index1].lstCartItems[index2].isShipFromDisabled = true;
        if (event.detail.value) {
          this.productInfoArray[index1].lstCartItems[index2].isIncotermsDisabled = false;
          let productSku = this.productInfoArray[index1].strSku;
          this.productInfoArray[index1].lstCartItems[index2].lstIncoterms =
            this.getFieldListOptions(
              productSku,
              "strIncoterms",
              "strShipTo",
              event.detail.value,
            );
        } else {
          this.productInfoArray[index1].lstCartItems[
            index2
          ].isIncotermsDisabled = true;
        }
        this.validateQuantityField(index1, index2);
      }
      if (event.target.dataset.id === "strIncoterms") {
        this.productInfoArray[index1].lstCartItems[index2].strShipFrom = null;


        if (event.detail.value) {
          this.productInfoArray[index1].lstCartItems[
            index2
          ].isShipFromDisabled = false;
          let productSku = this.productInfoArray[index1].strSku;
          this.productInfoArray[index1].lstCartItems[index2].lstShipFrom =
            this.getFieldListOptions(
              productSku,
              "strShipFrom",
              "strIncoterms",
              event.detail.value,
              this.productInfoArray[index1].lstCartItems[index2].strShipTo
            );
          if (this.productInfoArray[index1].lstCartItems[index2].strIncoterms == 'CIF' && (this.productInfoArray[index1].lstCartItems[index2].strIncoterms != '' || this.productInfoArray[index1].lstCartItems[index2].strIncoterms != null)) {
            this.isCIF = true;
          }
        } else {
          this.productInfoArray[index1].lstCartItems[
            index2
          ].isShipFromDisabled = true;
        }
        this.validateQuantityField(index1, index2);
      }
      if (event.target.dataset.id === "strDeliveryMode") {
        this.validateQuantityField(index1, index2);
      }
      if (event.target.dataset.id === "strShipFrom") {
        this.validateQuantityField(index1, index2);
      }
      if (event.target.dataset.id === 'strPackType' && this.productInfoArray[index1].boolThirdParty) {
        let packType = event.detail.value;
        if (packType) {
          if (packType === PACK_TYPES.PACKED) {
            this.productInfoArray[index1].lstCartItems[index2].isPackageTypeDisabled = false;
            this.productInfoArray[index1].lstCartItems[index2].lstPackagingType = this.productInfoArray[index1].lstPackagingType;
          }
          else {
            this.productInfoArray[index1].lstCartItems[index2].isPackageTypeDisabled = true;
            this.productInfoArray[index1].lstCartItems[index2].strPackageType = '';
            this.productInfoArray[index1].lstCartItems[index2].lstPackagingType = [];
          }
        }
      }
      if (
        [
          "strShipTo",
          "strShipFrom",
          "strDeliveryMode",
          "strIncoterms",
          "intQuantity",
          "datRequestedShipmentDate"
        ].includes(event.target.dataset.id)
      ) {
        this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan = [];
        this.productInfoArray[index1].lstCartItems[index2].strFrequency = null;
        this.productInfoArray[index1].lstCartItems[
          index2
        ].boolShipmentPlan = false;
        this.productInfoArray[index1].lstCartItems[
          index2
        ].isShipmentPlanErrorQty = false;
        this.productInfoArray[index1].lstCartItems[index2].strDeliveryPONumber =
          isBrazilRegion()
            ? this.productInfoArray[index1].lstCartItems[index2]
              .strDeliveryPONumber
            : null;
        this.productInfoArray[index1].lstCartItems[
          index2
        ].intPONumberIncrement = null;
      }
      if (event.target.dataset.id === "strFrequency") {
        if (event.detail.value) {
          const startDate = this.productInfoArray[index1].datContractStartDate;
          const endDate = this.productInfoArray[index1].datContractEndDate;
          this.calculateMonthWeekDifference(
            startDate,
            endDate,
            event.detail.value
          );
          const maxIterations = Math.min(this.monthWeekCount, 4);
          this.addShipmentLineOnFrequencyChange(event, maxIterations);
        } else {
          let strFrequency = event.detail.value === null ? true : false;
          this.addAutoPopulatedShipmentPlan(event, strFrequency);
        }
      }

      if (event.target.dataset.id === "datRequestedShipmentDate" && event.detail.value && !this.productInfoArray[index1].lstCartItems[index2].strFrequency) {
        this.checkForShipmentDateError(index1, index2);
        if (this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan?.length === 1) {
          {
            this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan[0].datRequestedShipmentDate = event.detail.value;
          }
        }
      }

      if (event.target.dataset.id === "decSellOutPrice" && event.detail.value) {
        this.productInfoArray[index1].lstCartItems[index2].decSellOutPrice = event.detail.value;
      }
      if (event.target.dataset.id === "intFiscalNumber") {
        const currentItem = this.productInfoArray[index1].lstCartItems[index2];
        if (event.detail.value !== "") {
          currentItem.intFiscalNumber = event.detail.value;
          currentItem.isDatNotaFiscalDateDisabled = false;
        } else {
          currentItem.datNotaFiscalDate = "";
          currentItem.isDatNotaFiscalDateDisabled = true;
        }
      }
      if (event.target.dataset.id === "datNotaFiscalDate" && event.detail.value) {
        const currentItem = this.productInfoArray[index1].lstCartItems[index2];
        currentItem.datNotaFiscalDate = event.detail.value;
      }
      // if (event.target.dataset.id === "strDeliveryInstructions") {
      //   const inputValue = event.target.value;
      //   const regex = /^[A-Za-z0-9#,./ -]*$/
      //   if (!regex.test(inputValue)) {
      //     event.target.setCustomValidity(formatLabel(pmc_inputElement_patternMismatchError, [pmc_requestToDeliverShippingInformation_deliveryInstructions]));
      //   } else {
      //     event.target.setCustomValidity('');
      //   }
      //   event.target.reportValidity();
      // }

    }
    this.checkEmptyStatus();
  }

  /**
   * Handles change on Blur for intFiscalNumber
   * @function handleDataBlur
   * @param {Event} event
   */
  handleDataBlur(event) {
    let index1 = parseInt(event.target.dataset.productIndex, 10);
    let index2 = parseInt(event.target.dataset.shipmentIndex, 10);

    if (event.target.dataset.id === "intFiscalNumber") {
      const currentItem = this.productInfoArray[index1].lstCartItems[index2];
      if (event.detail.value && event.detail.value !== '' && event.detail.value !== undefined) {
        currentItem.isDatNotaFiscalDateRequired = true;
      } else {
        currentItem.isDatNotaFiscalDateRequired = false;
      }
      setTimeout(() => {
        this.template.querySelector(`[data-product-index="${index1}"][data-shipment-index="${index2}"][data-id="datNotaFiscalDate"]`).updateIsRequired();
      });
    }
  }


  /**
   * Handles change in shipment data
   * @function handleShipmentDataChange
   * @param {Event} event
   */
  handleShipmentDataChange = (event) => {
    console.log('handleShipmentDataChange >>>', event);
    let index1 = parseInt(event.target.dataset.productIndex, 10);
    let index2 = parseInt(event.target.dataset.shipmentIndex, 10);
    let index3 = parseInt(event.currentTarget.dataset.shipmentPlanIndex, 10);

    this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan[index3][
      event.target.dataset.id
    ] = event.detail.value;

    if (event.detail.value && event.target.dataset.id === "intQuantity") {
      this.checkForQtyShipmentPlanError(index1, index2);
    }
    if (
      event.target.dataset.id === "datRequestedShipmentDate" &&
      event.detail.value && this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan
        ?.length === 1 && this.validateDateFields(event.detail.value)
    ) {
      this.productInfoArray[index1].lstCartItems[index2].datRequestedShipmentDate = event.detail.value;
    }

    if (event.detail.value && event.target.dataset.id === "datRequestedShipmentDate") {
      this.checkDuplicateShipmentPlanRequestedDates(index1, index2);
    }
    this.isDeleteEnabled(event);
    this.checkEmptyStatus();
  };

  /**
   * Check for the given shipment row if quantity field should be disabled
   * @function validateQuantityField
   * @param {number} productIndex
   * @param {number} shipmentIndex
   */
  validateQuantityField(productIndex, shipmentIndex) {
    this.getTotalQuantity(productIndex);
    this.productInfoArray[productIndex].lstCartItems[
      shipmentIndex
    ].intQuantity = null;
    let item = this.productInfoArray[productIndex].lstCartItems[shipmentIndex];
    if (
      item.strShipTo &&
      item.strDeliveryMode &&
      item.strIncoterms &&
      item.strShipFrom
    ) {
      item.isQuantityDisabled = false;
      this.findAvailableQuantity(productIndex, shipmentIndex);
    } else {
      item.isQuantityDisabled = true;
    }
  }

  /**
   * Method to Check Error if Total Qty is Greater than Input Qty
   * @function checkForQtyShipmentPlanError
   * @param {number} index1
   * @param {number} index2
   */
  checkForQtyShipmentPlanError = (index1, index2) => {
    let totalShipmentQty = this.getTotalShipmentQuantity(index1, index2);
    if (totalShipmentQty !== parseInt(this.productInfoArray[index1].lstCartItems[index2].intQuantity, 10)) {
      this.productInfoArray[index1].lstCartItems[index2].isShipmentPlanErrorQty = true;
    } else {
      this.productInfoArray[index1].lstCartItems[index2].isShipmentPlanErrorQty = false;
    }
  }

  /**
   * Method to Check Error if Requested Shipment Date is within the contract start and End date
   * @function checkForShipmentDateError
   * @param {number} index1
   * @param {number} index2
   */
  checkForShipmentDateError = (index1, index2) => {
    const cartItem = this.productInfoArray[index1].lstCartItems[index2];

    const isRequestedShipmentDateValid = this.validateDateFields(cartItem.datRequestedShipmentDate);
    cartItem.isShipmentDateError = !isRequestedShipmentDateValid;

    const inpDate = getRawDateUtil(cartItem.datRequestedShipmentDate)?.setUTCHours(0, 0, 0, 0);
    const minDate = new Date(this.minShipmentDate)?.setUTCHours(0, 0, 0, 0);
    const maxDate = new Date(this.maxShipmentDate)?.setUTCHours(0, 0, 0, 0);

    cartItem.warningShipmentDate = false;


    if (inpDate < minDate || inpDate > maxDate) {
      cartItem.warningShipmentDate = true;
    }


    /*let isRequestedShipmentDateValid = this.validateDateFields(this.productInfoArray[index1].lstCartItems[index2].datRequestedShipmentDate);
    if (!isRequestedShipmentDateValid) {
      this.productInfoArray[index1].lstCartItems[index2].isShipmentDateError = true;
    } else {
      this.productInfoArray[index1].lstCartItems[index2].isShipmentDateError = false;
    }*/
  }

  /**
   * To remove Duplicate Records from Picklists
   * @function removeDuplicateRecords
   * @param {Array} arr
   */
  removeDuplicateRecords(arr) {
    let filtered = [];
    let uniqueObject = {};
    arr.forEach(item => {
      let objValue = item.value;
      uniqueObject[objValue] = item;
    });
    Object.values(uniqueObject).forEach(item => {
      filtered.push(item);
    });

    return filtered;
  }

  /**
   * Get available quantity for the given shipment row
   * @function findAvailableQuantity
   * @param {number} productIndex
   * @param {number} shipmentIndex
   */
  findAvailableQuantity(productIndex, shipmentIndex) {
    let item = this.productInfoArray[productIndex].lstCartItems[shipmentIndex];
    if (this.isThirdPartyScreen) {
      item.intAvailableQty = this.productInfoArray[productIndex].lstContractItems.reduce((total, contractItem) => total + contractItem.intAvailableQuantity, 0);
    } else {
      item.intAvailableQty = this.productInfoArray[
        productIndex
      ].lstContractItems?.find(
        (contract) =>
          contract.strShipTo === item.strShipTo &&
          contract.strDeliveryMode === item.strDeliveryMode &&
          contract.strIncoterms === item.strIncoterms &&
          contract.strShipFrom === item.strShipFrom
      )?.intAvailableQuantity;
    }
  }

  /**
   * If product image doesn't load, display default image
   * @function handleImageError
   * @param {Event} event
   */
  handleImageError = (event) => {
    event.currentTarget.src = this.iconUrlObj.mosaicLogoUrl;
    event.currentTarget.style.height = "unset";
    event.currentTarget.onerror = null;
  };

  /**
   * Return total quantity for the given product
   * @function getTotalQuantity
   * @param {number} productIndex
   */
  getTotalQuantity = (productIndex) => {
    const quantities = this.productInfoArray[productIndex]?.lstCartItems.map(
      (ele) => (ele.intQuantity ? +ele.intQuantity : 0)
    );
    const total = quantities?.reduce((acc, curr) => acc + curr);
    this.productInfoArray[productIndex].strTotalQty = total;
  };

  /**
   * Return total Shipment Quantity for the given shipment Plan
   * @function getTotalShipmentQuantity
   * @param {number} productIndex
   * @param {number} shipmentIndex
   */
  getTotalShipmentQuantity = (productIndex, shipmentIndex) => {
    let shipmentQty = 0;
    this.productInfoArray[productIndex].lstCartItems[
      shipmentIndex
    ].lstShipmentPlan.forEach((el) => {
      shipmentQty += (+el.intQuantity);
    });
    return shipmentQty;
  };

  /**
   * Return list of given field for each product
   * @function getFieldListOptions
   * @param {string} productSku
   * @param {string} fieldName
   * @param {string} filterByField
   * @param {string} filterByValue
   * @param {string} shipTo
   */
  getFieldListOptions(
    productSku,
    fieldName,
    filterByField = null,
    filterByValue = null,
    shipTo = null,
  ) {
    let list = this.productInfoArray?.find(
      (product) => product.strSku === productSku);

    let listOfValuesPresent = [];
    if (filterByField) {

      listOfValuesPresent = this.productInfoArray
        ?.find((product) => product.strSku === productSku)
        ?.lstContractItems?.filter(
          (contract) => contract[filterByField] === filterByValue
        )
      if (shipTo) {
        listOfValuesPresent = listOfValuesPresent?.filter(
          (contract) => contract.strShipTo === shipTo
        )
      }
      listOfValuesPresent = listOfValuesPresent?.map((contract) => contract[fieldName]);
    } else {
      listOfValuesPresent = this.productInfoArray
        ?.find((product) => product.strSku === productSku)
        ?.lstContractItems?.map((contract) => contract[fieldName]);
    }

    switch (fieldName) {
      case "strShipTo":
        list = list.lstShipTo;
        break;
      case "strShipFrom":
        list = list.lstShipFrom;
        break;
      case "strIncoterms":
        list = list.lstIncoterms;
        break;
      case "strDeliveryMode":
        list = list.lstDeliveryModes;
        break;
      default:
        break;
    }

    list = list?.filter((el) => listOfValuesPresent?.includes(el.value));
    return list;
  }

  /**
   * Method to check if User Input Quantity Exceed from given Contract
   * @function checkProductTotalQuantityTPF
   */
  checkProductTotalQuantityTPF = (indexProduct = null) => {
    let allValid = true;
    if (this.isThirdPartyScreen) {
      this.productInfoArray?.forEach((prod, index) => {
        if (indexProduct !== null && index !== indexProduct) return;
        let productIndex = +index + 2;
        let qtyValidationCount = 0;
        prod.lstCartItems?.forEach((item, itemIndex) => {
          let intAvailableQty = prod.lstContractItems.reduce((total, contractItem) => total + contractItem.intAvailableQuantity, 0);
          prod.intAvailableQty = intAvailableQty;
          let quantities = prod.lstCartItems.map(
            (ele) => (ele.intQuantity ? +ele.intQuantity : 0)
          );
          let totalQuantity = quantities?.reduce((acc, curr) => acc + curr);
          prod.totalQuantity = totalQuantity;
          if (totalQuantity > intAvailableQty) {
            qtyValidationCount++;
          }
          prod.qtyExceedFlag = qtyValidationCount > 0 ? true : false;
          const fieldsToHighlight = ['intQuantity']
          fieldsToHighlight?.forEach(field => {
            const element = this.template.querySelectorAll(`.card-body>div:nth-child(${productIndex}) [data-id="${field}"]`)[itemIndex];
            if (prod.qtyExceedFlag) {
              element?.reportErrorValidity();
              allValid = false;
              prod.availableQuantityErrorMsg = formatLabel(
                this.availableQuantityErrorMsg,
                [
                  this.productInfoArray[index].totalQuantity,
                  this.productInfoArray[index].intAvailableQty || ""
                ]
              );
            } else {
              element?.removeReportErrorValidity();
            }
          });
        })
      });
    }
    return allValid;
  }

  /**
   * Inability Method for a user to add a duplicate product line in RTD & TPF flow.
   * @function checkDuplicateRows
   * @param {number} indexProduct
   */
  checkDuplicateRows = (indexProduct = null) => {
    let allValid = true;
    this.productInfoArray.forEach((el, index) => {
      if (indexProduct !== null && index !== indexProduct) return;
      let productIndex = +index + 2;
      let duplicateCount = 0;
      el.lstCartItems?.forEach((item, itemIndex, arr) => {
        if (!item.strShipFrom || !item.strDeliveryMode || !item.strIncoterms || !item.strShipFrom) return;
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
        const fieldsToHighlight = this.isThirdPartyScreen ? ['strShipTo'] : ['strShipTo', 'strIncoterms', 'strDeliveryMode', 'strShipFrom']
        fieldsToHighlight?.forEach(field => {
          const element = this.template.querySelectorAll(`.card-body>div:nth-child(${productIndex}) [data-id="${field}"]`)[itemIndex];
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
   * Inability Method for a user to add a duplicate Shipment Plan Requested Date in RTD & TPF flow.
   * @function checkDuplicateShipmentPlanRequestedDates
   * @param {number} indexProduct
   * @param {number} indexShipment
   */
  checkDuplicateShipmentPlanRequestedDates = (indexProduct = null, indexShipment = null) => {
    let allValid = true;
    this.productInfoArray.forEach((el, index) => {
      if (indexProduct !== null && index !== indexProduct) return;
      let productIndex = +index + 2;
      el.lstCartItems?.forEach((item, elIndex) => {
        if (indexShipment !== null && elIndex !== indexShipment) return;
        let duplicateCount = 0;
        let shipmentSelector = elIndex + 1;
        item.lstShipmentPlan?.forEach((plan, itemIndex, arr) => {
          let shipmentPlanSelector = itemIndex + 2;
          const isDuplicate = arr.some((otherItem, otherIndex) => {
            return (
              itemIndex !== otherIndex &&
              plan.datRequestedShipmentDate !== null && otherItem.datRequestedShipmentDate !== null && plan.datRequestedShipmentDate === otherItem.datRequestedShipmentDate
            );
          });
          item.isDuplicate = isDuplicate;
          if (isDuplicate) {
            duplicateCount++;
          }
          const fieldsToHighlight = ['datRequestedShipmentDate'];
          fieldsToHighlight?.forEach(field => {
            let element = this.template.querySelector(`.card-body>div:nth-child(${productIndex}) .shipment-col>div:nth-child(${shipmentSelector}) .shipment-plan-container .shipment-plan-details-sections>div:nth-child(${shipmentPlanSelector}) [data-id="${field}"]`);
            if (item.isDuplicate) {
              element?.reportErrorValidity();
              allValid = false;
            } else {
              element?.removeReportErrorValidity();
            }
          });
        })
        if (duplicateCount > 0) {
          item.isDuplicate = true;
        }
      })
    })
    return allValid;
  }

  /**
   * add new shipment details for the respective product on click
   * @function addShipment
   * @param {Event} event
   */
  addShipment = (event) => {
    let index = parseInt(event.target.dataset.productIndex, 10);
    if (!this.checkDuplicateRows(index)) return;
    this.productInfoArray?.forEach((el, i) => {
      if (i === index) {
        el.lstCartItems = [
          ...el.lstCartItems,
          {
            intQuantity: "",
            strCartItemId: "",
            strShipTo: null,
            strShipFrom: null,
            strIncoterms: el.lstCartItems[0].strIncoterms,
            strDeliveryMode: el.lstCartItems[0].strDeliveryMode,
            datRequestedShipmentDate: null,
            strSource: el.lstCartItems[0].strSource ? el.lstCartItems[0].strSource : null,
            strSubscriptionId: el.lstCartItems[0].strSubscriptionId,
            isIncotermsDisabled: true,
            isShipFromDisabled: true,
            isQuantityDisabled: true
          }
        ];
        if (isBrazilRegion()) {
          el.lstCartItems[el.lstCartItems.length - 1].strPackType = el.lstCartItems[0].strPackType ? el.lstCartItems[0].strPackType : null;
          el.lstCartItems[el.lstCartItems.length - 1].strSkuPackType = el.lstCartItems[0].strPackType;
          el.lstCartItems[el.lstCartItems.length - 1].strPackageType = el.lstCartItems[0].strPackageType ? el.lstCartItems[0].strPackageType : null;
          el.lstCartItems[el.lstCartItems.length - 1].isPackTypeDisabled = el.lstCartItems[0].strSkuPackType ? true : false;
        }
      }
    });
    this.getTotalQuantity(index);
    this.isProceedDisabled = true;
  };

  /**
   * add new shipment details for the respective product on click for Third-Party Scenario Only
   * @function addthirdPartyAddShipmentShipment
   * @param {Event} event
   */
  thirdPartyAddShipment = (event) => {
    let index = parseInt(event.target.dataset.productIndex, 10);
    if (!this.checkDuplicateRows(index) || !this.checkProductTotalQuantityTPF(index)) return;
    this.productInfoArray?.forEach((el, i) => {
      if (i === index) {
        el.lstCartItems = [
          ...el.lstCartItems,
          {
            intQuantity: "",
            strCartItemId: "",
            strShipTo: null,
            strShipFrom: el.lstCartItems[0].strShipFrom,
            strIncoterms: el.lstCartItems[0].strIncoterms,
            strDeliveryMode: el.lstCartItems[0].strDeliveryMode,
            isIncotermsDisabled: false,
            isDeliveryModeDisabled: false,
            strDeliveryModeLabel: el.lstCartItems[0].strDeliveryMode,
            strIncotermsLabel: el.lstCartItems[0].strIncoterms || "",
            strSource: el.lstCartItems[0].strSource ? el.lstCartItems[0].strSource : null,
            strSubscriptionId: el.lstCartItems[0].strSubscriptionId,
            datRequestedShipmentDate: null,
            isDecSellOutPriceDisabled: false,
            isIntFiscalNumberDisabled: false,
            isDatNotaFiscalDateDisabled: true
          }
        ];
        if (isBrazilRegion()) {
          el.lstCartItems[el.lstCartItems.length - 1].strPackType = el.lstCartItems[0].strPackType ? el.lstCartItems[0].strPackType : null;
          el.lstCartItems[el.lstCartItems.length - 1].strSkuPackType = el.lstCartItems[0].strPackType;
          el.lstCartItems[el.lstCartItems.length - 1].strPackageType = el.lstCartItems[0].strPackageType ? el.lstCartItems[0].strPackageType : null;
          el.lstCartItems[el.lstCartItems.length - 1].isPackTypeDisabled = el.lstCartItems[0].strPackType ? true : false;
          el.lstCartItems[el.lstCartItems.length - 1].strPackageTypeFlag = el.lstCartItems[0].strPackageTypeFlag ? true : el.lstCartItems[0].strPackageTypeFlag;


          el.lstCartItems[el.lstCartItems.length - 1].lstPackagingType = el.lstCartItems[0].strPackType === PACK_TYPES.PACKED ? el.lstPackagingType : [];
          el.lstCartItems[el.lstCartItems.length - 1].isPackageTypeDisabled = el.lstCartItems[0].strPackType === PACK_TYPES.PACKED ? false : true


        }
      }
    });

    this.getTotalQuantity(index);
    this.isProceedDisabled = true;
  };

  /**
   * delete a shipment details row on click
   * @function deleteShipment
   * @param {Event} event
   */
  deleteShipment = (event) => {
    let index1 = parseInt(event.currentTarget.dataset.productIndex, 10);
    let index2 = parseInt(event.currentTarget.dataset.shipmentIndex, 10);
    let cartItemId = event.currentTarget.dataset.cartId;
    let shipmentPalnCartItemIdsToDelete = [];
    this.isShipmentPlanAvailable = this.productInfoArray[index1]?.lstCartItems[index2]?.lstShipmentPlan?.length > 1 ? true : false;
    if (this.isShipmentPlanAvailable) {
      const currShipmentPlanLength = this.productInfoArray[index1].lstCartItems[index2]?.lstShipmentPlan.length;
      for (let i = 0; i < currShipmentPlanLength; i++) {
        if (this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan[i]?.strCartItemId) {
          shipmentPalnCartItemIdsToDelete.push(this.productInfoArray[index1].lstCartItems[index2]?.lstShipmentPlan[i]?.strCartItemId);
        }
      }
      this.deleteLineItemProduct(shipmentPalnCartItemIdsToDelete);
    } else {
      if (cartItemId !== "") {
        this.deleteFromCartHandler(cartItemId);
      }
    }
    this.productInfoArray[index1].lstCartItems?.splice(index2, 1);
    if (!this.productInfoArray[index1].lstCartItems.length) {
      this.productInfoArray.splice(index1, 1);
    }
    this.getTotalQuantity(index1);
    this.checkEmptyStatus();
    setTimeout(() => {
      if (this.productInfoArray[index1]?.isDuplicate) {
        this.checkDuplicateRows(index1);
      }
      if (this.productInfoArray[index1]?.qtyExceedFlag) {
        this.checkProductTotalQuantityTPF(index1);
      }
      this.validateInputFields(index1, index2);
    });

  };

  /**
   * To open a shipment details Accordian row on click
   * @function expandShipment
   * @param {Event} event
   */
  expandShipment = (event) => {
    const productIndex = parseInt(event.target.dataset.productIndex, 10);
    const shipmentIndex = parseInt(event.target.dataset.shipmentIndex, 10);
    const shipmentDiv = this.template.querySelector(`.shipment-plan-container[data-product-index="${productIndex}"][data-shipment-index="${shipmentIndex}"]`);
    const accordionIcon = this.template.querySelector(`.acc-icon[data-product-index="${productIndex}"][data-shipment-index="${shipmentIndex}"]`);
    if (!accordionIcon.classList.contains("down") && this.validateQtyShipmntDate(event) || !this.checkDuplicateRows(productIndex) || !this.checkProductTotalQuantityTPF(productIndex)) return;
    if (accordionIcon.classList.contains("down") && !this.checkDuplicateShipmentPlanRequestedDates(productIndex, shipmentIndex)) {
      shipmentDiv.style.display = shipmentDiv.style.display === "block" ? "block" : "none";
    } else {
      shipmentDiv.style.display = shipmentDiv.style.display === "block" ? "none" : "block";
      accordionIcon.classList.toggle("down");
    }
    const isAccOpen = accordionIcon.classList.contains("down");
    this.productInfoArray[productIndex].lstCartItems[
      shipmentIndex
    ].isShipToDisabled = isAccOpen;
    this.productInfoArray[productIndex].lstCartItems[
      shipmentIndex
    ].isShipFromDisabled = isAccOpen;
    this.productInfoArray[productIndex].lstCartItems[
      shipmentIndex
    ].isQuantityDisabled = isAccOpen;
    this.productInfoArray[productIndex].lstCartItems[
      shipmentIndex
    ].isShipmentDateDisabled = isAccOpen;
    this.productInfoArray[productIndex].lstCartItems[
      shipmentIndex
    ].isDeliveryModeDisabled = isAccOpen;
    this.productInfoArray[productIndex].lstCartItems[
      shipmentIndex
    ].isIncotermsDisabled = isAccOpen;
    this.productInfoArray[productIndex].lstCartItems[
      shipmentIndex
    ].isDecSellOutPriceDisabled = isAccOpen;
    this.productInfoArray[productIndex].lstCartItems[
      shipmentIndex
    ].isIntFiscalNumberDisabled = isAccOpen;
    this.productInfoArray[productIndex].lstCartItems[
      shipmentIndex
    ].isDatNotaFiscalDateDisabled = isAccOpen;
    this.addAutoPopulatedShipmentPlan(event);
    this.checkForNotaFiscalBillingDate(event);
  };

  /**
   * When User close Accordion then add the default state for Nota Fiscal Billing Date
   * @function checkForNotaFiscalBillingDate
   * @param {Event} event
   */
  checkForNotaFiscalBillingDate = (event) => {
    const productIndex = parseInt(event.target.dataset.productIndex, 10);
    const shipmentIndex = parseInt(event.target.dataset.shipmentIndex, 10);
    const element = this.productInfoArray[productIndex].lstCartItems[shipmentIndex];
    const accordionIcon = this.template.querySelector(`.acc-icon[data-product-index="${productIndex}"][data-shipment-index="${shipmentIndex}"]`);
    if (!accordionIcon.classList.contains("down")) {
      element.isDatNotaFiscalDateDisabled = (element.intFiscalNumber === '' || element.intFiscalNumber === undefined) ? true : false;
    }
  }

  /**
   * When User Clicks on Accordion then one row will auto populate with QTY and Shipment Date
   * @function addAutoPopulatedShipmentPlan
   * @param {Event} event
   * @param {string} strFrequency
   */
  addAutoPopulatedShipmentPlan = (event, strFrequency) => {
    let index1 = event.target.dataset.productIndex;
    let index2 = event.target.dataset.shipmentIndex;
    if (
      (!this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan ||
        this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan
          ?.length === 0) &&
      !this.productInfoArray[index1].lstCartItems[index2].strFrequency
    ) {
      this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan = [
        {
          strCartItemId: this.productInfoArray[index1].lstCartItems[index2].strCartItemId,
          intQuantity:
            this.productInfoArray[index1].lstCartItems[index2].intQuantity,
          datRequestedShipmentDate:
            this.productInfoArray[index1].lstCartItems[index2]
              .datRequestedShipmentDate,
          strDeliveryPONumber: ""
        }
      ];
    } else if (
      this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan
        ?.length === 1 &&
      !this.productInfoArray[index1].lstCartItems[index2].strFrequency
    ) {
      this.productInfoArray[index1].lstCartItems[
        index2
      ].lstShipmentPlan[0].intQuantity =
        this.productInfoArray[index1].lstCartItems[index2].intQuantity;
      this.template.querySelector(`[data-product-index="${index1}"][data-shipment-index="${index2}"][data-shipment-plan-index="0"][data-id="intQuantity"]`).reportValidity();
      this.productInfoArray[index1].lstCartItems[
        index2
      ].lstShipmentPlan[0].datRequestedShipmentDate =
        this.productInfoArray[index1].lstCartItems[
          index2
        ].datRequestedShipmentDate;
      this.template.querySelector(`[data-product-index="${index1}"][data-shipment-index="${index2}"][data-shipment-plan-index="0"][data-id="datRequestedShipmentDate"]`).reportValidity();
    } else if (strFrequency) {
      this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan = [
        {
          strCartItemId: this.productInfoArray[index1].lstCartItems[index2].strCartItemId,
          intQuantity:
            this.productInfoArray[index1].lstCartItems[index2].intQuantity,
          datRequestedShipmentDate:
            this.productInfoArray[index1].lstCartItems[index2]
              .datRequestedShipmentDate,
          strDeliveryPONumber: ""
        }
      ];
    }
    this.checkForQtyShipmentPlanError(index1, index2);
    this.isDeleteEnabled(event);
  };

  /**
   * add new shipment line for the respective shipment item on click
   * @function addShipmentLine
   * @param {Event} event
   */
  addShipmentLine = (event) => {
    let index1 = parseInt(event.target.dataset.productIndex, 10);
    let index2 = parseInt(event.currentTarget.dataset.shipmentIndex, 10);
    if (!this.checkDuplicateShipmentPlanRequestedDates(index1, index2)) return;

    if (!this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan) {
      this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan = [];
    }

    this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan = [
      ...this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan,
      {
        strCartItemId: "",
        intQuantity: "",
        datRequestedShipmentDate: null,
        strDeliveryPONumber: ""
      }
    ];
    this.isDeleteEnabled(event);
  };

  /**
   * delete/remove a shipment line row on click
   * @function removeShipmentLine
   * @param {Event} event
   */
  removeShipmentLine = (event) => {
    let index1 = parseInt(event.currentTarget.dataset.productIndex, 10);
    let index2 = parseInt(event.currentTarget.dataset.shipmentIndex, 10);
    let index3 = parseInt(event.currentTarget.dataset.shipmentPlanIndex, 10);
    let cartItemId = event.currentTarget.dataset.cartItemId;
    this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan.splice(index3, 1);
    if (cartItemId !== "") {
      this.deleteFromCartHandler(cartItemId);
    }
    this.checkForQtyShipmentPlanError(index1, index2);
    this.isDeleteEnabled(event);
    this.checkEmptyStatus();
    if (this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan?.length === 1 && this.validateDateFields(this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan[0].datRequestedShipmentDate)) {
      this.productInfoArray[index1].lstCartItems[index2].datRequestedShipmentDate = this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan[0].datRequestedShipmentDate;
    }
    this.checkDuplicateShipmentPlanRequestedDates(index1, index2);
    setTimeout(() => {
      this.validateInputFields(index1, index2, index3);
    });
  };

  /**
   * Checking for each line item if remove button should be visible
   * @function isDeleteEnabled
   * @param {Event} event
   */
  isDeleteEnabled(event) {
    let index1 = event.currentTarget.dataset.productIndex;
    let index2 = event.currentTarget.dataset.shipmentIndex;
    this.isRemoveEnabled = this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan.length > 1 ? true : false;
    this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan[0].hideRemoveBtn = false;
    for (let i = 1; i < this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan.length; i++) {
      this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan[i].hideRemoveBtn = true;
    }
    if (this.isRemoveEnabled) {
      this.productInfoArray[index1].lstCartItems[
        index2
      ].datRequestedShipmentDate = !this.productInfoArray[index1].lstCartItems[
        index2
      ].strFrequency
          ? this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan[0]
            .datRequestedShipmentDate
            ? this.productInfoArray[index1].lstCartItems[index2]
              .lstShipmentPlan[0].datRequestedShipmentDate
            : this.productInfoArray[index1].lstCartItems[index2]
              .datRequestedShipmentDate
          : this.productInfoArray[index1].lstCartItems[index2]
            .datRequestedShipmentDate;
      this.productInfoArray[index1].lstCartItems[
        index2
      ].boolShipmentPlan = true;
    } else {
      this.productInfoArray[index1].lstCartItems[
        index2
      ].datRequestedShipmentDate = !this.productInfoArray[index1].lstCartItems[
        index2
      ].strFrequency && this.validateDateFields(event.detail.value)
          ? this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan[0]
            .datRequestedShipmentDate
            ? this.productInfoArray[index1].lstCartItems[index2]
              .lstShipmentPlan[0].datRequestedShipmentDate
            : this.productInfoArray[index1].lstCartItems[index2]
              .datRequestedShipmentDate
          : this.productInfoArray[index1].lstCartItems[index2]
            .datRequestedShipmentDate;
      this.productInfoArray[index1].lstCartItems[
        index2
      ].boolShipmentPlan = false;
    }
    this.checkEmptyStatus();
  }

  /**
   * When user Select Picklist from Frequency Dropdown - Add shipment Plan Lines Accordingly
   * @function addShipmentLineOnFrequencyChange
   * @param {Event} event
   * @param {number} maxIterations
   */
  addShipmentLineOnFrequencyChange = (event, maxIterations) => {
    let index1 = parseInt(event.currentTarget.dataset.productIndex, 10);
    let index2 = parseInt(event.currentTarget.dataset.shipmentIndex, 10);

    let lstShipmentPlanCartItemIds = this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan;
    this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan = [];
    for (let i = 0; i < maxIterations; i++) {
      const newLine = {
        strCartItemId: lstShipmentPlanCartItemIds[i]?.strCartItemId || "",
        intQuantity: "",
        datRequestedShipmentDate: null,
        strDeliveryPONumber: ""
      };
      this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan.push(
        newLine
      );
    }

    const quantity = this.productInfoArray[index1].lstCartItems[index2].intQuantity;
    let lstShipmentPlan = this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan;
    const equalQuantity = Math.floor(quantity / maxIterations);
    const remainingQuantity = quantity % maxIterations;
    lstShipmentPlan.forEach((line) => {
      line.intQuantity = equalQuantity;
    });
    lstShipmentPlan[maxIterations - 1].intQuantity += remainingQuantity;
    this.checkForQtyShipmentPlanError(index1, index2);
    this.checkDuplicateShipmentPlanRequestedDates(index1, index2);
    this.isDeleteEnabled(event);
  };

  /**
   * Function to calculate the number of months and weeks between two Dates
   * @function calculateMonthWeekDifference
   * @param {date} startDate
   * @param {date} endDate
   * @param {number} frequency
   */
  calculateMonthWeekDifference = (startDate, endDate, frequency) => {
    const start = new Date(startDate);
    const end = new Date(endDate);
    let timeDifference = end - start;
    const millisecondsPerDay = 24 * 60 * 60 * 1000;
    const averageDaysPerMonth = 30.44;
    const numberOfDays = Math.round(timeDifference / millisecondsPerDay);
    const numberOfMonths = Math.round(numberOfDays / averageDaysPerMonth);
    const numberOfWeeks = Math.round(numberOfDays / 7);
    let result;

    if (frequency === "Monthly") {
      result = `${numberOfMonths}`;
    } else if (frequency === "Weekly") {
      result = `${numberOfWeeks}`;
    }
    this.monthWeekCount = result;
  };

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
   * Backend method to remove line level product
   * @function deleteLineItemProduct
   * @param {string} cartItemsIds
   */
  deleteLineItemProduct(cartItemsIds) {
    this.isSpinner = true;
    deleteProductFromCart({
      strCartId: this.cartId,
      lstCartItemsId: cartItemsIds
    })
      .then(() => {
        this.isSpinner = false;
      })
      .catch((error) => {
        toastMessageHandler();
        this.isSpinner = false;
        this.error = error;
      });
  }

  /**
   * passing field values to backend and giving next step details to parent component
   * @function proceedButtonHandler
   */
  proceedButtonHandler = () => {
    if (!this.checkDuplicateRows() || !this.checkDuplicateShipmentPlanRequestedDates() || !this.checkProductTotalQuantityTPF()) return;
    this.productInfoArray.forEach((ele, index1) => {
      let productInfoObj = {
        strProductId: ele.strProductId,
        strProductName: ele.strProductName,
        strSku: ele.strSku,
        strImgSrc: ele.strImgSrc,
        strItemNumber: ele.strItemNumber,
        strContractId: this.contractId,
        datContractStartDate: ele.datContractStartDate,
        datContractEndDate: ele.datContractEndDate,
        strContractPONumber: ele.strContractPONumber,
        intTotalQuantity: ele.intTotalQuantity,
        lstCartItems: []
      };

      ele.lstCartItems.forEach((item, index2) => {
        let shipmentInfoObj = {
          strCartItemId: item.strCartItemId,
          intQuantity: parseInt(item.intQuantity, 10),
          strShipTo: item.strShipTo,
          datRequestedShipmentDate: item.datRequestedShipmentDate,
          strIncoterms: item.strIncoterms,
          strDeliveryMode: item.strDeliveryMode,
          strShipFrom: ele.boolThirdParty ? item.strShipFrom.value : item.strShipFrom,
          strSource: item.strSource,
          strDeliveryPONumber: item.strDeliveryPONumber,
          strFrequency: item.strFrequency,
          strDeliveryInstructions: item.strDeliveryInstructions,
          strSubscriptionId: item.strSubscriptionId,
          intPONumberIncrement: parseInt(item.intPONumberIncrement, 10),
          intFiscalNumber: parseInt(item.intFiscalNumber, 10),
          datNotaFiscalDate: item.datNotaFiscalDate,
          decSellOutPrice: ele.boolThirdParty ?
            (typeof item?.decSellOutPrice === 'string' ?
              (item.decSellOutPrice.includes(',') ? parseFloat(item.decSellOutPrice.replace(/,/g, '.')).toFixed(2) : parseFloat(item?.decSellOutPrice).toFixed(2)) :
              (typeof item?.decSellOutPrice === 'number' ? parseFloat(item.decSellOutPrice).toFixed(2) : null)) : null,
          boolShipmentPlan:
            item.boolShipmentPlan || item.lstShipmentPlan?.length > 1,
          lstShipmentPlan: []
        };

        this.shipmentSectionCount++;
        const productCartItemNumber = `${ele.strCartReferenceNumber}-${this.shipmentSectionCount}-1`
        shipmentInfoObj.strCartItemReferenceNumber = productCartItemNumber;

        if (isBrazilRegion()) {
          shipmentInfoObj.strPackType = item.strPackType;
          if (ele.boolThirdParty) shipmentInfoObj.strPackageType = item.strPackageType;
        }

        const deliveryPONumber = item.strDeliveryPONumber;
        const poNumberIncrement = item.intPONumberIncrement;
        const currShipmentPlanLength = item.lstShipmentPlan.length;
        const actualShipmentPlanLength = this.productInfoArrayOrignal[index1].lstCartItems[index2]?.lstShipmentPlan.length;
        if (currShipmentPlanLength > 0) {
          if (currShipmentPlanLength < actualShipmentPlanLength) {
            for (let i = currShipmentPlanLength; i < actualShipmentPlanLength; i++) {
              this.deleteFromCartHandler(this.productInfoArrayOrignal[index1].lstCartItems[index2]?.lstShipmentPlan[i].strCartItemId);
            }
          }
        }
        item.lstShipmentPlan?.forEach((plan, index) => {
          let shipmentPlanItem = {
            strCartItemId: plan.strCartItemId ? plan.strCartItemId : "",
            intQuantity: parseInt(plan.intQuantity, 10),
            datRequestedShipmentDate: plan.datRequestedShipmentDate
          };
          if (isBrazilRegion() || (deliveryPONumber && !poNumberIncrement)) {
            shipmentPlanItem.strDeliveryPONumber = deliveryPONumber;
          } else {
            if (deliveryPONumber && poNumberIncrement) {
              shipmentPlanItem.strDeliveryPONumber =
                index === 0
                  ? deliveryPONumber
                  : `${deliveryPONumber}-${(index * poNumberIncrement)
                    .toString()
                    .padStart(2, "0")}`;
            } else {
              shipmentPlanItem.strDeliveryPONumber = "";
            }
          }
          const shipmentPlanCartItemNumber = `${ele.strCartReferenceNumber}-${this.shipmentSectionCount}-${index + 1}`
          shipmentPlanItem.strCartItemReferenceNumber = shipmentPlanCartItemNumber;

          shipmentInfoObj.lstShipmentPlan.push(shipmentPlanItem);
        });

        productInfoObj.lstCartItems.push(shipmentInfoObj);
      });
      this.saveToCartItems.push(productInfoObj);
      productInfoObj.boolThirdParty = this.isThirdPartyScreen;
      this.pageItems.push(productInfoObj);
    });
    this.isSpinner = true;
    updateDeliverCheckOutShipmentInfo({
      strCartId: this.cartId,
      lstCartWrapper: this.saveToCartItems,
      //1116
      strCommunityId: communityId
    })
      .then((response) => {
        if (response?.strStatusCode === "002") {
          this.dispatchEvent(
            new CustomEvent("buttonclick", {
              detail: {
                value: "isOrderReview",
                step: 2,
                shipmentInfo: this.pageItems,
                shipToInfo: this.shipToArray,
                picklistObj: this.picklistObj
              }
            })
          );
        }
        this.isSpinner = false;
      })
      .catch((e) => {
        toastMessageHandler();
        this.isSpinner = false;
      });
  };

  /**
   * Check if all the fields are filled
   * @function checkEmptyStatus
   */
  checkEmptyStatus = () => {
    let allValid = true;
    this.productInfoArray?.forEach((el) => {
      el.lstCartItems.forEach((item) => {
        let obj = {
          strShipTo: item.strShipTo,
          strIncoterms: item.strIncoterms,
          strDeliveryMode: item.strDeliveryMode,
          strShipFrom: item.strShipFrom,
          datRequestedShipmentDate: item.datRequestedShipmentDate,
        };
        if (
          Object.values(obj).includes("") ||
          Object.values(obj).includes(null) ||
          Object.values(obj).includes(undefined) ||
          item.intQuantity === "" ||
          +item.intQuantity === 0 ||
          (
            el.boolThirdParty === true && (!item.decSellOutPrice || +item.decSellOutPrice === 0)
          ) ||
          item.isErrorQuantity === true ||
          item.isShipmentPlanErrorQty === true ||
          !this.validateDateFields(item.datRequestedShipmentDate) ||
          (item.intPONumberIncrement ? !this.validatePONumberIncrement(item.intPONumberIncrement) : false)
        ) {
          allValid = false;
        }
        if (isBrazilRegion() && (!item.strPackType || (el.boolThirdParty && item.strPackType === PACK_TYPES.PACKED && !item.strPackageType) || (el.boolThirdParty && item.strPackType === PACK_TYPES.BULK && item.strPackageType))) {
          allValid = false;
        }
        if (isBrazilRegion() && (item.intFiscalNumber && !item.datNotaFiscalDate)) {
          allValid = false;
        }
        if (!isBrazilRegion() && (el.boolThirdParty === true)) {
          allValid = true;
        }

        if (isBrazilRegion() && this.template.querySelectorAll(`[data-id="strDeliveryInstructions"]`).forEach(inputComponent => {
          if (!inputComponent.reportValidity()) {
            allValid = false;
          }
        }));
        item.lstShipmentPlan?.forEach((plan) => {
          let dateObj = {
            datPlanRequestedShipmentDate: plan.datRequestedShipmentDate
          };
          if (
            Object.values(dateObj).includes("") ||
            Object.values(dateObj).includes(null) ||
            Object.values(dateObj).includes(undefined) ||
            plan.intQuantity === "" ||
            +plan.intQuantity === 0 ||
            !this.validateDateFields(plan.datRequestedShipmentDate)
          ) {
            allValid = false;
          }
        });
      });
    });
    this.isProceedDisabled = !allValid;
  };

  /**
   * Validate if Requested Shipment Date Has Valid Values
   * @function validateDateFields
   * @param {Date} date
   */
  validateDateFields(date) {
   
    
    //GSMD-1882
    let inpDate = getRawDateUtil(date)?.setUTCHours(0, 0, 0, 0);
    let currDate = new Date().setUTCHours(0, 0, 0, 0);
    
    
    console.log('Input>>>', inpDate)
    let valid = false;
    if (inpDate >= currDate) {
      valid = true;
    }






    

    /*
    if (inpDate >= minDate && (inpDate >= currDate || minDate > currDate) && inpDate <= maxDate) {
      valid = true;
    }*/
    return valid;

  }

  /**
   * Validate PO Number Increment
   * @function validatePONumberIncrement
   * @param {number} poNumberIncrement
   */
  validatePONumberIncrement(poNumberIncrement) {
    let poNum = +poNumberIncrement;
    return (poNum && poNum > 0 && poNum < 11);
  }

  /**
   * Validate if Requested Shipment Date Has Valid Values
   * @function validateQtyShipmntDate
   * @param {Event} event
   */
  validateQtyShipmntDate = (event) => {
    let allValid = true;
    const productIndex = event.target.dataset.productIndex;
    const shipmentIndex = event.target.dataset.shipmentIndex;
    this.template
      .querySelectorAll(
        `.requiredInput[data-product-index="${productIndex}"][data-shipment-index="${shipmentIndex}"]`
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
  };

  /**
   * Report Validity for line item of the deleted row
   * @function validateInputFields
   * @param {number} productIndex
   * @param {number} shipmentIndex
   * @param {number} shipmentPlanIndex
   */
  validateInputFields(productIndex, shipmentIndex, shipmentPlanIndex = null) {
    let productSelector = +productIndex + 2;
    let shipmentSelector = +shipmentIndex + 1;
    if (shipmentPlanIndex) {
      let shipmentPanSelector = +shipmentPlanIndex + 2;
      this.template.querySelectorAll(`.card-body>div:nth-child(${productSelector}) .shipment-col>div:nth-child(${shipmentSelector}) .shipment-plan-container .shipment-plan-details-sections>div:nth-child(${shipmentPanSelector}) [data-id]`).forEach((inputComponent) => {
        inputComponent.reportValidity();
      });
    }
    else {
      this.template.querySelectorAll(`.card-body>div:nth-child(${productSelector}) .shipment-col>div:nth-child(${shipmentSelector}) [data-id]`).forEach((inputComponent) => {
        inputComponent.reportValidity();
      });
    }
  }


  // _isShowSearchAddressModal = false;
  // @api
  // get showSearchAddressModal() {
  //   return this._isShowSearchAddressModal;
  // }
  // set showSearchAddressModal(value) {
  //   this._isShowSearchAddressModal = value;
  // }

  /**
   * Function to close switch account modal
   * @function openSearchAddressModal
   */
  openSearchAddressModal(event) {
    // this.productInfoArray[event.detail.indexProduct].lstCartItems[event.target.dataset.indexShipment].showSearchAddressModal = true;
    this.productInfoArray[event.target.dataset.productIndex].lstCartItems[event.target.dataset.shipmentIndex].showSearchAddressModal = true;
  }

  confirmShipToSelection(event) {
    let index1 = event.detail.indexProduct;
    let index2 = event.detail.indexShipment;
    this.productInfoArray[index1].lstCartItems[index2]["strShipTo"] = event.detail.selectedShipTo;
    if (!this.productInfoArray[index1].boolThirdParty) {
      this.productInfoArray[index1].lstCartItems[index2].strIncoterms = null;
      this.productInfoArray[index1].lstCartItems[index2].strShipFrom = null;
    }
    this.productInfoArray[index1].lstCartItems[index2].isShipFromDisabled = true;
    if (event.detail.selectedShipTo) {
      this.productInfoArray[index1].lstCartItems[index2].isIncotermsDisabled = false;
      let productSku = this.productInfoArray[index1].strSku;
      this.productInfoArray[index1].lstCartItems[index2].lstIncoterms =
        this.getFieldListOptions(
          productSku,
          "strIncoterms",
          "strShipTo",
          event.detail.selectedShipTo,
        );
    } else {
      this.productInfoArray[index1].lstCartItems[index2].isIncotermsDisabled = true;
    }
    this.validateQuantityField(index1, index2);
    this.checkEmptyStatus();
  }
  /**
   * Function to close switch account modal
   * @function closeSwitchAccountModal
   */
  closeSearchAddressModal(event) {
    // this._isShowSearchAddressModal = false;
    this.productInfoArray[event.detail.indexProduct].lstCartItems[event.detail.indexShipment].showSearchAddressModal = false;
    // this.productInfoArray[event.detail.indexProduct].lstCartItems[event.detail.indexShipment].strShipTo = event.detail.selectedShipTo?event.detail.selectedShipTo:this.productInfoArray[event.detail.indexProduct].lstCartItems[event.detail.indexShipment].strShipTo;
    let strShipTo = this.productInfoArray[event.detail.indexProduct].lstCartItems[event.detail.indexShipment].strShipTo;
    let newStrShipTo = event.detail.selectedShipTo;
    if (strShipTo !== newStrShipTo) {
      this.productInfoArray[event.detail.indexProduct].lstCartItems[event.detail.indexShipment].strShipTo = newStrShipTo;
    }
    this.template.querySelector(`c-pmc_dh_custom-picklist[data-product-index='${event.detail.indexProduct}'][data-shipment-index='${event.detail.indexShipment}']`)?.updateSelectedOption();
    if (event.detail.selectionChanged == true) {
      this.confirmShipToSelection(event);
    }
  }

}