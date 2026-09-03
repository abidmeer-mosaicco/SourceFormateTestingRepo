import { LightningElement, track } from 'lwc';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

import pmc_contactUs_title from "@salesforce/label/c.pmc_contactUs_title";
import pmc_contactUs_mail from "@salesforce/label/c.pmc_contactUs_mail";
import pmc_contactUs_general from "@salesforce/label/c.pmc_contactUs_general";
import pmc_contactUs_us from "@salesforce/label/c.pmc_contactUs_us";
import pmc_contactUs_canada from "@salesforce/label/c.pmc_contactUs_canada";
import pmc_contactUs_brazil from "@salesforce/label/c.pmc_contactUs_brazil";
import pmc_contactUs_india from "@salesforce/label/c.pmc_contactUs_india";
import pmc_contactUs_faqs from "@salesforce/label/c.pmc_contactUs_faqs";
import pmc_emailTemplate_email from "@salesforce/label/c.pmc_emailTemplate_email";
import pmc_userDetails_phone from "@salesforce/label/c.pmc_userDetails_phone";

/**
 * A custom LWC for Contact Us Page.
 * @alias Pmc_dh_contactUs
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant Soni
 * @example
 * <c-pmc_dh_contact-us></c-pmc_dh_contact-us>
 */

export default class Pmc_dh_contactUs extends LightningElement {

  @track labels = {
    pmc_contactUs_title,
    pmc_contactUs_mail,
    pmc_contactUs_general,
    pmc_contactUs_us,
    pmc_contactUs_canada,
    pmc_contactUs_brazil,
    pmc_contactUs_india,
    pmc_contactUs_faqs,
    pmc_emailTemplate_email,
    pmc_userDetails_phone
  };
  mailToEmail = "mailto:" + pmc_contactUs_mail;

  @track iconUrlObj = {
    mailIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-mail-address.svg`,
    phoneIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-phone-number.svg`,
    faqIconUrl: `${PMC_BrandingAssetsStaticResource}/icons/icon-faqs.svg`,
  };
}