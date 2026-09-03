import { LightningElement,wire,track } from "lwc";


import scheduleOrderNonProdEndpoint from '@salesforce/label/c.PMC_SS_ScheduleOrder_NonProd';
import scheduleOrderProdEndpoint from '@salesforce/label/c.PMC_SS_ScheduleOrder_Prod';

import boolIsSandbox from '@salesforce/apex/PMC_SS_ScheduleOrderController.checkSandbox';

import { NavigationMixin } from "lightning/navigation";



export default class Navigation extends NavigationMixin(LightningElement) {
  @track strUrl;
  @wire(boolIsSandbox) boolCheckSandbox ;
  
  // Used to handle navigation to URL//
  handleNavigate() {
    boolIsSandbox().then(boolResult => {
      // If org is Sandbox//
      if(boolResult==true){
        this.strUrl = scheduleOrderNonProdEndpoint ;
      }

      // If org is Prod//
      else{
        this.strUrl = scheduleOrderProdEndpoint ;
      }
      const objNavigationConfig = {
        type: 'standard__webPage',
        attributes: {
            url: this.strUrl
        }
	};
    this[NavigationMixin.Navigate](objNavigationConfig);

    }).catch();
    
  }
}