import { LightningElement } from 'lwc';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

export default class Pmc_dh_outage extends LightningElement {
    mosaicLogoUrl;

    connectedCallback(){
        this.mosaicLogoUrl = `${PMC_BrandingAssetsStaticResource}/images/logo-mosaic.png`
    }
       
}