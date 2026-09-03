/**
* @description : Test class for PMC_DH_ShipToAddressCreationController
* @author      : Krishan Jangir
**/
@Istest
public with sharing class PMC_DH_ShipToAddressCreationTest { 
    @testSetup  static void setup()
    {
        Account acc = PMC_DH_TestDataFactoryClass.createParentTestAccount();
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Digital Hub Super Buyer' LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id); 
        
        User user=[SELECT id, Contact.IndividualId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
       
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        
        System.runAs(user){
            PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
        }
        
    }
    
    @IsTest
    public static void createShipToAddressTest(){
        
        Test.startTest();        
        User usr=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
        Id lstPermSet=[select id from PermissionSet where Name ='PMC_DH_Account_Switcher'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet);
        // Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        // PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id,lstPermSet1);
        // Account objAcc = [select id,Name,Phone,ParentId,PMC_SS_TaxIDOrCNPJOrCPF__c,RecordTypeId,PMC_DH_Delivery_Instruction__c,PMC_SS_RegionalManager__c,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,Type,CurrencyIsoCode from Account where name='Ship To Account123' limit 1][0];
        Account objAcc1 = [select id,CurrencyIsoCode from Account where name='Parent Test Account'];
        System.runAs(usr){
        PMC_DH_ShipToAddressCreationController.AddressDetails addressDetailsWrapper = new PMC_DH_ShipToAddressCreationController.AddressDetails();
        addressDetailsWrapper.strAddressName = 'Alia'; 
        addressDetailsWrapper.strAddress = '123 Church Street';
        addressDetailsWrapper.strNumber = '987654';
        addressDetailsWrapper.strCity = 'San Francisco';
             addressDetailsWrapper.strPersonOrOrganization='Person';
        addressDetailsWrapper.strZipcode = '23456738';
        addressDetailsWrapper.strCnpj = '98787645623';
              addressDetailsWrapper.strState = 'AL';
            addressDetailsWrapper.strcountry = 'US';
             addressDetailsWrapper.strcontactPhone ='000-000-0000';
        addressDetailsWrapper.strDeliveryInstructions = 'Deliver Safely';
           PMC_DH_ShipToAddressCreationController.AddressDetails addressDetailsWrapper1 = new PMC_DH_ShipToAddressCreationController.AddressDetails();
        addressDetailsWrapper1.strAddressName = 'Ship To Account123'; 
        addressDetailsWrapper1.strAddress = '123 Test Avenue';
        addressDetailsWrapper1.strNumber = '987654';
        addressDetailsWrapper1.strCity = 'San Francisco';
        addressDetailsWrapper1.strZipcode = '23456738';
           addressDetailsWrapper1.strPersonOrOrganization='Person';
        addressDetailsWrapper1.strCnpj = '98787645623';
        addressDetailsWrapper1.strDeliveryInstructions = 'Deliver Safely';
        addressDetailsWrapper1.strState = 'AL';
            addressDetailsWrapper1.strcountry = 'US';
             addressDetailsWrapper1.strcontactPhone ='000-000-0000';
        String str = JSON.serialize(addressDetailsWrapper);
                    String str1 = JSON.serialize(addressDetailsWrapper1);
            //Account acc = PMC_DH_ShipToAddressCreationController.createShipToAddress(objAcc1.id,str);
            PMC_DH_ShipToAddressCreationController.PMC_DH_CreateShipToAddressWrapper acc = PMC_DH_ShipToAddressCreationController.createShipToAddress(objAcc1.id,str); //changes as part of GDASF-19642
          PMC_DH_ShipToAddressCreationController.PMC_DH_CreateShipToAddressWrapper acc1 = PMC_DH_ShipToAddressCreationController.createShipToAddress(objAcc1.id,str1); //changes as part of GDASF-19642

            // PMC_DH_ShipToAddressCreationController.createTaskForSalesTeam(objAcc.id);
            // PMC_DH_ShipToAddressCreationController.createSoldToShipToRelation(objAcc1.Id, objAcc.id,'USD');
            //System.assertEquals(addressDetailsWrapper.strAddressName, acc.Name,'Account Names not matching');
           // System.assertEquals(addressDetailsWrapper.strAddressName, acc.objAccount.Name,'Account Names not matching'); //changes as part of GDASF-19642
        }
                
         
            
            Test.stopTest();        
    }
    @IsTest
    public static void getAddressTypeTest(){
        
        Test.startTest();  
        PMC_DH_ShipToAddressCreationWrapper wrp;
        wrp=new PMC_DH_ShipToAddressCreationWrapper();
        List<PMC_DH_ShipToAddressCreationWrapper.AddressType> lstaddr=PMC_DH_ShipToAddressCreationController.getAddressType('Ship-to');
        System.assertNotEquals(null, lstaddr,'addr test case 2');
        Test.stopTest();
    }
    @IsTest
    public static void getNewAddressStateDetailsTest(){
        User userSuperBuer=[SELECT id from User WHERE Username = 'demouser@test.com.testuser'];
        Test.startTest();
        System.runAs(userSuperBuer){
            string addr =PMC_DH_ShipToAddressCreationController.getNewAddressStateDetails();
            System.assertNotEquals(null, addr,'addr test case 2');
        }
        Test.stopTest();
    }
    @isTest
    public static void getCreateExceptionTest(){
        Test.startTest();
        
        Boolean exceptionOccurred;
            try{
                PMC_DH_ShipToAddressCreationController.throwUsersTestException = true;
                PMC_DH_ShipToAddressCreationController.createShipToAddress(null,null);
            }catch(exception e){
                exceptionOccurred=true;
            }
            System.assert(exceptionOccurred, 'An Exception was not thrown');
        
        test.stopTest();
    }
    @isTest
    public static void getNewStateExceptionTest(){
        Test.startTest();
        PMC_DH_ShipToAddressCreationController.throwUsersTestException = true;
        String result = PMC_DH_ShipToAddressCreationController.getNewAddressStateDetails();
        
        System.assert(result!=null, 'An Exception was not thrown');
        
        test.stopTest();
    }

}