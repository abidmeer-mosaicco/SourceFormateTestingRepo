import { LightningElement } from 'lwc';

export default class ScrollToExternalSection extends LightningElement {
    handleClick() {
        //const section = document.querySelector('#compromisos-contractuales');
        const section = "https://globaldigitalacceleration--devp1.sandbox.my.site.com/miskimayo/s/gestion-social?language=en_US#compromisos-contractuales"
        console.log("section "+section);

        const baseUrl = window.location.origin;
        console.log("baseUrl "+baseUrl);;
        //const section = this.template.querySelector('#compromisos-contractuales');
        if (section) {
            section.scrollIntoView({ behavior: 'smooth' });
        } else {
            console.warn('Elemento com id "compromisos-contractuales" não encontrado.');
        }
    }

    /*handleClick() {
        window.scrollBy({ top: 3200, behavior: 'smooth' });
        const baseUrl = window.location.origin;
        console.log("baseUrl "+baseUrl);;
        //const url = baserl.replace('/apex/', '');
    }*/
}