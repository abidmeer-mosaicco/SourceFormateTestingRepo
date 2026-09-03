/** 
* @description Controller for submitting order
* @author Mosaic Direct Dev 
* @last modified on 2023-October-05
* @last modified by Mosaic Direct Dev 
* Created On: 2023-October-05
**/
public without sharing class PMC_DH_OrderSubmitController {

    public static boolean boolThrowException=false;

    /**
* @description 
* @author  Mosaic Direct Dev 
* @param strCartId 
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper 
**/ 
    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper submitOrder(String strCartId){
        HTTPResponse response;
        String responseBody;
        Set<Integer> setStatusCode = new Set<Integer>{200,201,202};
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        try{
            if(boolThrowException && Test.isRunningTest()){
                throw new AuraHandledException('Exception Test');
            }
            WebCart objCart = [SELECT Id, Status FROM WebCart WHERE Id = :strCartId WITH SECURITY_ENFORCED];
            response = PMC_DH_OrderSchedulingService.submitOrUpdateSchedulingRequest(strCartId);
            if(setStatusCode.contains(response.getstatusCode()) ) {
                responseBody = (String)response.getBody();
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.ORDER_CREATION_SUCCESS_MODULE);
                result.strData =responseBody;
                if( Schema.sObjectType.WebCart.isUpdateable()){
                    objCart.Status = PMC_DH_ConstantClass.CLOSED;                    
                    update objCart;                     
                }
            }
            else{
                result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ORDER_CREATION_SUCCESS_MODULE);
            }

        }
        catch(Exception ex){
            result = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
        }
        return result;
    }
    /** 
* @description Controller for fetching order History
* @author Mosaic Direct Dev 
* @last modified on 2023-October-05
* @last modified by Mosaic Direct Dev 
@param strEffectiveAccountId
    @return PMC_DH_OrderListViewWrapper
* Created On: 2023-October-05
**/
    @AuraEnabled
    public static PMC_DH_OrderListViewWrapper fetchOrderHistory(String strEffectiveAccountId){
        HTTPResponse response ;
        String responseBody;
            Set<Integer> setStatusCode = new Set<Integer>{200,201,202};
        PMC_DH_OrderFetchWrapper orderFetchWrapper = new PMC_DH_OrderFetchWrapper();
        PMC_DH_OrderListViewWrapper orderHistoryWrapper = new PMC_DH_OrderListViewWrapper();
        List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> responseWrapper = new List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>();
        try{
            response = PMC_DH_OrderSchedulingService.fetchOrderHistoryFromSAP(strEffectiveAccountId);
                if(setStatusCode.contains(response.getStatusCode())  && response.getBody() != Null){
                    responseBody = (String)response.getBody();
                    orderFetchWrapper = (PMC_DH_OrderFetchWrapper)JSON.deserialize(responseBody, PMC_DH_OrderFetchWrapper.class);
                    responseWrapper = orderFetchWrapper.lstData;
                orderHistoryWrapper = PMC_DH_OrderSubmitUtils.createOrderHistoryWrapper(responseWrapper, strEffectiveAccountId); 
                    orderHistoryWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.FETCH_ORDERS_SUCCESS_MODULE);
                }
            
        }
        catch(Exception Ex){
                orderHistoryWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
        }
        return orderHistoryWrapper;
    }    
      
    /**
* @description update the map of ship to id with address
* @author  Mosaic Direct Dev 
* @param mapOfShiptToIdAdd
* @param wrap
* @param cpfShipToMap
* @return  Map<String,String>
**/
    public static Map<String,String> updateShipToAddressMap(Map<String,String> mapOfShiptToIdAdd, PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper wrap, Map<String,PMC_SS_AccountPartnerRelationships__c> cpfShipToMap){
        if(String.isNotBlank(wrap.strShiptoid) && !mapOfShiptToIdAdd.containsKey(wrap.strShiptoid)){
            mapOfShiptToIdAdd.put(wrap.strShiptoid, wrap.strShiptoName + ' ' + wrap.strShiptoadd);   
        }
        else if(String.isNotBlank(wrap.strAccIdentifier) && cpfShipToMap.containsKey(wrap.strAccIdentifier)){ //strAccIdentifier - new attribute provided from CPI
           
            
            PMC_SS_AccountPartnerRelationships__c objShipTo = cpfShipToMap.get(wrap.strAccIdentifier);
            String strShipToLabel = objShipTo.PMC_SS_RelatedAccount__r.Name + ' ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingStreet + ', ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingCity + ', ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingState + ' ' + objShipTo.PMC_SS_RelatedAccount__r.ShippingPostalCode;
            mapOfShiptToIdAdd.put(wrap.strAccIdentifier,  strShipToLabel);
        }
        return mapOfShiptToIdAdd;
    }
    
    /**
* @description 
* @author Sugunkar ROuthu
* @param effectiveAccountId 
* @return String 
**/
    public static Map<String,PMC_SS_AccountPartnerRelationships__c> getCPFAccountMap(String effectiveAccountId){
        
        Map<String,PMC_SS_AccountPartnerRelationships__c> shipToMap = new Map<String,PMC_SS_AccountPartnerRelationships__c>();
        List<PMC_SS_AccountPartnerRelationships__c> lstShipTpAccount = [SELECT Id, PMC_SS_Account__c, PMC_SS_Account__r.Name,
                                                                        PMC_SS_RelatedAccount__c, PMC_SS_RelatedAccount__r.Name,PMC_SS_RelatedAccount__r.PMC_DH_StreetNumber__c, PMC_SS_RelatedAccount__r.Type,
                                                                        PMC_SS_RelatedAccount__r.ShippingStreet, PMC_SS_RelatedAccount__r.ShippingCity, PMC_SS_RelatedAccount__r.ShippingPostalCode, PMC_SS_RelatedAccount__r.ShippingState,
                                                                        PMC_SS_RelatedAccount__r.PMC_SS_CPF__c, PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c,PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c,PMC_SS_RelatedAccount__r.PMC_SS_AccountExternalID__c,PMC_SS_RelatedAccount__r.ParentId,PMC_SS_RelatedAccount__r.shippingcountry,PMC_SS_RelatedAccount__r.PMC_DH_Delivery_Instruction__c  
                                                                        FROM PMC_SS_AccountPartnerRelationships__c WHERE PMC_SS_Account__c=:effectiveAccountId
                                                                        AND PMC_SS_Type__c=:PMC_DH_ConstantClass.ACCOUNT_TYPE AND PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c!=:PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS 
                                                                        WITH SECURITY_ENFORCED];
       
 if(!lstShipTpAccount.isEmpty()){
            for(PMC_SS_AccountPartnerRelationships__c objShipTo : PMC_DH_QuoteManagementHelper.removeDuplicateRelatedAccountsFromList(lstShipTpAccount)){ 
                if(objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_CPF__c != null){
                String strdentifierCPF=objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_CPF__c+'-'+objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c;
                        if(strdentifierCPF.length()>25){
                        String strdentifierCPF2=   strdentifierCPF.right(25);
                        shipToMap.put(strdentifierCPF2, objShipTo);
                        }else{
                            shipToMap.put(objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_CPF__c+'-'+objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c, objShipTo); 
                        }   
                }
                else if(objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c != null){
                   
                        String strdentifierCNPJ=objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c+'-'+objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c;
                        if(strdentifierCNPJ.length()>25){
                                    String strdentifierCNPJ2=   strdentifierCNPJ.right(25);
                                shipToMap.put(strdentifierCNPJ2, objShipTo);
                        }else{
                            shipToMap.put(objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c+'-'+objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c, objShipTo);
                                }  
                }
            }
        }
        return shipToMap;
    }
    //Adding new for GSMD-339
      public static Map<String,PMC_SS_AccountPartnerRelationships__c> getCPFAccountMapLegacy(String effectiveAccountId){        
        Map<String,PMC_SS_AccountPartnerRelationships__c> shipToMap = new Map<String,PMC_SS_AccountPartnerRelationships__c>();
        List<PMC_SS_AccountPartnerRelationships__c> lstShipTpAccount = [SELECT Id, PMC_SS_Account__c, PMC_SS_Account__r.Name,
                                                                        PMC_SS_RelatedAccount__c, PMC_SS_RelatedAccount__r.Name,PMC_SS_RelatedAccount__r.PMC_DH_StreetNumber__c, PMC_SS_RelatedAccount__r.Type,
                                                                        PMC_SS_RelatedAccount__r.ShippingStreet, PMC_SS_RelatedAccount__r.ShippingCity, PMC_SS_RelatedAccount__r.ShippingPostalCode, PMC_SS_RelatedAccount__r.ShippingState,
                                                                        PMC_SS_RelatedAccount__r.PMC_SS_CPF__c, PMC_SS_RelatedAccount__r.PMC_SS_StateTaxNumber__c,PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c,PMC_SS_RelatedAccount__r.PMC_SS_AccountExternalID__c,PMC_SS_RelatedAccount__r.ParentId,PMC_SS_RelatedAccount__r.shippingcountry,PMC_SS_RelatedAccount__r.PMC_DH_Delivery_Instruction__c  
                                                                        FROM PMC_SS_AccountPartnerRelationships__c WHERE PMC_SS_Account__c=:effectiveAccountId
                                                                        AND PMC_SS_Type__c=:PMC_DH_ConstantClass.ACCOUNT_TYPE AND PMC_SS_RelatedAccount__r.PMC_DH_Account_Status__c!=:PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS 
                                                                        WITH SECURITY_ENFORCED];
          
          if(!lstShipTpAccount.isEmpty()){
              for(PMC_SS_AccountPartnerRelationships__c objShipTo : PMC_DH_QuoteManagementHelper.removeDuplicateRelatedAccountsFromList(lstShipTpAccount)){ 
                  if(objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_CPF__c != null){                    
                      shipToMap.put(objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_CPF__c, objShipTo); 
                  }
                  else if(objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c != null){
                      shipToMap.put(objShipTo.PMC_SS_RelatedAccount__r.PMC_SS_TaxIDOrCNPJOrCPF__c, objShipTo);
                  }
              }
          }
          return shipToMap;
      }
}