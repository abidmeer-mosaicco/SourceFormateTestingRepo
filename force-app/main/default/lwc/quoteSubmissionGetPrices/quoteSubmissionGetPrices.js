import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import postInfoToCPIFromLWC from '@salesforce/apex/PMC_CPQ_FetchLatestPriceBeforeSubmission.postInfoToCPIFromLWC';
import LABEL_GET_LATEST_PRICES_BUTTON from '@salesforce/label/c.QuoteSubmission_GetLatestPricesButton';
import LABEL_RETRY_BUTTON from '@salesforce/label/c.QuoteSubmission_RetryButton';
import LABEL_INSTRUCTIONS from '@salesforce/label/c.QuoteSubmission_Instructions';
import LABEL_INITIALIZING_STATUS from '@salesforce/label/c.QuoteSubmission_InitializingStatus';
import LABEL_FETCHING_PRICES from '@salesforce/label/c.QuoteSubmission_FetchingPrices';
import LABEL_WAITING_FOR_PRICES from '@salesforce/label/c.QuoteSubmission_WaitingForPrices';
import LABEL_PRICES_FETCHED_SUCCESS from '@salesforce/label/c.QuoteSubmission_PricesFetchedSuccess';
import LABEL_PRICES_FETCHED_TOAST_TITLE from '@salesforce/label/c.QuoteSubmission_PricesFetchedToastTitle';
import LABEL_PRICES_FETCHED_TOAST_MESSAGE from '@salesforce/label/c.QuoteSubmission_PricesFetchedToastMessage';
import LABEL_NO_RECORD_ID_ERROR from '@salesforce/label/c.QuoteSubmission_NoRecordIdError';
import LABEL_SAP_CONNECTION_ERROR from '@salesforce/label/c.QuoteSubmission_SAPConnectionError';
import LABEL_DEFAULT_SAP_ERROR from '@salesforce/label/c.QuoteSubmission_DefaultSAPError';
import LABEL_SUBSCRIPTION_ERROR from '@salesforce/label/c.QuoteSubmission_SubscriptionError';
import LABEL_PLATFORM_EVENT_ERROR from '@salesforce/label/c.QuoteSubmission_PlatformEventError';
import LABEL_PROCESSING_ERROR from '@salesforce/label/c.QuoteSubmission_ProcessingError';
import LABEL_TIMEOUT_ERROR from '@salesforce/label/c.QuoteSubmission_TimeoutError';
import LABEL_VALIDATION_PRICE_NOT_COMPLETE from '@salesforce/label/c.QuoteSubmission_ValidationPriceNotComplete';
import LABEL_VALIDATION_STILL_LOADING from '@salesforce/label/c.QuoteSubmission_ValidationStillLoading';
import LABEL_VALIDATION_HAS_ERROR from '@salesforce/label/c.QuoteSubmission_ValidationHasError';
import LABEL_VALIDATION_CANNOT_PROCEED_TITLE from '@salesforce/label/c.QuoteSubmission_ValidationCannotProceedTitle';
import LABEL_VALIDATION_BASIC_MESSAGE from '@salesforce/label/c.QuoteSubmission_ValidationBasicMessage';
import LABEL_PROCESSING_SPINNER from '@salesforce/label/c.QuoteSubmission_ProcessingSpinner';

export default class QuoteSubmissionGetPrices extends LightningElement {
    @api recordId;
    @api quoteName;
    @api quoteRegion;
    
    @api canProceed = false;
    @api isLoading = false;
    @api statusMessage = '';
    @api errorMessage = '';
    @api priceCalloutSuccess = false;
    
    @api availableActions = [];
    
    @api required = false;
    
    @track showRetryButton = false;
    iframeLoaded = false;

    get labels() {
        return {
            LABEL_GET_LATEST_PRICES_BUTTON: LABEL_GET_LATEST_PRICES_BUTTON,
            LABEL_RETRY_BUTTON: LABEL_RETRY_BUTTON,
            LABEL_INSTRUCTIONS_MESSAGE: LABEL_INSTRUCTIONS,
            LABEL_PROCESSING_SPINNER: LABEL_PROCESSING_SPINNER
        };
    }

    renderedCallback() {
        if (!this.iframeLoaded) {
            this.iframeLoaded = true;
            console.log('🔄 LWC renderedCallback: initializing flow state and adding message listener');
            window.addEventListener('message', this.handleVfMessage);
            this.initializeFlowState();
            this.handleFetchPrices();
        }
    }
    
    connectedCallback() {
        
    }
    
    disconnectedCallback() {
        console.log('🔌 LWC disconnectedCallback: removing message listener');
        window.removeEventListener('message', this.handleVfMessage);
    }
    
    initializeFlowState() {
        console.log('🚀 Initializing flow state');
        this.canProceed = false;
        this.isLoading = true;
        this.statusMessage = LABEL_INITIALIZING_STATUS;
        this.priceCalloutSuccess = false;
        this.errorMessage = '';
        this.updateFlowAttributes();
    }
    
    async handleFetchPrices() {
        console.log('➡️ handleFetchPrices called');
        if (!this.recordId) {
            this.showError(LABEL_NO_RECORD_ID_ERROR);
            return;
        }
        
        this.startPriceFetch();
        
        setTimeout(async () => {
        try {
            console.log('⏳ Waiting for prices...');
            this.statusMessage = LABEL_WAITING_FOR_PRICES;
            this.updateFlowAttributes();
            setTimeout(async () => {
                console.log('⏰ Timeout reached, proceeding with postInfoToCPIFromLWC');
                let result = await postInfoToCPIFromLWC({ lstQuotes: [{ Id: this.recordId }] });
                console.log('✅ postInfoToCPIFromLWC result', result);
            }, 1200); // 1.2 seconds timeout
        } catch (error) {
            console.error('❌ Error fetching prices:', error);
            this.handlePriceFetchError(LABEL_SAP_CONNECTION_ERROR + (error.body?.message || error.message));
        }
        }, 3000);
    }
    
    startPriceFetch() {
        console.log('🔄 Starting price fetch process');
        this.isLoading = true;
        this.canProceed = false;
        this.errorMessage = '';
        this.showRetryButton = false;
        this.statusMessage = LABEL_FETCHING_PRICES;
        this.updateFlowAttributes();
    }
    
    handleVfMessage = (event) => {
        console.log('📩 Received message from VF:', event);
        if (!event || !event.data) return;
        if (event.data.type === 'cometd-event' && event.data.event === '/event/Get_Price_Response__e') {
            const payload = event.data.payload && event.data.payload.payload;
            console.log('📦 Platform event payload:', payload);
            if (payload && payload.Quote__c === this.recordId) {
                if (payload.StatusCode__c === 200) {
                    console.log('✅ Price fetch success event for this quote');
                    this.handlePriceFetchSuccess();
                } else {
                    let errorMessage = LABEL_DEFAULT_SAP_ERROR;
                    try {
                        let errorPayload = payload.Message__c;
                        console.error(errorPayload);
                        if(errorPayload){
                            if(errorPayload.includes('"details":')){
                                if(!errorPayload.endsWith('}')){
                                    if(!errorPayload.endsWith('"')){
                                        errorPayload = errorPayload + '"';
                                    }
                                    errorPayload = errorPayload + '}';
                                }
                            }
                            const error = JSON.parse(errorPayload);
                            errorMessage = error.details || errorMessage;
                        }
                    } catch (e) {}
                    console.error('❌ Price fetch error event:', errorMessage);
                    this.handlePriceFetchError(errorMessage);
                }
            }
        } else if (event.data.type === 'cometd-error') {
            console.error('❌ CometD error from VF:', event.data.error);
            this.handlePriceFetchError(event.data.error || LABEL_PLATFORM_EVENT_ERROR);
        }
    };

    handlePriceFetchSuccess() {
        console.log('✅ handlePriceFetchSuccess: updating state and firing toast');
        this.isLoading = false;
        this.canProceed = true;
        this.priceCalloutSuccess = true;
        this.statusMessage = LABEL_PRICES_FETCHED_SUCCESS;
        this.errorMessage = '';
        this.showRetryButton = false;
        this.updateFlowAttributes();
        this.dispatchEvent(new ShowToastEvent({
            title: LABEL_PRICES_FETCHED_TOAST_TITLE,
            message: LABEL_PRICES_FETCHED_TOAST_MESSAGE,
            variant: 'success'
        }));
        this.handleGoNext();
    }
    
    handlePriceFetchError(errorMessage) {
        console.error('❌ handlePriceFetchError:', errorMessage);
        this.isLoading = false;
        this.canProceed = false;
        this.priceCalloutSuccess = false;
        this.statusMessage = '';
        this.errorMessage = errorMessage;
        this.showRetryButton = true;
        this.updateFlowAttributes();
    }
    
    async handleRetry() {
        console.log('🔁 handleRetry called');
        this.initializeFlowState();
        this.handleFetchPrices();
    }
    
    showError(message) {
        console.error('❌ showError:', message);
        this.errorMessage = message;
        this.showRetryButton = true;
        this.updateFlowAttributes();
    }
    
    updateFlowAttributes() {
        console.log('📡 updateFlowAttributes: canProceed', this.canProceed, 'isLoading', this.isLoading, 'statusMessage', this.statusMessage, 'errorMessage', this.errorMessage, 'priceCalloutSuccess', this.priceCalloutSuccess);
        this.dispatchEvent(new FlowAttributeChangeEvent('canProceed', this.canProceed));
        this.dispatchEvent(new FlowAttributeChangeEvent('isLoading', this.isLoading));
        this.dispatchEvent(new FlowAttributeChangeEvent('statusMessage', this.statusMessage));
        this.dispatchEvent(new FlowAttributeChangeEvent('errorMessage', this.errorMessage));
        this.dispatchEvent(new FlowAttributeChangeEvent('priceCalloutSuccess', this.priceCalloutSuccess));
    }
    
    @api
    validate() {
        console.log('🔍 validate called: canProceed', this.canProceed, 'isLoading', this.isLoading, 'errorMessage', this.errorMessage, 'priceCalloutSuccess', this.priceCalloutSuccess);
        if (!this.canProceed) {
            return { isValid: false, errorMessage: LABEL_VALIDATION_PRICE_NOT_COMPLETE };
        }
        if (this.isLoading) {
            return { isValid: false, errorMessage: LABEL_VALIDATION_STILL_LOADING };
        }
        if (this.errorMessage) {
            return { isValid: false, errorMessage: LABEL_VALIDATION_HAS_ERROR + this.errorMessage };
        }
        return { isValid: true };
    }

    @api
    get isValid() {
        return this.canProceed && !this.isLoading && !this.errorMessage;
    }

    @api
    get validationMessage() {
        if (!this.canProceed) return LABEL_VALIDATION_BASIC_MESSAGE;
        if (this.isLoading) return LABEL_VALIDATION_STILL_LOADING;
        if (this.errorMessage) return LABEL_VALIDATION_HAS_ERROR + this.errorMessage;
        return null;
    }
    
    handleGoNext() {
        console.log('➡️ handleGoNext called');
        setTimeout(() => {
            const validationResult = this.validate();
            console.log('🔍 handleGoNext validationResult:', validationResult);
            if (validationResult.isValid) {
                if (this.availableActions.find(action => action === 'NEXT')) {
                    const navigateNextEvent = new FlowNavigationNextEvent();
                    this.dispatchEvent(navigateNextEvent);
                }
            } else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Cannot Proceed',
                    message: validationResult.errorMessage,
                    variant: 'error'
                }));
            }
        }, 1000);
    }
}