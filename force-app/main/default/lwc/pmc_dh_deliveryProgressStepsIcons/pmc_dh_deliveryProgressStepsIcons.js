import { LightningElement, api } from 'lwc';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import iconGreenRingTemplate from "./template/iconGreenRingTemplate.html";
import iconGreenDotTemplate from "./template/iconGreenDotTemplate.html";
import iconGrayDotTemplate from "./template/iconGrayDotTemplate.html";
import iconTruckActiveTemplate from "./template/iconTruckActiveTemplate.html";
import iconTruckTemplate from "./template/iconTruckTemplate.html";

/**
 * A custom LWC to display Delivery Progress Steps Icons.
 * @alias Pmc_dh_deliveryProgressStepsIcons
 * @extends LightningElement
 * @hideconstructor
 * @author Venkata Sai Mouli, Agastya
 * @example
 * <c-pmc_dh_delivery-progress-steps-icons></c-pmc_dh_delivery-progress-steps-icons>
 */

export default class Pmc_dh_deliveryProgressStepsIcons extends LightningElement {
    @api icon = '';
    @api statusIcon = false;
    @api status = '';
    iconUrlObj = {
        iconGreenRing: `${PMC_BrandingAssetsStaticResource}/icons/icon-green-ring.svg`,
        iconGreenDot: `${PMC_BrandingAssetsStaticResource}/icons/icon-green-dot.svg`,
        iconGrayDot: `${PMC_BrandingAssetsStaticResource}/icons/icon-gray-dot.svg`,
        iconTruckActive: `${PMC_BrandingAssetsStaticResource}/icons/icon-truck-active.svg`,
        iconTruck: `${PMC_BrandingAssetsStaticResource}/icons/icon-truck.svg`,
    }

    /**
   * Render an appropriate icon depending upon the status and icon name
   * @function render
   */
    render() {
        if (this.statusIcon){
            switch (this.status) {
                case "Active": return iconGreenRingTemplate;
                case "Completed": return iconGreenDotTemplate;
                case "Pending": return iconGrayDotTemplate;
                default: break;
            }
        } else {
            if(this.icon === "icontruck"){
                return iconTruckActiveTemplate;
            } else if(this.icon === "icontruckpending"){
                return iconTruckTemplate;
            }
        }
        return 1;
    }
}