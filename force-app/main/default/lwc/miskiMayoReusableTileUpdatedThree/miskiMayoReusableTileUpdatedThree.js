import { LightningElement, api } from 'lwc';
import ICONS from '@salesforce/resourceUrl/miskiMayoReusableTiles';

export default class MiskiMayoReusableTileUpdatedThree extends LightningElement {
    @api textHead;
    @api fontSizeHead;
    @api textColorHead
    @api text;
    @api backGroundColor;
    @api backGroundBorderColor;
    @api iconName;
    @api textColor;
    @api fontSize;
    @api cardHeight;
    @api bottonTextHeight;
    @api borderThickness;
    @api borderColor;
    @api iconSize;
    @api backgroundOpacity;

    @api iconAlignment;
    @api iconPaddingLeft;
    @api iconPaddingRight;
    @api iconPaddingTop;
    @api iconPaddingBottom;


    @api fontHeadStyle;
    @api fontHeadWeight;
    @api borderRadius= '';

    get iconUrl() {
        return ICONS + `/${this.iconName}.svg`;
    }

    get backgroundOverlayStyle() {

        return `
            background-color: ${this.backGroundColor};
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: ${this.cardHeight}px;
            border-radius: 1.25rem;
            z-index: 0;
            opacity: 0.${this.backgroundOpacity};
            border: ${this.borderThickness}px solid ${this.borderColor};
            border-radius: ${this.borderRadius}px;
            border-color: ${this.borderColor};
        `;
    }

    get bottomStyle() {
        return `
            padding: 1rem;
            background-color: ${this.backGroundBorderColor};
            color: ${this.textColor};
            font-size: ${this.fontSize}px;
            height: ${this.bottonTextHeight}px;
            z-index: 1;
        `;
    }

    get textHeaderStyle() {
        return `
            color: ${this.textColorHead};
            font-size: ${this.fontSizeHead}px;
            z-index: 999;
            font-style: ${this.fontHeadStyle};
            font-weight: ${this.fontHeadWeight};
            margin-bottom: 1rem;
        `;
    }

    get iconStyle() {
        return `
            max-width: ${this.iconSize}rem;
            max-height: ${this.iconSize}rem;
            z-index: 1;
        `;
    }

        get iconPosition() {
        return `
            text-align: ${this.iconAlignment};
            padding-left: ${this.iconPaddingLeft}px;
            padding-right: ${this.iconPaddingRight}px;
            padding-top: ${this.iconPaddingTop}px;
            padding-bottom: ${this.iconPaddingBottom}px;
        `;
    }

    //iconPosition
}