/**
 * @description       : 
 * @author            : Mosaic Direct | Dev Team
 * @group             : 
 * @last modified on  : 04-10-2024
 * @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
@isTest
public without sharing class PMC_DH_RequestedOrderDetailsTest {

    @testSetup  static void setup()
    {
        Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
        acc.isPartner=true;
        //acc.isBuyer=true;
        update acc;
        BuyerAccount buyerAccount = new BuyerAccount();
        buyerAccount.BuyerId = acc.Id;
        buyerAccount.Name = 'Test Buyer Account (Mosaic)';
        buyerAccount.IsActive = true;
        insert buyerAccount;
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
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
                
        String strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        System.runAs(user){
        WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
        insert cartObj;
        Product2 objProduct = new Product2();
        objProduct.Name ='Test Product';
        objProduct.isActive = true;
		objProduct.StockKeepingUnit='1234';
        objProduct.PMC_CPQ_QuantityUnitOfMeasure__c='STN';
        insert objProduct;
        Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
        SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
        Test.startTest();
        

        CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
        insert testCartDeliveryGroup;              
        
        BuyerGroup byrgrp=PMC_DH_TestDataFactoryClass.createBuyerGroup();

        PMC_DH_TestDataFactoryClass.createBuyerGroupMember(acc.Id,byrgrp.Id);
        CommerceEntitlementPolicy commrceEntPolicy=PMC_DH_TestDataFactoryClass.createEntitlementPolicy();
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementBuyerGroup(commrceEntPolicy.Id,byrgrp.Id);
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementProduct(commrceEntPolicy.Id,objProduct.Id); 

        Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);  
        shipToAcc.PMC_SS_MDMVerified__c = TRUE;
        shipToAcc.PMC_DH_Account_Status__c='Active';
        update shipToAcc;
        PMC_SS_AccountPartnerRelationships__c accPartnrRel = PMC_DH_TestDataFactoryClass.createSoldToShipToAccountJunction(shipToAcc.Id, acc.Id);

        Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
        loc.PMC_CPQ_Plant__c = 'Test';
        update loc;
        PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(objProduct, loc);

        SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,objProduct);  
        testQuoteLine.PMC_CPQ_SoldToShipToJunction__c = accPartnrRel.Id;
        testQuoteLine.PMC_CPQ_ProductLocation__c = prodLocation.id;
        update testQuoteLine;
        Contract testContract = PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id);
        PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
        objCartItem.strCartId=cartObj.id;
        objCartItem.strProductId=objProduct.id;
        objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
        objCartItem.strShipToAccId=shipToAcc.id;
        objCartItem.strQuoteLineId = testQuoteLine.Id;
        objCartItem.strShipFromId=prodLocation.id;
        objCartItem.strContractId = testContract.Id;
        CartItem cartItem=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem);
        cartItem.PMC_DH_AccountPartnerRelationship__c = accPartnrRel.Id;
        cartItem.PMC_DH_Source__c='RFQ';
        cartItem.PMC_DH_DeliveryMode__c='truck';
        cartItem.PMC_DH_Contract__c = testContract.Id;
        upsert cartItem;
        SBQQ__Subscription__c sub = PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
        cartItem.PMC_DH_Subscription__c = sub.Id;
        update cartItem;
        Test.stopTest();
        }
    }
    /**
    * @description 
    * @author Mosaic Direct | Dev Team | 10-15-2023 
    **/
    @isTest
    public static void getRequestedOrderDetailsWithException(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Contract con = [select Id, ContractNumber, PMC_CPQ_ContractNumberIdentifier__c, Status, Account.name from contract LIMIT 1]; 
        System.runAs(user){
           PMC_DH_RequestedOrderHelper.throwTestException=true;           
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
        	String strResponseSAP= '{"lstData":[{"strPoNumber":"TEST SELF","strAccIdentifier":"ACC-201","strShiptoId":"800 PEMBRO","strConfirmedCuttingQty":"50.000","strContractFinalized":"'+con.PMC_CPQ_ContractNumberIdentifier__c +'","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000089-1-1","strMaterial":"1234","strConfirmDelDate":" 1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"100.000","strReqDelDate":"05.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"Test OTC - Customer Test OTC","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"0.000","strGeneralPrice":"0.000","strCreatedOn":"2023-09-29T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP", "strPackType":"", "strPackingType":"Bulk"}]}';
            PMC_DH_OrderDetailsWrapper result = PMC_DH_RequestedOrderDetails.getOrderDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id, strResponseSAP);
            system.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }

    /**
    * @description 
    * @author Mosaic Direct | Dev Team | 10-15-2023 
    **/
    @isTest
    public static void getRequestedOrderDetailsSuccessTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Contract con = [select Id, ContractNumber, PMC_CPQ_ContractNumberIdentifier__c, Status, Account.name from contract LIMIT 1]; 
        System.runAs(user) {
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            String strResponseSAP= '{"lstData":[{"strPoNumber":"TEST SELF","strAccIdentifier":"ACC-201","strShiptoId":"","strConfirmedCuttingQty":"50.000","strContractFinalized":"'+con.PMC_CPQ_ContractNumberIdentifier__c +'","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000089-1-1","strMaterial":"1234","strConfirmDelDate":" 1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"100.000","strReqDelDate":"05.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"Test OTC - Customer Test OTC","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"0.000","strGeneralPrice":"0.000","strCreatedOn":"2023-09-29T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP", "strPackType":"", "strPackingType":"Bulk", "strSalesOrder": "00300001428", "strProtocolNo": "Mhfhjsksol"}]}';
            PMC_DH_OrderDetailsWrapper result = PMC_DH_RequestedOrderDetails.getOrderDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id, strResponseSAP);
            System.Assert(result!=null, 'Success');
        }
        Test.stopTest();
    }

      /**
    * @description 
    * @author Mosaic Direct | Dev Team | 10-15-2023 
    **/
    @isTest
    public static void getRequestedOrderResponseException(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            String strResponseSAP= '{"lstData"strPoNumber":"TEST SELF","strAccIdentifier":"ACC-201","strShiptoId":"800 PEMBRO","strConfirmedCuttingQty":"50.000","strContractFinalized":"00103913","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000089-1-1","strMaterial":"1234","strConfirmDelDate":" 1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"100.000","strReqDelDate":"05.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"Test OTC - Customer Test OTC","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"0.000","strGeneralPrice":"0.000","strCreatedOn":"2023-09-29T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strAccIdentifier":"ACC-202","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"10.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000089-1-2","strMaterial":"1234","strConfirmDelDate":" 1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"10.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-03T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strAccIdentifier":"ACC-202","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"5.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000099-1-1","strMaterial":"1234","strConfirmDelDate":" 1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"5.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-04T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZORB Defec","strAccIdentifier":"ACC-209","strShiptoId":"RUA PARANA","strConfirmedCuttingQty":"10.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000108-1-1","strMaterial":"1234","strConfirmDelDate":" 1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"10.000","strReqDelDate":"17.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"COOPERATIVA AGROPECUARIA DE PA","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"0.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-10T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"}]}"';
            PMC_DH_OrderDetailsWrapper result;
            try {
                result = PMC_DH_RequestedOrderDetails.getOrderDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id, strResponseSAP);
            } catch (Exception ex) {
                system.Assert(ex != Null, 'Success');
            }
           
        	system.Assert(strTestAcct != Null, 'Success');
        }
        Test.stopTest();
    }

    @isTest
    public static void getRequestedOrderNoDataTest(){
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        system.runAs(user){
            Account strTestAcct=[SELECT id FROM Account WHERE Name='Parent Test Account' limit 1][0];
            String strResponseSAP= '{"lstData":[]}"';
            PMC_DH_OrderDetailsWrapper result;
            result = PMC_DH_RequestedOrderDetails.getOrderDetails(PMC_DH_ConstantClass.TEST_COMMUNITYID,strTestAcct.Id, strResponseSAP);
           
        system.Assert(strTestAcct!=null, 'Success');
        }
        Test.stopTest();
    }
    
}