/**
* @description : Test class for PMC_DH_GetPriceQuoteService
* @author      : Humera
* @userStory   : GDASF-6862 
* @last modified by Humera
* @last modified on 08-02-2023
**/
@isTest
public with sharing class PMC_DH_GetPriceQuoteServiceTest {
/**
* @description Method for getting test data from PMC_DH_TestDataFactoryClass
* @param: none
* @return: void
* @author Humera
*/
    @testSetup  static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        
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
            WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
        insert cartObj;
        Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
        insert prod;
        CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
        insert testCartDeliveryGroup;
        CartItem cartItem=PMC_DH_TestDataFactoryClass.buildCartItem(cartObj.id, prod.id,testCartDeliveryGroup.Id);
        cartItem.PMC_DH_Number__c = 1;
        insert cartItem;
        
        Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
        Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
        PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
        PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
        objCartItem.strCartId=cartObj.id;
        objCartItem.strProductId=prod.id;
        objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
        objCartItem.strShipToAccId=shipToAcc.id;
        objCartItem.strShipFromId=prodLocation.id;
        CartItem cartItem1=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem); 
        cartItem1.PMC_DH_Number__c = 2;
        insert cartItem1;
        }
       }
    /**
* @description Test Method for convertPriceInfoToResponseWrapper
* @param: none
* @return: void
* @author Humera
*/  
@isTest
public static void makeCallOutRequestTest()
{
    Test.startTest();
    Boolean exceptionOccurred;
        try{
    User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
    Webcart objWebCart=[SELECT id FROM WebCart WHERE Name='Test Web Cart'];
    List<WebCart> lstCarts=new List<WebCart>{objWebCart};
    system.runAs(user){
       HttpResponse response = PMC_DH_GetPriceQuoteService.makeCallOutRequest(lstCarts);
       system.assert(response.getBody()!=null,'success');
    }
        }
    catch(Exception ex){
            exceptionOccurred=true;
        }
    Test.stopTest();
}
   /*************************************************************************
* @method Name  : getMockResponse 
* @description  : Method to get Response
* @return       : HttpResponse
******************************************************************************/ 

    public static HttpResponse getMockResponse(){
      // Create a fake response
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setBody('{"HeaderSet":{"Header":{"PriceDate":"2023-07-19","Ztransid":"Q-01308","QtValidT":"2023-07-15","ReturnSet":"","ReqDateH":"2023-07-29","PartnerSet":{"Partner":[{"PartnRole":"SH","Ztransid":"Q-01308","PartnNumb":"30000009","ZrefTransid":"?","ItmNumber":"1"},{"PartnRole":"SH","Ztransid":"Q-01308","PartnNumb":"30000009","ZrefTransid":"?","ItmNumber":"2"},{"PartnRole":"SP","Ztransid":"Q-01308","PartnNumb":"30000009","ZrefTransid":"?","ItmNumber":"0"}]},"DistrChan":"00","QtValidF":"2023-07-04","PurchNoC":"","Price_CondSet":[{"Price_Cond":[{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"500.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZLST"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"10.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZF01"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"SKTV"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZLTX"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZITD"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZITE"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZITR"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZITR"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"PCIP"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"50.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZFIT"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZPMN"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZNTB"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"500.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZLST"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"10.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZF01"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"SKTV"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZLTX"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZITD"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZITE"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZITR"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZITR"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"PCIP"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"50.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZFIT"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZPMN"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZNTB"}]}],"Pmnttrms":"0001","ItemSet":{"Item":[{"Ztransid":"Q-01308","CondValue":"0.000","ReqQty":"0000000000001","SalesUnit":"STN","Material":"1000229","Incoterms2":"SAP/Supply chain","Incoterms1":"CFR","TargetQty":"0000000000001","Plant":"1002","PurchNoC":"","TargetQu":"STN","ZrefTransid":"?","ItmNumber":"1","CondType":""},{"Ztransid":"Q-01308","CondValue":"0.000","ReqQty":"0000000000001","SalesUnit":"STN","Material":"1000229","Incoterms2":"SAP/Supply chain","Incoterms1":"CFR","TargetQty":"0000000000001","Plant":"1002","PurchNoC":"","TargetQu":"STN","ZrefTransid":"?","ItmNumber":"2","CondType":""}]},"SalesOrg":"1002","Currency":"USD","Division":"10","ZrefTransid":"?","PurchDate":"2023-07-19","Raw_MaterialSet":{"Raw_Material":{"Ztransid":"","ZrefTransid":""}},"DocType":"ZQP","ShipCond":"Z1","Item_RSet":{"Item_R":[{"TaxAmount":"0.0000","Zpricerefresh":"","HgLvItem":"000000","Ztransid":"Q-01308","NetValue":"0.5100","Material":"1000229","ZrefTransid":"?","ItmNumber":"1","Zprcduedt":"2023-08-08"},{"TaxAmount":"0.0000","Zpricerefresh":"","HgLvItem":"000000","Ztransid":"Q-01308","NetValue":"0.5100","Material":"1000229","ZrefTransid":"?","ItmNumber":"2","Zprcduedt":"2023-08-08"}]}}}}');
    res.setStatusCode(200);
        return res;
    }
     /*************************************************************************
* @method Name  : getMockResponse 
* @description  : Method to get Response
* @return       : HttpResponse
******************************************************************************/ 

    public static HttpResponse getMockResponse2(){
      // Create a fake response
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setBody('{"HeaderSet":{"Header":{"PriceDate":"2023-07-19","Ztransid":"Q-01308","QtValidT":"2023-07-15","ReturnSet":"","ReqDateH":"2023-07-29","PartnerSet":{"Partner":[{"PartnRole":"SH","Ztransid":"Q-01308","PartnNumb":"30000009","ZrefTransid":"?","ItmNumber":"1"},{"PartnRole":"SH","Ztransid":"Q-01308","PartnNumb":"30000009","ZrefTransid":"?","ItmNumber":"2"},{"PartnRole":"SP","Ztransid":"Q-01308","PartnNumb":"30000009","ZrefTransid":"?","ItmNumber":"0"}]},"DistrChan":"00","QtValidF":"2023-07-04","PurchNoC":"","Price_CondSet":[{"Price_Cond":[{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"500.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZLST"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"10.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZF01"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"SKTV"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZLTX"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZITD"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZITE"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZITR"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZITR"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"PCIP"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"50.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZFIT"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZPMN"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"1","CondType":"ZNTB"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"500.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZLST"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"10.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZF01"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"SKTV"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZLTX"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZITD"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZITE"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZITR"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZITR"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"PCIP"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"","CondValue":"50.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZFIT"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZPMN"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01308","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"?","ItmNumber":"2","CondType":"ZNTB"}]}],"Pmnttrms":"0001","ItemSet":{"Item":[{"Ztransid":"Q-01308","CondValue":"0.000","ReqQty":"0000000000001","SalesUnit":"STN","Material":"1000229","Incoterms2":"SAP/Supply chain","Incoterms1":"CFR","TargetQty":"0000000000001","Plant":"1002","PurchNoC":"","TargetQu":"STN","ZrefTransid":"?","ItmNumber":"1","CondType":""},{"Ztransid":"Q-01308","CondValue":"0.000","ReqQty":"0000000000001","SalesUnit":"STN","Material":"1000229","Incoterms2":"SAP/Supply chain","Incoterms1":"CFR","TargetQty":"0000000000001","Plant":"1002","PurchNoC":"","TargetQu":"STN","ZrefTransid":"?","ItmNumber":"2","CondType":""}]},"SalesOrg":"1002","Currency":"USD","Division":"10","ZrefTransid":"?","PurchDate":"2023-07-19","Raw_MaterialSet":{"Raw_Material":{"Ztransid":"","ZrefTransid":""}},"DocType":"ZQP","ShipCond":"Z1","Item_RSet":{"Item_R":[{"TaxAmount":"0.0000","Zpricerefresh":"","HgLvItem":"000000","Ztransid":"Q-01308","NetValue":"0.5100","Material":"1000229","ZrefTransid":"?","ItmNumber":"1","Zprcduedt":"2023-08-08"},{"TaxAmount":"0.0000","Zpricerefresh":"","HgLvItem":"000000","Ztransid":"Q-01308","NetValue":"0.5100","Material":"1000229","ZrefTransid":"?","ItmNumber":"2","Zprcduedt":"2023-08-08"}]}}}}');
    res.setStatusCode(400);
        return res;
    }
    
    
    
}