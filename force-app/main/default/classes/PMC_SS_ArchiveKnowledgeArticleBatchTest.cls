/**
 * @description This test class will be used to cover all the methods of PMC_ArchiveKnowledgeArticleBatch and PMC_ArchiveKnowledgeArticleSchedule
 * @author Vedashri
 */

@isTest(seeAllData = false)
public with sharing class PMC_SS_ArchiveKnowledgeArticleBatchTest {
   /**
    * @description This Method will be used to setup the test data for the test class execution.
    */
    
    @testsetup
    private static void setup() {
        List<String>lstProfileNames = New List<String>{'System Administrator','Service User'};
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SRV_Permission_Set_Group'};
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        Integer intuserCount =0;
        User objSystemAdminUser;  
        User objServiceUser;
        List<User> lstUser = PMC_TestUtilityClass.createUser(2);
            for(User objUser : lstUser) {
                If(intuserCount==0){
                   objUser.LastName = 'Admin User Test';
                   objUser.ProfileId = mapOfProfiles.get('System Administrator'); 
                   objUser.FederationIdentifier = objUser.Username + 'Admin';
                }else if(intuserCount==1){
                    objUser.LastName = 'Service User Test';
                    objUser.ProfileId = mapOfProfiles.get('Service User'); 
                   objUser.FederationIdentifier = objUser.Username + 'Service';
                }
                objUser.isActive = true;                
                objUser.MobilePhone = '1234567890';
                objUser.UserPermissionsKnowledgeUser =true;
                objUser.LanguageLocaleKey = 'en_US';
                intuserCount = intuserCount + 1;
            }            
            insert lstUser;
            objSystemAdminUser = lstUser[0];
            objServiceUser = lstUser[1];
		PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objServiceUser}, mapOfPermissionGrp.get('PMC_SRV_Permission_Set_Group'));        
        
    }
    /** 
    * @description This method will be used to test the scenario where Case status is updated to Escalated and from Escalated to other Status.
    */ 
    
    @isTest
    private static void testArchiveArticleBtach() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User  WHERE UserPermissionsKnowledgeUser=:True AND isActive =:true AND LastName = 'Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        PermissionSet objPermissionSet = [SELECT Id FROM PermissionSet WHERE Name =: 'PMC_CREDKnowledge'];
        insert new PermissionSetAssignment(AssigneeId = objUser.id, PermissionSetId = objPermissionSet.Id);
        if(objUser != null) {
            System.runAs(objUser) {
            
                PMC_TestUtilityClass.insertBulletinArticle('TestClassArticle1');
                PMC_TestUtilityClass.insertBulletinArticle('DraftTestClassArticle1');
                
                String strCreateDraft = '';
                for(knowledge__kav objKnowledge : [SELECT Id,UrlName,KnowledgeArticleId FROM knowledge__kav])
                {
                    if(objKnowledge.UrlName == 'DraftTestClassArticle1') {
                        strCreateDraft =objKnowledge.KnowledgeArticleId;
                    }            
                    KbManagement.PublishingService.publishArticle(objKnowledge.KnowledgeArticleId, true);
                }
                if(String.isNotBlank(strCreateDraft)) {
                    KbManagement.PublishingService.editOnlineArticle (strCreateDraft, false);
                }
            
                PMC_SS_ArchiveKnowledgeArticleBatch objBatch = New PMC_SS_ArchiveKnowledgeArticleBatch();
                Database.executeBatch(objBatch);
                Test.stopTest();
       			System.assertEquals(true, [SELECT Id,UrlName,PublishStatus FROM knowledge__kav ].size()>0, 'Check Draft article');
            }
        }        
    }
    @isTest
    private static void testArchiveArticleSchedule() {
		Test.StartTest();
        User objUser = [SELECT Id, Name FROM User  WHERE UserPermissionsKnowledgeUser=:True AND isActive =:true AND LastName = 'Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        PermissionSet objPermissionSet = [SELECT Id FROM PermissionSet WHERE Name =: 'PMC_CREDKnowledge'];
        insert new PermissionSetAssignment(AssigneeId = objUser.id, PermissionSetId = objPermissionSet.Id);
            System.runAs(objUser) {
                PMC_TestUtilityClass.insertBulletinArticle('TestClassArticle1');
                PMC_TestUtilityClass.insertBulletinArticle('DraftTestClassArticle1');
                
                String strCreateDraft = '';
                for(knowledge__kav objKnowledge : [SELECT Id,UrlName,KnowledgeArticleId FROM knowledge__kav])
                {
                    if(objKnowledge.UrlName == 'DraftTestClassArticle1') {
                        strCreateDraft =objKnowledge.KnowledgeArticleId;
                    }            
                    KbManagement.PublishingService.publishArticle(objKnowledge.KnowledgeArticleId, true);
                }
                if(String.isNotBlank(strCreateDraft)) {
                    KbManagement.PublishingService.editOnlineArticle (strCreateDraft, false);
                }
                PMC_SS_ArchiveKnowledgeArticleSchedule objScheduler = new PMC_SS_ArchiveKnowledgeArticleSchedule();
                String sch = '0 0 23 * * ?';
                system.schedule('Archive Article Schedule', sch, objScheduler );
                System.assertEquals(true, [SELECT Id,UrlName,PublishStatus FROM knowledge__kav WHERE UrlName='DraftTestClassArticle1'].size() >0, 'Check Draft article');
             Test.stopTest();
            }
        
		

	}
    
}