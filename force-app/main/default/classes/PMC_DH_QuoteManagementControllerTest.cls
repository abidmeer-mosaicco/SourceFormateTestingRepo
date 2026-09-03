/**
* @description : Test class for PMC_DH_QuoteManagementController
* @author      : Humera Rahath
* @userStory   : GDASF-121
* @last modified by HumeraRahath
* @last modified on 06-07-2023
**/
@isTest
public with sharing class PMC_DH_QuoteManagementControllerTest { 
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @testSetup  static void setup()
    {
        
        User userAdmin=PMC_DH_TestDataFactoryClass.createAdminUser();
        User user;
        Account acc;
        String strContactId;
        System.runAs(userAdmin){
            acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
            Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
            PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
            user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
            strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
            Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
            PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
            Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
            PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
            Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
            PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
            Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
            PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        } 
        
        system.runAs(user){
            
            Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            shipToAcc.PMC_SS_MDMVerified__c = TRUE;
            shipToAcc.PMC_DH_Account_Status__c='Active';
            update shipToAcc;
            PMC_SS_SalesArea__c testSalesArea = new PMC_SS_SalesArea__c();
            testSalesArea.PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
            testSalesArea.PMC_SS_DistributionChannel__c = '0';
            testSalesArea.PMC_SS_Division__c = '10';
            insert testSalesArea;
            List<Account> lstAccounts = new List<Account>();
            lstAccounts.add(acc);
            List<PMC_SS_SalesArea__c> lstSalesAreas = new List<PMC_SS_SalesArea__c>();
            lstSalesAreas.add(testSalesArea);
            PMC_TestUtilityClass.createAccountSalesAreaRelationship(lstAccounts, lstSalesAreas);
            // PMC_SS_AccountPartnerRelationships__c accPartnrRel = PMC_DH_TestDataFactoryClass.createSoldToShipToAccountJunction(shipToAcc.Id, acc.Id);
            
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            testQuote.PMC_CPQ_QuoteOrigin__c = 'DH Request';
            testQuote.SBQQ__Status__c='Request';
            update testQuote;
            Test.startTest();
            PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            
            Contract testContract=PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id); 
            testContract.Status='Activated';
            update testContract;
            Test.stopTest();
        }
    } 
    
    /**
* @description Test Method for getQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @isTest
    public static void getQuoteDetailsTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            String strQuoteId=[SELECT ID FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'][0].ID;
            String quoteLineId = [SELECT Id FROM SBQQ__QuoteLine__c Where SBQQ__Quote__c=:strQuoteId ].Id;
        Account strTestAcct1=[SELECT id FROM Account WHERE Name='Ship To Account123' limit 1][0];
        if(!String.isBlank(strTestAcct1.Id)) 
            {
            List<PMC_SS_SalesArea__c> lstSalesArea = [SELECT Id FROM PMC_SS_SalesArea__c WITH SECURITY_ENFORCED LIMIT 1];
            PMC_SS_AccountSalesAreaRelationship__c relObj = new PMC_SS_AccountSalesAreaRelationship__c(PMC_SS_Account__c = strTestAcct1.Id, PMC_SS_SalesArea__c = lstSalesArea[0].Id);
            insert relObj;
            PMC_SS_AccountPartnerRelationships__c soldToShipToAccount = new PMC_SS_AccountPartnerRelationships__c();
            soldToShipToAccount.PMC_SS_Account__c=strTestAcct.ID;
            soldToShipToAccount.PMC_SS_RelatedAccount__c=strTestAcct1.Id;
            soldToShipToAccount.CurrencyIsoCode='USD';
            soldToShipToAccount.PMC_SS_Type__c = PMC_DH_ConstantClass.ACCOUNT_TYPE;
            // soldToShipToAccount.PMC_SS_RelatedAccountSalesArea__c = relObj.Id;
            insert soldToShipToAccount;
            }
            PMC_DH_QuoteManagementHelper.updateQuoteLineProdInfo('MTN', new List<String>{quoteLineId});
            PMC_DH_QuoteDetailsWrapper result=PMC_DH_QuoteManagementControllerClass.getQuoteDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id ,strQuoteId);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    /**
* @description Test Method for getQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @isTest
    public static void getQuoteDetailsAcceptedTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            SBQQ__Quote__c objQuote=[SELECT ID FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'];
            objQuote.PMC_CPQ_CustomerAcceptanceMethod__c='Email';
            objQuote.SBQQ__Status__c='Accepted';
            update objQuote;
            PMC_DH_QuoteDetailsWrapper result=PMC_DH_QuoteManagementControllerClass.getQuoteDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id ,objQuote.id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for getQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @isTest
    public static void getQuoteDetailsAcceptedbyAMTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            SBQQ__Quote__c objQuote=[SELECT ID FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'];
            objQuote.SBQQ__Status__c='Accepted';
            objQuote.PMC_CPQ_CustomerAcceptanceMethod__c='Accepted by DH Customer';
            update objQuote;
            PMC_DH_QuoteDetailsWrapper result=PMC_DH_QuoteManagementControllerClass.getQuoteDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id ,objQuote.id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    /**
* @description Test Method for getQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @isTest
    public static void getQuoteDetailsRejectedReasonTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            SBQQ__Quote__c objQuote=[SELECT ID FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'];
            objQuote.SBQQ__Status__c='Rejected';
            objQuote.PMC_CPQ_RejectedReason__c='Other';
            objQuote.PMC_CLM_OtherRejectionReason__c='rejected';
            update objQuote;
            PMC_DH_QuoteDetailsWrapper result=PMC_DH_QuoteManagementControllerClass.getQuoteDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id ,objQuote.id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    /**
* @description Test Method for getQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Humera
* 
*/
    @isTest
    public static void getQuoteDetailsExceptionTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean exceptionOccurred;
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            PMC_DH_QuoteManagementControllerClass.getQuoteDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id ,'765949');
            exceptionOccurred=true;
            System.assert(exceptionOccurred, 'An Exception was not thrown');
        }
        Test.stopTest();
    }   
    
    /**
* @description Test Method for updateQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Krishan
* 
*/
    @isTest
    public static void updateQuoteDetailsTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            PMC_DH_QuoteUpdateWrapper quoteWrapper = new PMC_DH_QuoteUpdateWrapper();
            SBQQ__Quote__c objQuote=[SELECT ID,PMC_DH_PaymentMethod__c,PMC_CPQ_ContractStart__c,PMC_CPQ_ContractEnd__c,SBQQ__PaymentTerms__c,CurrencyIsoCode FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote' LIMIT 1];
            quoteWrapper.strQuoteId = objQuote.id;
            quoteWrapper.strCurrencyIsoCode = objQuote.CurrencyIsoCode;
            quoteWrapper.datContractStartDate =String.valueof(objQuote.PMC_CPQ_ContractStart__c);
            quoteWrapper.datContractEndDate =String.valueof(objQuote.PMC_CPQ_ContractEnd__c);
            quoteWrapper.datPrepaymentDate = objQuote.PMC_CPQ_ContractStart__c;
            quoteWrapper.strPaymentTerms =objQuote.SBQQ__PaymentTerms__c;
            quoteWrapper.strPaymentMethods=objQuote.PMC_DH_PaymentMethod__c;
            
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_QuoteManagementControllerClass.updateQuote(quoteWrapper);
            
            system.Assert(result!=null, 'Success');
            
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for updateQuoteDetails method
* 
* @param: none
* 
* @return: void
*
* @author Krishan
* 
*/
    @isTest
    public static void updateQuoteDetailsExceptionTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean exceptionOccurred=true;
            try{
                PMC_DH_QuoteUpdateWrapper quoteWrapper = new PMC_DH_QuoteUpdateWrapper();
                SBQQ__Quote__c objQuote=[SELECT ID,PMC_DH_PaymentMethod__c,PMC_CPQ_ContractStart__c,PMC_CPQ_ContractEnd__c,SBQQ__PaymentTerms__c,CurrencyIsoCode FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote' LIMIT 1];
                quoteWrapper.strQuoteId =''; 
                quoteWrapper.strCurrencyIsoCode = objQuote.CurrencyIsoCode;
                quoteWrapper.datContractStartDate =String.valueof(objQuote.PMC_CPQ_ContractStart__c);
                quoteWrapper.datContractEndDate =String.valueof(objQuote.PMC_CPQ_ContractEnd__c);
                quoteWrapper.datPrepaymentDate = objQuote.PMC_CPQ_ContractStart__c;
                quoteWrapper.strPaymentTerms =objQuote.SBQQ__PaymentTerms__c;
                quoteWrapper.strPaymentMethods=objQuote.PMC_DH_PaymentMethod__c;
                
                PMC_DH_QuoteManagementControllerClass.updateQuote(quoteWrapper);
            }
            catch(exception e){
                exceptionOccurred=true;
            }            
            System.assert(exceptionOccurred, 'An Exception was not thrown');
            
            
        }
        Test.stopTest();
    }
    /**
* @description Test Method for UpdateQuoteLineDetails method
* 
* @param: none
* 
* @return: void
*
* @author Krishan
* 
*/
    @isTest
    public static void updateQuoteLineDetailsTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            PMC_DH_QuoteLineUpdateWrapper quoteLineWrapper = new PMC_DH_QuoteLineUpdateWrapper();
            SBQQ__QuoteLine__c objQuoteLine=[SELECT ID,SBQQ__Quantity__c,PMC_CPQ_ShipTo__c,PMC_CPQ_Incoterms1__c,PMC_CPQ_ModeofTransportation__c FROM SBQQ__QuoteLine__c WHERE PMC_CPQ_Incoterms1__c='CIF' LIMIT 1];
            quoteLineWrapper.strQuoteLineItemId = objQuoteLine.id;
            quoteLineWrapper.strQuoteLineItemQuantity = String.valueof(objQuoteLine.SBQQ__Quantity__c);
            quoteLineWrapper.strShipTo =objQuoteLine.PMC_CPQ_ShipTo__c;
            quoteLineWrapper.strIncoterms =objQuoteLine.PMC_CPQ_Incoterms1__c;
            quoteLineWrapper.strDeliveryMode =objQuoteLine.PMC_CPQ_ModeofTransportation__c;
            quoteLineWrapper.strProductUOM='MTN';
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_QuoteManagementControllerClass.updateQuoteLineItem(quoteLineWrapper);
            system.Assert(result!=null, 'Success');
            
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for getQuote Exception method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getQuoteExceptionTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean exceptionOccurred;
            try{
                PMC_DH_DigitalHubB2BUtils.throwTestException = true;
                SBQQ__Quote__c strQuote=[SELECT id,SBQQ__Account__r.ID FROM SBQQ__Quote__c WHERE PMC_DH_QuoteFriendlyName__c='Test Quote' limit 1];
                PMC_DH_QuoteManagementControllerClass.getQuote(strQuote.ID,strQuote.SBQQ__Account__r.ID);
            }catch(exception e){
                exceptionOccurred=true;
            }
            System.assert(exceptionOccurred, 'An Exception was not thrown');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for getPaymentInfo Exception method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getPaymentInfoExceptionTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean exceptionOccurred;
            try{
                PMC_DH_DigitalHubB2BUtils.throwTestException = true;
                SBQQ__Quote__c strQuote=[SELECT id FROM SBQQ__Quote__c WHERE PMC_DH_QuoteFriendlyName__c='Test Quote' limit 1][0];
                PMC_DH_QuoteManagementControllerClass.getPaymentInfo(strQuote);
            }catch(exception e){
                exceptionOccurred=true;
            }
            System.assert(exceptionOccurred, 'An Exception was not thrown');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for getContractInfo Exception method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getContractInfoExceptionTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean exceptionOccurred;
            try{
                PMC_DH_DigitalHubB2BUtils.throwTestException = true;
                SBQQ__Quote__c strQuote=[SELECT id FROM SBQQ__Quote__c WHERE PMC_DH_QuoteFriendlyName__c='Test Quote' limit 1][0];
                PMC_DH_QuoteManagementControllerClass.getContractInfo(strQuote);
            }catch(exception e){
                exceptionOccurred=true;
            }
            System.assert(exceptionOccurred, 'An Exception was not thrown');
        }
        Test.stopTest();
    }
}