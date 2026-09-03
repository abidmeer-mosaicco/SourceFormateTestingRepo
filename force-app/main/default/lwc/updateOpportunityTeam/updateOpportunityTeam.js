import { LightningElement, api, wire } from 'lwc';
import canReplicateForUser
    from '@salesforce/apex/OppTeamReplicationGate.canReplicateForUser';
    
import canCurrentUserReplicate 
    from '@salesforce/apex/OppTeamReplicationGate.canCurrentUserReplicate';


export default class UpdateOpportunityTeam extends LightningElement {
    @api recordId;

    hasAccess = false;
    loaded = false;
    showModal = false; // ✅ MISSING
    error;

   
@wire(canCurrentUserReplicate)
accessWire({ data }) {
    this.hasAccess = data === true;
    this.loaded = true;
}

    get showButton() {
       return this.loaded && this.hasAccess;
     
    }

   
    openModal() {
        this.showModal = true;
    }

    
    closeModal() {
        this.showModal = false;
    }
}