import { LightningElement, api, track } from 'lwc';

export default class MiskiMayoReusableButtonHoverColor extends LightningElement {
    @api label = '';
    @api url = '';
    @api backgroundColor = '';
    @api backgroundHoverColor = '';
    @api borderColor = '';
    @api borderThickness = '';
    @api borderRadius = '';
    @api textColor = '';
    @api fontSize = '';

    @track styleButton;
    @track stylesLoaded = false;
    @track showButton = false;
    @api openUrlInANewTab = '';

    originalStyle = '';

    connectedCallback() {
        if (!this.stylesLoaded) {
            if (this.borderThickness && this.borderRadius && this.fontSize && this.label && this.url && this.backgroundColor && this.borderColor && this.textColor) {
                this.originalStyle = `font-size: ${this.fontSize}rem; background-color: ${this.backgroundColor}; border: ${this.borderThickness}px solid ${this.borderColor}; color: ${this.textColor}; padding: 10px 20px; border-radius: ${this.borderRadius}px; cursor: pointer; font-weight: bold; text-align: center; transition: all 0.3s ease;`;
                this.styleButton = this.originalStyle;
                this.showButton = true;
                this.stylesLoaded = true;
            }
        }
    }

    handleMouseOver() {
        this.styleButton = this.originalStyle.replace(`background-color: ${this.backgroundColor};`, `background-color: ${this.backgroundHoverColor};`);
    }

    handleMouseOut() {
        this.styleButton = this.originalStyle;
    }

    handleClick() {
        if (this.url) {
            if(this.openUrlInANewTab === 'true') {
                window.open(this.url, '_blank');
            }else
            {
                window.location.href = this.url;
            }
        }
    }
}