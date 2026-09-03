import { LightningElement, api, wire, track } from 'lwc';

import { customLabel  } from 'c/pmc_ss_customLabelUtility';

import { NavigationMixin } from "lightning/navigation";
import { CurrentPageReference } from "lightning/navigation";
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from "lightning/uiRecordApi";
//import PMC_SS_SNOW_RequestType_KeyValue from '@salesforce/label/c.PMC_SS_SNOW_RequestType_KeyValue';

import getPickListValues from '@salesforce/apex/PMC_SS_CaseDisputeManagementCtrl.getPickListValues'; 
import getAccountRelatedDetails from '@salesforce/apex/PMC_SS_CaseServiceNowUpdateCtrl.getAccountRelatedDetails';
import getUserDetails from '@salesforce/apex/PMC_SS_CaseServiceNowUpdateCtrl.getUserDetails';
import getInvoices from '@salesforce/apex/PMC_SS_CaseServiceNowUpdateCtrl.getInvoices';
import createSNTicket from '@salesforce/apex/PMC_SS_CaseServiceNowUpdateCtrl.createSNTicket';
import getsnowlistDetails from '@salesforce/apex/PMC_SS_CaseServiceNowUpdateCtrl.getsnowlistDetails';

import ID_FIELD from "@salesforce/schema/Case.Id";
import SNOW_TICKET_TYPE_FIELD from "@salesforce/schema/Case.PMC_SS_ServiceNowTicketType__c";
import SNOW_REQUEST_TYPE_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_RequestType__c";
import SNOW_NEW_CONTRACT_FIELD from "@salesforce/schema/Case.PMC_SS_NewContract__c";
import SNOW_RECIPIENT_OF_CIR_LETTER_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_RecipientsofCirLetter__c";
import SNOW_INITIAL_REQUEST_PERIOD_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_InitialRequestPeriod__c";
import SNOW_MOSAIC_PAYING_RECEIVING_COMPANY_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_MosaicPayingReceivingCompany__c";
import SNOW_CUSTOMER_CODE_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_CustomerCode__c";
import SAP_CUSTOMER_NUMBER_FIELD from "@salesforce/schema/Case.PMC_SS_SAP_CustomerNumber__c";
import CPR_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_CPR__c";
import MORTGAGE_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_Mortage__c";
import INITIAL_DATE_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_InitialDate__c";
import FINAL_DATE_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_FinalDate__c";
import SNOW_WARRANTY_TYPE_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_WarrantyType__c";
import CASE_CURRENCY_FIELD from "@salesforce/schema/Case.CurrencyIsoCode";
import SNOW_FINANCIAL_OPERATION_VALUE_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_FinancialOperationValue__c";
import SNOW_ENDORSEMENT_VALUE_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_EndorsementValue__c";
import SNOW_PAYEE_NAME_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_PayeeName__c";
import SNOW_CONTRACT_AMENDMENT_TYPE_FIELD from "@salesforce/schema/Case.PMC_SS_ContractAmendmentType__c";
import SNOW_UOM_CONVERSION_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_UnitofMeasurementConversion__c";
import SNOW_ORDER_OR_CONTRACT_NUMBER_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_OrderNumberorContractNumber__c";
import SNOW_COMMENTS_FIELD from "@salesforce/schema/Case.Comments";

import SNOW_ISSUEREASON_FIELD from "@salesforce/schema/Case.PMC_SS_IssueReason__c";
import SNOW_Type_FIELD from "@salesforce/schema/Case.Type";
import SNOW_EXACT_DATETOBE_PAID_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_ExactDateToBePaid__c";
import SNOW_SEGMENT_MANAGER_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_SegmentManager__c";
import SNOW_BUSINESS_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_Business__c";
import SNOW_REASON_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_Reason__c";
import SNOW_CASE_NUMBER_FIELD from "@salesforce/schema/Case.CaseNumber"; 
import SNOW_ABATEMENTCONTRACT_NUMBER_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_AbatementContractNumber__c"; 
import SNOW_PROGRAM_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_Program__c";
import SNOW_ORDER_CONTRACT_FIELD from "@salesforce/schema/Case.PMC_SS_SNOW_OrderNumberorContractNumber__c";
import SNOW_INVOICE_FIELD from "@salesforce/schema/Case.PMC_SS_Invoice__c";
import SNOW_TICKET_NUMBER from "@salesforce/schema/Case.PMC_SS_SNOW_ServiceNowTicketNumber__c";
import SNOW_TICKET_SYNC_ID from "@salesforce/schema/Case.PMC_SS_SNOW_ServiceNowTicketSyncId__c";
import SNOW_TICKET_STATUS from "@salesforce/schema/Case.PMC_SS_SNOW_StatusLabel__c";
import SNOW_TICKET_STATUS_VALUE from "@salesforce/schema/Case.PMC_SS_SNOW_StatusValue__c";

import USER_ID from '@salesforce/user/Id'; //this is how you will retreive the USER ID of current in user.
import FEDERATION_ID from '@salesforce/schema/User.FederationIdentifier';

const FIELDS = ['Case.AccountId', 'Case.Account.Name','Case.PMC_SS_IssueReason__c','Case.Type','Case.PMC_SS_SNOW_Business__c','Case.PMC_SS_SNOW_Reason__c', 'Case.PMC_SS_Invoice__c',
                'Case.PMC_SS_SNOW_RequestType__c','Case.PMC_SS_SNOW_SegmentManager__c','Case.PMC_SS_SNOW_OrderNumberorContractNumber__c',
                'Case.PMC_SS_NewContract__c','Case.PMC_SS_NewContract__r.SBQQ__Quote__r.SBQQ__CustomerAmount__c','Case.CurrencyIsoCode',
                'Case.ContactId', 'Case.CreatedById', 'Case.Contact.Name', 'Case.CreatedBy.Manager.Name', 'Case.CreatedBy.Name',
                'Case.Account.PMC_SS_SAPCustomerNumber__c','Case.PMC_SS_SNOW_ExactDateToBePaid__c','Case.PMC_SS_SNOW_Program__c',
                'Case.CaseNumber','Case.PMC_SS_SNOW_AbatementContractNumber__c',
                'Case.PMC_SS_SNOW_RecipientsofCirLetter__c', 'Case.PMC_SS_SNOW_InitialRequestPeriod__c',
                'Case.PMC_SS_SNOW_MosaicPayingReceivingCompany__c', 'Case.ContactPhone', 'Case.PMC_SS_AccountManager__c', 'Case.PMC_SS_AccountManager__r.Name', 'Case.ContactEmail', 
                'Case.PMC_SS_SNOW_CustomerCode__c', 'Case.PMC_SS_SNOW_WarrantyType__c', 'Case.PMC_SS_SNOW_FinancialOperationValue__c',
                'Case.PMC_SS_SNOW_EndorsementValue__c','Case.PMC_SS_SAP_CustomerNumber__c','Case.PMC_SS_SNOW_CPR__c',
                'Case.PMC_SS_SNOW_PayeeName__c','Case.PMC_SS_SNOW_InitialDate__c','Case.PMC_SS_SNOW_FinalDate__c',
                'Case.PMC_SS_ContractAmendmentType__c','Case.PMC_SS_SNOW_Mortage__c',
                'Case.PMC_SS_SNOW_UnitofMeasurementConversion__c','Case.PMC_SS_SNOW_OrderNumberorContractNumber__c',
                'Case.Product.PMC_CPQ_SAPProductCode__c', 'Case.Product.PMC_CPQ_ProductShortDescription__c','Case.Comments' //'Case.PMC_SS_SNOW_CenterToBeExpanded__c',
                ];

export default class Pmc_ss_caseServiceNowUpdate extends NavigationMixin(LightningElement) {

    @track customLabels = customLabel;

    @track recordId = '';
    @track selectedSolution;

    @track solutions = [];
    @track solutionsTemp = [];
    @track companies = [];
    @track requestTypes = [];
    @track contracts = [];
    @track mosaicPayingReceivingCompanies = [];
    @track warrantyTypes = [];
    @track caseCurrencies =[];
    @track contractAmendmentTypes = [];
    @track nitrates = [];
    @track uomConversions = [];
    @track accountName = '';
    @track orders = [];
    @track contractValues = [];
    @track segmentManagers = [];
    @track arraySNOW = {};    

    @track manager = '';
    @track name = '';
    @track requestType = '';
    @track contract = '';
    @track contactPhone = '';
    //@track circularisationLetterName = '';
    @track recipientOfCircularizationLetter = '';
    @track initialRequestPeriod = '';
    @track mosaicPayingReceivingCompany = ''; 
    //@track taxIdOrCNPJOrCPF = '';
    @track accountManager = '';
    @track customerCode = '';
    @track sapCustomerNumber = '';
    @track contractValue = '';
    @track cpr =false;
    @track mortgage =false;
    @track initialDate = '';
    @track finalDate = '';
    @track exactDateTobePaid = '';
    @track warrantyType = '';
    @track caseCurrency ='';
    @track financialOperationValue = '';
    @track contactEmail = '';
    @track endorsementValue = '';
    @track contractAmendmentType = '';
    //@track centerToBeExpanded = '';
    @track comments = '';
    @track sapProductCode = '';
    @track productShortDescription = '';
    @track uomConversion = false;
    @track segmentManager = '';
    @track businessValue = '';
    @track businessValues = [];
    @track programValue = '';
    @track programValues = [];
    @track reasonValue = '';
    @track reasonValues = [];
    @track invoiceValue = '';
    @track invoiceValues = [];
    @track isLoading = false;

    @track dataReceived = {};

    @track dataToBeUpdated = {};
    @track isSolutionSelected= false;
    @track caseType = '';
    @track issueReason = '';
    @track isDisplaySolution = false;
    @track orderOrContactNumber = '';
    @track abatementContractNumber = '';
    @track caseNumber = '';
    @track reasonDetail ='';
    @track unity ='';
    //@track orderOrContractNumber ='';
    @track federationIdentifier ='';

   


    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        this.recordId = currentPageReference.state.recordId;
        this.dataToBeUpdated[ID_FIELD.fieldApiName] = currentPageReference.state.recordId;
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        console.log('Calling getRecords');
        if(data) {
            console.log('**Data --> ' + JSON.stringify(data));
            if(data.fields) {

                this.dataReceived = data;
                if(data.fields.PMC_SS_IssueReason__c.value && data.fields.Type.value) {

                    this.issueReason = data.fields.PMC_SS_IssueReason__c.value;
                    this.caseType = data.fields.Type.value;
                    this.fetchSolution();
                }
        
                if(data.fields.AccountId.value) {
                    this.fetchOrdersAndContracts(data.fields.AccountId.value);
                    this.getInvoiceValues(data.fields.AccountId.value,data.fields.PMC_SS_Invoice__c.value);
                    
                }
                
                if(data.fields.CreatedBy.value.fields.Manager.displayValue) {
                    this.manager = data.fields.CreatedBy.value.fields.Manager.displayValue;
                }

                if(data.fields.Contact.displayValue) {
                    this.name = data.fields.Contact.displayValue;
                }

                if(data.fields.PMC_SS_SNOW_AbatementContractNumber__c.value) {
                    this.abatementContractNumber = data.fields.PMC_SS_SNOW_AbatementContractNumber__c.value;
                }
                
                if(data.fields.CaseNumber.value) {
                    this.caseNumber = data.fields.CaseNumber.value;
                }
                if(data.fields.PMC_SS_SNOW_RequestType__c.value) {
                    this.requestType = data.fields.PMC_SS_SNOW_RequestType__c.value;
                }
                if(data.fields.PMC_SS_SNOW_Business__c.value) {
                    this.businessValue = data.fields.PMC_SS_SNOW_Business__c.value;
                }
                if(data.fields.PMC_SS_SNOW_Reason__c.value) {
                    this.reasonValue = data.fields.PMC_SS_SNOW_Reason__c.value;
                    if(this.reasonValue =='7'){
                        this.fetchProgramValues();
                    }
                }
                if(data.fields.PMC_SS_SNOW_Program__c.value) {
                    this.programValue = data.fields.PMC_SS_SNOW_Program__c.value;
                }

                if(data.fields.PMC_SS_SNOW_SegmentManager__c.value) {
                    this.segmentManager = data.fields.PMC_SS_SNOW_SegmentManager__c.value;
                }
                
                if(data.fields.Account.value) {
                    if(data.fields.Account.value.fields) {
                        if(data.fields.Account.value.fields.PMC_SS_SAPCustomerNumber__c.value) {
                            this.sapCustomerNumber = data.fields.Account.value.fields.PMC_SS_SAPCustomerNumber__c.value;
                        }
                        if(data.fields.Account.value.fields.Name.value) {
                            this.accountName = data.fields.Account.value.fields.Name.value;
                        }
                    }
                }
                if(data.fields.PMC_SS_SNOW_InitialRequestPeriod__c.value) {
                    this.initialRequestPeriod = data.fields.PMC_SS_SNOW_InitialRequestPeriod__c.value;
                }

                if(data.fields.PMC_SS_SNOW_MosaicPayingReceivingCompany__c.value) {
                    this.mosaicPayingReceivingCompany = data.fields.PMC_SS_SNOW_MosaicPayingReceivingCompany__c.value;
                }

                if(data.fields.PMC_SS_SNOW_RecipientsofCirLetter__c.value) {
                    this.recipientOfCircularizationLetter = data.fields.PMC_SS_SNOW_RecipientsofCirLetter__c.value;
                }

                if(data.fields.ContactPhone.value) {
                    this.contactPhone = data.fields.ContactPhone.value;
                }

                if(data.fields.PMC_SS_AccountManager__r.displayValue) {
                    this.accountManager = data.fields.PMC_SS_AccountManager__r.displayValue;
                }

                if(data.fields.ContactEmail.value) {
                    this.contactEmail = data.fields.ContactEmail.value;
                }

                if(data.fields.PMC_SS_SNOW_OrderNumberorContractNumber__c.value) {
                    this.orderOrContactNumber = data.fields.PMC_SS_SNOW_OrderNumberorContractNumber__c.value;
                }
                if(data.fields.PMC_SS_SNOW_CPR__c.value) {
                    this.cpr = data.fields.PMC_SS_SNOW_CPR__c.value;
                }
                if(data.fields.PMC_SS_SNOW_Mortage__c.value) {
                    this.mortgage = data.fields.PMC_SS_SNOW_Mortage__c.value;
                }
                if(data.fields.PMC_SS_SNOW_InitialDate__c.value) {
                    this.initialDate = data.fields.PMC_SS_SNOW_InitialDate__c.value;
                }
                if(data.fields.PMC_SS_SNOW_FinalDate__c.value) {
                    this.finalDate = data.fields.PMC_SS_SNOW_FinalDate__c.value;
                }
                if(data.fields.PMC_SS_SNOW_ExactDateToBePaid__c.value) {
                    this.exactDateTobePaid = data.fields.PMC_SS_SNOW_ExactDateToBePaid__c.value;
                }
                if(data.fields.PMC_SS_SNOW_WarrantyType__c.value) {
                    this.warrantyType = data.fields.PMC_SS_SNOW_WarrantyType__c.value;
                }
                if(data.fields.CurrencyIsoCode.value) {
                    this.caseCurrency = data.fields.CurrencyIsoCode.value;
                }

                if(data.fields.PMC_SS_SNOW_FinancialOperationValue__c.value) {
                    this.financialOperationValue = data.fields.PMC_SS_SNOW_FinancialOperationValue__c.value;
                }
                if(data.fields.PMC_SS_SNOW_EndorsementValue__c.value) {
                    this.endorsementValue = data.fields.PMC_SS_SNOW_EndorsementValue__c.value;
                }

                if(data.fields.PMC_SS_SNOW_PayeeName__c.value) {
                    this.payeeName = data.fields.PMC_SS_SNOW_PayeeName__c.value;
                }
                if(data.fields.PMC_SS_ContractAmendmentType__c.value) {
                    this.contractAmendmentType  = data.fields.PMC_SS_ContractAmendmentType__c.value;
                }
                if(data.fields.PMC_SS_SNOW_UnitofMeasurementConversion__c.value) {
                    this.uomConversion = data.fields.PMC_SS_SNOW_UnitofMeasurementConversion__c.value;
                }

                if(data.fields.Comments .value) {
                    this.comments = data.fields.Comments.value;
                }

                if(data.fields.Product.value) {
                    if(data.fields.Product.value.fields) {
                        if(data.fields.Product.value.fields.PMC_CPQ_ProductShortDescription__c.value) {
                            this.productShortDescription = data.fields.Product.value.fields.PMC_CPQ_ProductShortDescription__c.value;
                        }

                        if(data.fields.Product.value.fields.PMC_CPQ_SAPProductCode__c.value) {
                            this.sapProductCode = data.fields.Product.value.fields.PMC_CPQ_SAPProductCode__c.value;
                        }
                    }
                }
            }           
        }
        else if(error) {
            console.log('Error in fetching data --> ' + JSON.stringify(error));
        }
    }
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [FEDERATION_ID]
    }) wireuser({error, data}) {
        if (error) {
           this.error = error ; 
        } else if (data) {
            this.federationIdentifier =data.fields.FederationIdentifier.value;
        }
    }

    fetchSolution() {
		getPickListValues({
            strObjApiName: 'Case',
            strFieldName: 'PMC_SS_ServiceNowTicketType__c'
			}).then(data => {
                if(data) {
                    this.solutions.push({
                        label: this.customLabels.PMC_SS_SelectOption,
                        value: "--- Select ---"
                    });
                    for (var i=0; i<data.length; i++) {
                    
                        if(this.caseType =='Internal' && this.issueReason == 'Credit Request')
                        {
                            
                            if(data[i].value == 'Customer Credit Analysis' || data[i].value == 'Perform Warranty'
                            || data[i].value == 'Warranty Formalization' || data[i].value == 'Release of Paid Contracts' || data[i].value == 'Debit or Credit Notes') {
                                this.solutions.push({
                                    label:   data[i].label,
                                    value: data[i].value
                                });
                            }                          
                        }
                        else if(this.caseType =='Internal' && this.issueReason == 'Financial Solution'){
                            if(data[i].value == 'Use of Credits, Return, Receipt of Discharge and Reports' || data[i].value == 'Collections Portal'
                            || data[i].value == 'Circularization Letters – Clients' || data[i].value == 'Debit or Credit Notes') {

                                this.solutions.push({
                                    label:   data[i].label,
                                    value: data[i].value
                                });
                            }
                            
                        }
                        
                    }
                    this.getSNOWKeyValues();
                }
			}).catch(error => {
                this.showError(this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,error.body.message);
            });
    }
    handleOnChange(e) {
        let id = this.getRealId(e.target.id);
        if(id == 'solution') {
            this.selectedSolution = e.target.value;
            this.fetchPicklistValues();

            if( this.selectedSolution == 'Collections Portal')
            {
                this.getUserDetailsForCollectionPortal();
            }
        }
        else if(id == 'requestType') {
            this.requestType = e.target.value;

            /*Updating for GPT-28823*/
            this.contractValue='';
            this.contract=''
            this.exactDateTobePaid='';
            this.initialDate='';
            this.finalDate='';
            this.orderOrContactNumber='';

             /* GPT-28823*/
            
        }
        else if(id == 'businessValue') {
            this.businessValue = e.target.value;
        }
        else if(id == 'programValue') {
            this.programValue = e.target.value;
        }
        else if(id == 'reasonValue') {
            this.reasonValue = e.target.value;
            /*Updating for GPT-28823*/
            this.reasonDetail ='';
            this.programValue ='';
            this.abatementContractNumber ='';
            /* GPT-28823*/
            if(this.reasonValue =='7'){
                this.fetchProgramValues();
            }
        }
        else if(id == 'contract') {
           this.contract = e.target.value;
           this.updateContractValue();
        }
        else if(id == 'recipientOfCircularizationLetter') {
            this.recipientOfCircularizationLetter = e.target.value;
        }
        else if(id == 'initialRequestPeriod') {
            this.initialRequestPeriod = e.target.value;
        }
        else if(id == 'mosaicPayingReceivingCompany') {
            this.mosaicPayingReceivingCompany = e.target.value;
        }
        else if(id == 'cpr') {
            this.cpr = e.target.checked;
        }
        else if(id == 'mortgage') {
            this.mortgage = e.target.checked;
        }
        else if(id == 'initialDate') {
            this.initialDate = e.target.value;
        }
        else if(id == 'finalDate') {
            this.finalDate = e.target.value;
        }
        else if(id == 'exactDateToPay') {
            this.exactDateTobePaid = e.target.value;
        }
        else if(id == 'warrantyType') {
            this.warrantyType = e.target.value;
            /*Updating for GPT-28823*/
            this.endorsementValue = '';
            this.financialOperationValue = '';
            this.payeeName='';
           /* GPT-28823*/
        }
        else if(id == 'caseCurrency') {
            this.caseCurrency = e.target.value;
        }
        else if(id == 'financialOperationValue') {
            this.financialOperationValue = e.target.value;
        }
        else if(id == 'endorsementValue') {
            this.endorsementValue = e.target.value;
        }
        else if(id == 'payeeName') {
            this.payeeName = e.target.value;
        }
        else if(id == 'uomConversion') {
            this.uomConversion = e.target.checked;
        }
        else if(id == 'contractAmendmentType') {
            this.contractAmendmentType = e.target.value;
        }
        /*else if(id == 'centerToBeExpanded') {
            this.centerToBeExpanded = e.target.value;
        }*/
        else if(id == 'comments') {
            this.comments = e.target.value;
        }
        else if(id == 'segmentManager') {
            this.segmentManager = e.target.value;
        }
        else if(id == 'abatementContractNumber') {
            this.abatementContractNumber = e.target.value;
        }
        else if(id == 'orderOrContractNumber') {
            this.orderOrContactNumber = e.target.value;
        } 
        else if(id == 'invoice') {
            this.invoiceValue = e.target.value;
        }
        else if(id == 'unity') {
            this.unity = e.target.value;
        }
        else if(id == 'reasonDetail') {
            this.reasonDetail = e.target.value;
        }
        
    }

    get isDisplayOrderContractNumber() {
        return this.selectedSolution =='Use of Credits, Return, Receipt of Discharge and Reports' && 
        (this.requestType == 'Return of Values' || this.requestType == 'Discharge Receipt' || this.requestType == 'Use of the balance in another contract'   );
    }
    
    get isDisplayInitialAndFinalDate() {
        return this.selectedSolution =='Use of Credits, Return, Receipt of Discharge and Reports' && 
        (this.requestType == 'Advance Reports' || this.requestType == 'Compensation reports' || this.requestType == 'Billed and billable portfolio report' ||
        this.requestType == 'Supplementary Invoice Report'  );
    }
    get isDisplayCaseNumberField() {
        return this.selectedSolution =='Debit or Credit Notes' && this.reasonValue == '8';
    }
    get isDisplayReasonDetail() {
        return this.selectedSolution =='Debit or Credit Notes' && this.reasonValue == '6';
    }
    get isDisplayAbatementContractNumberField() {
        return this.selectedSolution =='Debit or Credit Notes' && this.reasonValue == '7';
    }
    
    get isDisplayExactDate() {
        return this.selectedSolution =='Debit or Credit Notes' || (this.selectedSolution == 'Collections Portal' && this.requestType == '3');
    }

    get isContractAnalysisAR() {
        return this.selectedSolution == 'Release of Paid Contracts' || this.selectedSolution == 'Collections Portal';
    }

    get isCircularizationLettersClients(){
        return this.selectedSolution == 'Circularization Letters – Clients';
    }
    get isPerformWarranty(){
        return this.selectedSolution == 'Perform Warranty';
    }

    get isWarrantyFormalization() {
        return this.selectedSolution == 'Warranty Formalization';
    }
    get isCustomerCreditAnalysis() {
        return this.selectedSolution == 'Customer Credit Analysis';;
    }

    get isCollectionsPortal() {
        return this.selectedSolution == 'Collections Portal';
    }
    get isDebitOrCreditNotes() {
        return this.selectedSolution == 'Debit or Credit Notes';
    }

    get isUseofCreditsReturnReceiptofDischargeandReports() {
        return this.selectedSolution == 'Use of Credits, Return, Receipt of Discharge and Reports';
    }

    get isDisplayRequestTypeField() {
        return this.selectedSolution == 'Release of Paid Contracts' || this.selectedSolution == 'Use of Credits, Return, Receipt of Discharge and Reports' ||
        this.selectedSolution == 'Release of Paid Contracts' || this.selectedSolution == 'Collections Portal' || this.selectedSolution =='Debit or Credit Notes';
    }

    get isDisplayContractNumber() {
        return this.selectedSolution == 'Release of Paid Contracts' || (this.selectedSolution == 'Collections Portal' && this.requestType == '3');
    }

    get isDisplayNameField() {
        return this.selectedSolution == 'Warranty Formalization' || this.selectedSolution == 'Collections Portal';
    }
    get isContactEmailField() {
        return this.selectedSolution == 'Use of Credits, Return, Receipt of Discharge and Reports';
    }
    get isSAPCustomerNumberField() {
        return this.selectedSolution == 'Circularization Letters – Clients'||
                this.selectedSolution == 'Use of Credits, Return, Receipt of Discharge and Reports' ||
                this.selectedSolution == 'Perform Warranty' || this.selectedSolution == 'Release of Paid Contracts'
                || this.selectedSolution == 'Customer Credit Analysis' || this.selectedSolution =='Debit or Credit Notes' || (this.selectedSolution == 'Collections Portal' && this.requestType == '3');
    }
    get isCommentField() {
        return this.selectedSolution == 'Circularization Letters – Clients'|| this.selectedSolution == 'Warranty Formalization'||  this.selectedSolution == 'Release of Paid Contracts' ||
                this.selectedSolution == 'Use of Credits, Return, Receipt of Discharge and Reports' || this.selectedSolution == 'Perform Warranty'|| this.selectedSolution == 'Customer Credit Analysis'
                || this.selectedSolution == 'Collections Portal' || this.selectedSolution == 'Debit or Credit Notes';
    }
    get isCommentRequiredField() {
        return this.selectedSolution == 'Circularization Letters – Clients'|| this.selectedSolution == 'Release of Paid Contracts' || this.selectedSolution == 'Perform Warranty'||
                (this.selectedSolution == 'Use of Credits, Return, Receipt of Discharge and Reports' && this.requestType == 'Return of Values') || this.selectedSolution == 'Customer Credit Analysis' 
                || this.selectedSolution == 'Collections Portal' || this.selectedSolution == 'Debit or Credit Notes';
    }

    get isFinancialOperationValueField() {
        return this.warrantyType == '4' && this.selectedSolution == 'Warranty Formalization';
    }
    get isEndorsementValueAndPayeeField() {
        return this.warrantyType == '5' && this.selectedSolution == 'Warranty Formalization';
    }

    get isSolutionSelected(){
        return this.selectedSolution != '--- Select ---';
    }

    fetchPicklistValues() {
        if(this.isContractAnalysisAR || this.isUseofCreditsReturnReceiptofDischargeandReports || this.isDebitOrCreditNotes) {
            this.fetchRequestTypes();
        }
        else if(this.isUseofCreditsReturnReceiptofDischargeandReports) {
            this.fetchCompanies();
        }
        else if(this.isCircularizationLettersClients) {
            this.fetchMosaicPayingReceivingCompanies();
        }
        else if(this.isWarrantyFormalization) {
            this.fetchWarrantyTypes();
        }
        else if(this.isCustomerCreditAnalysis) {
            this.fetchCaseCurrencies();
        }
        if(this.isDebitOrCreditNotes) {
            this.fetchBusinessValues();
            this.fetchReasonValues();
        }
    }

    fetchContractAmendmentTypes() {

        getPickListValues({
            strObjApiName: 'Case',
            strFieldName: 'PMC_SS_ContractAmendmentType__c'
        }).then(data => {
                if(data) {
                    var array = [];
                    for (var i=0; i<data.length; i++) {
                        array.push({
                            label:   data[i].label,
                            value: data[i].value
                        });
                    }

                    this.contractAmendmentTypes = array;
                }
        }).catch(error => {
            this.showError(this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,error.body.message);
        }); 
    }

    fetchWarrantyTypes() {

        getPickListValues({
            strObjApiName: 'Case',
            strFieldName: 'PMC_SS_SNOW_WarrantyType__c'
        }).then(data => {
                if(data) {
                    var array = [];
                    for (var i=0; i<data.length; i++) {
                        array.push({
                            label:   data[i].label,
                            value: data[i].value
                        });
                    }

                    this.warrantyTypes = array;
                }
        }).catch(error => {
            this.showError(this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,error.body.message);
        }); 

    }
    fetchBusinessValues() {

        getPickListValues({
            strObjApiName: 'Case',
            strFieldName: 'PMC_SS_SNOW_Business__c'
        }).then(data => {
                if(data) {
                    var array = [];
                    for (var i=0; i<data.length; i++) {
                        array.push({
                            label:   data[i].label,
                            value: data[i].value
                        });
                    }

                    this.businessValues = array;
                }
        }).catch(error => {
            this.showError(this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,error.body.message);
        }); 

    }
    fetchProgramValues() {

        getPickListValues({
            strObjApiName: 'Case',
            strFieldName: 'PMC_SS_SNOW_Program__c'
        }).then(data => {
                if(data) {
                    var array = [];
                    for (var i=0; i<data.length; i++) {
                        array.push({
                            label:   data[i].label,
                            value: data[i].value
                        });
                    }

                    this.programValues = array;
                }
        }).catch(error => {
            this.showError(this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,error.body.message);
        }); 

    }
    fetchReasonValues() {

        getPickListValues({
            strObjApiName: 'Case',
            strFieldName: 'PMC_SS_SNOW_Reason__c'
        }).then(data => {
                if(data) {
                    var array = [];
                    for (var i=0; i<data.length; i++) {
                        array.push({
                            label:   data[i].label,
                            value: data[i].value
                        });
                    }

                    this.reasonValues = array;
                }
        }).catch(error => {
            this.showError(this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage ,error.body.message);
        }); 

    }

    fetchCaseCurrencies() {

        getPickListValues({
            strObjApiName: 'Case',
            strFieldName: 'CurrencyIsoCode'
        }).then(data => {
                if(data) {
                    var array = [];
                    for (var i=0; i<data.length; i++) {
                        array.push({
                            label:   data[i].label,
                            value: data[i].value
                        });
                    }

                    this.caseCurrencies = array;
                }
        }).catch(error => {
            this.showError(this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage ,error.body.message);
        }); 

    }



    fetchRequestTypes() {

        getPickListValues({
            strObjApiName: 'Case',
            strFieldName: 'PMC_SS_SNOW_RequestType__c'
        }).then(data => {
                if(data) {
                    var array = [];
                    for (var i=0; i<data.length; i++) {
                        if(this.selectedSolution =='Use of Credits, Return, Receipt of Discharge and Reports' && 
                        (data[i].value == 'Advance Reports' || data[i].value == 'Billed and billable portfolio report' || data[i].value == 'Compensation reports' ||
                        data[i].value == 'Discharge Receipt' || data[i].value == 'Receipt Composition' || data[i].value == 'Return of Values' ||
                        data[i].value == 'Supplementary Invoice Report' || data[i].value == 'Use of the balance in another contract' 
                        ))
                        {
                                array.push({
                                    label:   data[i].label,
                                    value: data[i].value
                                });
                                                      
                        }
                        else if(this.selectedSolution =='Release of Paid Contracts' && 
                        (data[i].value == 'Empty Factory' || data[i].value == 'Premium Products' || data[i].value == 'Replan' || data[i].value == 'Scrap Order' || 
                        data[i].value == 'Truck in the Factory' || data[i].value == 'Wallet Lock')){
                                array.push({
                                    label:   data[i].label,
                                    value: data[i].value
                                });
                        } 
                        else if(this.selectedSolution =='Collections Portal' && 
                        (data[i].value == '1' || data[i].value == '2' || data[i].value == '3' || data[i].value == '4' )){
                                array.push({
                                    label:   data[i].label,
                                    value: data[i].value
                                });
                        }
                        else if(this.selectedSolution =='Debit or Credit Notes' && 
                        (data[i].value == '13' || data[i].value == '14' )){
                                array.push({
                                    label:   data[i].label,
                                    value: data[i].value
                                });
                        }
                    }

                    this.requestTypes = array;

                }
        }).catch(error => {
            this.showError(this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,error.body.message);
        }); 
    }

    fetchMosaicPayingReceivingCompanies() {

        getPickListValues({
            strObjApiName: 'Case',
            strFieldName: 'PMC_SS_SNOW_MosaicPayingReceivingCompany__c'
            }).then(data => {
                if(data) {
                    var array = [];
                    for (var i=0; i<data.length; i++) {
                        array.push({
                            label:   data[i].label,
                            value: data[i].value
                        });
                    }

                    this.mosaicPayingReceivingCompanies = array;
                }
            }).catch(error => {
                this.showError(this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,error.body.message);
            });
    }

    getUserDetailsForCollectionPortal()
    {
        getUserDetails().then(data => {
                if(data) {
                    console.log('==data====',data);
                    var array = [];
                    for (var i=0; i<data.length; i++) {
                        array.push({
                            label:   data[i].Name,
                            value: data[i].Id,
                            federationIdentifier: data[i].FederationIdentifier
                        });
                    }
                    this.segmentManagers = array;
                }
            }).catch(error => {
                this.showError(this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,error.body.message);
            });

    }
    getSNOWKeyValues()
    {
        getsnowlistDetails().then(data => {
            if(data) {
                var arrayres = [];
                for (var i=0; i<data.length; i++) {
                    this.arraySNOW[data[i].MasterLabel]=data[i].PMC_SS_Value__c;
                }
            }
        })
    }
            

    
    getInvoiceValues(strAccountId,invoiceTemp)
    {
        getInvoices({
            strAccountId: strAccountId
            }).then(data => {
                if(data) {
                    var array = [];
                    for (var i=0; i<data.length; i++) {
                        array.push({
                            label:   data[i].Name,
                            value: data[i].Id
                        });
                        if (invoiceTemp == data[i].Id) {
                            this.invoiceValue = invoiceTemp
                        }
                    }
                    this.invoiceValues = array;
                }
            }).catch(error => {
                this.showError(this.customLabels.PMC_SS_FailedtoFetchData_ErrorMessage,error.body.message);
            });

    }

    fetchOrdersAndContracts(strAccountId) {

        getAccountRelatedDetails({strAccountId: strAccountId}).then(result => {
            if(result != undefined && result != null) {
                for(var i=0; i<result.Contracts.length; i++) {
                    this.contracts.push({
                        label : result.Contracts[i].ContractNumber,
                        value : result.Contracts[i].ContractNumber,
                        Id : result.Contracts[i].Id
                    });
                    if(result.Contracts[i].SBQQ__Quote__c != undefined && result.Contracts[i].SBQQ__Quote__c != null) {
                        this.contractValues.push({
                            label : result.Contracts[i].SBQQ__Quote__r.SBQQ__CustomerAmount__c,
                            value : result.Contracts[i].ContractNumber
                        });
                    }
                    else {
                        
                        this.contractValues.push({
                            label : 0,
                            value : result.Contracts[i].ContractNumber
                        });
                    }

                    if(this.dataReceived.fields.PMC_SS_NewContract__c.value) {
                        if(this.dataReceived.fields.PMC_SS_NewContract__c.value == result.Contracts[i].Id) {
                            this.contract = result.Contracts[i].ContractNumber;
                            if(result.Contracts[i].SBQQ__Quote__c != undefined && result.Contracts[i].SBQQ__Quote__c != null) {
                                this.contractValue = result.Contracts[i].SBQQ__Quote__r.SBQQ__CustomerAmount__c;
                            } else {
                                this.contractValue = 0;
                            }
                            
                        }
                    }
                } 
            }
            else {

            }
        }).catch(error => {

        });
    }

    saveAction() {
        
        if(this.validateFields()) {
            
            this.prepareDataToBeUpdated();

            this.isLoading = true;

            console.log('Data To Be Updated --> ' + JSON.stringify(this.dataToBeUpdated));

            const recordInput = {
                fields: this.dataToBeUpdated
            };

            updateRecord(recordInput).then(result => {

                if(result != undefined) {
                    //this.isLoading = false;
                    this.showSuccessToast(this.customLabels.PMC_SS_Success_MessageLabel, this.customLabels.PMC_SS_Caseupdated_MessageLabel);
                    this.createSNTicketCallout();
                    //this.closeAction();
                }
                else {
                    this.showError(this.customLabelsPMC_SS_FailedtoUpdateRecord_ErrorMessage,this.customLabels.PMC_SS_PleasetryAgain_MessageLabel);
                }
            })
            .catch(error => {
                console.log('Error --> ' + JSON.stringify(error.body));
                this.showError(this.customLabelsPMC_SS_FailedtoUpdateRecord_ErrorMessage,error.body.message);
            });
        }
        
    }
    isInputValid() {
        
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.Required');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
            
        });
        
        return isValid;
    }


    validateFields() {

        var validationSuccess = true;
        
        if(this.selectedSolution != undefined && this.selectedSolution != '--- Select ---' ) {
            let inputFields = this.template.querySelectorAll('.Required');
            inputFields.forEach(inputField => {
                if(!inputField.checkValidity()) {
                    inputField.reportValidity();
                    validationSuccess = false;
                }
                
            });           
        }
        else {
            validationSuccess = false;
            this.showError(this.customLabels.PMC_SS_SelectTicketType_ErrorMessage,"");
            
        }
        return validationSuccess;
    }

    prepareDataToBeUpdated() {

        this.dataToBeUpdated[SNOW_TICKET_TYPE_FIELD.fieldApiName] = this.selectedSolution;

        if(this.isContractAnalysisAR) {
            this.dataToBeUpdated[SNOW_REQUEST_TYPE_FIELD.fieldApiName] = this.requestType;
            this.dataToBeUpdated[SAP_CUSTOMER_NUMBER_FIELD.fieldApiName] = this.sapCustomerNumber;
            this.dataToBeUpdated[SNOW_COMMENTS_FIELD.fieldApiName] = this.comments;
            this.updateContractNumber();
        }
        else if(this.isCircularizationLettersClients) {
            //this.dataToBeUpdated[SNOW_CIRCULARIZATION_LETTER_NAME_FIELD.fieldApiName] = this.circularisationLetterName;
            this.dataToBeUpdated[SNOW_RECIPIENT_OF_CIR_LETTER_FIELD.fieldApiName] = this.recipientOfCircularizationLetter;
            this.dataToBeUpdated[SNOW_INITIAL_REQUEST_PERIOD_FIELD.fieldApiName] = this.initialRequestPeriod;
            this.dataToBeUpdated[SNOW_MOSAIC_PAYING_RECEIVING_COMPANY_FIELD.fieldApiName] = this.mosaicPayingReceivingCompany;
            this.dataToBeUpdated[SAP_CUSTOMER_NUMBER_FIELD.fieldApiName] = this.sapCustomerNumber;
            this.dataToBeUpdated[SNOW_COMMENTS_FIELD.fieldApiName] = this.comments;
        }
        else if(this.isWarrantyFormalization) {
            //this.dataToBeUpdated[SNOW_CUSTOMER_CODE_FIELD.fieldApiName] = this.customerCode;
            this.dataToBeUpdated[SNOW_WARRANTY_TYPE_FIELD.fieldApiName] = this.warrantyType;
            this.dataToBeUpdated[SNOW_FINANCIAL_OPERATION_VALUE_FIELD.fieldApiName] = this.financialOperationValue;
            this.dataToBeUpdated[SNOW_ENDORSEMENT_VALUE_FIELD.fieldApiName] = this.endorsementValue;
            this.dataToBeUpdated[SNOW_PAYEE_NAME_FIELD.fieldApiName] = this.payeeName;
            this.dataToBeUpdated[SNOW_COMMENTS_FIELD.fieldApiName] = this.comments;
        }
        else if(this.isPerformWarranty){
            this.dataToBeUpdated[CPR_FIELD.fieldApiName] = this.cpr;
            this.dataToBeUpdated[MORTGAGE_FIELD.fieldApiName] = this.mortgage;
            this.dataToBeUpdated[SAP_CUSTOMER_NUMBER_FIELD.fieldApiName] = this.sapCustomerNumber;
            this.dataToBeUpdated[SNOW_COMMENTS_FIELD.fieldApiName] = this.comments;
        } 
        else if(this.isCustomerCreditAnalysis){
            this.dataToBeUpdated[CASE_CURRENCY_FIELD.fieldApiName] = this.caseCurrency;
            this.dataToBeUpdated[SAP_CUSTOMER_NUMBER_FIELD.fieldApiName] = this.sapCustomerNumber;
            this.dataToBeUpdated[SNOW_COMMENTS_FIELD.fieldApiName] = this.comments;
        }
        if(this.isCollectionsPortal)
        {
            this.updateContractNumber();
            this.dataToBeUpdated[SNOW_REQUEST_TYPE_FIELD.fieldApiName] = this.requestType;
            this.dataToBeUpdated[SNOW_SEGMENT_MANAGER_FIELD.fieldApiName] = this.segmentManager;
            this.dataToBeUpdated[SAP_CUSTOMER_NUMBER_FIELD.fieldApiName] = this.sapCustomerNumber;
            this.dataToBeUpdated[SNOW_EXACT_DATETOBE_PAID_FIELD.fieldApiName] = this.exactDateTobePaid;
            this.dataToBeUpdated[SNOW_COMMENTS_FIELD.fieldApiName] = this.comments;
        }
        if(this.isDebitOrCreditNotes)
        {    
            this.dataToBeUpdated[SNOW_REQUEST_TYPE_FIELD.fieldApiName] = this.requestType;
            this.dataToBeUpdated[SAP_CUSTOMER_NUMBER_FIELD.fieldApiName] = this.sapCustomerNumber;
            this.dataToBeUpdated[SNOW_BUSINESS_FIELD.fieldApiName] = this.businessValue;
            this.dataToBeUpdated[SNOW_EXACT_DATETOBE_PAID_FIELD.fieldApiName] = this.exactDateTobePaid;
            this.dataToBeUpdated[SNOW_REASON_FIELD.fieldApiName] = this.reasonValue;
            this.dataToBeUpdated[SNOW_PROGRAM_FIELD.fieldApiName] = this.programValue;
            this.dataToBeUpdated[SNOW_ABATEMENTCONTRACT_NUMBER_FIELD.fieldApiName] = this.abatementContractNumber;
            this.dataToBeUpdated[SNOW_COMMENTS_FIELD.fieldApiName] = this.comments;    
        }
        if(this.isUseofCreditsReturnReceiptofDischargeandReports)
        {
            this.dataToBeUpdated[SNOW_REQUEST_TYPE_FIELD.fieldApiName] = this.requestType;
            this.dataToBeUpdated[SNOW_INVOICE_FIELD.fieldApiName] = this.invoiceValue;
            this.dataToBeUpdated[SAP_CUSTOMER_NUMBER_FIELD.fieldApiName] = this.sapCustomerNumber;
            if(this.isDisplayOrderContractNumber) {
                this.dataToBeUpdated[SNOW_ORDER_OR_CONTRACT_NUMBER_FIELD.fieldApiName] = this.orderOrContactNumber;
            }
            this.dataToBeUpdated[INITIAL_DATE_FIELD.fieldApiName] = this.initialDate;
            this.dataToBeUpdated[FINAL_DATE_FIELD.fieldApiName] = this.finalDate;
            this.dataToBeUpdated[SNOW_COMMENTS_FIELD.fieldApiName] = this.comments;
        }
        
    }

    updateContractNumber() {
        if(this.contract != undefined && this.contract != null) {
            for(var i=0; i<this.contracts.length; i++) {
                 if(this.contracts[i].value == this.contract) {
                     this.dataToBeUpdated[SNOW_NEW_CONTRACT_FIELD.fieldApiName] = this.contracts[i].Id;
                 }
            }
        }
    }
    updateContractValue() {
        if(this.contract != undefined && this.contract != null) {
            for(var i=0; i<this.contractValues.length; i++) {
                 if(this.contractValues[i].value == this.contract) {
                     this.contractValue = this.contractValues[i].label;
                 }
            }
        }
    }

    getRealId(id) {
        const parts = (id || "").split("-");
        parts.pop();
        return parts.join("-");
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    scrollToItem(item) {
        setTimeout(() => {
            if(item && item.scrollIntoView) {
                item.scrollIntoView({
                    behavior: "smooth",
                    block: "center"
                });
            }
        });
    }
    createSNTicketCallout() {
        var objCase = {}
        objCase["callerID"] = this.federationIdentifier;
        objCase["u_incident_number"] = this.caseNumber;
        objCase["u_integration_id"] = this.recordId;
        console.log('Data from the mapvalues Array'+this.arraySNOW);

        var mapRequestType = this.arraySNOW;
        console.log('This is a new array ');

        console.log('Data from the mapvalues'+JSON.stringify(mapRequestType));
       

        if(this.selectedSolution == 'Debit or Credit Notes') {
            objCase["u_customer_sap_code"] = this.sapCustomerNumber;
            objCase["u_business"] = this.businessValue;
            objCase["u_due_date_payment"] = this.exactDateTobePaid;
            objCase["u_payment_effective_date"] = this.exactDateTobePaid;
            objCase["u_reason"] = this.reasonValue;
            objCase["u_program"] = this.programValue;
            objCase["u_abatement_contract"] = this.abatementContractNumber;
            if(mapRequestType[this.requestType] != undefined && mapRequestType[this.requestType] != null) {
                
                objCase["request_type"] = mapRequestType[this.requestType];
                objCase["u_request_type"] = this.requestType; 
            }
            else {
                objCase["request_type"] = this.requestType;
                objCase["u_request_type"] = this.requestType; 
            }

            if(this.reasonDetail != undefined && this.reasonDetail != '') {
                this.comments = 'Unity:'+this.unity+'\n Reason Detail:'+ this.reasonDetail +'\n '+this.comments;
            }
            else {
                this.comments = 'Unity:'+this.unity+'\n '+this.comments;
            }
        }
        else if(this.selectedSolution == 'Customer Credit Analysis')
        {
            objCase["u_cod_customer"] = this.sapCustomerNumber;
            this.comments = 'Currency used in this analysis is:'+this.caseCurrency +'\n'+this.comments;
           
        }
        else if(this.selectedSolution == 'Circularization Letters – Clients')
        {
            objCase["u_email_client_circularisation_letter"] = this.recipientOfCircularizationLetter;
            objCase["u_initial_date_circularisation_letter"] = this.initialRequestPeriod;
            objCase["u_company_mosaic"] = this.mosaicPayingReceivingCompany;
            this.comments = 'Customer SAP Code:'+ this.sapCustomerNumber+'\n '+this.comments;
            
        }
        else if(this.selectedSolution == 'Use of Credits, Return, Receipt of Discharge and Reports')
        {
            objCase["u_email_customer_receipt"] = this.contactEmail;
            objCase["u_order_number_contract_or_invoice"] = this.orderOrContactNumber;

            if(this.invoiceValue != undefined && this.invoiceValue != null) {
                for(var i=0; i<this.invoiceValues.length; i++) {
                     if(this.invoiceValues[i].value == this.invoiceValue) {
                         objCase["u_number_nf"] = this.invoiceValues[i].label;
                     }
                }
            }
            var strInitialDate = '';
            var strFinalDate = '';
            if(this.initialDate != undefined && this.initialDate != '') {
                strInitialDate = '\n Initial Date:'+ this.initialDate;
            }
            if(this.finalDate != undefined && this.finalDate != '') {
                var strFinalDate ='\n Final Date:'+ this.finalDate;
            }  
            
            this.comments = 'Request Type:'+ this.requestType+strInitialDate+strFinalDate+'\nCustomer SAP Code:'+ this.sapCustomerNumber+'\n '+this.comments;
            
        }
        else if(this.selectedSolution=='Release of Paid Contracts') {
            
            if(mapRequestType[this.requestType] != undefined && mapRequestType[this.requestType] != null) {
                objCase["u_request_type_paid_contracts"] = mapRequestType[this.requestType];
                objCase["u_request_type"] = this.requestType; 
            }
            else {
                objCase["u_request_type_paid_contracts"] = this.requestType;
                objCase["u_request_type"] = this.requestType; 
            } 
            this.comments = 'Customer SAP Code:'+ this.sapCustomerNumber+'\n Contract Number:'+this.contract +
                        '\n Contract Value:'+this.contractValue +'\n '+this.comments;    
            
    
        }
        else if(this.selectedSolution == 'Collections Portal')
        {
            objCase["u_payment_effective_date"] = this.exactDateTobePaid;
            objCase["u_client_name"] =  this.name;
            if(mapRequestType[this.requestType] != undefined && mapRequestType[this.requestType] != null) {
                objCase["request_type"] = mapRequestType[this.requestType];
                objCase["u_request_type"] = this.requestType; 
            }
            else {
                objCase["request_type"] = this.requestType;
                objCase["u_request_type"] = this.requestType; 
            }

            if(this.segmentManager != undefined && this.segmentManager != null) {
                for(var i=0; i<this.segmentManagers.length; i++) {
                     if(this.segmentManagers[i].value == this.segmentManager) {
                         objCase["u_segment_manager"] = this.segmentManagers[i].federationIdentifier;
                     }
                }
            }
            if(this.requestType == '3') {
                this.comments = 'Customer SAP Code:'+ this.sapCustomerNumber+'\n Contract Number:'+this.contract +
                        '\n Contract Value:'+this.contractValue +'\n '+this.comments;    
            }
        }
        else if(this.selectedSolution == 'Perform Warranty') {
            objCase["u_cod_customer"] = this.sapCustomerNumber;
            objCase["u_type_of_warranty_cpr"] = this.cpr;
            objCase["u_type_of_warranty_mortage"] = this.mortgage;
            
        }
        else if(this.selectedSolution == 'Warranty Formalization') {
            objCase["u_client_name"] =  this.name;
            objCase["u_cod_customer"] = this.sapCustomerNumber;
            objCase["u_warranty_type"] = this.warrantyType;
           //objCase["u_operation_value"] = this.caseCurrency +';'+this.financialOperationValue;
            objCase["u_financial_operation_value_new"] = this.financialOperationValue;

            objCase["u_payee_name"] = this.payeeName;
            objCase["u_endorsement_value"] = this.endorsementValue;
           
        }
        objCase["comments"] =this.comments;
        console.log('request JSON--> ' + JSON.stringify(objCase));
        createSNTicket({
            strSolutionType: this.selectedSolution,
            strRequestJson : JSON.stringify(objCase)
            }).then(result => {
                if(result != undefined && result != 'ERROR') {
                    result = result.replace("(", "{");
                    result = result.replace(")", "}");
                    result = result.replaceAll("\'", "\"");
                    var resultJSON = JSON.parse(result);
                    console.log('result-->'+JSON.stringify(result))
                    this.saveTickectDetails(resultJSON["ticket"],resultJSON["ticket_sys_id"],resultJSON["state_label"],resultJSON["state_value"]);
                }
                else {
    
                    this.isLoading = false;
                    this.showError(this.customLabels.PMC_SS_SNOW_ServiceNowTicketCreation_ErrorMessage,this.customLabels.PMC_SS_PleasetryAgain_MessageLabel);
                }
            })
            .catch(error => {
                console.log('Error --> ' + JSON.stringify(error.body));
                this.showError(this.customLabels.PMC_SS_SNOW_ServiceNowTicketCreation_ErrorMessage,error.body.message);
            });
    }
    
    saveTickectDetails(tickectNumber,tickectSyncID,ticketStatus,ticketValue ) {
            var objCaseToUpdate = {};
            objCaseToUpdate[ID_FIELD.fieldApiName] = this.recordId;
            objCaseToUpdate[SNOW_TICKET_NUMBER.fieldApiName] = tickectNumber;
            objCaseToUpdate[SNOW_TICKET_SYNC_ID.fieldApiName] = tickectSyncID;
            objCaseToUpdate[SNOW_TICKET_STATUS.fieldApiName] = ticketStatus;
            objCaseToUpdate[SNOW_TICKET_STATUS_VALUE.fieldApiName] = ticketValue;
            const recordInput = {
                fields: objCaseToUpdate
            };
            updateRecord(recordInput).then(result => {

                if(result != undefined) {
                    this.isLoading = false;
                    this.showSuccessToast(this.customLabels.PMC_SS_Success_MessageLabel, this.customLabels.PMC_SS_SNOW_ServicenowTicketCreation_SuccessMessage +tickectNumber);
                    this.closeAction();
                }
                else {
                    this.showError(this.customLabelsPMC_SS_FailedtoUpdateRecord_ErrorMessage,this.customLabels.PMC_SS_PleasetryAgain_MessageLabel);
                }
            })
            .catch(error => {
                console.log('Error --> ' + JSON.stringify(error.body));
                this.showError(this.customLabelsPMC_SS_FailedtoUpdateRecord_ErrorMessage,error.body.message);
            });
    }
    
    showSuccessToast(tittleMessage, strMessage) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: tittleMessage,
                message: strMessage,
                variant: "success",
            }),
        );
    }

    showError (tittleMessage, strMessage) {
        this.isLoading = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: tittleMessage,
                message: strMessage,
                variant: "error",
            }),
        );
    }
}