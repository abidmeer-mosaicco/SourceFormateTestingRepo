import { LightningElement, api } from 'lwc';
import ICONS from '@salesforce/resourceUrl/miskiMayoReusableTiles';

export default class MiskiMayoReusableTileHoverCard extends LightningElement {
    @api title;
    @api description;
    @api iconName;
    @api backGroundColor="#ffffff;";
    @api backGroundColorMouseHover;
    @api fontSizeTitle;
    @api fontSizeDescription;
    @api cardHeight;

    get iconUrl() {
        return ICONS + `/${this.iconName}.svg`;
    }

    get cardStyle() {
        return `background-color: ${this.backGroundColor}; width:100%; height: ${this.cardHeight}px;`;
    }


    get hoverStyle() {
        return `background-color: ${this.backGroundColorMouseHover};`;
    }

    get fontSizeTitleStyle() {
        return `font-size: ${this.fontSizeTitle}px;`;
    }

    get fontSizeDescriptionStyle() {
        return `font-size: ${this.fontSizeDescription}px;`;
    }
}