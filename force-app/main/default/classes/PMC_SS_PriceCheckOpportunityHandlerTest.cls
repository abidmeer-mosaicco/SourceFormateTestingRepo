/**
 * @description Test class for PMC_SS_PriceCheckOpportunityHandler
 * @author Megha Sunhare
 * @storyNumber GDASF-7257
 */
@isTest
private with sharing class PMC_SS_PriceCheckOpportunityHandlerTest {

    /**
     * @description : Test setup method to prepare data for test.
     */
    @TestSetup
    private static void testSetupData(){
        
        List<String>lstProfileNames = New List<String>{'System Administrator','Sales User'};
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SLS_Permission_Set_Group'};
            
        UserRole objAdminUserRole = [SELECT Id FROM UserRole WHERE Name = 'Admin' LIMIT 1];
    
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
                   objUser.userRoleId = objAdminUserRole.Id;
                }else if(intuserCount==1){
                    objUser.LastName = 'Sales User Test';
                    objUser.ProfileId = mapOfProfiles.get('Sales User');
                }
                objUser.isActive = true;                
                objUser.MobilePhone = '1234567890';
                intuserCount = intuserCount + 1;
            }            
            insert lstUser;
            objSystemAdminUser = lstUser[0];
            objSalesUser = lstUser[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSalesUser}, mapOfPermissionGrp.get('PMC_SLS_Permission_Set_Group'));
        
        List<User> lstPortalUsers;
        System.runAs(objSystemAdminUser){
            Profile objDHBuyerProfile = [SELECT Id FROM Profile WHERE Name = 'Digital Hub Buyer' LIMIT 1];
            if(objDHBuyerProfile != null){
                lstPortalUsers = PMC_TestUtilityClass.createPortalUser(1, objDHBuyerProfile);
                PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm'];
                Insert new PermissionSetLicenseAssign(AssigneeId = lstPortalUsers[0].id, PermissionSetLicenseId = psl.Id);
            	PermissionSetGroup ps = [SELECT Id, Status FROM PermissionSetGroup WHERE DeveloperName = 'PMC_DH_Buyer_Permission_Set_Group'];
                if (ps.Status != 'Updated') {
                Test.calculatePermissionSetGroup(ps.id);
                }
                insert new PermissionSetAssignment(AssigneeId = lstPortalUsers[0].Id, PermissionSetGroupId = ps.Id);
            }
        }

        System.runAs(objSystemAdminUser){
            Account objAccount = PMC_TestUtilityClass.createAccount('Test Account for Opportunity', 'PMC_SS_Customer');
            objAccount.OwnerId = lstPortalUsers.get(0).Id;
            update objAccount;
            
            List<Opportunity> lstOpportunities = PMC_TestUtilityClass.createOpportunity(1, '');
            lstOpportunities.get(0).Name = PMC_SS_ConstantClass.PRICE_CHECK_OPPORTUNITY_NAME_SUBSTRING + objAccount.Name;
            lstOpportunities.get(0).PMC_SS_ProductFamilies__c = 'ATHOS;DAP-MAP;GYPSUM';
            lstOpportunities.get(0).CloseDate = System.today() + 4;
            lstOpportunities.get(0).AccountId = objAccount.Id;
            lstOpportunities.get(0).OwnerId = lstPortalUsers.get(0).Id;
			lstOpportunities.get(0).CurrencyIsoCode = 'USD';
            lstOpportunities.get(0).PMC_SS_OpportunitySource__c = 'Web';
            update lstOpportunities;
        }

    }

    /**
     * @description : Test method to test the update existing opportunity scenario
     */
    @isTest
    private static void testOpportunityUpdateOnPriceCheck(){
        
        Test.startTest();
        User objPortalUser = [SELECT Id, Name FROM User WHERE IsActive = true AND Profile.Name = 'Digital Hub Buyer' AND FirstName = 'Test Portal'  WITH SECURITY_ENFORCED LIMIT 1];
        Account objAccount = [SELECT Id FROM Account WHERE OwnerId = :objPortalUser.Id LIMIT 1];
        Opportunity objOpportunity = [SELECT Id, Name, PMC_SS_ProductFamilies__c FROM Opportunity WHERE OwnerId = :objPortalUser.Id AND AccountId = :objAccount.Id LIMIT 1];
                
        List<String> lstProductInterests = new List<String>{'DAP-MAP','GYPSUM','ATHOS'};
        String strOpportunityId;
        System.runAs(objPortalUser){
            strOpportunityId = PMC_SS_PriceCheckOpportunityHandler.createOpportunityForGetPriceCall(objAccount.Id, lstProductInterests, 'USD');
        }         
        Test.stopTest();
        
        //Opportunity objUpdatedOpportunity = [SELECT Id, CloseDate FROM Opportunity WHERE Id = :strOpportunityId];
        
        System.assertEquals(objOpportunity.Id, strOpportunityId, 'Expected existing opportunity to be updated');
    }
    
    /**
     * @description : Test method to test the create new opportunity scenario
     */
    @isTest
    private static void testOpportunityCreateOnPriceCheck(){
        
        Test.startTest();
        User objPortalUser = [SELECT Id, Name FROM User WHERE IsActive = true AND Profile.Name = 'Digital Hub Buyer' AND FirstName = 'Test Portal'  WITH SECURITY_ENFORCED LIMIT 1];
        Account objAccount = [SELECT Id, Name FROM Account WHERE OwnerId = :objPortalUser.Id LIMIT 1];
        Opportunity objOpportunity = [SELECT Id, Name, PMC_SS_ProductFamilies__c FROM Opportunity WHERE OwnerId = :objPortalUser.Id AND AccountId = :objAccount.Id LIMIT 1];
        
        List<String> lstProductInterests = new List<String>{'MES','NITROGEN','ATHOS'};
        String strOpportunityId;
        System.runAs(objPortalUser){
        	strOpportunityId = PMC_SS_PriceCheckOpportunityHandler.createOpportunityForGetPriceCall(objAccount.Id, lstProductInterests, 'CAD');
        }
        Test.stopTest();
        
        Opportunity objNewOpportunity = [SELECT Id, Name, CloseDate, PMC_SS_ProductFamilies__c FROM Opportunity WHERE Id = :strOpportunityId];
        List<String> lstNewOppProdFmlySorted = objNewOpportunity.PMC_SS_ProductFamilies__c.split(';');
        lstNewOppProdFmlySorted.sort();
        lstProductInterests.sort();

        System.assertNotEquals(objOpportunity.Id, strOpportunityId, 'Expected a new opportunity to be created');
        System.assertEquals(lstProductInterests, lstNewOppProdFmlySorted, 'Expected new opportunity to have all the product families selected by user');
        System.assertEquals(PMC_SS_ConstantClass.PRICE_CHECK_OPPORTUNITY_NAME_SUBSTRING + objAccount.Name , objNewOpportunity.Name, 'Expected name to be set as price check for Test Account for Opportunity');
        
    }
    
    /**
     * @description : Teset method to test the null account or product families scenario
    */
    @isTest
    private static void testNullAccountAndProductInterestCheck(){
        
        Test.startTest();
		User objPortalUser = [SELECT Id, Name FROM User WHERE IsActive = true AND Profile.Name = 'Digital Hub Buyer' AND FirstName = 'Test Portal'  WITH SECURITY_ENFORCED LIMIT 1];
        String strOpportunityId;
        System.runAs(objPortalUser){      
        	strOpportunityId = PMC_SS_PriceCheckOpportunityHandler.createOpportunityForGetPriceCall(NULL, NULL, NULL);  
        }
        Test.stopTest();
        
        System.assert(strOpportunityId == '', 'Expected null response');
    }
    
    /**
     * @description : Teset method to test the invalid product family scenario
    */
    @isTest
    private static void testInvalidProductFamily(){      
        
        Test.startTest();
        User objPortalUser = [SELECT Id, Name FROM User WHERE IsActive = true AND Profile.Name = 'Digital Hub Buyer' AND FirstName = 'Test Portal'  WITH SECURITY_ENFORCED LIMIT 1];
        Account objAccount = [SELECT Id, Name FROM Account WHERE OwnerId = :objPortalUser.Id LIMIT 1];
        List<String> lstProductInterests = new List<String>{'DAP-MAP','GYPSUM','Invalid'};
        String strOpportunityId;
        System.runAs(objPortalUser){
        	strOpportunityId = PMC_SS_PriceCheckOpportunityHandler.createOpportunityForGetPriceCall(objAccount.Id, lstProductInterests, 'BRL');      
        }
        Test.stopTest();
        
        List<PMC_ErrorLog__c> lstErrorLog = [SELECT Id FROM PMC_ErrorLog__c];
        
        System.assertEquals(1, lstErrorLog.size(), 'Expected error log record to be inserted');
        System.assertEquals('', strOpportunityId, 'Expected no opportunity Id to be returned');
    }
    
    /**
     * @description : Test method to test if the opportunity owner of existing opportunity is different then in with sharing mode a new opportunity is getting created.
     */
    @isTest
    private static void testOpportunityUpdateOnPriceCheckDifferentUser(){
        
        Test.startTest();
        User objPortalUser = [SELECT Id, Name FROM User WHERE IsActive = true AND Profile.Name = 'Digital Hub Buyer' AND FirstName = 'Test Portal'  WITH SECURITY_ENFORCED LIMIT 1];
        Account objAccount = [SELECT Id FROM Account WHERE OwnerId = :objPortalUser.Id LIMIT 1];
        Opportunity objOpportunity = [SELECT Id, Name, PMC_SS_ProductFamilies__c FROM Opportunity WHERE OwnerId = :objPortalUser.Id AND AccountId = :objAccount.Id LIMIT 1];
        
        User objAdminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        objOpportunity.OwnerId = objAdminUser.Id;
        Update objOpportunity;
                
        List<String> lstProductInterests = new List<String>{'DAP-MAP','GYPSUM','ATHOS'};
        String strOpportunityId;
        System.runAs(objPortalUser){
            strOpportunityId = PMC_SS_PriceCheckOpportunityHandler.createOpportunityForGetPriceCall(objAccount.Id, lstProductInterests, 'USD');
        }         
        Test.stopTest();
        
        //Opportunity objUpdatedOpportunity = [SELECT Id, CloseDate FROM Opportunity WHERE Id = :strOpportunityId];
        
        System.assertEquals(objOpportunity.Id, strOpportunityId, 'Expected existing opportunity to be updated');
    }
    
    /**
     * @description : Test method to test new opportunity creation when account and product families are same on opportunity but the currency is different.
     */
    @isTest
    private static void testOpportunityCreateOnPriceCheckWithNewCurrency(){
        
        Test.startTest();
        User objPortalUser = [SELECT Id, Name FROM User WHERE IsActive = true AND Profile.Name = 'Digital Hub Buyer' AND FirstName = 'Test Portal'  WITH SECURITY_ENFORCED LIMIT 1];
        Account objAccount = [SELECT Id FROM Account WHERE OwnerId = :objPortalUser.Id LIMIT 1];
        Opportunity objOpportunity = [SELECT Id, Name, PMC_SS_ProductFamilies__c FROM Opportunity WHERE OwnerId = :objPortalUser.Id AND AccountId = :objAccount.Id LIMIT 1];
                
        List<String> lstProductInterests = new List<String>{'DAP-MAP','GYPSUM','ATHOS'};
        String strOpportunityId;
        System.runAs(objPortalUser){
            strOpportunityId = PMC_SS_PriceCheckOpportunityHandler.createOpportunityForGetPriceCall(objAccount.Id, lstProductInterests, 'CAD');
        }         
        Test.stopTest();
        
        Opportunity objUpdatedOpportunity = [SELECT Id, CloseDate, CurrencyIsoCode FROM Opportunity WHERE Id = :strOpportunityId];
        
        System.assertNOTEquals(objOpportunity.Id, strOpportunityId, 'Expected new opportunity to be created');
        System.assertEquals('CAD' , objUpdatedOpportunity.CurrencyIsoCode, 'Expected CAD currency to be set');
        
    }
}