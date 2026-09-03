import { LightningElement, track } from 'lwc';

export default class Pmc_dh_userManagement extends LightningElement {
    @track items = [{
        label: 'Account Details',
        state: 'active',
        value: 'accountDetails',
        id: 1,
    },
    {
        label: 'User Details',
        state: 'inActive',
        value: 'userDetails',
        id: 2,
    },
    {
        label: 'Addresses',
        state: 'inActive',
        value: 'addresses',
        id: 3,
    },
    {
        label: 'Credit',
        state: 'inActive',
        id: 4,
    },
    {
        label: 'Preferences',
        state: 'inActive',
        id: 5,
    },
    {
        label: 'Rebates',
        state: 'inActive',
        id: 6,
    },
    {
        label: 'Subscription',
        state: 'inActive',
        id: 7,
    },
    {
        label: 'User Management',
        state: 'inActive',
        id: 8,
    },
    {
        label: 'Leads Management',
        state: 'inActive',
        id: 9,
    },
    ]
    @track userManagementTabsHandler = {
        accountDetails: true,
        userDetails: false,
        addresses: false,
    }

    isPageLoaded = false;
    isArrowNeeded = true;
    isSmallScreen = false;
    isMediumScreen = false;

    idNav = 1;
    idContent = 1;


    renderedCallback() {
        if (this.isPageLoaded) return;
        this.isSmallScreen = window.screen.width <= 768;
        this.isMediumScreen = window.screen.width > 768 && window.screen.width <= 1180;
        this.tabNavHandler();
        this.isPageLoaded = true;
    }

    handleItemClickEvent(event) {
        const id = event.target?.dataset?.id;
        Object.keys(this.userManagementTabsHandler).forEach(el => {
            this.userManagementTabsHandler[el] = false;
        });
        this.userManagementTabsHandler[event.target.dataset.value] = true;
        this.items.forEach(item => {
            item.state = item.id.toString() === id.toString() ? 'active' : 'inActive';
        });
    }

    tabNavHandler() {
        let itemWidth = this.template.querySelector('.slds-tabs_default__nav.slds-list_horizontal').clientWidth;
        this.template.querySelector('.slds-tabs_default__nav.slds-list_horizontal').style.maxWidth = itemWidth + 'px';
        this.template.querySelectorAll('.slds-tabs_default__item').forEach((ele) => {
            let x = +ele.getAttribute('data-id');
            if (this.isSmallScreen) {
                // ele.style.maxWidth = itemWidth / 2 + 'px';
                ele.classList.add('hide-small');
                if (x == this.idNav || x == this.idNav + 1) {
                    ele.classList.remove('hide-small');
                }
            }
            if (this.isMediumScreen) {
                // ele.style.maxWidth = itemWidth / 5 + 'px';
                ele.classList.add('hide-medium');
                if (x >= this.idNav && x <= this.idNav + 4) {
                    ele.classList.remove("hide-medium");
                }
            }
        })
    }

    scrollLeft() {
        this.idNav = this.idNav - 1;
        this.tabNavHandler();
    }
    scrollRight() {
        this.idNav = this.idNav + 1;
        this.tabNavHandler();
    }
    get bDisableBackBtn() {
        return Number(this.idNav) == 1 ? true : false;
    }
    get bDisableNextBtn() {
        if (this.isSmallScreen) {
            return Number(this.idNav) == this.items.length - 1 ? true : false;
        }
        if (this.isMediumScreen) {
            return Number(this.idNav) == this.items.length - 4 ? true : false;
        }
    }

}