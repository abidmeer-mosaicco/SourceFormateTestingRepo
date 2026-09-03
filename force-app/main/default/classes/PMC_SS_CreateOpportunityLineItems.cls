/**
* @description This class will be used to create Opportunity Line Items for Differential Opportunity.
* @author Chetna Nihalani
* @storynumber GDASF-10431
* @TestClass PMC_SS_CreateOpportunityLineItemsTest
*/
public with sharing class PMC_SS_CreateOpportunityLineItems {

    public Static Map<Id, Decimal> mapProductIdQuantity = new Map<Id, Decimal>();
    public Static Map<Id, Id> mapSalesAgreementProductIdProductId = new Map<Id, Id>();
    public Static Map<Id, Decimal> mapProductIdSalesPrice = new Map<Id, Decimal>();
    public Static Map<Id, Id> mapProductIdPricebookEntryId = new Map<Id, Id>();   
    public Static String strOpportunityProductInsertionStatus='Success'; 
    
    /**
    * @description This method is invoked from the flow - PMC SS Differential Opportunity Flow 
    * @param lstCreateFlowMap - Pass invocable variabes to CreateMapInputs method
    * @return This method will return list of string used to check if differential opportunity was created successfully 
    */ 

    @InvocableMethod(label='Create Map')
    public static List<String> createMap(List<CreateMapInputs> lstCreateFlowMap) {

        // Check if Opportunity Product List is not null //
        if(lstCreateFlowMap[0].lstOpportunityLineItem != null) {

            //Loop through Opportunity Line Items //
            for(OpportunityLineItem sObj : lstCreateFlowMap[0].lstOpportunityLineItem){
                
                Id idProduct = (ID)sObj.get('Product2Id');
                Decimal decProductQuantity = (Decimal)sObj.get('Quantity');

                //If product exists in Map, add the quantities //
                if(mapProductIdQuantity.containsKey(idProduct)) {
                    mapProductIdQuantity.put(idProduct, mapProductIdQuantity.get(idProduct) + decProductQuantity);
                } else {

                    // If product does not exist in Map, insert Product Id and quantity //
                    mapProductIdQuantity.put(idProduct, decProductQuantity);
                } 
            }
        }      

        // Process Sales Agreement Products and create maps // 
        processSalesAgreementProducts(lstCreateFlowMap[0].lstSalesAgreementProducts);
    
        // Get differential quantity and prepare map//                
        processSalesAgreementSchedules(lstCreateFlowMap[0].lstSalesAgreementProductSchedules);  

        // Create Opportunity Products to be added to differential opportunity//
        createOpportunityProducts(mapProductIdQuantity,lstCreateFlowMap[0].idOpportunity);
        
    return new List<String>{strOpportunityProductInsertionStatus};
}

    /**
    * @description Process Sales Agreement Products to create Maps of Sales Agreement Product Id x Product Id , Product Id x Sales Price and Product Id x PricebookEntry Id
    * @param lstSalesAgreementProducts - Related Sales Agreement Products
    */

    public static void processSalesAgreementProducts(List<SalesAgreementProduct> lstSalesAgreementProducts) {

    // Loop through related Sales Agreement Products //
    for(SalesAgreementProduct objSalesAgreementProduct : lstSalesAgreementProducts) {

        // Check if map doesn't contain key and assign Sales Price and Pricebook //
        if(!mapSalesAgreementProductIdProductId.containsKey(objSalesAgreementProduct.Id)) {
            mapSalesAgreementProductIdProductId.put(objSalesAgreementProduct.Id, objSalesAgreementProduct.ProductId);
            mapProductIdSalesPrice.put((Id)objSalesAgreementProduct.get('ProductId'), (Decimal)objSalesAgreementProduct.get('SalesPrice'));
            mapProductIdPricebookEntryId.put((Id)objSalesAgreementProduct.get('ProductId'), (Id)objSalesAgreementProduct.get('PricebookEntryId'));
        }
    }
}

    /**
    * @description Process Sales Agreement Product Schedules to get final map of Product Id x Differential Quantity
    * @param lstSalesAgreementProductSchedules - Related Sales Agreement Product Schedules
    */

    public static void processSalesAgreementSchedules(List<SalesAgreementProductSchedule> lstSalesAgreementProductSchedules) {                
    Integer intProductQuantity =0 ;
    Integer intPlannedQuantity;

    // Loop through all the related Sales Agreement schedules // 
    for(SalesAgreementProductSchedule objSalesAgreementProductSchedule : lstSalesAgreementProductSchedules) {

        // Check if Product Id already present in Map and assign planned quantity//
        if(mapSalesAgreementProductIdProductId.containsKey(objSalesAgreementProductSchedule.SalesAgreementProductId)) {
            intPlannedQuantity = objSalesAgreementProductSchedule.PlannedQuantity;     

            // Check if map is not empty and get product quantity //
            if(!mapProductIdQuantity.isEmpty() ) {                                   
                intProductQuantity = (Integer)mapProductIdQuantity.get(mapSalesAgreementProductIdProductId.get(objSalesAgreementProductSchedule.SalesAgreementProductId));        
                intProductQuantity = intProductQuantity != null ? intProductQuantity : 0;                                        
            }   

            // Calculate differential of Planned Quantit and Delivered Quantity //
            mapProductIdQuantity.put(mapSalesAgreementProductIdProductId.get(objSalesAgreementProductSchedule.SalesAgreementProductId), intPlannedQuantity - intProductQuantity);                              
        }
    }        
}

    /**
    * @description Create Opportunity Products and assign values
    * @param mapProductIdQuantity - Map of Product Id and Quantity
    * @param opportunityId - Opportunity Id of newly created Opportunity passed from Flow
    */
    
    public static void createOpportunityProducts(Map<Id, Decimal> mapProductIdQuantity,Id opportunityId) {
    OpportunityLineItem objOpportunityLineItemToCreate;
    List<OpportunityLineItem> lstOpportunityLineItems = new List<OpportunityLineItem>();          

    // Loop through Map keys i.e Products and create Opportunity Products //
    for( Id idProduct : mapProductIdQuantity.keySet()) {
        objOpportunityLineItemToCreate = new OpportunityLineItem();
        objOpportunityLineItemToCreate.Product2Id = idProduct;
        objOpportunityLineItemToCreate.Quantity = mapProductIdQuantity.get(idProduct);

        // If product quantity is null or zero, don't create Opportunity Product // 
        if (objOpportunityLineItemToCreate.Quantity<=0){
            continue;
        }

        //Assign Opportunity Id//
        objOpportunityLineItemToCreate.OpportunityId = opportunityId;

        // Assign Sales Price// 
        objOpportunityLineItemToCreate.UnitPrice = mapProductIdSalesPrice.get(idProduct);

        // Assign PricebookEntry Id //
        objOpportunityLineItemToCreate.PricebookEntryId = mapProductIdPricebookEntryId.get(idProduct);

        //Add to list //
        lstOpportunityLineItems.add(objOpportunityLineItemToCreate);
    }
    try{

        // Insert records in database //
        Database.SaveResult[] srList= Database.insert(lstOpportunityLineItems,true);
    for (Database.SaveResult sr : srList) {
        if (!sr.isSuccess()) {
            strOpportunityProductInsertionStatus='Failed';
            break;
        }
    }
    }catch(DmlException objDmlException) {
    PMC_ErrorLogClass.processException(objDmlException);
}
}


    /**
    * @description This class will be used to define invocable variables referenced in PMC SS Differential Opportunity Flow.
    */   

    //Inputs for Invocable method passed from flow //
    public class CreateMapInputs{
        @InvocableVariable
        public List<OpportunityLineItem> lstOpportunityLineItem;

        @InvocableVariable
        public List<SalesAgreementProductSchedule> lstSalesAgreementProductSchedules;

        @InvocableVariable
        public List<SalesAgreementProduct>  lstSalesAgreementProducts;

        @InvocableVariable
        public Id idOpportunity;
}
}