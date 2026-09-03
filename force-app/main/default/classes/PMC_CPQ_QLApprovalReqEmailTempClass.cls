/**
* @description This class will be used to fetch the data from the org to be used in Email Template.
* @author Azmir Ali
* @storynumber GCPM-2397
*/
public with sharing class PMC_CPQ_QLApprovalReqEmailTempClass {
   
    private OrderItem orderItemInfo;
    
    /**
* @description orderitemId -to store the quoteid rendering from the email template 
*/
    public string orderItemId {get;set;}

 /**
* @description This method is used to Query only the Orders which is related to the Order Line id passed
* @description qLines -  to store the Orders which have RawMaterials in the related list
* @return qLines 
*/
	public List<OrderItem> oLines{
        get{
            if(orderItemId!=null){ 
                oLines= [SELECT id,OrderItemNumber, Order.OrderNumber, Order.PMC_CPQ_SAPOrderNumber__c, Order.Contract.ContractNumber, Order.Contract.PMC_CPQ_PO__c,
                             PMC_CPQ_ShipTo__r.Name, Order.Account.Name, Product2.Name, Quantity, PMC_CPQ_PricingDate__c,PMC_CPQ_FPDPricefromPriceFx__c,
                             PMC_CPQ_FinalAgreedPrice__c, PMC_CPQ_OrderLineStatus__c, PMC_CPQ_OrderItemIntegrationMessage__c  from OrderItem WHERE ID = :orderItemId WITH SECURITY_ENFORCED];
            }
            return oLines;            
        }set;
    }
}