import { LightningElement,api, wire } from 'lwc';
import generateContract from '@salesforce/apex/PMC_CPQ_GenerateContract.generateContract';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import {CloseActionScreenEvent} from 'lightning/actions';

export default class Pmc_Cpq_Generatecontract extends NavigationMixin(LightningElement) {
    @api recordId; // Current Quote ID

    @wire(generateContract, { quoteId: '$recordId' })
    wiredContract({ error, data }) {
        if (data) {

            this.closeAction();
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { 
                    url: data 
                },
                state:{
                    target:'_top'
                } 
            })
        } else if (error) {
            console.error(error);
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
            this.closeAction();
        }
    }
    
    handleAction() {
        generateContract({ quoteId: this.recordId })
        .then(url => {
            this.closeAction();
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { 
                    url: url 
                },
                state:{
                    target:'_top'
                } 
            })
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
            this.closeAction();
        });
    }
    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}