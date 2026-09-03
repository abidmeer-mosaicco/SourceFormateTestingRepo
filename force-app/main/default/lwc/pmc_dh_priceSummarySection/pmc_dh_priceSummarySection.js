import { LightningElement, track, api } from 'lwc';
import { getCurrencyAndPrice } from "c/pmc_dh_utilityJs";

import pmc_contractDetails_priceSummary from "@salesforce/label/c.pmc_contractDetails_priceSummary";
import pmc_contractDetails_volume from "@salesforce/label/c.pmc_contractDetails_volume";
import pmc_quoteCheckoutFlow_tons from "@salesforce/label/c.pmc_quoteCheckoutFlow_tons";
import pmc_contractDetails_products from "@salesforce/label/c.pmc_contractDetails_products";
import pmc_contractDetails_total from "@salesforce/label/c.pmc_contractDetails_total";
import pmc_quoteHistory_totalPrice from "@salesforce/label/c.pmc_quoteHistory_totalPrice";
import pmc_priceSummary_quoteDetailsError from "@salesforce/label/c.pmc_priceSummary_quoteDetailsError";
import pmc_priceSummary_rfqError from "@salesforce/label/c.pmc_priceSummary_rfqError";

const FLOW_RFQ = "RFQ";
const FLOW_QUOTE_DETAILS = "Quote Details";

export default class Pmc_dh_priceSummarySection extends LightningElement {
  @api legalMsg;
  @api priceSummaryData = null;
  @api flow = null;
  @track labels = {
    pmc_contractDetails_priceSummary,
    pmc_contractDetails_volume,
    pmc_quoteCheckoutFlow_tons,
    pmc_contractDetails_products,
    pmc_contractDetails_total,
    pmc_quoteHistory_totalPrice
  };
  @track pageObj = {};
  totalVolume = 0;
  allPriceValuesNull = true;
  errorMsg;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    if (this.priceSummaryData) {
      this.pageObj = JSON.parse(JSON.stringify(this.priceSummaryData));
      this.getTotalVolume(this.pageObj?.lstPriceSummary);
      this.pageObj?.lstPriceSummary.forEach(el => {
        el.decPrice = getCurrencyAndPrice(this.pageObj?.strCurrencyIsoCode, el.decPrice);
        if (el.decPrice !== 'N/A') this.allPriceValuesNull = false;
      });
      this.pageObj.decTotalPrice = getCurrencyAndPrice(this.pageObj?.strCurrencyIsoCode, this.pageObj?.decTotalPrice);
    }
    if (this.allPriceValuesNull) {
      switch (this.flow) {
        case FLOW_QUOTE_DETAILS:
          this.errorMsg = pmc_priceSummary_quoteDetailsError;
          break;
        case FLOW_RFQ:
          this.errorMsg = pmc_priceSummary_rfqError;
          break;
        default:
          break;
      }
    }
  }

  /**
   * Calculates total volume
   * @function getTotalVolume
   * @param {Array} priceSummary 
   */
  getTotalVolume(priceSummary) {
    const groupedByUOM = priceSummary.reduce((group, product) => {
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
        totalVolumeForUOM = totalVolumeForUOM + +product.intQuantity
      });
      if (!index) {
        totalVolume = `${totalVolumeForUOM} ${strUOM}`
      }
      else {
        totalVolume = `${totalVolume} + ${totalVolumeForUOM} ${strUOM}`
      }
    });
    this.totalVolume = totalVolume;
  }
}