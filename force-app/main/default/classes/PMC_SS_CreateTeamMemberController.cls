/**
* @description Controller used to create Team Member Records.
* @author Kailas Shimpi
* @storynumber GDASF-14672
**/

public without sharing class PMC_SS_CreateTeamMemberController {
    
    @TestVisible 
        public static Boolean boolNotTestException = true;
    
    /**
	* @description Method to create Account Team Member Records
	* @param mapConvertedAccIdWithDealOwner - Map of Converted Account IDs and Deal Owner from Lead Record
	*/
    public static void createAccountTeamMember(Map<Id,Id> mapConvertedAccIdWithDealOwner) {
        try {
            //List to store AccountTeamMember
            List<AccountTeamMember> lstAccTeams = new List<AccountTeamMember>();
            //Object to map account team member values
            AccountTeamMember objAccTeamMem;
            
            //Iterate through the list of Accounts that created from the Lead conversion
            for (Account objAcc : [SELECT Id, OwnerId FROM Account WHERE Id IN : mapConvertedAccIdWithDealOwner.keySet() WITH SECURITY_ENFORCED]) {
                objAccTeamMem = new AccountTeamMember();
                if((Test.isRunningTest() && boolNotTestException) || (!Test.isRunningTest())){
                    objAccTeamMem.UserId = mapConvertedAccIdWithDealOwner.get(objAcc.Id);
                }
                objAccTeamMem.TeamMemberRole = PMC_SS_ConstantClass.TEAM_MEMBER_ROLE_SDR;
                objAccTeamMem.AccountId  = objAcc.Id;
                objAccTeamMem.AccountAccessLevel = PMC_SS_ConstantClass.TEAM_MEMBER_ACCESS_LEVEL_EDIT;
                objAccTeamMem.ContactAccessLevel = PMC_SS_ConstantClass.TEAM_MEMBER_ACCESS_LEVEL_READ;
                lstAccTeams.add(objAccTeamMem);
            }
            //Insert Account Team
            if (Schema.sObjectType.AccountTeamMember.isCreateable() && !lstAccTeams.isEmpty()) {
                insert lstAccTeams;
            }
        } catch(DmlException objDmlException) {
            PMC_ErrorLogClass.processException(objDmlException);
        }
    }
    
    /**
	* @description Method to create Opportunity Team Member Records
	* @param mapConvertedOppIdWithDealOwner - Map of Converted Opportunity IDs and Deal Owner from Lead Record
	*/
    public static void createOpportunityTeamMember(Map<Id,Id> mapConvertedOppIdWithDealOwner) {
        try {
            //List to store OpportunityTeamMember
            List<OpportunityTeamMember> lstOppTeams = new List<OpportunityTeamMember>();
            //Object to map opportunity team member values
            OpportunityTeamMember objOppTeamMem;
            
            //Iterate through the list of Opportunities that created from the Lead conversion
            for (Opportunity objOpp : [SELECT Id, OwnerId FROM Opportunity WHERE Id IN : mapConvertedOppIdWithDealOwner.keySet() WITH SECURITY_ENFORCED]) {
                objOppTeamMem = new OpportunityTeamMember();
                
                objOppTeamMem.TeamMemberRole = PMC_SS_ConstantClass.TEAM_MEMBER_ROLE_SDR;
                objOppTeamMem.OpportunityId = objOpp.Id;
                if((Test.isRunningTest() && boolNotTestException) || (!Test.isRunningTest())){
                    objOppTeamMem.UserId = mapConvertedOppIdWithDealOwner.get(objOpp.Id);
                }
                objOppTeamMem.OpportunityAccessLevel = PMC_SS_ConstantClass.TEAM_MEMBER_ACCESS_LEVEL_EDIT;
                lstOppTeams.add(objOppTeamMem);
            }
            //Insert Opportunity Team Members
            if(Schema.sObjectType.OpportunityTeamMember.isCreateable() && !lstOppTeams.isEmpty()) {
                insert lstOppTeams;
            }
        } catch(DmlException objDmlException) {
            PMC_ErrorLogClass.processException(objDmlException);
        }
    }
}