/**
* @description This class will be used to fetch the data from the org to be used in Email Template.
* @author Jeyanthi Muthaiah
* @storynumber GDASF-3258 
*/
public with sharing class PMC_CPQ_ApprovalRequestEmailTempClass {
    
    /** 
* @description blendedProductsList -to store the Quotelines which have blended products
* @description hasCalculatedRawMaterialSums -to know that the CalculatedRawMaterialSums is called before or not
* @description rawMaterialListCFRSum -to store the Sum of ListCFR Tons of Same Raw Materilas which have same Product SKU 
* @description rawMaterialSoldCFRSum -to store the Sum of SoldCFR of Same Raw Materilas which have same Product SKU
*/
    private SBQQ__Quote__c quoteInfo;
    private Boolean hasCalculatedRawMaterialSums= false;
    private Map<String, Decimal> rawMaterialListCFRSum ;
    private Map<String, Decimal> rawMaterialSoldCFRSum ;
    public List<SBQQ__QuoteLine__c> blendedProducts{get;set;}
   
    /**
* @description quoteId -to store the quoteid rendering from the email template 
*/
    public string quoteId {get;set;}

    /**
* @description PMC_CPQ_EmailControllerWrapperClass -Wrapper class of this main class to store all the getters and setters
*/  
    public PMC_CPQ_EmailControllerWrapperClass wrapper{get;set;}
    
    
    /**
* @description This method is the constructor of this class
*/
    public PMC_CPQ_ApprovalRequestEmailTempClass (){
         rawMaterialListCFRSum = new Map<String,Decimal>();
        rawMaterialSoldCFRSum = new Map<String,Decimal>();
         blendedProducts = new List<SBQQ__QuoteLine__c>();
          wrapper = new PMC_CPQ_EmailControllerWrapperClass ();
            
    }
    
    /**
* @description This method is used to Query only the blended products among Quote line which is related to the Quote id passed
* @description qLines -  to store the Quotelines which have RawMaterials in the related list
* @return qLines 
*/
    public List<SBQQ__QuoteLine__c> qLines{
        get{
            System.debug('QuoteLine' +quoteId);
            if(quoteId!=null){ 
                // Modified by Jaswanth vaithiswaran part of GOHS-45 queried field PMC_CPQ_Margin is changed to PMC_CPQ_ReplacementMargin__c
               qLines= [SELECT id,SBQQ__ProductName__c, PMC_CPQ_CustomerPrice__c,PMC_CPQ_ContractType__c,PMC_CPQ_FinalPricePerTonne__c,PMC_CPQ_PriceGuidanceTarget__c,PMC_CPQ_PriceGuidanceFloor__c,
                          PMC_CPQ_PriceBookValue__c,PMC_CPQ_PaymentTerms__c,PMC_CPQ_Incoterms1__c,PMC_CPQ_PaymentDate__c,PMC_CPQ_VolumeDiscount__c,PMC_CPQ_Discount__c,PMC_CPQ_ExspaceIndicator__c,PMC_CPQ_GeneralComments__c,PMC_CPQ_ReplacementMargin__c,
                                       (select PMC_CPQ_Product__r.Name, PMC_CPQ_ListCFR__c,PMC_CPQ_SoldCFR__c,PMC_CPQ_Quantity__c,PMC_CPQ_QuantityTons__c,PMC_CPQ_ProductSKU__c from Raw_Materials1__r)
                                       from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteId WITH SECURITY_ENFORCED];
                
            }
            
           if(quoteId!=null){
            for (SBQQ__QuoteLine__c blendedProduct :qLines) {
                if (blendedProduct.Raw_Materials1__r.size() > 0) {
                    
                    blendedProducts.add(blendedProduct);
                }
            }
           }
            if (!hasCalculatedRawMaterialSums && blendedProducts.size()>0 ) {
                calculateRawMaterialSums(blendedProducts);
                hasCalculatedRawMaterialSums = true;
            }
            return qLines;            
        }set;
    }
    
    /**
* @description This method is used to Query Quote details of the  passed Quote id
* @return quoteInfo
*/
    public SBQQ__Quote__c getQuoteInfo(){
        if (SBQQ__Quote__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() &&
            Schema.SObjectType.SBQQ__Quote__c.fields.Name.isAccessible() &&
            Schema.SObjectType.SBQQ__Quote__c.fields.SBQQ__ListAmount__c.isAccessible() && Schema.SObjectType.SBQQ__Quote__c.fields.SBQQ__AdditionalDiscountAmount__c.isAccessible() && Schema.SObjectType.SBQQ__Quote__c.fields.SBQQ__NetAmount__c.isAccessible() && quoteInfo == NULL && quoteId != NULL) {
                quoteInfo = [SELECT id,Name,PMC_CPQ_ExpiresOn__c, PMC_CPQ_ExpirationDate__c,PMC_CPQ_ExpirationTime__c,SBQQ__PaymentTerms__c,PMC_CPQ_QuoteShortNameDescription__c,CurrencyIsoCode,PMC_CPQ_ContractEnd__c,CreatedDate,PMC_CPQ_AccountCountry__c,SBQQ__Account__r.Name,                        
                             (select CreatedDate from Approvals1__r),PMC_AdditionalComments__c from SBQQ__Quote__c where ID  =:quoteId WITH SECURITY_ENFORCED];
            }
        return quoteInfo;
    } 
    
    /**
* @description This method is used to Calculate the Total Quantity Tons
*@param blendedProducts - holds the Quotelines. 
*@description rawMaterialSKU - to store the Raw Material Name
*@description quantity - to store the Raw Material Quantity
*/
    private void calculateRawMaterialSums(List<SBQQ__QuoteLine__c> blendedProducts) {
        
        for (SBQQ__QuoteLine__c blendedProduct : blendedProducts) {
            for (PMC_CPQ_RawMaterial__c blendedProductInfo : blendedProduct.Raw_Materials1__r) {
                String rawMaterialSKU = blendedProductInfo.PMC_CPQ_ProductSKU__c;
                Decimal quantity = blendedProductInfo.PMC_CPQ_QuantityTons__c;
                
                if (wrapper.rawMaterialQuantitySum.containsKey(rawMaterialSKU)) {
                    wrapper.rawMaterialQuantitySum.put(rawMaterialSKU, wrapper.rawMaterialQuantitySum.get(rawMaterialSKU) + quantity);
                } else {
                    wrapper.rawMaterialQuantitySum.put(rawMaterialSKU, quantity);
                }
            }
        }
        calculateRawMaterialAvg(blendedProducts);
        
    }
    /**
* @description This method is used to Calculate the Avg List and Sold CFR
*@param blendedProducts - holds the Quotelines. 
*@description rawMaterialSKU - to store the Raw Material Name
*@description listCFR - to store the Raw Material ListCFR
*@description SoldCFR - to store the Raw Material SoldCFR
*@description nameofRM - to store the Raw Material Name

*/
    private void calculateRawMaterialAvg(List<SBQQ__QuoteLine__c> blendedProducts) {
        for (SBQQ__QuoteLine__c blendedProduct : blendedProducts) {
            for (PMC_CPQ_RawMaterial__c blendedProductInfo : blendedProduct.Raw_Materials1__r) {
                String rawMaterialSKU = blendedProductInfo.PMC_CPQ_ProductSKU__c;
                Decimal quantity = blendedProductInfo.PMC_CPQ_QuantityTons__c;
                Decimal listCFR = blendedProductInfo.PMC_CPQ_ListCFR__c;
                Decimal soldCFR = blendedProductInfo.PMC_CPQ_SoldCFR__c;
                Decimal totalListCFR = quantity*listCFR;
                Decimal totalSoldCFR = quantity*soldCFR;
                String nameofRM = blendedProductInfo.PMC_CPQ_Product__r.Name;
                
                if (rawMaterialListCFRSum.containsKey(rawMaterialSKU)) {
                    rawMaterialListCFRSum.put(rawMaterialSKU, rawMaterialListCFRSum.get(rawMaterialSKU) + totalListCFR);
                } else {
                    rawMaterialListCFRSum.put(rawMaterialSKU, totalListCFR);
                }
                if (rawMaterialSoldCFRSum.containsKey(rawMaterialSKU)) {
                    rawMaterialSoldCFRSum.put(rawMaterialSKU, rawMaterialSoldCFRSum.get(rawMaterialSKU) + totalSoldCFR);
                } else {
                    rawMaterialSoldCFRSum.put(rawMaterialSKU, totalSoldCFR);
                } 
                wrapper.rawMaterialName.put(rawMaterialSKU,nameofRM) ;                
            }
        }
        wrapper.rawMaterialSumsKey = wrapper.rawMaterialQuantitySum.keySet();
        for(String keys :wrapper.rawMaterialSumsKey){           
            wrapper.rawMaterialListCFRAvg.put(keys, (rawMaterialListCFRSum.get(keys)/wrapper.rawMaterialQuantitySum.get(keys)).setScale(2));
            wrapper.rawMaterialSoldCFRAvg.put(keys, (rawMaterialSoldCFRSum.get(keys)/wrapper.rawMaterialQuantitySum.get(keys)).setScale(2));          
        }
         
    }
    
}