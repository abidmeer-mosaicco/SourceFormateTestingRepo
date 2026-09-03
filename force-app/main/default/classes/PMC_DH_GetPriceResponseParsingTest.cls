/**
* @description : Test class for PMC_DH_GetPriceResponseParsing
* @author      : Rohan Undale
* @userStory   : GDASF-6862 
* @last modified by Rohan Undale
* @last modified on 08-02-2023
**/
@isTest
public with sharing class PMC_DH_GetPriceResponseParsingTest {
    
    
    
    public static final String RESPONSE_SUCCESS='{"HeaderSet":{"Header":{"PriceDate":"2023-07-19","Ztransid":"Q-01308","QtValidT":"2023-07-15","ReturnSet":"","ReqDateH":"2023-07-29","PartnerSet":{"Partner":[{"PartnRole":"SH","Ztransid":"Q-01308","PartnNumb":"30000009","ZrefTransid":"?","ItmNumber":"1"},{"PartnRole":"SH","Ztransid":"Q-01308","PartnNumb":"30000009","ZrefTransid":"?","ItmNumber":"2"},{"PartnRole":"SP","Ztransid":"Q-01308","PartnNumb":"30000009","ZrefTransid":"?","ItmNumber":"0"}]},"DistrChan":"00","QtValidF":"2023-07-04","PurchNoC":"","Price_CondSet":[{"Price_Cond":[{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"500.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZLST"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"10.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZF01"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"SKTV"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZLTX"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZITD"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZITE"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZITR"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZITR"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"PCIP"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"50.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZFIT"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZPMN"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZNTB"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"500.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZLST"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"10.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZF01"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"SKTV"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZLTX"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZITD"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZITE"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZITR"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZITR"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"PCIP"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"50.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZFIT"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZPMN"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZNTB"}]}],"Pmnttrms":"0001","ItemSet":{"Item":[{"Ztransid":"Q-01308","CondValue":"0.000","ReqQty":"0000000000001","SalesUnit":"STN","Material":"1000229","Incoterms2":"SAP/Supply chain","Incoterms1":"CFR","TargetQty":"0000000000001","Plant":"1002","PurchNoC":"","TargetQu":"STN","ZrefTransid":"?","ItmNumber":"1","CondType":""},{"Ztransid":"Q-01308","CondValue":"0.000","ReqQty":"0000000000001","SalesUnit":"STN","Material":"1000229","Incoterms2":"SAP/Supply chain","Incoterms1":"CFR","TargetQty":"0000000000001","Plant":"1002","PurchNoC":"","TargetQu":"STN","ZrefTransid":"?","ItmNumber":"2","CondType":""}]},"SalesOrg":"1002","Currency":"USD","Division":"10","ZrefTransid":"?","PurchDate":"2023-07-19","Raw_MaterialSet":{"Raw_Material":{"Ztransid":"","ZrefTransid":""}},"DocType":"ZQP","ShipCond":"Z1","Item_RSet":{"Item_R":[{"TaxAmount":"0.0000","Zpricerefresh":"","HgLvItem":"000000","Ztransid":"Q-01308","NetValue":"0.5100","Material":"1000229","ZrefTransid":"?","ItmNumber":"1","Zprcduedt":"2023-08-08"},{"TaxAmount":"0.0000","Zpricerefresh":"","HgLvItem":"000000","Ztransid":"Q-01308","NetValue":"0.5100","Material":"1000229","ZrefTransid":"?","ItmNumber":"2","Zprcduedt":"2023-08-08"}]}}}}';
    public static final String RESPONSE_ERROR='{"error":{"code":"/IWCOR/CX_DS_EDM_FACET_ERROR/005056A509B11ED1BDCCCC5E8168819D","message":{"@xml:lang":"en","$":"Property TargetQu at offset 799 has invalid value Tons"},"innererror":{"application":{"component_id":"","service_namespace":"SAP","service_id":"ZOTC_I060_QUOTATION_PRICE_CAL_SRV","service_version":"0001"},"transactionid":"686d613dde394c71becd3c3b1cd797c3","timestamp":"20230807151134.0291530","Error_Resolution":{"SAP_Transaction":"For backend administrators use ADT feed reader SAP Gateway Error Log or run transaction /IWFND/ERROR_LOG on SAP Gateway hub system and search for entries with the timestamp above for more details","SAP_Note":"See SAP Note 1797736 for error analysis (https://service.sap.com/sap/support/notes/1797736)"},"errordetails":{"errordetail":[{"message":"The mother invoice was not created."}]}}}}';
                                             //'{"error":{"code":"/IWCOR/CX_DS_EDM_FACET_ERROR/005056A509B11ED1BDCCCC5E8168819D","message":{"@xml:lang":"en","$":"Property \'TargetQu\' at offset \'799\' has invalid value \'Tons\'"},"innererror":{"application":{"component_id":"","service_namespace":"/SAP/","service_id":"ZOTC_I060_QUOTATION_PRICE_CAL_SRV","service_version":"0001"},"transactionid":"686d613dde394c71becd3c3b1cd797c3","timestamp":"20230807151134.0291530","Error_Resolution":{"SAP_Transaction":"For backend administrators: use ADT feed reader \"SAP Gateway Error Log\" or run transaction /IWFND/ERROR_LOG on SAP Gateway hub system and search for entries with the timestamp above for more details","SAP_Note":"See SAP Note 1797736 for error analysis (https://service.sap.com/sap/support/notes/1797736)"},"errordetails" :"" }}}}';
    
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* @param: none
* @return: void
* @author Rohan
*/
    @testSetup  static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
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
        Id lstPermSet4=[select id from PermissionSet where Name ='PMC_DH_CR_TransactionLogs'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet4);
        Id lstPermSet5=[select id from PermissionSet where Name ='PMC_DH_R_CommerceEntitlementSalesArea'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet5);
        
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
        
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        system.runAs(user){
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            insert cartObj;
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            prod.PMC_CPQ_QuantityUnitOfMeasure__c='STN';
            insert prod;
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            Test.startTest();
            PMC_DH_TestDataFactoryClass.createCommerceEntitlementSalesArea(acc.Id, prod.Id, testSalesArea.Id);
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            Id recordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Domestic SA').getRecordTypeId();
            Date datToday = Date.today();
            SBQQ__Quote__c testQuote2=new SBQQ__Quote__c();
            testQuote2.RecordTypeId = recordTypeId;
            testQuote2.PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote2';
            testQuote2.PMC_DH_QuoteFriendlyName__c='Test Quote';
            testQuote2.PMC_DH_PaymentMethod__c='ACH';
            testQuote2.SBQQ__Status__c='Draft';
            testQuote2.PMC_CPQ_PO__c = '1234';
            testQuote2.SBQQ__Account__c=acc.id;
            testQuote2.CreatedDate=datToday;
            testQuote2.PMC_CPQ_ContractStart__c=datToday;
            testQuote2.PMC_CPQ_ContractEnd__c=datToday.addDays(31);
            testQuote2.PMC_CPQ_ExpiresOn__c=system.now()+15;
            testQuote2.SBQQ__PaymentTerms__c='Cash Against Documents';//'Net 30';
            testQuote2.CurrencyIsoCode='USD';
            testQuote2.PMC_CPQ_ContractStageName__c = 'Pending Signature';
            testQuote2.SBQQ__PrimaryContact__c=strContactId;
            testQuote2.PMC_CPQ_PrimaryContact__c = strContactId;
            testQuote2.PMC_CPQ_AccountManager__c=userinfo.getUserId();
            testQuote2.PMC_CPQ_CustomCreatedDate__c=system.now();
            testQuote2.SBQQ__Opportunity2__c=opp.id;
            testQuote2.PMC_CPQ_QuoteOrigin__c = 'DH Request';
            insert testQuote2;
            
            SBQQ__QuoteLine__c testQuoteLine2=new SBQQ__QuoteLine__c();
            testQuoteLine2.SBQQ__Product__c=prod.id;
            testQuoteLine2.SBQQ__Quantity__c=25;
            testQuoteLine2.PMC_CPQ_ModeofTransportation__c='Truck';
            testQuoteLine2.PMC_CPQ_ContractType__c = 'Priced';
            testQuoteLine2.SBQQ__Quote__c=testQuote2.id;
            testQuoteLine2.PMC_CPQ_QuoteRecordType__c = 'Domestic SA';
            testQuoteLine2.PMC_CPQ_FinalPricePerTonne__c = 20;
            testQuoteLine2.PMC_CPQ_CustomerPrice__c = 20;
            testQuoteLine2.PMC_CPQ_UnitofMeasure__c='MTN';
            testQuoteLine2.PMC_CPQ_PackType__c='Bulk';
            insert testQuoteLine2;
            
            PricebookEntry pe = new PricebookEntry(Product2Id = prod.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1);
            insert pe;
            SalesAgreement salesAgreement = new SalesAgreement();
            salesAgreement.Name = 'Test Sales Agreement';
            salesAgreement.Status = 'Draft';
            salesAgreement.StartDate = System.Today()-1;
            salesAgreement.EndDate = System.Today() + 60;
            salesAgreement.AccountId = acc.Id;
            salesAgreement.ScheduleFrequency = 'Weekly';
            salesAgreement.ScheduleCount = 60;
            salesAgreement.CurrencyIsoCode = 'USD';
            salesAgreement.ProductLevel = 'Product';
            salesAgreement.PricebookId = Test.getStandardPricebookId();
            insert salesAgreement;
            SalesAgreementProduct sap = new SalesAgreementProduct();
            sap.name = prod.name;
            sap.SalesAgreementId = salesAgreement.id;
            sap.PricebookEntryId = pe.id;
            sap.InitialPlannedQuantity = 300;
            insert sap;
            Test.stopTest();
            CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
            insert testCartDeliveryGroup;
            CartItem cartItem=PMC_DH_TestDataFactoryClass.buildCartItem(cartObj.id, prod.id,testCartDeliveryGroup.Id);
            cartItem.PMC_DH_Number__c = 1;
            CartItem.SalesPrice = 1000.0000000001;
            CartItem.ListPrice = 900.0000001;
            CartItem.TotalPrice = 900.00000001 ;
            CartItem.TotalListPrice = 1000.00000002;
            insert cartItem;
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem.strCartId=cartObj.id;
            objCartItem.strProductId=prod.id;
            objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
            objCartItem.strShipFromId=prodLocation.id;
            CartItem cartItem1=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem); 
            cartItem1.PMC_DH_Number__c = 2;
            insert cartItem1;
        }
    }
    /**
* @description Test Method for convertPriceInfoToResponseWrapper
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void convertPriceInfoToResponseWrapperTest()
    {
        Test.startTest();
        Boolean exceptionOccurred;
        try{
            PMC_DH_GetPriceResponseParsing.throwUsersTestException = true;
            User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
            String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
            
            system.runAs(user){
                PMC_DH_PricingDetailWrapper result=PMC_DH_GetPriceResponseParsing.convertPriceInfoToResponseWrapper(strCartId);
                system.assert(result!=null,'success');
            }
        }
        catch(Exception ex){
            exceptionOccurred=true;
        }
        Test.stopTest();
    }
    /** 
* @description Used to invoke apex 
*/
    @isTest
    public static void testGetPriceGenericSuccessCall()
    {
        Test.startTest();
        
        
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        
        system.runAs(user){
            Test.setMock(HttpCalloutMock.class, new PMC_DH_GetPriceCalloutTest(200,RESPONSE_SUCCESS,'Success'));
            PMC_DH_PricingDetailWrapper result=PMC_DH_GetPriceResponseParsing.convertPriceInfoToResponseWrapper(strCartId);
            System.assert(result!=null, 'List should not be empty');
        }
        
        Test.stopTest();
    }
    /** 
* @description Used to invoke apex 
*/
    @isTest
    public static void testGetPriceErrorHandling2()
    {
        
        Test.startTest();
        
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        
        Test.setMock(HttpCalloutMock.class, new PMC_DH_GetPriceCalloutTest(500,RESPONSE_ERROR,'Error'));
        system.runAs(user){
            PMC_DH_PricingDetailWrapper result=PMC_DH_GetPriceResponseParsing.convertPriceInfoToResponseWrapper(strCartId);
            System.assert(result!=null, 'An Exception was not thrown');  
        }
        
        
        Test.stopTest();
    }
    
    /** 
* @description Used to invoke apex 
*/
    @isTest
    public static void testGetPriceErrorHandling3()
    {
        
        Test.startTest();
        
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        List<WebCart> webCartList =[SELECT id FROM WebCart WHERE Name='Test Web Cart'];
        
        Test.setMock(HttpCalloutMock.class, new PMC_DH_GetPriceCalloutTest(501,RESPONSE_ERROR,'Error'));
        system.runAs(user){
            PMC_DH_PricingDetailWrapper result=PMC_DH_GetPriceResponseParsing.convertPriceInfoToResponseWrapper(webCartList[0].Id);
            System.assert(result!=null, 'An Exception was not thrown'); 
        }
        
        
        Test.stopTest();
    }
    
     /** 
* @description Used to invoke apex 
*/
    
    @isTest
    public static void testGetPriceErrorHandling4()
    {
        
        Test.startTest();
        
        try{
            HttpRequest request= new HttpRequest();
            request.setBody('');
            HttpResponse response = new HttpResponse();
            response.setBody('');
            PMC_DH_LoggingUtils.createDHTransactionLogs(request,response,NULL); 
        }Catch(Exception ex){
            System.assert(ex!=null, 'An Exception thrown'); 
        }
    }
    
    
    /**
* @description Test Method for getPricingSummaryForQuote method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getPricingSummaryForQuoteTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            SBQQ__Quote__c objQuote=[SELECT ID FROM SBQQ__Quote__c WHERE PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote'];
            PMC_DH_PricingDetailWrapper result=PMC_DH_GetPriceResponseParsing.getPricingSummaryForQuote(objQuote.Id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    /**
* @description Test Method for getPricingSummaryForQuote method
* 
* @param: none
* 
* @return: void
*
* @author Rohan
* 
*/
    @isTest
    public static void getPricingSummaryForQuoteTest2(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            SBQQ__Quote__c objQuote=[SELECT ID FROM SBQQ__Quote__c WHERE  PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote2'];
            PMC_DH_PricingDetailWrapper result=PMC_DH_GetPriceResponseParsing.getPricingSummaryForQuote(objQuote.Id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
}