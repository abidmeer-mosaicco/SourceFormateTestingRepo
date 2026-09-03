@isTest(seeAllData=false)
public class MosaicDirectContractSummaryCtrlTest {
    @TestSetup
    private static void setup() {
        List<Order> lstOrders = PMC_CPQ_OrderIntegrationTest.createOrders(1);
        if (!lstOrders.isEmpty() && lstOrders[0].Id == null) {
            insert lstOrders;
        }
       
        User userAdmin;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            userAdmin = PMC_DH_TestDataFactoryClass.createAdminUser();
        }
        
        System.runAs(userAdmin){ 
            List<Opportunity> lstOpty = PMC_TestUtilityClass.createOpportunity(1,'Master');
            List<Account> lstAcct = [SELECT Id, PMC_SS_AccountExternalID__c, PMC_SS_SAPCustomerNumber__c FROM Account WHERE Id = :lstOpty[0].AccountId];
            lstAcct[0].PMC_SS_AccountExternalID__c = '2378651345';
            lstAcct[0].PMC_SS_SAPCustomerNumber__c = '2378651345';
            update lstAcct;

            Account accWithBilling = new Account();
            accWithBilling.Name = 'Teste';
            accWithBilling.BillingCity = 'Teste';
            accWithBilling.BillingState = 'Espírito Santo';
            accWithBilling.BillingStreet = 'Teste';
            accWithBilling.BillingPostalCode = '29161000';
            accWithBilling.BillingCountry = 'Brazil';
            insert accWithBilling;

            List<Contact> lstCont = PMC_TestUtilityClass.createContact(1,'Master');
            List<Product2> lstProduct = PMC_TestUtilityClass.createProduct(1,'PMC_CPQ_NA');

            if (!lstProduct.isEmpty() && lstProduct[0].Id == null) {insert lstProduct;}
            lstProduct[0].PMC_CPQ_SAPProductCode__c = '';
            update lstProduct;

            List<SBQQ__Quote__c> lstQuotes = PMC_TestUtilityClass.createCPQQuotes(1, lstOpty , lstCont);

            SBQQ__QuoteLine__c objQL1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = lstQuotes.get(0).Id,
                SBQQ__Product__c = lstProduct.get(0).Id,
                PMC_CPQ_ShipTo__c = accWithBilling.Id,
                PMC_CPQ_QuoteRecordType__c = 'Domestic NA',
                PMC_CPQ_ContractType__c = 'FPD'
            );
            insert objQL1;

            if (lstOrders[0].Id == null) insert lstOrders;
            lstOrders[0].PMC_CPQ_SAPOrderNumber__c = '30008758';
            lstOrders[0].OwnerId = userAdmin.Id;
            update lstOrders;

            List<Contract> lstContract = PMC_TestUtilityClass.createContract(lstAcct, lstOpty);
            lstContract[0].SBQQ__Quote__c = lstQuotes.get(0).Id;
            lstContract[0].PMC_CPQ_LatestQuote__c = lstQuotes.get(0).Id;
            lstContract[0].ContractNumber__c = lstQuotes.get(0).Id;
            update lstContract;

            SBQQ__Subscription__c objSub = new SBQQ__Subscription__c();
            objSub.SBQQ__Contract__c = lstContract[0].Id;
            objSub.SBQQ__Account__c = lstAcct[0].Id;
            objSub.SBQQ__Quantity__c = 1;
            objSub.SBQQ__QuoteLine__c = objQL1.Id;
            insert objSub;

            OrderItem objOP = new OrderItem(
                OrderId = lstOrders[0].Id, 
                SBQQ__QuoteLine__c = objQL1.Id,
                SBQQ__Subscription__c = objSub.Id, 
                Product2Id = lstProduct.get(0).Id, 
                Quantity = 1, 
                ListPrice = 100, 
                PMC_CPQ_ListPrice__c = 100, 
                UnitPrice = 100,
                PMC_CPQ_ContractType__c = 'FPD', 
                PMC_CPQ_ShipTo__c = lstOpty.get(0).AccountId
            );
            insert objOP;
        }

        List<String> lstProfileNames = new List<String>{ 'System Administrator', 'Sales User' };
            List<String> lstPermissionSetGroupNames = new List<String>{
                'PMC_Administrator_Permission_Set_Group',
                    'PMC_SLS_Permission_Set_Group'
                    };
                        
                        Map<String, Id> mapOfProfiles      = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String, PermissionSetGroup> psg = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionSetGroupNames);
        
        Integer i = 0;
        List<User> users = PMC_TestUtilityClass.createUser(2);
        for (User u : users) {
            if (i == 0) {
                u.LastName = 'Admin User Test';
                u.ProfileId = mapOfProfiles.get('System Administrator');
                u.FederationIdentifier = u.Username + 'Admin';
            } else {
                u.LastName = 'Sales User Test';
                u.ProfileId = mapOfProfiles.get('Sales User');
                u.FederationIdentifier = u.Username + 'Sales';
            }
            u.IsActive = true;
            u.MobilePhone = '1234567890';
            u.UserPermissionsKnowledgeUser = true;
            u.LanguageLocaleKey = 'en_US';
            u.PMC_CPQ_SalesRegion__c = 'North America';
            u.PMC_CPQ_PrimaryBusinessType__c = 'Feed';
            i++;
        }

        System.runAs(new User(Id = UserInfo.getUserId())) {
            try {
                toggleBypass(true);
                insert users;
            } finally {
                toggleBypass(false);
            }
        }

        User sysAdmin  = users[0];
        User salesUser = users[1];
        
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(
            new List<User>{ sysAdmin },
            psg.get('PMC_Administrator_Permission_Set_Group')
        );
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(
            new List<User>{ salesUser },
            psg.get('PMC_SLS_Permission_Set_Group')
        );
        
        System.runAs(sysAdmin) {
            // Try the factory, then hard fallback if needed
            List<PMC_SS_SalesArea__c> created = new List<PMC_SS_SalesArea__c>();
            try {
                created = PMC_TestUtilityClass.createSalesArea(1, 'Master');
            } catch (Exception ignore) {}
            if (created.isEmpty()) {
                PMC_SS_SalesArea__c sa = new PMC_SS_SalesArea__c();
                // Use values you know are valid in your org
                sa.PMC_SS_SalesOrganization__c    = 'Mosaic Global Sales';
                sa.PMC_CPQ_SAPSalesOrganization__c= '10020010';
                sa.PMC_SS_DistributionChannel__c  = 'Common';
                sa.PMC_SS_Division__c             = 'Domestic';
                insert sa;
                created.add(sa);
            } else {
                created[0].PMC_SS_SalesOrganization__c     = 'Mosaic Global Sales';
                created[0].PMC_CPQ_SAPSalesOrganization__c = '10020010';
                created[0].PMC_SS_DistributionChannel__c   = 'Common';
                created[0].PMC_SS_Division__c              = 'Domestic';
                update created;
            }
        }
    }

    @IsTest
    static void testGetContractItems() {
        Contract c = [
            SELECT Id, SBQQ__Quote__c, PMC_CPQ_LatestQuote__c
            FROM Contract
            LIMIT 1
        ];
        System.assertNotEquals(null, c.SBQQ__Quote__c, 'SBQQ__Quote__c should not be blank');

        Test.startTest();
        List<MosaicDirectContractSummaryCtrl.ContractItemDTO> results =
            MosaicDirectContractSummaryCtrl.getContractItems(c.SBQQ__Quote__c);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Result list should not be null');
        System.assertNotEquals(0, results.size(), 'Expected at least one ContractItemDTO returned');

        MosaicDirectContractSummaryCtrl.ContractItemDTO dto = results[0];
        System.assertNotEquals(null, dto.subscriptionId, 'subscriptionId should not be null');
        System.assertNotEquals(null, dto.contractId, 'contractId should not be null');
        System.assertNotEquals(null, dto.quoteLineId, 'quoteLineId should not be null');
    }

    @IsTest
    static void testGetContractItems_blankParam_returnsEmpty() {
        Test.startTest();
        List<MosaicDirectContractSummaryCtrl.ContractItemDTO> results =
            MosaicDirectContractSummaryCtrl.getContractItems('');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Result should not be null for blank input');
        System.assertEquals(0, results.size(), 'Should return empty list for blank quoteName');
    }
    
    @IsTest
    static void test_getShipToOptions_blankId() {
        Test.startTest();
        List<MosaicDirectContractSummaryCtrl.ShipToOption> results =
            MosaicDirectContractSummaryCtrl.getShipToOptions('');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for blank ID');
    }

    @IsTest
    static void test_getShipToOptions_nullId() {
        Test.startTest();
        List<MosaicDirectContractSummaryCtrl.ShipToOption> results =
            MosaicDirectContractSummaryCtrl.getShipToOptions(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for null ID');
    }
    
    @IsTest
    static void test_getShipToOptions_validData() {
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
            PMC_SS_Segmentation__c = '09',
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

        PMC_SS_AccountPartnerRelationships__c partnerRel = new PMC_SS_AccountPartnerRelationships__c(PMC_SS_Account__c = testSoldTo.Id);
		partnerRel.Name = 'Test';
		partnerRel.PMC_SS_Account__c = testSoldTo.Id;
		partnerRel.PMC_SS_RelatedAccount__c = testSoldTo.Id;
		partnerRel.PMC_SS_Type__c = 'Ship-to';
		insert partnerRel;
        SBQQ__Quote__c quote;
        try {
            toggleBypass(true);  
            quote = new SBQQ__Quote__c(
                PMC_CPQ_SoldToShipToJunction__c = partnerRel.Id,
                SBQQ__Account__c = testSoldTo.Id
            );
            insert quote;
        } finally {
            toggleBypass(false);
        }

        Test.startTest();
        List<MosaicDirectContractSummaryCtrl.ShipToOption> results =
            MosaicDirectContractSummaryCtrl.getShipToOptions(quote.Id);
        Test.stopTest();

        System.assert(results.size() > 0, 'Expected at least one ShipToOption returned');
        System.assertNotEquals(null, results[0].label, 'Label should not be null');
    }

    @IsTest
    static void test_ShipToOption_constructor() {
        MosaicDirectContractSummaryCtrl.ShipToOption opt =
            new MosaicDirectContractSummaryCtrl.ShipToOption('Label Example', 'Value123');

        System.assertEquals('Label Example', opt.label, 'Label should match constructor input');
        System.assertEquals('Value123', opt.value, 'Value should match constructor input');
    }

    private static void toggleBypass(Boolean enable) {
        try {
            PMC_ProcessSwitches__c s = PMC_ProcessSwitches__c.getOrgDefaults();
            if (s == null) s = new PMC_ProcessSwitches__c();
            try { s.put('PMC_BypassValidationRule__c', enable); } catch (Exception ignore) {}
            try { s.put('PMC_Bypass_Flows__c',         enable); } catch (Exception ignore) {}
            try { s.put('PMC_BypassFlow__c',           enable) ;} catch (Exception ignore) {}
            try { s.put('PMC_BypassAutomations__c',    enable); } catch (Exception ignore) {}
            try { s.put('PMC_Disable_Quote_Flows__c',  enable); } catch (Exception ignore) {}
            upsert s;
        } catch (Exception ignoreOuter) {}
    }
}