/**
* @description This class will be used to handle all triggers on Opportunity object.
* @author Nandini Dey
* @storynumber GDASF-2588
*/
public with sharing class PMC_OpportunityTriggerHelper {
    
    /**
    * @description This method will be used to update Analysis Stage Date field whenever Opportunity stage name is updated to "Analysis".
    * @param lstNewOpportunities - List of New Opportunities.
    * @param mapNewOpportunities - Map of Updated Opportunities.
    * @param mapOldOpportunities - Map of old values of Opportunities.
    */
    public static void updateAnalysisStageDate(List<Opportunity> lstNewOpportunities, Map<Id, Opportunity> mapNewOpportunities, Map<Id, Opportunity> mapOldOpportunities) {
        for(Opportunity opp : lstNewOpportunities) {
            //below condition will be executed for Update context of the trigger
            if(mapOldOpportunities != null && mapOldOpportunities.get(opp.Id).StageName != PMC_SS_ConstantClass.OPPORTUNITY_ANALYSIS_STAGE && mapNewOpportunities.get(opp.Id).StageName == PMC_SS_ConstantClass.OPPORTUNITY_ANALYSIS_STAGE) {
                opp.PMC_SS_AnalysisStageDate__c = System.today();
            }
            //below condition will be executed for Insert context of the trigger
            if(mapOldOpportunities == null && opp.StageName == PMC_SS_ConstantClass.OPPORTUNITY_ANALYSIS_STAGE) {
                opp.PMC_SS_AnalysisStageDate__c = System.today();
            }
        }                   
    }
    
    /**
    * @description This method will be used to update the Opportunity Type as Indirect Sales when the Opportunity owner is a Retailer(user with DH Buyer Profile).
    * @param lstNewOpportunities - List of New Opportunities.
    */
    public static void updateTypeIndirectSales(List<Opportunity> lstNewOpportunities) {
        //map of OwnerId and Profile name
        Map<ID, String> mapNewOwnerIdProfileName = new Map<ID, String>();
        List<User> lstNewOwner = new List<User>();
        //getting the ownerId of the Triggered Opportunities.
        for(Opportunity objOpportunity: lstNewOpportunities) {
            mapNewOwnerIdProfileName.put(objOpportunity.OwnerId,'');
        }
        
        //Getting the Profiles of the triggered Opportunity Owners
        lstNewOwner = [Select Id, Profile.Name from User where Id In :mapNewOwnerIdProfileName.keySet() WITH SYSTEM_MODE];
        for(User objOwnr: lstNewOwner){
            mapNewOwnerIdProfileName.put(objOwnr.Id,objOwnr.Profile.Name);
        }

        for(Opportunity objOpportunity: lstNewOpportunities) { 
            if((mapNewOwnerIdProfileName.get(objOpportunity.OwnerId) == PMC_SS_ConstantClass.DH_BUYER_PROFILE)||(mapNewOwnerIdProfileName.get(objOpportunity.OwnerId) == PMC_SS_ConstantClass.DH_SUPERBUYER_PROFILE) ) {
                objOpportunity.Type = PMC_SS_ConstantClass.OPPORTUNITY_TYPE_INDIRECT_SALES;
            }
        }                   
    }
}