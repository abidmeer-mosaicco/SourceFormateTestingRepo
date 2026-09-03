/**
* @description This class acts as a helper for the PMC_SS_CloneOpportunityRecordClass.
* @author Isha Gupta
*/
public with sharing class PMC_SS_CloneOpportunityRecordHelperClass {
    
    @testVisible
    public static boolean boolTest = false;
    
    
    /** @description This method is used to clone the Opportunity Contact Roles.
* @param objOpportunity - selected Opportunity record.
* @param objClonedOpportunity - cloned Opportunity object created in method cloneOpportunityDetails.
* @return This method returns a boolean that used to check for successfull cloning of Opportunity Contact Role.
*/  
    public static Boolean cloneOpportunityContact(Opportunity objOpportunity, Opportunity objClonedOpportunity){
        Boolean boolCheck = true;
        OpportunityContactRole objClonedContactRole;
        List<OpportunityContactRole> lstClonedContactRole = new List<OpportunityContactRole>();
        List<OpportunityContactRole> lstContactRole = [SELECT ContactId, OpportunityId, IsPrimary, Role
                                                       FROM OpportunityContactRole 
                                                       WHERE OpportunityId = :objOpportunity.Id WITH SECURITY_ENFORCED];
        
        if(lstContactRole.size()>0){
            for(OpportunityContactRole objContactRole: lstContactRole ) {
                //clone Opportunity Contact Roles with deep clone attribute as true.
                objClonedContactRole = objContactRole.clone(false,true,false,false);
                objClonedContactRole.OpportunityId = objClonedOpportunity.Id;
                lstClonedContactRole.add(objClonedContactRole);
            }
            Database.SaveResult[] srList = Database.insert(lstClonedContactRole, false);
            for (Database.SaveResult sr : srList) {  
                if (!sr.isSuccess() || boolTest) {
                    boolCheck = false;
                    break;
                } 
            }
        }
        return boolCheck;
        
    }
    
    /** @description This method is used to clone the Opportunity Team Members.
* @param objOpportunity - selected Opportunity record.
* @param objClonedOpportunity - cloned Opportunity object created in method cloneOpportunityDetails.
* @return This method returns a boolean that used to check for successfull cloning of Opportunity Team Member.
*/     
    public static Boolean cloneOpportunityTeamMember(Opportunity objOpportunity, Opportunity objClonedOpportunity){
        Boolean boolCheck=true;
        OpportunityTeamMember objClonedTeamMember;
        List<OpportunityTeamMember> lstClonedTeamMember = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> lstTeamMember = [SELECT CreatedById, LastModifiedById, OpportunityId, OpportunityAccessLevel, TeamMemberRole, UserId 
                                                     FROM OpportunityTeamMember 
                                                     WHERE OpportunityId = :objOpportunity.Id WITH SECURITY_ENFORCED];
        if(lstTeamMember.size()>0){
            for(OpportunityTeamMember objTeamMember : lstTeamMember) {
                //clone Opportunity Team Members with deep clone attribute as true.
                objClonedTeamMember = objTeamMember.clone(false, true, false, false);
                objClonedTeamMember.OpportunityId = objClonedOpportunity.Id;
                lstClonedTeamMember.add(objClonedTeamMember);
            }
            Database.SaveResult[] srList = Database.insert(lstClonedTeamMember,false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess() || boolTest) {
                    boolCheck = false;
                    break;
                }
            }
        }
        return boolCheck;
    }
    
    /** @description This method is used to clone the Opportunity Product
* @param objOpportunity - selected Opportunity record.
* @param objClonedOpportunity - cloned Opportunity object created in method cloneOpportunityDetails.
* @return This method returns a boolean that used to check for successfull cloning of Opportunity Line Item.
*/     
    public static Boolean cloneOpportunityLineItem(Opportunity objOpportunity, Opportunity objClonedOpportunity){
        Boolean boolCheck=true;
        OpportunityLineItem objClonedProducts;
        List<OpportunityLineItem> lstClonedProducts = new List<OpportunityLineItem>();
        List<OpportunityLineItem> lstProducts = [SELECT  sbaa__ApprovalStatus__c,ServiceDate, UnitPrice, Discount,  Description, ListPrice, OpportunityId, Name, SBQQ__ParentID__c, Product2Id, ProductCode, Quantity, SBQQ__QuoteLine__c, SBQQ__SubscriptionType__c, Subtotal, PricebookEntryId 
                                                 FROM OpportunityLineItem 
                                                 WHERE OpportunityId = :objOpportunity.Id WITH SECURITY_ENFORCED];
        if(lstProducts.size()>0){
            for(OpportunityLineItem objProducts: lstProducts) {
                //clone Opportunity Line Items with deep clone attribute as true.
                objClonedProducts = objProducts.clone(false, true, false, false);
                objClonedProducts.OpportunityId = objClonedOpportunity.Id;
                lstClonedProducts.add(objClonedProducts);
            }
            Database.SaveResult[] srList = Database.insert(lstClonedProducts, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess() || boolTest) {
                    boolCheck = false;
                    break;
                }
            }
        }
        return boolCheck;
    }
    
    /** @description This method is used to clone the Contracts.
* @param objOpportunity - selected Opportunity record.
* @param objClonedOpportunity - cloned Opportunity object created in method cloneOpportunityDetails.
* @return This method returns a boolean that used to check for successfull cloning of Contracts.
*/     
    public static Boolean cloneContracts(Opportunity objOpportunity, Opportunity objClonedOpportunity){
        boolean boolCheck=true;
        Contract objClonedContract;
        List<Contract> lstClonedContracts = new List<Contract>();
        List<Contract> lstContracts = [SELECT AccountId, PMC_CPQ_Contract_Blocked__c,ActivatedById, ActivatedDate,SBQQ__ActiveContract__c, SBQQ__AmendmentRenewalBehavior__c, SBQQ__AmendmentOpportunityRecordTypeId__c, SBQQ__AmendmentOpportunityStage__c, SBQQ__AmendmentOwner__c, 
                                       SBQQ__AmendmentPricebookId__c, SBQQ__AmendmentStartDate__c, BillingAddress, SBQQ__SubscriptionQuantitiesCombined__c, CompanySignedId, CompanySignedDate, CurrencyIsoCode, EndDate, Name, ContractNumber, OwnerId, 
                                       StartDate, ContractTerm, CreatedById, CustomerSignedId, CustomerSignedDate, CustomerSignedTitle, SBQQ__DefaultRenewalContactRoles__c, SBQQ__DefaultRenewalPartners__c, Description, SBQQ__DisableAmendmentCoTerm__c, 
                                       SBQQ__Evergreen__c, SBQQ__ExpirationDate__c, LastModifiedById, SBQQ__MasterContract__c, SBQQ__MDQRenewalBehavior__c, SBQQ__Opportunity__c, SBQQ__OpportunityPricebookId__c, SBQQ__Order__c,OwnerExpirationNotice, 
                                       SBQQ__PreserveBundleStructureUponRenewals__c, Pricebook2Id, SBQQ__Quote__c, SBQQ__RenewalForecast__c, SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunityRecordTypeId__c, SBQQ__RenewalOpportunityStage__c, 
                                       SBQQ__RenewalOwner__c, SBQQ__RenewalPricebookId__c, SBQQ__RenewalQuoted__c, SBQQ__RenewalTerm__c, SBQQ__RenewalUpliftRate__c, SalesAgreementId, ShippingAddress, SpecialTerms, Status 
                                       FROM Contract 
                                       WHERE SBQQ__Opportunity__c = :objOpportunity.Id WITH SECURITY_ENFORCED];        
        if(lstContracts.size()>0){
            for(Contract objContract: lstContracts) {
                //clone Contracts with deep clone attribute as true.
                objClonedContract = objContract.clone(false, true, false, false);
                objClonedContract.SBQQ__Opportunity__c = objClonedOpportunity.Id;
                lstClonedContracts.add(objClonedContract);
            }
            Database.SaveResult[] srList = Database.insert(lstClonedContracts, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess() || boolTest) {
                    boolCheck = false;
                    break;
                }
            }
        }
        return boolCheck;
    }
    
    /** @description This method is used to clone the Quotes.
* @param objOpportunity - selected Opportunity record.
* @param objClonedOpportunity - cloned Opportunity object created in method cloneOpportunityDetails.
* @return This method returns a boolean that used to check for successfull cloning of Quotes.
*/     
    public static Boolean cloneQuotes(Opportunity objOpportunity, Opportunity objClonedOpportunity){
        boolean boolCheck=true;
        Quote objClonedQuote ;
        List<Quote> lstClonedQuotes = new List<Quote>();
        List<Quote> lstQuotes = [SELECT AccountId, AdditionalAddress, AdditionalName, BillingAddress, BillingName, ContactId, ContractId, CreatedById, Description, Discount, Email, ExpirationDate, Fax, GrandTotal, LastModifiedById, LineItemCount, OpportunityId, 
                                 OwnerId, Phone, CurrencyIsoCode, Name, QuoteNumber, QuoteToAddress, QuoteToName, ShippingAddress, ShippingName, ShippingHandling, Status, Subtotal, IsSyncing, Tax, TotalPrice 
                                 FROM Quote 
                                 WHERE OpportunityId = :objOpportunity.Id WITH SECURITY_ENFORCED];
        if (lstQuotes.size()>0){
            for(Quote objQuote: lstQuotes) {
                //clone Quotes with deep clone attribute as true.
                objClonedQuote = objQuote.clone(false, true, false, false);
                objClonedQuote.OpportunityId = objClonedOpportunity.Id;
                lstClonedQuotes.add(objClonedQuote);
            }
            Database.SaveResult[] srList = Database.insert(lstClonedQuotes, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess() || boolTest) {
                    boolCheck = false;
                    break;
                }
            }
        }
        return boolCheck;  
    }
    
}