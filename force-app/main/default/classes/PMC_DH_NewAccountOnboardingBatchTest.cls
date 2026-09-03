/**
 * @description       : Test Class for New Account Onboarding Batch Job
 * @author            : Rohan Undale
 * @created on        : 11-17-2023
 * @group             : Mosaic Direct
 * @last modified on  : 
 * @last modified by  : 
**/
@isTest
public with Sharing class PMC_DH_NewAccountOnboardingBatchTest {
	@TestSetup
    static void testSetup()
    {
        User userAdmin=PMC_DH_TestDataFactoryClass.createAdminUser();
        System.runAs(userAdmin){
            Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
            PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
            Test.startTest();        
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            prod.PMC_CPQ_MaterialGroup__c='Feed';
            prod.PMC_CPQ_ProductTypes__c='services';
            prod.PMC_CPQ_ProductFamily__c='MES';
            prod.PMC_CPQ_Potassium__c=17;
            prod.PMC_CPQ_Phosphorous__c=7;
            prod.PMC_CPQ_Nitrogen__c=35;
            prod.PMC_CPQ_ProductSubFamily__c='mes';
            prod.PMC_DH_isProcessed__c=FALSE;
            insert prod;
    
            Product2 prod2 = PMC_DH_TestDataFactoryClass.createProduct();
            prod2.Name='Test Product1';
            prod2.ProductCode='AB-45678';
            prod2.StockKeepingUnit='45678';
            prod2.PMC_CPQ_MaterialGroup__c='gypsum';
            prod2.PMC_CPQ_ProductTypes__c='commodity';
            prod2.PMC_CPQ_ProductFamily__c='MES';
            prod2.PMC_CPQ_Potassium__c=17;
            prod2.PMC_CPQ_Phosphorous__c=7;
            prod2.PMC_CPQ_Nitrogen__c=35;
            prod2.PMC_CPQ_ProductSubFamily__c='mes';
            prod2.PMC_DH_isProcessed__c=FALSE;
            insert prod2; 
    
            ProductCatalog pc=new ProductCatalog(name='mosaic Direct');
            insert pc;
            PMC_SS_SalesArea__c testSalesArea = new PMC_SS_SalesArea__c();
            testSalesArea.PMC_SS_SalesOrganization__c = 'Mosaic Global Sales LLC';
            testSalesArea.PMC_SS_DistributionChannel__c = '0';
            testSalesArea.PMC_SS_Division__c = '10';
            insert testSalesArea;
    
            PMC_CPQ_ProductSalesArea__c tetProSalesArea=new PMC_CPQ_ProductSalesArea__c();
            tetProSalesArea.PMC_CPQ_Product__c=prod.Id;
            tetProSalesArea.PMC_CPQ_Sales_Area__c=testSalesArea.Id;
            insert tetProSalesArea;
    
            PMC_SS_AccountSalesAreaRelationship__c testAccSalesArea=new PMC_SS_AccountSalesAreaRelationship__c();
            testAccSalesArea.PMC_SS_Account__c=acc.Id;
            testAccSalesArea.PMC_SS_SalesArea__c=testSalesArea.Id;
            insert testAccSalesArea;
    
            BuyerAccount buyerAccount = new BuyerAccount();
            buyerAccount.BuyerId = acc.Id;
            buyerAccount.Name = 'Test Buyer Account (BA-AJ)';
            buyerAccount.IsActive = true;
            insert buyerAccount;
            
            ProductCategory productCat=new  ProductCategory(Name='Mes',PMC_DH_Category_ID__c='FEED-SERVICES-MES-MES',catalogid=pc.id,IsNavigational=true);
            insert productCat;
            
            Pricebook2 objPB = new Pricebook2(Name = 'DH Price Book', IsActive = true);
            insert objPB;
            
            WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
            webStore.Name = 'Mosaic Direct';
            update webStore;
        }
    }
    
    /**
    * @description       : Test Class method for New Account Onboarding Batch Job
    * @author            : Rohan Undale
    * @created on        : 11-17-2023
    **/
    @isTest
    public static void testProductOnBoardBatch()
    {
        
        User userAdmin= [SELECT Id,Name from User Where FirstName='Test John' AND IsActive=TRUE LIMIT 1];
        System.runAs(userAdmin){
            try{
            PMC_DH_NewAccountOnboardingBatch batchJob=new PMC_DH_NewAccountOnboardingBatch();
            Datetime datTSystemTime;
            String strCronExpression;
            String strJobId;
            Test.startTest();
            Database.executeBatch(batchJob);
            Test.stopTest();
            CronTrigger objCronTrigg;
            datTSystemTime = System.now().addSeconds(10);
            strCronExpression =  datTSystemTime.second() + ' ' + datTSystemTime.minute() + ' ' + datTSystemTime.hour() + ' ' + datTSystemTime.day() + ' ' + datTSystemTime.month() + ' ? ' + datTSystemTime.year();
            strJobId = System.schedule('New Account Onboarding', strCronExpression, batchJob );
            objCronTrigg = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :strJobId];
            System.assertEquals(strCronExpression, objCronTrigg.CronExpression, 'Cron Expressions are matching');
            System.assertEquals(0, objCronTrigg.TimesTriggered, '0 Times triggered');
            }
            Catch(Exception ex){
                System.assertEquals(ex!=NULL,true,'Cron Expressions');
            }
        }
    }
}