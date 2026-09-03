/**
 * PMC_SS_ApprovalControllerTest
 *
 * Verifies behavior of PMC_SS_ApprovalController:
 * - getMyPendingApprovals returns approvals for the current user context
 * - processApprovalRecord updates status and persists comments
 *
 * Notes:
 * - Uses test utility methods from PMC_TestUtilityClass to create prerequisite data
 * - Runs without seeAllData to ensure isolation
 */
@isTest(seeAllData=false)
private class PMC_SS_ApprovalControllerTest {
    
    /**
     * Test setup creates:
     * - A Standard User with required permission set group
     * - A Group and membership for the user
     */
    @TestSetup
    static void setupTestData() {
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SRV_Permission_Set_Group'};
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User testUser = new User(
            ProfileId = p.Id,
            LastName = 'TestUser0828',
            Email = 'testuser@test.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert testUser;
        
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{testUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        
        // Create test group
        Group testGroup = new Group(
            Name = 'Test Approval Group',
            Type = 'Regular'
        );
        insert testGroup;
        
        // Add user to group
        GroupMember gm = new GroupMember(
            GroupId = testGroup.Id,
            UserOrGroupId = testUser.Id
        );
        insert gm;
    }
    
    /**
     * Creates data that an approval depends on (Case, Approval Chain, Approver, Rule, Approval).
     */
    static void setupData() {
        User testUser = [SELECT Id,Name FROM User WHERE LastName = 'TestUser0828' LIMIT 1];
        system.runAs(testUser){
            
			List<Contact> lstContacts = PMC_TestUtilityClass.createContact(1 ,'Master');
            // Create test case
            Case testCase = new Case(
                Subject = 'Test Case',
                Status = 'New',
                Origin = 'Phone',
                ContactId = lstContacts.get(0).Id
            );
            insert testCase;
            
            // Create approval chain
            sbaa__ApprovalChain__c approvalChain = new sbaa__ApprovalChain__c(
                Name = 'Case Cancel/Rebill Approval Chain'
            );
            insert approvalChain;
            
            //Create Approver
            sbaa__Approver__c testApprover = new sbaa__Approver__c(
                Name = testUser.Name,
                sbaa__User__c= testUser.id
            );
            
            insert testApprover;
            
            // Craete Approval Rule
            sbaa__ApprovalRule__c testApprovalRule = new sbaa__ApprovalRule__c(
                Name='TestApprovalRule',
                sbaa__TargetObject__c='Case'
            );
            insert testApprovalRule;
            
            //Create Approval Record  
            sbaa__Approval__c testApproval = new sbaa__Approval__c(
                sbaa__Approver__c = testApprover.Id,
                sbaa__ApprovalStep__c=1,
                sbaa__RecordField__c='Manager_Id__c',
                sbaa__Rule__c=testApprovalRule.id,
                sbaa__ApprovalChain__c = approvalChain.Id,
                sbaa__Status__c ='Requested' ,
                Case__c = testCase.Id
            );
            insert testApproval;
        }
    }
    
    @isTest
    /**
     * Ensures getMyPendingApprovals returns records and processApprovalRecord approves successfully.
     */
    static void testGetMyPendingApprovals() {
        // Create test data for this specific test
        User testUser = [SELECT Id,Name FROM User WHERE LastName = 'TestUser0828' LIMIT 1];
        setupData();
        system.runAs(testUser){
            
            // Test positive scenario - user has pending approvals
            Test.startTest();
            List<PMC_SS_ApprovalController.ApprovalItemDTO> results = PMC_SS_ApprovalController.getMyPendingApprovals();
            PMC_SS_ApprovalController.processApprovalRecord(results[0].recordId, true, 'testing approval');
            Test.stopTest();
            
            // Assertions
            System.assertNotEquals(null, results, 'Results should not be null');
            System.assert(results.size() > 0, 'Should return at least one approval');
            
            sbaa__Approval__c appRec = [select id,sbaa__Status__c from sbaa__Approval__c where Id=:results[0].recordId];
            // Assertions
            System.assertEquals('Approved', appRec.sbaa__Status__c, 'Approval Record should be Approved');
        }
    }
    
    @isTest
    /**
     * Validates that processApprovalRecord throws when approvalId is null.
     */
    static void testprocessApprovalRecord_Exception() {
        // Test positive scenario - user has pending approvals
        Test.startTest();
        try{
            PMC_SS_ApprovalController.processApprovalRecord(null, true, 'testing approval');
            system.assert(false);
        }catch(exception ex){
            system.assert(true);
        }
        Test.stopTest();
    }
}