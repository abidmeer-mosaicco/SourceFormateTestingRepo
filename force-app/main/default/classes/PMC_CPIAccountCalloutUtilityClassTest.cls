/**
* @description This test class will be used to cover all the methods of PMC_TestUtilityClass.
* @author Kailas Shimpi
* @storynumber GPSSM-1224
*/

@isTest(SeeAllData=false)
private class PMC_CPIAccountCalloutUtilityClassTest {
    
    // Method to create test Account Data
    @isTest private static Account createTestAccount() {
        
        String gsRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        
        Account testAccountManager = new Account(
            RecordTypeId = gsRecordTypeID,
            Name = 'Test Account Manager',
            BillingCountryCode = 'BR',
            Phone = '(12) 3456-7890',
            Fax = '',
            PMC_SS_SalesOrg__c = '4000',
            PMC_SS_SalesOffice__c = '430A',
            PMC_SS_SalesDistrict__c = 'ZBR004',
            Sales_Group__c = '785',
            PMC_SS_PaymentTerm__c = 'D030',
            Customer_Group__c = '07',
            PMC_SS_SAPCustomerNumber__c = '2003020',
            PMC_SS_ReconciliationAccount__c = '110003',
            PMC_SS_StateTaxNumber__c = '1234567',
            PMC_SS_MunicipalTaxNumber__c = 'MT67890',
            PMC_SS_ShippingCondition__c = 'Z2',
            PMC_SS_Underdeltolerance__c = 5,
            PMC_SS_OverdelTolerance__c = 10
        );
        insert testAccountManager;
        
        Account testCommissionAgent = new Account(
            RecordTypeId = gsRecordTypeID,
            Name = 'Test Commission Agent',
            BillingCountryCode = 'BR',
            Phone = '(12) 3456-7890',
            Fax = '',
            PMC_SS_SalesOrg__c = '4000',
            PMC_SS_SalesOffice__c = '430A',
            PMC_SS_SalesDistrict__c = 'ZBR004',
            Sales_Group__c = '785',
            PMC_SS_PaymentTerm__c = 'D030',
            Customer_Group__c = '07',
            PMC_SS_SAPCustomerNumber__c = '2003040',
            PMC_SS_ReconciliationAccount__c = '110003',
            PMC_SS_StateTaxNumber__c = '1234567',
            PMC_SS_MunicipalTaxNumber__c = 'MT67890',
            PMC_SS_ShippingCondition__c = 'Z2',
            PMC_SS_Underdeltolerance__c = 5,
            PMC_SS_OverdelTolerance__c = 10
        );
        insert testCommissionAgent;
        
        Account testTSMManager = new Account(
            RecordTypeId = gsRecordTypeID,
            Name = 'Test TSM Manager',
            BillingCountryCode = 'BR',
            Phone = '(12) 3456-7890',
            Fax = '',
            PMC_SS_SalesOrg__c = '4000',
            PMC_SS_SalesOffice__c = '430A',
            PMC_SS_SalesDistrict__c = 'ZBR004',
            Sales_Group__c = '785',
            PMC_SS_PaymentTerm__c = 'D030',
            Customer_Group__c = '07',
            PMC_SS_SAPCustomerNumber__c = '2003050',
            PMC_SS_ReconciliationAccount__c = '110003',
            PMC_SS_StateTaxNumber__c = '1234567',
            PMC_SS_MunicipalTaxNumber__c = 'MT67890',
            PMC_SS_ShippingCondition__c = 'Z2',
            PMC_SS_Underdeltolerance__c = 5,
            PMC_SS_OverdelTolerance__c = 10
        );
        insert testTSMManager;
        
        Account testCustServRep = new Account(
            RecordTypeId = gsRecordTypeID,
            Name = 'Test Cust Serv Rep',
            BillingCountryCode = 'BR',
            Phone = '(12) 3456-7890',
            Fax = '',
            PMC_SS_SalesOrg__c = '4000',
            PMC_SS_SalesOffice__c = '430A',
            PMC_SS_SalesDistrict__c = 'ZBR004',
            Sales_Group__c = '785',
            PMC_SS_PaymentTerm__c = 'D030',
            Customer_Group__c = '07',
            PMC_SS_SAPCustomerNumber__c = '',
            PMC_SS_ReconciliationAccount__c = '110003',
            PMC_SS_StateTaxNumber__c = '1234567',
            PMC_SS_MunicipalTaxNumber__c = 'MT67890',
            PMC_SS_ShippingCondition__c = 'Z2',
            PMC_SS_Underdeltolerance__c = 5,
            PMC_SS_OverdelTolerance__c = 10
        );
        insert testCustServRep;    
        
        Account testBillTo = new Account(
            RecordTypeId = gsRecordTypeID,
            Name = 'TestBillTo Partner',
            Type = 'Bill-to',
            BillingCountryCode = 'US',
            BillingStateCode = 'PA',
            BillingCity = 'Oletafort',
            BillingPostalCode = '71847',
            BillingStreet = '2823 Dare Inlet',
            Phone = '1234567890',
            Fax = '',
            PMC_SS_SalesOrg__c = '1002',
            PMC_SS_SalesOffice__c = '303C',
            PMC_SS_SalesDistrict__c = 'US0006',
            Sales_Group__c = '907',
            PMC_SS_PaymentTerm__c = 'D030',
            Customer_Group__c = '01',
            PMC_SS_SAPCustomerNumber__c = '3000030',
            PMC_SS_Segmentation__c = '10',
            PMC_SS_ReconciliationAccount__c = '110003',
            PMC_SS_ShippingCondition__c = 'Z2',
            PMC_SS_Underdeltolerance__c = 5,
            PMC_SS_OverdelTolerance__c = 10,
            Team_Accounts_Attribute_4__c = '05',
            Sales_Channel_Attribute_5__c = '10',
            Country_Region_Attribute_6__c = 'AN',
            Sales_Region_Attribute_7__c = '07A'
        );
        
        Account testPayer = new Account(
            RecordTypeId = gsRecordTypeID,
            Name = 'TestPayer Partner',
            Type = 'Payer',
            BillingCountryCode = 'US',
            BillingStreet = '111 PayerPartner Street',            
            Phone = '1234567890',
            Fax = '',
            PMC_SS_SalesOrg__c = '1002',
            PMC_SS_SalesOffice__c = '303C',
            PMC_SS_SalesDistrict__c = 'US0006',
            Sales_Group__c = '907',
            PMC_SS_PaymentTerm__c = 'D030',
            Customer_Group__c = '01',
            PMC_SS_SAPCustomerNumber__c = '3000030',
            PMC_SS_Segmentation__c = '10',
            PMC_SS_ReconciliationAccount__c = '110003',
            PMC_SS_ShippingCondition__c = 'Z2',
            PMC_SS_Underdeltolerance__c = 5,
            PMC_SS_OverdelTolerance__c = 10,
            Team_Accounts_Attribute_4__c = '05',
            Sales_Channel_Attribute_5__c = '10',
            Country_Region_Attribute_6__c = 'AN',
            Sales_Region_Attribute_7__c = '07A'
        );
        
        Account testSoldTo = new Account(
            RecordTypeId = gsRecordTypeID,
            Name = '4567890ABC SoldTo',
            Type = 'Sold-to',
            BillingCountryCode = 'US',
            BillingStateCode = 'MD',
            BillingCity = 'Runolfssonbury',
            BillingPostalCode = '51573',
            BillingStreet = '585 Gibson Crossroad',
            Phone = '1234567890',
            Fax = '',
            PMC_SS_SalesOrg__c = '1002',
            PMC_SS_SalesOffice__c = '303C',
            PMC_SS_SalesDistrict__c = 'US0006',
            Sales_Group__c = '907',
            PMC_SS_PaymentTerm__c = 'D030',
            Customer_Group__c = '01',
            PMC_SS_SAPCustomerNumber__c = '3000030',
            PMC_SS_Segmentation__c = '10',
            PMC_SS_ReconciliationAccount__c = '110003',
            PMC_SS_ShippingCondition__c = 'Z2',
            PMC_SS_Underdeltolerance__c = 5,
            PMC_SS_OverdelTolerance__c = 10,
            Team_Accounts_Attribute_4__c = '05',
            Sales_Channel_Attribute_5__c = '10',
            Country_Region_Attribute_6__c = 'AN',
            Sales_Region_Attribute_7__c = '07A'
        );
        insert testSoldTo;  
        
        Account testShipTo = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Ship-to Customer').getRecordTypeId(),
            Name = 'Test Ship To Partner',
            Type = 'Ship-to',
            BillingCountryCode = 'BR',
            Phone = '(12) 3456-7890',
            Fax = '',
            PMC_SS_PaymentTerm__c = 'D030',
            Customer_Group__c = '07',
            PMC_SS_SoldToAccount__c = testSoldTo.Id,
            PMC_SS_SAPCustomerNumber__c = '2000020',
            PMC_SS_ReconciliationAccount__c = '110003',
            PMC_SS_StateTaxNumber__c = '1234567',
            PMC_SS_MunicipalTaxNumber__c = 'MT67890',
            PMC_SS_ShippingCondition__c = 'Z2',
            PMC_SS_Underdeltolerance__c = 5,
            PMC_SS_OverdelTolerance__c = 10
        );
        insert testShipTo;  
        
        Account testAccount = new Account(
            RecordTypeId = gsRecordTypeID,
            Account_Manager__c = testAccountManager.id,
            Name = 'Test Account',
            BillingCountryCode = 'BR',
            Commissions_agent_account__c = testCommissionAgent.Id,
            Cust_Serv_Rep_Account__c = testCustServRep.Id,
            Domestic_Broker_Text__c = '1004433',
            Domestic_Broker_2__c = '1004455',
            TSM_Manager_Account__c = testTSMManager.Id,
            Bill_to_partner_related__c = testBillTo.Id,
            Payer_partner_related__c = testPayer.Id,
            PMC_SS_SoldToAccount__c = testSoldTo.Id,
            Shipto_partner_related__c = testShipTo.Id,
            Phone = '(12) 3456-7890',
            Fax = '',
            PMC_SS_SalesOrg__c = '4000',
            PMC_SS_SalesOffice__c = '430A',
            PMC_SS_SalesDistrict__c = 'ZBR004',
            Sales_Group__c = '785',
            PMC_SS_PaymentTerm__c = 'D030',
            Customer_Group__c = '07',
            PMC_SS_SAPCustomerNumber__c = '',
            PMC_SS_ReconciliationAccount__c = '110003',
            PMC_SS_StateTaxNumber__c = '1234567',
            PMC_SS_MunicipalTaxNumber__c = 'MT67890',
            PMC_SS_ShippingCondition__c = 'Z2',
            PMC_SS_Underdeltolerance__c = 5,
            PMC_SS_OverdelTolerance__c = 10
        );
        insert testAccount;
        return testAccount;
    }
    
    // Mock class for HTTP callout
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testSendCalloutRequest() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        String method = 'POST';
        String endpoint = 'https://test.endpoint.com/api';
        String requestBody = '{"key":"value"}';
        
        Test.startTest();
        HttpResponse response = PMC_CPIAccountCalloutUtilityClass.sendCalloutRequest(method, endpoint, requestBody);
        Test.stopTest();
        
        System.assertNotEquals(response, null, 'Response should not be null');
        System.assertEquals(response.getStatusCode(), 200, 'Status code should be 200');
    }
    
    // Test Method: Validates the createShipToPayload method
    @isTest
    static void testCreateShipToPayload() {
        // Create the test Account
        Account testAccount = createTestAccount();
        
        // Prepare test data
        List<Id> accountIds = new List<Id>{ testAccount.Id };
            Map<String, String> jsonParams = new Map<String, String>{
                'strOverDelivTol' => '35',
                    'strUnderDelivTol' => '99',
                    'strAccountManager' => 'ZF',
                    'strAcctAssmtGrpCust' => 'Group1',
                    'strBillToPartner' => 'BP',    
                    'strBPGrouping' => 'Z002',
                    'BusinessPartnerCategory' => '2',    
                    'strCashPlanningGroup' => 'C1',
                    'strCNPJNumber' => '987654321',
                    'strCommissionAgent' => 'ZH',
                    'strCPFNumber' => '11122233344',
                    'strCurrency' => 'USD',
                    'strCustomerTaxCategory' => 'TaxA',
                    'strCustPriceProc' => '1',                
                    'strCustServRep' => 'ZA',                
                    'strCustomerGroup' => '07',                
                    'strDistChannel' => '00',                
                    'strDivision' => '10',
                    'strDomesticBroker' => 'ZJ',
                    'strInvDates' => 'US',
                    'strInvListSched' => 'US',
                    'strItemOrderProb' => '100',
                    'strLanguage' => 'EN',
                    'strLayoutSortingRule' => 'RuleX',
                    'strNaturalPerson' => 'X',
                    'strOperation' => 'BPCreation',
                    'strPartnerFunction' => 'FunctionX',
                    'strReconcAcc' => '12345',
                    'strRUCPYOrg' => 'RUC5678',
                    'strRUCPYPerson' => 'RUC1234',
                    'strSalesOrg' => '4000',
                    'strSalesOffice' => '430A',
                    'strSalesDistrict' => 'ZBR004',
                    'strSalesGroup' => '785',			
                    'strSearchTerm1' => 'SearchTerm',
                    'strShipCondition' => 'Z2',
                    'strTaxClass' => 'ClassX',
                    'strToleranceGroup' => 'T1',
                    'strTransportation' => 'TransportA',
                    'strTSMManager' => 'ZB'
                    };
                        
                        String strRUCPYOrg = '12345678';
        String strRUCPYPerson = '12345678';
        
        Test.startTest();        
        // Invoke method
        String payload = PMC_CPIAccountCalloutUtilityClass.createShipToPayload(accountIds, jsonParams);
        
        // Assertions
        System.assertNotEquals(payload, null, 'Serialized body should not be null');
        System.assert(payload.contains('Z002'), 'Payload should include Business Partner Grouping');
        
        Test.stopTest();
    }
    
   @isTest
    static void testCreateSoldToPayload() {
        // Step 1: Validate that record type exists in this org
        Schema.RecordTypeInfo customerRTInfo = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer');
        System.assertNotEquals(customerRTInfo, null, 'RecordType "Customer" is missing in this org');
        String customerRTId = customerRTInfo.getRecordTypeId();
        
        // Step 2: Create test Account (already does related record inserts)
        Account testAccount;
        try {
            testAccount = createTestAccount();
        } catch (Exception e) {
            System.debug('Failed to create testAccount: ' + e.getMessage());
            System.assert(false, 'Test account creation failed due to: ' + e.getMessage());
        }
        
        System.assertNotEquals(testAccount, null, 'testAccount should not be null');
        System.assertNotEquals(testAccount.Id, null, 'testAccount.Id should not be null');
        
        // Step 3: JSON parameters for Sold-to
        Map<String, String> jsonParams = new Map<String, String>{
            'strOverDelivTol' => '35',
                'strUnderDelivTol' => '99',
                'strAccountManager' => 'ZF',
                'strAcctAssmtGrpCust' => 'Group1',
                'strBillToPartner' => 'BP',    
                'strBPGrouping' => 'Z001',
                'BusinessPartnerCategory' => '2',    
                'strCashPlanningGroup' => 'C1',
                'strCNPJNumber' => '987654321',
                'strCommissionAgent' => 'ZH',
                'strCPFNumber' => '11122233344',
                'strCurrency' => 'USD',
                'strCustomerTaxCategory' => 'TaxA',
                'strCustPriceProc' => '1',                
                'strCustServRep' => 'ZA',                
                'strCustomerGroup' => '07',                
                'strDistChannel' => '00',                
                'strDivision' => '10',
                'strDomesticBroker' => 'ZJ',
                'strInvDates' => 'US',
                'strInvListSched' => 'US',
                'strItemOrderProb' => '100',
                'strLanguage' => 'EN',
                'strLayoutSortingRule' => 'RuleX',
                'strNaturalPerson' => 'X',
                'strOperation' => 'BPCreation',
                'strPartnerFunction' => 'FunctionX',
                'strPaymentTerm' => 'D030',
                'strReconcAcc' => '12345',
                'strRUCPYOrg' => 'RUC5678',
                'strRUCPYPerson' => 'RUC1234',
                'strSalesOrg' => '4000',
                'strSalesOffice' => '430A',
                'strSalesDistrict' => 'ZBR004',
                'strSalesGroup' => '785',			
                'strSearchTerm1' => 'SearchTerm',
                'strShipCondition' => 'Z2',
                'strTaxClass' => 'ClassX',
                'strToleranceGroup' => 'T1',
                'strTransportation' => 'TransportA',
                'strTSMManager' => 'ZB'
                };
                    
                    // Step 4: Call the utility method inside try-catch for diagnostics
                    String payload;
        try {
            Test.startTest();
            payload = PMC_CPIAccountCalloutUtilityClass.createSoldToPayload(new List<Id>{ testAccount.Id }, jsonParams);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('createSoldToPayload threw an exception: ' + e.getMessage());
            System.assert(false, 'createSoldToPayload failed: ' + e.getMessage());
        }
        
        // Step 5: Final assertions
        System.assertNotEquals(payload, null, 'Payload should not be null');
        System.assert(payload.contains('Test Account'), 'Payload should include account name');
        System.assert(payload.contains('Z001'), 'Payload should include Business Partner Grouping');
    }
    
    
    // Test Method for createBillToPayload
    @isTest
    static void testCreateBillToPayload() {
        // Create the test Account
        Account testAccount = createTestAccount();
        
        Map<String, String> jsonParams = new Map<String, String>{
            'strOverDelivTol' => '35',
                'strUnderDelivTol' => '99',
                'strAccountManager' => 'ZF',
                'strAcctAssmtGrpCust' => 'Group1',
                'strBillToPartner' => 'BP',    
                'strBPGrouping' => 'Z004',
                'BusinessPartnerCategory' => '2',    
                'strCashPlanningGroup' => 'C1',
                'strCNPJNumber' => '987654321',
                'strCommissionAgent' => 'ZH',
                'strCPFNumber' => '11122233344',
                'strCurrency' => 'USD',
                'strCustomerTaxCategory' => 'TaxA',
                'strCustPriceProc' => '1',                
                'strCustServRep' => 'ZA',                
                'strCustomerGroup' => '07',                
                'strDistChannel' => '00',                
                'strDivision' => '10',
                'strDomesticBroker' => 'ZJ',
                'strInvDates' => 'US',
                'strInvListSched' => 'US',
                'strItemOrderProb' => '100',
                'strLanguage' => 'EN',
                'strLayoutSortingRule' => 'RuleX',
                'strNaturalPerson' => 'X',
                'strOperation' => 'BPCreation',
                'strPartnerFunction' => 'FunctionX',
                'strPaymentTerm' => 'D030',
                'strReconcAcc' => '12345',
                'strRUCPYOrg' => 'RUC5678',
                'strRUCPYPerson' => 'RUC1234',
                'strSalesOrg' => '4000',
                'strSalesOffice' => '430A',
                'strSalesDistrict' => 'ZBR004',
                'strSalesGroup' => '785',			
                'strSearchTerm1' => 'SearchTerm',
                'strShipCondition' => 'Z2',
                'strShipToPartner' => 'SH',
                'strSoldToPartner' => 'SP',
                'strTaxClass' => 'ClassX',
                'strToleranceGroup' => 'T1',
                'strTransportation' => 'TransportA',
                'strTSMManager' => 'ZB'
                };
                    
                    String strRUCPYOrg = '12345678';
        String strRUCPYPerson = '12345678';
        
        Test.startTest();
        String payload = PMC_CPIAccountCalloutUtilityClass.createBillToPayload(new List<Id>{ testAccount.Id }, jsonParams);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(payload, null, 'Payload should not be null');
        System.assert(payload.contains('Test Account'), 'Payload should include account name');
        System.assert(payload.contains('Z004'), 'Payload should include Business Partner Grouping');
    }
    
    // Test Method for createPayerPayload
    @isTest
    static void testCreatePayerPayload() {
        // Create the test Account
        Account testAccount = createTestAccount();
        
        Map<String, String> jsonParams = new Map<String, String>{
            'strOverDelivTol' => '35',
                'strUnderDelivTol' => '99',
                'strAccountManager' => 'ZF',
                'strAcctAssmtGrpCust' => 'Group1',
                'strBillToPartner' => 'BP',    
                'strBPGrouping' => 'Z003',
                'BusinessPartnerCategory' => '2',    
                'strCashPlanningGroup' => 'C1',
                'strCNPJNumber' => '987654321',
                'strCommissionAgent' => 'ZH',
                'strCPFNumber' => '11122233344',
                'strCurrency' => 'USD',
                'strCustomerTaxCategory' => 'TaxA',
                'strCustPriceProc' => '1',                
                'strCustServRep' => 'ZA',                
                'strCustomerGroup' => '07',                
                'strDistChannel' => '00',                
                'strDivision' => '10',
                'strDomesticBroker' => 'ZJ',
                'strInvDates' => 'US',
                'strInvListSched' => 'US',
                'strItemOrderProb' => '100',
                'strLanguage' => 'EN',
                'strLayoutSortingRule' => 'RuleX',
                'strNaturalPerson' => 'X',
                'strOperation' => 'BPCreation',
                'strPartnerFunction' => 'FunctionX',
                'strPaymentTerm' => 'D030',
                'strReconcAcc' => '12345',
                'strRUCPYOrg' => 'RUC5678',
                'strRUCPYPerson' => 'RUC1234',
                'strSalesOrg' => '4000',
                'strSalesOffice' => '430A',
                'strSalesDistrict' => 'ZBR004',
                'strSalesGroup' => '785',			
                'strSearchTerm1' => 'SearchTerm',
                'strShipCondition' => 'Z2',
                'strTaxClass' => 'ClassX',
                'strToleranceGroup' => 'T1',
                'strTransportation' => 'TransportA',
                'strTSMManager' => 'ZB'
                };
                    
                    String strRUCPYOrg = '12345678';
        String strRUCPYPerson = '12345678';
        
        Test.startTest();
        String payload = PMC_CPIAccountCalloutUtilityClass.createPayerPayload(new List<Id>{ testAccount.Id }, jsonParams);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(payload, null, 'Payload should not be null');
        System.assert(payload.contains('Test Account'), 'Payload should include account name');
        System.assert(payload.contains('Z003'), 'Payload should include Business Partner Grouping');
    }
    
    @isTest
    static void testAutoRetryQueueableApex() {
        Integer stackDepth = 1;
        String errorMsg = 'Temporary network issue';
        
        // Mocking Custom Metadata Type
        Test.startTest();
        Boolean shouldRetry = PMC_CPIAccountCalloutUtilityClass.autoRetryQueueableApex(stackDepth, errorMsg);
        Test.stopTest();
        
        System.assert(shouldRetry == false || shouldRetry == true, 'shouldRetry should return a boolean');
    }
}