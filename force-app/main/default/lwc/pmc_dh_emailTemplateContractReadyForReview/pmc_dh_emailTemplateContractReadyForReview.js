import { LightningElement } from 'lwc';

export default class Pmc_dh_emailTemplateContractReadyForReview extends LightningElement {
  startTripleParantheses = "{{{";
  endTripleParantheses = "}}}";

  copyPasteLlink = "{labels.pmc_emailTemplate_contractReadyLink}" + this.startTripleParantheses + "SBQQ__Quote__c.Id" + this.endTripleParantheses;
  contractNumber = this.startTripleParantheses + "SBQQ__Quote__c.PMC_CPQ_Document_ID__c" + this.endTripleParantheses;
  contractType = this.startTripleParantheses + "SBQQ__Quote__c.PMC_CPQ_ContractType__c" + this.endTripleParantheses;
  companyName = this.startTripleParantheses + "SBQQ__Quote__c.SBQQ__Account__c" + this.endTripleParantheses;
}