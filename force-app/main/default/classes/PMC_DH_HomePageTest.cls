/**
 * @description Test class for home page controller
 * @author hemant giri goswami
 * @since  09-04-2023
 */
@isTest
public with sharing  class PMC_DH_HomePageTest {
    @TestSetup
    static void testSetup(){
        // test Classes fixes
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
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        system.runAs(user){
            Account shipToAcc = PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
            PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
            Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
            SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
            Test.startTest();
            SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
            testQuoteLine.PMC_CPQ_ShipTo__c = shipToAcc.Id;
            update testQuoteLine;
            Contract testContract = PMC_DH_TestDataFactoryClass.createContract(testQuote.Id,acc.Id);
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
            insert cartObj;
            CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
            insert testCartDeliveryGroup;
            CartItem cartItem=PMC_DH_TestDataFactoryClass.buildCartItem(cartObj.id, prod.id,testCartDeliveryGroup.Id);
            cartItem.Quantity = 5;
            cartItem.TotalLineAmount = 5100;
            insert cartItem;
            PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
            objCartItem.strCartId=cartObj.id;
            objCartItem.strProductId=prod.id;
            objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
            objCartItem.strShipToAccId=shipToAcc.id;
            objCartItem.strShipFromId=prodLocation.id;
            objCartItem.strQuoteLineId = testQuoteLine.Id;
            objCartItem.strContractId = testContract.Id;
            SBQQ__Subscription__c subsc=PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
            subsc.PMC_CPQ_TotalAvailableQuantity__c=1;
            update subsc;
            Order testOrder = PMC_DH_TestDataFactoryClass.createOrder(acc, testContract, cartObj.id);
            OrderItem oi1 = PMC_DH_TestDataFactoryClass.creatOrderLine(testOrder, cartItem);
            oi1.PMC_CPQ_ConfirmedQuantity__c = 50;
            update oi1;
            testOrder.status='In Progress'; //change for GDASF-21480: 'Partially Shipped' replaced by 'In Progress'
            testOrder.PMC_DH_OrderTypeCode__c = 'ZOR';
            update testOrder;
            Shipment shipmnt = PMC_DH_TestDataFactoryClass.createShipment(testOrder);
            ShipmentItem si = PMC_DH_TestDataFactoryClass.createShipmentItem(oi1,shipmnt);
            si.PMC_CPQ_DeliveryLineStatus__c = 'Completely Shipped';
            update si;
            Test.stopTest();
       }
    }


        /**s
* @description Test Method for getRecentContracts
* @param: none
* @return: void
*  @since 09-04-2023
* @author hemant giri goswami
*/
    @isTest
    public static void getRecentContractsTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' and  AccountNumber='Test002' LIMIT 1];
        String strAccid=acc.id;
        system.runAs(user){
            Contract con=[select id,ContractTerm,Status from contract where accountid=:strAccid];
            con.ContractTerm=1;
            con.status='Activated';
            con.EndDate=system.today()+1;
            update con;
            PMC_DH_HomePageWrapper.RecentContractWrapper result = PMC_DH_HomePageController.getActiveContracts(acc.Id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
    
    @isTest
    public static void getActiveContractsTestExcep()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' LIMIT 1];
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            String strIns='';
            try{
                PMC_DH_HomePageController.getActiveContracts(acc.Id);
            }
            catch(Exception e){
                strIns='Exception';
            }
            System.assertEquals('',strIns,'Passed');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void getRecentContractsTestExcep()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' LIMIT 1];
        system.runAs(user){
            PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            String strIns='';
            try{
                PMC_DH_HomePageController.getRecentQuotes(acc.Id);
            }
            catch(Exception e){
                strIns='Exception';
            }
            System.assertEquals('',strIns,'Passed');
        }
        Test.stopTest();
    }
     /**
* @description Test Method for getRecentQuotes
* @param: none
* @return: void
*  @since 09-04-2023
* @author @mhumerarahath
*/
@isTest
    public static void getRecentQuotesTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' LIMIT 1];
        system.runAs(user){
            PMC_DH_HomePageWrapper.RecentQuotesWrapper result = PMC_DH_HomePageController.getRecentQuotes(acc.Id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
    /**
* @description Test Method for fetchRecentUpdates
* @param: none
* @return: void
*  @since 10-06-2023
* @author @Dishari
*/
@isTest
    public static void fetchRecentUpdatesTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name FROM Account Where Name='Parent Test Account' LIMIT 1];
        
        system.runAs(user){
            PMC_DH_HomePageController.RecentUpdatesWrapper result = PMC_DH_HomePageController.fetchRecentUpdates(acc.Id);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }
    
    

    @isTest
    public static void getOrdersinTransitTest()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Account acc = [SELECT Id,Name,RecordType.Name FROM Account Where Name='Parent Test Account' LIMIT 1];
        acc.RecordType.Name='Retailer';
        update acc;
        system.runAs(user){
            PMC_DH_HomePageController.PMC_DH_OrdersInTransitWrapper lstresult=PMC_DH_HomePageController.getOrdersinTransit(acc.id);
            system.Assert(lstresult!=null, 'Success');
        }
        Test.stopTest();
        
    }
    
    
    @isTest 
    public static void getOrdersinTransitException()
    {
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            String strIns='';
            PMC_DH_DigitalHubB2BUtils.throwTestException=true;
            try{
                PMC_DH_HomePageController.getOrdersinTransit(' ');
            }
            catch(Exception e){
                strIns='Exception';
            }
            System.assertEquals('',strIns,'Passed');
        }
        Test.stopTest();
    }
}