import { LightningElement } from 'lwc';
import MosaicLogo from '@salesforce/resourceUrl/pmc_MosaicLogo';
//import BrandingAssets from "@salesforce/resourceUrl/pmc_brandingStaticResource";
//import { loadStyle } from 'lightning/platformResourceLoader';
import privacypolicy from '@salesforce/label/c.SchedulerSite_privacypolicy';
import tnc from '@salesforce/label/c.SchedulerSite_tnc';
import aboutus from '@salesforce/label/c.SchedulerSite_aboutus';
import contactus from '@salesforce/label/c.SchedulerSite_contactus';
import copyright from '@salesforce/label/c.SchedulerSite_copyright';

export default class  SchedulerSiteFooter extends LightningElement {
 

    //MosiacLogo = `${BrandingAssets}/images/mosaic_logo_NA.png`;
    MosiacLogo = MosaicLogo;

    label = {
        privacypolicy,
        tnc,
        aboutus,
        contactus,
        copyright
       
    };

    


    
}