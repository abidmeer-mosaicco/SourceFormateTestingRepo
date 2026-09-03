/**
* @description This class will be used to handle all trigger operations on PMC_SS_Allocation__c object
* @author Aravind Chaganti
* @storynumber : GDASF-16609 
* Test Class: PMC_SS_AllocationTriggerHandlerTest
*/
public with sharing class PMC_SS_AllocationTriggerHelperExtension {
    /**
     * @description This populates the Product, Location, Allocation Period on Allocation from Allocation Summary
     * @param lstAllocations List of Allocation records
    */
    public static void populateFieldsOnAllocation(List<PMC_SS_Allocation__c> lstAllocations){
        Set<Id> setAllocationSummaryIds= new Set<Id>();
        Map<Id,PMC_SS_AllocationSummary__c> mapAllocationSummary=new Map<Id,PMC_SS_AllocationSummary__c>();
        for(PMC_SS_Allocation__c alloc:lstAllocations){
            if(alloc.PMC_SS_AllocationSummary__c!=null){
                setAllocationSummaryIds.add(alloc.PMC_SS_AllocationSummary__c);
            }
        }
        for(PMC_SS_AllocationSummary__c allocSummary:[SELECT ID, PMC_SS_Product__c, PMC_SS_Location__c,PMC_SS_AllocationPeriod__c FROM PMC_SS_AllocationSummary__c WHERE ID IN :setAllocationSummaryIds WITH SECURITY_ENFORCED]){
            mapAllocationSummary.put(allocSummary.Id,allocSummary);
        }
        //Map<Id,PMC_SS_AllocationSummary__c> mapAllocationSummary=new Map<Id,PMC_SS_AllocationSummary__c>([SELECT ID, PMC_SS_Product__c, PMC_SS_Location__c, PMC_SS_AllocationPeriod__c FROM PMC_SS_AllocationSummary__c WITH SECURITY_ENFORCED WHERE ID IN :setAllocationSummaryIds]);
        for (PMC_SS_Allocation__c alloc:lstAllocations){
            if(alloc.PMC_SS_AllocationSummary__c!=null){
                alloc.PMC_SS_AllocationPeriod__c=mapAllocationSummary.get(alloc.PMC_SS_AllocationSummary__c).PMC_SS_AllocationPeriod__c;
                alloc.PMC_SS_Product__c=mapAllocationSummary.get(alloc.PMC_SS_AllocationSummary__c).PMC_SS_Product__c;
                alloc.PMC_SS_Location__c=mapAllocationSummary.get(alloc.PMC_SS_AllocationSummary__c).PMC_SS_Location__c;
            }
        }
    }
    
    /**
     * @description Creates a map of product location and period keys of allocations.
     * @param lstAllocations List of Allocation records
     * @return Set<String>
    */
    public static Set<String> createProductLocationKeySet(List<PMC_SS_Allocation__c> lstAllocations){
        Set<String>setProductLocationMonthKeys=new Set<String>();
        
        for(PMC_SS_Allocation__c alloc:lstAllocations){
            if(alloc.PMC_SS_ProductLocationAllocationKey__c!=null){
                setProductLocationMonthKeys.add(alloc.PMC_SS_ProductLocationAllocationKey__c);
            }    
        }
        
        return setProductLocationMonthKeys;
    }
    
}