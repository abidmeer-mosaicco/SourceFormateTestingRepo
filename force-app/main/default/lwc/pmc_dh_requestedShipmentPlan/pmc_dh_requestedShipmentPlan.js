import { LightningElement, track } from 'lwc';
import PMC_BrandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { formatDate } from "c/pmc_dh_utilityJs";

import pmc_modal_close from "@salesforce/label/c.pmc_modal_close";

// import basePath from '@salesforce/community/basePath';
import { deleteItemFromCart } from 'commerce/cartApi';
import communityId from '@salesforce/community/Id';
import { isBrazilRegion } from 'c/pmc_dh_utilityJs';
import getDeliverCheckOutShipmentInfo from "@salesforce/apex/PMC_DH_RequestToDeliverController.getDeliverCheckOutShipmentInfo";
import addCartItems from "@salesforce/apex/PMC_DH_ContractUtil.addCartItems";
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
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
import pmc_requestToDeliverShippingInformation_infoMessage from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_infoMessage";
import pmc_requestToDeliverShippingInformation_deliveryAddress from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_deliveryAddress";
import pmc_requestToDeliverShippingInformation_qty from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_qty";
import pmc_requestToDeliverShippingInformation_requestedShipmentDate from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_requestedShipmentDate";
import pmc_requestToDeliverShippingInformation_deliveryMode from "@salesforce/label/c.pmc_requestToDeliverShippingInformation_deliveryMode";
import { toastMessageHandler } from "c/pmc_dh_utilityJs";
const MESSAGE_TYPE_INFO = "info";

export default class Pmc_dh_requestedShipmentPlan extends LightningElement {

    closeIconUrl = `${PMC_BrandingStaticResource}/icons/icon-close.svg`;
    /* @track labels = {
        pmc_modal_close,       
    } */

    /* @track mockData = [
        {
            "lstCartWrapper": [
                {
                    "lstCartItems": [
                        {
                            "intQuantity": 25,
                            "strCartItemId": "0a9DT000000CgIRYA0",
                            "strDeliveryMode": "Container",
                            "strIncoterms": "FCA",
                            "strShipFrom": "a4KDT000000aS0g2AE",
                            "strShipTo": "001DT000014shMEYAY",
                            "strSource": "RTD",
                            "strDeliveryPONumber": "ABC21",
                            "strFrequency": "Monthly",
                            "intPONumberIncrement": 5,
                            "boolShipmentPlan": true,
                            "lstShipmentPlan": [
                                {
                                    "strCartItemId": "21312312",
                                    "intQuantity": 10,
                                    "datRequestedShipmentDate": "2023-07-13",
                                    "strDeliveryPONumber": "ABC21-05",
                                }, {
                                    "strCartItemId": "21312312",
                                    "intQuantity": 10,
                                    "datRequestedShipmentDate": "2023-07-13",
                                    "strDeliveryPONumber": "ABC21-10",
                                }, {
                                    "strCartItemId": "21312312",
                                    "intQuantity": 10,
                                    "datRequestedShipmentDate": "2023-07-13",
                                    "strDeliveryPONumber": "ABC21-15",
                                }
                            ]
                        }
                    ],
                    "lstDeliveryModes": [
                        {
                            "label": "Truck",
                            "value": "Truck"
                        },
                        {
                            "label": "Container",
                            "value": "Container"
                        },
                        {
                            "label": "Barge",
                            "value": "Barge"
                        }
                    ],
                    "lstIncoterms": [
                        {
                            "label": "CIF",
                            "value": "CIF"
                        },
                        {
                            "label": "CFR",
                            "value": "CFR"
                        },
                        {
                            "label": "FCA",
                            "value": "FCA"
                        }
                    ],
                    "lstShipFrom": [
                        {
                            "label": "Mosaic Fertilizer (Beijing) Co",
                            "value": "a4KDT000000aSN02AM"
                        },
                        {
                            "label": "MWSPC,  Saudi Arabia",
                            "value": "a4KDT000000aS0e2AE"
                        },
                        {
                            "label": "FL, Tampa",
                            "value": "a4KDT000000aS0g2AE"
                        }
                    ],
                    "lstShipTo": [
                        {
                            "label": "North America 6",
                            "value": "001DT000014shMFYAY"
                        },
                        {
                            "label": "North America 1",
                            "value": "001DT000014shM5YAI"
                        },
                        {
                            "label": "North America 5",
                            "value": "001DT000014shMEYAY"
                        }
                    ],
                    "lstFrequency": [{
                        "label": "Monthly",
                        "value": "Monthly"
                    }, {
                        "label": "Weekly",
                        "value": "Weekly"
                    }],
                    "strContractPONumber": "newnewnew",
                    "strImgSrc": "/digitalhub/sfsites/c/cms/delivery/media/MCZYGKDIARIBESJFF32BZIJBURIA?recordId=01tDT000009jQoy&buyerId=001DT000013aaAS",
                    "strProductId": "01tDT000009jQoyYAE",
                    "strProductName": "DIAMMONIUM PHOSPHATE  18-46-00",
                    "strSku": "100011",
                    "datContractStartDate": "2023-01-01T00:00:00Z",
                    "datContractEndDate": "2023-01-14T12:00:00Z",
                    "strContractPONumber": "",
                    "intTotalQuantity": "",
                    "strItemNumber": "",
                }
            ]
        }

    ] */

    @track mockData = [
        {
            "lstCartWrapper": [
                {
                    "datContractEndDate": "2023-08-13",
                    "datContractStartDate": "2023-07-14",
                    "lstCartItems": [
                        {
                            "datRequestedShipmentDate": "2023-07-17",
                            "intQuantity": 75,
                            "strCartItemId": "0a9DT000000CgfLYAS",
                            "strDeliveryMode": "Truck",
                            "strIncoterms": "CIF",
                            "strShipFrom": "a4KDT000000aSN02AM",
                            "strShipTo": "001DT000014shMFYAY",
                            "strSource": "RTD"
                        }
                    ],
                    "lstContractItems": [
                        {
                            "intAvailableQuantity": 75,
                            "intOrderQuantity": 25,
                            "intQuantity": 100,
                            "strContractItemId": "a3ODT000004YHOG2A4",
                            "strDeliveryMode": "Truck",
                            "strIncoterms": "CIF",
                            "strShipFrom": "131DT000000DNdjYAG",
                            "strShipTo": "001DT000014shMFYAY"
                        }
                    ],
                    "lstDeliveryModes": [
                        {
                            "label": "Truck",
                            "value": "Truck"
                        },
                        {
                            "label": "Container",
                            "value": "Container"
                        },
                        {
                            "label": "Barge",
                            "value": "Barge"
                        }
                    ],
                    "lstFrequency": [
                        {
                            "label": "Monthly",
                            "value": "Monthly"
                        },
                        {
                            "label": "Weekly",
                            "value": "Weekly"
                        }
                    ],
                    "lstIncoterms": [
                        {
                            "label": "CIF",
                            "value": "CIF"
                        },
                        {
                            "label": "CFR",
                            "value": "CFR"
                        },
                        {
                            "label": "FCA",
                            "value": "FCA"
                        }
                    ],
                    "lstShipFrom": [
                        {
                            "label": "Mosaic Fertilizer (Beijing) Co",
                            "value": "a4KDT000000aSN02AM"
                        },
                        {
                            "label": "MWSPC,  Saudi Arabia",
                            "value": "a4KDT000000aS0e2AE"
                        },
                        {
                            "label": "FL, Tampa",
                            "value": "a4KDT000000aS0g2AE"
                        }
                    ],
                    "lstShipTo": [
                        {
                            "label": "North America 6",
                            "value": "001DT000014shMFYAY"
                        },
                        {
                            "label": "North America 1",
                            "value": "001DT000014shM5YAI"
                        },
                        {
                            "label": "North America 5",
                            "value": "001DT000014shMEYAY"
                        }
                    ],
                    "objContractSummaryWrapper": {
                        "datContractEndDate": "2023-08-13",
                        "datContractStartDate": "2023-07-14",
                        "strContractNumber": "00000289",
                        "strContractType": "Priced Contract Truck",
                        "strPaymentTermSelected": "Net 90",
                        "strPoNumber": "newnewnew"
                    },
                    "strContractPONumber": "newnewnew",
                    "strImgSrc": "/digitalhub/sfsites/c/cms/delivery/media/MCWLKTH2ZHHRFWBHG4ADCO27FM64?recordId=01tDT000009jQq5&buyerId=001DT000013aaAS",
                    "strProductId": "01tDT000009jQq5YAE",
                    "strProductName": "??KMAG",
                    "strSku": "102162"
                },
                {
                    "datContractEndDate": "2023-08-13",
                    "datContractStartDate": "2023-07-14",
                    "lstCartItems": [
                        {
                            "datRequestedShipmentDate": "2023-07-17",
                            "intQuantity": 75,
                            "strCartItemId": "0a9DT000000CgfLYAS",
                            "strDeliveryMode": "Truck",
                            "strIncoterms": "CIF",
                            "strShipFrom": "a4KDT000000aSN02AM",
                            "strShipTo": "001DT000014shMFYAY",
                            "strSource": "RTD"
                        }
                    ],
                    "lstContractItems": [
                        {
                            "intAvailableQuantity": 75,
                            "intOrderQuantity": 25,
                            "intQuantity": 100,
                            "strContractItemId": "a3ODT000004YHOG2A4",
                            "strDeliveryMode": "Truck",
                            "strIncoterms": "CIF",
                            "strShipFrom": "131DT000000DNdjYAG",
                            "strShipTo": "001DT000014shMFYAY"
                        }
                    ],
                    "lstDeliveryModes": [
                        {
                            "label": "Truck",
                            "value": "Truck"
                        },
                        {
                            "label": "Container",
                            "value": "Container"
                        },
                        {
                            "label": "Barge",
                            "value": "Barge"
                        }
                    ],
                    "lstFrequency": [
                        {
                            "label": "Monthly",
                            "value": "Monthly"
                        },
                        {
                            "label": "Weekly",
                            "value": "Weekly"
                        }
                    ],
                    "lstIncoterms": [
                        {
                            "label": "CIF",
                            "value": "CIF"
                        },
                        {
                            "label": "CFR",
                            "value": "CFR"
                        },
                        {
                            "label": "FCA",
                            "value": "FCA"
                        }
                    ],
                    "lstShipFrom": [
                        {
                            "label": "Mosaic Fertilizer (Beijing) Co",
                            "value": "a4KDT000000aSN02AM"
                        },
                        {
                            "label": "MWSPC,  Saudi Arabia",
                            "value": "a4KDT000000aS0e2AE"
                        },
                        {
                            "label": "FL, Tampa",
                            "value": "a4KDT000000aS0g2AE"
                        }
                    ],
                    "lstShipTo": [
                        {
                            "label": "North America 6",
                            "value": "001DT000014shMFYAY"
                        },
                        {
                            "label": "North America 1",
                            "value": "001DT000014shM5YAI"
                        },
                        {
                            "label": "North America 5",
                            "value": "001DT000014shMEYAY"
                        }
                    ],
                    "objContractSummaryWrapper": {
                        "datContractEndDate": "2023-09-18",
                        "datContractStartDate": "2023-10-22",
                        "strContractNumber": "00000289",
                        "strContractType": "Priced Contract Truck",
                        "strPaymentTermSelected": "Net 90",
                        "strPoNumber": "newnewnew"
                    },
                    "strContractPONumber": "newnewnew",
                    "strImgSrc": "/digitalhub/sfsites/c/cms/delivery/media/MCWLKTH2ZHHRFWBHG4ADCO27FM64?recordId=01tDT000009jQq5&buyerId=001DT000013aaAS",
                    "strProductId": "01tDT000009jQq5YAE",
                    "strProductName": "??KMAG",
                    "strSku": "102162"
                }
            ]
        }
    ]

    /**
     * Lifecycle Hook
     */
    /* connectedCallback() {
        this.today = new Date().toISOString().slice(0, 10);
        // this.productInfoArray = JSON.stringify(this.data.lstCartWrapper);

        this.productInfoArray = JSON.parse(JSON.stringify(this.data.lstCartWrapper));  
      } */

    // handleDataChange() {
    //     return;
    // }

    @track cssDropdownIcon = 'acc-icon';

    /**
    *  To open a shipment details Accordian row on click
    */
    expandShipment = (event) => {
        const shipmentIndex = event.target.dataset.shipmentIndex;
        const productIndex = event.target.dataset.productIndex;
        // const shipmentDiv = this.template.querySelector(`.shipment-plan-container[data-shipment-index="${shipmentIndex}"]`);
        // const accordionIcon = this.template.querySelector(`.acc-icon[data-shipment-index="${shipmentIndex}"]`);

        const shipmentDiv = this.template.querySelector(`.shipment-plan-container[data-product-index="${productIndex}"][data-shipment-index="${shipmentIndex}"]`);
        const accordionIcon = this.template.querySelector(`.acc-icon[data-product-index="${productIndex}"][data-shipment-index="${shipmentIndex}"]`);

        shipmentDiv.style.display = (shipmentDiv.style.display === 'block') ? 'none' : 'block';
        accordionIcon.classList.toggle('down');
    }

    /**
     * add new shipment line for the respective shipment item on click    
     */
    addShipmentLine = (event) => {
        let index1 = event.currentTarget.dataset.productIndex;
        let index2 = event.currentTarget.dataset.shipmentIndex;

        if (!this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan) {
            this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan = [];
        }

        /* this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan = [
            ...this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan,
            {
                strCartItemId: '',
                intQuantity: '',
                datRequestedShipmentDate: null,
                strDeliveryPONumber: ''
            }
        ] */

        const quantity = this.productInfoArray[index1].lstCartItems[index2].intQuantity;
        let lstShipmentPlan = this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan;
        let numberOfLines = lstShipmentPlan.length;

        const newLine = {
            strCartItemId: '',
            intQuantity: '',
            datRequestedShipmentDate: null,
            strDeliveryPONumber: ''
        };

        if (numberOfLines > 0) {
            const equalQuantity = Math.floor(quantity / (numberOfLines + 1));
            const remainingQuantity = quantity % (numberOfLines + 1);
            lstShipmentPlan.forEach((line) => {
                line.intQuantity = equalQuantity;
            });

            lstShipmentPlan[numberOfLines - 1].intQuantity += remainingQuantity;
        }

        newLine.intQuantity = Math.floor(quantity / (numberOfLines + 1));
        this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan.push(newLine);

        this.isDeleteEnabled(event);
    }


    /**
     *  delete/remove a shipment line row on click
     */
    removeShipmentLine = (event) => {
        let index1 = event.currentTarget.dataset.productIndex;
        let index2 = event.currentTarget.dataset.shipmentIndex;
        let index3 = event.currentTarget.dataset.shipmentPlanIndex;
        // this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan.splice(index3, 1);


        // let equalQuantity = Math.floor(quantity / numberOfLines); 

        // if (numberOfLines > 0) {
        //     this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan.forEach((line, index) => {
        //         line.intQuantity = equalQuantity;
        //     });
        // }

        if (index3 >= 0 && index3 < this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan.length) {
            this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan.splice(index3, 1);
        }

        /* const remainingQuantity = quantity - numberOfLines * equalQuantity;
        if (remainingQuantity > 0 && numberOfLines > 0) {
            const additionalQuantityPerLine = Math.floor(remainingQuantity / numberOfLines);
            const remainingQuantityDistribution = remainingQuantity % numberOfLines;

            this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan.forEach((line) => {
                line.intQuantity += additionalQuantityPerLine;
            });


            for (let i = 0; i < remainingQuantityDistribution; i++) {
                this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan[i].intQuantity++;
            }
        } */

        const quantity = this.productInfoArray[index1].lstCartItems[index2].intQuantity;
        let lstShipmentPlan = this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan;
        let numberOfLines = lstShipmentPlan.length;

        if (numberOfLines > 0) {
            const equalQuantity = Math.floor(quantity / numberOfLines);

            lstShipmentPlan.forEach((line) => {
                line.intQuantity = equalQuantity;
            });

            const remainingQuantity = quantity - numberOfLines * equalQuantity;

            if (remainingQuantity > 0) {
                const additionalQuantityPerLine = Math.floor(remainingQuantity / numberOfLines);
                const remainingQuantityDistribution = remainingQuantity % numberOfLines;

                lstShipmentPlan.forEach((line, index) => {
                    line.intQuantity += additionalQuantityPerLine; // Add the additional quantity to each line

                    if (index < remainingQuantityDistribution) {
                        line.intQuantity++; // Add 1 to the quantity of the first few lines
                    }
                });
            }
        }

        this.isDeleteEnabled(event);
    }

    isDeleteEnabled(event) {
        let index1 = event.currentTarget.dataset.productIndex;
        let index2 = event.currentTarget.dataset.shipmentIndex;
        this.isRemoveEnabled = this.productInfoArray[index1].lstCartItems[index2].lstShipmentPlan.length > 1 ? true : false;
    }

    monthWeekCount = 0;
    @track isRemoveEnabled;

    // Function to calculate the number of months and weeks between two GMT dates
    calculateMonthWeekDifference(startDate, endDate) {
        let timeDifference = endDate - startDate;
        const millisecondsPerDay = 24 * 60 * 60 * 1000;
        const averageDaysPerMonth = 30.44;
        const numberOfDays = Math.round(timeDifference / millisecondsPerDay);
        const numberOfMonths = Math.round(numberOfDays / averageDaysPerMonth);
        const numberOfWeeks = Math.round(numberOfDays / 7);
        let result;
        if (numberOfDays < averageDaysPerMonth) {
            result = `${numberOfWeeks} week${numberOfWeeks !== 1 ? "s" : ""}`;

            console.log('numberOfWeeks', result);
        } else {
            result = `${numberOfMonths} month${numberOfMonths !== 1 ? "s" : ""}`;
            console.log('numberOfMonths', result);
        }
        this.monthWeekCount = (numberOfDays < averageDaysPerMonth) ? numberOfWeeks : numberOfMonths;
        return this.monthWeekCount;
    }


    messageBannerType = MESSAGE_TYPE_INFO;
    @track isLocationBrazil = false;
    @track pageItems = [];
    @track saveToCartItems = [];
    @track productInfoArray;
    @track getDeliverCheckOutShipmentInfoObject = {};
    isProceedDisabled = false;
    isContentLoaded = true;
    isSpinner = false;
    pageRendered = false;
    today;
    effectiveAccountId;
    communityId;
    cartId;
    contractId;


    @track iconUrlObj = {
        deleteIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-delete.svg`,
        arrowRightIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-arrowright.svg`,
        mosaicLogoUrl: `${PMC_BrandingAssetsStaticResource}/images/logo-mosaic.png`,
    };

    @track labels = {
        pmc_modal_close,
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
        pmc_requestToDeliverShippingInformation_infoMessage,
        pmc_requestToDeliverShippingInformation_deliveryAddress,
        pmc_requestToDeliverShippingInformation_qty,
        pmc_requestToDeliverShippingInformation_requestedShipmentDate,
        pmc_requestToDeliverShippingInformation_deliveryMode
    };

    /**
     * Lifecycle Hook
     */
    connectedCallback() {
        this.today = new Date().toISOString().slice(0, 10);
        this.communityId = communityId;
        if (isBrazilRegion()) {
            this.isLocationBrazil = !this.isLocationBrazil;
        }
        if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
            this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
        }
        if (sessionStorage.getItem('CONTRACT_ID')) {
            this.contractId = sessionStorage.getItem("CONTRACT_ID");
        }
        if (sessionStorage.getItem('CART_ID')) {
            this.cartId = sessionStorage.getItem('CART_ID');
        }
        this.getDeliverCheckOutShipmentInfoObject = {
            strCommunityId: this.communityId,
            strContractId: this.contractId,
            strCartId: this.cartId,
            strEffectiveAccountId: this.effectiveAccountId
        }
        this.fetchShipmentInfo();
    }

    /**
     * Lifecycle Hook
     */
    renderedCallback() {
        /* if (this.pageRendered) return;
        if (this.isContentLoaded) {
          let baseUrl = window.location.origin;
          this.productInfoArray.forEach(el => {
            let href = `${baseUrl}${basePath}/product/${el.strProductId}`;
            el.href = href;
            el.lstCartItems.forEach(item => {
              if (!item.strShipTo && !item.strDeliveryMode) {
                item.isDeliveryModeDisabled = true;
              }
              if (!item.strDeliveryMode && !item.strIncoterms) {
                item.isIncotermsDisabled = true;
              }
              if (!item.strIncoterms && !item.strShipFrom) {
                item.isShipFromDisabled = true;
              }
            })
          });
          this.productInfoArray.forEach((el, i) => {
            this.getTotalQuantity(i);
          });
          this.checkEmptyStatus();
          this.pageRendered = true;
        } */

        /* this.productInfoArray.forEach((el, indexProduct) => {
         el.datContractStartDate = formatDate(el.datContractStartDate);
         el.datContractEndDate = formatDate(el.datContractEndDate);
        }) */

        /*  this.productInfoArray.forEach(el => {
          el.datContractStartDate = formatDate(el.datContractStartDate);
          el.datContractEndDate = formatDate(el.datContractEndDate);
         }) */


    }

    /**
     * fetch shipment details from backend method
     */
    fetchShipmentInfo = () => {
        this.isSpinner = true;
        getDeliverCheckOutShipmentInfo({
            deliverWrap: this.getDeliverCheckOutShipmentInfoObject
        })
            .then((data) => {
                if (JSON.parse(JSON.stringify(data)).statusCodeMessage?.strStatusMessage) {
                    toastMessageHandler(JSON.parse(JSON.stringify(data)).statusCodeMessage.strStatusMessage)
                  }
                this.productInfoArray = JSON.parse(JSON.stringify(data.lstCartWrapper));
                this.isContentLoaded = true;
                this.isSpinner = false;
            })
            .catch(() => {
                toastMessageHandler();
                this.productInfoArray = JSON.parse(JSON.stringify(this.mockData[0].lstCartWrapper));
                this.productInfoArray.forEach(el => {
                    el.datContractStartDate = formatDate(el.datContractStartDate);
                    el.datContractEndDate = formatDate(el.datContractEndDate);
                });
                this.isSpinner = false;
            });
    }


    /**
     * passing field values to backend and giving next step details to parent component
     */
    proceedButtonHandler = () => {
        this.productInfoArray.forEach(ele => {
            let productInfoObj = {
                strProductId: ele.strProductId, strProductName: ele.strProductName, strSku: ele.strSku, strTotalQty: ele.strTotalQty, strImgSrc: ele.strImgSrc, strItemNumber: ele.strItemNumber, lstCartItems: []
            };

            ele.lstCartItems.forEach(item => {
                let shipmentInfoObj = { strCartItemId: item.strCartItemId, intQuantity: item.intQuantity, strShipTo: item.strShipTo, datRequestedShipmentDate: item.datRequestedShipmentDate, strIncoterms: item.strIncoterms, strDeliveryMode: item.strDeliveryMode, strShipFrom: item.strShipFrom, strSource: item.strSource };

                productInfoObj.lstCartItems.push(shipmentInfoObj);
            })
            this.saveToCartItems.push(productInfoObj);
            this.pageItems.push(productInfoObj);
            this.dispatchEvent(
                new CustomEvent("buttonclick", {
                    detail: {
                        value: "isOrderReview",
                        step: 2,
                        shipmentInfo: this.pageItems
                    }
                })
            );
        });
       this.isSpinner = true;
        addCartItems({
            strCartId: this.cartId,
            lstCartWrapper: this.saveToCartItems
        }).then((response) => {
            if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
                toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
              }
            this.isSpinner = false;
        }).catch(() => {
            toastMessageHandler();
            this.isSpinner = false;
        })
    }

    /**
     * On key up for Quantity Field
     */
    handleKeyUp = (event) => {
        let index1 = event.target.dataset.productIndex;
        let index2 = event.target.dataset.shipmentIndex;
        event.target.value = event.target.value.replace(/[^0-9]/g, '');
        this.productInfoArray[index1].lstCartItems[index2][event.target.dataset.id] = event.target.value;
        this.getTotalQuantity(index1);
    }

    /**
     * On input change event handler
     */
    handleDataChange = (event) => {
        let index1 = event.target.dataset.productIndex;
        let index2 = event.target.dataset.shipmentIndex;

        if (event.target.dataset.id === 'strItemNumber') {
            if (event.detail.value) {
                this.productInfoArray[index1].strItemNumber = event.detail.value;
            }
        } else {
            this.productInfoArray[index1].lstCartItems[index2][event.target.dataset.id] = event.detail.value;
            if (event.target.dataset.id === 'intQuantity') {
                this.getTotalQuantity(index1);
            }

            if (event.target.dataset.id === 'strShipTo') {
                if (event.detail.value) {
                    this.productInfoArray[index1].lstCartItems[index2].isDeliveryModeDisabled = false;
                    this.productInfoArray[index1].lstCartItems[index2].strDeliveryMode = null;
                    this.productInfoArray[index1].lstCartItems[index2].strIncoterms = null;
                    this.productInfoArray[index1].lstCartItems[index2].strShipFrom = null;
                }
                else {
                    this.productInfoArray[index1].lstCartItems[index2].isDeliveryModeDisabled = true;
                    this.productInfoArray[index1].lstCartItems[index2].isIncotermsDisabled = true;
                    this.productInfoArray[index1].lstCartItems[index2].isShipFromDisabled = true;
                    this.productInfoArray[index1].lstCartItems[index2].strDeliveryMode = null;
                    this.productInfoArray[index1].lstCartItems[index2].strIncoterms = null;
                    this.productInfoArray[index1].lstCartItems[index2].strShipFrom = null;
                }
            }

            if (event.target.dataset.id === 'strDeliveryMode') {
                if (event.detail.value) {
                    this.productInfoArray[index1].lstCartItems[index2].isIncotermsDisabled = false;
                    this.productInfoArray[index1].lstCartItems[index2].strIncoterms = null;
                    this.productInfoArray[index1].lstCartItems[index2].strShipFrom = null;
                }
                else {
                    this.productInfoArray[index1].lstCartItems[index2].isIncotermsDisabled = true;
                    this.productInfoArray[index1].lstCartItems[index2].isShipFromDisabled = true;
                    this.productInfoArray[index1].lstCartItems[index2].strIncoterms = null;
                    this.productInfoArray[index1].lstCartItems[index2].strShipFrom = null;
                }
            }

            if (event.target.dataset.id === 'strIncoterms') {
                if (event.detail.value) {
                    this.productInfoArray[index1].lstCartItems[index2].isShipFromDisabled = false;
                    this.productInfoArray[index1].lstCartItems[index2].strShipFrom = null;
                }
                else {
                    this.productInfoArray[index1].lstCartItems[index2].isShipFromDisabled = true;
                    this.productInfoArray[index1].lstCartItems[index2].strShipFrom = null;
                }
            }
            // On Change frequency add 4 qty 
            if (event.target.dataset.id === 'strFrequency') {
                if (event.detail.value) {
                    const startDate = this.productInfoArray[index1].datContractStartDate;
                    const endDate = this.productInfoArray[index1].datContractEndDate;
                    this.calculateMonthWeekDifference(startDate, endDate);
                    const maxIterations = Math.min(this.monthWeekCount, 4);
                    for (let i = 0; i < maxIterations; i++) {
                        this.addShipmentLine(event);
                    }
                }
            }
            this.checkEmptyStatus();
        }

    }

    /**
     * If product image doesn't load, display default image
     */
    handleImageError = (event) => {
        event.currentTarget.src = this.iconUrlObj.mosaicLogoUrl;
        event.currentTarget.style.height = "unset";
        event.currentTarget.onerror = null;
    }

    /**
     * Return total quantity for the given product
     */
    getTotalQuantity = (productIndex) => {
        const quantities = this.productInfoArray[productIndex].lstCartItems.map((ele) => (ele.intQuantity ? +ele.intQuantity : 0));
        const total = quantities.reduce((acc, curr) => acc + curr);
        this.productInfoArray[productIndex].strTotalQty = total;
    }

    /**
     * add new shipment details for the respective product on click    
     */
    addShipment = (event) => {
        let index = parseInt(event.target.dataset.productIndex, 10);
        this.productInfoArray.forEach((el, i) => {
            if (i === index) {
                el.lstCartItems = [...el.lstCartItems,
                { intQuantity: '', strCartItemId: '', strShipTo: null, strShipFrom: null, strIncoterms: null, strDeliveryMode: null, datRequestedShipmentDate: null, isDeliveryModeDisabled: true, isIncotermsDisabled: true, isShipFromDisabled: true }];
            }
        });

        this.getTotalQuantity(index);
        this.isProceedDisabled = true;
    }

    /**
     *  delete a shipment details row on click
     */
    deleteShipment = (event) => {
        let index1 = event.currentTarget.dataset.productIndex;
        let index2 = event.currentTarget.dataset.shipmentIndex;
        let cartItemId = event.currentTarget.dataset.cartId;
        this.productInfoArray[index1].lstCartItems.splice(index2, 1);
        if (!this.productInfoArray[index1].lstCartItems.length) {
            this.productInfoArray.splice(index1, 1);
        }
        if (cartItemId !== '') {
            this.deleteFromCartHandler(cartItemId);
        }
        this.getTotalQuantity(index1);
        this.checkEmptyStatus();
    }

    /**
     *  To open a shipment details Accordian row on click
     */
    /* expandShipment = () => {
      return;
    } */

    /**
     * Backend Method to delete item from cart
     */
    async deleteFromCartHandler(itemId) {
        try {
            await deleteItemFromCart(itemId);
        } catch (error) {
            this.error = error;
        }
    }

    /**
     * Check if all the fields are filled
     */
    checkEmptyStatus = () => {
        let allValid = true;
        this.productInfoArray.forEach(el => {
            el.lstCartItems.forEach(item => {
                let obj = { strShipTo: item.strShipTo, strIncoterms: item.strIncoterms, strDeliveryMode: item.strDeliveryMode, strShipFrom: item.strShipFrom, datRequestedShipmentDate: item.datRequestedShipmentDate }
                if (Object.values(obj).includes('') || Object.values(obj).includes(null) || item.intQuantity === ('') || +item.intQuantity === 0) {
                    allValid = false;
                }
            })
        });
        this.isProceedDisabled = !allValid;
    }
}