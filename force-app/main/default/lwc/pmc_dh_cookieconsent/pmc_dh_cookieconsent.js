import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {isCategoryAllowedForCurrentConsent,setCookieConsent} 
  from 'lightning/userConsentCookie'

export default class Pmc_dh_cookieconsent extends LightningElement {
    @track checkedEssential = true;
    @track checkedPreferences = isCategoryAllowedForCurrentConsent("Preferences");
    @track checkedMarketing = isCategoryAllowedForCurrentConsent("Marketing");
    @track checkedStatistics = isCategoryAllowedForCurrentConsent("Statistics");

    @track
    consent = {
        Preferences : this.checkedPreferences,
        Marketing : this.checkedMarketing,
        Statistics : this.checkedEssential
    }

    changeToggleEssential(event){
        console.log("Change toggle Essential triggered. Cannot be changed");
        this.checkedEssential = this.checkedEssential;
        this.showErrorToast();
    }
    
    changeTogglePreferences(event){
        console.log("Change toggle Preference triggered");
        this.checkedPreferences = !this.checkedPreferences;
        console.log("Current setting for Preferences : " + this.checkedPreferences);
        this.setPreferences(this.checkedPreferences);
        console.log(JSON.parse(JSON.stringify(this.consent)));
        setCookieConsent(this.consent);
    }

    changeToggleMarketing(event){
        console.log("Change toggle Marketing triggered");
        this.checkedMarketing = !this.checkedMarketing;
        console.log("Current setting for Marketing : " + this.checkedMarketing);
        this.setMarketing(this.checkedMarketing);
        console.log(JSON.parse(JSON.stringify(this.consent)));
        setCookieConsent(this.consent);
    }

    changeToggleStatistics(event){
        console.log("Change toggle Statistics triggered");
        this.checkedStatistics = !this.checkedStatistics;
        console.log("Current setting for Statistics : " + this.checkedStatistics);
        this.setStatistics(this.checkedStatistics);
        console.log(JSON.parse(JSON.stringify(this.consent)));
        setCookieConsent(this.consent);
    }

    showErrorToast() {
        const evt = new ShowToastEvent({
            title: 'Essential Cookies cannot be blocked',
            message: 'These cookies are required for the app to function properly.',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    setPreferences(value) {
        this.consent.Preferences = value;
    }

    setMarketing(value) {
        this.consent.Marketing = value;
    }

    setStatistics(value) {
        this.consent.Statistics = value;
    }

    handleClickSetConsent() {
        console.log(JSON.parse(JSON.stringify(this.preferences)));
        setCookieConsent(this.consent);
    }

}