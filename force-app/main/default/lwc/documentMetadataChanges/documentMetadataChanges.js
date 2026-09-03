import { LightningElement, track, api } from 'lwc';
import getTopicsBySectionValue from '@salesforce/apex/DocumentTopicController.getTopicsBySectionValue';

export default class DocumentMetadataChanges extends LightningElement {
    @api sectionValue = 'Making Metadata Changes';  // exact picklist label
    @api pageTitle = 'Making Metadata Changes';
    @api openAllOnLoad = false;

    @track topics = [];
    @track allTopics = [];

    isLoading = true;
    errorMessage;
    noResults = false;
    _debounce;

    get title() { return this.pageTitle || this.sectionValue; }

    connectedCallback() { this.load(); }

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
                        _searchBlob: this.stripHtml(a.bodyHtml || '')
                    }))
                }));
                this.allTopics = shape(data, this.openAllOnLoad);
                this.topics = JSON.parse(JSON.stringify(this.allTopics));
                this.isLoading = false;
                requestAnimationFrame(() => this.renderBodies());
            })
            .catch((e) => { this.errorMessage = (e?.body?.message) || e.message || 'Unknown error'; this.isLoading = false; });
    }

    // (rest identical to the Org Setup component)
    toggleTopic = (e) => { const id = e.currentTarget.dataset.id; this.topics = this.topics.map(t => (t.id === id ? { ...t, _expanded: !t._expanded } : t)); requestAnimationFrame(() => this.renderBodies()); };
    expandAll = () => { this.topics = this.topics.map(t => ({ ...t, _expanded: true })); requestAnimationFrame(() => this.renderBodies()); };
    collapseAll = () => { this.topics = this.topics.map(t => ({ ...t, _expanded: false })); };
    openUrl = (e) => { const url = e.currentTarget.dataset.url; if (url) window.open(url, '_blank'); };
    
    renderBodies() {
        this.topics.forEach(t => {
            if (!t._expanded) return;
            (t.articles || []).forEach(a => {
                const host = this.template.querySelector(`.rt[data-article-id="${a.id}"]`);
                if (host) host.innerHTML = a.bodyHtml || '';
            });
        });
    }
    stripHtml(html) { const tmp = document.createElement('div'); tmp.innerHTML = html; return (tmp.textContent || tmp.innerText || '').toLowerCase(); }
}