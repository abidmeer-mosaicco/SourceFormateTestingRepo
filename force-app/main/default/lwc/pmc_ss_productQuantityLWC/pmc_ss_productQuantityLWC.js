import { LightningElement, wire, track ,api} from 'lwc';
import {
    FlowNavigationNextEvent
  } from "lightning/flowSupport";
export default class pmc_ss_productQuantityLWC extends LightningElement {
@api lstRecords = [];
@api lstValue=[];
lstSaveDraftValues = [];
@api fieldColumns = [
{ label: 'Name', fieldName: 'Name' },
{ label: 'Quantity',fieldName:'Quantity',editable: true, type : 'integer'}
];
@track boolShowError = false;
@track boolShowNext = true;

handleSave(event) {
    this.lstSaveDraftValues=[];
    this.boolShowError = false;
    this.boolShowNext = true;
    this.lstSaveDraftValues = event.detail.draftValues;
    this.lstValue=[];
  

    for(let i=0;i<this.lstSaveDraftValues.length;i++){
        this.boolShowNext = true;
      //Show error for blank values//
       if(this.lstSaveDraftValues.length < this.lstRecords.length){
            this.boolShowError = true;
            break;
        }
        //Show error for non numeric values or values less than equal to 0//
        let quantityFormat = /[0-9]+/;
            if(!quantityFormat.test(this.lstSaveDraftValues[i].Quantity) || this.lstSaveDraftValues[i].Quantity<=0){
            this.boolShowError = true;
            break;
        }
        
        this.lstValue.push(this.lstSaveDraftValues[i].Quantity);

        //Enable Next button if no error//
        if(this.boolShowError == true){
            this.boolShowNext = true;
        }
        else{
            this.boolShowNext = false;
        }
        
    }
    
    
}

handleChange(event){
  if(event.detail.draftValues.Quantity===undefined){
    this.boolShowNext=true;
  }

}

handleCancel(){
  this.boolShowNext = true;
  this.boolShowError = false;
}


  handleNext() { 
      const navigateNextEvent = new FlowNavigationNextEvent();
      this.dispatchEvent(navigateNextEvent);
  }
}