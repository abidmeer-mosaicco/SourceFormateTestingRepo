/**
* @description       : 
* @author            : Mosaic Direct | Dev Team
* @group             : 
* @last modified on  : 03-01-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public without sharing class PMC_DH_RequestedOrderHelper {
     
    public static boolean throwTestException = false;
     /**
* @description 
* @author Mosaic Direct | Dev Team  | 10-16-2023 
* @param strShipFrom
* @param strShipTo
* @param strContractId
* @return String 
**/
    public static String getShipFrom(String strShipFrom, String strShipTo, String strContractId){
        String strShipFro = '';
        try{
            strShipFro = processShipFrom(strShipFrom,strShipTo,strContractId);
        }
        catch(QueryException qe){
            String strTemp = '';
            // Handle inaccessible fields
            Map<String, Set<String>> inaccessible = qe.getInaccessibleFields();
            Set<String> quoteLineFields = inaccessible.get('SBQQ__QuoteLine__c');    
            Set<String> subFields = inaccessible.get('SBQQ__Subscription__c');
            Set<String> prodLocationFields = inaccessible.get('PMC_CPQ_ProductLocation__c');    
            Set<String> accountFields = inaccessible.get('Account');
            Set<String> locationFields = inaccessible.get('Location');
            if(quoteLineFields != Null && subFields != Null && prodLocationFields != Null && accountFields != Null && locationFields != Null ){
                strTemp = 'Inaccessible';
            }
        }        
        return strShipFro;
    }
   
    /**
* @description 
* @author Mosaic Direct | Dev Team  | 10-16-2023 
* @param strShipFrom
* @param strShipTo
* @param strContractId
* @return String 
**/
    public static String processShipFrom(String strShipFrom, String strShipTo, String strContractId){
        String strShipFro = '';
        if(throwTestException && Test.isRunningTest()) {
            throw new QueryException(PMC_DH_ConstantClass.TEST_EXCEPTION_MESSAGE);
        }
        else {
        if(strShipFrom != Null && strShipTo != Null && strContractId != Null){
            List<SBQQ__Subscription__c> lstSubs =[SELECT Id,SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_SS_AccountExternalID__c, SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c from SBQQ__Subscription__c where SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c = :strShipTo and SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__c  = :strShipFrom and SBQQ__Contract__c = :strContractId WITH USER_MODE];
            if(!lstSubs.isEmpty()){
                strShipFro = lstSubs[0].SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c;
            }
        }
    }
        return strShipFro;
    }
     /**
* @description 
* @author Mosaic Direct | Dev Team  | 10-16-2023 
* @param strShipFrom
* @param strShipTo
* @param strContractId
* @return String 
**/
    public static String getShipTo(String strShipFrom, String strShipTo, String strContractId){
        String strShipT = '';
        if(strShipFrom != Null && strShipTo != Null && strContractId != Null){
                List<SBQQ__Subscription__c> lstSubs =[SELECT Id,SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_SS_AccountExternalID__c, SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c from SBQQ__Subscription__c where SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c = :strShipTo and SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__c  = :strShipFrom and SBQQ__Contract__c = :strContractId WITH SECURITY_ENFORCED];
                if(!lstSubs.isEmpty()){
                    strShipT= lstSubs[0].SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_SS_AccountExternalID__c;
                    //strShipT = '876578';

                }
            }  
        return strShipT;
    }

}