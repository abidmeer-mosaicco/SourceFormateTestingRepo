import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getMenuItems from '@salesforce/apex/MD_MenuService.getMenuItems';

export default class Md_menuController extends LightningElement {
    @track menuItems = [];
    @track isAdmin = false;
    @track selectedRegion;

    _regionalMenusCache = {};
    _currentPath = '';
    _closeTimers = new Map();

    get hasMenu() {
        return this.menuItems.length > 0;
    }

    get regionOptions() {
        if (!this._regionalMenusCache) return [];
        return Object.keys(this._regionalMenusCache).map(region => ({
            label: `${region} Menu`,
            value: region
        }));
    }

    connectedCallback() {
        this._currentPath = window.location.pathname;
    }

    @wire(CurrentPageReference)
    handlePageChange(pageRef) {
        if (!pageRef) return;

        const newPath = window.location.pathname;
        if (this._currentPath === newPath) return;

        this._currentPath = newPath;
        if (this.hasMenu) {
            this._recalculateActiveStates();
        }
    }

    @wire(getMenuItems)
    wiredMenu({ data, error }) {
        if (error) console.error({ error });
        if (!data) return;

        this.isAdmin = data.isAdmin;

        if (!this.isAdmin) {
            this.menuItems = data.defaultMenu.map(item => this._enrichItem(item));
            return;
        }

        this._regionalMenusCache = {};
        for (let [region, items] of Object.entries(data.regionalMenus)) {
            this._regionalMenusCache[region] = items.map(item => this._enrichItem(item));
        }

        let regions = Object.keys(this._regionalMenusCache);
        
        if (!regions.length) {
            this.menuItems = [];
            return;
        }

        if (!this.selectedRegion || !regions.includes(this.selectedRegion)) {
            this.selectedRegion = regions[0];
        }
        
        this.menuItems = this._regionalMenusCache[this.selectedRegion];
    }

    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;
        this.menuItems = this._regionalMenusCache[this.selectedRegion] || [];
    }

    handleDropdownEnter(event) {
        let key = event.currentTarget.dataset.key;
        clearTimeout(this._closeTimers.get(key));
        this._closeTimers.delete(key);

        this.menuItems = this.menuItems.map(item =>
            item.featureKey === key ? { ...item, isOpen: true } : item
        );
    }

    handleDropdownLeave(event) {
        let key = event.currentTarget.dataset.key;

        let timer = setTimeout(() => {
            this.menuItems = this.menuItems.map(item =>
                item.featureKey === key ? { ...item, isOpen: false } : item
            );
            this._closeTimers.delete(key);
        }, 250);

        this._closeTimers.set(key, timer);
    }

    _recalculateActiveStates() {
        this.menuItems = this.menuItems.map(item => this._enrichItem(item));
        
        if (!this.isAdmin) return;
        
        for (let region in this._regionalMenusCache) {
            this._regionalMenusCache[region] = this._regionalMenusCache[region].map(item => this._enrichItem(item));
        }
    }

    _enrichItem(item) {
        let children = item.children?.map(child => {
            let childActive = this._isActiveExact(child.url);

            return {
                ...child,
                isActive: childActive,
                linkClass: this._linkClass(childActive)
            };
        }) ?? null;

        let isActive = children
            ? children.some(child => child.isActive)
            : this._isActive(item.url);

        return {
            ...item,
            isOpen: item.isOpen || false,
            isActive,
            linkClass: this._linkClass(isActive),
            children
        };
    }

    _isActive(url) {
        if (!url || url === '#') return false;
        return this._currentPath === url || this._currentPath.startsWith(url + '/');
    }

    _isActiveExact(url) {
        if (!url || url === '#') return false;
        return this._currentPath === url;
    }

    _linkClass(isActive) {
        return isActive ? 'md-menu-link active' : 'md-menu-link';
    }
}