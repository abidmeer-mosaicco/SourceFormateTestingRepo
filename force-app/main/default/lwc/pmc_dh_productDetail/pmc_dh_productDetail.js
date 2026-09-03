import { LightningElement,track, api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord,updateRecord,getRecordNotifyChange } from 'lightning/uiRecordApi';
import updateProdutDetails from "@salesforce/apex/PMC_DH_ProductManagementClass.updateProdutDetails";
export default class Pmc_dh_productDetail extends LightningElement {
    @api recordId;
    @track isSpinner = false;
   
    handleSubmit(event) {
       this.isSpinner = true;
        event.preventDefault();
        let fieldData = event.detail.fields;
        let prodObject = {
            strProductId : this.recordId,
            strProductClassification : fieldData.PMC_CPQ_ProductClassification__c,
            strCropType : fieldData.PMC_CPQ_CropType__c,
            strGranuleType : fieldData.PMC_CPQ_GranularType__c,
            strBusinessApplication : fieldData.PMC_CPQ_BusinessApplication__c,
            strMicronutrient : fieldData.PMC_DH_Micronutrients__c
        }

        updateProdutDetails({
            objProDataWrapper : prodObject,
          }).then(result => {
            this.isSpinner=false;
            if (result.strStatusCode === '000') {
              getRecordNotifyChange([{recordId : this.recordId}]);
              this.fireToastEvent('Success!!', 'Record Updated Successfully','success');
            }else{
              this.fireToastEvent('Error!!', 'Error In Product Update','error');
            }
            console.log('result', result);
           
          }).catch(error => {
            this.isSpinner=false;
            console.error('Error', error);
          })
    }
    fireToastEvent(title, message, varient){
        const toastEvent = new ShowToastEvent({
            title: 'Success!!',
            message: 'Record Updated Successfully',
            variant : 'success'
        });
        this.dispatchEvent(toastEvent);
    }
}