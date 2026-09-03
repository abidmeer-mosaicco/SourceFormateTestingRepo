/*
* This class is the test class for PMC_CPQ_ApprovalGroupEmailSenderClass.
* @author Jeyanthi Muthaiah
* @storynumber GDASF-10718 S14
*/
@isTest(seeAllData=false)
public class PMC_CPQ_ApprovalGroupEmailSenderTest  {
    
 /**
    * @description This Method will be used to setup the test data for the test class execution.
   */
     @testsetup
    private static void setup() {
        
        List<String>lstProfileNames = New List<String>{'System Administrator','Sales User'};
        List<userRole> userRoleName= [SELECT Id FROM userRole WHERE Name = 'Service Director'];
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SLS_Permission_Set_Group'};
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        Integer intuserCount =0;
        User objSystemAdminUser;  
        User objSalesUser;
        List<User> lstUser = PMC_TestUtilityClass.createUser(2);
            for(User objUser : lstUser) {
                If(intuserCount==0){
                   objUser.LastName = 'Admin User Test';
                   objUser.ProfileId = mapOfProfiles.get('System Administrator'); 
                   objUser.FederationIdentifier = objUser.Username + 'Admin';
                   objUser.UserRoleId=userRoleName[0].id;
                }else if(intuserCount==1){
                    objUser.LastName = 'Sales User Test';
                    objUser.ProfileId = mapOfProfiles.get('Sales User'); 
                   objUser.FederationIdentifier = objUser.Username + 'Sales';
                }
                objUser.isActive = true;                
                objUser.MobilePhone = '1234567890';
                objUser.UserPermissionsKnowledgeUser =true;
                objUser.LanguageLocaleKey = 'en_US';
                intuserCount = intuserCount + 1;
            }            
            insert lstUser;
            objSystemAdminUser = lstUser[0];
            objSalesUser = lstUser[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSalesUser}, mapOfPermissionGrp.get('PMC_SLS_Permission_Set_Group'));    
    }
    /* 
* This method will be used to cover qLines and sendApprovalGroupEmail method of the PMC_CPQ_ApprovalGroupEmailSenderClass.
* 
*/ 
  @isTest
    public static void testSendApprovalGroupEmail() {
        Test.startTest();
        User testUser = [SELECT Id, Name FROM User Where LastName='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(testUser) {
            
            //Create Approver
            sbaa__Approver__c testApprover = new sbaa__Approver__c(
                Name = testUser.Name,
                sbaa__User__c= testUser.id
            );
            
            insert testApprover;
            
            //Email Tempalte 
            EmailTemplate validEmailTemplate = new EmailTemplate(
                isActive = true,
                Name = 'GroupEmailTemp',
                DeveloperName = 'Group_Email_Temp',
                TemplateType = 'text',
                FolderId = UserInfo.getUserId()
            );
            insert validEmailTemplate;        
            
            //Insert Created Email Templte id to the template
            sbaa__EmailTemplate__c testEmailTemplate = new sbaa__EmailTemplate__c(
                Name = 'TestTemplate',
                sbaa__TemplateId__c=validEmailTemplate.id
            );
            insert testEmailTemplate;
            
            // Craete Approval Rule
            sbaa__ApprovalRule__c testApprovalRule = new sbaa__ApprovalRule__c(
                Name='TestApprovalRule',
                sbaa__ApprovalTemplate__c=testEmailTemplate.id,
                sbaa__TargetObject__c='SBQQ__Quote__c'
                
            );
            insert testApprovalRule;
            
            //Create Approval Record  
            sbaa__Approval__c testApproval = new sbaa__Approval__c(
                sbaa__Approver__c = testApprover.Id,
                sbaa__ApprovalStep__c=1,
                sbaa__RecordField__c='Quote__c',
                sbaa__Rule__c=testApprovalRule.id
                
            );
            insert testApproval;
            
            
            // Call the method under test
            Boolean testRunning=true;
            List<Id> recordIds = new List<Id>{ testApproval.Id };
                
            PMC_CPQ_ApprovalGroupEmailSenderClass.testRunning = true;
            PMC_CPQ_ApprovalGroupEmailSenderClass.sendApprovalGroupEmail(recordIds);
            
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            email.setTemplateId(testEmailTemplate.id);
            if(!TestRunning){
                email.setWhatId( testApproval.Id );
                
            }           
            email.setTargetObjectId(testUser.id);
            email.setSaveAsActivity(false);
            emailMessages.add(email); 
            System.assertEquals(1, emailMessages.size(), 'Expected 1 email to be sent');          
        }
        Test.stopTest();
    }
}