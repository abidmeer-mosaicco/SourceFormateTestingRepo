import { LightningElement, api } from 'lwc';
import ICONS from '@salesforce/resourceUrl/miskiMayoReusableTiles';

export default class MiskiMayoReusableTile extends LightningElement {
    @api text;
    @api backGroundColor; //#ffffff;
    @api backGroundBorderColor; // Default Miski Mayo border color #e32e12; backGroundBorderColor
    @api iconName;
    @api textColor;
    @api fontSize;
    @api cardHeight;
    @api bottonTextHeight;

    get iconUrl() {
        return ICONS + `/${this.iconName}.svg`;
    }

    get cardStyle() {
        return `
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            border: 1px solid ${this.backGroundBorderColor};
            border-radius: 1.25rem;
            overflow: hidden;
            width: 100%;
            height: ${this.cardHeight}px;
            text-align: center;
            background-color:${this.backGroundColor};
        `;
    }

    get iconStyle() {
        return `
            background-color:${this.backGroundColor};
        `;
    }

    get iconSection() {
        return `
            padding: ${this.iconPadding}px 0;
            background-color: white;
        `;
    }

    get iconStyle() {
        return `
        max-width: ${this.iconSize}px 0;
        max-height: ${this.iconSize}px 0;
        `;
    }
                
    get bottomStyle() {
        return `
            background-color: ${this.backGroundBorderColor};
            padding: 1rem;
            color: ${this.textColor};
            font-size: ${this.fontSize}px;
            height: ${this.bottonTextHeight}px;
        `;
    }

    get textStyle() {
        return `
            background-color: ${this.backGroundBorderColor};
            padding: 1rem;
            color: white;
            font-size: 0.875rem;
        `;
    }
}