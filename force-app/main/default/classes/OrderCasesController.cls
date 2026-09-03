public with sharing class OrderCasesController {
    @AuraEnabled(cacheable=true)
    public static List<Case> getRelatedCases(Id orderId) {
        System.debug('In apex class!');
        List<Case> casesRetreived = [SELECT Id, CaseNumber, Status, Type, Contact.Name, PMC_SS_AtFaultParty__c, CreatedDate 
                FROM Case WHERE PMC_SS_Order__c = :orderId ORDER BY CreatedDate DESC];
        System.debug('casesRetreived-->' + casesRetreived);
        return casesRetreived;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOrderDetails(Id orderId) {
        Order ord = [SELECT Id, AccountId, Contract.CustomerSignedId, PMC_CPQ_SoldToAccount__c, PMC_CPQ_SAPOrderNumber__c,PMC_CPQ_PO__c,OrderNumber 
        //GSMD3234
        ,(select id,PMC_CPQ_ModeofTransportation__c,PMC_CPQ_ShipTo__r.name,PMC_CPQ_UnitOfMeasure__c,product2.name,PMC_CPQ_ConfirmedQuantity__c from orderitems  )              
        FROM Order WHERE Id = :orderId];

        Map<String, Object> result = new Map<String, Object>();
        result.put('AccountId', ord.AccountId);
        result.put('ContactId', ord.Contract.CustomerSignedId);
        result.put('PMC_SS_SoldToAccount__c', ord.AccountId);
        result.put('PMC_SS_SAPOrderNumber__c', ord.PMC_CPQ_SAPOrderNumber__c);
        result.put('PMC_SS_SNOW_OrderNumberorContractNumber__c', ord.OrderNumber);
        result.put('PMC_SS_Order__c', ord.Id);
        //Added for GSMD-1534
        result.put('Customer_Purchase_Order__c', ord.PMC_CPQ_PO__c);
        //GSMD-3234
        if(ord.orderitems!=null)
        {
            if(ord.orderitems.size()==1)
            {
                result.put('Is_MultipleOrdereItem',false);
                result.put('OrderRecord',ord.orderitems[0]);
                


            }
            if(ord.orderitems.size()>1)
            {
                result.put('Is_MultipleOrdereItem',true);
                result.put('OrderItemRecords', ord.orderitems);

            }
        }
        

        return result;
    }
}