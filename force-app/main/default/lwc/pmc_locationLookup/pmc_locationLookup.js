import { LightningElement, track } from 'lwc';
import searchLocations from '@salesforce/apex/LocationLookupController.searchLocations';
export default class CustomLocationLookup extends LightningElement {
   @track searchKey = '';
   @track locations = [];
   @track showDropdown = false;
   get comboboxClass() {
       return this.showDropdown
           ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open'
           : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
   }
   // Handle typing
   handleKeyChange(event) {
       this.searchKey = event.target.value;
       this.fetchLocations();
   }
   // Handle clicking the search icon
   handleIconClick() {
       this.fetchLocations();
   }
   fetchLocations() {
       searchLocations({ searchKey: this.searchKey })
           .then(result => {
               this.locations = result;
               this.showDropdown = result.length > 0;
           })
           .catch(error => {
               console.error('Error fetching locations', error);
               this.locations = [];
               this.showDropdown = false;
           });
   }
   // Handle selecting a record
   handleSelect(event) {
       let recordId = event.currentTarget.dataset.id;
       let recordName = event.currentTarget.dataset.name;
       this.searchKey = recordName;
       this.showDropdown = false;
       // fire custom event to parent 
       this.dispatchEvent(new CustomEvent('locationselected', {
           detail: { locationId: recordId, locationName: recordName }
       }));
   }
}