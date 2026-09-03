public class PMC_SS_Case_AA_EmailTemplate_ctrl {
	
    public Id caseId {get;set;}
    public Id approvalId {get;set;}
    
    public PMC_SS_Case_AA_EmailTemplate_ctrl() {}
    
    public Case getcaseRecord(){
        System.Debug('caseRecord PRT1**: '+this.caseId);
        if (this.caseId != null) {
			return [SELECT Id, CaseNumber, Subject, Description,
                          Account.Name,
                          PMC_SS_AtFaultParty__c,
                          PMC_SS_Location__r.Name,
                          PMC_SS_OriginalInvoiceAmount__c,
                          PMC_SS_RebillAmount__c,
                          PMC_SS_InvoiceDifference__c,
                          PMC_SS_MOT__c,
                          CreatedBy.Name
                          FROM Case
                          WHERE Id = :this.caseId
                          LIMIT 1];
        }
        
        return null;
    }
    
    public sbaa__Approval__c getapprovalRecord(){
        if(approvalId != null){
            return [SELECT Id,Name,Owner.Name,LastModifiedDate,sbaa__RejectedBy__r.Name,sbaa__CommentsLong__c,sbaa__Approver__r.Name,sbaa__AssignedTo__r.Name,sbaa__Approver__r.LastModifiedDate,CreatedBy.name FROM sbaa__Approval__c WHERE Id=:this.approvalId];
        }
        return null;
    }
    
    public String getcaseLink() {
        return URL.getOrgDomainURL().toExternalForm() + '/' + this.caseId;
    }
    
    public String getapprovalLink() {
        return URL.getOrgDomainURL().toExternalForm() + '/' + this.approvalId;
    }
   public String getFormattedRebillAmount() {
   return (getcaseRecord()?.PMC_SS_RebillAmount__c != null)
       ? String.valueOf(getcaseRecord().PMC_SS_RebillAmount__c.setScale(2, RoundingMode.HALF_UP)): '';
   }
public String getFormattedOriginalInvoiceAmount() {
   return (getcaseRecord()?.PMC_SS_OriginalInvoiceAmount__c != null)
       ? String.valueOf(getcaseRecord().PMC_SS_OriginalInvoiceAmount__c.setScale(2, RoundingMode.HALF_UP)): '';
}
public String getFormattedInvoiceDifference() {
   return (getcaseRecord()?.PMC_SS_InvoiceDifference__c != null)
       ? String.valueOf(getcaseRecord().PMC_SS_InvoiceDifference__c.setScale(2, RoundingMode.HALF_UP)): '';
}
}