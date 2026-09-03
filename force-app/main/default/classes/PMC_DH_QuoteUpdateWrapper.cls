/**
* @description       : Wrapper for Quote Update
* @author            : @Krishan Jangir
* @group             : 
* @last modified on  : 06-06-2023
* @last modified by  : @Krishan Jangir
**/
public class PMC_DH_QuoteUpdateWrapper {
    /**
* @description Id of Quote

* @return String

*/
    @Auraenabled // fixed @digitalhubcodereview
    public String strQuoteId{get;set;}
    
    
    
    
    /**

* @description Contract Start Date of Cart

* @return Date

*

**/
    
    @AuraEnabled
    
    public String datContractStartDate {get;set;}
    
    /**

* @description Prepayment date of Cart

* @return Date

*

**/
    
@AuraEnabled
    
public Date datPrepaymentDate {get;set;}//added as part of GDASF-19809
    
    
    /**

* @description Contract End Date of Cart

* @return Date

*

**/
    
    @AuraEnabled
    
    public String datContractEndDate{get;set;}
    
    
    
    /**

* @description currency code

* @return       String

**/
    
    @AuraEnabled
    
    public String strCurrencyIsoCode{get;set;}
    
    
    
    /**

* @description payment terms

* @return       String

**/
    
    @AuraEnabled
    
    public String strPaymentTerms{get;set;}
    
    
    
    /**

* @description payment method

* @return       String

**/
    
    @AuraEnabled
    
    public String strPaymentMethods{get;set;}
    
    /**

* @description Friendly name

* @return       String

**/
    @AuraEnabled
    public String strFriendlyName{get;set;}
    
}