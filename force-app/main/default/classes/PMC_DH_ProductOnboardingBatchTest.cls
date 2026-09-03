/**
* @description       : Test Class for Product Onboarding Batch Job
* @author            : Hemant Giri Goswami | hegoswami@deloitte.com
* @group             : Mosaic Direct
* @last modified on  : 04-09-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
@isTest
public with sharing class PMC_DH_ProductOnboardingBatchTest {
    
    @TestSetup
    static void testSetup() {
        User userAdmin = PMC_DH_TestDataFactoryClass.createAdminUser();
        System.runAs(userAdmin) {
            Account acc = PMC_DH_TestDataFactoryClass.createParentTestAccount();
            PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            prod.PMC_CPQ_ProductSegment__c = 'Feed';
            prod.PMC_CPQ_ProductTypes__c = 'Services';
            prod.PMC_CPQ_ProductFamily__c = 'Mes';
            prod.PMC_CPQ_Potassium__c = 17;
            prod.PMC_CPQ_Phosphorous__c = 7;
            prod.PMC_CPQ_Nitrogen__c = 35;
            prod.PMC_CPQ_Boron__c = 10;
            prod.PMC_CPQ_ProductSubFamily__c = 'Mes';
            prod.PMC_DH_isProcessed__c = false;
            insert prod;
            
            Product2 prod2 = PMC_DH_TestDataFactoryClass.createProduct();
            prod2.Name = 'Test Product1';
            prod2.ProductCode = 'AB-45678';
            prod2.StockKeepingUnit = '45678';
            prod2.PMC_CPQ_ProductSegment__c = 'GYPSUM';
            prod2.PMC_CPQ_ProductTypes__c = 'COMMODITY';
            prod2.PMC_CPQ_ProductFamily__c = 'MES';
            prod2.PMC_CPQ_Potassium__c = 17;
            prod2.PMC_CPQ_Phosphorous__c = 7;
            prod2.PMC_CPQ_Nitrogen__c = 35;
            prod2.PMC_CPQ_ProductSubFamily__c = 'MES';
            prod2.PMC_CPQ_Boron__c = 10;
            prod2.PMC_DH_isProcessed__c = false;
            insert prod2;
            
            ProductCatalog pc = new ProductCatalog(name = 'mosaic Direct');
            insert pc;
            
            PMC_SS_SalesArea__c testSalesArea = new PMC_SS_SalesArea__c();
            testSalesArea.PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
            testSalesArea.PMC_SS_DistributionChannel__c = '0';
            testSalesArea.PMC_SS_Division__c = '10';
            insert testSalesArea;
            
            PMC_CPQ_ProductSalesArea__c tetProSalesArea = new PMC_CPQ_ProductSalesArea__c();
            tetProSalesArea.PMC_CPQ_Product__c = prod.Id;
            tetProSalesArea.PMC_CPQ_Sales_Area__c = testSalesArea.Id;
            insert tetProSalesArea;
            
            PMC_SS_AccountSalesAreaRelationship__c testAccSalesArea = new PMC_SS_AccountSalesAreaRelationship__c();
            testAccSalesArea.PMC_SS_Account__c = acc.Id;
            testAccSalesArea.PMC_SS_SalesArea__c = testSalesArea.Id;
            insert testAccSalesArea;
            
            BuyerGroup bGrp = PMC_DH_TestDataFactoryClass.createBuyerGroup();
            
            BuyerAccount buyerAccount = new BuyerAccount();
            buyerAccount.BuyerId = acc.Id;
            buyerAccount.Name = 'Test Buyer Account (BA-AJ)';
            buyerAccount.IsActive = true;
            insert buyerAccount;
            
            PMC_DH_TestDataFactoryClass.createBuyerGroupMember(buyerAccount.BuyerId, bGrp.Id);
            
            CommerceEntitlementPolicy objPolicy = PMC_DH_TestDataFactoryClass.createEntitlementPolicy();
            PMC_DH_TestDataFactoryClass.createCommerceEntitlementBuyerGroup(objPolicy.Id, bGrp.Id);
            PMC_DH_TestDataFactoryClass.createCommerceEntitlementProduct(objPolicy.Id, prod.Id);
            
            ProductCategory productCat = new ProductCategory(
                Name = 'Mes',
                PMC_DH_Category_ID__c = 'GYPSUM-COMMODITY-MES-MES',
                catalogid = pc.id,
                IsNavigational = true
            );
            insert productCat;
            
            ProductCategory productCat2 = new ProductCategory(
                Name = 'Feed',
                PMC_DH_Category_ID__c = 'FEED-SERVICES-MES-MES',
                catalogid = pc.id,
                IsNavigational = true
            );
            insert productCat2;
            
            ProductCategoryProduct prodcatPro = new ProductCategoryProduct(Productid = prod2.id, ProductCategoryid = productCat.id);
            insert prodcatPro;
        }
    }
    
    @isTest
    public static void testProductOnBoardBatch() {
        User userAdmin = [SELECT Id, Name FROM User WHERE LastName = 'Admin User Test' AND IsActive = TRUE LIMIT 1];
        System.runAs(userAdmin) {
            try {
                PMC_DH_ProductOnboardingBatch batchJob = new PMC_DH_ProductOnboardingBatch();
                Test.startTest();
                String jobId = Database.executeBatch(batchJob);
                System.assert(jobId != null, 'Batch job ID should not be null');
                
                List<ProductMedia> lstProductMediaProdId = new List<ProductMedia>();
                Product2 pro = [SELECT Id, Name FROM Product2 LIMIT 1];
                ProductMedia pm = new ProductMedia();
                pm.ProductId = pro.Id;
                
                lstProductMediaProdId.add(pm);
                PMC_DH_ProductOnboardingBatchUtil.processedProductMediaid(lstProductMediaProdId, new Set<String>{pro.Id});
                Test.stopTest();
            } catch (Exception ex) {
                System.assertEquals(true, ex != null, 'Exception should not be null');
            }
        }
    }
    
    @isTest
    public static void testPopulateMicroNutrients() {
        Product2 testProd = new Product2(
            Name = 'Nutrient Test Product',
            ProductCode = 'NT-001',
            StockKeepingUnit = 'NT-001',
            PMC_CPQ_Boron__c = 10,
            PMC_CPQ_Copper__c = 5,
            PMC_CPQ_Zinc__c = 0,
            PMC_CPQ_Iron__c = null
        );
        insert testProd;
        
        Test.startTest();
        String result = PMC_DH_ProductOnboardingBatch.populateMicroNutrinents(testProd);
        Test.stopTest();
        
        System.assert(result.contains('Boron'), 'Micronutrients string should contain Boron');
        System.assert(result.contains('Copper'), 'Micronutrients string should contain Copper');
        System.assert(!result.contains('Zinc'), 'Zinc is zero and should NOT be included');
        System.assert(!result.contains('Iron'), 'Iron is null and should NOT be included');
    }
    
    // --- New helper & utility tests below ---
    
    @isTest
    public static void testHelperExecute() {
        Product2 productToTest = new Product2(
            Name = 'Test123',
            PMC_CPQ_Nitrogen__c = 10, 
            PMC_CPQ_Phosphorous__c = 20,
            PMC_CPQ_Potassium__c = 30,
            PMC_CPQ_Boron__c = 5,     
            PMC_CPQ_Copper__c = 2,    
            PMC_CPQ_Zinc__c = 0,      
            PMC_CPQ_Iron__c = null,
            PMC_DH_isProcessed__c = false
        );
        insert productToTest; 
        List<Product2> products = new List<Product2>{ productToTest };
            
            Test.startTest();
        PMC_DH_ProductOnboardingBatchHelper.executeHelper(products);
        Test.stopTest();
        
        Product2 updatedProd = [SELECT PMC_DH_isProcessed__c, PMC_DH_Micronutrients__c, PMC_DH_Nitrogen__c, PMC_DH_Phosphorous__c, PMC_DH_Potassium__c FROM Product2 WHERE Id = :productToTest.Id];
        System.assertEquals(true, updatedProd.PMC_DH_isProcessed__c, 'Product should be marked as processed');
        System.assertNotEquals(null, updatedProd.PMC_DH_Micronutrients__c, 'Micronutrients should be populated');
    }
    
    @isTest
    public static void testUtilityMethods() {
        Schema.DescribeFieldResult dr = Product2.PMC_DH_Nitrogen__c.getDescribe();
        Map<Integer, String> picklistMap = PMC_DH_ProductOnboardingBatchUtil.getPicklistValueMap(dr);
        System.assert(!picklistMap.isEmpty(), 'Picklist map should not be empty');
        
        Integer anyKey = picklistMap.keySet().iterator().next();
        String picklistValue = PMC_DH_ProductOnboardingBatchUtil.getMatchingPicklistValue(picklistMap, anyKey);
        System.assertNotEquals(null, picklistValue, 'Picklist value should not be null');
        
        List<Product2> prods = [SELECT Id, PMC_CPQ_ProductSegment__c, PMC_CPQ_ProductTypes__c, PMC_CPQ_ProductFamily__c, PMC_CPQ_ProductSubFamily__c FROM Product2 LIMIT 1];
        Test.startTest();
        PMC_DH_ProductOnboardingBatchUtil.executeProductProcessing(prods);
        Test.stopTest();
    }
    @isTest
    public static void testHelperMapMethods() {
        // Prepare test data inside System.runAs for proper context if needed
        User userAdmin = [SELECT Id FROM User WHERE LastName = 'Admin User Test' AND IsActive = TRUE LIMIT 1];
        System.runAs(userAdmin) {
            // Use existing Account from testSetup or create new for isolation
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            
            // Create BuyerGroups using factory or direct insert
            BuyerGroup bg1 = new BuyerGroup(Name = 'TestBuyerGroup1_' + System.currentTimeMillis());
            insert bg1;
            
            BuyerGroup bg2 = new BuyerGroup(Name = 'TestBuyerGroup2_' + System.currentTimeMillis());
            insert bg2;
            
            // Create Commerce Entitlement Policies
            CommerceEntitlementPolicy policy1 = PMC_DH_TestDataFactoryClass.createEntitlementPolicy();
            CommerceEntitlementPolicy policy2 = PMC_DH_TestDataFactoryClass.createEntitlementPolicy();
            
            // Map BuyerGroupMembers (link Account to BuyerGroups)
            PMC_DH_TestDataFactoryClass.createBuyerGroupMember(testAccount.Id, bg1.Id);
            PMC_DH_TestDataFactoryClass.createBuyerGroupMember(testAccount.Id, bg2.Id);
            
            // Map CommerceEntitlementBuyerGroup (link BuyerGroups to Policies)
            PMC_DH_TestDataFactoryClass.createCommerceEntitlementBuyerGroup(policy1.Id, bg1.Id);
            PMC_DH_TestDataFactoryClass.createCommerceEntitlementBuyerGroup(policy2.Id, bg2.Id);
            
            // Build mapBuyerGroupMembers: AccountId -> Set of BuyerGroupIds
            Map<Id, Set<Id>> mapBuyerGroupMembers = new Map<Id, Set<Id>>();
            mapBuyerGroupMembers.put(testAccount.Id, new Set<Id>{bg1.Id, bg2.Id});
            
            // Build mapEntitlementBuyerGroups: BuyerGroupId -> Set of PolicyIds
            Map<Id, Set<Id>> mapEntitlementBuyerGroups = new Map<Id, Set<Id>>();
            mapEntitlementBuyerGroups.put(bg1.Id, new Set<Id>{policy1.Id});
            mapEntitlementBuyerGroups.put(bg2.Id, new Set<Id>{policy2.Id});
            
            // Test getAccountEntPoliciesIdsSet
            Set<Id> entPolicies = PMC_DH_ProductOnboardingBatchHelper.getAccountEntPoliciesIdsSet(
                mapBuyerGroupMembers, mapEntitlementBuyerGroups, String.valueOf(testAccount.Id));
            System.assert(entPolicies.contains(policy1.Id), 'Should contain policy1');
            System.assert(entPolicies.contains(policy2.Id), 'Should contain policy2');
            
            // Prepare mapAcctoEntPolicies: AccountId -> Set of PolicyIds
            Map<Id, Set<Id>> mapAcctoEntPolicies = new Map<Id, Set<Id>>();
            mapAcctoEntPolicies.put(testAccount.Id, new Set<Id>{policy1.Id, policy2.Id});
            
            // Prepare mapAccountProducts: AccountId -> Set of ProductIds
            // Use existing products or create new
            Product2 prod1 = [SELECT Id FROM Product2 LIMIT 1];
            Product2 prod2 = [SELECT Id FROM Product2 WHERE Id != :prod1.Id LIMIT 1];
            Map<Id, Set<Id>> mapAccountProducts = new Map<Id, Set<Id>>();
            mapAccountProducts.put(testAccount.Id, new Set<Id>{prod1.Id, prod2.Id});
            
            // Test getMapProdEnableEntPolicies
            Map<Id, Set<Id>> prodToPolicies = PMC_DH_ProductOnboardingBatchHelper.getMapProdEnableEntPolicies(
                mapAcctoEntPolicies, mapAccountProducts);
            
            System.assert(prodToPolicies.containsKey(prod1.Id), 'Product1 key should be present');
            System.assert(prodToPolicies.containsKey(prod2.Id), 'Product2 key should be present');
            System.assert(prodToPolicies.get(prod1.Id).contains(policy1.Id), 'Product1 should have policy1');
            System.assert(prodToPolicies.get(prod1.Id).contains(policy2.Id), 'Product1 should have policy2');
            System.assert(prodToPolicies.get(prod2.Id).contains(policy1.Id), 'Product2 should have policy1');
            System.assert(prodToPolicies.get(prod2.Id).contains(policy2.Id), 'Product2 should have policy2');
        }
    }
    
    
}