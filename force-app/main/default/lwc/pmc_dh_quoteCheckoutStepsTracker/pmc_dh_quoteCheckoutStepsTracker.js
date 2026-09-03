import { LightningElement, api } from 'lwc';

/**
 * A custom LWC to track the steps of quote checkout flow.
 * @alias Pmc_dh_quoteCheckoutStepsTracker
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant
 * @example
 * <c-pmc_dh_quote-checkout-steps-tracker></c-pmc_dh_quote-checkout-steps-tracker>
 */

export default class Pmc_dh_quoteCheckoutStepsTracker extends LightningElement {
    @api stepsData = [];
}