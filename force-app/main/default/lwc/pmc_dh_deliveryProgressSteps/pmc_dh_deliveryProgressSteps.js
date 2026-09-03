import { LightningElement, api } from 'lwc';

/**
 * A custom LWC to display Delivery Progress Steps.
 * @alias Pmc_dh_deliveryProgressSteps
 * @extends LightningElement
 * @hideconstructor
 * @author Venkata Sai Mouli, Agastya
 * @example
 * <c-pmc_dh_delivery-progress-steps></c-pmc_dh_delivery-progress-steps>
 */

export default class Pmc_dh_deliveryProgressSteps extends LightningElement {
    @api stepsData = [];
}