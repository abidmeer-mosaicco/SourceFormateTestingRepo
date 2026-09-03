/**
 * @description       : Batch Class for Product Onboarding
 * @author            : Rohan Undale
 * @last modified on  : 01-08-2024
 * @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public with sharing class PMC_DH_ProductOnboardingBatch implements Database.Batchable<sObject> {
    private final static string PRODUCT_MICRONUTRIENTS_FIELDS = 'PRODUCT_MICRONUTRIENTS_FIELDS';
    /**
     * @description method to store Product Ids
     * @return Set<String> 
     */
    //public static Set<String> setProdIdsChunk;
    /**
    * @description Start method of batchable
    * @param objBatchableContext
    * @return  Database.QueryLocator
    * @date 10-20-2023
    */
    public Database.QueryLocator start(Database.BatchableContext objBatchableContext) {
        
        PMC_DH_Store_Configuration__mdt micorNutriConfig = [SELECT Id,PMC_DH_FieldsAPIName__c, DeveloperName from PMC_DH_Store_Configuration__mdt Where DeveloperName=:PRODUCT_MICRONUTRIENTS_FIELDS];
        Map<String,String> mpdata= (Map<String,String>)JSON.deserialize(micorNutriConfig.PMC_DH_FieldsAPIName__c, Map<String,String>.Class);
        
        String query='SELECT Id, Name, PMC_DH_isProcessed__c, PMC_CPQ_ProductSegment__c,PMC_CPQ_ProductTypes__c,PMC_CPQ_ProductFamily__c, PMC_CPQ_ProductSubFamily__c,';
            query+=' PMC_DH_Micronutrients__c, PMC_DH_Nitrogen__c, PMC_DH_Phosphorous__c, PMC_DH_Potassium__c, PMC_CPQ_Nitrogen__c, PMC_CPQ_Phosphorous__c, PMC_CPQ_Potassium__c';
        if(!mpdata.isEmpty()){
            query += ', '+String.join(mpdata.KeySet(), ', ');
        }
        query+=' FROM Product2 WHERE PMC_DH_isProcessed__c=FALSE AND (PMC_CPQ_ProductSegment__c!=NULL AND PMC_CPQ_ProductTypes__c!=NULL AND PMC_CPQ_ProductFamily__c!=NULL AND PMC_CPQ_ProductSubFamily__c!=NULL ) WITH SYSTEM_MODE';
        
        
        return Database.getQueryLocator(query);
        /*return Database.getQueryLocator(
            [SELECT Id, Name, PMC_DH_isProcessed__c, 
            PMC_CPQ_ProductSegment__c,PMC_CPQ_ProductTypes__c,PMC_CPQ_ProductFamily__c,PMC_CPQ_ProductSubFamily__c,
             PMC_DH_Nitrogen__c, PMC_DH_Phosphorous__c, PMC_DH_Potassium__c, PMC_CPQ_Nitrogen__c, PMC_CPQ_Phosphorous__c, PMC_CPQ_Potassium__c
             FROM Product2 
            WHERE PMC_DH_isProcessed__c=FALSE and (PMC_CPQ_ProductSegment__c!=null 
            and PMC_CPQ_ProductTypes__c!=null and PMC_CPQ_ProductFamily__c!=null and PMC_CPQ_ProductSubFamily__c!=null ) //for proper data-alignment
            WITH SYSTEM_MODE
            ]);*/
    }
    /**
    * @description execute method of batchable
    * @param objBatchableContext
    * @param lstProduct
    * @date 10-20-2023
    */
    public void execute(Database.BatchableContext objBatchableContext , List<Product2> lstProduct){
        PMC_DH_ProductOnboardingBatchHelper.executeHelper(lstProduct);
    }
    /**
    * @description finish method of batchable
    * @param objBatchableContext
    * @date 10-20-2023
    */
    public void finish(Database.BatchableContext objBatchableContext){
       // here it will call the batch indexing Job
        Database.executeBatch(new PMC_DH_UpdateEntitlementPolicyBatch());
    }


    

  
     /**
    * @description method to get the All Micro Nutrinets 
    * @param pro
    * @return String
    * @author Sugunakar ROuthu
    * @date 05-03-2024
    */
    
    public static String populateMicroNutrinents(Product2 pro){
        List<String> lsteligibleNutirents = new List<String>();
        PMC_DH_Store_Configuration__mdt micorNutriConfig = [SELECT Id,PMC_DH_FieldsAPIName__c, DeveloperName from PMC_DH_Store_Configuration__mdt Where DeveloperName=:PRODUCT_MICRONUTRIENTS_FIELDS WITH USER_MODE];
        Map<String,String> mpdata= (Map<String,String>)JSON.deserialize(micorNutriConfig.PMC_DH_FieldsAPIName__c, Map<String,String>.Class);
        for(String mn : mpdata.KeySet()){
            Decimal decPercentage = (Decimal)pro.get(mn);
            if( decPercentage > 0){
                lsteligibleNutirents.add(mpdata.get(mn));
            }
        }
        return String.join(lsteligibleNutirents,';');
    } 

}