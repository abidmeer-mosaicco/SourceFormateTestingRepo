/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-28-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class PMC_SS_CaseDisputeManagementCtrl {

    /**
     * @description - Method used to fetch the Order Details
     * @param strOrderId - Order Id
     * @return OrderDetailsWrapper - Returns Wrapper of type OrderDetailsWrapper
     */

    @AuraEnabled(cacheable=true)
    public static PMC_SS_CaseDisputeManagementWrappers.OrderDetailsWrapper getOrderItems(String strOrderId){
        try {
            Order objOrder = [SELECT Id, AccountId, Account.Name, ContractId, Contract.ContractNumber,BillToContactId,BillToContact.Name,
                                    PMC_CPQ_ShipToAccount__c, PMC_CPQ_ShipToAccount__r.Name, PMC_CPQ_SoldToAccount__c, PMC_CPQ_SoldToAccount__r.Name,SBQQ__Quote__c,
                                    (SELECT Id, OrderItemNumber, OrderId, UnitPrice, PMC_CPQ_ProductLocation__c,PMC_CPQ_ShipTo__c,PMC_CPQ_ShipTo__r.Name, PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__c, 
                                     PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c, Product2.Name, Product2Id, PMC_CPQ_SAPOrderLineID__c, Quantity, PMC_CPQ_OrderLineStatus__c,PMC_CPQ_LinePONumber__c
                                     FROM OrderItems),
                                    (SELECT Id, ShipmentNumber,PMC_CPQ_UoMUnitofMeasure__c, PMC_CPQ_DeliveryQuantity__c, PMC_CPQ_OriginLocation__c,
                                     	PMC_CPQ_OriginLocation__r.Name, DestinationLocationId, DestinationLocation.Name, PMC_CPQ_ShippedDate__c,
                                     	PMC_CPQ_VehicleID__c
                                     	FROM Deliveries__r),
                                    (SELECT Id, Name, PMC_CPQ_Contact__c, PMC_CPQ_Contact__r.Name, PMC_CPQ_TotalInvoiceValue__c, PMC_CPQ_OrderProduct__c,PMC_CPQ_InvoiceNumber__c,PMC_CPQ_Status__c,PMC_CPQ_DateIssued__c
                                       FROM Invoices__r ORDER BY CreatedDate DESC)
                                    FROM Order                                       
                                    WHERE Id =: strOrderId 
                                    ];

            if(objOrder != null) {
                PMC_SS_CaseDisputeManagementWrappers.OrderDetailsWrapper objOrderDetailsWrapper = new PMC_SS_CaseDisputeManagementWrappers.OrderDetailsWrapper();
                objOrderDetailsWrapper.objOrder = objOrder;

                PMC_SS_ObjectDetailsWrapper objAccountWrapper = new PMC_SS_ObjectDetailsWrapper(objOrder.AccountId, objOrder.Account.Name);
                objOrderDetailsWrapper.objAccountWrapper = objAccountWrapper;

                PMC_SS_ObjectDetailsWrapper objContractWrapper = new PMC_SS_ObjectDetailsWrapper(objOrder.ContractId, objOrder.Contract.ContractNumber);
                objOrderDetailsWrapper.objContractWrapper = objContractWrapper;

                
                PMC_SS_ObjectDetailsWrapper objSoldToAccountWrapper = new PMC_SS_ObjectDetailsWrapper(objOrder.PMC_CPQ_SoldToAccount__c, objOrder.PMC_CPQ_SoldToAccount__r.Name);
                objOrderDetailsWrapper.objSoldToAccountWrapper = objSoldToAccountWrapper;

                objOrderDetailsWrapper.lstOrderItems = objOrder.OrderItems;
                objOrderDetailsWrapper.lstInvoices = objOrder.Invoices__r;
                objOrderDetailsWrapper.lstDeliveries = objOrder.Deliveries__r;

                return objOrderDetailsWrapper; 
            }
        } 
        catch (Exception e) {
            System.debug('Error Message: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        
        return null;
    }

    /**
     * @description - Method used to fetch the delivery item Details
     * @param strOrderItemId - Order Item Id
     * @return List<ShipmentItem> - Returns List of Shipment Items
     */
    @AuraEnabled(cacheable=true)
    public static List<ShipmentItem> getDeliveryItems(String strOrderItemId){
        
            return [SELECT Id, PMC_CPQ_OrderProduct__c, ShipmentItemNumber, PMC_CPQ_DeliveryItemName__c,  PMC_CPQ_DeliveryItemID__c,
                    PMC_CPQ_ModeofTransportation__c, PMC_CPQ_PlantID__c, PMC_CPQ_VehicleID__c, PMC_CPQ_ShippedDate__c, Product2.Name,
                    PMC_CPQ_UnitofMeasure__c,PMC_CPQ_DeliveryQuantity__c,ShipmentId
                    FROM ShipmentItem                                           
                    WHERE PMC_CPQ_OrderProduct__c =: strOrderItemId 
                    WITH SECURITY_ENFORCED];                    
    }
    /**
     * added as per 1524
     * @description - Method used to fetch the QuoteLineitems 
     * @param productId - Order Item Id
     * @return List<SBQQ__QuoteLine__c> - Returns List of QuoteLineitems
     */
    @AuraEnabled(cacheable=true)
    public static List<SBQQ__QuoteLine__c> getQuoteLineitems(String productId,String quoteId){
        List<SBQQ__QuoteLine__c> QuoteLineitems = [SELECT Id,SBQQ__ListPrice__c
                    FROM SBQQ__QuoteLine__c                                           
                    WHERE SBQQ__Product__c =: productId  AND SBQQ__Quote__c =:quoteId
                    ];  
        if(!QuoteLineitems.isEmpty()){
            return QuoteLineitems;

        }  
        return null;                 
    }
    
    
    /**
     * @description - Method used to fetch the contract Details
     * @param strAccountId - Account Id
     * @return List<Contract> - Returns List of Contract
     */
    @AuraEnabled(cacheable=true) 
    public static List<Contract> getContracts(String strAccountId) {
        try {
            Account objAccount = [SELECT Id, (SELECT Id, ContractNumber FROM Contracts) FROM Account WHERE Id =: strAccountId WITH SECURITY_ENFORCED LIMIT 1];
            return objAccount.Contracts;
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

     /**
     * @description - Method used to fetch picklist values Case Object details
     * @param strObjApiName - Object API Name
     * @param strFieldName - Field Name
     * @return List<Map<String, String>> - Map with details
     */
    @AuraEnabled
    public static List<Map<String, String>> getPickListValues(String strObjApiName, String strFieldName) {
        List<Map<String, String>> lstOptions = new List <Map<String, String>>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(strObjApiName);
        if (objType == null) {
            return lstOptions;
        }
        Schema.DescribeSObjectResult sobjectDescribe = objType.getDescribe(SObjectDescribeOptions.DEFERRED);
        Map<String, Schema.SObjectField> mapField = sobjectDescribe.fields.getMap();
        if (mapField.get(strFieldName) == null) {
            return lstOptions;
        }
        List <Schema.PicklistEntry> pickListValues = mapField.get(strFieldName).getDescribe().getPickListValues();
        for (Schema.PicklistEntry f: pickListValues) {
            Map<String, String> mapValues = new Map<String, String> {
                'label' => f.getLabel(),
                'value' => f.getValue()
            };
            lstOptions.add(mapValues);
        }
        return lstOptions;
    }

    /**
     * @description - Method used to upload a document on Case
     * @param strBase64 - File Data
     * @param strFilename - File Name
     * @param strRecordId - Case Record Idd
     * @return String - Returns content document id
     */ 
    @AuraEnabled
    public static String uploadFile(String strBase64, String strFilename, String strRecordId) {
        ContentVersion objContentVersion = createContentVersion(strBase64, strFilename);
        ContentDocumentLink objContentDocLink = createContentLink(objContentVersion.Id, strRecordId);
        if (objContentVersion == null || objContentDocLink == null) {
            return null; 
        }
        return objContentDocLink.Id;
    } 
    
    /**
     * @description - Method used to prepare ContentVersion
     * @param strBase64 - File Data
     * @param strFilename - File Name
     * @return ContentVersion - Returns content document id
     */
    private static ContentVersion createContentVersion(String strBase64, String strFilename) {
        ContentVersion objContentVersion = new ContentVersion();
        objContentVersion.VersionData = EncodingUtil.base64Decode(strBase64);
        objContentVersion.Title = strFilename;
        objContentVersion.PathOnClient = strFilename;
        try {
            if(ContentVersion.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()) {
                insert objContentVersion;
                return objContentVersion;

            }
        } 
        catch(DMLException e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return null;
    }
    
    /**
     * @description - Method used to prepare ContentDocumentLink
     * @param strContentVersionId - Content Version Id
     * @param strRecordId - Case Record Idd
     * @return ContentDocumentLink - Returns content document Link id
     */
    private static ContentDocumentLink createContentLink(String strContentVersionId, String strRecordId) {
        if (strContentVersionId == null || strRecordId == null) { 
            return null; 
        }
        
        ContentDocumentLink objContentDocLink = new ContentDocumentLink();
            
        objContentDocLink.ContentDocumentId = [SELECT ContentDocumentId 
                                 FROM ContentVersion 
                                 WHERE Id =: strContentVersionId WITH SECURITY_ENFORCED
            					].ContentDocumentId;
        
        objContentDocLink.LinkedEntityId = strRecordId;
        objContentDocLink.ShareType = 'V';
        try {
            if(ContentDocumentLink.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()) {
                insert objContentDocLink;
                return objContentDocLink;
            }
        } 
        catch(DMLException e) { throw new AuraHandledException(e.getMessage());
        }
        return null;
    }
}