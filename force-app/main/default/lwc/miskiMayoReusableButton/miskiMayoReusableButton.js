import { LightningElement, api, track } from 'lwc';

export default class MiskiMayoReusableButton extends LightningElement {
    
    @api label = '';// Default value: Label of the Button
    @api url='';//Default value: Insert URL link
    @api backgroundColor='';// Default value: red
    @api borderColor='';// Default value: black
    @api borderThickness='';// Default value: 4px
    @api borderRadius= '';// Default value: 6px
    @api textColor='';// Default value: white
    @api fontSize=''; // Default value: font-size: 1.2rem;

    @track styleButton;
    @track stylesLoaded = false;
    @track showButton = false;

    connectedCallback() {
        if (!this.stylesLoaded) {
            if(this.borderThickness != '' && this.borderRadius != '' && this.fontSize != '' && this.label != '' && this.url != '' && this.backgroundColor != '' && this.borderColor != '' && this.textColor != '')
            {
                this.styleButton = `font-size: ${this.fontSize}rem; background-color: ${this.backgroundColor}; border: ${this.borderThickness}px solid ${this.borderColor}; color: ${this.textColor}; padding: 10px 20px; border-radius: ${this.borderRadius}px; cursor: pointer; font-weight: bold; text-align: center; transition: all 0.3s ease;`
                this.showButton = true;
                this.stylesLoaded = true;
            }
        }
    }

    handleClick() {
        if (this.url) {
            window.location.href = this.url;
        }
    }
}