/**
* @description : Test class for PMC_DH_UpdateEntitlementPolicyBatch
* @author      : Lohitha Sai
* @Created on   09/12/2023
**/
@isTest
public with sharing class PMC_DH_UpdateEntitlementPolicyBatchTest {
    /**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* @param: none 
* @return: void
* @author Lohitha
*/
    @testSetup  static void setup()
    {
        User userAdmin=PMC_DH_TestDataFactoryClass.createAdminUser();
        System.runAs(userAdmin){
            Account acc2=PMC_DH_TestDataFactoryClass.createParentTestAccount();
            PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc2);
            Test.startTest();
            
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            insert prod;
            Product2 prod2 = PMC_DH_TestDataFactoryClass.createProduct();
            prod2.Name='Test Product1';
            prod2.ProductCode='AB-45678';
            prod2.StockKeepingUnit='45678';
            insert prod2; 
            Test.stopTest();
            BuyerGroup bGrp = PMC_DH_TestDataFactoryClass.createBuyerGroup();
            BuyerAccount buyerAccount = new BuyerAccount();
            buyerAccount.BuyerId = acc2.Id;
            buyerAccount.Name = 'Test Buyer Account (BA-AJ)';
            buyerAccount.IsActive = true;
            insert buyerAccount;
            PMC_DH_TestDataFactoryClass.createBuyerGroupMember(buyerAccount.BuyerId,bGrp.Id);
            CommerceEntitlementPolicy objPolicy = PMC_DH_TestDataFactoryClass.createEntitlementPolicy();
            PMC_DH_TestDataFactoryClass.createCommerceEntitlementBuyerGroup(objPolicy.Id,bGrp.Id);
            PMC_DH_TestDataFactoryClass.createCommerceEntitlementProduct(objPolicy.Id,prod.Id);
            PMC_DH_TestDataFactoryClass.createCommerceEntitlementProduct(objPolicy.Id,prod2.Id);
            PMC_DH_TestDataFactoryClass.createEntitlementRules(acc2.Id,prod.Id);
            PMC_DH_TestDataFactoryClass.createEntitlementRules(acc2.Id,prod2.Id);
            WebStore testWebStore = PMC_DH_TestDataFactoryClass.createTestWebStore();
            testWebStore.Name = 'Mosaic Direct';
            update testWebStore;
        }
    }
    /**
* @description test Method for PMC_DH_UpdateEntitlementPolicyBatch
* @param: none
* @author Lohitha
**/
    @IsTest
    public static void testBatchClass(){
        
       
       
        PMC_DH_UpdateEntitlementPolicyBatch batchJob = new PMC_DH_UpdateEntitlementPolicyBatch();
        Datetime datTSystemTime;
        String strCronExpression;
        String strJobId;
        CronTrigger objCronTrigg;
        datTSystemTime = System.now().addSeconds(10);
        strCronExpression =  datTSystemTime.second() + ' ' + datTSystemTime.minute() + ' ' + datTSystemTime.hour() + ' ' + datTSystemTime.day() + ' ' + datTSystemTime.month() + ' ? ' + datTSystemTime.year();
        // Schedule the test job
        strJobId = System.schedule('Product Entitle Update', strCronExpression, batchJob );
        // Get the information from the CronTrigger API object.
        objCronTrigg = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :strJobId];
        // Verify the CRON expressions are the same.
        System.assertEquals(strCronExpression, objCronTrigg.CronExpression, 'Cron Expressions are matching');
        // Verify the job has not run.
        System.assertEquals(0, objCronTrigg.TimesTriggered, '0 Times triggered');
        
        Test.startTest();
        Database.executeBatch(batchJob);
        Test.stopTest();
    }
        
    @IsTest
    public static void testBatchClass1(){
       
        PMC_DH_UpdateEntitlementPolicyBatch batchJob = new PMC_DH_UpdateEntitlementPolicyBatch();
        PMC_DH_EntitlementRules__c et = [Select id,PMC_DH_Type__c from PMC_DH_EntitlementRules__c where PMC_DH_isActive__c=true LIMIT 1];
        et.PMC_DH_Type__c = 'RESTRICTED';
        update et;
        Datetime datTSystemTime;
        String strCronExpression;
        String strJobId;
        Test.startTest();
        Database.executeBatch(batchJob);
        Test.stopTest();
        CronTrigger objCronTrigg;
        datTSystemTime = System.now().addSeconds(10);
        strCronExpression =  datTSystemTime.second() + ' ' + datTSystemTime.minute() + ' ' + datTSystemTime.hour() + ' ' + datTSystemTime.day() + ' ' + datTSystemTime.month() + ' ? ' + datTSystemTime.year();
        // Schedule the test job
        strJobId = System.schedule('Product Entitle Update', strCronExpression, batchJob );
        // Get the information from the CronTrigger API object.
        objCronTrigg = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :strJobId];
        // Verify the CRON expressions are the same.
        System.assertEquals(strCronExpression, objCronTrigg.CronExpression, 'Cron Expressions are matching');
        // Verify the job has not run.
        System.assertEquals(0, objCronTrigg.TimesTriggered, '0 Times triggered');
        //system.assertEquals('', ,'');
    }
    
    @IsTest
    public static void testBatchClassException(){
        try{
            PMC_DH_UpdateEntitlementBatchHelper.executeHelper(NULL);
        }Catch(Exception ex){
            System.assertEquals(ex!=NULL, true, 'condtions are not satisfied');
        }
    }
}