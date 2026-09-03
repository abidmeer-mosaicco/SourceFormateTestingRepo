import { LightningElement, api, track } from 'lwc';
import findProducts from '@salesforce/apex/PMC_CPQ_ProductLookupController.findProducts';
import getProductById from '@salesforce/apex/PMC_CPQ_ProductLookupController.getProductById';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class ProductLookupFlow extends LightningElement {
    @track searchKey = '';
    @track results = [];
    @track selectedProductName = '';
    @api label;
    @api placeholder = 'Digite para buscar produtos...';
    
    _value;
    @api 
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val;
        if (val) {
            this.loadProduct(val);
        }
    }

    connectedCallback() {
        if (this.value) {
            this.loadProduct(this.value);
        }
    }

    loadProduct(productId) {
        getProductById({ productId })
            .then(product => {
                if (product) {
                    this.selectedProductName = product.PMC_CPQ_Product_Code_Name__c;
                    this.searchKey = product.PMC_CPQ_Product_Code_Name__c;
                }
            })
            .catch(error => {
                console.error('Erro ao carregar produto:', error);
            });
    }

    handleInputChange(event) {
        const searchKey = event.target.value;
        this.searchKey = searchKey;

        if (searchKey.length >= 2) {
            findProducts({ searchKey })
                .then(result => {
                    this.results = result;
                })
                .catch(error => {
                    console.error('Erro na busca de produtos:', error);
                    this.results = [];
                });
        } else {
            this.results = [];
        }
    }

    handleResultClick(event) {
        const productId = event.currentTarget.dataset.id;
        const productName = event.currentTarget.dataset.name;

        this.selectedProductName = productName;
        this._value = productId;
        this.searchKey = productName;
        this.results = [];

        this.dispatchEvent(new FlowAttributeChangeEvent('value', this._value));
    }

    get hasResults() {
        return this.results && this.results.length > 0;
    }
}