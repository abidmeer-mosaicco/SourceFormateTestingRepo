import { LightningElement } from 'lwc';
import ICON from '@salesforce/resourceUrl/miskiMayoMenuIcon';
import MM_BASEURL from '@salesforce/label/c.MM_BASEURL';

const LABELS = { MM_BASEURL};

export default class MiskiMayoMenuIconRedirect extends LightningElement {

    icon = ICON + '/miskiMayoIconFinal.png';

    handleClick() {
        const baseUrl = LABELS.MM_BASEURL;
        window.location.href = baseUrl;
    }
}