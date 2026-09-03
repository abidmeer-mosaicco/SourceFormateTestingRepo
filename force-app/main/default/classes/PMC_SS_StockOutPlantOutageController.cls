/**
* @description This class is used to create stock out/plant outage child cases
* @author Urvashi Chauhan
* @storynumber GDASF-15351
*/

public with sharing class PMC_SS_StockOutPlantOutageController {
    
    /**
    * @description This invocable method is invoked from a screen flow to create stock outage child cases
    * @param lstStockOutageRequest - List of Stock outage request
    */
    
    @InvocableMethod(label = 'Create Stock Out Plant Outage Child Cases')
    public static void createChildStockOutageChildCases(List<PMC_SS_StockOutageRequest> lstStockOutageRequest) {
        
        try {
            String strOrders;
            String strContracts;
            Case objParentCase;
            List<String> lstOrderNumbers = new List<String>();
            List<String> lstContractNumbers = new List<String>();
            Map<Id,Case> mapAccIdWithCase = new Map<Id,Case>();
            List<Case> lstChildCasesInsert = new List<Case>();
            
            if(!lstStockOutageRequest.isEmpty()) {
                strOrders = lstStockOutageRequest[0].strOrders;
                strContracts = lstStockOutageRequest[0].strContracts;
                objParentCase = lstStockOutageRequest[0].objParentCase;
            }
            
            if(String.isNotBlank(strOrders) && objParentCase != null) {
                lstOrderNumbers = strOrders.split(';');
                mapAccIdWithCase = createChildCasesForStockOutageOrders(lstOrderNumbers, objParentCase);
            }
            
            else if(String.isNotBlank(strContracts) && objParentCase != null) {
                lstContractNumbers = strContracts.split(';');
                mapAccIdWithCase = createChildCasesForStockOutageContracts(lstContractNumbers, objParentCase);
            }
            
            lstChildCasesInsert = mapAccIdWithCase.values();
            insertStockOutageChildCases(lstChildCasesInsert);
        }
        catch(Exception objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }
    
    /**
    * @description This method is used to create stock outage child cases from orders
    * @param lstOrderNumbers - List of Order Numbers
    * @param objParentCase - Parent Case record
    * @return mapAccIdWithCase - Map of Account Id with Case
    */
    
    public static Map<Id,Case> createChildCasesForStockOutageOrders(List<String> lstOrderNumbers, Case objParentCase) {
        
        if(!lstOrderNumbers.isEmpty()) {
            Map<Id,Case> mapAccIdWithCase = new Map<Id,Case>();
            List<Order> lstOrders = [SELECT Id, AccountId, OrderNumber FROM Order 
                                     WHERE OrderNumber IN :lstOrderNumbers
                                     WITH SECURITY_ENFORCED];
            
            for(Order objOrder : lstOrders) {
                
                if(!mapAccIdWithCase.containsKey(objOrder.AccountId)) {
                    
                    Case objChildCase = preaperChildCases(objParentCase);
                    objChildCase.PMC_SS_StockOutPlantOutageOrders__c = objOrder.OrderNumber;
                    objChildCase.AccountId = objOrder.AccountId;
                    
                    mapAccIdWithCase.put(objOrder.AccountId, objChildCase);
                    
                } 
                else {
                    Case objCaseOrder = mapAccIdWithCase.get(objOrder.AccountId);
                    objCaseOrder.PMC_SS_StockOutPlantOutageOrders__c = objCaseOrder.PMC_SS_StockOutPlantOutageOrders__c+ ';' +objOrder.OrderNumber;
                    mapAccIdWithCase.put(objOrder.AccountId, objCaseOrder);
                    
                }              
            }
            return mapAccIdWithCase;
            
        } else {
            return null;
        }
        
    }
    
    /**
    * @description This method is used to create stock outage child cases from contracts
    * @param lstContractNumbers - List of Contract Numbers
    * @param objParentCase - Parent Case record
    * @return mapAccIdWithCase - Map of Account Id with Case
    */
    
    public static Map<Id,Case> createChildCasesForStockOutageContracts(List<String> lstContractNumbers, Case objParentCase) {
        
        if(!lstContractNumbers.isEmpty()) {
            Map<Id,Case> mapAccIdWithCase = new Map<Id,Case>();
            List<Contract> lstContracts = [SELECT Id, AccountId, ContractNumber FROM Contract 
                                           WHERE ContractNumber IN :lstContractNumbers
                                           WITH SECURITY_ENFORCED];
            
            for(Contract objContract : lstContracts) {
                
                
                if(!mapAccIdWithCase.containsKey(objContract.AccountId)) {
                    
                  	Case objChildCase = preaperChildCases(objParentCase);
                    objChildCase.PMC_SS_StockOutPlantOutageContracts__c = objContract.ContractNumber;
                    objChildCase.AccountId = objContract.AccountId;
                    
                    mapAccIdWithCase.put(objContract.AccountId, objChildCase);
                    
                } else {
                    Case objCaseContract = mapAccIdWithCase.get(objContract.AccountId);
                    objCaseContract.PMC_SS_StockOutPlantOutageContracts__c = objCaseContract.PMC_SS_StockOutPlantOutageContracts__c+ ';' +objContract.ContractNumber;
                    mapAccIdWithCase.put(objContract.AccountId, objCaseContract);
                    
                }              
            }
            return mapAccIdWithCase;
            
        } else {
            return null;
        }
        
    }
    
    /**
    * @description This method is used to insert child cases in the database
    * @param lstChildCasesInsert - List of Stock outage child cases
    */
    
    public static void insertStockOutageChildCases(List<Case> lstChildCasesInsert) {
        
        if(!lstChildCasesInsert.isEmpty() && Schema.sObjectType.Case.isCreateable()) {
            insert lstChildCasesInsert; 
        }
    }
    
    /**
    * @description This method is used to insert child cases in the database
    * @param objParentCase - Parent Case record
    * @return objChildCase - Return Child Cases 
    */
    
    public static Case preaperChildCases(case objParentCase) {
	
					Case objChildCase = new Case();
                    objChildCase.Status = objParentCase.Status;
                    objChildCase.Type = objParentCase.Type;
                    objChildCase.BusinessHoursId = objParentCase.BusinessHoursId;
                    objChildCase.ParentId = objParentCase.Id;
                    objChildCase.Origin = objParentCase.Origin;
                    objChildCase.Priority = objParentCase.Priority;
                    objChildCase.Subject = objParentCase.Subject;
                    objChildCase.Description = objParentCase.Description;
                    objChildCase.CurrencyIsoCode = objParentCase.CurrencyIsoCode;
                    objChildCase.ProductId = objParentCase.ProductId;
                    objChildCase.PMC_SS_Location__c = objParentCase.PMC_SS_Location__c;
                    objChildCase.PMC_SS_IssueReason__c = objParentCase.PMC_SS_IssueReason__c;
                    objChildCase.PMC_SS_Plant__c = objParentCase.PMC_SS_Plant__c;
                    objChildCase.PMC_SS_StockOutPlantOutageStartDate__c = objParentCase.PMC_SS_StockOutPlantOutageStartDate__c;
                    objChildCase.PMC_SS_StockOutPlantOutageEndDate__c = objParentCase.PMC_SS_StockOutPlantOutageEndDate__c;
					
			return objChildCase;
	
	}
    
    /**
    * @description This class is used for invocable variables
    */
    
    public class PMC_SS_StockOutageRequest {
        
        @InvocableVariable
        public String strOrders;
        
        @InvocableVariable
        public String strContracts;
        
        @InvocableVariable(required=true)
        public Case objParentCase;
    }
}