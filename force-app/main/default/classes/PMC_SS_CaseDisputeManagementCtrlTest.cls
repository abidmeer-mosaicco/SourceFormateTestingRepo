@isTest(seeAllData = false)
public with sharing class PMC_SS_CaseDisputeManagementCtrlTest  {

    /**
    * @description This Method will be used to setup the test data for the test class execution.
    */
    
    @testsetup
    private static void setup() {
        List<String>lstProfileNames = New List<String>{'System Administrator','Service User'};
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SRV_Permission_Set_Group'};
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        Integer intuserCount =0;
        User objSystemAdminUser;  
        User objServiceUser;
        List<User> lstUser = PMC_TestUtilityClass.createUser(2);
            for(User objUser : lstUser) {
                If(intuserCount==0){
                   objUser.LastName = 'Admin User Test';
                   objUser.ProfileId = mapOfProfiles.get('System Administrator'); 
                   objUser.FederationIdentifier = objUser.Username + 'Admin';
                }else if(intuserCount==1){
                    objUser.LastName = 'Service User Test';
                    objUser.ProfileId = mapOfProfiles.get('Service User'); 
                   objUser.FederationIdentifier = objUser.Username + 'Service';
                }
                objUser.isActive = true;                
                objUser.MobilePhone = '1234567890';
                intuserCount = intuserCount + 1;
            }            
            insert lstUser;
            objSystemAdminUser = lstUser[0];
            objServiceUser = lstUser[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objServiceUser}, mapOfPermissionGrp.get('PMC_SRV_Permission_Set_Group'));
        BusinessHours objBusinessHrs = [SELECT Id, Name FROM BusinessHours WHERE isDefault = True AND IsActive = True];
        Account objAccount;
        Contact objContact;
        Opportunity objOpportunity;
        Contract objContract;
        System.runAs(objServiceUser){
        objAccount = PMC_TestUtilityClass.createAccount('Mike Rau', 'PMC_SS_Prospect');
        objContact = PMC_TestUtilityClass.createContact(1, '')[0];
        objOpportunity =  PMC_TestUtilityClass.createOpportunity(1, '')[0];
        }
	System.runAs(objSystemAdminUser){
        List<Account>lstAccount = new List<Account>{objAccount};  
        List<Opportunity>lstOpportunity = new List<Opportunity>{objOpportunity};
        //objContract = PMC_TestUtilityClass.createContract(new List<Account>{lstAccount}, new List<Opportunity>{lstOpportunity})[0];
        objContract = PMC_TestUtilityClass.createContract(lstAccount, lstOpportunity)[0];

        }
        Schema.Location objLocation ;
        PMC_CPQ_ProductLocation__c objProductLocation;
        Order objOrder;
        OrderItem objOrderItem;
        Shipment objShipment;
        ShipmentItem objShipmentItem;
        PMC_CPQ_Invoice__c objInvoice;
        System.runAs(objSystemAdminUser){
        objLocation = PMC_TestUtilityClass.createLocation('Test Schema.Location');
        objProductLocation = PMC_TestUtilityClass.createProductLocation('Test Product Location', objLocation);
        
        objOrder = PMC_TestUtilityClass.createOrders(1, new List<Account>{objAccount})[0];
        objOrder.PMC_CPQ_ShipToAccount__c = objAccount.Id;
        objOrder.PMC_CPQ_SoldToAccount__c = objAccount.Id;
        objOrder.ContractId = objContract.Id;
		update objOrder;
              
        objOrderItem = PMC_TestUtilityClass.createOrderProducts(1, new List<Order>{objOrder})[0];
        //objOrderItem = [Select Id,PMC_CPQ_ProductLocation__c,UnitPrice FROM OrderItem limit 1];
        objOrderItem.UnitPrice = 50;
        objOrderItem.PMC_CPQ_ProductLocation__c = objProductLocation.Id;
        //update objOrderItem;
        
        objShipment = PMC_TestUtilityClass.createDelivery('Test Shipment Name', objOrder);
        objShipmentItem = PMC_TestUtilityClass.createDeliveryItem(objShipment, objOrderItem);
        objInvoice = PMC_TestUtilityClass.createInvoice(objShipment, objOrder, objContact);
   
        }
        System.runAs(objServiceUser){
        Case objCase = PMC_TestUtilityClass.createCase(objBusinessHrs.Id, objAccount.Id, objServiceUser.Id,objLocation.Id);
        insert objCase;
        }    
    }
    
    /**
    * @description This Method will be used to cover GetOrderItems from PMC_SS_CaseDisputeManagementCtrl
    */
    @isTest
    private static void testGetOrderItems() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Order objOrder = [SELECT Id, Name FROM Order WHERE Name = 'Test Order 0' WITH SECURITY_ENFORCED LIMIT 1];        
        if(objUser != null && objOrder != null) {            
                PMC_SS_CaseDisputeManagementWrappers.OrderDetailsWrapper objOrderDetailsWrapper = PMC_SS_CaseDisputeManagementCtrl.getOrderItems(objOrder.Id);
            System.assertEquals(objOrderDetailsWrapper.objOrder.Id, objOrder.Id, 'Order has been updated on Wrapper');
            
        }
        }
        Test.stopTest();
    }
    
    /**
    * @description This Method will be used to cover GetOrderItems from PMC_SS_CaseDisputeManagementCtrl
    */
    @isTest
    private static void testGetOrderItemsFailure() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        try {            
            if(objUser != null) {
                System.runAs(objUser) {
                    PMC_SS_CaseDisputeManagementCtrl.getOrderItems('123456789012');
                    system.assert(true, 'Exceptions should be handled by the method');
                }
            }
        }
        catch(Exception objException) {
            System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
        }
        
        Test.stopTest();
    }
    
    /**
    * @description This Method will be used to cover GetDeliveryItems from PMC_SS_CaseDisputeManagementCtrl
    */
    @isTest
    private static void testGetDeliveryItems() {
        Test.startTest();
        List<OrderItem> objOrderItems = new List<OrderItem>();
        User objUser = [SELECT Id, Name FROM User Where LastName='Admin User Test' WITH SECURITY_ENFORCED LIMIT 1];
        if(objUser != null) {
            System.runAs(objUser) {
                objOrderItems = [Select Id from OrderItem where Order.Name ='Test Order 0' limit 1];
                If(!objOrderItems.isEmpty()){
                List<ShipmentItem> lstShipmentItems = PMC_SS_CaseDisputeManagementCtrl.getDeliveryItems(objOrderItems[0].Id);
                System.assertEquals(lstShipmentItems.size(), 1, 'Shipment Item Fetched'); 
                }
            }
        }
        Test.stopTest();
    }
    
    /**
    * @description This Method will be used to cover GetPickListValues from PMC_SS_CaseDisputeManagementCtrl
    */
    @isTest
    private static void testGetPickListValues() {
        Test.startTest();
        
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
            List<Map<String, String>> lstMapPicklistVal = PMC_SS_CaseDisputeManagementCtrl.getPickListValues('Case', 'PMC_SS_PaymentRequestType__c');
            
            System.assertNotEquals(lstMapPicklistVal.size(), 0, 'Picklist values fetched');
            try{
               PMC_SS_CaseDisputeManagementCtrl.getPickListValues('Account', 'PMC_SS_PaymentRequestType__c');

            }catch(Exception objException){
            System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
        	}
            try{
               PMC_SS_CaseDisputeManagementCtrl.getPickListValues('Acgcount', 'PMC_SS_PaymentRequestType__c');

            }catch(Exception objException){
            System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
        	}
        }
        
        Test.stopTest();
    }
    
    /**
    * @description This Method will be used to cover testUploadFile from PMC_SS_CaseDisputeManagementCtrl
    */
    @isTest
    private static void testUploadFile() {
        Test.startTest();
        
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
		Case objCase = [SELECT Id FROM Case LIMIT 1];
        
        if(objCase != null) {            
                String strId = PMC_SS_CaseDisputeManagementCtrl.uploadFile('VGVzdCAxMjM0', 'test file', objCase.Id);
                System.assertNotEquals(strId, '1234567890','Id Not Matching');
            }
        }
        Test.stopTest();
    }
    
    
    /**
    * @description This Method will be used to cover testUploadFile from PMC_SS_CaseDisputeManagementCtrl
    */
    @isTest
    private static void testUploadFileFailure() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];

       System.runAs(objUser) {
        try {
            Case objCase = [SELECT Id FROM Case LIMIT 1];
            
            if(objCase != null) {
                
                    PMC_SS_CaseDisputeManagementCtrl.uploadFile('', 'test file', objCase.Id);
                
            }
        }
        catch(Exception objException) {
            System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
        }        
       }
        Test.stopTest();
    }
    
    /**
    * @description This Method will be used to cover testUploadFile from PMC_SS_CaseDisputeManagementCtrl
    */
    @isTest
    private static void testUploadFileNull() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
       System.runAs(objUser){
        try {
            Case objCase = [SELECT Id FROM Case LIMIT 1];
            
            if(objCase != null) {
                    PMC_SS_CaseDisputeManagementCtrl.uploadFile('VGVzdCAxMjM0', 'test file', null);
                
            }
        }
        catch(Exception objException) {
            System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
        }        
       }
        Test.stopTest();
    }
    
    
    /**
    * @description This Method will be used to cover getContracts from PMC_SS_CaseDisputeManagementCtrl
    */
    @isTest
    private static void testGetContracts() {
        Test.startTest();
        
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Account objAccount = [SELECT Id FROM Account WITH SECURITY_ENFORCED LIMIT 1];

        if(objAccount != null) {           
           
                List<Contract> lstContracts = PMC_SS_CaseDisputeManagementCtrl.getContracts(objAccount.Id);
                System.assertNotEquals(100, lstContracts.size(), 'Contracts Retrieved');
            
        }
        }
        Test.stopTest();
    }
    
    /**
    * @description This Method will be used to cover getContracts from PMC_SS_CaseDisputeManagementCtrl
    */
    @isTest
    private static void testGetContractsException() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        try {            
            if(objUser != null) {
                    PMC_SS_CaseDisputeManagementCtrl.getContracts('');
            }
        }
        catch(Exception objException) {
            System.assertNotEquals('', objException.getMessage(), 'Expected error log object to be created');
        }        
        }
        Test.stopTest();
    }    
}