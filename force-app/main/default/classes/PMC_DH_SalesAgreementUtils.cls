/**
* @description : class for the methods that will be used for RFQ
* @author      : Sugunakar Routhu
* @last modified on  : 12-24-2023
* @last modified by  : Humera | Digital Hub
**/
// added with sharing
public with sharing class PMC_DH_SalesAgreementUtils {
    
    /*************************************************************************
* @method Name  : updateSalesAgreementId
* @description  : Method to update the Sales Agreement 
* @return PMC_DH_RequestForQuoteHelper.PMC_DH_SalesAreaForCartWrapper
* @param       	  strCartId
*****************************************************************************/
    
    public static PMC_DH_RequestForQuoteHelper.PMC_DH_SalesAreaForCartWrapper updateSalesAgreementId(String strCartId){
        PMC_DH_RequestForQuoteHelper.PMC_DH_SalesAreaForCartWrapper result = new PMC_DH_RequestForQuoteHelper.PMC_DH_SalesAreaForCartWrapper();
        try{
            Id salesAgrremntId=NULL;
            result.boolIsPriceEnabled=false;
            Integer highestAgreemntMathedProducts = 0;
            Set<String> setProductSKU = new  Set<String>();
            List<CartItem> cartItemList = new List<CartItem>();
            cartItemList = [SELECT Id, Product2.StockKeepingUnit, PMC_DH_Source__c,cart.AccountId FROM CartItem Where CartId =: strCartId WITH USER_MODE];
            String strEffAccId=cartItemList[0].cart.AccountId;
            if(cartItemList[0].PMC_DH_Source__c == 'RFQ' ){ 
        for(CartItem cItem : cartItemList ){
            setProductSKU.add(cItem.Product2.StockKeepingUnit);
        }
        for(SalesAgreement agrRec : [SELECT Id,Name,StartDate,EndDate, 
                                    (SELECT Id from SalesAgreementProducts Where Product.StockKeepingUnit IN : setProductSKU ) from SalesAgreement 
                                    Where AccountId= :strEffAccId  AND  StartDate <=TODAY AND EndDate >=TODAY
                                    AND Id IN (SELECT SalesAgreementId from SalesAgreementProduct Where Product.StockKeepingUnit IN : setProductSKU) WITH SYSTEM_MODE Order By CreatedDate DESC])
        {
            Integer currentAgreemntMathedProducts = agrRec.SalesAgreementProducts.size();
            if(currentAgreemntMathedProducts > highestAgreemntMathedProducts){
                salesAgrremntId =  agrRec.Id;
                highestAgreemntMathedProducts = currentAgreemntMathedProducts;
            }
            
        }
                if(salesAgrremntId!=null){
                    result.boolIsPriceEnabled=true;
                    result.strSalesArea=salesAgrremntId;
                }
               
                
            }
        }
        catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
    }
    return result;
    
}
}