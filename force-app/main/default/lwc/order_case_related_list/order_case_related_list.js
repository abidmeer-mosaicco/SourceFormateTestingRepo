import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getRelatedCases from '@salesforce/apex/OrderCasesController.getRelatedCases';
import getOrderDetails from '@salesforce/apex/OrderCasesController.getOrderDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    {
  label: 'Case Number',
  fieldName: 'caseLink',
  type: 'url',
  hideDefaultActions: true,
  typeAttributes: {
    label: { fieldName: 'CaseNumber' },
    target: '_blank'
  }
},
    { label: 'Status', fieldName: 'Status', type: 'text', hideDefaultActions: true },
    { label: 'Type', fieldName: 'Type', type: 'text', hideDefaultActions: true },
    { label: 'Contact Name', fieldName: 'ContactName', type: 'text', hideDefaultActions: true },
    { label: 'At Fault Party', fieldName: 'PMC_SS_AtFaultParty__c', type: 'text', hideDefaultActions: true },
    { label: 'Date/Time Opened', fieldName: 'CreatedDate', type: 'date', typeAttributes: {
        year: "numeric",
        month: "short",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit"
    }, hideDefaultActions: true }
];

const columnsOrderItem = [
    {
      label: "Order Product",
      fieldName: "proName",
      type: "text",
      dataType: "alphanumeric",
      sortable: true,
      defaultSortDirection: "asc",
      isAscSort: true
    },
   
    {
      label: "Confirmed Quantity",
      fieldName: "PMC_CPQ_ConfirmedQuantity__c",
      type: "text",
      dataType: "alphanumeric",
      sortable: true,
      defaultSortDirection: "asc",
      isAscSort: true
    },
    {
        label: "UoM",
        fieldName: "PMC_CPQ_UnitOfMeasure__c",
        type: "text",
        dataType: "alphanumeric",
        sortable: true,
        defaultSortDirection: "asc",
        isAscSort: true
      },
    {
      label: "MoT",
      fieldName: "PMC_CPQ_ModeofTransportation__c",
      type: "text",
      dataType: "alphanumeric",
      sortable: true,
      defaultSortDirection: "asc",
      isAscSort: true
    },
    {
        label: "Ship To",
        fieldName: "shipName",
        type: "text",
        dataType: "alphanumeric",
        sortable: true,
        defaultSortDirection: "asc",
        isAscSort: true
      }
  ];
  

export default class OrderCasesRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @track displayedCases;
    @track allCases;
    @track columns = COLUMNS;
    @track columnsOrder=columnsOrderItem;
    @track isLoading = true;
    @track showViewAll = false;
    @track showNewCaseModal = false;
    @track orderDetails;
    @track orderItemsData;
    @track isSubmitting = false;
    wiredCasesResult;

    @wire(getRelatedCases, { orderId: '$recordId' })
wiredCases(result) {
    this.wiredCasesResult = result;
    if (result.data) {
        // Clone each record and add the caseLink property
        const updatedCases = result.data.map(record => ({
            ...record,
            caseLink: '/' + record.Id
        }));
        this.allCases = updatedCases;
        this.displayedCases = updatedCases.length > 5 ? updatedCases.slice(0, 5) : updatedCases;
        this.showViewAll = updatedCases.length > 5;
        this.isLoading = false;
    } else if (result.error) {
        this.showToast('Error', 'Error fetching cases', 'error');
        this.isLoading = false;
    }
}


    @wire(getOrderDetails, { orderId: '$recordId' })
    wiredOrderDetails({ error, data }) {
        if (data) {
            this.orderDetails = data;
            const dataItem=data;
         
            const updatedItem = dataItem?.OrderItemRecords?.map(record => ({
               ...record,
               proName: record?.Product2?.Name,
               shipName:record?.PMC_CPQ_ShipTo__r?.Name
           }));
          
         this.orderItemsData=updatedItem;
           this.orderDetails = data;
           console.log('this.orderItemsData',this.orderItemsData);
          
           this.selectedRows=data?.OrderRecord;
           console.log('this.selectedRows',this.selectedRows);


            console.log('Data-->' + JSON.stringify(data));
            
        } else if (error) {
            this.showToast('Error', 'Error fetching order details', 'error');
        }
    }

    handleNewCase() {
        this.showNewCaseModal = true;
    }

    handleCloseModal() {
        this.showNewCaseModal = false;
    }
 //GSMD-3234
 handleRowSelection(event) {
    this.selectedRows = event.detail.selectedRows;
    console.log('Selected Rows:', this.selectedRows);
    this.selectedRows = this.orderItemsData.find((el) => el.Id === this.selectedRows[0].Id);
 
}
     handleSubmit(event) {
        event.preventDefault();
        
        const fields = event.detail.fields;
        let missingfields = [];

        if(!fields.Type){
            missingfields.push('Type');
        }
        if(!fields.Origin){
            missingfields.push('Origin');
        }
        if(this.orderDetails.Is_MultipleOrdereItem )
            {
             if(!this.selectedRows)
             {
                 missingfields.push('Invoice Item');
             }
             
            }
        if(missingfields.length > 0){
            const errorMsg = 'Please enter: ' + missingfields.join(', ');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Required Fields',
                    message: errorMsg,
                    variant: 'error'
                })
            );
        }else{
        this.isSubmitting = true;
        fields.PMC_SS_SoldToAccount__c =  this.orderDetails.PMC_SS_SoldToAccount__c;
        fields.PMC_SS_SAPOrderNumber__c =  this.orderDetails.PMC_SS_SAPOrderNumber__c;
        fields.PMC_SS_SNOW_OrderNumberorContractNumber__c =  this.orderDetails.PMC_SS_SNOW_OrderNumberorContractNumber__c;
        fields.PMC_SS_Order__c = this.recordId;
        fields.Customer_Purchase_Order__c =  this.orderDetails.Customer_Purchase_Order__c;
        //gsmd-3234
        fields.PMC_SS_MOT__c=this.selectedRows.PMC_CPQ_ModeofTransportation__c;
        fields.PMC_SS_ShipToAccount__c=this.selectedRows.PMC_CPQ_ShipTo__c;
        fields.PMC_SS_UOM__c=this.selectedRows.PMC_CPQ_UnitOfMeasure__c;
        fields.PMC_SS_OrderProduct__c=this.selectedRows.Id;
           
        

        this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
    }

 handleSuccess(event) {
        const newCaseId = event.detail.id;
        // Refresh the list to ensure the new case is included
        refreshApex(this.wiredCasesResult).then(() => {
            // Locate the new case to use its CaseNumber as the clickable label
            const newCase = this.allCases.find(rec => rec.Id === newCaseId);
            const labelName = newCase && newCase.CaseNumber ? newCase.CaseNumber : 'View Case';
            const viewUrl = '/' + newCaseId;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success!',
                    message: 'Case created successfully. {0}',
                    messageData: [{
                        url: viewUrl,
                        label: labelName
                    }],
                    variant: 'success'
                })
            );
            this.isSubmitting = false; // stop the spinner
            this.showNewCaseModal = false;
        });
    }


    handleViewAll() {
        console.log('I got triggered!')
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Order',
                relationshipApiName: 'Cases__r',
                actionName: 'view'
            }
        });
    }
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}