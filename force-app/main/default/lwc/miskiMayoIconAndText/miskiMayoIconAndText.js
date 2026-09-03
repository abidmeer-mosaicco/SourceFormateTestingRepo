import { LightningElement, api } from 'lwc';
import ICONS from '@salesforce/resourceUrl/miskiMayoReusableTiles';

export default class MiskiMayoIconAndText extends LightningElement {
    // (1) Icon
    /** File name (without extension) within the Static Resource (ex.: "fertilizante") */
    @api iconName;
    /** Icon size as number; will be applied in rem (ex.: 6 -> "6rem") */
    @api iconSize = 6;
    /** Optional alternative text for accessibility; if empty, uses headerText */
    @api iconAlt = '';

    // (2) Text - Header
    @api headerText = 'Header';
    /** Font Size Header in px (number) */
    @api headerFontSize = 22;
    /** Header Weight (ex.: 400, 600, 700 ou "bold") */
    @api headerFontWeight = '700';

    // (2) Text - Body
    @api bodyText = 'Body text goes here.';
    /** Font Size Body in px (number) */
    @api bodyFontSize = 16;
    /** Body Weight (ex.: 400, 500) */
    @api bodyFontWeight = '400';

    // (Optional) Maximum width of text content (px) to limit lines on desktop
    @api maxTextWidth = 900;

    // (Optional) Horizontal space between icon and text (rem)
    @api horizontalGapRem = 1.25;

    // (Optional) Text color (applied to header and body)
    @api textColor = '#111';

    // Icon URL from Static Resource
    get iconUrl() {
        // keeps the same pattern as its example component: <resource>/<name>.svg
        return ICONS + `/${this.iconName}.svg`;
    }

    get iconAltComputed() {
        return this.iconAlt && this.iconAlt.trim() ? this.iconAlt : (this.headerText || 'Icon');
        }

    // Calculated styles
    get containerStyle() {
        // Ensures top alignment and configurable gap
        return `
            gap: ${this.horizontalGapRem}rem;
        `;
    }

    get iconStyle() {
        const size = Number(this.iconSize) || 6;
        return `
            width: ${size}rem;
            height: ${size}rem;
            max-width: ${size}rem;
            max-height: ${size}rem;
        `;
    }

    get headerStyle() {
        const size = Number(this.headerFontSize) || 22;
        const weight = this.headerFontWeight || '700';
        return `
            font-size: ${size}px;
            font-weight: ${weight};
            color: ${this.textColor};
            line-height: 1.25;
        `;
    }

    get bodyStyle() {
        const size = Number(this.bodyFontSize) || 16;
        const weight = this.bodyFontWeight || '400';
        return `
            font-size: ${size}px;
            font-weight: ${weight};
            color: ${this.textColor};
            line-height: 1.5;
            max-width: ${Number(this.maxTextWidth) || 900}px;
        `;
    }
}