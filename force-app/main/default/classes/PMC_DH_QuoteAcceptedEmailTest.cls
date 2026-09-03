/**
 * @description Test Class for PMC_DH_QuoteAcceptedEmailController
 * @author hemant giri
 * @since  09-11-2023
 */
@istest
public with sharing class PMC_DH_QuoteAcceptedEmailTest {
   
    @TestSetup
    static void dataSetup(){
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        //Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        
        PMC_DH_TestDataFactoryClass.createTestWebStore();
        system.runAs(user){
            
            PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            Test.startTest();
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            testQuote.PMC_CPQ_ContractStageName__c='Draft';
            update testquote;
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            Test.stopTest();
        }
    }


    
    @isTest
    public static void sendEmailforQuoteAcceptedTest()
    {
        Test.startTest();
        User user=[SELECT id, ContactId, Contact.FirstName, Contact.LastName FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Id conId = user.ContactId;
        Contact con = [SELECT Id, IndividualId FROM Contact WHERE Id =: conId LIMIT 1];
        //if(con.IndividualId == null){
            Individual ind = PMC_DH_TestDataFactoryClass.createIndividual(user);
            con.IndividualId = ind.Id;
            update con;
            DataUseLegalBasis dulb = new DataUseLegalBasis(Name = 'Quotes');
            insert dulb;
            DataUsePurpose dup = new DataUsePurpose(Name = 'Accepted by Account Manager', LegalBasisId = dulb.Id);
            insert dup;
            ContactPointTypeConsent cptc = new ContactPointTypeConsent(ContactPointType = 'Email', 
                                                                       PrivacyConsentStatus = 'OptIn',
                                                                       Name = dup.Name,
                                                                       DataUsePurposeId = dup.Id,
                                                                       PartyId = con.IndividualId);
            insert cptc;
        //}
        system.runAs(user){
            String strQuoteId=[SELECT ID FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'][0].ID;
            List<Id> testIds = new List<Id>();
            testIds.add(strQuoteId);
            List<Boolean> result = PMC_DH_QuoteAcceptedEmailController.sendEmailforQuoteAccepted(testIds);
            System.assert(result != null, 'Success');
        }
        Test.stopTest();
    }
}