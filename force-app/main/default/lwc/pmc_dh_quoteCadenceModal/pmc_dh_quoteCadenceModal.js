import { LightningElement, api, track } from 'lwc';
import pmc_addressDetails_cancel from "@salesforce/label/c.pmc_addressDetails_cancel";
import pmc_quoteCheckoutFlow_deliveryMode from "@salesforce/label/c.pmc_quoteCheckoutFlow_deliveryMode";
import pmc_quoteCheckoutFlow_shipTo from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipTo";
import pmc_quoteCheckoutFlow_shipFrom from "@salesforce/label/c.pmc_quoteCheckoutFlow_shipFrom";
import pmc_homepage_product from "@salesforce/label/c.pmc_homepage_product";
import pmc_contractDetails_validityPeriod from "@salesforce/label/c.pmc_contractDetails_validityPeriod";
import pmc_requestToDeliverShippingInformation_frequency from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_frequency";
import pmc_quoteCheckoutFlow_quantity from "@salesforce/label/c.pmc_quoteCheckoutFlow_quantity";
import pmc_cadenceSuggestion_confirmCadenceSuggestion from "@salesforce/label/c.pmc_cadenceSuggestion_confirmCadenceSuggestion";
import pmc_requestToDeliver_qty from "@salesforce/label/c.pmc_requestToDeliver_qty";
import pmc_cadenceSuggestion_infoText from "@salesforce/label/c.pmc_cadenceSuggestion_infoText";

const monthsArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

/**
 * A custom LWC to display cadence suggestion modal on quote page
 * @alias Pmc_dh_quoteCadenceModal
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant Soni
 * @example
 * <c-pmc_dh_contract-cadence-modal></c-pmc_dh_contract-cadence-modal>
 */
export default class Pmc_dh_quoteCadenceModal extends LightningElement {
    @api isModal;

    @track array = [
        {
            strProduct: 'ASPIRE® 0-0-58 WITH BORON',
            strDeliveryMode: 'Truck - FOB',
            strShipTo: 'Address Name 123 Main Street, Tampa, FL',
            strShipFrom: 'Plant Name 123 Main Street, Tampa, FL',
            id: 1,
            strQuoteId: 1,
            boolIsCadenceSuggested: false,
            validityPeriod: "01/01/2023 - 09/01/2023",
            totalAvailableQty: 500
        },
        {
            strProduct: 'ASPIRE® 0-0-58 WITH BORON',
            strDeliveryMode: 'Truck - FOB',
            strShipTo: 'Address Name 123 Main Street, Tampa, FL',
            strShipFrom: 'Plant Name 123 Main Street, Tampa, FL',
            id: 2,
            strQuoteId: 2,
            boolIsCadenceSuggested: false,
            validityPeriod: "01/01/2023 - 04/04/2023",
            totalAvailableQty: 440
        },
        {
            strProduct: 'ASPIRE® 0-0-58 WITH BORON',
            strDeliveryMode: 'Truck - FOB',
            strShipTo: 'Address Name 123 Main Street, Tampa, FL',
            strShipFrom: 'Plant Name 123 Main Street, Tampa, FL',
            id: 3,
            strQuoteId: 3,
            boolIsCadenceSuggested: false,
            validityPeriod: "01/01/2023 - 12/15/2023",
            totalAvailableQty: 700
        },
        {
            strProduct: 'ASPIRE® 0-0-58 WITH BORON',
            strDeliveryMode: 'Truck - FOB',
            strShipTo: 'Address Name 123 Main Street, Tampa, FL',
            strShipFrom: 'Plant Name 123 Main Street, Tampa, FL',
            id: 4,
            strQuoteId: 4,
            boolIsCadenceSuggested: true,
            quantityData: []
        }
    ];

    @track labels = {
        pmc_addressDetails_cancel,
        pmc_quoteCheckoutFlow_deliveryMode,
        pmc_quoteCheckoutFlow_shipTo,
        pmc_quoteCheckoutFlow_shipFrom,
        pmc_homepage_product,
        pmc_contractDetails_validityPeriod,
        pmc_requestToDeliverShippingInformation_frequency,
        pmc_quoteCheckoutFlow_quantity,
        pmc_cadenceSuggestion_confirmCadenceSuggestion,
        pmc_cadenceSuggestion_infoText,
        pmc_requestToDeliver_qty
    };

    @track lstQtyPeriod = [];
    @track selectedQuoteLineObj = {};

    showQuantityFields = false;
    isConfirmBtnDisabled = true;
    warningMsg = '';

    connectedCallback() {
        this.array.forEach(item => {
            item.isRadioBtnChecked = false;
            item.lstQtyPeriod = [];
            if (item.boolIsCadenceSuggested) {
                item.lstQtyPeriod = item.quantityData
            }
            else {
                let { yearMonthObj, numberOfMonths } = this.calculateValidityPeriod(item.validityPeriod);
                let contractedMonth = "";
                Object.entries(yearMonthObj).forEach(([key, val]) => {
                    val.forEach((month) => {
                        contractedMonth = month <= 9 ? `0${month}/${key}` : `${month}/${key}`;
                        item.lstQtyPeriod.push({
                            id: contractedMonth,
                            qty: Math.floor(item.totalAvailableQty / (numberOfMonths + 1)),
                            monthContracted: contractedMonth
                        });
                    });
                });
                if (item.lstQtyPeriod) {
                    item.lstQtyPeriod[item.lstQtyPeriod.length - 1].qty +=
                        item.totalAvailableQty -
                        Math.floor(item.totalAvailableQty / (numberOfMonths + 1)) *
                        (numberOfMonths + 1);
                }
            }
        })
    }

    calculateValidityPeriod(validityPeriod) {
        const validityDates = validityPeriod.split(" - ");
        let startDate = new Date(validityDates[0]);
        let endDate = new Date(validityDates[1]);
        let timeDifference = endDate - startDate;
        const millisecondsPerDay = 24 * 60 * 60 * 1000;
        const averageDaysPerMonth = 30.44;
        const numberOfDays = Math.round(timeDifference / millisecondsPerDay);
        const numberOfMonths = Math.round(numberOfDays / averageDaysPerMonth);
        const startYear = startDate.getFullYear();
        const startMonth = startDate.getMonth();
        const endYear = endDate.getFullYear();
        const endMonth = endDate.getMonth();
        const numberOfYears = endYear - startYear + 1;
        let yearArray = [];
        for (let year = 0; year < numberOfYears; year++) {
            yearArray.push(startYear + year);
        }
        let yearMonthObj = {};
        if (startYear === endYear) {
            yearMonthObj[startYear] = monthsArray.slice(startMonth, endMonth + 1);
        } else {
            yearArray.forEach((year) => {
                if (year === startYear) {
                    yearMonthObj[year] = monthsArray.slice(startMonth);
                } else if (year === endYear) {
                    yearMonthObj[year] = monthsArray.slice(0, endMonth + 1);
                } else {
                    yearMonthObj[year] = monthsArray;
                }
            });
        }
        return { yearMonthObj, numberOfMonths };
    }

    handleDataChange(event) {
        if (event.detail.value === '') {
            this.selectedQuoteLineObj.lstQtyPeriod[event.currentTarget.dataset.index].qty = ''
        } else {
            this.selectedQuoteLineObj.lstQtyPeriod[event.currentTarget.dataset.index].qty = Number(event.detail.value)
        }
    }

    calculateTotalQty() {
        let totalEnteredQty = 0;
        if (this.selectedQuoteLineObj?.lstQtyPeriod) {
            this.selectedQuoteLineObj?.lstQtyPeriod.forEach((item) => {
                totalEnteredQty += Number(item.qty)
            })
        }
        return totalEnteredQty;
    }

    handleClick(event) {
        if (this.checkQuantityFieldsError()) {
            event.preventDefault();
            // this.array.forEach((item) => {
            //     if (item.strQuoteId === this.selectedQuoteLineObj.strQuoteId) {
            //         item.isRadioBtnChecked = true;
            //     }
            //     else {
            //         item.isRadioBtnChecked = false
            //     }
            // });
            // return;
        }
    }

    handleRadioOptionChange(event) {
        this.array.forEach((item) => {
            if (item.strQuoteId === +event.target.dataset.quoteId) {
                item.isRadioBtnChecked = true;
                this.selectedQuoteLineObj = JSON.parse(JSON.stringify(item));
            }
            else {
                item.isRadioBtnChecked = false
            }
        });
        this.showQuantityFields = true;
        this.warningMsg = "";
        this.isConfirmBtnDisabled = false;
    }

    checkQuantityFieldsError() {
        let isAnyQuantityEmpty = false;
        let totalEnteredQty = this.calculateTotalQty();
        let isQuantityMismatch = this.selectedQuoteLineObj.totalAvailableQty ? this.selectedQuoteLineObj.totalAvailableQty !== totalEnteredQty : false;
        if (this.selectedQuoteLineObj?.lstQtyPeriod) {
            this.selectedQuoteLineObj?.lstQtyPeriod.forEach((item) => {
                if (item.qty === "") {
                    isAnyQuantityEmpty = true
                }
            })
        }
        if (isAnyQuantityEmpty) {
            this.warningMsg = "The quantity field(s) cannot be blank."
        }
        else if (isQuantityMismatch) {
            this.warningMsg = `Selected Ordered Quantity ${totalEnteredQty} doesn't match ${this.selectedQuoteLineObj.totalAvailableQty}, Please enter a valid quantity.`;
        } else {
            this.warningMsg = ""
        }
        return (isAnyQuantityEmpty || isQuantityMismatch)
    }

    confirmBtnHandler() {
        // console.log('debug');
        if (this.checkQuantityFieldsError()) return;
    }

    closeModalHandler() {
        this.dispatchEvent(new CustomEvent("closemodal"));
    }
}