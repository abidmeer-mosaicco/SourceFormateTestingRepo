/**
 * @description This test class will be used to cover all the methods of PMC_SS_TechnicalBulletinController
 * @author Vedashri
 */

@isTest(seeAllData = false)
public with sharing class PMC_SS_TechnicalBulletinControllerTest {
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
                ContentVersion objContentVersion = new ContentVersion(
                    Title = 'Some document',
                    PathOnClient = 'some document.png',
                    VersionData = Blob.valueOf('Some document')
                );
                insert objContentVersion;
                
                ContentDocument objContentDocument = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :objContentVersion.Id];

                List<knowledge__kav> lstKnowlegeArticle = new List<knowledge__kav>();
                List<ContentDocumentLink> lstConDocLinkToInsert = new List<ContentDocumentLink>();
                String strCreateDraft = '';
                for(knowledge__kav objKnowledge : [SELECT Id,UrlName,KnowledgeArticleId FROM knowledge__kav])
                {
                    lstKnowlegeArticle.add(objKnowledge);
                    if(objKnowledge.UrlName == 'DraftTestClassArticle1') {
                        strCreateDraft =objKnowledge.KnowledgeArticleId;
                        ContentDocumentLink objContentDocumentLink = new ContentDocumentLink(ContentDocumentId = objContentDocument.Id,LinkedEntityId = objKnowledge.Id);
                        lstConDocLinkToInsert.add(objContentDocumentLink);//insert objContentDocumentLink;
                    }
                }
                insert lstConDocLinkToInsert;


                for(knowledge__kav objKnowledge : lstKnowlegeArticle)
                {
                   KbManagement.PublishingService.publishArticle(objKnowledge.KnowledgeArticleId, true);
                }
            
                PMC_SS_TechnicalBulletinController.getAllKnowledgeArticles();
                System.assertEquals(true, PMC_SS_TechnicalBulletinController.getAllKnowledgeArticles().size()>0, 'Check article size');               
            }
        }
        Test.stopTest();
    }    
}