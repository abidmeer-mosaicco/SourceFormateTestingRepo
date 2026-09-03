import { LightningElement, track, api } from 'lwc';
import getTopicsBySectionValue from '@salesforce/apex/DocumentTopicController.getTopicsBySectionValue';

export default class DocumentEnvironmentalSetup extends LightningElement {
    @api sectionValue = 'Org Setup';
    @api pageTitle = 'Environmental Setup';
    @api openAllOnLoad = false;

    @track topics = [];
    @track allTopics = [];

    isLoading = true;
    errorMessage;
    noResults = false;
    _debounce;

    get title() {
        return this.pageTitle || this.sectionValue;
    }

    connectedCallback() {
        this.load();
    }

    load() {
        this.isLoading = true;
        const sv = (this.sectionValue || '').trim();
        getTopicsBySectionValue({ sectionValue: sv })
            .then((data) => {
                const shape = (arr, expanded) => (arr || []).map(t => ({
                    ...t,
                    _expanded: !!expanded,
                    articles: (t.articles || []).map(a => ({
                        ...a,
                        // useful if you later add search/filter
                        _searchBlob: this.stripHtml(a.bodyHtml || '')
                    }))
                }));
                this.allTopics = shape(data, this.openAllOnLoad);
                this.topics = JSON.parse(JSON.stringify(this.allTopics));
                this.isLoading = false;
            })
            .catch((e) => {
                this.errorMessage = (e?.body?.message) || e.message || 'Unknown error';
                this.isLoading = false;
            });
    }

    toggleTopic = (e) => {
        const id = e.currentTarget.dataset.id;
        this.topics = this.topics.map(t => (t.id === id ? { ...t, _expanded: !t._expanded } : t));
    };

    expandAll = () => {
        this.topics = this.topics.map(t => ({ ...t, _expanded: true }));
    };

    collapseAll = () => {
        this.topics = this.topics.map(t => ({ ...t, _expanded: false }));
    };

    openUrl = (e) => {
        const url = e.currentTarget.dataset.url;
        if (url) window.open(url, '_blank');
    };

    stripHtml(html) {
        const tmp = document.createElement('div');
        tmp.innerHTML = html;
        return (tmp.textContent || tmp.innerText || '').toLowerCase();
    }
}