import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import FILTER_CHANNEL from '@salesforce/messageChannel/FilterEvent__c';
import getLastIntegrationUpdate from '@salesforce/apex/TrackTraceController.getLastIntegrationUpdate';
import USER_ID from "@salesforce/user/Id";

const STORAGE_KEY = 'mosaic:tableType';

export default class MosaicBargeRail extends LightningElement {

    _buttonNames = [];
    activeTab;
    hasPublishedInitial = false;
    isVisible = true;
    lastUpdate;

    @wire(MessageContext)
    messageContext;

    @wire(getLastIntegrationUpdate)
    wiredUpdate({ data, error }) {
        if (data) {
            this.lastUpdate = data;
        }
        if (error) {
            console.error(error);
        }
    }

    get lastUpdateFormatted() {
        if (!this.lastUpdate) return null;

        const formatted = new Intl.DateTimeFormat('en-US', {
            dateStyle: 'medium',
            timeStyle: 'short'
        }).format(new Date(this.lastUpdate));

        return ` ${formatted}`;
    }

    @api
    set buttonNames(value) {
        this._buttonNames = this.normalizeToArray(value);

        if (this._buttonNames.length > 0) {
            const scoped = (k) => `${k}:${USER_ID}`;
            const stored = localStorage.getItem(scoped(STORAGE_KEY));

            if (stored && this._buttonNames
                .map(label => this.normalizeValue(label))
                .includes(stored)) {

                this.activeTab = stored;
            } else {
                this.activeTab = this.normalizeValue(this._buttonNames[0]);
            }
        }
    }

    get buttonNames() {
        return this._buttonNames;
    }

    connectedCallback() {
        this.tryInitialPublish();
    }

    disconnectedCallback() {
        const scoped = (k) => `${k}:${USER_ID}`;
        const firstTab = this.normalizeValue(this._buttonNames[0]);

        try {
            localStorage.setItem(scoped(STORAGE_KEY), firstTab);
        } catch (e) {
            console.log('Unable to access localStorage:', e);
        }
    }

    renderedCallback() {
        this.tryInitialPublish();
    }

    tryInitialPublish() {
        if (
            !this.hasPublishedInitial &&
            this.messageContext &&
            this.activeTab
        ) {
            this.publishCurrentTab();
            this.hasPublishedInitial = true;
        }
    }



    get computedTabs() {
        return this._buttonNames.map(label => {
            const value = this.normalizeValue(label);
            return {
                label,
                value,
                className: value === this.activeTab ? 'tab active' : 'tab'
            };
        });
    }

    handleTabClick(event) {
        const selectedValue = event.currentTarget.dataset.value;

        if (selectedValue === this.activeTab) return;

        this.activeTab = selectedValue;
        this.publishCurrentTab();
    }

    publishCurrentTab() {
        if (!this.activeTab) return;

        const scoped = (k) => `${k}:${USER_ID}`;

        // sessionStorage.setItem(STORAGE_KEY, this.activeTab);
        try {
            localStorage.setItem(scoped(STORAGE_KEY), this.activeTab);
        } catch (e) {
            console.log('Unable to access localStorage:', e);
        }

        if (this.messageContext) {
            publish(this.messageContext, FILTER_CHANNEL, {
                value: this.activeTab
            });
        }
    }

    normalizeToArray(value) {
        if (!value) return [];
        if (Array.isArray(value)) return value;
        if (typeof value === 'string') {
            return value.split(',')
                .map(v => v.trim())
                .filter(Boolean);
        }
        return [];
    }

    normalizeValue(label) {
        return label.toLowerCase().replace(/\s+/g, '');
    }

    handleDismiss() {
        this.isVisible = false;
    }
}