/**
* @description       : This class will be used to insert any test data to be used in test class execution.
* @author            : 
* @group             : 
* @last modified on  : 03-14-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public without sharing class PMC_DH_TestDataFactoryClass { 
    
/*************************************************************************
* @Method Name   : createTestWebStore
* @description   : Method to create or retrieve webstore
* @params        : None
* @return        : WebStore
*****************************************************************************/
    public static WebStore createTestWebStore()
    {
        List<WebStore> testWebStoreList = [SELECT id,Name,Description FROM WebStore WHERE Name ='TestWebStore' WITH SECURITY_ENFORCED LIMIT 1];
        string strTestWebStoreId;
        WebStore testWebStore ;
        if(!testWebStoreList.isEmpty())
        {
            strTestWebStoreId = testWebStoreList[0].id;
            testWebStore = testWebStoreList[0];
        }
        else
        {
            testWebStore = new WebStore();
            testWebStore.Name = 'TestWebStore';
            if(Schema.sObjectType.WebStore.isCreateable())
            { 
            insert testWebStore;
            }
            
        }
        return testWebStore;
    }
    /*************************************************************************
* @Method Name   : getNetworkId
* @description   Method to retrieve NetworkId
* @param     webstoreId :String
* @return       String
*****************************************************************************/
    public static String getNetworkId(String webstoreId)
    {
        List<WebStoreNetwork> webNetwork=  [SELECT NetworkId FROM WebStoreNetwork WHERE WebStoreId=:webstoreId WITH SECURITY_ENFORCED LIMIT 1 ];
        String strNId;
        if(!webNetwork.isEmpty())
        {        
            strNId= webNetwork[0].NetworkId;   
        }
        return strNId;
    }
    /*************************************************************************
* @Method Name    : getWebstoreId
* @description    : Method to retrieve webStoreId
* @param  networkId :String
* @return         : String
*****************************************************************************/
    public static String getWebStoreId(String networkId)
    {
        List<WebStoreNetwork> webNetwork=  [SELECT WebStoreId  FROM WebStoreNetwork WHERE NetworkId=:networkId WITH SECURITY_ENFORCED LIMIT 1];
        string webStoreId;
        if(!webNetwork.isEmpty())
        {        
            webStoreId= webNetwork[0].WebStoreId;   
        }
        return webStoreId;
    }
    /*************************************************************************
* @Method Name     : createTestAccount
* @description     : Method to insert Account
* @params          : None
* @return          : Account
*****************************************************************************/
    public static Account createTestAccount(){
        Id recordTypeId = Schema.SObjectType.Account.getrecordtypeinfosbydevelopername().get('PMC_SS_Customer').getRecordTypeId();
        Account acc=new Account(Name = 'Test Account', 
        AccountNumber = 'Test001', 
        Type = 'Sold-to', 
        PMC_SS_RegionalManager__c = UserInfo.getUserId(),
        CurrencyIsoCode = 'USD',
        RecordTypeId=recordTypeId,        
         BillingCountry='United States',       
        BillingState='California',
        BillingStreet='fsvc',
        BillingCity='San Francisco',
       BillingPostalCode= '94001');
        // acc.Name='Test Account';
        // acc.AccountNumber='Test001';
        // acc.PMC_SS_RegionalManager__c = UserInfo.getUserId();
        // acc.Type = 'Sold-to';
        //acc.RecordTypeId=recordTypeId;

        if(Schema.sObjectType.Account.isCreateable())
        {
        insert acc;
        }
        return acc;
    }
    
    /**
* @description   : Create Parent Test Account
* 
* @return        : Account
*

*/
    public static Account createParentTestAccount(){
        Account parentAcc = new Account();
        parentAcc.Name='Parent Test Account';
        parentAcc.AccountNumber='Test002';
        parentAcc.PMC_SS_RegionalManager__c = UserInfo.getUserId();
        parentAcc.PMC_SS_SAPCustomerNumber__c = '12346785';
        parentAcc.Type = 'Sold-to';
         parentAcc.BillingCountry='United States';
        parentAcc.CurrencyIsoCode='USD';
        parentAcc.BillingState='California';
        parentAcc.BillingStreet='fsvc';
        parentAcc.BillingCity='San Francisco';
        parentAcc.BillingPostalCode= '94001';
        parentAcc.phone='000-000-0000';
        Id recordTypeId = Schema.SObjectType.Account.getrecordtypeinfosbydevelopername().get('PMC_SS_Customer').getRecordTypeId();
        parentAcc.RecordTypeId=recordTypeId;
        insert parentAcc;
        return parentAcc;
        
    }
    
    /**
* @description   : Create Test Account with a parent account
* 
* @param parentAcc 
*
* @return        : Account
*

*/
    
    public static Account createShipToTestAccount(Account parentAcc){
        Account acc=new Account();
        acc.Name='Ship To Account123'; 
        acc.AccountNumber='Test00123';
        acc.PMC_SS_AccountExternalID__c = '4082583';
        acc.PMC_SS_SAPCustomerNumber__c = '5389421474';
        acc.PMC_SS_SoldToAccount__c = parentAcc.Id;
        //acc.ParentId = parentAcc.Id;
        //acc.PMC_SS_RegionalManager__c = UserInfo.getUserId();
        acc.ShippingStreet = '123 Test Avenue';
        acc.BillingCountry='United States';
        acc.ShippingState = 'California';
         acc.phone='000-000-0000';
        acc.ShippingStreet='fsvc';
        acc.ShippingCity = 'San Francisco';
        acc.ShippingPostalCode = '94001';
         acc.BillingCountry='United States';
        acc.CurrencyIsoCode='USD';
        acc.BillingState='California';
        acc.BillingStreet='fsvc';
        acc.BillingCity='San Francisco';
        acc.BillingPostalCode= '94001';
    acc.PMC_SS_SoldToAccount__c =parentAcc.Id;
        acc.Type = 'Ship-to';
        acc.Phone='123-456-7890'; 

        // acc.PMC_SS_Channel__c = 'Cooperative';
        acc.PMC_DH_Delivery_Instruction__c = 'Test';
        Id recordTypeId = Schema.SObjectType.Account.getrecordtypeinfosbydevelopername().get('PMC_SS_Customer').getRecordTypeId();
        acc.RecordTypeId=recordTypeId;
        if (Schema.SObjectType.Account.fields.getMap().containsKey('PMC_SS_Account__c')) {
            acc.put('PMC_SS_Account__c', parentAcc.Id);
        }
        Boolean originalBypass = setBypassFlow(true);
        insert acc;
        setBypassFlow(originalBypass);
        return acc;
    }

    private static Boolean setBypassFlow(Boolean bypass) {
        PMC_ProcessSwitches__c bypassSetting = PMC_ProcessSwitches__c.getOrgDefaults();
        if (bypassSetting.Id == null) {
            bypassSetting = new PMC_ProcessSwitches__c();
        }
        Boolean originalBypass = bypassSetting.PMC_BypassFlow__c;
        bypassSetting.PMC_BypassFlow__c = bypass;
        upsert bypassSetting;
        return originalBypass;
    }
    
    /**
* @description   : Assign Permisson Set group
* 
* @param struserId
@param strPermissionSetId
* 
*

*/
    public static void assignPermissionSetToUser(String struserId, String strPermissionSetId){
        User testOwner = [SELECT TimeZoneSidKey, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
        
        system.runAs(testOwner){
            PermissionSetAssignment pgroupAss = new PermissionSetAssignment();
            pgroupAss.AssigneeId=struserId;
            pgroupAss.PermissionSetId=strPermissionSetId;
            if(Schema.sObjectType.PermissionSetAssignment.isCreateable()){
            insert pgroupAss;
            }
        }
    }  
    
    /**
* @description   : Assign Permisson Set group
* 
* @param struserId
* 
*

*/ 
    
    
/*    public static void assignPermissionSetGroupToUser(String struserId){
        User testOwner = [SELECT TimeZoneSidKey, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
        Id lstPermSetGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName ='PMC_DH_Super_Buyer_Permission_Set_Group'].Id;
        system.runAs(testOwner){
            PermissionSetAssignment assignment=new PermissionSetAssignment(PermissionSetGroupId=lstPermSetGroup,AssigneeId=struserId);
            //if(Schema.sObjectType.PermissionSetAssignment.isCreateable())
            //{
                insert assignment;
            //}
        }}*/
    
    /**
* @description   : Create Test Contact
* 
* @param accId
* 
* @return        : Contact
*

*/
    public static Contact createTestContact(String accId){
        Contact con=new Contact();
        con.lastName='Test Contact';
        con.Email = 'demouser1@abc.com';
        con.PMC_SS_Status__c = 'Active';
        con.AccountId = accId;
        if(Schema.sObjectType.Contact.isCreateable())
        {
        insert con;
        }
        return con;
        
    }  
    /**
* @description   : Create Contact
* 
* @param accId
* 
* @return        : Contact
*

*/
    public static Contact createContact(string accId){
        Contact contactCommerce = new Contact(
            FirstName = 'Demo',
            LastName = 'TestUser',
            Phone = 'US(+1)(222)222-78905',
            Email = 'demouser1@abc.com',
            MailingStreet = 'xyzz',
            Title = 'Customer',
            AccountId=accId,
            MailingCountry = 'United States'
        );
        
        insert contactCommerce;
        return contactCommerce;
    }
    
    /**
* @description   : Create Test User
* 
* @param accId
* @param profileId
* 
* @return        : Contact
*

*/ 
    
    private static void setPrimaryContractRecipient(String accId, Id contactId){
        String primaryContractRecipientField = 'Primary_Contract_Recipient__c';
        if(String.isBlank(accId) || !Schema.SObjectType.Account.fields.getMap().containsKey(primaryContractRecipientField)){
            return;
        }
        Account objQuoteAccount = new Account(Id = accId);
        objQuoteAccount.put(primaryContractRecipientField, contactId);
        update objQuoteAccount;
    }

    public static User createTestUser(string accId,string profileId){
        Contact contactDH = new Contact(
            FirstName = 'DemoUserRequest',
            LastName  = 'Bush',
            Phone = 'US(+1)(222) 222-22222',
            Email = 'demouser@test.com',
            AccountId = accId,
            MailingStreet = 'abc',
            PMC_SS_Status__c = 'Active',
            PMC_SS_CPF__c='1235rf6768',
            Title = 'Customer'
        );
        insert contactDH;
        setPrimaryContractRecipient(accId, contactDH.Id);

        User testUser;
        User testOwner = [SELECT TimeZoneSidKey, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
        
        system.runAs(testOwner){
            UserRole role = new UserRole (DeveloperName = 'DH_Role' , Name = 'DH_Role' );
            if(Schema.sObjectType.UserRole.isCreateable())
            {
            insert role;
            }
            testUser = new User(
                FederationIdentifier = 'emailtesting10101x@gmail.com',
                MobilePhone = '+1 9876543210',
                FirstName = 'DemoUserRequest',
                LastName = 'Bush',
                Email = 'demouser@test.com',
                Username = 'demouser@test.com.testuser',
                UserRole = role,
                Alias = 'abctest',
                isActive = true,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                ContactId = contactDH.ID,
                ProfileId = profileID,
                PMC_CPQ_SalesRegion__c = 'North America',
                PMC_CPQ_PrimaryBusinessType__c = 'Feed',
                //PMC_CPQ_SalesArea__c = 'Mosaic Fertilizer Export Common',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                CurrencyIsoCode = 'USD',
                Country='United States'
            );
            if(Schema.sObjectType.User.isCreateable()){
            insert testUser;
            }
            
        }
        return testUser;
    }
    /**
* @description   : Create Product
* 
* 
* @return        : Product2
*

*/
    public static Product2 createProduct(){
        Product2 prod = new Product2();
        prod.Name='Test Product';
        prod.ProductCode='GH-1234';
        prod.Description='Test New Description';
        prod.StockKeepingUnit='1234';
        prod.IsActive=TRUE;
        prod.Family='Simple';
        return prod;
    }
    /**
* @description   : Create Location
* 
* 
* @return        : Schema.Location
*

*/
    public static Schema.Location createLocation(){
        Schema.Location testLoc = new Schema.Location();
        testLoc.Name = 'Test Location';
        testLoc.LocationType = 'Warehouse';
        testLoc.Description = 'Test Location Description';
        insert as system testLoc;
        
        return testLoc;
    }
    /**
* @description   : Create Product Location
* 
* @param prod
* @param loc
* 
* @return        : PMC_CPQ_ProductLocation__c
*

*/
    
    public static PMC_CPQ_ProductLocation__c createProductLocation(Product2 prod, Schema.Location loc){
        PMC_CPQ_ProductLocation__c prodLocation = new PMC_CPQ_ProductLocation__c();
        prodLocation.Name = 'Test Product Location';
        prodLocation.PMC_CPQ_ProductName__c = prod.Id;
        prodLocation.PMC_CPQ_Location__c = loc.Id;
        if(Schema.sObjectType.PMC_CPQ_ProductLocation__c.isCreateable())
        {
        insert prodLocation;
        }
        return prodLocation;
    }

    /**
* @description   : Create build cart
* 
* @param strwebStoreId
* @param straccountId
* 
* @return        : Webcart
*

*/  
    public static Webcart buildCart(String strwebStoreId, String straccountId){
        Webcart testCart = new Webcart();
        testCart.Name= 'Test Web Cart';
        testCart.Type = 'Cart';
        testCart.Status = 'Active';
        testCart.PMC_DH_PaymentTerms__c ='Prepayment';//Added as of GDASF - 19809
        testCart.WebStoreId = strwebStoreId;
        testCart.AccountId = straccountId;
        testCart.PMC_DH_Account__c=straccountId;
        testCart.OwnerId = Userinfo.getUserId();
        testCart.PMC_DH_Currency__c = 'USD';
        return testCart;
    }
    /**
* @description   : Create build cart delivery group
* 
* @param strCartId
* 
* @return        : CartDeliveryGroup
*

*/ 
    public static CartDeliveryGroup buildCartDeliveryGroup(String strCartId){ 
        CartDeliveryGroup testCartDGroup = new CartDeliveryGroup();
        testCartDGroup.Name = 'Test Delivery Group';
        testCartDGroup.CartId = strCartId;
        return testCartDGroup;
    }
    /**
* @description   : Create build cart item
* 
* @param strCartId
* @param strProductId
* @param strDeliveryGroupId
* 
* @return        : CartItem
*

*/   
    public static CartItem buildCartItem(String strCartId,String strProductId, String strDeliveryGroupId ){
        CartItem testCartItem = new CartItem();
        testCartItem.name = 'Test Cart Item';
        testCartItem.cartId = strCartId;
        testCartItem.Quantity = 1;
        testCartItem.SalesPrice = 1000;
        testCartItem.ListPrice = 900;
        testCartItem.TotalPrice = 900 ;
        testCartItem.TotalListPrice = 1000;
        testCartItem.Product2Id = strProductId;
        testCartItem.Type = 'Product';
        testCartItem.PMC_DH_DeliveryMode__c='Barge';
        testCartItem.CartDeliveryGroupId = strDeliveryGroupId;
        testCartItem.PMC_DH_Source__c = 'RFQ';
        testCartItem.CurrencyIsoCode = 'USD';
        return testCartItem;
    }
    
    
    /**
* @description   : Create build cart item
* 
* @param objCartItem
* @return CartItem
*

*/   
    public static CartItem buildCartItem1(CartItemObject objCartItem){
        CartItem testCartItem = new CartItem();
        testCartItem.name = 'Test Cart Item1'; 
        testCartItem.cartId =objCartItem.strCartId;
        testCartItem.Quantity = 1;
        testCartItem.SalesPrice = 1000;
        testCartItem.ListPrice = 900;
        testCartItem.TotalPrice = 900 ;
        testCartItem.TotalListPrice = 1000;
        testCartItem.Product2Id = objCartItem.strProductId;
        testCartItem.Type = 'Product';
        testCartItem.PMC_DH_Incoterms__c='FOB';
        testCartItem.PMC_DH_DeliveryMode__c='Barge';
        testCartItem.PMC_DH_PlantShipFrom__c=objCartItem.strShipFromId;
        testCartItem.PMC_DH_ShipTo__c=objCartItem.strShipToAccId;
        testCartItem.CartDeliveryGroupId = objCartItem.strDeliveryGroupId;
        testCartItem.PMC_DH_Frequency__c = 'Monthly';
        return testCartItem;
    }
   /**
* @description   : Class for CartItem Param
*

*/ 
    public with sharing class CartItemObject {
          /**
* @description Cart Id of CartItem
* @return  String 
*/
        public String strCartId{get;set;}
          /**
* @description Product Id of CartItem
* @return  String 
*/
        public String strProductId{get;set;}
          /**
* @description DeliveryGroupId Id of Cart
* @return  String 
*/
        public String strDeliveryGroupId{get;set;}
          /**
* @description Ship To Account Id of CartItem
* @return  String 
*/
        public String strShipToAccId{get;set;}
          /**
* @description  Ship From Id of CartItem
* @return  String 
*/
        public String strShipFromId{get;set;}
        /**
* @description  Quote Line Id of CartItem
* @return  String 
*/
        public String strQuoteLineId{get;set;}
        /**
* @description  Contract Id of CartItem
* @return  String 
*/
        public String strContractId{get;set;}
        /**
* @description  Account Id of CartItem
* @return  String 
*/
        public String strAccId{get;set;}
    }
    
    /**
* @description   : Create Account Team member
* 
* @param strAccId
* @param strUserId
* @param strTeamMemberRole
* 
* @return        : AccountTeamMember
*

*/    
    public static AccountTeamMember createTestAccountTeamMember(String strAccId,String strUserId,String strTeamMemberRole){
        AccountTeamMember objAccTeamMember  = new AccountTeamMember();
        objAccTeamMember.AccountId = strAccId;
        objAccTeamMember.TeamMemberRole = strTeamMemberRole;    
        objAccTeamMember.UserId=strUserId;
        if(Schema.sObjectType.AccountTeamMember.isCreateable()) 
        {
        insert objAccTeamMember;
        }
        return objAccTeamMember;
        
    }
    /**
* @description   : Create Portal User
* 
* 
*

*/ 
    @future
    public static void createPortalUser(){
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None'  WITH SECURITY_ENFORCED Limit 1];
        Profile profile1 = new Profile(Id = getSystemAdministratorProfileId(new Map<String,Id>()));
        
        User portalAccountOwner1 = new User(
                FederationIdentifier = 'emailtesting10101xyz@gmail.com',
                MobilePhone = '+1 9876543210',
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username =System.now().millisecond() + 'test211@test.com',
            Alias = 'Test11',
            Email='bruce.wayne1@Test11.com',
            Phone = '+1 1234567890',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago',
            Country = 'United States',
            PMC_CPQ_SalesRegion__c = 'North America'
        );
        Database.insert(portalAccountOwner1);
        System.runAs ( portalAccountOwner1 ) {
            Account portalAccount2 = new Account(
                Name = 'TestAccount',
                OwnerId = portalAccountOwner1.Id,
                Type = 'Sold-to',
                AccountNumber = '12345678',
                BillingState = 'California',
                BillingCity = 'San Francisco', 
                BillingStreet = '123 Test Street',
                BillingPostalCode = '94001', 
                BillingCountry = 'United States'
            );
            Boolean originalBypass = setBypassFlow(true);
            Database.insert(portalAccount2);
            setBypassFlow(originalBypass);
            Contact contactDH = new Contact(
                FirstName = 'DemoUserRequest',
                LastName  = 'Bush',
                Phone = '+1 1234567890',
                PMC_DH_CountryCode__c='US +1',
                Email = 'demouser@test.com',
                AccountId = portalAccount2.id,
                MailingStreet = 'abc',
                Title = 'Customer',
                PMC_SS_Status__c = 'Active',
                Birthdate = date.newInstance(1992,05,01)
            );
            insert contactDH;
            UserRole role = new UserRole (DeveloperName = 'DH_Role' , Name = 'DH_Role' );
            insert role;
            Profile portalProfile = [SELECT Id FROM Profile where Name = 'Digital Hub Super Buyer' WITH SECURITY_ENFORCED Limit 1];
            User testUser = new User(
                FederationIdentifier = 'emailtesting10101xy@gmail.com',
                MobilePhone = '+1 9876543210',
                FirstName = 'DemoUserRequest',
                LastName = 'Bush',
                Email = 'demouser@test.com',
                Username = 'demouser1@test.com.testuser',
                Phone= '+1 1234567890',
                UserRole = role,
                Alias = 'abctest',
                isActive = true,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                ContactId = contactDH.ID,
                ProfileId = portalProfile.id,
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                CurrencyIsoCode = 'USD',
                Country = 'United States'
            );
            
            insert testUser;
            
        }
 
    }


/**
* @description   : Create quote
* 
* @param acc
* @param strContactId
* @return SBQQ__QuoteLine__c
*
*/ 
    public static SBQQ__Quote__c createQuote(Account acc,String strContactId,Opportunity opp){
        Id recordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('PMC_CPQ_DomesticBR').getRecordTypeId();
        Date datToday = Date.today();
        SBQQ__Quote__c testQuote=new SBQQ__Quote__c();
        testQuote.RecordTypeId = recordTypeId;
        testQuote.PMC_CPQ_QuoteShortNameDescription__c='TestDH Quote';
        testQuote.PMC_DH_QuoteFriendlyName__c='Test Quote';
        testQuote.PMC_DH_PaymentMethod__c='ACH';
        testQuote.SBQQ__Status__c='Draft';
        testQuote.PMC_CPQ_PO__c = '1234';
        testQuote.SBQQ__Account__c=acc.id;
        //testQuote.CreatedDate=datToday;
        testQuote.PMC_CPQ_ContractStart__c=datToday;
        testQuote.PMC_CPQ_ContractEnd__c=datToday.addDays(31);
        testQuote.PMC_CPQ_ExpiresOn__c=system.now()+15;
        testQuote.SBQQ__PaymentTerms__c='Cash Against Documents';//'Net 30';
        testQuote.CurrencyIsoCode='USD';
        testQuote.PMC_CPQ_Currency__c='USD';
        //testQuote.PMC_CPQ_ContractStageName__c = 'Pending Signature';
        testQuote.SBQQ__PrimaryContact__c=strContactId;
        testQuote.PMC_CPQ_PrimaryContact__c = strContactId;
        testQuote.PMC_CPQ_AccountManager__c=userinfo.getUserId();
        testQuote.PMC_CPQ_CustomCreatedDate__c=system.now();
        testQuote.SBQQ__Opportunity2__c=opp.id;
        testQuote.PMC_CPQ_QuoteOrigin__c = 'DH Request';
        testQuote.SBQQ__Primary__c = true; //GDASF-20692
        if(Schema.sObjectType.SBQQ__Quote__c.isCreateable()){
            insert testQuote;
        }
        return testQuote;
        
    }

   /**
* @description   : Create order
* @param acc
* @param strContractId
* @return Order
*/ 
    public static Order createOrder(Account acc,Contract conRecord, String cartId){
        Order testOrder = new Order();
        testOrder.Name='Test Order';
        testOrder.AccountId=acc.Id;
        testOrder.Status = 'Draft';
        testOrder.EffectiveDate = Date.today();
        testOrder.Type = 'Standard Sales Order';
        testOrder.ContractId =conRecord.id;
        testOrder.PMC_DH_ContractStartDate__c = conRecord.StartDate;
        
        testOrder.PMC_DH_ContractEndDate__c =conRecord.EndDate;
        testOrder.PMC_DH_ContractEndDate__c  = Date.today().addMonths(3);
        testOrder.SBQQ__Quote__c = conRecord.SBQQ__Quote__c;
        testOrder.CurrencyIsoCode = 'USD';
        testOrder.PMC_DH_SAPOrderCreatedDate__c = Date.today();
        testOrder.Pricebook2Id=Test.getStandardPricebookId();
        testOrder.PMC_CPQ_SAPOrderNumber__c = 'SAP1234';
        //testOrder.OrderNumber='00000193';
        system.debug('TestOrder'+testOrder);
        if(Schema.sObjectType.Order.isCreateable()){
            insert testOrder;
        }
        return testOrder;
    }
    /**
* @description   : Create Order line
* 
* @param testQuote
* @param prod

* @return OrderItem
*/ 
    public static OrderItem creatOrderLine(Order testOrder,CartItem ci){
        
        Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            Update standardPricebook; 
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = standardPricebook.Id,
                Product2Id =  ci.Product2Id,
                UnitPrice = 0,
                IsActive = true,
                CurrencyIsoCode='USD'
                
            );
            Insert pbe;
        
        OrderItem orderItem = new OrderItem();
        orderItem.OrderId = testOrder.Id;
        orderItem.Product2Id = ci.Product2Id;
        orderItem.SBQQ__Contract__c = testOrder.ContractId;
        orderItem.PMC_CPQ_RequestedShipDate__c = ci.PMC_DH_RequestedShipmentDate__c;
        orderItem.PMC_CPQ_ShipTo__c = ci.PMC_DH_ShipTo__c;
        orderItem.PMC_CPQ_ProductLocation__c = ci.PMC_DH_PlantShipFrom__c;
        orderItem.PMC_CPQ_ModeofTransportation__c = ci.PMC_DH_DeliveryMode__c;
        orderItem.PMC_CPQ_Incoterms__c = ci.PMC_DH_Incoterms__c;
        orderItem.PMC_DH_Frequency__c = ci.PMC_DH_Frequency__c;
        orderItem.PMC_CPQ_LinePONumber__c = ci.PMC_DH_DeliveryPONumber__c;
        orderItem.PMC_DH_ItemNumber__c = ci.PMC_DH_ItemNumber__c;
        orderItem.PMC_CPQ_OrderLineStatus__c = 'Placed';
        orderItem.PMC_CPQ_PackageType__c = 'Big Bag 1500 Kg';
        orderItem.PricebookEntryId = pbe.Id;
        orderItem.Quantity = ci.Quantity;
        orderItem.UnitPrice = 0;
        orderItem.ListPrice = 0;
        orderItem.PMC_CPQ_ListPrice__c = 0;
        if(Schema.sObjectType.OrderItem.isCreateable()){
            insert orderItem;
        }
        return orderItem;
            
    }

   /**
* @description   : Create Shipment item
* @param testQuote
* @param prod
* @return ShipmentItem
*/

    public static Shipment createShipment(Order testOrder){
        Shipment shipmnt = new Shipment();
        shipmnt.PMC_CPQ_Order__c = testOrder.Id;
        shipmnt.ShipToName = 'Test';
        shipmnt.PMC_CPQ_SAPDeliveryID__c = '1234';
        shipmnt.PMC_CPQ_ShippedDate__c = System.today();
        shipmnt.PMC_CPQ_DeliveryPlannedGIDate__c = System.today()-1;
        if(Schema.sObjectType.ShipmentItem.isCreateable()){
            insert shipmnt;
        }
        return shipmnt;
    }
    
/**
* @description   : Create Shipment item
* @param testQuote
* @param prod
* @return ShipmentItem
*/
    public static ShipmentItem createShipmentItem(OrderItem orderItem, Shipment shipmnt){
        ShipmentItem deliveryItem = new ShipmentItem();
        deliveryItem.ShipmentId = shipmnt.Id;
        deliveryItem.PMC_CPQ_OrderProduct__c = orderItem.Id;
        deliveryItem.Product2Id = orderItem.Product2Id;
        deliveryItem.PMC_CPQ_VehicleID__c = 'SA1234';
        deliveryItem.PMC_CPQ_ShippedDate__c = System.today();
        deliveryItem.PMC_CPQ_DeliveryQuantity__c = 10;
        deliveryItem.PMC_CPQ_ETA__c = System.today();
        deliveryItem.PMC_CPQ_CurrentLocation__c = 'United States';
        deliveryItem.Quantity = 10;
        deliveryItem.PMC_CPQ_DeliveryItemID__c = '1234_56676';
        deliveryItem.PMC_CPQ_DeliveryStatus__c = 'Completely Shipped';
        deliveryItem.PMC_CPQ_DeliveryLineStatus__c = 'Completely Shipped';
        if(Schema.sObjectType.ShipmentItem.isCreateable()){
            insert deliveryItem;
        }
        return deliveryItem;
    }
  
   /**
* @description   : Create Opportunity
* 
* @param acc
* @return Opportunity
*

*/ 
    public static Opportunity createOpportunity(Account acc){		
    Opportunity objOpportunity = new Opportunity();
            objOpportunity.Name = 'test Opportunity Name';
            objOpportunity.AccountId = acc.Id;
            objOpportunity.CloseDate = System.today();
            objOpportunity.StageName = 'Prospecting';
            objOpportunity.ForecastCategoryName = 'Pipeline';
        objOpportunity.OwnerId=userinfo.getUserId();
        insert objOpportunity;
        return objOpportunity;
    }

    /**
    * @description
    * @param acc 
    * @return Opportunity 
    **/
    public static Opportunity createOpportunity2(Account acc){		
        Opportunity objOpportunity = new Opportunity();
                objOpportunity.Name = 'test Opportunity Name 2.0';
                objOpportunity.AccountId = acc.Id;
                objOpportunity.CloseDate = System.today();
                objOpportunity.StageName = 'New';
                objOpportunity.ForecastCategoryName = 'Pipeline';
            objOpportunity.OwnerId=userinfo.getUserId();
            insert objOpportunity;
            return objOpportunity;
        }
    /**
* @description   : Create quote line
* 
* @param testQuote
* @param prod

* @return SBQQ__QuoteLine__c
*

*/ 
    public static SBQQ__QuoteLine__c creatQuoteLine(SBQQ__Quote__c testQuote,Product2 prod){
        SBQQ__QuoteLine__c testQuoteLine=new SBQQ__QuoteLine__c();
        testQuoteLine.SBQQ__Product__c=prod.id;
        System.debug('Prod Id:'+prod.id);
        testQuoteLine.SBQQ__Quantity__c=25;
        testQuoteLine.PMC_CPQ_Incoterms1__c='CIF';
        testQuoteLine.PMC_CPQ_ModeofTransportation__c='Vessel';
        testQuoteLine.PMC_CPQ_ContractType__c = 'Priced';
        testQuoteLine.SBQQ__Quote__c=testQuote.id;
        testQuoteLine.PMC_CPQ_QuoteRecordType__c = 'Domestic NA';
        testQuoteLine.PMC_CPQ_QuoteRecordSubType__c='Feed';
        testQuoteLine.PMC_CPQ_FinalPricePerTonne__c = 20;
        testQuoteLine.PMC_CPQ_CustomerPrice__c = 20;
        testQuoteLine.PMC_CPQ_UnitofMeasure__c='MTN';
        testQuoteLine.PMC_CPQ_PackType__c='Packed';
        testQuoteLine.PMC_CPQ_PackageType__c='Saco 50 kg';
        testQuoteLine.PMC_CPQ_VCOQuotation__c = true;
        if(Schema.sObjectType.SBQQ__QuoteLine__c.isCreateable()){
            insert testQuoteLine;
        }
        return testQuoteLine;
            
    }

    public static SBQQ__QuoteLine__c creatQuoteLine2(SBQQ__Quote__c testQuote,Product2 prod){
        SBQQ__QuoteLine__c testQuoteLine=new SBQQ__QuoteLine__c();
        testQuoteLine.SBQQ__Product__c=prod.id;
        testQuoteLine.SBQQ__Quantity__c=25;
        testQuoteLine.PMC_CPQ_Incoterms1__c='FOB';
        testQuoteLine.PMC_CPQ_ModeofTransportation__c='Rail';
        testQuoteLine.PMC_CPQ_ContractType__c = 'Priced';
        testQuoteLine.SBQQ__Quote__c=testQuote.id;
        testQuoteLine.PMC_CPQ_QuoteRecordType__c = 'Domestic NA';
        testQuoteLine.PMC_CPQ_QuoteRecordSubType__c='Feed';
        testQuoteLine.PMC_CPQ_FinalPricePerTonne__c = 20;
        testQuoteLine.PMC_CPQ_CustomerPrice__c = 20;
        testQuoteLine.PMC_CPQ_UnitofMeasure__c='STN';
        testQuoteLine.PMC_CPQ_PackType__c='Bulk';
        testQuoteLine.PMC_CPQ_PackageType__c='';
        testQuoteLine.PMC_CPQ_TruckType__c='Graneleiro';
        if(Schema.sObjectType.SBQQ__QuoteLine__c.isCreateable()){
            insert testQuoteLine;
        }
        return testQuoteLine;
            
    }
    
    /**
* @description   : Create Cadence Record
* @param testQuoteLine
* @return PMC_CPQ_Cadence__c
*/
    public static PMC_CPQ_Cadence__c createCadence(SBQQ__QuoteLine__c testQuoteLine){
        PMC_CPQ_Cadence__c testCadence = new PMC_CPQ_Cadence__c();
        testCadence.PMC_CPQ_QuoteLine__c = testQuoteLine.Id;
        testCadence.PMC_CPQ_RequestedDate__c = System.today();
        testCadence.PMC_CPQ_RequestedQuantity__c = 25;
        if(Schema.sObjectType.PMC_CPQ_Cadence__c.isCreateable()){
            insert testCadence;
        }
        return testCadence;
    }

    /**
* @description   : Create SoldTo ShipTo Account Junction
* 
* @param strAccountId
* @param strSoldToAccId
* 
* @return        : PMC_SS_AccountPartnerRelationships__c
*

*/ 
                
public static PMC_SS_AccountPartnerRelationships__c createSoldToShipToAccountJunction(String strAccountId, String strSoldToAccId){
    PMC_SS_AccountPartnerRelationships__c objSoldToShipToAccountJunction = new PMC_SS_AccountPartnerRelationships__c();
    objSoldToShipToAccountJunction.PMC_SS_RelatedAccount__c = strAccountId;
    objSoldToShipToAccountJunction.PMC_SS_Account__c = strSoldToAccId;
    objSoldToShipToAccountJunction.PMC_SS_Type__c=PMC_DH_ConstantClass.ACCOUNT_TYPE;
                
    if(Schema.sObjectType.PMC_SS_AccountPartnerRelationships__c.isCreateable())
    {
    insert objSoldToShipToAccountJunction;
    }
    return objSoldToShipToAccountJunction;    
}
    
    public static void createAccountContactRelation(Id strShipToAccId, Id strEffectiveAccountId) { 
        
        List<AccountContactRelation> lstAccConRelation = new List<AccountContactRelation>();
        for(Contact objContact : [SELECT Id, AccountId FROM Contact WHERE AccountId =:strEffectiveAccountId WITH SECURITY_ENFORCED]){
            AccountContactRelation objAccountContactRelation = new AccountContactRelation();
            objAccountContactRelation.ContactId = objContact.Id;
            objAccountContactRelation.AccountId = strShipToAccId;
            lstAccConRelation.add(objAccountContactRelation);
        }
        if(Schema.sObjectType.AccountContactRelation.isCreateable()){
            Database.insert(lstAccConRelation, false);
        }
        
    }
    
    
    /**
* @description   : Case Create
* @param strAccId
* @param strConId
* @param strBusinessHoursId
* @return        : Case
*

*/
  public static Case createCaseRecord(String strAccId, String strConId, String strBusinessHoursId){
        Case caseRec = new Case();
        caseRec.ContactId= strConId;
        caseRec.AccountId=strAccId;
        caseRec.BusinessHoursId=strBusinessHoursId;
        caseRec.Status='New';
        caseRec.Type='Shipping';
        caseRec.Origin='Email';
        caseRec.Priority='Low';
        caseRec.Subject='test case demo';
        caseRec.PMC_SS_IssueReason__c	='Delivery delay';
        caseRec.description='just for the purpose of test class';
        caseRec.CurrencyIsoCode='USD';
        if(Schema.sObjectType.Case.isCreateable()){
            insert caseRec;
        }
        return caseRec;
        
    } 
    
    /**
* @description   : createContract
* @param strQuoteId
* @param strAcctId
* @return Contract
*
*/ 
    public static Contract createContract(String strQuoteId,String strAcctId){
        Contract testContract=new Contract();
        testContract.SBQQ__Quote__c=strQuoteId;
        testContract.PMC_CPQ_LatestQuote__c=strQuoteId;
        testContract.AccountId=strAcctId;
        testContract.PMC_CPQ_ContractType__c = 'Priced Contract Truck';
        testContract.StartDate = Date.today()-1;
        testContract.EndDate = Date.today().addMonths(3);
        testContract.Status='Draft';
       
        // GDASF-20692
        String strQuoteNumber = [SELECT Name FROM SBQQ__Quote__c WHERE Id =: strQuoteId LIMIT 1].Name;
        testContract.PMC_CPQ_ContractNumberIdentifier__c = strQuoteNumber.split('-')[1];
        if(Schema.sObjectType.Contract.isCreateable()){
            insert testContract;
        }
        return testContract;
    }

    /**
* @description   : createSubscription
* @param objCartItem
* @return SBQQ__Subscription__c
*
*/ 
   public static SBQQ__Subscription__c createSubscription(CartItemObject objCartItem)
    {
        SBQQ__Subscription__c testSubscription = new SBQQ__Subscription__c();
        testSubscription.SBQQ__Quantity__c = 20;
        testSubscription.PMC_CPQ_TotalOrderedQuantity__c = 10;
        testSubscription.PMC_CPQ_TotalAvailableQuantity__c = 10;
        testSubscription.SBQQ__QuoteLine__c = objCartItem.strQuoteLineId;
        testSubscription.SBQQ__Contract__c = objCartItem.strContractId;
        testSubscription.SBQQ__Account__c = objCartItem.strAccId;
        testSubscription.SBQQ__Product__c = objCartItem.strProductId;
        
        // GDASF-20692
        String strSubNumber = generateRandomString(4);
        testSubscription.PMC_CPQ_SubscriptionNumberIdentifier__c = strSubNumber;
        if(Schema.sObjectType.SBQQ__Subscription__c.isCreateable()){
            insert testSubscription;
        }
        return testSubscription;
    }
       
   /**
* @description   : createCommentAndDocForCase
* @param testCaseId
*/ 
    public static void createCommentAndDocForCase(String testCaseId){
        ContentVersion testContent = new ContentVersion(
                Title = 'Test Document',
                PathOnClient = 'testdocument.txt',
                VersionData = Blob.valueOf('Test Content Data')
            );
            insert testContent;
            Id contentId = [SELECT Id,ContentDocumentId FROM contentVersion Where Id=:testContent.Id].ContentDocumentId;
            ContentDocumentLink testCDLink = new ContentDocumentLink();
            testCDLink.LinkedEntityId = testCaseId;
            testCDLink.ContentDocumentId = contentId;
            testCDLink.ShareType = 'V';
            insert testCDLink;
            CaseComment testComment = new CaseComment(
                ParentId = testCaseId,
                CommentBody = 'Test Comment'
            );
            insert testComment;
    }  
   /**
* @description   : createEntitlementRules
* @param strAccId
* @param strProdId
* @return PMC_DH_EntitlementRules__c
*/ 
    public static PMC_DH_EntitlementRules__c createEntitlementRules(String strAccId,String strProdId){
        PMC_DH_EntitlementRules__c testEntitlement = new PMC_DH_EntitlementRules__c();
        testEntitlement.Error_Log__c = 'error log';
        testEntitlement.PMC_DH_isActive__c = True;
        testEntitlement.PMC_DH_isProcessed__c = False;
        testEntitlement.PMC_DH_Type__c = 'ENABLED';
        testEntitlement.PMC_DH_SoldToAccount__c = strAccId;
        testEntitlement.PMC_DH_Product__c = strProdId;
        //if(Schema.sObjectType.PMC_DH_EntitlementRules__c.isCreateable()){
            insert testEntitlement;
        //}
        return testEntitlement;
        
    }
    /**
* @description   : createBuyerGroup
* @return BuyerGroup
*/ 
public static BuyerGroup createBuyerGroup(){
    BuyerGroup testBuyerGroup = new BuyerGroup();
    testBuyerGroup.Name = 'test buyer group';
    testBuyerGroup.Description = 'buyer group for test';
    //testBuyerGroup.Role = 'Account Based';
    //if(Schema.sObjectType.BuyerGroup.isCreateable()){
        insert testBuyerGroup;
    //}
    return testBuyerGroup;
}

    /**
* @description   : createBuyerGroupMember
* @param strBuyerId
* @param strBuyerGroupId
* @return BuyerGroupMember
*/ 
    public static BuyerGroupMember createBuyerGroupMember(String strBuyerId, String strBuyerGroupId){
        BuyerGroupMember testBuyerGroupMember = new BuyerGroupMember();
        testBuyerGroupMember.BuyerId = strBuyerId;
        testBuyerGroupMember.BuyerGroupId = strBuyerGroupId;
        //if(Schema.sObjectType.BuyerGroupMember.isCreateable()){
            insert testBuyerGroupMember;
        //}
        return testBuyerGroupMember;
    }
    /**
* @description   : createEntitlementPolicy
* @return CommerceEntitlementBuyerGroup
*/ 
public static CommerceEntitlementPolicy createEntitlementPolicy(){
    CommerceEntitlementPolicy testEntitlementPolicy = new CommerceEntitlementPolicy();
    testEntitlementPolicy.Name = 'Test Entitlement Policy';
    testEntitlementPolicy.Description = 'Entitlement Policy for the test';
    testEntitlementPolicy.isActive = True;
    testEntitlementPolicy.CanViewProduct = True;
    testEntitlementPolicy.CanViewPrice = True;
    // if(Schema.sObjectType.CommerceEntitlementPolicy.isCreateable()){
        insert testEntitlementPolicy;
    //}
    return testEntitlementPolicy;
}

    
    /**
* @description   : createCommerceEntitlementBuyerGroup
* @param strPolicyId
* @param strBuyerGroupId
* @return CommerceEntitlementBuyerGroup
*/ 
    public static CommerceEntitlementBuyerGroup createCommerceEntitlementBuyerGroup(String strPolicyId, string strBuyerGroupId){
        CommerceEntitlementBuyerGroup testEntitlementBuyerGroup = new CommerceEntitlementBuyerGroup();
        testEntitlementBuyerGroup.PolicyId = strPolicyId;
        testEntitlementBuyerGroup.BuyerGroupId = strBuyerGroupId;
        if(Schema.sObjectType.CommerceEntitlementBuyerGroup.isCreateable()){
            insert testEntitlementBuyerGroup;
        }
        return testEntitlementBuyerGroup;
    }
    /**
* @description   : createCommerceEntitlementProduct
* @param strPolicyId
* @param strProdId
* @return CommerceEntitlementProduct
*/  
    public static CommerceEntitlementProduct createCommerceEntitlementProduct(String strPolicyId, String strProdId){
        CommerceEntitlementProduct testEntitlementProduct = new CommerceEntitlementProduct();
        testEntitlementProduct.PolicyId = strPolicyId;
        testEntitlementProduct.ProductId = strprodId;
        //if(Schema.sObjectType.CommerceEntitlementProduct.isCreateable()){
            insert testEntitlementProduct;
        //}
        return testEntitlementProduct;
    }
        /**
* @description   : createIndividual
* @param user
* @return Individual
*/ 
    public static Individual createIndividual(User user){
        Individual ind = new Individual();
        ind.FirstName = user.Contact.FirstName;
        ind.LastName = user.Contact.LastName;
        insert ind;
        return ind;
    }

        /**
* @description   : createCommerceEntitlementSalesArea
* @param strAccountId
* @param strProductId
* @param strSalesAreaId
* @return void
*/  
    public static void createCommerceEntitlementSalesArea(String strAccountId, String strProductId, String strSalesAreaId){
        PMC_DH_CommerceEntitlementSalesArea__c cesa = new PMC_DH_CommerceEntitlementSalesArea__c(
        PMC_DH_Account__c = strAccountId,
        PMC_DH_Product__c = strProductId,
        PMC_DH_SalesArea__c = strSalesAreaId);
        //if(Schema.sObjectType.PMC_DH_CommerceEntitlementSalesArea__c.isCreateable()){
            insert cesa;
        //}
    }


     /**
    * @description 
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 01-23-2024 
    * @param testQuote 
    * @param prod 
    * @param prod2 
    * @return List<SBQQ__QuoteLine__c> 
    **/
    public static List<SBQQ__QuoteLine__c> createMutipleQuoteLines(SBQQ__Quote__c testQuote,Product2 prod,Product2 prod2,Opportunity opp2)
    {
        List<SBQQ__QuoteLine__c> lstQuoteLine=new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c testQuoteLine1=new SBQQ__QuoteLine__c();
        testQuoteLine1.SBQQ__Product__c=prod.id;
        testQuoteLine1.SBQQ__Quantity__c=25;
        testQuoteLine1.PMC_CPQ_Incoterms1__c='CIF';
        testQuoteLine1.PMC_CPQ_ModeofTransportation__c='Vessel';
        testQuoteLine1.PMC_CPQ_ContractType__c = 'Priced';
        testQuoteLine1.SBQQ__Quote__c=testQuote.id;
        testQuoteLine1.PMC_CPQ_QuoteRecordType__c = 'Domestic NA';
        testQuoteLine1.PMC_CPQ_QuoteRecordSubType__c='Feed';
        testQuoteLine1.PMC_CPQ_FinalPricePerTonne__c = 20;
        testQuoteLine1.PMC_CPQ_CustomerPrice__c = 20;
        testQuoteLine1.PMC_CPQ_UnitofMeasure__c='MTN';
        testQuoteLine1.PMC_CPQ_PackType__c='Packed';
        testQuoteLine1.PMC_CPQ_PackageType__c='Saco 50 kg';
        lstQuoteLine.add(testQuoteLine1);
        testQuote.SBQQ__Opportunity2__c=opp2.id;
        if(Schema.sObjectType.SBQQ__Quote__c.isUpdateable()){
            update testQuote;
        }
        
        SBQQ__QuoteLine__c testQuoteLine2=new SBQQ__QuoteLine__c();
        testQuoteLine2.SBQQ__Product__c=prod2.id;
        testQuoteLine2.SBQQ__Quantity__c=25;
        testQuoteLine2.PMC_CPQ_Incoterms1__c='CIF';
        testQuoteLine2.PMC_CPQ_ModeofTransportation__c='Vessel';
        testQuoteLine2.PMC_CPQ_ContractType__c = 'Priced';
        testQuoteLine2.SBQQ__Quote__c=testQuote.id;
        testQuoteLine2.PMC_CPQ_QuoteRecordType__c = 'Domestic NA';
        testQuoteLine2.PMC_CPQ_QuoteRecordSubType__c='Feed';
        testQuoteLine2.PMC_CPQ_FinalPricePerTonne__c = 20;
        testQuoteLine2.PMC_CPQ_CustomerPrice__c = 20;
        testQuoteLine2.PMC_CPQ_UnitofMeasure__c='STN';
        testQuoteLine2.PMC_CPQ_PackType__c='Packed';
        testQuoteLine2.PMC_CPQ_PackageType__c='Saco 50 kg';
        lstQuoteLine.add(testQuoteLine2);
        if(Schema.sObjectType.SBQQ__QuoteLine__c.isCreateable()){
            insert lstQuoteLine;
        }
        return lstQuoteLine;
    }
    /**
    * @description test method to create  Catalog
    * @author Humera Rahath
    **/
    public static ProductCatalog createTestCatalog(){
        ProductCatalog testCatalog=new ProductCatalog();
        testCatalog.name='Mosaic Direct Catalog';
        insert testCatalog;
        return testCatalog;
    }
    /**
    * @description test method to create parent category
    * @author Humera Rahath
    * @param strCatalogId
    **/
    public static void CreateTestParentCategory(String strCatalogId){
        ProductCategory testCategory = new ProductCategory();
        testCategory.CatalogId=strCatalogId;
        testCategory.name='Products';
        testCategory.PMC_DH_Category_ID__c='Products';
        insert testCategory;
    }

    /**
    * @description Create to handle PROD related test run fails
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 03-14-2024 
    * @return User 
    **/
    private static Id getSystemAdministratorProfileId(Map<String,Id> mapOfProfiles){
        Id systemAdministratorProfileId = mapOfProfiles.get('System Administrator');
        if(systemAdministratorProfileId == null){
            systemAdministratorProfileId = [SELECT Id FROM Profile WHERE PermissionsModifyAllData = true AND UserType = 'Standard' ORDER BY CreatedDate ASC LIMIT 1].Id;
        }
        return systemAdministratorProfileId;
    }

    public static User createAdminUser()
    {
        List<String>lstProfileNames = New List<String>{'System Administrator'};
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group'};
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        String strRoleId=[Select id from UserRole where Name='Admin' LIMIT 1].id;
        Integer intuserCount =0;
        User objSystemAdminUser;  
        List<User> lstUser = PMC_TestUtilityClass.createUser(1);
            for(User objUser : lstUser) {
                If(intuserCount==0){
                objUser.LastName = 'Admin User Test';
                objUser.ProfileId = getSystemAdministratorProfileId(mapOfProfiles);
                objUser.FederationIdentifier = objUser.Username + 'Admin';
                }
                objUser.isActive = true;
                objUser.UserRoleId=strRoleId;              
                objUser.MobilePhone = '1234567890';
                objUser.UserPermissionsKnowledgeUser =true;
                objUser.LanguageLocaleKey = 'en_US';
                intuserCount = intuserCount + 1;
            }            
            insert lstUser;
            objSystemAdminUser = lstUser[0];
            PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));        
            return objSystemAdminUser;
    }
    /**
    * @description Method to generate random string
    * @author Nikhilesh Mohanty
    * @param lengthOfString
    * @return User 
    **/
    public static String generateRandomString(Integer lengthOfString) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String strRand = '';
        while (strRand.length() < lengthOfString) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            strRand += chars.substring(idx, idx+1);
        }
        return strRand; 
    }
    

    
    
    // ... [Other existing factory methods]
    
    /**
     * @description   : Create additional helper methods if needed
     * 
     * Note: Existing methods are not modified. Only new methods are added here.
     **/
    
    /**
     * @description   : Create multiple CartItems with Contracts
     * 
     * @param lstCartItemObjects : List<CartItemObject>
     * @return List<CartItem>
     **/
    public static List<CartItem> buildMultipleCartItems(List<CartItemObject> lstCartItemObjects){
        List<CartItem> lstCartItems = new List<CartItem>();
        for(CartItemObject obj : lstCartItemObjects){
            CartItem ci = buildCartItem1(obj);
            lstCartItems.add(ci);
        }
        return lstCartItems;
    }
    
    /**
     * @description   : Create CartItemObject
     * 
     * @param strCartId
     * @param strProductId
     * @param strDeliveryGroupId
     * @param strShipToAccId
     * @param strShipFromId
     * @param strContractId
     * @return CartItemObject
     **/
    public static CartItemObject createCartItemObject(String strCartId, String strProductId, String strDeliveryGroupId, String strShipToAccId, String strShipFromId, String strContractId){
        CartItemObject obj = new CartItemObject();
        obj.strCartId = strCartId;
        obj.strProductId = strProductId;
        obj.strDeliveryGroupId = strDeliveryGroupId;
        obj.strShipToAccId = strShipToAccId;
        obj.strShipFromId = strShipFromId;
        obj.strContractId = strContractId;
        return obj;
    }
    
    
}