/**
* @description : Test class for PMC_DH_RequestToDeliverController class
* @author      : Krishan jangir
* @last modified by Krishan jangir
* @last modified on 07-04-2023

**/
@isTest
public with sharing class PMC_DH_RequestToDeliverTest {
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* 
* @param: none
* 
* @return: void
*
* @author krishan
* 

*/
    @testSetup  static void setup()
    {
        // test class fixes
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Digital Hub Super Buyer' LIMIT 1];
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
        
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        
        //Instantiate the Pricebook2 record with StandardPricebookId
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        //Execute an update DML on the Pricebook2 record, to make IsStandard to true
        Update standardPricebook;
       
        System.runAs(user){
            
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            testQuote.PMC_CPQ_QuoteOrigin__c = 'DH Request';
            update testQuote;
            Test.startTest();
            SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            
            Contract testContract=PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id); 
            // testContract.Status='Activated';
            // update testContract;
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            cartObj.PMC_DH_PaymentMethod__c = 'PO';
            
            
            insert cartObj;
            
            CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
            insert testCartDeliveryGroup;
            CartItem cartItem=PMC_DH_TestDataFactoryClass.buildCartItem(cartObj.id, prod.id,testCartDeliveryGroup.Id);
            cartItem.PMC_DH_Contract__c = testContract.Id;
            insert cartItem;
            
            Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            shipToAcc.PMC_DH_Account_Status__c = 'Active';
            shipToAcc.PMC_SS_MDMVerified__c = TRUE;
            update shipToAcc;
            //testQuoteLine.PMC_CPQ_VCOQuotation__c=true;
            testQuoteLine.PMC_CPQ_ShipTo__c = shipToAcc.Id;
            update testQuoteLine;
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem.strCartId=cartObj.id;
            objCartItem.strProductId=prod.id;
            objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
            objCartItem.strShipToAccId=shipToAcc.id;
            objCartItem.strShipFromId=prodLocation.id;
            objCartItem.strQuoteLineId = testQuoteLine.Id;
            objCartItem.strContractId = testContract.Id;
            SBQQ__Subscription__c sub2=PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
            CartItem cartItem1=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem);
            cartItem1.PMC_DH_Subscription__c=sub2.id;
            cartItem1.PMC_DH_ItemNumber__c='1';
            insert cartItem1;
            
            PMC_DH_TestDataFactoryClass.createSoldToShipToAccountJunction(shipToAcc.id, acc.Id);
            Test.stopTest();
        }
    }
    
   
    
    @isTest
    public static void getDeliverCheckOutShipExceptionTest()
    {
        Test.startTest();
        Account strTestAcct=[SELECT id,RecordType.Name FROM Account WHERE Name='Parent Test Account' limit 1][0];
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Boolean exceptionOccurred=true;
            try{
                String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
                String testContractId=[select Id from contract limit 1].Id;
system.debug('testContractId'+testContractId);
                PMC_DH_RequestToDeliverController.DeliverCheckOutShipment innerWrap = new PMC_DH_RequestToDeliverController.DeliverCheckOutShipment();
                innerWrap.strCartId = strCartId;
                innerWrap.strEffectiveAccountId = strTestAcct.id;
                innerWrap.strContractId=testContractId;
                innerWrap.strCommunityId = PMC_DH_ConstantClass.TEST_COMMUNITYID;
                
                PMC_DH_RequestToDeliverController.getDeliverCheckOutShipmentInfo(innerWrap); 
            }
            catch(exception e){
                exceptionOccurred=true;
            }
          //  system.Assert(exceptionOccurred, 'An Exception was not thrown');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for createOrderFromCart
* 
* @param: none
* 
* @return: void
*
* @author Nikhilesh
* 
*/
     
    @isTest
    public static void createOrderFromCartTest1()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT Id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        Contract testContract = [SELECT ID, Status, StartDate, EndDate FROM Contract WHERE SBQQ__Quote__r.PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote'][0];
        testContract.Status='Activated';
        testContract.EndDate = Date.today() + 12;
        update testContract;
        PMC_DH_RequestToDeliverController.PMC_DH_OrderCreateInputParams inputParams = new PMC_DH_RequestToDeliverController.PMC_DH_OrderCreateInputParams();
        inputParams.strCartId=strCartId;
        inputParams.lstProductSKU= new List<String>{'1234'};
            
            system.runAs(user){
                PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_RequestToDeliverController.createOrderFromCart(inputParams);
               // System.assert(result.strStatusCode=='000','success');
            }
        Test.stopTest();
    }
    
    /**
* @description Test Method for order creation before contract start date
* @param: none
* @return: void
* @author Nikhilesh
*/  
    @isTest
    public static void createOrderFromCartBeforeContractStartTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT Id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        Contract testContract = [SELECT ID, Status, StartDate, EndDate FROM Contract WHERE SBQQ__Quote__r.PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote'][0];
        testContract.Status='Activated';
        testContract.StartDate = Date.today() + 2;
        testContract.EndDate = Date.today() + 12;
        update testContract;
        PMC_DH_RequestToDeliverController.PMC_DH_OrderCreateInputParams inputParams = new PMC_DH_RequestToDeliverController.PMC_DH_OrderCreateInputParams();
        inputParams.strCartId=strCartId;
        inputParams.lstProductSKU= new List<String>{'1234'};
            
            system.runAs(user){
                PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_RequestToDeliverController.createOrderFromCart(inputParams);
               // System.assert(result.strStatusCode=='000','success');
            }
        Test.stopTest();
    }
    
    
    
    
    
        /**
* @description Test Method for order creation after contract end date
* @param: none
* @return: void
* @author Nikhilesh
*/  
    @isTest
    public static void createOrderFromCartAfterContractEndTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT Id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        Contract testContract = [SELECT ID, Status, StartDate, EndDate FROM Contract WHERE SBQQ__Quote__r.PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote'][0];
        testContract.Status='Activated';
        testContract.StartDate = Date.today() - 15;
        testContract.EndDate = Date.today() - 2;
        update testContract;
        PMC_DH_RequestToDeliverController.PMC_DH_OrderCreateInputParams inputParams = new PMC_DH_RequestToDeliverController.PMC_DH_OrderCreateInputParams();
        inputParams.strCartId='';
        inputParams.lstProductSKU= new List<String>{'1234'};
            
            system.runAs(user){
                PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_RequestToDeliverController.createOrderFromCart(inputParams);
               // System.assert(result.strStatusCode=='100','success');
            }
        Test.stopTest();
    }
    
    /**
* @description Test Method for addCartItems
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void updateDeliverCheckOutShipmentInfoTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        
        CartItem cartItems =[select PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.PMC_CPQ_AdvanceBilling__c,
                             PMC_DH_IsReorder__c,PMC_DH_SellOutPrice__c,PMC_DH_RequestedShipmentDate__c,id,Product2.Name,Product2Id,Product2.StockKeepingUnit,
                             PMC_DH_ShipTo__c, PMC_DH_PlantShipFrom__c, PMC_DH_DeliveryMode__c,
                             PMC_DH_Incoterms__c, Type, CartDeliveryGroupId, Quantity from CartItem where cartid=:strCartId and Name='Test Cart Item1'];
        List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper> lstCartItemWrap = new List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>();
        PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestToDeliverWrapper.CartItemWrapper();
        cartItemWrap.strCartItemId = cartItems.id;
        cartItemWrap.intQuantity = integer.valueOf(PMC_DH_ConstantClass.PRODUCT_QUANTITY);
        cartItemWrap.strShipTo = cartItems.PMC_DH_ShipTo__c;
        cartItemWrap.strIncoterms =cartItems.PMC_DH_Incoterms__c;
        cartItemWrap.strDeliveryMode =cartItems.PMC_DH_DeliveryMode__c;
        cartItemWrap.strShipFrom =cartItems.PMC_DH_PlantShipFrom__c;
        cartItemWrap.strSource ='RTD';
        cartItemWrap.boolShipmentPlan = false;
        cartItemWrap.strCartItemReferenceNumber = 'MD-0000000239-1-1';
        lstCartItemWrap.add(cartItemWrap);
        
        List<PMC_DH_RequestToDeliverWrapper.CartWrapper> lstCartWrapper = new List<PMC_DH_RequestToDeliverWrapper.CartWrapper>();
        PMC_DH_RequestToDeliverWrapper.CartWrapper objCartWrapper = new PMC_DH_RequestToDeliverWrapper.CartWrapper();
        objCartWrapper.lstCartItems = lstCartItemWrap;
        objCartWrapper.strProductId = cartItems.Product2Id;
        objCartWrapper.strProductName = cartItems.Product2.Name;
        objCartWrapper.boolThirdParty = true;
        lstCartWrapper.add(objCartWrapper);
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=PMC_DH_RequestToDeliverController.updateDeliverCheckOutShipmentInfo(strCartId, lstCartWrapper,PMC_DH_ConstantClass.TEST_COMMUNITYID);
           // system.assert(result!=null,'success');
           // 
            
           
        }
         String result2 = PMC_DH_RequestToDeliverUtil.getShipToTP(cartItemWrap,cartItems);
         Contract testContract = [SELECT ID, Status, StartDate, EndDate FROM Contract WHERE SBQQ__Quote__r.PMC_CPQ_QuoteShortNameDescription__c = 'TestDH Quote'][0];
        testContract.Status='Activated';
        testContract.StartDate = Date.today() - 15;
        testContract.EndDate = Date.today() - 2;
        update testContract;
         String result3 = PMC_DH_RequestToDeliverUtil.getShipToForTP(cartItemWrap,cartItems,testContract);
        
        Test.stopTest();
    }
    
    /**
* @description Test Method for addCartItems with Shipments
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void updateDeliverCheckOutShipmentInfoWithShipmentTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        
        CartItem cartItems =[select id,Product2.Name,Product2Id,Product2.StockKeepingUnit, PMC_DH_ShipTo__c, PMC_DH_PlantShipFrom__c, PMC_DH_DeliveryMode__c, PMC_DH_Incoterms__c, Type, CartDeliveryGroupId, Quantity, PMC_DH_RequestedShipmentDate__c from CartItem where cartid=:strCartId and Name='Test Cart Item1'];
        List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper> lstCartItemWrap = new List<PMC_DH_RequestToDeliverWrapper.CartItemWrapper>();
        PMC_DH_RequestToDeliverWrapper.CartItemWrapper cartItemWrap = new PMC_DH_RequestToDeliverWrapper.CartItemWrapper();
        cartItemWrap.strCartItemId = cartItems.id;
        cartItemWrap.intQuantity = integer.valueOf(PMC_DH_ConstantClass.PRODUCT_QUANTITY);
        cartItemWrap.strShipTo = cartItems.PMC_DH_ShipTo__c;
        cartItemWrap.strIncoterms =cartItems.PMC_DH_Incoterms__c;
        cartItemWrap.strDeliveryMode =cartItems.PMC_DH_DeliveryMode__c;
        cartItemWrap.strShipFrom =cartItems.PMC_DH_PlantShipFrom__c;
        cartItemWrap.strSource ='RTD';
        cartItemWrap.boolShipmentPlan = true;
        cartItemWrap.strCartItemReferenceNumber='MD-0000000001-1-1';
        List<PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper> lstShipmentPlan = new List<PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper>();
        PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper sh1 = new PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper();
        sh1.strCartItemId = cartItems.id;
        sh1.strDeliveryPoNumber = 'asdfghj';
        sh1.intQuantity = integer.valueOf(PMC_DH_ConstantClass.PRODUCT_QUANTITY);
        sh1.datRequestedShipmentDate = cartItems.PMC_DH_RequestedShipmentDate__c;
        lstShipmentPlan.add(sh1);
        
        PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper sh2 = new PMC_DH_RequestToDeliverWrapper.ShipmentPlanWrapper();
        sh2.strDeliveryPoNumber = 'asdfghj';
        sh2.intQuantity = integer.valueOf(PMC_DH_ConstantClass.PRODUCT_QUANTITY);
        sh2.datRequestedShipmentDate = cartItems.PMC_DH_RequestedShipmentDate__c;
        lstShipmentPlan.add(sh2);
        cartItemWrap.lstShipmentPlan = lstShipmentPlan;
        lstCartItemWrap.add(cartItemWrap);
        
        List<PMC_DH_RequestToDeliverWrapper.CartWrapper> lstCartWrapper = new List<PMC_DH_RequestToDeliverWrapper.CartWrapper>();
        PMC_DH_RequestToDeliverWrapper.CartWrapper objCartWrapper = new PMC_DH_RequestToDeliverWrapper.CartWrapper();
        objCartWrapper.lstCartItems = lstCartItemWrap;
        objCartWrapper.strProductId = cartItems.Product2Id;
        objCartWrapper.strProductName = cartItems.Product2.Name;
        objCartWrapper.boolThirdParty = true;
        lstCartWrapper.add(objCartWrapper);
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=PMC_DH_RequestToDeliverController.updateDeliverCheckOutShipmentInfo(strCartId, lstCartWrapper,PMC_DH_ConstantClass.TEST_COMMUNITYID);
            //ert(result!=null,'success');
        }
        Test.stopTest();
    }
    /**
* @description Test Method for addCartItems
* @param: none
* @return: void
* @author Rohan
*/  
    @isTest
    public static void getCartItemsExceptionTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Map<String,PMC_DH_RequestForQuoteController.ConnectApiWrapper> mapProductDetail = new Map<String,PMC_DH_RequestForQuoteController.ConnectApiWrapper>();
        PMC_DH_RequestToDeliverUtil.CartItemParamWrapper cartItemWrap = new PMC_DH_RequestToDeliverUtil.CartItemParamWrapper();
        String userRegion = '';
        system.runAs(user){
            Boolean exceptionOccurred;
            try{
                PMC_DH_DigitalHubB2BUtils.throwTestException = true;
                PMC_DH_RequestToDeliverUtil.getCartItemDetails(cartItemWrap,userRegion,mapProductDetail);
            }catch(Exception ex){
                exceptionOccurred = true;
            }
            
           // system.assert(exceptionOccurred,'success');
        }
        Test.stopTest();
    }
    
            /**
* @description Test Method for deleting cart items
* @param: none
* @return: void
* @author Nikhilesh
*/  
    @isTest
    public static void deleteCartItemsTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        List<CartItem> cartItems =[select id,Product2.Name,Product2Id,Product2.StockKeepingUnit, PMC_DH_ShipTo__c, PMC_DH_PlantShipFrom__c, PMC_DH_DeliveryMode__c, PMC_DH_Incoterms__c, Type, CartDeliveryGroupId, Quantity, PMC_DH_RequestedShipmentDate__c from CartItem where cartid=:strCartId and Name='Test Cart Item1'];
    	List<String> lstCartItemsId = new List<String>();
        for(CartItem ci : cartItems){
            lstCartItemsId.add(ci.Id);
        }
        System.runAs(user){
            PMC_DH_RequestToDeliverController.deleteCartItems(lstCartItemsId, strCartId);
        }
       // System.assertEquals(strCartId!=NULL, TRUE, 'SUCESS');
        Test.stopTest();
    }
    /**
* @description Test Method for getShipToForContract method
* @param: none
* @return: void
* @author Nikhilesh
*/
    @isTest
    public static void testGetShipToForContract(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account strTestAcc1=[SELECT id,RecordType.Name FROM Account WHERE Name='Parent Test Account' limit 1][0];
        system.runAs(user){
            List<PMC_DH_PicklistWrapper> result = PMC_DH_RequestToDeliverUtil.getShipToForContract(strTestAcc1.Id);
            //ert(result!=null,'success');
        }
        Test.stopTest();
    }
    
     @isTest
    public static void testGetShipToForContract44(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account strTestAcc1=[SELECT id,RecordType.Name FROM Account WHERE Name='Parent Test Account' limit 1][0];
        system.runAs(user){
            List<PMC_DH_PicklistWrapper> result = PMC_DH_RequestToDeliverUtil.getShipToForContractNA(strTestAcc1.Id);
            //ert(result!=null,'success');
        }
        Test.stopTest();
    }
     @isTest
    public static void testGetShipToForContractShipToForContractforVCOANDBilling(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account strTestAcc1=[SELECT id,RecordType.Name FROM Account WHERE Name='Parent Test Account' limit 1][0];
        system.runAs(user){
            List<PMC_DH_PicklistWrapper> result = PMC_DH_RequestToDeliverUtil.getShipToForContractforVCOANDBilling(strTestAcc1.Id);
            //ert(result!=null,'success');
        }
        Test.stopTest();
    }
    
     @isTest
    public static void testGetPackTypeValue(){
        Test.startTest();
        String result = PMC_DH_RequestToDeliverUtil.getPackTypeValue('Packed'); 
       // System.assert(result!=null, 'success');
        Test.stopTest();
    }
    @isTest
    public static void testgetPoNumber(){
        Test.startTest();        
        String result = PMC_DH_RequestToDeliverUtil.getPoNumber('1234','123456','REGION_BRAZIL'); 
        
          User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT id FROM WebCart WHERE Name='Test Web Cart'][0].id;
        List<CartItem> cartItems =[select PMC_DH_DeliveryPONumber__c,id,Product2.Name,Product2Id,Product2.StockKeepingUnit, PMC_DH_ShipTo__c, PMC_DH_PlantShipFrom__c, PMC_DH_DeliveryMode__c, PMC_DH_Incoterms__c, Type, CartDeliveryGroupId, Quantity, PMC_DH_RequestedShipmentDate__c from CartItem where cartid=:strCartId and Name='Test Cart Item1'];
    	
       String result1 = PMC_DH_RequestToDeliverUtil.getOrderDeliveryPONumber(cartItems);
         String result2 = PMC_DH_RequestToDeliverUtil.getLineItemPO(cartItems,cartItems[0]);
        Boolean result3 = PMC_DH_RequestToDeliverUtil.getThirdParty(true);
       
        
        
        Test.stopTest();
    }
     @isTest
    public static void testgetThirdPartyAddresses(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account strTestAcc1=[SELECT id,RecordType.Name FROM Account WHERE Name='Parent Test Account' limit 1][0];
        system.runAs(user){
            List<PMC_DH_PicklistWrapper> result = PMC_DH_RequestToDeliverUtil.getThirdPartyAddresses(strTestAcc1.Id,true);
            //ert(result!=null,'success');
        }
        Test.stopTest();
    }
    
}