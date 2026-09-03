import { LightningElement, api } from 'lwc';
export default class FeatureButton extends LightningElement { 
    @api label; 
    @api iconName; 
    @api description; 
    handleClick() { 
        this.dispatchEvent(new CustomEvent('click', { bubbles: true, composed: true })); 
    }

    handleKey(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleClick();
        }
    }
}