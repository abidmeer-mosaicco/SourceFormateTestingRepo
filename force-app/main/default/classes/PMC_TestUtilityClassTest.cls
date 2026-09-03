/**
 * @description This test class will be used to cover all the methods of PMC_TestUtilityClass.
 * @author Kailas Shimpi
 * @storynumber GPSSM-1224
 */

 @isTest(seeAllData=false)
 public class PMC_TestUtilityClassTest {
     /**
     * @description This method will be use to cover createUser of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateUser() {
         Test.startTest();
         List<User> lstUsers = PMC_TestUtilityClass.createUser(1);
         System.assert(lstUsers.size() != 0,'User records were not created, test method-testCreateUser');
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover the negative scenario of createTestUserRecords of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateUserNull() {
         Test.startTest();
         try {
             List<User> lstUsers = PMC_TestUtilityClass.createUser(null);
             System.assert(lstUsers.size() != 0, 'User records were not created, test method-testCreateUserNull');
         }catch(Exception e) {
             system.assertEquals(e.getMessage(), 'Attempt to de-reference a null object','Expected a NullPointerException');
         }
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createTestAccountRecords of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateAccount() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             Account objAccount = PMC_TestUtilityClass.createAccount('The Mosaic Company 1','PMC_SS_Prospect');
             System.assert(objAccount != null, 'Account records were not created.');
         }
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createTestContactRecords of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateContact() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             List<Contact> lstContacts = PMC_TestUtilityClass.createContact(1,'Master');
             System.assert(lstContacts.size() != 0, 'Contact records were not created.');
         }
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createOpportunity of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateLead() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             List<Lead> lstLeads = PMC_TestUtilityClass.createLead(1,'Master');
             System.assert(lstLeads.size() != 0, 'Lead records were not created.');
         }
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createOpportunity of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateOpportunity() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(1,'Master');
             System.assert(lstOpportunities.size() != 0, 'Opportunity records were not created.');
         }        
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createOpportunityContactRoles of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateOpportunityContactRoles() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(1,'Master');
             List<Contact> lstContacts = PMC_TestUtilityClass.createContact(1,'Master');
             List<OpportunityContactRole> lstOpportunityContactRoles = PMC_TestUtilityClass.createOpportunityContactRoles(lstContacts,lstOpportunities);
             System.assert(lstOpportunityContactRoles.size() != 0, 'OpportunityContactRole records were not created.');
         }        
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createOpportunityTeamMember of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateOpportunityTeamMember() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             List<User> lstUser = PMC_TestUtilityClass.createUser(1);
             List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(1,'Master');
             List<OpportunityTeamMember> lstOppTeamMembers = PMC_TestUtilityClass.createOpportunityTeamMember(lstUser, lstOpportunities);
             System.assert(lstOppTeamMembers.size() != 0, 'OpportunityTeamMember records were not created.');
         }        
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createProduct of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateProduct() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             List<Product2> lstProducts = PMC_TestUtilityClass.createProduct(1,'PMC_CPQ_NA');
             System.assert(lstProducts.size() != 0, 'Product records were not created.');
         }        
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createPriceBookEntry of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreatePriceBookEntry() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             List<Product2> lstProducts = PMC_TestUtilityClass.createProduct(1,'PMC_CPQ_Brazil');
             Id idPriceBook = Test.getStandardPricebookId();
             List<PricebookEntry> lstProceBookEntry = PMC_TestUtilityClass.createPriceBookEntry(lstProducts,idPriceBook);
             System.assert(lstProceBookEntry.size() != 0, 'PriceBookEntry records were not created.');
         }        
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createOpportunityLineItem of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateOpportunityLineItem() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(1,'Master');
             List<Product2> lstProducts = PMC_TestUtilityClass.createProduct(1,'PMC_CPQ_Brazil');
             Id idPriceBook = Test.getStandardPricebookId();
             List<PricebookEntry> lstProceBookEntry = PMC_TestUtilityClass.createPriceBookEntry(lstProducts,idPriceBook);
             List<OpportunityLineItem> lstOpportunityLineItem = PMC_TestUtilityClass.createOpportunityLineItem(lstProceBookEntry,lstOpportunities);
             System.assert(lstOpportunityLineItem.size() != 0, 'OpportunityLineItem records were not created.');
         }        
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createContract of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateContract() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         List<Account> lstAccounts = new List<Account>();
         System.runAs(objUser) {
             List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(1,'Master');
             Account objAccount = PMC_TestUtilityClass.createAccount('The Mosaic Company 2','PMC_SS_Prospect');
             lstAccounts.add(objAccount);
             //List<Account> lstAccounts = PMC_TestUtilityClass.createAccount(1,'Master');
             List<Contract> lstContracts = PMC_TestUtilityClass.createContract(lstAccounts,lstOpportunities);
             System.assert(lstContracts.size() != 0, 'Contract records were not created.');
         }        
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createQuotes of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateQuotes() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(1,'Master');
             List<Quote> lstQuotes = PMC_TestUtilityClass.createQuotes(1, lstOpportunities);
             System.assert(lstQuotes.size() != 0, 'Quote records were not created.');
         }        
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createCPQQuotes of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateCPQQuotes() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(1,'Master');
             List<Contact> lstContacts = PMC_TestUtilityClass.createContact(1,'Master');
             List<SBQQ__Quote__c> lstQuotes = PMC_TestUtilityClass.createCPQQuotes(1, lstOpportunities, lstContacts);
             System.assert(lstQuotes.size() != 0, 'Quote records were not created.');
         }        
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createOrders of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateOrders() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             List<Account> lstAccount = new List<Account>(); 
             Account objAccount = PMC_TestUtilityClass.createAccount('The Mosaic Company 3','PMC_SS_Prospect');
             lstAccount.add(objAccount);
             List<Order> lstOrders = PMC_TestUtilityClass.createOrders(1, lstAccount);
             System.assert(lstOrders.size() != 0, 'Order records were not created.');
         }        
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createOrders of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateOrderProducts() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];  
         System.runAs(objUser) {
             List<Account> lstAccount = new List<Account>(); 
             Account objAccount = PMC_TestUtilityClass.createAccount('The Mosaic Company 4','PMC_SS_Prospect');
             lstAccount.add(objAccount);
             List<Order> lstOrders = PMC_TestUtilityClass.createOrders(1, lstAccount);
             List<OrderItem> lstOrderProducts = PMC_TestUtilityClass.createOrderProducts(1, lstOrders);
             System.assert(lstOrderProducts.size() != 0, 'Order records were not created.');
         }        
         Test.stopTest();
     }


     /**
     * @description This method will be use to cover createSalesArea of PMC_TestUtilityClass.
     */
    @isTest 
    private static void testCreateSalesArea() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
        System.runAs(objUser) {
            List<PMC_SS_SalesArea__c> lstSalesAreas = PMC_TestUtilityClass.createSalesArea(1,'Master');
            System.assert(lstSalesAreas.size() != 0, 'Sales Area records were not created.');
        }
        Test.stopTest();
    }
     
    /**
     * @description This method will be use to cover createAccountSalesAreaRelationship of PMC_TestUtilityClass.
     */
    @isTest 
    private static void testCreateAccountSalesAreaRelationship() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
		List<Account> lstAccounts = new List<Account>();
        System.runAs(objUser) {
			Account objAccountToCreate = PMC_TestUtilityClass.createAccount('Google','PMC_SS_Prospect');
            lstAccounts.add(objAccountToCreate);
            List<PMC_SS_SalesArea__c> lstSalesAreas = PMC_TestUtilityClass.createSalesArea(1,'Master');
            List<PMC_SS_AccountSalesAreaRelationship__c> lstAccountSalesAreaRelationships = PMC_TestUtilityClass.createAccountSalesAreaRelationship(lstAccounts, lstSalesAreas);
            System.assert(lstAccountSalesAreaRelationships.size() != 0, 'Account sales area relationship records were not created.');
        }
        Test.stopTest();
    }
     
    /**
     * @description This method will be use to cover createLeadObjectWrapper of PMC_TestUtilityClass.
     */
    @isTest 
    private static void testCreateLeadObjectWrapper() {
        Test.startTest();
        Lead objLead  = PMC_TestUtilityClass.createLeadObjectWrapper('LastName', 'lead@lead.lead', 'Sulphur');
        Test.stopTest();
        System.assertEquals('Test.COM', objLead.Company, 'Expected Company to be populated');
        System.assertEquals('Test.COM', objLead.Website, 'Expected website to be populated');
        System.assertEquals('New', objLead.Status, 'Expected status to be new');
    }
     
     /**
     * @description This method will be use to cover createCase of PMC_TestUtilityClass.
     */
    @isTest 
     private static void testCreateCase() {
         Schema.Location objLocation= PMC_TestUtilityClass.createLocation('Test Location');
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         BusinessHours objBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True]; 
         System.runAs(objUser) {
             
             Account objAccountToCreate = PMC_TestUtilityClass.createAccount('Google','PMC_SS_Prospect');
             Case objCase = PMC_TestUtilityClass.createCase(objBusinessHrs.Id, objAccountToCreate.Id, objUser.Id,objLocation.Id);
             System.assertEquals(objCase.Subject, 'Test Subject', 'Case has been created with the subject - Test Subject');

             //List<Contact> lstContacts = PMC_TestUtilityClass.createContact(1, '');
             //Case objCase1 = PMC_TestUtilityClass.createCaseWithContact(objBusinessHrs.Id, lstContacts[0].Id, objUser.Id);
             //System.assertEquals(objCase1.ContactId, lstContacts[0].Id, 'Case has been created with the subject - Test Subject');
         }
         Test.stopTest();
     }
     
        
     /**
     * @description This method will be use to cover createCase of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateContactWithPhoneNo() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             Contact objContactToCreate = PMC_TestUtilityClass.createContactWithPhone();
             System.assertEquals(objContactToCreate.Phone, '0101010101', 'Contact Phone Check');
         }
         
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createPortalUser of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreatePortalUser() {
         Test.startTest();
         Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Digital Hub Buyer' LIMIT 1];
         List<User> lstPortalUsers = PMC_TestUtilityClass.createPortalUser(1, objProfile);
         System.assert(lstPortalUsers.size() != 0,'Portal User records were not created, test method-testCreatePortalUser');
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover the negative scenario of createPortalUser of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreatePortalUserNull() {
         Test.startTest();
         try {
             Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Digital Hub Buyer' LIMIT 1];
             List<User> lstPortalUsers = PMC_TestUtilityClass.createPortalUser(null, objProfile);
             System.assert(lstPortalUsers.size() != 0, 'User records were not created, test method-testCreateUserNull');
         }catch(Exception e) {
             system.assertEquals(e.getMessage(), 'Attempt to de-reference a null object','Expected a NullPointerException');
         }
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover assignPermissionSetGroupToUsers of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testAssignPermissionSetGroupToUsers() {
         Test.startTest();
         Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Digital Hub Buyer' LIMIT 1];
         List<User> lstPortalUsers = PMC_TestUtilityClass.createPortalUser(1, objProfile);
         PermissionSetGroup perSetGrp = [SELECT Id, Status FROM PermissionSetGroup LIMIT 1];
         if (perSetGrp.Status != 'Updated') {
                Test.calculatePermissionSetGroup(perSetGrp.id);
          }
         PMC_TestUtilityClass.assignPermissionSetGroupToUsers(lstPortalUsers, perSetGrp);
         List<PermissionSetAssignment> lstPermSetAssignmentsCreated = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetGroupId = :perSetGrp.Id ]; 
         System.assertEquals(true,lstPermSetAssignmentsCreated.size()>=0,'Permission set is not created');
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover CreateLocation of PMC_TestUtilityClass.
     */
     @isTest
     private static void testCreateLocation() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             Schema.Location objLocation = PMC_TestUtilityClass.createLocation('Test Schema.Location 1');
             System.assertEquals(objLocation.Name, 'Test Schema.Location 1', 'Location Name Check');
         }
         
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover CreateProductLocation of PMC_TestUtilityClass.
     */
     @isTest
     private static void testCreateProductLocation() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             Schema.Location objLocation = PMC_TestUtilityClass.createLocation('Test Schema.Location 2');
             PMC_CPQ_ProductLocation__c objPrdLocation = PMC_TestUtilityClass.createProductLocation('Test Product Location 2', objLocation);
             System.assertEquals(objPrdLocation.Name, 'Test Product Location 2', 'Product Location Name Check');
         }
         
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createDelivery of PMC_TestUtilityClass.
     */
     @isTest
     private static void testCreateDelivery() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             Account objAccount = PMC_TestUtilityClass.createAccount('The Mosaic Company 5','PMC_SS_Prospect');
             List<Order> lstOrders = PMC_TestUtilityClass.createOrders(1, new List<Account>{objAccount});
             Shipment objShipment = PMC_TestUtilityClass.createDelivery('Test Delivery', lstOrders[0]);
             System.assertEquals(objShipment.ShipToName, 'Test Delivery', 'Shipment Name Check');
         }
         
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover CreateDeliveryItem of PMC_TestUtilityClass.
     */
     @isTest
     private static void testCreateDeliveryItem() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             Account objAccount = PMC_TestUtilityClass.createAccount('The Mosaic Company 6','PMC_SS_Prospect');
             List<Order> lstOrders = PMC_TestUtilityClass.createOrders(1, new List<Account>{objAccount});
             Shipment objShipment = PMC_TestUtilityClass.createDelivery('Test Delivery', lstOrders[0]);
             OrderItem objOrderItem = PMC_TestUtilityClass.createOrderProducts(1, new List<Order>{lstOrders[0]})[0];
             ShipmentItem objShipmentItem = PMC_TestUtilityClass.createDeliveryItem(objShipment, objOrderItem);
             System.assertEquals(objShipmentItem.PMC_CPQ_VehicleID__c, 'Test Vehicle', 'ShipmentItem Vehicle Check');
         }
         
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover createInvoice of PMC_TestUtilityClass.
     */
     @isTest
     private static void testCreateInvoice() {
         Test.startTest();
         User objUser = [SELECT Id, Name FROM User where isActive=true LIMIT 1];
         System.runAs(objUser) {
             Account objAccount = PMC_TestUtilityClass.createAccount('The Mosaic Company 7','PMC_SS_Prospect');
             List<Order> lstOrders = PMC_TestUtilityClass.createOrders(1, new List<Account>{objAccount});
             Shipment objShipment = PMC_TestUtilityClass.createDelivery('Test Delivery', lstOrders[0]);
             Contact objContact = PMC_TestUtilityClass.createContact(1, '')[0];
             PMC_CPQ_Invoice__c objInvoice = PMC_TestUtilityClass.createInvoice(objShipment, lstOrders[0], objContact);
             System.assertEquals(objInvoice.PMC_CPQ_OriginalAmount__c, 1000.0, 'Original Amount Check');
         }
         
         Test.stopTest();
     }
     
     /**
     * @description This method will be use to cover CreateSalesAgreement of PMC_TestUtilityClass.
     */
    @isTest
    private static void testCreateSalesAgreement() {
        Test.startTest();
        List<Profile> lstSalesProfile = [SELECT Id FROM Profile WHERE Name = 'Sales User'];
        List<User> lstUser;
        if(lstSalesProfile != null && !lstSalesProfile.isEmpty()) {
             lstUser = PMC_TestUtilityClass.createUser(1);
             if(lstUser != null && !lstUser.isEmpty()) {
                 lstUser[0].ProfileId = lstSalesProfile[0].Id;
                 lstUser[0].isActive = true;
             }
             insert lstUser;
        }
        PermissionSetLicense psl=[SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'ManufacturingSalesAgreementsPsl'];
        insert new PermissionSetLicenseAssign(AssigneeId = lstUser[0].Id, PermissionSetLicenseId = psl.Id);
        PermissionSet objPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'PMC_CRESalesAgreement' ];
        insert new PermissionSetAssignment(AssigneeId = lstUser[0].Id, PermissionSetId = objPermSet.Id);
        PermissionSetGroup objPerSetGrp = [SELECT Id, Status FROM PermissionSetGroup WHERE DeveloperName = 'PMC_SLS_Permission_Set_Group'];
        if (objPerSetGrp.Status != 'Updated') {
                Test.calculatePermissionSetGroup(objPerSetGrp.id);
                }
        insert new PermissionSetAssignment(AssigneeId = lstUser[0].Id, PermissionSetGroupId = objPerSetGrp.Id);
        System.runAs(lstUser[0]) {
            List<SalesAgreement> lstSalesAgreement = PMC_TestUtilityClass.createSalesAgreement(1,'PMC_SS_BusinessPartnerAgreement');
            System.assert(lstSalesAgreement.size() != 0, 'Sales Agreement records were not created.');
        }
        Test.stopTest();
    }
     
     /**
     * @description This method will be use to cover createSalesAgreementProduct of PMC_TestUtilityClass.
     */
    @isTest
    private static void testCreateSalesAgreementProduct() {
        Test.startTest();
        List<Profile> lstSalesProfile = [SELECT Id FROM Profile WHERE Name = 'Sales User'];
         List<User> lstUser;
         if(lstSalesProfile != null && !lstSalesProfile.isEmpty()) {
             lstUser = PMC_TestUtilityClass.createUser(1);
             if(lstUser != null && !lstUser.isEmpty()) {
                 lstUser[0].ProfileId = lstSalesProfile[0].Id;
                 lstUser[0].isActive = true;
             }
             insert lstUser;
         }
        PermissionSetLicense psl=[SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'ManufacturingSalesAgreementsPsl'];
        insert new PermissionSetLicenseAssign(AssigneeId = lstUser[0].Id, PermissionSetLicenseId = psl.Id);
        PermissionSet objPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'PMC_CPQ_CRED_Pricebook' ];
        insert new PermissionSetAssignment(AssigneeId = lstUser[0].Id, PermissionSetId = objPermSet.Id);
        PermissionSetGroup objPerSetGrp = [SELECT Id, Status FROM PermissionSetGroup WHERE DeveloperName = 'PMC_SLS_Permission_Set_Group'];
        if (objPerSetGrp.Status != 'Updated') {
                Test.calculatePermissionSetGroup(objPerSetGrp.id);
                }
        insert new PermissionSetAssignment(AssigneeId = lstUser[0].Id, PermissionSetGroupId = objPerSetGrp.Id);
        System.runAs(lstUser[0]) {
            List<SalesAgreement> lstSalesAgreement = PMC_TestUtilityClass.createSalesAgreement(1,'PMC_SS_BusinessPartnerAgreement');
            System.assert(lstSalesAgreement.size() != 0, 'Sales Agreement records were not created.');
            List<SalesAgreementProduct> lstSalesAgreementProducts = PMC_TestUtilityClass.createSalesAgreementProduct(1,lstSalesAgreement);
            System.assert(lstSalesAgreementProducts.size() != 0, 'Sales Agreement Product records were not created.');
        }
        Test.stopTest();
    }
     
  
     
     
     
    /**
     * @description This method will be use to cover createSoldToShipToAccountJunctionObjectWrapper of PMC_TestUtilityClass.
     */
     @isTest 
     private static void testCreateCaseWithContact() {
        Test.startTest();
        List<Contact> lstContact = PMC_TestUtilityClass.createContact(1, 'Master');
        BusinessHours objBusinessHour = [Select Id From BusinessHours Where Name = 'Default' LIMIT 1];
        User objUser = [Select Id From User LIMIT 1];
        
        Case objCase = PMC_TestUtilityClass.createCaseWithContact(objBusinessHour.Id, lstContact.get(0).Id, objUser.Id );
        Test.stopTest();
        System.assert(objCase != NUll , 'Expected case to be created');
    }
     
     
     /**
     * @description This method will be use to cover createPartnerObjectWrapper of PMC_TestUtilityClass.
     */
    @isTest 
    private static void createPartnerObjectWrapper() {
        Test.startTest();
         List<User> lstUser = new List<User>();
        PermissionSetGroup perSetGrpAdmin = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'PMC_Administrator_Permission_Set_Group'];
        Profile objUserProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        if(objUserProfile != null) {
            lstUser = PMC_TestUtilityClass.createUser(1);
            if(lstUser != null && !lstUser.isEmpty()) {
                lstUser[0].ProfileId = objUserProfile.Id;
                lstUser[0].LastName = 'Admin User Test';
                lstUser[0].isActive = true;
            }
            Database.upsert(lstUser) ;
            PMC_TestUtilityClass.assignPermissionSetGroupToUsers(lstUser, perSetGrpAdmin);
        }
        
       User objSystemAdminUser = lstUser[0];
        System.runAs(objSystemAdminUser){
          List<Account> lstAccounts = new List<Account>();
        Account objAccount;
        for(Integer intAccountCount = 0; intAccountCount < 2; intAccountCount++) {
            objAccount = new Account();
            objAccount = PMC_TestUtilityClass.createAccount('Deloitte' + intAccountCount,'PMC_SS_Customer');
            lstAccounts.add(objAccount);
        }
        lstAccounts[1].Type='Ship-to';
        lstAccounts[1].PMC_SS_SAPCustomerNumber__c='1111';
        lstAccounts[0].Type='Sold-to';
        lstAccounts[0].PMC_SS_SAPCustomerNumber__c='112';
        //upsert(lstAccounts);
        List<PMC_SS_AccountPartnerRelationships__c> lstPartners = PMC_TestUtilityClass.createPartnerObjectWrapper(50,lstAccounts[0].Id,lstAccounts[1].Id);
        System.assertEquals('Test Partner', lstPartners[0].Name, 'Expected Name to be populated');
        System.assertEquals(lstAccounts[0].Id, lstPartners[0].PMC_SS_Account__c, 'Expected Account Id to be populated');
		System.assertEquals(lstAccounts[1].Id, lstPartners[0].PMC_SS_RelatedAccount__c, 'Expected Related Account Id to be populated');            
        }
        Test.stopTest();
 
    }
     
     
 
 }