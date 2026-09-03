import { LightningElement, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import md_themeAssets from '@salesforce/resourceUrl/md_themeAssets';
import getActiveRouteGuards from '@salesforce/apex/MD_MenuService.getActiveRouteGuards';
import hasDebug from '@salesforce/customPermission/MD_DEBUG';

const DEBUG = (...args) => {
    if (hasDebug) console.log('[MD_THEME]', ...args);
};

/**
 * @slot header
 * @slot footer
 * @slot cookie
 */
export default class MdTheme extends NavigationMixin(LightningElement) {
    _cssLoaded = false;
    cssVersion = 'v1';

    isEvaluating = true;
    hasAccess = false;

    routeMap = null;
    currentPath = null;

    @wire(getActiveRouteGuards)
    wiredGuards({ error, data }) {
        if (error) {
            console.error('[MD_THEME] Error routing permissions.', error);
            this.hasAccess = true;
            this.isEvaluating = false;
            return;
        }

        if (!data) return;

        this.routeMap = data;
        this.checkAccess();
    }

    @wire(CurrentPageReference)
    pageRef(reference) {
        if (!reference) return;
        this.currentPath = window.location.pathname;
        this.checkAccess();
    }

    checkAccess() {
        if (!this.routeMap || !this.currentPath) return;

        let isAllowed = true;
        let sortedRoutes = Object.keys(this.routeMap).sort((a, b) => b.length - a.length);

        for (const routeUrl of sortedRoutes) {
            if (this.currentPath === routeUrl || this.currentPath.endsWith(routeUrl) || this.currentPath.includes(routeUrl)) {
                isAllowed = this.routeMap[routeUrl];
                break;
            }
        }

        if (!isAllowed) {
            DEBUG(`Access Denied for URL ${this.currentPath}. Redirecting to Home.`);
            this.hasAccess = false;

            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Home'
                }
            }, true);
        } else {
            DEBUG(`Access Granted for URL ${this.currentPath}`);
            this.hasAccess = true;
        }

        this.isEvaluating = false;
    }

    renderedCallback() {
        if (this._cssLoaded) return;
        this._cssLoaded = true;

        let dynamicPath = `${md_themeAssets}/${this.cssVersion}/global.css`;

        loadStyle(this, dynamicPath).then(() => {
            DEBUG(`CSS ${this.cssVersion} injected successfully.`);
        }).catch(error => {
            console.error(`[MD_THEME] CSS ${this.cssVersion} ERROR: `, error);
        });
    }
}