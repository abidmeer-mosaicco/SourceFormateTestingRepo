/**
 * @description This test class will be used to cover all the methods of PMC_CaseTriggerHandler and PMC_CaseTriggerHelper.
 * @author Sayali Shinde
 */

@isTest(seeAllData = false)
private with sharing class PMC_CaseTriggerHandlerTest {
    

    /**
    * @descriptionn This Method will be used to setup the test data for the test class execution.
    */
    
    @testsetup
    private static void setup() {
        
        List<String>lstProfileNames = New List<String>{'System Administrator','Service User'};
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SRV_Permission_Set_Group'};
      List<Case> lstCases = new List<Case>();
        List<Account> lstAccounts = new List<Account>();
        
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        UserRole objRole = [SELECT Id,Name FROM UserRole WHERE Name ='NA Customer Service Lead'];
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
                   objUser.UserRoleId = objRole.Id;
                } 
                objUser.isActive = true;                
                objUser.MobilePhone = '1234567890';
                intuserCount = intuserCount + 1;
            }            
            insert lstUser;
            objSystemAdminUser = lstUser[0];
            objServiceUser = lstUser[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objServiceUser}, mapOfPermissionGrp.get('PMC_SRV_Permission_Set_Group'));
        BusinessHours objBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True];
        
        System.runAs(objSystemAdminUser){         
         PMC_TestUtilityClass.createLocation('Test Location');
         PMC_TestUtilityClass.createProduct(1,'PMC_CPQ_NA');
        }
       System.runAs(objServiceUser){
        lstAccounts = getTestAccountList();
           // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
        insert testContact;

            lstCases = getTestCasesList(lstAccounts, objSystemAdminUser.Id, objBusinessHrs.Id,testContact.id);
           
            insert lstCases;
               Account result = new Account();
        result.Name = 'Account-11' ;
        result.NumberOfEmployees = 0;
           result.BillingCity='Pune';
           result.BillingStreet='gftgf cgvf';
        insert result;
            List<Contact> lstContacts = PMC_TestUtilityClass.createContact(1, '');
            if(lstContacts.size() > 0 && lstAccounts.size() > 0) {
                lstContacts[0].AccountId = result.Id;
                lstContacts[0].PMC_SS_Status__c = 'Active';
                testContact.AccountId=result.id;
                testContact.PMC_SS_Status__c='Active';
                update testContact;
            
                PMC_TestUtilityClass.createCaseWithContact(objBusinessHrs.Id, testContact.Id, lstUser[0].Id);
            }
           
        }
        
    }

    /**
     * @description Method will create Test Accounts 
     * @return - List<Account> return list of test accounts created
     */

    public static List<Account> getTestAccountList() {

        List<Account> lstAccounts = new List<Account>();
        for(Integer intAccountCount = 0; intAccountCount < 3; intAccountCount++) {
            Account objAccount = PMC_TestUtilityClass.createAccount('Deloitte'+intAccountCount,'PMC_SS_Customer');
            lstAccounts.add(objAccount);
        }
        return lstAccounts;
    }

    /**
     * @description Method will create Test Case 
     * @param lstAccounts - List of test accounts created
     * @param idUser - User Id as Owner
     * @param idBusinessHours - Business Hours Id
     * @return List<Case> return list of test cases created
     */

    public static List<Case> getTestCasesList(List<Account> lstAccounts, Id idUser, Id idBusinessHours,id contactid) {
    Schema.Location objLocation = [SELECT ID FROM Location limit 1];
        List<Case> lstCases = new List<Case>();

        for(Integer intAccountCount = 0; intAccountCount < lstAccounts.size(); intAccountCount++) {
            Case objCase = PMC_TestUtilityClass.createCase(idBusinessHours, lstAccounts[intAccountCount].Id, idUser,objLocation.Id);
            
            objCase.Subject = intAccountCount == 0 ? 'Test Case High Priority Excemption' : 'Test Subject';
            objCase.Type = intAccountCount == 0 ? 'Internal' : 'Shipping';     
            objCase.PMC_SS_IssueReason__c = intAccountCount == 0 ? 'MDM Verification' : 'Diversion';
            objCase.PMC_SS_RouteToQuality__c = False;
            objCase.contactId=contactid;
            lstCases.add(objCase);
        }
        
        return lstCases;
    }
    
    /**
     * @description Method will create Test Case 
     
     */
    
    @isTest
    public static void testAttachContactLeadOnCase() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
            Schema.Location objLocation = [SELECT ID FROM Location limit 1];
                List<Case> lstCases = new List<Case>();
                Id idBusinessHours = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True LIMIT 1].Id; 
                
                  // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
           testContact.Email = 'hidituzig@dropjar.com';

              testContact.PMC_SS_Status__c = 'Active';
        insert testContact;
                
                List<Lead> lstLeads = PMC_TestUtilityClass.createLead(1, '');
                lstLeads[0].Phone = '3213213213';
                lstLeads[0].Email = 'kynipub@tafmail.com';
                update lstLeads[0];
              
                
                Case objCase = PMC_TestUtilityClass.createCaseWithoutContact(idBusinessHours, null, objUser.Id,objLocation.Id);
                objCase.SuppliedEmail='stuartLittle@lele.comm';
              objCase.SuppliedPhone='1212121212';
              objCase.ContactId=testContact.id;
              lstCases.add(objCase);
                
                Case objCase2 = PMC_TestUtilityClass.createCase(idBusinessHours, null, objUser.Id,objLocation.Id);
                objCase2.SuppliedEmail=testContact.Email;   
             objCase2.ContactId=testContact.id;
                lstCases.add(objCase2);
              
              Case objCase3 = PMC_TestUtilityClass.createCaseWithoutContact(idBusinessHours, null, objUser.Id,objLocation.Id);
                objCase3.SuppliedEmail=lstLeads[0].Email; 
             objCase3.ContactId=testContact.id;
                lstCases.add(objCase3);
                
                Case objCase4 = PMC_TestUtilityClass.createCase(idBusinessHours, null, objUser.Id,objLocation.Id);                
                objCase4.SuppliedEmail=lstLeads[0].Email;   
             objCase4.ContactId=testContact.id;
              lstCases.add(objCase4);
                insert lstCases;
            
                System.assertEquals(objCase4.SuppliedEmail, lstLeads[0].Email, 'Lead & Case Email are matched');
            }
        
        
        Test.stopTest();
    }
    
    
    /** 
    * @description This method will be used to test the scenario where Case status is updated to Escalated and from Escalated to other Status.
    */ 
    
    @isTest
    private static void testUpdateIsEscalatedFlag() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Case objCase = [SELECT Id, Subject, Status FROM Case WHERE Subject = 'Test Subject' WITH SECURITY_ENFORCED LIMIT 1];
        
         
                objCase.Status = 'Escalated';
                update objCase;
                System.assertEquals('Escalated', objCase.Status, 'Status has been updated to Escalated');
                
                objCase.Status = 'Working';
                update objCase;
                System.assertEquals('Working', objCase.Status, 'Status has been updated to Working');
            
        }
        
        Test.stopTest();
    }
    
    
    /** 
    * @description This method will be used to test the scenario where case status is updated to Re-Open.
    */ 
    
  @isTest
    private static void testCheckBusinessDaysOnCaseReOpen() {
        Test.startTest();
        
        
        User objUser = [SELECT Id, Name FROM User WHERE LastName = 'Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        User objUser1 = [SELECT Id, Name FROM User WHERE LastName = 'Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        Case objCase;
        System.runAs(objUser) {
        objCase = [SELECT Id, Subject, Status, ClosedDate FROM Case WHERE Subject = 'Test Subject' WITH SECURITY_ENFORCED LIMIT 1];
        Schema.Location objLocation = [SELECT ID FROM Location limit 1];
             product2 test=new product2(Name='test product');// added for 3975
            insert test;
    Schema.Product2 objProduct2 = [SELECT ID FROM Product2 where id =:test.id limit 1];
        if(objUser != null && objCase != null && objUser1 != null && objProduct2 != null) {          
                objCase.Status = 'Closed';
                objCase.PMC_SS_AtFaultParty__c = 'Service';
                objCase.PMC_SS_IssueReason__c = 'Diversion';
                objCase.PMC_SS_SAP_CustomerNumber__c = '12540';
                objCase.PMC_SS_Location__c = objLocation.Id;
                objCase.PMC_SS_NewDestinationLocation__c = objLocation.Id;
                objCase.PMC_SS_ShipmentDate__c= Date.today();
                objCase.PMC_SS_ReturnQuantity__c = 2;
                objCase.PMC_SS_SAPOrderNumber__c ='test2121';
                objCase.PMC_SS_ProductType__c ='AFI';
                objCase.PMC_SS_VehicleId__c='KL-TEST';
                objCase.PMC_SS_MOT__c ='Barge';
                objCase.PMC_SS_ActionReason__c='Debit';
        objCase.ProductId = objProduct2.Id;
        objCase.PMC_SS_SAPInvoiceNumber__c ='1234';
                update objCase;
            }
        }
            
            System.runAs(objUser1) {
                objCase.Status = 'Re-Open';
                objCase.PMC_SS_ReOpenReason__c = 'New information';
                update objCase;
                
                System.assertEquals(objUser.Id != objUser1.Id, true, 'Case has been re-opened by non closing user');
            }
        
        
        Test.stopTest();
    }
    
    
    /** 
    * @description This method will be used to test the Validation Error scenario when case status is updated to Re-Open.
    */ 
    
    @isTest
    private static void testCheckBusinessDaysOnCaseReOpenValidationError() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Schema.Location objLocation = [SELECT ID FROM Location limit 1];
            product2 test=new product2(Name='test product');// added for 3975
            insert test;
    Schema.Product2 objProduct2 = [SELECT ID FROM Product2 where id =:test.id limit 1];
        try{
            PMC_CaseTriggerHelper.boolThrowException = true;
            Case objCase = [SELECT Id, Subject, Status, ClosedDate,BusinessHoursId FROM Case WHERE Subject = 'Test Subject' WITH SECURITY_ENFORCED LIMIT 1];
                    objCase.Status = 'Closed';
                    objCase.PMC_SS_AtFaultParty__c = 'Service';
                    objCase.PMC_SS_IssueReason__c = 'Diversion';
                    objCase.PMC_SS_SAP_CustomerNumber__c = '12540';
                    objCase.PMC_SS_Location__c = objLocation.Id;
                    objCase.PMC_SS_NewDestinationLocation__c = objLocation.Id;
                    objCase.PMC_SS_ShipmentDate__c= Date.today();
                    objCase.PMC_SS_ReturnQuantity__c = 2;
                    objCase.PMC_SS_SAPOrderNumber__c ='test2121';
                    objCase.PMC_SS_ProductType__c ='AFI';
                    objCase.PMC_SS_VehicleId__c='KL-TEST';
                    objCase.PMC_SS_MOT__c ='Barge';
                    objCase.PMC_SS_ActionReason__c='Debit';
                    objCase.ProductId = objProduct2.Id;
                    objCase.PMC_SS_SAPInvoiceNumber__c ='1234';
                    update objCase;
                    Map<Id,Case> mapCase = new Map<Id,Case>();
                    mapCase.put(objCase.Id,objCase); 
                    objCase.Status = 'Re-Open';
                    objCase.PMC_SS_ReOpenReason__c = 'New information';
                    update objCase;
                    
                    system.assert(TRUE, 'Exceptions should be handled by the method');
                }
            
        
        catch(Exception objException){
            
            System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
        }
        }
        Test.stopTest();
    }

    /** 
    * @description This method will check whether Web Email and Web Name on Case is populated
    */ 
    @isTest
    private static void testUpdateWebEmailandWebName() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
         Schema.Location objLocation = [SELECT ID FROM Location limit 1];
        BusinessHours objTestBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True]; 
        Account objTestAccount = [SELECT Id, Name FROM Account  WITH SECURITY_ENFORCED LIMIT 1];
 // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
        insert testContact;
        
    Case objTestCase= PMC_TestUtilityClass.createCase(objTestBusinessHrs.Id,objTestAccount.Id ,objUser.Id,objLocation.Id);
        objTestCase.Type='Internal';
        objTestCase.PMC_SS_IssueReason__c='Article Request';
            objTestCase.ContactId=testContact.id;
        insert objTestCase;

        Case objCase1= [SELECT Id, SuppliedEmail, SuppliedName, Subject, Type, PMC_SS_IssueReason__c FROM Case WHERE Subject='Test Subject'AND Type='Internal' AND PMC_SS_IssueReason__c='Article Request'];
        Case objTestCase2= PMC_TestUtilityClass.createCase(objTestBusinessHrs.Id,objTestAccount.Id ,objUser.Id,objLocation.Id);
        objTestCase2.Type='Product';
                    objTestCase2.ContactId=testContact.id;

            insert objTestCase2;    
        objTestCase2.PMC_SS_IssueReason__c='Product Request';
        Update objTestCase2;
        objTestCase2.PMC_SS_IssueReason__c='Incorrect Product';
        Update objTestCase2;
        objTestCase2.Type='Transactions';    
        objTestCase2.PMC_SS_IssueReason__c='Rebate';
        //Update objTestCase2;
        objTestCase2.Type='Internal';    
        objTestCase2.PMC_SS_IssueReason__c='Article Request';
        Update objTestCase2;
        System.assertEquals(UserInfo.getName(), objCase1.SuppliedName, 'Web Name updated');
        System.assertEquals(UserInfo.getUserEmail(), objCase1.SuppliedEmail, 'Web Email updated');
        }
    
        Test.stopTest();
    }
    
    
    /** 
    * @description This method will be used to test the Bypass Trigger Logic.
    */ 
    
    @isTest
    private static void testBypassUpdateOperation() {
    

        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Schema.Location objLocation = [SELECT ID FROM Location limit 1];
        PMC_CaseTriggerHandler.boolBypassTriggerLogic = true;
        Case objCase = [SELECT Id, Subject, Status, ClosedDate, BusinessHoursId, AccountId FROM Case WHERE Subject = 'Test Subject' WITH SECURITY_ENFORCED LIMIT 1];
        product2 test=new product2(Name='test product');// added for 3975
            insert test;
    Schema.Product2 objTestProduct = [SELECT ID FROM Product2 where id =:test.id limit 1];
                 // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
        insert testContact;
                Case objCase1 = PMC_TestUtilityClass.createCase(objCase.BusinessHoursId, objCase.AccountId, objUser.Id,objLocation.Id);
           objCase1.ContactId =  testContact.id;  
            insert objCase1;
        objCase.PMC_SS_NewDestinationLocation__c = objLocation.Id;
                objCase.PMC_SS_ShipmentDate__c= Date.today();
                objCase.PMC_SS_ReturnQuantity__c = 2;
                objCase.PMC_SS_SAPOrderNumber__c ='test2121';
                objCase.PMC_SS_ProductType__c ='AFI';
                objCase.PMC_SS_VehicleId__c='KL-TEST';
                objCase.PMC_SS_MOT__c ='Barge';
                objCase.PMC_SS_ActionReason__c='Debit';
                objCase.PMC_SS_Location__c=objLocation.Id;
                objCase.Status = 'Closed';
              objCase.PMC_SS_AtFaultParty__c = 'Service';
                objCase.PMC_SS_IssueReason__c = 'Diversion';
                objCase.PMC_SS_SAP_CustomerNumber__c = '12540';
        objCase.ProductId = objTestProduct.Id;
                objCase.PMC_SS_SAPInvoiceNumber__c ='1234';

                update objCase;  
            
        System.assertEquals('Closed', [SELECT ID,Status FROM CASE WHERE ID=: objCase.ID].Status,'Validating Case Status Closed');
        }
        Test.stopTest();        
       }

    /** 
    * @description This method will be used to test the Case Type setup based on subject for email-to-case Logic.
    */ 
    
    @isTest
    private static void testCaseTypeFromSubject() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {  
     Schema.Location objLocation = [SELECT ID FROM Location limit 1];
              // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
        insert testContact;
         Case objCase = [SELECT Id, Subject, Status, ClosedDate, BusinessHoursId, AccountId FROM Case WHERE Subject = 'Test Subject' WITH SECURITY_ENFORCED LIMIT 1];
                Case objCase1 = PMC_TestUtilityClass.createCase(objCase.BusinessHoursId, objCase.AccountId, objUser.Id,objLocation.Id);
                objCase1.Subject ='Shipment';
                objCase1.Origin = PMC_SS_ConstantClass.CASE_ORIGIN_EMAIL;
           objCase1.ContactId= testContact.id;
                insert objCase1;
                
                Case objCase2 = PMC_TestUtilityClass.createCase(objCase.BusinessHoursId, objCase.AccountId, objUser.Id,objLocation.Id);
                objCase2.Subject ='Other Case';
                objCase2.Type ='';
                       objCase2.ContactId= testContact.id;

                objCase2.Origin = PMC_SS_ConstantClass.CASE_ORIGIN_EMAIL;
                insert objCase2;
                System.assertEquals('Shipping', [SELECT ID,Type FROM CASE WHERE ID=: objCase.ID].Type,'Validating Case Type');
            }
        Test.stopTest();
    }
    /** 
    * @description This method will be used to test the Validation Error scenario when case status is updated to Re-Open.
    */ 
    
    @isTest
    private static void testCaseTypeFromSubjectError() {
        
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        try{                   
            PMC_CaseTriggerHelperExtension.updateCaseTypebasedOnSubject(null);
         }
        catch(Exception objException){
            System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
        }
        }
        test.stopTest();
    }
    
    /** 
    * @description This method will be used to test the routing of Case to Quality Queue when Route to Quality is checked.
    */ 
    @isTest
    private static void testUpdateCaseOwnerBasedOnRouteToQuality() {

        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Case objCase = [SELECT Id, Subject,Status, OwnerId, PMC_SS_RouteToQuality__c FROM Case WHERE Subject = 'Test Subject' WITH SECURITY_ENFORCED LIMIT 1];
                objCase.PMC_SS_RouteToQuality__c = True;
                update objCase;
                PMC_SS_CaseUserReferenceUpdate.updateBillingQueue(null,null);
                PMC_SS_CaseUserReferenceUpdate.addAccountAndRegionalManagerOnInsertUpdate(null,null);
                PMC_CaseTriggerHelperMethodExtension.updateStatusForSN(null,null);        
        System.assertEquals([SELECT Id, OwnerId FROM Case WHERE Subject = 'Test Subject' WITH SECURITY_ENFORCED LIMIT 1].OwnerId, [SELECT Id FROM Group where Type='Queue' And DeveloperName ='PMC_SS_Quality' limit 1].Id,'Validating Owner Change');
        }
        Test.stopTest();
        }

  /** 
    * @description This method will be used to test the entitlement link to case.
    */
    @isTest
    private static void testassignEntitlmentRecordToCases() {
        
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Schema.Location objLocation = [SELECT ID FROM Location limit 1];
        BusinessHours objTestBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True];
        Account objTestAccount = [SELECT Id, Name FROM Account  WITH SECURITY_ENFORCED LIMIT 1];  
        AccountTeamMember testNationalDirectorTeamMember = PMC_TestUtilityClass.createAccountTeamMember( objUser.Id,objTestAccount.Id,'National Director');
        insert testNationalDirectorTeamMember;
              // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
        insert testContact;
        Case objTestCase= PMC_TestUtilityClass.createCase(objTestBusinessHrs.Id,objTestAccount.Id ,objUser.Id,objLocation.Id);
     objTestCase.ContactId=testContact.id;
        insert objTestCase;
        System.assertEquals(true,objTestCase !=null,'Validate entitilement tag');
        }
        Test.stopTest();
    }
    
    /** 
    * @description This method will be used to test the exception.
    */ 
    @isTest
    private static void testUpdatePriorityException() {

        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        try{    
            PMC_CaseTriggerHelper.updateCasePriority(null);                
        }
        catch(Exception objException){
            System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
        }
        }
        Test.stopTest();        
    }
  
    /** 
    * @description This method will be used to test the updation of Case's Account Manager whenever Account is populated.
    */ 
    @isTest
    private static void testCaseAccountManagerUpdation() {

        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Case objCase = [SELECT Id, Subject, PMC_SS_AccountManager__c FROM Case WHERE Subject = 'Test Subject' WITH SECURITY_ENFORCED LIMIT 1];
        Account objAccount = [SELECT Id, Name, OwnerId FROM Account WHERE RecordType.DeveloperName ='PMC_SS_Customer' WITH SECURITY_ENFORCED LIMIT 1];
                objCase.AccountId = objAccount.Id;
                objCase.PMC_SS_ContractCancellation__c =PMC_SS_ConstantClass.UNAPPROVED_CREDIT_LIMIT;
                update objCase;
                objCase.PMC_SS_ContractCancellation__c ='';
                update objCase;
            
        System.assertEquals(objCase.PMC_SS_AccountManager__c, objAccount.OwnerId ,'Validating Account Manager Update');
        }
        Test.stopTest();
    }
    
    /** 
    * @description This method will be used to test the locking of closed case.
    */ 
    @isTest
    private static void testCaseLockRecord() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
    Schema.Location objLocation = [SELECT ID FROM Location limit 1];
    product2 test=new product2(Name='test product');// added for 3975
            insert test;
    Schema.Product2 objTestProduct = [SELECT ID FROM Product2 where id =:test.id limit 1];       
        Case objCase = [SELECT Id, Subject, PMC_SS_AccountManager__c FROM Case WHERE Subject = 'Test Subject' WITH SECURITY_ENFORCED LIMIT 1];
        Account objAccount = [SELECT Id, Name, OwnerId FROM Account WHERE RecordType.DeveloperName ='PMC_SS_Customer' WITH SECURITY_ENFORCED LIMIT 1];
                objCase.AccountId = objAccount.Id;
                objCase.Status = 'Closed';
                objCase.PMC_SS_AtFaultParty__c = 'Service';
                objCase.PMC_SS_IssueReason__c = 'Diversion';
                objCase.PMC_SS_SAP_CustomerNumber__c = '12540';
                objCase.PMC_SS_Location__c=objLocation.Id;
                objCase.PMC_SS_NewDestinationLocation__c = objLocation.Id;
                objCase.PMC_SS_ShipmentDate__c= Date.today();
                objCase.PMC_SS_ReturnQuantity__c = 2;
                objCase.PMC_SS_SAPOrderNumber__c ='test2121';
                objCase.PMC_SS_ProductType__c ='AFI';
                objCase.PMC_SS_VehicleId__c='KL-TEST';
                objCase.PMC_SS_MOT__c ='Barge';
                objCase.PMC_SS_ActionReason__c='Debit';
                objCase.PMC_SS_SAPInvoiceNumber__c ='1234';
                objCase.ProductId = objTestProduct.Id;
                 objCase.Type='Internal';
                update objCase;
                
                objCase.PMC_SS_SAP_CustomerNumber__c = '1240';
                update objCase;
                PMC_CaseTriggerHelperMethodExtension.lockClosedCase(null,null);
            
        System.assertEquals(objCase.PMC_SS_AccountManager__c, objAccount.OwnerId ,'Validating Account Manager Update');
            }
        Test.stopTest();
    }
    @isTest
    private static void testClearCaseAmmendment (){
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Schema.Location objLocation = [SELECT ID FROM Location limit 1];
        BusinessHours objTestBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True];
        Account objTestAccount = [SELECT Id, Name FROM Account  WITH SECURITY_ENFORCED LIMIT 1];
        Case objTestCase= PMC_TestUtilityClass.createCase(objTestBusinessHrs.Id,objTestAccount.Id,objUser.Id,objLocation.Id);
        objTestCase.PMC_SS_ContractAmendmentType__c = PMC_SS_ConstantClass.CONTRACT_AMENDMENT_TYPE_DUE_DATE;
         // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
        insert testContact;
            objTestCase.Type = PMC_SS_ConstantClass.CASE_TYPE_TRANSACTIONS;          
        objTestCase.contactid=testContact.id;
        insert objTestCase; 
        objTestCase.Type = PMC_SS_ConstantClass.CASE_TYPE_TECHNICAL;
    update objTestCase;
        Case updatedCase = [Select PMC_SS_ContractAmendmentType__c from Case Where Id=:objTestCase.Id];
         System.assertEquals(updatedCase.PMC_SS_ContractAmendmentType__c, null,'Validating contract agreeement type clearing');
        }   
        Test.stoptest();        
    }
    @isTest
    private static void testClearArticleType (){ 
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
    Contact objTestContact = [SELECT Id, Name FROM Contact WITH SECURITY_ENFORCED LIMIT 1];
        Case objTestCase = [SELECT Id, PMC_SS_ArticleType__c , PMC_SS_IssueReason__c FROM Case WITH SECURITY_ENFORCED LIMIT 1];
            
                objTestCase.Type='Internal';
                objTestCase.PMC_SS_IssueReason__c='Article Request';
                objTestCase.PMC_SS_ArticleType__c='FAQ';
                objTestCase.ContactId = objTestContact.Id;
                update objTestCase;
                objTestCase.PMC_SS_IssueReason__c='Data Entry';
                update objTestCase;                
          System.assertEquals([Select PMC_SS_ArticleType__c from Case Where Id=:objTestCase.Id].PMC_SS_ArticleType__c, null,'Validating Article Type clearing');
        }        
        Test.stoptest();
         
    }
   @isTest
    private static void testInvoiceDifference(){
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Schema.Location objLocation = [SELECT ID FROM Location limit 1];
        List<Case> lstCases = new List<Case>();    
         BusinessHours objTestBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True];
        Account objTestAccount = [SELECT Id, Name FROM Account  WITH SECURITY_ENFORCED LIMIT 1];
          // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
        insert testContact;
    Case objTestCase= PMC_TestUtilityClass.createCase(objTestBusinessHrs.Id,objTestAccount.Id,objUser.Id,objLocation.Id);
        objTestCase.Type='Invoice';
        objTestCase.PMC_SS_IssueReason__c='Invoice Adjustments';
        objTestCase.PMC_SS_ActionReason__c='Rebill';
        objTestCase.PMC_SS_OriginalInvoiceAmount__c=1000;
        objTestCase.PMC_SS_RebillAmount__c=100;
        objTestCase.PMC_SS_SNOW_Status__c = 'Waiting for Treatment'; 
            objTestCase.contactid=testContact.id;
        lstCases.add(objTestCase);
        Case objTestCase1= PMC_TestUtilityClass.createCase(objTestBusinessHrs.Id,objTestAccount.Id ,objUser.Id,objLocation.Id);
        objTestCase1.Type='Product';
        objTestCase1.PMC_SS_IssueReason__c='Product Request';
        lstCases.add(objTestCase1);
        insert lstCases;
        lstCases[0].PMC_SS_ActionReason__c = 'Cancel';
        lstCases[0].PMC_SS_SNOW_Status__c = 'Waiting for Execution';  
        PMC_TestUtilityClass.createContentDocumentLink( lstCases[1].Id);
    PMC_TestUtilityClass.createContentDocumentLink( lstCases[1].Id);
        lstCases[1].PMC_SS_MDMStatus__c ='Waiting for Master Data Management';
        update lstCases;
        lstCases[1].PMC_SS_MDMStatus__c ='Waiting for Product Routing Creation and Assignment';
        update lstCases;
        System.assertEquals(lstCases[1].PMC_SS_MDMStatus__c,'Waiting for Product Routing Creation and Assignment' ,'MDM Status is updated');
        System.assertEquals([Select PMC_SS_InvoiceDifference__c from Case Where Id=:lstCases[0].Id].PMC_SS_InvoiceDifference__c, 0,'  Invoice Difference not calculated properly');
        }    
    Test.stoptest();    
}

    @isTest
    private static void testAccountSegmentManagerAssignmentToCaseType (){ 
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Schema.Location objLocation = [SELECT ID FROM Location limit 1];
        BusinessHours objTestBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True];
        Account objTestAccount = [SELECT Id, Name FROM Account  WITH SECURITY_ENFORCED LIMIT 1];
            
                AccountTeamMember testSegmentManagerTeamMember = PMC_TestUtilityClass.createAccountTeamMember( objUser.Id,objTestAccount.Id,'Segment Manager');
                AccountTeamMember testRegionalManagerTeamMember = PMC_TestUtilityClass.createAccountTeamMember( objUser.Id,objTestAccount.Id,'Regional Director');

                insert testSegmentManagerTeamMember;
                insert testRegionalManagerTeamMember;        
        Case objTestCase= PMC_TestUtilityClass.createCase(objTestBusinessHrs.Id,objTestAccount.Id,objUser.Id,objLocation.Id);
        objTestCase.Type = PMC_SS_ConstantClass.INVOICE;
            // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
           testContact.Email = 'hidituzig@dropjar.com';

              testContact.PMC_SS_Status__c = 'Active';
        insert testContact;

        objTestCase.PMC_SS_IssueReason__c =PMC_SS_ConstantClass.INVOICE_ADJUSTMENTS;
            objTestCase.ContactId=testContact.id;
        insert objTestCase;
        System.assertEquals(PMC_SS_ConstantClass.INVOICE, objTestCase.Type,'Check invoice ');
        }
        Test.stoptest();
    }
    
    @isTest
    private static void testAccountRegionalAssignmentToCaseType (){ 
        Test.startTest();
        
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Schema.Location objLocation = [SELECT ID FROM Location limit 1];
        
        BusinessHours objTestBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True];
        Account objTestAccount = [SELECT Id, Name FROM Account  WITH SECURITY_ENFORCED LIMIT 1];
                AccountTeamMember testRegionalDirectorTeamMember = PMC_TestUtilityClass.createAccountTeamMember( objUser.Id,objTestAccount.Id,'Regional Director');
                insert testRegionalDirectorTeamMember;
            // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
           testContact.Email = 'hidituzig@dropjar.com';

              testContact.PMC_SS_Status__c = 'Active';
        insert testContact;
        Case objTestCase= PMC_TestUtilityClass.createCase(objTestBusinessHrs.Id,objTestAccount.Id,objUser.Id,objLocation.Id);
        objTestCase.ContactId=testContact.id;
            insert objTestCase;
        Case objCase = [SELECT Id, PMC_SS_SNOW_ServiceNowTicketNumber__c FROM Case WHERE Id =: objTestCase.Id WITH SECURITY_ENFORCED LIMIT 1];
        objCase.PMC_SS_SNOW_ServiceNowTicketNumber__c = 'abcde';
        objCase.PMC_SS_SNOW_Status__c = 'Waiting for Treatment';
        update objCase;
        System.assertEquals(objUser.Id, [Select ID,PMC_SS_RegionalDirector__c from Case where ID =: objTestCase.ID limit 1].PMC_SS_RegionalDirector__c,'Regional Director not Assigned ');
        }
        Test.stoptest();       
    }
    
    
    @isTest
    private static void callingprepareMapContactEmailPhone(){
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.RunAs(objUser){
        
                // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
           testContact.Email = 'hidituzig@dropjar.com';

              testContact.PMC_SS_Status__c = 'Active';
        insert testContact;

            Set<String> setPhone = new Set<String>{'hidituzig@dropjar.com'};
          Map<String, Id> mapContactEmailPhone= PMC_ContactOrLeadAssignmentToCase.prepareMapContactEmailPhone(setPhone);
        System.assertEquals(true,mapContactEmailPhone.size() > 0 ,'Case is Auto Approved');
        }
        Test.stoptest();
        } 
    
    @isTest
    private static void callingupdateCaseMilestoneTriggerToPause(){
        Test.startTest();
        
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
            Schema.Location objLocation = [SELECT ID FROM Location limit 1];
            
            BusinessHours objTestBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True];
            Account objTestAccount = [SELECT Id, Name FROM Account  WITH SECURITY_ENFORCED LIMIT 1];
            objTestAccount.BillingCountry='Brazil';
            objTestAccount.BillingPostalCode='78400-000';
            objTestAccount.phone='';
            Update objTestAccount;
            AccountTeamMember testRegionalDirectorTeamMember = PMC_TestUtilityClass.createAccountTeamMember( objUser.Id,objTestAccount.Id,'Regional Director');
            insert testRegionalDirectorTeamMember;
            // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
           testContact.Email = 'hidituzig@dropjar.com';

              testContact.PMC_SS_Status__c = 'Active';
        insert testContact;

            Case objTestCase= PMC_TestUtilityClass.createCase(objTestBusinessHrs.Id,objTestAccount.Id,objUser.Id,objLocation.Id);
            objTestCase.Status = 'Working';
            objTestCase.contactId=testContact.id;
            insert objTestCase;
            Case objCase = [SELECT Id, PMC_SS_SNOW_ServiceNowTicketNumber__c FROM Case WHERE Id =: objTestCase.Id WITH SECURITY_ENFORCED LIMIT 1];
            objCase.Status = 'Pending';
            update objCase;
            System.assertEquals('Pending', [Select ID,Status from Case where ID =: objTestCase.ID limit 1].Status,'Status not Updated');
        }
        Test.stoptest(); 
    }
    
    @isTest
    private static void callingupdateCaseMilestoneTriggerToWorking(){
        Test.startTest();
        
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
            Schema.Location objLocation = [SELECT ID FROM Location limit 1];
            
            BusinessHours objTestBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True];
            Account objTestAccount = [SELECT Id, Name FROM Account  WITH SECURITY_ENFORCED LIMIT 1];
            objTestAccount.BillingCountry='Brazil';
            objTestAccount.BillingPostalCode='78400-000';
            objTestAccount.phone='';
            Update objTestAccount;
            AccountTeamMember testRegionalDirectorTeamMember = PMC_TestUtilityClass.createAccountTeamMember( objUser.Id,objTestAccount.Id,'Regional Director');
            insert testRegionalDirectorTeamMember;
            Entitlement entl = new Entitlement(Name='TestEntitlement', AccountId=objTestAccount.Id);
            insert entl;
            // Create a test contact
         Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
          testContact.Primary_Function__c='Administration';
           testContact.Seniority_Level__c='Assistant';
           testContact.Email = 'hidituzig@dropjar.com';

              testContact.PMC_SS_Status__c = 'Active';
        insert testContact;

           
            Case objTestCase= PMC_TestUtilityClass.createCase(objTestBusinessHrs.Id,objTestAccount.Id,objUser.Id,objLocation.Id);
            objTestCase.RecordTypeId = Schema.SObjectType.Case.getrecordtypeinfosbydevelopername().get('CustomerService').getRecordTypeId();
            objTestCase.EntitlementId = entl.Id;
            objTestCase.ContactId=testContact.id;
            insert objTestCase;
            Case objCase = [SELECT Id, PMC_SS_SNOW_ServiceNowTicketNumber__c FROM Case WHERE Id =: objTestCase.Id WITH SECURITY_ENFORCED LIMIT 1];
            objCase.Status = 'Working';
            objCase.ContactId=testContact.id;
            update objCase;
            System.assertEquals('Working', [Select ID,Status from Case where ID =: objTestCase.ID limit 1].Status,'Status not Updated');
            System.debug('SOQL: '+[SELECT Id, completionDate, MilestoneType.Name, caseId FROM CaseMilestone where caseId=:objTestCase.Id]);
        }
        Test.stoptest(); 
    }
}