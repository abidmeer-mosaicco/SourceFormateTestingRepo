/**
* @description       : Batch Class to create Subscription records from Quoteline loaded.
* @author            : Prakhar Srivastava
**/

public class PMC_DM_SubscriptionCreateBatch implements Database.Batchable<sObject>
{
	Id userId;
    List<Id> lstQLId = new List<Id>();
    
    /**
    * @description Constructor for PMC_DM_SubscriptionCreateBatch class
    * @param userId
    */
    public PMC_DM_SubscriptionCreateBatch(Id userId){
        this.userId = userId;
    }
    
    /**
    * @description Constructor for PMC_DM_SubscriptionCreateBatch class
    * @param userId
    * @param lstQLId
    */
    public PMC_DM_SubscriptionCreateBatch(Id userId, List<Id> lstQLId){
        this.userId = userId;
        this.lstQLId = lstQLid;
    }
    
    /**
    * @description Start method of batchable
    * @param objBC
    * @return  Database.QueryLocator
    */
    
    public Database.QueryLocator start(Database.BatchableContext objBC){
        String query;
        if(!lstQLId.isEmpty()){
            query = 'select id,SBQQ__Quote__c, CurrencyIsoCode, SBQQ__Quantity__c, PMC_CPQ_PriceDueDate__c,PMC_CPQ_LinePONumber__c,PMC_CPQ_DeliveryStartDate__c, PMC_CPQ_DeliveryEndDate__c,SBQQ__SubscriptionPricing__c,PMC_CPQ_PaymentTerms__c,PMC_CPQ_ShipTo__c,PMC_CPQ_PaymentDate__c,'; 
            query+= ' PMC_CPQ_Commission__c, PMC_CPQ_CommissionCurrency__c, PMC_CPQ_CropType__c, PMC_CPQ_CustomerOfferedPrice__c, PMC_CPQ_FinalPricePerTon__c, PMC_CPQ_VCODeliveryRegion__c, PMC_CPQ_FinalPricePerTonne__c,PMC_CPQ_ProductLocation__c,PMC_CPQ_SoldToShipToJunction__c,';
            query+= ' PMC_CPQ_FreightMonth__c, PMC_CPQ_Incoterms1__c, PMC_CPQ_UnitofMeasure__c, PMC_CPQ_ModeofTransportation__c, SBQQ__Product__c, PMC_CPQ_ContractType__c, PMC_CPQ_CustomerPrice__c from SBQQ__QuoteLine__c where CreatedById =: userId and SBQQ__Quote__r.PMC_CLM_ContractCreated__c = true and id in :lstQLId and PMC_CPQ_GeneralComments__c = null'; 
        }
        else{
            query = 'select id,SBQQ__Quote__c, CurrencyIsoCode, SBQQ__Quantity__c, PMC_CPQ_PriceDueDate__c,PMC_CPQ_LinePONumber__c,PMC_CPQ_DeliveryStartDate__c, PMC_CPQ_DeliveryEndDate__c,SBQQ__SubscriptionPricing__c,PMC_CPQ_PaymentTerms__c,PMC_CPQ_ShipTo__c,PMC_CPQ_PaymentDate__c,'; 
            query+= ' PMC_CPQ_Commission__c, PMC_CPQ_CommissionCurrency__c, PMC_CPQ_CropType__c, PMC_CPQ_CustomerOfferedPrice__c, PMC_CPQ_FinalPricePerTon__c, PMC_CPQ_VCODeliveryRegion__c, PMC_CPQ_FinalPricePerTonne__c,PMC_CPQ_ProductLocation__c,PMC_CPQ_SoldToShipToJunction__c,';
            query+= ' PMC_CPQ_FreightMonth__c, PMC_CPQ_Incoterms1__c, PMC_CPQ_UnitofMeasure__c, PMC_CPQ_ModeofTransportation__c, SBQQ__Product__c, PMC_CPQ_ContractType__c, PMC_CPQ_CustomerPrice__c from SBQQ__QuoteLine__c where CreatedById =: userId and SBQQ__Quote__r.PMC_CLM_ContractCreated__c = true and PMC_CPQ_GeneralComments__c = null'; 
        }
        return Database.getQueryLocator(query); 
    }
    /**
    * @description execute method of batchable
    * @param objBC
    * @param lstQuoteLines
    */    
    public void execute(Database.BatchableContext objBC, List<SBQQ__QuoteLine__c> lstQuoteLines)
    {
        List<SBQQ__Subscription__c> lstSubcription = new List<SBQQ__Subscription__c>();
        List<SBQQ__QuoteLine__c> lstQLUpdate = new List<SBQQ__QuoteLine__c>();
        try{
            // create a map of quote created by DM user and related contract
            Map<Id,Contract> mapQuoteContract =  new Map<Id,Contract>();
            for(Contract con: [select id, SBQQ__Quote__c, ownerId, AccountId from Contract where CreatedById =:userId]){
                mapQuoteContract.put(con.SBQQ__Quote__c,con);
            }
            // prepare mapping of subscription data
            for (SBQQ__QuoteLine__c objQLs : lstQuoteLines){  
                SBQQ__Subscription__c objSub = new SBQQ__Subscription__c();
                objSub = createSubMapping(objQLs, mapQuoteContract, userId);
                lstSubcription.add(objSub);
                objQLs.PMC_CPQ_GeneralComments__c = 'Subscription Created';
                lstQLUpdate.add(objQLs);
                
            }
            // insert subscription
            if(!lstSubcription.isEmpty()){
                    SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, lstSubcription);
                    Database.insert(decision.getRecords());
                    SObjectAccessDecision decisionQL = Security.stripInaccessible(AccessType.UPDATABLE, lstQLUpdate);
                    Database.update(decisionQL.getRecords());
                } 
        }
        catch(Exception e){
            PMC_ErrorLog__c objErrorLog = new PMC_ErrorLog__c();
            objErrorLog.PMC_Message__c = e.getMessage();
        	objErrorLog.PMC_MethodName__c = 'execute';
        	objErrorLog.PMC_ClassName__c = 'PMC_DM_SubscriptionCreateBatch';
        	Database.insert(objErrorLog, false);
        }
    }
    /**
    * @description createSubMapping method to create mapping of subscription record
    * @param objQLs
    * @param mapQuoteContract
    * @param userId
    * @return objSub
    */ 
    public static SBQQ__Subscription__c createSubMapping(SBQQ__QuoteLine__c objQLs, Map<Id,Contract> mapQuoteContract, Id userId){
        SBQQ__Subscription__c objSub = new SBQQ__Subscription__c();
        objSub.CurrencyIsoCode = objQLs.CurrencyIsoCode;
        objSub.ownerId = mapQuoteContract.get(objQLs.SBQQ__Quote__c)!= null ? (mapQuoteContract.get(objQLs.SBQQ__Quote__c)).ownerId: userId;
        objSub.SBQQ__Account__c = (mapQuoteContract.get(objQLs.SBQQ__Quote__c)).AccountId!=null ? (mapQuoteContract.get(objQLs.SBQQ__Quote__c)).AccountId: null;
        objSub.PMC_CPQ_Commission__c = objQLs.PMC_CPQ_Commission__c;
        objSub.PMC_CPQ_CommissionCurrency__c = objQLs.PMC_CPQ_CommissionCurrency__c;
        objSub.SBQQ__Contract__c = mapQuoteContract.get(objQLs.SBQQ__Quote__c)!= null ? (mapQuoteContract.get(objQLs.SBQQ__Quote__c)).Id: null;
        objSub.PMC_CPQ_CropType__c = objQLs.PMC_CPQ_CropType__c;
        objSub.PMC_CPQ_CustomerOfferedPrice__c = objQLs.PMC_CPQ_CustomerOfferedPrice__c;	
        objSub.PMC_CPQ_FinalPricePerTon__c = objQLs.PMC_CPQ_FinalPricePerTon__c;	
        objSub.PMC_CPQ_PriceDueDate__c = objQLs.PMC_CPQ_PriceDueDate__c;	
        objSub.PMC_CPQ_FreightMonth__c = objQLs.PMC_CPQ_FreightMonth__c;
        objSub.PMC_CPQ_Incoterms1__c = objQLs.PMC_CPQ_Incoterms1__c;
        objSub.SBQQ__QuoteLine__c = objQLs.Id;	
        objSub.PMC_CPQ_TotalAvailableQuantity__c = objQLs.SBQQ__Quantity__c;
        objSub.SBQQ__Quantity__c = objQLs.SBQQ__Quantity__c;
        objSub.PMC_CPQ_TotalOrderedQuantity__c = 0;	
        objSub.PMC_CPQ_UnitofMeasure__c	= objQLs.PMC_CPQ_UnitofMeasure__c;
        objSub.PMC_CPQ_ModeofTransportation__c = objQLs.PMC_CPQ_ModeofTransportation__c;                	
        objSub.SBQQ__Product__c	= objQLs.SBQQ__Product__c!=null ? objQLs.SBQQ__Product__c: null;
        objSub.PMC_CPQ_LinePONumber__c = objQLs.PMC_CPQ_LinePONumber__c;
        objSub.PMC_CPQ_DeliveryStartDate__c = objQLs.PMC_CPQ_DeliveryStartDate__c;
        objSub.PMC_CPQ_DeliveryEndDate__c = objQLs.PMC_CPQ_DeliveryEndDate__c;
        objSub.PMC_CPQ_VCODeliveryRegion__c = objQLs.PMC_CPQ_VCODeliveryRegion__c;
        objSub.PMC_CPQ_FinalPricePerTonne__c = objQLs.PMC_CPQ_FinalPricePerTonne__c;
        objSub.PMC_CPQ_ContractType__c = objQLs.PMC_CPQ_ContractType__c;
        objSub.PMC_CPQ_ShipTo__c = objQLs.PMC_CPQ_ShipTo__c !=null ? objQLs.PMC_CPQ_ShipTo__c: null;
        objSub.PMC_CPQ_SoldToShipToJunction__c = objQLs.PMC_CPQ_SoldToShipToJunction__c !=null ? objQLs.PMC_CPQ_SoldToShipToJunction__c: null;
        objSub.PMC_CPQ_CustomerPrice__c = objQLs.PMC_CPQ_CustomerPrice__c;
        objSub.PMC_CPQ_PaymentTerms__c = objQLs.PMC_CPQ_PaymentTerms__c;
        objSub.PMC_CPQ_ProductLocation__c = objQLs.PMC_CPQ_ProductLocation__c != null ? objQLs.PMC_CPQ_ProductLocation__c: null;
        objSub.SBQQ__SubscriptionPricing__c = objQLs.SBQQ__SubscriptionPricing__c;
        objSub.PMC_CPQ_PaymentDate__c = objQLs.PMC_CPQ_PaymentDate__c;
        return objSub;
    }

    
    /**
    * @description finish method of batchable
    * @param objBC
    */    
    public void finish(Database.BatchableContext objBC)
    {
        System.assertEquals('Success','Success');
    }
}