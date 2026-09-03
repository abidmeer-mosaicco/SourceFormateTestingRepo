import { LightningElement, api } from 'lwc';

export default class Pmc_dh_spinner extends LightningElement {
    @api alternativeText = 'Loading';
    @api size = 'medium';
    @api isSpinner;
    @api variant = 'brand';
}