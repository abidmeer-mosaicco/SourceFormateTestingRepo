import { LightningElement, track, api } from 'lwc';

import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

import iconTruckTemplate from "./template/iconTruckTemplate.html";
import iconCashTemplate from "./template/iconCashTemplate.html";
import iconFileCheckTemplate from "./template/iconFileCheckTemplate.html";
import iconCheckTemplate from "./template/iconCheckTemplate.html";
import iconTruckActiveTemplate from "./template/iconTruckActiveTemplate.html";
import iconCashActiveTemplate from "./template/iconCashActiveTemplate.html";
import iconFileCheckActiveTemplate from "./template/iconFileCheckActiveTemplate.html";
import iconCheckActiveTemplate from "./template/iconCheckActiveTemplate.html";
import iconRingTemplate from "./template/iconRingTemplate.html";
import iconDiscTemplate from "./template/iconDiscTemplate.html";
import iconCheckSolidTemplate from "./template/iconCheckSolidTemplate.html";

/**
 * A custom LWC for containing icon templates used in quote checkout flow.
 * @alias Pmc_dh_quoteCheckoutFlowIcons
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant
 * @example
 * <c-pmc_dh_quote-checkout-flow-icons></c-pmc_dh_quote-checkout-flow-icons>
 */

export default class Pmc_dh_quoteCheckoutFlowIcons extends LightningElement {
    @api icon = '';
    @api statusIcon = false;
    @api status = '';
    
    @track iconUrlObj = {
        iconCash: `${PMC_BrandingAssetsStaticResource}/icons/icon-cash.svg`,
        iconTruck: `${PMC_BrandingAssetsStaticResource}/icons/icon-truck.svg`,
        iconCheck: `${PMC_BrandingAssetsStaticResource}/icons/icon-circle-check.svg`,
        iconFileCheck: `${PMC_BrandingAssetsStaticResource}/icons/icon-file-check.svg`,
        iconCashActive: `${PMC_BrandingAssetsStaticResource}/icons/icon-cash-active.svg`,
        iconTruckActive: `${PMC_BrandingAssetsStaticResource}/icons/icon-truck-active.svg`,
        iconCheckActive: `${PMC_BrandingAssetsStaticResource}/icons/icon-circle-check-active.svg`,
        iconFileCheckActive: `${PMC_BrandingAssetsStaticResource}/icons/icon-file-check-active.svg`,
        iconCheckSolid: `${PMC_BrandingAssetsStaticResource}/icons/icon-circle-check-solid.svg`,
        iconRing: `${PMC_BrandingAssetsStaticResource}/icons/icon-ring.svg`,
        iconDisc: `${PMC_BrandingAssetsStaticResource}/icons/icon-disc.svg`,
    };
    
    /**
     * Returning icon template according to api values passed from parent
     */
    render() {
        if (this.statusIcon)
            switch (this.status) {
                case "complete": return iconCheckSolidTemplate;
                case "active": return iconRingTemplate;
                case "pending": return iconDiscTemplate;
                default: return iconTruckTemplate;
            }

        else {
            switch (this.icon) {
                case "icontruck": return this.status === 'active' ? iconTruckActiveTemplate : iconTruckTemplate;                
                case "iconcash": return this.status === 'active' ? iconCashActiveTemplate : iconCashTemplate;
                case "iconfilecheck": return this.status === 'active' ? iconFileCheckActiveTemplate : iconFileCheckTemplate;
                case "iconcheck": return this.status === 'active' ? iconCheckActiveTemplate : iconCheckTemplate;
                default: return iconTruckTemplate;
            }
        }
    }
}