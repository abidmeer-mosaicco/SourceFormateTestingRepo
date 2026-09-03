/**
 * @description This test class will be used to cover all the methods of PMC_CPQ_QuoteTriggerHelper.
 * @author Raphael Soares
 * @storynumber GCPM-977
 */
@isTest(seeAllData=false)
public with sharing class PMC_CPQ_QuoteTriggerHelperTest {
    /**
     * @description This Method will be used to setup the data for the test class execution.
     */
    @testSetup
    private static void setup() {
        // Create test account
        Account testAccount = PMC_DH_TestDataFactoryClass.createTestAccount();

        // Create test contact
        Contact testContact = PMC_DH_TestDataFactoryClass.createTestContact(testAccount.Id);

        // Create test opportunity
        Opportunity testOpp = PMC_DH_TestDataFactoryClass.createOpportunity(testAccount);
        testOpp.CurrencyIsoCode = 'USD';
        update testOpp;

        // Create test quote
        SBQQ__Quote__c testQuote = PMC_DH_TestDataFactoryClass.createQuote(testAccount, testContact.Id, testOpp);
        testQuote.SBQQ__Status__c = 'Draft';
        update testQuote;

        // Create test product
        Product2 testProduct = PMC_DH_TestDataFactoryClass.createProduct();
        insert testProduct;

        // Create test quote line
        SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote, testProduct);
    }

    /**
     * @description Test method for deleteZeroQuantityLinesAfterApproval with empty set
     */
    @isTest
    private static void testDeleteZeroQuantityLinesAfterApprovalEmptySet() {
        Test.startTest();
        PMC_CPQ_QuoteTriggerHelper.deleteZeroQuantityLinesAfterApproval(new Set<Id>());
        Test.stopTest();

        // Verify no lines were deleted
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id FROM SBQQ__QuoteLine__c];
        System.assertEquals(1, quoteLines.size(), 'No quote lines should be deleted for empty set');
    }

    /**
     * @description Test method for deleteZeroQuantityLinesAfterApproval with approved quotes
     */
    @isTest
    private static void testDeleteZeroQuantityLinesAfterApproval() {
        // Create additional quote lines with zero/null quantity
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c>();

        // Zero quantity line
        SBQQ__QuoteLine__c zeroQtyLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 0
        );
        testQuoteLines.add(zeroQtyLine);

        // Null quantity line
        SBQQ__QuoteLine__c nullQtyLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = null
        );
        testQuoteLines.add(nullQtyLine);

        insert testQuoteLines;
        System.assertEquals(
            3,
            [
                    SELECT Id, SBQQ__Quantity__c
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__c = :testQuote.Id
                ]
                .size(),
            'error'
        );

        Test.startTest();
        PMC_CPQ_QuoteTriggerHelper.deleteZeroQuantityLinesAfterApproval(new Set<Id>{ testQuote.Id });
        Test.stopTest();

        List<SBQQ__QuoteLine__c> remainingLines = [
            SELECT Id, SBQQ__Quantity__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :testQuote.Id
        ];

        // Verify only zero/null quantity lines were deleted
        for (SBQQ__QuoteLine__c qLine : remainingLines) {
            System.assertNotEquals(null, qLine.SBQQ__Quantity__c, 'Remaining line should have non-null quantity');
            System.assertNotEquals(0, qLine.SBQQ__Quantity__c, 'Remaining line should have non-zero quantity');
        }
    }

    /**
     * @description Test method for deleteZeroQuantityLinesAfterApproval with no zero quantity lines
     */
    @isTest
    private static void testDeleteZeroQuantityLinesAfterApprovalNoZeroLines() {
        // Delete any zero/null quantity lines first (none should exist in test data)
        List<SBQQ__QuoteLine__c> zeroQuantityLines = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quantity__c = 0 OR SBQQ__Quantity__c = NULL
        ];
        delete zeroQuantityLines;

        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        PMC_CPQ_QuoteTriggerHelper.deleteZeroQuantityLinesAfterApproval(new Set<Id>{ testQuote.Id });
        Test.stopTest();

        // Verify no lines were deleted
        List<SBQQ__QuoteLine__c> remainingLines = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :testQuote.Id
        ];
        System.assertEquals(1, remainingLines.size(), 'No lines should be deleted when no zero quantity lines exist');
    }

    /**
     * @description Test method for validateProductsEntitlementPoliciesAfterAccepted covering all scenarios
     */
    @isTest
    private static void testValidateProductsEntitlementPoliciesAfterAccepted() {
        // Retrieve test data from setup
        SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Account__r.PMC_SS_SAPCustomerNumber__c FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        // Use the existing quote line from setup
        List<SBQQ__QuoteLine__c> existingQuoteLines = [SELECT Id, SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :testQuote.Id];
        System.assertEquals(1, existingQuoteLines.size(), 'One quote line should exist from setup');
        System.assertEquals(testProduct.Id, existingQuoteLines[0].SBQQ__Product__c, 'Quote line should reference the setup product');
        
        // Create CommerceEntitlementPolicy linked to the account's SAP customer number
        CommerceEntitlementPolicy entitlementPolicy = new CommerceEntitlementPolicy(
            Name = 'Test Entitlement Policy',
            PMC_DH_SAPCustomerNumber__c = testQuote.SBQQ__Account__r.PMC_SS_SAPCustomerNumber__c,
            IsActive = true
        );
        insert entitlementPolicy;
        
        // Verify no products are linked to the entitlement policy initially
        List<CommerceEntitlementProduct> initialEntitlements = [
            SELECT ProductId 
            FROM CommerceEntitlementProduct 
            WHERE PolicyId = :entitlementPolicy.Id
        ];
        System.assertEquals(0, initialEntitlements.size(), 'No products should be linked to the entitlement policy initially');
        
        Test.startTest();

        // Test null quote ID scenario
        PMC_CPQ_QuoteTriggerHelper.validateProductsEntitlementPoliciesAfterAccepted(null);

        // Test invalid quote ID scenario
        PMC_CPQ_QuoteTriggerHelper.validateProductsEntitlementPoliciesAfterAccepted('000000000000000000');

        // Test valid quote ID scenario
        PMC_CPQ_QuoteTriggerHelper.validateProductsEntitlementPoliciesAfterAccepted(testQuote.Id);
        
        Test.stopTest();
        
        // Verify if the product from the setup quote line was linked to the entitlement policy
        List<CommerceEntitlementProduct> finalEntitlements = [
            SELECT ProductId 
            FROM CommerceEntitlementProduct 
            WHERE PolicyId = :entitlementPolicy.Id
        ];
        System.assertEquals(1, finalEntitlements.size(), 'One product should be linked to the entitlement policy');
        System.assertEquals(testProduct.Id, finalEntitlements[0].ProductId, 'The product from the setup quote should be linked to the entitlement policy');
    }

    /**
     * @description Test method for deleteZeroQuantityLinesAfterApproval with empty set
     */
    @isTest
    private static void testUpdateQuoteItemsVCO() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        testQuote.PMC_CPQ_VCOQuotation__c = true;
        update testQuote;

        Set<Id> quoteIds = new Set<Id>{ testQuote.Id };
        List<SBQQ__Quote__c> newQuotes = [SELECT Id, PMC_CPQ_VCOQuotation__c FROM SBQQ__Quote__c WHERE Id IN :quoteIds];

        Test.startTest();
        PMC_CPQ_QuoteTriggerHelper.updateQuoteItemsVCO(quoteIds, newQuotes);
        Test.stopTest();

        // Verify lines were updated with new VCO value.
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :testQuote.Id];
        List<SBQQ__QuoteLine__c> vcoQuoteLines = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :testQuote.Id AND PMC_CPQ_VCOQuotation__c = true];
        System.assertEquals(quoteLines.size(), vcoQuoteLines.size(), 'All quote lines should have been updated with new VCO value.');
    }
}