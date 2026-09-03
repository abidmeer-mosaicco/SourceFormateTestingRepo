@IsTest
public class PMC_DH_ProductManagementClassTest {
    
    @testSetup  static void setup()
    {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Digital Hub Product Merchandiser' LIMIT 1];
        
        User testUser = new User(
                FederationIdentifier = 'emailtesting10101x@gmail.com',
                MobilePhone = '+1 9876543210',
                FirstName = 'DemoUserRequest',
                LastName = 'Bush',
                Email = 'demouser@test.com',
                Username = 'demouser@test.com.testuser',
                //UserRole = role,
                Alias = 'abctest',
                isActive = true,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                ProfileId = profile.Id,
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
        
        User userR=[SELECT id FROM User WHERE Email = 'demouser@test.com' limit 1];
        
          System.runAs(userR)
        {
            Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
            prod.PMC_DH_CropType__c='Cotton';
            insert prod;
        }
    }
    
    @isTest
    public static void testProductData(){
        Product2 objProduct = [SELECT Id, PMC_CPQ_ProductClassification__c, PMC_DH_CropType__c, PMC_CPQ_GranularType__c, PMC_CPQ_BusinessApplication__c,PMC_DH_Micronutrients__c  FROM Product2 LIMIT 1];
        PMC_DH_ProductManagementClass.PMC_DH_ProdcutData objProDataWrapper = new PMC_DH_ProductManagementClass.PMC_DH_ProdcutData();
        objProDataWrapper.strProductId = objProduct.Id;
        objProDataWrapper.strProductClassification = objProduct.PMC_CPQ_ProductClassification__c;
        objProDataWrapper.strCropType = objProduct.PMC_DH_CropType__c ;
        objProDataWrapper.strGranuleType = objProduct.PMC_CPQ_GranularType__c;
        objProDataWrapper.strBusinessApplication = objProduct.PMC_CPQ_BusinessApplication__c;
        objProDataWrapper.strMicronutrient = objProduct.PMC_DH_Micronutrients__c;
        User userR=[SELECT id FROM User WHERE Email = 'demouser@test.com' limit 1];
        
          System.runAs(userR)
        {
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper  result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper ();
            result = PMC_DH_ProductManagementClass.updateProdutDetails(objProDataWrapper);
            System.assertEquals(result.strStatusCode , '000', 'Failure');
            
        }
    }
    
    @isTest
    public static void testProductDataException(){
        Product2 objProduct = [SELECT Id, PMC_CPQ_ProductClassification__c, PMC_DH_CropType__c, PMC_CPQ_GranularType__c, PMC_CPQ_BusinessApplication__c, PMC_DH_Micronutrients__c FROM Product2 LIMIT 1]; 
        PMC_DH_ProductManagementClass.PMC_DH_ProdcutData objProDataWrapper = new PMC_DH_ProductManagementClass.PMC_DH_ProdcutData();
        objProDataWrapper.strProductId = 'test' + objProduct.Id ;
        objProDataWrapper.strProductClassification = objProduct.PMC_CPQ_ProductClassification__c;
        objProDataWrapper.strCropType = objProduct.PMC_DH_CropType__c ;
        objProDataWrapper.strGranuleType = objProduct.PMC_CPQ_GranularType__c;
        objProDataWrapper.strBusinessApplication = objProduct.PMC_CPQ_BusinessApplication__c;
        objProDataWrapper.strMicronutrient = objProduct.PMC_DH_Micronutrients__c;
        User userR=[SELECT id FROM User WHERE Email = 'demouser@test.com' limit 1];
        
          System.runAs(userR)
        {
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper  result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper ();
            result = PMC_DH_ProductManagementClass.updateProdutDetails(objProDataWrapper);
            System.assertEquals(result.strStatusCode , '100', 'Failure');
        }
    }
        
}