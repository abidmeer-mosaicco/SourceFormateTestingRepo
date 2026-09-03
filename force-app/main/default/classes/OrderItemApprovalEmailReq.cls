/**
* @description This class will be used to fetch the data from the org to be used in Email Template.
* @author Azmir Ali
* @storynumber GCPM-2397 
*/
public with sharing class OrderItemApprovalEmailReq {
    
    private SBQQ__Quote__c quoteInfo;

/**
* @description orderitemId -to store the quoteid rendering from the email template 
*/
    public string quoteId {get;set;}

/**
* @description PMC_CPQ_EmailControllerWrapperClass -Wrapper class of this main class to store all the getters and setters
*/  
    public PMC_CPQ_EmailControllerWrapperClass wrapper{get;set;}
   
/**
* @description This method is the constructor of this class
*/
  
	public OrderItemApprovalEmailReq (){
          wrapper = new PMC_CPQ_EmailControllerWrapperClass ();
    }

/**
* @description This method is used to Query only the Quote which is related to the Quote Line id passed
* @description qLines -  to store the Quote Line 
* @return qLines 
*/
 
     public List<SBQQ__QuoteLine__c> qLines{
        get{
            if(quoteId!=null){ 
              qLines= [SELECT id,SBQQ__Quote__c,SBQQ__ProductName__c, PMC_CPQ_CustomerPrice__c,PMC_CPQ_ContractType__c,PMC_CPQ_FinalPricePerTonne__c,PMC_CPQ_PriceGuidanceTarget__c,PMC_CPQ_PriceGuidanceFloor__c,
                       PMC_CPQ_PriceBookValue__c,PMC_CPQ_PaymentTerms__c,PMC_CPQ_Incoterms1__c,PMC_CPQ_PaymentDate__c,PMC_CPQ_VolumeDiscount__c,PMC_CPQ_Discount__c,PMC_CPQ_ExspaceIndicator__c,PMC_CPQ_GeneralComments__c,PMC_CPQ_ReplacementMargin__c
                       from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteId WITH SECURITY_ENFORCED]; 
            }
            return qLines;            
        }set;
    }
      public SBQQ__Quote__c getQuoteInfo(){
        if (quoteInfo == NULL && quoteId != NULL) {
                quoteInfo = [SELECT id,Name,PMC_CPQ_ExpiresOn__c, PMC_CPQ_ExpirationDate__c,PMC_CPQ_ExpirationTime__c,SBQQ__PaymentTerms__c,PMC_CPQ_QuoteShortNameDescription__c,CurrencyIsoCode,PMC_CPQ_ContractEnd__c,CreatedDate,PMC_CPQ_AccountCountry__c,SBQQ__Account__r.Name,                        
                             PMC_AdditionalComments__c from SBQQ__Quote__c where ID  =:quoteId WITH SECURITY_ENFORCED];
            }
        return quoteInfo;
    } 
          
}