/**
* @description This class will be used to handle all trigger operations on PMC_SS_Allocation__c object
* @author Aravind Chaganti
* @storynumber : GDASF-16609
* Test Class: PMC_SS_AllocationTriggerHandlerTest
*/
public with sharing class PMC_SS_AllocationTriggerHelper {
    
    //Variable to cover the exception part
    @testVisible
    private static Boolean boolThrowException = false;

    /**
     * @description This method populates the Product Location Month Key
     * @param lstAllocations List of Allocation records
     */
     public static void populateProductLocationMonthKey(List<PMC_SS_Allocation__c> lstAllocations){
        Map<String,Id>mapAllocationSummary=new Map<String,Id>();
        Set<Id>setProductIds=new Set<Id>();
        Set<Id>setLocationIds=new Set<Id>();
        for(PMC_SS_Allocation__c alloc:lstAllocations){
            setProductIds.add(alloc.PMC_SS_Product__c);
            setLocationIds.add(alloc.PMC_SS_Location__c);
        }
        for(PMC_SS_AllocationSummary__c allocationSummary:[SELECT ID,PMC_SS_ProductLocationAllocationKey__c FROM PMC_SS_AllocationSummary__c WITH SECURITY_ENFORCED]){
            mapAllocationSummary.put(allocationSummary.PMC_SS_ProductLocationAllocationKey__c,allocationSummary.Id);
        }
        Map<Id,Product2>mapProductSAPCode=new Map<Id,Product2>([SELECT ID,PMC_CPQ_SAPProductCode__c FROM PRODUCT2 WHERE ID IN :setProductIds]);
        Map<Id,Schema.Location>mapLocationSAPCode=new Map<Id,Schema.Location>([SELECT ID,PMC_CPQ_SAPLocationId__c FROM Location WHERE ID IN :setLocationIds]);
        try{
            for(PMC_SS_Allocation__c allocation:lstAllocations){
                allocation.PMC_SS_ProductLocationAllocationKey__c=allocation.PMC_SS_Product__c!=null && allocation.PMC_SS_Location__c!=null ?mapProductSAPCode.get(allocation.PMC_SS_Product__c).PMC_CPQ_SAPProductCode__c+'-'+mapLocationSAPCode.get(allocation.PMC_SS_Location__c).PMC_CPQ_SAPLocationId__c+'-'+allocation.PMC_SS_AllocationPeriod__c:null;
                allocation.PMC_SS_AllocationSummary__c=mapAllocationSummary.containsKey(allocation.PMC_SS_ProductLocationAllocationKey__c)?mapAllocationSummary.get(allocation.PMC_SS_ProductLocationAllocationKey__c):null;
            }
        }catch (QueryException objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }
    
    /**
     * @description This method restricts the Product Creation of Allocation records exceeeding Allocation Quantity on Summary
     * @param lstAllocations List of Allocation records
     * @param mapOldAllocations Old Map of Allocation records
     */
      public static void restrictAllocationExceedingQuantity(List<PMC_SS_Allocation__c> lstAllocations, Map<Id, PMC_SS_Allocation__c> mapOldAllocations){
        Set<Id>setProfileIds=new Set<Id>();
        for(Profile p:[SELECT ID FROM PROFILE WHERE NAME='API Only profile' OR NAME='System Administrator' WITH SYSTEM_MODE]){
            setProfileIds.add(p.Id);
        }
        if(setProfileIds.contains(UserInfo.getProfileId())){
            return;
        }
        else{
            checkAllocationQuantity(lstAllocations,mapOldAllocations);
        }     
    }
    /**
     * @description This method restricts the Product Creation of Allocation records exceeeding Allocation Quantity on Summary
     * @param lstAllocations List of Allocation records
     * @param mapOldAllocations old map of Allocation records
     */
    private static void checkAllocationQuantity(List<PMC_SS_Allocation__c> lstAllocations, Map<Id, PMC_SS_Allocation__c> mapOldAllocations){
        Map<String,Decimal>mapAllocationSummaryQuantity=new Map<String,Decimal>();
        Map<String,Decimal>mapAllocationQuantity=new Map<String,Decimal>();
        try{
            for(PMC_SS_AllocationSummary__c allocSummary:[SELECT ID,PMC_SS_ProductLocationAllocationKey__c,PMC_SS_TotalAllocationQuantity__c FROM PMC_SS_AllocationSummary__c WHERE PMC_SS_ProductLocationAllocationKey__c!=NULL WITH USER_MODE ORDER BY PMC_SS_ProductLocationAllocationKey__c]){
                mapAllocationSummaryQuantity.put(allocSummary.PMC_SS_ProductLocationAllocationKey__c,allocSummary.PMC_SS_TotalAllocationQuantity__c);
            }
            mapAllocationQuantity=getMapAllocationQuantity();
            for(PMC_SS_Allocation__c alloc:lstAllocations){
                PMC_SS_Allocation__c oldAllocation=mapOldAllocations!=null?mapOldAllocations.get(alloc.Id):null;
                Decimal decCumulativeQuantity=mapAllocationSummaryQuantity.containsKey(alloc.PMC_SS_ProductLocationAllocationKey__c)?mapAllocationSummaryQuantity.get(alloc.PMC_SS_ProductLocationAllocationKey__c):null;
                Decimal decTotalQuantity=null;
                decTotalQuantity=oldAllocation!=null && mapAllocationQuantity.containsKey(alloc.PMC_SS_ProductLocationAllocationKey__c)?mapAllocationQuantity.get(alloc.PMC_SS_ProductLocationAllocationKey__c)+alloc.PMC_SS_AllocatedActualQuantity__c-oldAllocation.PMC_SS_AllocatedActualQuantity__c:mapAllocationQuantity.get(alloc.PMC_SS_ProductLocationAllocationKey__c)+alloc.PMC_SS_AllocatedActualQuantity__c; 
                throwvalidationErrorMessage(decCumulativeQuantity,decTotalQuantity,alloc);
            }
            
        }catch (QueryException objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }
    /**
     * @description This method returns the map of allocation quantity for a product location allocation period
     * @return Map<String,Decimal> 
     */
    private static Map<String,Decimal> getMapAllocationQuantity(){
        Map<String,Decimal>mapAllocationQuantity=new Map<String,Decimal>();
        for(PMC_SS_Allocation__c allocation:[SELECT ID,PMC_SS_ProductLocationAllocationKey__c,PMC_SS_AllocatedActualQuantity__c FROM PMC_SS_Allocation__c WHERE PMC_SS_ProductLocationAllocationKey__c!=NULL WITH USER_MODE ORDER BY PMC_SS_ProductLocationAllocationKey__c]){
            if(!mapAllocationQuantity.containsKey(allocation.PMC_SS_ProductLocationAllocationKey__c)){
                mapAllocationQuantity.put(allocation.PMC_SS_ProductLocationAllocationKey__c,allocation.PMC_SS_AllocatedActualQuantity__c);
            }
            else
            {
                Decimal aggregateofAllocatedQuantity=mapAllocationQuantity.get(allocation.PMC_SS_ProductLocationAllocationKey__c)+allocation.PMC_SS_AllocatedActualQuantity__c;
                mapAllocationQuantity.put(allocation.PMC_SS_ProductLocationAllocationKey__c,aggregateofAllocatedQuantity);
            }     
        }
        return mapAllocationQuantity;
    }
    /**
     * @description This method restricts the Product Creation of Allocation records exceeeding Allocation Quantity on Summary
     * @param decCumulativeQuantity Decimal Value of Cumulative Quantity
     * @param decTotalQuantity Decimal Value of Total Quantity
     * @param allocation Allocation record
     */
    private static void throwvalidationErrorMessage(Decimal decCumulativeQuantity, Decimal decTotalQuantity, PMC_SS_Allocation__c allocation){
        if((decCumulativeQuantity!=null && decTotalQuantity!=null) && decCumulativeQuantity<decTotalQuantity){
            allocation.addError(System.Label.PMC_SS_AllocationErrorMessage);
        }
    }
    /**
    * @description This method restricts the Product Creation of Allocation records exceeeding Allocation Quantity on Summary
    * @param lstAllocations List of Allocation records
    */
     public static void createAllocationSummary(List<PMC_SS_Allocation__c> lstAllocations){
        Set<Id>setProfileIds=new Set<Id>();
        Set<String>setProductLocationMonthKeys=new Set<String>();
        Map<String,PMC_SS_AllocationSummary__c>mapAllocationSummary=new Map<String,PMC_SS_AllocationSummary__c>();
        
        Decimal decimalTotalQuantity;
        try{
            for(Profile p:[SELECT ID FROM PROFILE WHERE NAME!='API Only profile' AND NAME!='System Administrator' WITH SYSTEM_MODE]){
                setProfileIds.add(p.Id);
            }
            if(setProfileIds.contains(UserInfo.getProfileId())){
                return;
            }
            setProductLocationMonthKeys = PMC_SS_AllocationTriggerHelperExtension.createProductLocationKeySet(lstAllocations);
            
            for(PMC_SS_Allocation__c allocation:[SELECT ID,PMC_SS_ProductLocationAllocationKey__c,PMC_SS_Product__c,PMC_SS_Location__c,PMC_SS_AllocationPeriod__c,PMC_SS_AllocatedActualQuantity__c FROM PMC_SS_Allocation__c WHERE PMC_SS_ProductLocationAllocationKey__c IN :setProductLocationMonthKeys WITH SECURITY_ENFORCED]){
                PMC_SS_AllocationSummary__c allocSummary=new PMC_SS_AllocationSummary__c();
                if(!mapAllocationSummary.containsKey(allocation.PMC_SS_ProductLocationAllocationKey__c)){
                    allocSummary.PMC_SS_ProductLocationAllocationKey__c=allocation.PMC_SS_ProductLocationAllocationKey__c;
                    allocSummary.PMC_SS_Product__c=allocation.PMC_SS_Product__c;
                    allocSummary.PMC_SS_Location__c=allocation.PMC_SS_Location__c;
                    allocSummary.PMC_SS_AllocationPeriod__c=allocation.PMC_SS_AllocationPeriod__c; 
                    allocSummary.PMC_SS_TotalAllocationQuantity__c=allocation.PMC_SS_AllocatedActualQuantity__c;
                    mapAllocationSummary.put(allocSummary.PMC_SS_ProductLocationAllocationKey__c,allocSummary);
                }
                else{
                    allocSummary=mapAllocationSummary.get(allocation.PMC_SS_ProductLocationAllocationKey__c);
                    decimalTotalQuantity=allocSummary.PMC_SS_TotalAllocationQuantity__c+allocation.PMC_SS_AllocatedActualQuantity__c;
                    mapAllocationSummary.get(allocation.PMC_SS_ProductLocationAllocationKey__c).PMC_SS_TotalAllocationQuantity__c=decimalTotalQuantity;
                }
            }
            if(!mapAllocationSummary.isEmpty()){
                upsert mapAllocationSummary.values() PMC_SS_ProductLocationAllocationKey__c;
            }
            
        }catch (QueryException objQueryException) {
            PMC_ErrorLogClass.processException(objQueryException);
        }
    }
    
}