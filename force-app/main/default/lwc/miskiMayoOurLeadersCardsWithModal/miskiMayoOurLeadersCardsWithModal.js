import { LightningElement, track } from 'lwc';
import CARD_IMAGES from '@salesforce/resourceUrl/miskiMayoOurLeadersCardsWithModal';
import MMmiskiMayoOurLeadersCardsWithModalPart1 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart1";
import MMmiskiMayoOurLeadersCardsWithModalPart2 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart2";
import MMmiskiMayoOurLeadersCardsWithModalPart3 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart3";
import MMmiskiMayoOurLeadersCardsWithModalPart4 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart4";
import MMmiskiMayoOurLeadersCardsWithModalPart5 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart5";
import MMmiskiMayoOurLeadersCardsWithModalPart6 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart6";
import MMmiskiMayoOurLeadersCardsWithModalPart7 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart7";
import MMmiskiMayoOurLeadersCardsWithModalPart8 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart8";
import MMmiskiMayoOurLeadersCardsWithModalPart9 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart9";
import MMmiskiMayoOurLeadersCardsWithModalPart10 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart10";
import MMmiskiMayoOurLeadersCardsWithModalPart11 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart11";
import MMmiskiMayoOurLeadersCardsWithModalPart12 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart12";
import MMmiskiMayoOurLeadersCardsWithModalPart13 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart13";
import MMmiskiMayoOurLeadersCardsWithModalPart14 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart14";
import MMmiskiMayoOurLeadersCardsWithModalPart15 from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPart15";
import MMmiskiMayoOurLeadersCardsWithModalTitle from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalTitle";
import MMmiskiMayoOurLeadersCardsWithModalPresidentTitle from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPresidentTitle";
import MMmiskiMayoOurLeadersCardsWithModalPresidentName from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalPresidentName";
import MMmiskiMayoOurLeadersCardsWithModalDirectorOperationsTitle from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalDirectorOperationsTitle";
import MMmiskiMayoOurLeadersCardsWithModalDirectorOperationsName from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalDirectorOperationsName";
import MMmiskiMayoOurLeadersCardsWithModalDirectorAdministrationTitle from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalDirectorAdministrationTitle";
import MMmiskiMayoOurLeadersCardsWithModalDirectorAdministrationName from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalDirectorAdministrationName";
import MMmiskiMayoOurLeadersCardsWithModalDirectorSecretaryTitle from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalDirectorSecretaryTitle";
import MMmiskiMayoOurLeadersCardsWithModalDirectorSecretaryName from "@salesforce/label/c.MMmiskiMayoOurLeadersCardsWithModalDirectorSecretaryName";

export default class MiskiMayoOurLeadersCardsWithModal extends LightningElement {
    @track isShowModal = false;
    @track selectedCard = {};
    labels = {MMmiskiMayoOurLeadersCardsWithModalTitle, MMmiskiMayoOurLeadersCardsWithModalPart1, MMmiskiMayoOurLeadersCardsWithModalPart2, MMmiskiMayoOurLeadersCardsWithModalPart3, MMmiskiMayoOurLeadersCardsWithModalPart4,
        MMmiskiMayoOurLeadersCardsWithModalPart5, MMmiskiMayoOurLeadersCardsWithModalPart6, MMmiskiMayoOurLeadersCardsWithModalPart7, MMmiskiMayoOurLeadersCardsWithModalPart8,
        MMmiskiMayoOurLeadersCardsWithModalPart9, MMmiskiMayoOurLeadersCardsWithModalPart10, MMmiskiMayoOurLeadersCardsWithModalPart11, MMmiskiMayoOurLeadersCardsWithModalPart12,
        MMmiskiMayoOurLeadersCardsWithModalPart13, MMmiskiMayoOurLeadersCardsWithModalPart14, MMmiskiMayoOurLeadersCardsWithModalPart15,
        MMmiskiMayoOurLeadersCardsWithModalPresidentTitle, MMmiskiMayoOurLeadersCardsWithModalPresidentName, MMmiskiMayoOurLeadersCardsWithModalDirectorOperationsTitle,
        MMmiskiMayoOurLeadersCardsWithModalDirectorOperationsName, MMmiskiMayoOurLeadersCardsWithModalDirectorAdministrationTitle, MMmiskiMayoOurLeadersCardsWithModalDirectorAdministrationName,
        MMmiskiMayoOurLeadersCardsWithModalDirectorSecretaryTitle, MMmiskiMayoOurLeadersCardsWithModalDirectorSecretaryName
    };

    cards = [
        {
            id: 1,
            title: 'Card 1',
            modalContent: {
                name: this.labels.MMmiskiMayoOurLeadersCardsWithModalPresidentName,
                text: this.labels.MMmiskiMayoOurLeadersCardsWithModalPresidentTitle,
                image: CARD_IMAGES + '/photo1.jpg',
                classImageCard: 'text-right',
                classImage: 'image-right',
                classFooter: 'card-footer-right',
                description: [this.labels.MMmiskiMayoOurLeadersCardsWithModalPart1, this.labels.MMmiskiMayoOurLeadersCardsWithModalPart2, this.labels.MMmiskiMayoOurLeadersCardsWithModalPart3, this.labels.MMmiskiMayoOurLeadersCardsWithModalPart4]
            }
        },
        {
            id: 2,
            title: 'Card 2',
            body: 'Card 2 Contents',
            modalContent: {
                name: this.labels.MMmiskiMayoOurLeadersCardsWithModalDirectorOperationsName,
                text: this.labels.MMmiskiMayoOurLeadersCardsWithModalDirectorOperationsTitle,
                image: CARD_IMAGES + '/photo2.jpg',
                classImageCard: 'image-center',
                classImage: 'image-width',
                classFooter: 'card-footer',
                description: [this.labels.MMmiskiMayoOurLeadersCardsWithModalPart5, this.labels.MMmiskiMayoOurLeadersCardsWithModalPart6, this.labels.MMmiskiMayoOurLeadersCardsWithModalPart7, this.labels.MMmiskiMayoOurLeadersCardsWithModalPart8]
            }
        },
        {
            id: 3,
            title: 'Card 3',
            body: 'Card 3 Contents',
            modalContent: {
                name: this.labels.MMmiskiMayoOurLeadersCardsWithModalDirectorAdministrationName,
                text: this.labels.MMmiskiMayoOurLeadersCardsWithModalDirectorAdministrationTitle,
                image: CARD_IMAGES + '/photo3.jpg',
                classImageCard: 'text-right',
                classImage: 'image-right',
                classFooter: 'card-footer-right',
                description: [this.labels.MMmiskiMayoOurLeadersCardsWithModalPart9, this.labels.MMmiskiMayoOurLeadersCardsWithModalPart10, this.labels.MMmiskiMayoOurLeadersCardsWithModalPart11, this.labels.MMmiskiMayoOurLeadersCardsWithModalPart12]
            }
        },
        {
            id: 4,
            title: 'Card 4',
            body: 'Card 4 Contents',
            modalContent: {
                name: this.labels.MMmiskiMayoOurLeadersCardsWithModalDirectorSecretaryName,
                text: this.labels.MMmiskiMayoOurLeadersCardsWithModalDirectorSecretaryTitle,
                image: CARD_IMAGES + '/photo4.jpg',
                classImageCard: 'image-center',
                classImage: 'image-width',
                classFooter: 'card-footer',
                description: [this.labels.MMmiskiMayoOurLeadersCardsWithModalPart13, this.labels.MMmiskiMayoOurLeadersCardsWithModalPart14, this.labels.MMmiskiMayoOurLeadersCardsWithModalPart15]
            }
        }
    ];

    handleClick(event) {
        const cardId = parseInt(event.currentTarget.dataset.id, 10);
        const selected = this.cards.find(c => c.id === cardId);
        this.selectedCard = selected.modalContent;
        this.isShowModal = true;
    }

    hideModalBox() {
        this.isShowModal = false;
    }

    handleMouseOver(event) {
        event.currentTarget.classList.add('zoom');
    }

    handleMouseOut(event) {
        event.currentTarget.classList.remove('zoom');
    }
}