import { LightningElement, track, api } from 'lwc';
import pmc_orderDetails_calledPriceSummary from '@salesforce/label/c.pmc_orderDetails_calledPriceSummary';
import pmc_quoteCheckoutFlow_products from '@salesforce/label/c.pmc_quoteCheckoutFlow_products';
import pmc_orderDetails_unpricedQty from '@salesforce/label/c.pmc_orderDetails_unpricedQty';
import pmc_orderDetails_pricedQty from '@salesforce/label/c.pmc_orderDetails_pricedQty';
import pmc_orderDetails_orderLine from '@salesforce/label/c.pmc_orderDetails_orderLine';
import pmc_contractDetails_volume from '@salesforce/label/c.pmc_contractDetails_volume';
import pmc_contractDetails_pricePerUnit from '@salesforce/label/c.pmc_contractDetails_pricePerUnit';
import pmc_quoteHistory_totalPrice from '@salesforce/label/c.pmc_quoteHistory_totalPrice';
import pmc_contractDetails_total from '@salesforce/label/c.pmc_contractDetails_total';
import pmc_orderDetails_calledPriceSummaryMsg from '@salesforce/label/c.pmc_orderDetails_calledPriceSummaryMsg';
import { getCurrencyAndPrice } from "c/pmc_dh_utilityJs";
import pmc_priceSummary_quoteDetailsError from "@salesforce/label/c.pmc_priceSummary_quoteDetailsError";

export default class Pmc_dh_orderCalledPriceSummary extends LightningElement {
  @track labels = {
    pmc_orderDetails_calledPriceSummary,
    pmc_quoteCheckoutFlow_products,
    pmc_orderDetails_unpricedQty,
    pmc_orderDetails_pricedQty,
    pmc_orderDetails_orderLine,
    pmc_contractDetails_volume,
    pmc_contractDetails_pricePerUnit,
    pmc_quoteHistory_totalPrice,
    pmc_contractDetails_total,
    pmc_orderDetails_calledPriceSummaryMsg
  }

  @api lstCalledPriceSummaryData = null;
  @track pageObj = {};
  allPriceValuesNull = true;
  errorMsg;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if (this.lstCalledPriceSummaryData) {
      this.pageObj = JSON.parse(JSON.stringify(this.lstCalledPriceSummaryData));
      if (this.pageObj?.productWrapper) {
        this.getTotalVolume(this.pageObj.productWrapper);
        this.getTotalPrice(this.pageObj.productWrapper);
      }
    }
    if (this.allPriceValuesNull) {
      this.errorMsg = pmc_priceSummary_quoteDetailsError;
    }
  }

  /**
   * Method to calculate the total price and total price per ton
   * @function getTotalPrice
   * @param {Array} productData 
   */
  getTotalPrice(productData) {
    productData.forEach(product => {
      let totalPricePerTon = 0;
      let totalPrice = 0;
      product.lstOrderLineData.forEach(orderItem => {
        if (orderItem.strPricePerTon !== "TBD") {
          totalPricePerTon += Number(orderItem.strPricePerTon);
          orderItem.strPricePerTon = getCurrencyAndPrice(this.pageObj.strCurrencyISOCode, orderItem.strPricePerTon);
        } if (orderItem.strTotalPrice !== "TBD") {
          totalPrice += Number(orderItem.strTotalPrice);
          orderItem.strTotalPrice = getCurrencyAndPrice(this.pageObj.strCurrencyISOCode, orderItem.strTotalPrice);
        }
      });
      if (totalPricePerTon !== 0 || totalPrice !== 0) this.allPriceValuesNull = false;
      product.totalPricePerTon = (totalPricePerTon === 0) ? "TBD" : getCurrencyAndPrice(this.pageObj.strCurrencyISOCode, totalPricePerTon.toString());
      product.totalPrice = (totalPrice === 0) ? "TBD" : getCurrencyAndPrice(this.pageObj.strCurrencyISOCode, totalPrice.toString());
    })
  }

  /**
   * Method to calculate the total volume
   * @function getTotalVolume
   * @param {Array} productData 
   */
  getTotalVolume(productData) {
    productData.forEach(item => {
      const groupedByUOM = item.lstOrderLineData.reduce((group, product) => {
        const { strUOM } = product;
        group[strUOM] = group[strUOM] ?? [];
        group[strUOM].push(product);
        return group;
      }, {});
      let totalVolume = '';
      Object.keys(groupedByUOM).forEach((key, index) => {
        let totalVolumeForUOM = 0;
        let strUOM = '';
        if (groupedByUOM[key][0].strUOM) {
          strUOM = groupedByUOM[key][0].strUOM;
        }
        groupedByUOM[key].forEach(product => {
          totalVolumeForUOM = totalVolumeForUOM + +Number(product.strVolume)
        });
        if (!index) {
          totalVolume = `${totalVolumeForUOM} ${strUOM}`
        }
        else {
          totalVolume = `${totalVolume} + ${totalVolumeForUOM} ${strUOM}`
        }
      });
      item.totalVolume = totalVolume;
    })
  }
}