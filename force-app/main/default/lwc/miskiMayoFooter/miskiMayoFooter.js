import { LightningElement } from 'lwc';
import IMAGES from '@salesforce/resourceUrl/miskiMayoFooter';
import MMFooterOficinasPiura from "@salesforce/label/c.MMFooterOficinasPiura";
import MMFooterOficinasPiuraAddress from "@salesforce/label/c.MMFooterOficinasPiuraAddress";
import MMFooterOficinasLima from "@salesforce/label/c.MMFooterOficinasLima";
import MMFooterOficinasLimaAddress from "@salesforce/label/c.MMFooterOficinasLimaAddress";
import MMFooterEnlacesdeInteres from "@salesforce/label/c.MMFooterEnlacesdeInteres";
import MMFooterFOSPIBAY from "@salesforce/label/c.MMFooterFOSPIBAY";
import MMFooterSNMPE from "@salesforce/label/c.MMFooterSNMPE";
import MMFooterMosaic from "@salesforce/label/c.MMFooterMosaic";
import MMFooterMitsui from "@salesforce/label/c.MMFooterMitsui";
import MMFooterMineriadetodos from "@salesforce/label/c.MMFooterMineriadetodos";
import MMFooterISEM from "@salesforce/label/c.MMFooterISEM";
import MMFooterEITIPERU from "@salesforce/label/c.MMFooterEITIPERU";
import MMFooterWIMPeru from "@salesforce/label/c.MMFooterWIMPeru";
import MMFooterVisitanuestrasredessociales from "@salesforce/label/c.MMFooterVisitanuestrasredessociales";
import MMFooterFacebook from "@salesforce/label/c.MMFooterFacebook";
import MMFooterYouTube from "@salesforce/label/c.MMFooterYouTube";
import MMFooterLinkedIn from "@salesforce/label/c.MMFooterLinkedIn";
import MMFooterCopyright from "@salesforce/label/c.MMFooterCopyright";
import MMFooterDesarrollado from "@salesforce/label/c.MMFooterDesarrollado";
import MMFooterSNMPEWebsiteLink from "@salesforce/label/c.MMFooterSNMPEWebsiteLink";
import MMFooterMosaicWebsiteLink from "@salesforce/label/c.MMFooterMosaicWebsiteLink";
import MMFooterMitsuiWebsiteLink from "@salesforce/label/c.MMFooterMitsuiWebsiteLink";
import MMFooterMineriadetodosWebsiteLink from "@salesforce/label/c.MMFooterMineriadetodosWebsiteLink";
import MMFooterISEMWebsiteLink from "@salesforce/label/c.MMFooterISEMWebsiteLink";
import MMFooterEITIPERUWebsiteLink from "@salesforce/label/c.MMFooterEITIPERUWebsiteLink";
import MMFooterWIMPeruWebsiteLink from "@salesforce/label/c.MMFooterWIMPeruWebsiteLink";
import MMFooterFacebookWebsiteLink from "@salesforce/label/c.MMFooterFacebookWebsiteLink";
import MMFooterYouTubeWebsiteLink from "@salesforce/label/c.MMFooterYouTubeWebsiteLink";
import MMFooterLinkedInWebsiteLink from "@salesforce/label/c.MMFooterLinkedInWebsiteLink";
import MMFooterFOSPIBAYWebsiteLink from "@salesforce/label/c.MMFooterFOSPIBAYWebsiteLink";
import MMFooterMiskiMayoLogoAltText from "@salesforce/label/c.MMFooterMiskiMayoLogoAltText";
import MM_TRABAJA_CON_NOSOTROS_URL_COMPLETE from "@salesforce/label/c.MM_TRABAJA_CON_NOSOTROS_URL_COMPLETE";
import MM_PROVEEDORES_URL_COMPLETE from "@salesforce/label/c.MM_PROVEEDORES_URL_COMPLETE";
import MM_EXTERNAL_ADRYAN_URL_COMPLETE from "@salesforce/label/c.MM_EXTERNAL_ADRYAN_URL_COMPLETE";   
import MM_EXTERNAL_WORKDAY_URL_COMPLETE from "@salesforce/label/c.MM_EXTERNAL_WORKDAY_URL_COMPLETE";
import MM_INGRESO_A_PUERTO_URL_COMPLETE from "@salesforce/label/c.MM_INGRESO_A_PUERTO_URL_COMPLETE";

export default class MiskiMayoFooter extends LightningElement {
    facebook = IMAGES + '/facebook-icon.png';
    youtube = IMAGES + '/youtube-icon.png';
    linkedin = IMAGES + '/linkedin-icon.png';
    miskiMayoLogo = IMAGES + '/miskimayo-logo.png';
    locationIcon = IMAGES + '/location-icon.png';
    showFooter = false;


    labels = {
        MMFooterOficinasPiura,
        MMFooterOficinasPiuraAddress,
        MMFooterOficinasLima,
        MMFooterOficinasLimaAddress,
        MMFooterEnlacesdeInteres,
        MMFooterFOSPIBAY,
        MMFooterSNMPE,
        MMFooterMosaic,
        MMFooterMitsui,
        MMFooterMineriadetodos,
        MMFooterISEM,
        MMFooterEITIPERU,
        MMFooterWIMPeru,
        MMFooterVisitanuestrasredessociales,
        MMFooterFacebook,
        MMFooterYouTube,
        MMFooterLinkedIn,
        MMFooterCopyright,
        MMFooterDesarrollado,
        MMFooterFOSPIBAYWebsiteLink,
        MMFooterSNMPEWebsiteLink,
        MMFooterMosaicWebsiteLink,
        MMFooterMitsuiWebsiteLink,
        MMFooterMineriadetodosWebsiteLink,
        MMFooterISEMWebsiteLink,
        MMFooterEITIPERUWebsiteLink,
        MMFooterWIMPeruWebsiteLink,
        MMFooterFacebookWebsiteLink,
        MMFooterYouTubeWebsiteLink,
        MMFooterLinkedInWebsiteLink,
        MMFooterMiskiMayoLogoAltText,
        MM_TRABAJA_CON_NOSOTROS_URL_COMPLETE,
        MM_PROVEEDORES_URL_COMPLETE,
        MM_EXTERNAL_ADRYAN_URL_COMPLETE,
        MM_EXTERNAL_WORKDAY_URL_COMPLETE,
        MM_INGRESO_A_PUERTO_URL_COMPLETE
    };

    connectedCallback() {
        if(!this.showFooter)
        {
            setTimeout(() => {
                this.showFooter = true;
            }, 3000);
        }
    }
}