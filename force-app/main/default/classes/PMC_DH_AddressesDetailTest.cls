/**
* @description : Test class for PMC_DH_UserDetailController
* @author      : Krishan Jangir
* @userStory   : GDPH-568
* @last modified on 2023-05-15
* @last modified by Nikhilesh
**/
@IsTest
public with sharing class PMC_DH_AddressesDetailTest {
    @testsetup static void testSetup(){
        
        Account acc;
        User user;
        User userAdmin=PMC_DH_TestDataFactoryClass.createAdminUser();
        System.runAs(userAdmin){
        acc=PMC_DH_TestDataFactoryClass.createTestAccount();
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id); 
        user=[SELECT id, Contact.IndividualId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        }
        System.runAs(user){
            Account shipToAcc=new Account();
            //shipToAcc.PMC_DH_Account_Status__c='Active';
            shipToAcc.Name='Ship To Account'; 
            shipToAcc.AccountNumber='Test123';
            shipToAcc.PMC_SS_AccountExternalID__c = '4083583';
            shipToAcc.PMC_SS_SAPCustomerNumber__c = '4083583';
         
            shipToAcc.ShippingStreet = '123 Test Street';
            shipToAcc.BillingStreet = '123 Test Street';
            shipToAcc.BillingCountry='United States';
            shipToAcc.ShippingState = 'Alabama';
            shipToAcc.ShippingCity = 'Baltimore';
            shipToAcc.ShippingPostalCode = '940012';
            shipToAcc.BillingCity='Los Angeles';
            shipToAcc.BillingState='Pennsylvania';
            shipToAcc.BillingPostalCode= '940093';
            shipToAcc.Type = 'Ship-to';
          
            shipToAcc.PMC_DH_Delivery_Instruction__c = 'Deliver safely';
            Id recordTypeId = Schema.SObjectType.Account.getrecordtypeinfosbydevelopername().get('PMC_SS_Customer').getRecordTypeId();
            shipToAcc.RecordTypeId=recordTypeId;
            shipToAcc.Phone='(123) 456-7890'; 

            insert shipToAcc;
            PMC_DH_TestDataFactoryClass.createSoldToShipToAccountJunction(shipToAcc.Id, acc.Id);
            Account shipToAcc2=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            shipToAcc2.PMC_SS_MDMVerified__c = TRUE;
            shipToAcc2.PMC_DH_Account_Status__c='Active';
            shipToAcc2.BillingStreet = '1243 Test Street';
            shipToAcc2.BillingCountry='United States';
            shipToAcc2.BillingCity='Los Angales';
            shipToAcc2.BillingState='Pennsylvania';
            shipToAcc2.BillingPostalCode= '940092';
             shipToAcc2.Phone='(123) 456-7890'; 
            update shipToAcc2;
            PMC_DH_TestDataFactoryClass.createSoldToShipToAccountJunction(shipToAcc2.Id, acc.Id);
        }
    
    }

    @isTest
    public static void getAddressDetailsTest(){
        
        User usr = [SELECT Id, ProfileId, isActive,ContactId,AccountId FROM User WHERE Email='demouser@test.com' AND isActive = TRUE LIMIT 1];
        Account parAcc = [SELECT id from Account where name='Test Account'];
            
        Test.startTest();
        
        System.runAs(usr){
          
            PMC_DH_AddressDetailWrapper result = PMC_DH_AddressesDetailController.getAddressDetails(parAcc.id);
            System.Assert(result!=null, 'Success');
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void getAddressDetailsTestException(){ 
        
        user usr = [Select id,contactId,accountId from User where Username='demouser@test.com.testuser'];
        Account parAcc = [SELECT id from Account where name='Test Account'];
        
        Test.startTest();
        
        system.runAs(usr){
            String strName;
            try{
                PMC_DH_AddressesDetailController.boolThrowException=true;
            	PMC_DH_AddressesDetailController.getAddressDetails(parAcc.id);
        	}
            catch(Exception e){
                strName='Exception';
            }
         	System.assert(strName.equals('Exception'),'Passed');
        }
        
        Test.stopTest();
    }

    @IsTest
    public static void testGetAddrListTypes() {
        user usr = [Select id,contactId,accountId from User where Username='demouser@test.com.testuser'];
        Test.startTest();
        PMC_DH_AddressStatusFilter__mdt record1 = new PMC_DH_AddressStatusFilter__mdt();
        record1.PMC_DH_Status__c = 'Validated';


        PMC_DH_AddressStatusFilter__mdt record2 = new PMC_DH_AddressStatusFilter__mdt();

        record2.PMC_DH_Status__c = 'In Analysis';
        system.runAs(usr){
        List<PMC_DH_PicklistWrapper> result = PMC_DH_AddressesDetailController.getAddrListTypes();

      //  System.assertEquals(2, result.size(),'Success');
        }
        Test.stopTest();
    }

    @IsTest
    public static void testUpdateAddressDetails() {
        Test.startTest();
        Account shipToAcc = [SELECT Id, Name, Type, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, PMC_SS_TaxIDOrCNPJOrCPF__c, ParentId, shippingcountry FROM Account WHERE AccountNumber='Test00123' LIMIT 1];
        PMC_DH_AddressWrapper.AddressViewDetails addDetailwrapper = new PMC_DH_AddressWrapper.AddressViewDetails();
        Account acc1 = [SELECT Id, ParentId FROM Account WHERE Name = 'Test Account' LIMIT 1];
       // Account acc2 = [SELECT Id, ParentId FROM Account WHERE Name = 'Parent Test Account 2' LIMIT 1];

        addDetailwrapper.strAccountId = shipToAcc.Id;
        addDetailwrapper.strNumber = 'Street 1';
        addDetailwrapper.strAddressName = shipToAcc.Name;
        addDetailwrapper.strAddressType = shipToAcc.Type;
        addDetailwrapper.strAddress = shipToAcc.ShippingStreet;
        addDetailwrapper.strCity = shipToAcc.ShippingCity;
        addDetailwrapper.strState = shipToAcc.ShippingState;
        addDetailwrapper.strZipcode = shipToAcc.ShippingPostalCode;
        addDetailwrapper.strCNPJ = shipToAcc.PMC_SS_TaxIDOrCNPJOrCPF__c;
        addDetailwrapper.strCPF = shipToAcc.PMC_SS_TaxIDOrCNPJOrCPF__c;
        addDetailwrapper.boolMandatoryChanged=true;
        addDetailwrapper.strSoldToAcc = acc1.Id;
        addDetailwrapper.strOldSoldToAcc = acc1.Id;
        addDetailwrapper.strCountry = shipToAcc.shippingcountry; 
        addDetailwrapper.strStatus = '';
        addDetailwrapper.strCnpj = 'abcd';
        addDetailwrapper.strDeliveryInstructions = 'Deliver on time';
        //Profile prf = [SELECT Id, name FROM Profile WHERE name = 'Digital Hub Logistics Manager'];
        User usr = [SELECT Id, ProfileId, isActive FROM User WHERE Email='demouser@test.com' AND isActive = TRUE LIMIT 1];

        System.runAs(usr){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_AddressesDetailController.updateAddressDetails(addDetailwrapper, acc1.Id);
            System.assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
    @IsTest
    public static void testUpdateDuplicateAddress() {
        Test.startTest();
        Account shipToAcc = [SELECT Id, Name, Type, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, PMC_SS_TaxIDOrCNPJOrCPF__c, ParentId, shippingcountry FROM Account WHERE AccountNumber='Test123' LIMIT 1];
        PMC_DH_AddressWrapper.AddressViewDetails addDetailwrapper = new PMC_DH_AddressWrapper.AddressViewDetails();
        Account acc1 = [SELECT Id, ParentId FROM Account WHERE Name = 'Test Account' LIMIT 1];
       // Account acc2 = [SELECT Id, ParentId FROM Account WHERE Name = 'Parent Test Account 2' LIMIT 1];
		Account shipToAcc2 = [SELECT Id, ParentId FROM Account WHERE AccountNumber='Test00123' LIMIT 1];
        addDetailwrapper.strAccountId = shipToAcc2.Id;
        addDetailwrapper.strNumber = 'Street 1';
        addDetailwrapper.strAddressName = shipToAcc.Name;
        addDetailwrapper.strAddressType = shipToAcc.Type;
        addDetailwrapper.strAddress = shipToAcc.ShippingStreet;
        addDetailwrapper.strCity = shipToAcc.ShippingCity;
        addDetailwrapper.strState = shipToAcc.ShippingState;
        addDetailwrapper.strZipcode = shipToAcc.ShippingPostalCode;
        addDetailwrapper.strCNPJ = shipToAcc.PMC_SS_TaxIDOrCNPJOrCPF__c;
        addDetailwrapper.boolMandatoryChanged=true;
        addDetailwrapper.strSoldToAcc = shipToAcc.Id;
        addDetailwrapper.strOldSoldToAcc = shipToAcc.Id;
        addDetailwrapper.strCountry = shipToAcc.shippingcountry; 
        addDetailwrapper.strStatus = '';
        addDetailwrapper.strCnpj = shipToAcc.PMC_SS_TaxIDOrCNPJOrCPF__c;//'abcd';
        addDetailwrapper.strDeliveryInstructions = 'Deliver on time';
        //Profile prf = [SELECT Id, name FROM Profile WHERE name = 'Digital Hub Logistics Manager'];
        User usr = [SELECT Id, ProfileId, isActive FROM User WHERE Email='demouser@test.com' AND isActive = TRUE LIMIT 1];

        System.runAs(usr){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_AddressesDetailController.updateAddressDetails(addDetailwrapper, acc1.Id);
            System.assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    @IsTest
    public static void testUpdateAddressDetails1() {
        Test.startTest();
        Account shipToAcc = [SELECT Id, Name, Type, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, PMC_SS_TaxIDOrCNPJOrCPF__c, ParentId, shippingcountry FROM Account WHERE AccountNumber='Test00123' LIMIT 1];
        PMC_DH_AddressWrapper.AddressViewDetails addDetailwrapper = new PMC_DH_AddressWrapper.AddressViewDetails();
        Account acc1 = [SELECT Id, ParentId FROM Account WHERE Name = 'Test Account' LIMIT 1];
        //Account acc2 = [SELECT Id, ParentId FROM Account WHERE Name = 'Parent Test Account 2' LIMIT 1];

        addDetailwrapper.strAccountId = shipToAcc.Id;
        addDetailwrapper.strNumber = 'Street 1';
        addDetailwrapper.strAddressName = shipToAcc.Name;
        addDetailwrapper.strAddressType = shipToAcc.Type;
        addDetailwrapper.strAddress = shipToAcc.ShippingStreet;
        addDetailwrapper.strCity = shipToAcc.ShippingCity;
        addDetailwrapper.strCPF = shipToAcc.PMC_SS_TaxIDOrCNPJOrCPF__c;
        addDetailwrapper.strState = shipToAcc.ShippingState;
        addDetailwrapper.strZipcode = shipToAcc.ShippingPostalCode;
        addDetailwrapper.strCNPJ = shipToAcc.PMC_SS_TaxIDOrCNPJOrCPF__c;
        addDetailwrapper.strSoldToAcc = acc1.Id;
        addDetailwrapper.strOldSoldToAcc = shipToAcc.Id;
        addDetailwrapper.strCountry = shipToAcc.shippingcountry; 
        addDetailwrapper.strStatus = '';
        addDetailwrapper.strCnpj = 'abcd';
        addDetailwrapper.strDeliveryInstructions = 'Deliver on time';
        //Profile prf = [SELECT Id, name FROM Profile WHERE name = 'Digital Hub Logistics Manager'];
         User usr = [SELECT Id, ProfileId, isActive FROM User WHERE Email='demouser@test.com' AND isActive = TRUE LIMIT 1];
      
        System.runAs(usr){
          PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_AddressesDetailController.updateAddressDetails(addDetailwrapper, shipToAcc.Id);  
            
            //PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result2 = PMC_DH_AddressesDetailController.updateAddressDetails(addDetailwrapper, acc1.Id);
            System.assert(result!=null, 'Success');
        }
        Test.stopTest();
    }


    @IsTest
    public static void testUpdateAddressDetailsNotAccessible() {
        Test.startTest();
        Account shipToAcc = [SELECT Id, Name, Type, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, PMC_SS_TaxIDOrCNPJOrCPF__c, ParentId, shippingcountry FROM Account WHERE AccountNumber='Test00123' LIMIT 1];
        PMC_DH_AddressWrapper.AddressViewDetails addDetailwrapper = new PMC_DH_AddressWrapper.AddressViewDetails();
        Account acc1 = [SELECT Id, ParentId FROM Account WHERE Name = 'Test Account' LIMIT 1];

        addDetailwrapper.strAccountId = shipToAcc.Id;
        addDetailwrapper.strNumber = 'Street 1';
        addDetailwrapper.strAddressName = shipToAcc.Name;
        addDetailwrapper.strAddressType = shipToAcc.Type;
        addDetailwrapper.strAddress = shipToAcc.ShippingStreet;
        addDetailwrapper.strCity = shipToAcc.ShippingCity;
        addDetailwrapper.strState = shipToAcc.ShippingState;
        addDetailwrapper.strZipcode = shipToAcc.ShippingPostalCode;
        addDetailwrapper.strCNPJ = shipToAcc.PMC_SS_TaxIDOrCNPJOrCPF__c;
        addDetailwrapper.strSoldToAcc = acc1.Id;
        addDetailwrapper.strCountry = shipToAcc.shippingcountry; 
        addDetailwrapper.strStatus = '';
        addDetailwrapper.strCnpj = 'abcd';
        addDetailwrapper.strDeliveryInstructions = 'Deliver on time';
    
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_AddressesDetailController.updateAddressDetails(addDetailwrapper, acc1.Id);
        System.assert(result!=null, 'Success');
    
        Test.stopTest();
    }
    
    @IsTest
    public static void testUpdateAddressDetailsException() {
        Test.startTest();
        Account shipToAcc = [SELECT Id, Name, Type, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, PMC_SS_TaxIDOrCNPJOrCPF__c, ParentId, shippingcountry FROM Account WHERE AccountNumber='Test00123' LIMIT 1];
        PMC_DH_AddressWrapper.AddressViewDetails addDetailwrapper = new PMC_DH_AddressWrapper.AddressViewDetails();
        Account acc1 = [SELECT Id, ParentId FROM Account WHERE Name = 'Test Account' LIMIT 1];
        //Account acc2 = [SELECT Id, ParentId FROM Account WHERE Name = 'Parent Test Account 2' LIMIT 1];

        addDetailwrapper.strAccountId = shipToAcc.Id;
        addDetailwrapper.strNumber = 'Street 1';
        addDetailwrapper.strAddressName = shipToAcc.Name;
        addDetailwrapper.strAddressType = shipToAcc.Type;
        addDetailwrapper.strAddress = shipToAcc.ShippingStreet;
        addDetailwrapper.strCity = shipToAcc.ShippingCity;
        addDetailwrapper.strState = shipToAcc.ShippingState;
        addDetailwrapper.strZipcode = shipToAcc.ShippingPostalCode;
        addDetailwrapper.strCNPJ = shipToAcc.PMC_SS_TaxIDOrCNPJOrCPF__c;
        addDetailwrapper.strSoldToAcc = acc1.Id;
        addDetailwrapper.strCountry = shipToAcc.shippingcountry; 
        addDetailwrapper.strStatus = '';
        addDetailwrapper.strCPF='989.989.90-09';
        addDetailwrapper.strDeliveryInstructions = 'Deliver on time';
        //Profile prf = [SELECT Id, name FROM Profile WHERE name = 'Digital Hub Logistics Manager'];
        User usr = [SELECT Id, ProfileId, isActive FROM User WHERE Email='demouser@test.com' AND isActive = TRUE LIMIT 1];
        System.runAs(usr){
            PMC_DH_AddressesDetailController.boolThrowException=true;
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_AddressesDetailController.updateAddressDetails(addDetailwrapper, acc1.Id);
            
         	System.assertEquals('100', result.strStatusCode, 'Status code should be 100');
        }
        Test.stopTest();
    }

    @IsTest
    public static void testViewAddressDetails() {
        User usr = [SELECT Id, ProfileId, isActive,ContactId,AccountId FROM User WHERE Username = 'demouser@test.com.testuser' AND isActive = TRUE LIMIT 1];
        
        Test.startTest();
        
        System.runAs(usr){
            /*PMC_SS_AccountPartnerRelationships__c soldToShipToAccount = new PMC_SS_AccountPartnerRelationships__c();
            soldToShipToAccount.PMC_SS_Account__c=parAcc.Id;
            soldToShipToAccount.PMC_SS_RelatedAccount__c=accShipTo.Id;
            soldToShipToAccount.CurrencyIsoCode='USD';
            soldToShipToAccount.PMC_SS_Type__c=PMC_DH_ConstantClass.ACCOUNT_TYPE;
            insert soldToShipToAccount;*/
            PMC_SS_AccountPartnerRelationships__c soldToShipToAccount = [SELECT Id, PMC_SS_RelatedAccount__c FROM PMC_SS_AccountPartnerRelationships__c LIMIT 1];
            PMC_DH_AddressWrapper wrapper = PMC_DH_AddressesDetailController.viewAddressDetails(soldToShipToAccount.Id); 
            System.assertEquals(wrapper.addressData.strAccountId,soldToShipToAccount.PMC_SS_RelatedAccount__c,'Success');
        } 

        Test.stopTest();
    }
    
    @IsTest
    public static void testViewAddressDetailsException() {
        Test.startTest();
        Account shipToAcc = [SELECT Id, Name, Type, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, PMC_SS_TaxIDOrCNPJOrCPF__c, ParentId, shippingcountry FROM Account WHERE AccountNumber='Test00123' LIMIT 1];
        PMC_DH_AddressWrapper.AddressViewDetails addDetailwrapper = new PMC_DH_AddressWrapper.AddressViewDetails();
        
        addDetailwrapper.strAccountId = shipToAcc.Id;
        addDetailwrapper.strNumber = 'Street 1';
        addDetailwrapper.strAddressName = shipToAcc.Name;
        addDetailwrapper.strAddressType = shipToAcc.Type;
        addDetailwrapper.strAddress = shipToAcc.ShippingStreet;
        addDetailwrapper.strCity = shipToAcc.ShippingCity;
        addDetailwrapper.strState = shipToAcc.ShippingState;
        addDetailwrapper.strZipcode = shipToAcc.ShippingPostalCode;
        addDetailwrapper.strCNPJ = shipToAcc.PMC_SS_TaxIDOrCNPJOrCPF__c;
        addDetailwrapper.strSoldToAcc = shipToAcc.ParentId;
        addDetailwrapper.strCountry = shipToAcc.shippingcountry; 
        addDetailwrapper.strStatus = 'Pending';
        //Profile prf = [SELECT Id, name FROM Profile WHERE name = 'Digital Hub Logistics Manager'];
        User usr = [SELECT Id, ProfileId, isActive FROM User WHERE Email='demouser@test.com' AND isActive = TRUE LIMIT 1];

        System.runAs(usr){
            String strName;
            try{
                PMC_DH_AddressesDetailController.boolThrowException=true;
            	PMC_DH_AddressesDetailController.viewAddressDetails(shipToAcc.Id);
            }
            catch(Exception e){
                strName='Exception';
            }
         	System.assert(strName.equals('Exception'),'Passed');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testDeleteAddresses() {
        
        PMC_SS_AccountPartnerRelationships__c objSoldToShipTo = [SELECT ID,PMC_SS_RelatedAccount__c,PMC_SS_Account__c from PMC_SS_AccountPartnerRelationships__c where PMC_SS_RelatedAccount__r.Name='Ship To Account123'];
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_AddressesDetailController.deleteAddresses(objSoldToShipTo.PMC_SS_RelatedAccount__c);
        
        
        System.assertEquals('000', result.strStatusCode,'000');
        System.assertEquals('DeleteAddress', result.strModule,'delete addresses');
    }
}