import { LightningElement } from 'lwc';
import MosaicLogo from '@salesforce/resourceUrl/pmc_MosaicLogo';
//import BrandingAssets from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import title from '@salesforce/label/c.SchedulerSite_title';


export default class SchedulerSiteHeader extends LightningElement {
   MosiacLogo = MosaicLogo;

   //MosiacLogo = `${BrandingAssets}/images/mosaic_logo_NA.png`;

     label = {
        title
    };



}