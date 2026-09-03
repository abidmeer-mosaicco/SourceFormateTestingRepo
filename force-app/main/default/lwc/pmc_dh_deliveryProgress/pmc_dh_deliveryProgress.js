import { LightningElement, api } from "lwc";
import pmc_brandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import pmc_deliveryTracking_deliveryProgress from "@salesforce/label/c.pmc_deliveryTracking_deliveryProgress";
import pmc_deliveryTracking_current from "@salesforce/label/c.pmc_deliveryTracking_current";

/**
 * A custom LWC to display delivery progress.
 * @alias Pmc_dh_deliveryProgress
 * @extends LightningElement
 * @hideconstructor
 * @author Venkata Sai Mouli, Agastya
 * @example
 * <c-pmc_dh_delivery-progress></c-pmc_dh_delivery-progress>
 */

export default class Pmc_dh_deliveryProgress extends LightningElement {
  @api deliveryProgress;
  labels = {
    pmc_deliveryTracking_deliveryProgress,
    pmc_deliveryTracking_current
  }

  iconUrl = `${pmc_brandingStaticResource}/icons/icon-gray-rectangle.svg`;
}