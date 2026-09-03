import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import basePath from '@salesforce/community/basePath';
import Id from '@salesforce/user/Id';
import USER_ACCOUNT_FIELD from '@salesforce/schema/User.AccountId';
import getProductSuggestions from '@salesforce/apex/PMC_DH_ProductSuggestionsClass.getProductSuggestions';
import Enable_Global_Search from '@salesforce/customPermission/Enable_Global_Search';

import pmc_searchBar_productSuggestionsText from "@salesforce/label/c.pmc_searchBar_productSuggestionsText";
import pmc_searchBar_globalSearchText from "@salesforce/label/c.pmc_searchBar_globalSearchText";
import pmc_searchBar_search from "@salesforce/label/c.pmc_searchBar_search";
import { toastMessageHandler } from "c/pmc_dh_utilityJs";

/**
 * A Custom Search Flyout.
 * @alias Pmc_dh_searchBar
 * @description    : To show items in Search Flyout. 
 * @author Himanshu Rathore
 * @example
 * <c-pmc_dh_search-bar></c-pmc_dh_search-bar>
 */
const MIN_LENGTH = 3;
const DONE_TYPING_INTERVAL = 500;

export default class PMC_DH_searchBarLWC extends NavigationMixin(LightningElement) {
  @track searchTerm = '';
  @track effectiveAccountId;
  @track error;
  @track _urlToForm;
  @track _isSearchFlyout = false;
  @track _searchResults = [];
  @track tempSearchTerm;
  @track labels = {
    pmc_searchBar_productSuggestionsText,
    pmc_searchBar_search
  }
  typingTimer;
  inputText = '';
  isSearchBar = Enable_Global_Search;

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    this.searchTerm = currentPageReference.state?.term || '';
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    window.addEventListener('click', e => {
      if (!this.template.querySelector('.search-container').contains(e.target)) {
        this.clearSearchResults();
      }
    })
  }

  /**
  * Handle search on search icon click
  * @function handleSearchChange
  */
  handleSearchChange() {
    this.navigateToPage();
  }

  /**
  * To Navigate on global-search page, when user hits enter or click on search-icon
  * @function navigateToPage
  */
  navigateToPage() {
    this._urlToForm = this.template.querySelector('.search').value.trim();
    const pageRef = {
      type: 'standard__webPage',
      attributes: {
        url: `${basePath}${pmc_searchBar_globalSearchText}/${encodeURIComponent(this._urlToForm)}`,
      }
    };

    if (this._urlToForm) {
      this.clearSearchResults();
      this[NavigationMixin.Navigate](pageRef)
    }
  }

  /**
  * Searching on enter key
  * @function handleSearchTermKeyDown
  * @param {Event} event 
  */
  handleSearchTermKeyDown(event) {
    if (event.keyCode === 13) {
      this.navigateToPage();
    }
  }

  /**
  * Fetching Effective Account Id
  */
  @wire(getRecord, { recordId: Id, fields: [USER_ACCOUNT_FIELD] })
  currentUserInfo({ error, data }) {
    if (data) {
      this.effectiveAccountId = data.fields.AccountId.value;
    } else if (error) {
      this.error = error;
    }
  }

  /**
  * User enter first 3 characters of any product name in the search, it will auto-suggest previously searched terms in flyout
  * @function search
  * @param {Event} event 
  */
  search = (event) => {
    if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
      this.effectiveAccountId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    }
    this.inputText = event.detail.value.toLowerCase().trim();
    clearTimeout(this.typingTimer);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.typingTimer = setTimeout(() => {
      if (this.inputText && this.inputText.length >= MIN_LENGTH) {
        getProductSuggestions({
          strSearchTerm: this.inputText,
          strEffectiveAccountId: this.effectiveAccountId,
        })
          .then((result) => {
            if (result && Object.keys(result).length) {
              if (JSON.parse(JSON.stringify(result)).statusCodeMessage?.strStatusMessage) {
                toastMessageHandler(JSON.parse(JSON.stringify(result)).statusCodeMessage.strStatusMessage)
              }
              const searchResultsMap = JSON.parse(JSON.stringify(result.lstProdSuggestions)).map((el, index) => ({
                id: index,
                element: el
              }));
              this._isSearchFlyout = true;
              this._searchResults = searchResultsMap;
            }
          })
          .catch(() => {
            toastMessageHandler();
          });
      }
      else {
        this.clearSearchResults();
      }
    }, DONE_TYPING_INTERVAL);
  }

  /**
  * To Navigate on global-search page, when user selects from search flyout
  * @function handleSearchFlyoutChange
  * @param {Event} event 
  */
  handleSearchFlyoutChange(event) {
    event.preventDefault();
    const selectedValue = event.target.dataset.productVal;
    const pageRef = {
      type: 'standard__webPage',
      attributes: {
        url: `${basePath}${pmc_searchBar_globalSearchText}/${encodeURIComponent(selectedValue)}`,
      }
    };
    if (selectedValue) {
      this.searchTerm = '';
      this.clearSearchResults();
      this[NavigationMixin.Navigate](pageRef)
    }
  }

  /**
  * To hide the search result flyout 
  * @function clearSearchResults
  */
  clearSearchResults = () => {
    this._searchResults = null;
    this._isSearchFlyout = false;
  }

  /** 
  * Key Press for Product Selection in Search Flyout
  * @function searchFlyoutKeypressHandler
  * @param {Event} event
  */
  searchFlyoutKeypressHandler = (event) => {
    if (event.keyCode === 13) {
      event.preventDefault();
      this.handleSearchFlyoutChange(event);
    }
  }

  /**
   * Close the search flyout
   * @function closeSearchFlyout
   */
  closeSearchFlyout = () => {
    this._isSearchFlyout = false;
  }
}