import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomLookup extends LightningElement {

    @api childObjectApiName = ''; //The API Name of the Object on which Lookup field exist
    @api targetFieldApiName = ''; //The API Name of the Lookup field
    @api fieldLabel = ''; //Your field label here
    @api disabled = false; //It decide weather the lookup field appears as disabled or not
    @api value; //Use this property to populate the default lookup field value
    @api required = false; // It decide the selection is required or not

    handleChange(event) {
        // Creates the event
        const selectedEvent = new CustomEvent('valueselected', {
            detail: event.detail.value
        });
        //dispatching the custom event
        this.dispatchEvent(selectedEvent);
    }

    @api isValid() {
        if (this.required) {
            this.template.querySelector('lightning-input-field').reportValidity();
        }
    }

    @api validateFields() {
        var orderElemet = this.template.querySelector('lightning-input-field');

        if(orderElemet.value === "" || orderElemet.value === undefined || orderElemet.value === null) {
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Select the Order to Proceed further',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
            return false;
        }

        return true;
    }
}