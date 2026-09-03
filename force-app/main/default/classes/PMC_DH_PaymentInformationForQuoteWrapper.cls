/**
* @description : Wrapper class for PMC_DH_RequestForQuoteController.getPaymentInfoForQuote()
* @author      : Nikhilesh Mohanty
* @userStory   : GDASF-63, GDASF-106
* @last modified on 06-01-2023
* @last modified by @Nikhilesh
**/
public class PMC_DH_PaymentInformationForQuoteWrapper {
    /**
 * @description Id of Cart
 * @author @Nikhilesh 
 * 
**/
    @AuraEnabled
    public String strCartId{get;set;}

    /**
 * @description Contract Start Date of Cart
 * @author @Nikhilesh 
 * 
**/
    @AuraEnabled
    public Date datContractStartDate {get;set;}

    /**
 * @description Contract End Date of Cart
 * @author @Nikhilesh 
 * 
**/
    @AuraEnabled
    public Date datContractEndDate{get;set;}

    /**
 * @description List for value label picklist
 * @return 		String
**/
    @AuraEnabled
    public String strCurrencyIsoCode{get;set;}

    /**
 * @description List for value label picklist
 * @return 		String
**/
    @AuraEnabled
    public String strPaymentTerms{get;set;}

    /**
 * @description List for value label picklist
 * @return 		String
**/
    @AuraEnabled
    public String strPaymentMethods{get;set;}
    /**
* @description List of Product Families
* @return 		List<String>
*/
        @AuraEnabled
        public List<String> lstProductFamilies{get;set;} 
        /**
 * @description Prepayment Date of Cart
 * @author @kreddylakshmi 
**/
        @AuraEnabled
        public Date datPrepaymentDate{get;set;} //added as part of GDASF-19809
}