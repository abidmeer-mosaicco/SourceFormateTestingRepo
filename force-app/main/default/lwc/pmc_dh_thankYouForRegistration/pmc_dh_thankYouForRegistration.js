import { LightningElement, track } from 'lwc';

import pmc_registration_thankYouText from "@salesforce/label/c.pmc_registration_thankYouText";
import pmc_registration_representativeCall from "@salesforce/label/c.pmc_registration_representativeCall";
import pmc_registration_learnMoreAboutMosaic from "@salesforce/label/c.pmc_registration_learnMoreAboutMosaic";
import pmc_registration_learnMoreAboutMosaicUrl from "@salesforce/label/c.pmc_registration_learnMoreAboutMosaicUrl";

export default class Pmc_dh_thankYouForRegistration extends LightningElement {
    @track labels = {
        pmc_registration_thankYouText,
        pmc_registration_representativeCall,
        pmc_registration_learnMoreAboutMosaic,
        pmc_registration_learnMoreAboutMosaicUrl
    }
}