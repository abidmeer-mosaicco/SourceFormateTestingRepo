// import { LightningElement } from 'lwc';
// import CopadoLinkedinLogo from '@salesforce/resourceUrl/CopadoLinkedinLogo';
// import CopadoTwitterLogo from '@salesforce/resourceUrl/CopadoTwitterLogo';
// import CopadoFacebookLogo from '@salesforce/resourceUrl/CopadoFacebookLogo';
// import CopadoInstagramLogo from '@salesforce/resourceUrl/CopadoInstagramLogo';
// import CopadoYoutubeLogo from '@salesforce/resourceUrl/CopadoYoutubeLogo';
// import CopadoMosaicLogo from '@salesforce/resourceUrl/CopadoMosaicLogo';

// export default class CopadoFooterPageComp extends LightningElement {

//     linkedinIcon = CopadoLinkedinLogo;
//     twitterIcon = CopadoTwitterLogo;
//     facebookIcon = CopadoFacebookLogo;
//     instagramIcon = CopadoInstagramLogo;
//     youtubeIcon = CopadoYoutubeLogo;
//     mosaicLogo = CopadoMosaicLogo;

//     get currentYear() {
//         return new Date().getFullYear();
//     }
// }




import { LightningElement } from 'lwc';
import CopadoMosaicLogo from '@salesforce/resourceUrl/CopadoMosaicLogo';
import privacypolicy from '@salesforce/label/c.SchedulerSite_privacypolicy';
import tnc from '@salesforce/label/c.SchedulerSite_tnc';
import aboutus from '@salesforce/label/c.SchedulerSite_aboutus';
import contactus from '@salesforce/label/c.SchedulerSite_contactus';

export default class CopadoFooterPageComp extends LightningElement {

    mosaicLogo = CopadoMosaicLogo;

    label = {
        privacypolicy,
        tnc,
        aboutus,
        contactus

    };

    get currentYear() {
        return new Date().getFullYear();
    }

}