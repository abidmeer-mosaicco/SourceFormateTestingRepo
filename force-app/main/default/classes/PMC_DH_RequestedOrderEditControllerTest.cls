@isTest
public class PMC_DH_RequestedOrderEditControllerTest {
    Public static final String STRING_EDIT_SUCCESS = '{"lstData":[{"strPoNumber":"TEST SELF","strShiptoId":"800 PEMBRO","strConfirmedCuttingQty":"50.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000089-1-1","strMaterial":"1234","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strCustomerReqQty":"15.000","strReqDelDat":"29.04.2024","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"Test OTC - Customer Test OTC","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"0.000","strGeneralPrice":"0.000","strCreatedOn":"2023-09-29T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"10.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000098-1-1","strMaterial":"1234","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strCustomerReqQty":"10.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-03T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"5.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000099-1-1","strMaterial":"000000000001000031","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strCustomerReqQty":"5.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-04T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"}]}';
    //Public static final String STRING_EDIT_SUCCESS = '{"lstData":[{"strPoNumber":"TEST SELF","strShiptoId":"800 PEMBRO","strConfirmedCuttingQty":"50.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000089-1-1","strMaterial":"1234","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strCustomerReqQty":"100.000","strReqDelDate":"05.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"Test OTC - Customer Test OTC","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"0.000","strGeneralPrice":"0.000","strCreatedOn":"2023-09-29T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"10.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000098-1-1","strMaterial":"1234","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strCustomerReqQty":"10.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-03T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"5.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000099-1-1","strMaterial":"000000000001000031","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strCustomerReqQty":"5.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-04T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"}]}';
    // public static final String STRING_EDIT_SUCCESS = '{"lstResultData":{"strReqId":"MD-0000002051-1-1","strPlant":"4030","strCustomerId":"20000021","strMaterial":"1000031","strIncoterms":"CIF","strCreatedBy":"Liam Smithson","strCreatedVia":"Mosaic Direct","strNfeCoopCustomer":"6656","strGenPricePerunit":"1.000","strTotPrice":"1.000","strCustomerReqQty":"345.000","strUnitOfMeasure":"","strPackingType":"Packed","strPackType":"Saco 50 Kg - Paletizado","strReqDelDat":"10.01.2024","strContractReq":"","strContractItemNo":"","strShipTo":"20000005","strProtocolPrice":"0.000","strDelInstr":"Deliver safely","strMot":"Truck","strPoNo":"","strPaymentTermsn":"","strSelfConsInd":"","strCutomerMaterial":"","strNFEBillingDate":"13.01.2024"}}';
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
        
        //Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
        Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);
        
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        //String strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
        
        String strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
        WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
        insert cartObj;
        Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
        insert prod;
        Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
        SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
        SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);         
        Test.startTest();
        CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
        insert testCartDeliveryGroup;        
        BuyerGroup byrgrp=PMC_DH_TestDataFactoryClass.createBuyerGroup();
        
        PMC_DH_TestDataFactoryClass.createBuyerGroupMember(acc.Id,byrgrp.Id);
        CommerceEntitlementPolicy commrceEntPolicy=PMC_DH_TestDataFactoryClass.createEntitlementPolicy();
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementBuyerGroup(commrceEntPolicy.Id,byrgrp.Id);
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementProduct(commrceEntPolicy.Id,prod.Id);
        
        Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
        Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
        
        PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
        PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
        objCartItem.strCartId=cartObj.id;
        objCartItem.strProductId=prod.id;
        objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
        objCartItem.strShipToAccId=shipToAcc.id;
        objCartItem.strQuoteLineId = testQuoteLine.Id;
        objCartItem.strShipFromId=prodLocation.id;
        //objCartItem.strContractId = testContract.Id;
        PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
        
        PMC_DH_TestDataFactoryClass.CartItemObject objCartItem2=new PMC_DH_TestDataFactoryClass.CartItemObject();
        objCartItem2.strCartId=cartObj.id;
        objCartItem2.strProductId=prod.id;
        objCartItem2.strDeliveryGroupId=testCartDeliveryGroup.id;
        objCartItem2.strShipToAccId=shipToAcc.id;
        objCartItem2.strShipFromId=prodLocation.id;
        PMC_DH_TestDataFactoryClass.createSubscription(objCartItem2);
        
        CartItem cartItem2=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem2);
        cartItem2.PMC_DH_Source__c='RFQ';
        //cartItem2.PMC_DH_Contract__c=testC1.Id;
        upsert cartItem2;
    }
    
    
    @isTest
    public static void testOrderEdit(){
        Test.setMock(HTTPCalloutMock.Class, new PMC_DH_OrderSubmitMock(202,STRING_EDIT_SUCCESS, 'Success'));
        Test.startTest();
        // String responseData = '{\"lstData\":[{\"strTotPrice\":\"1.000\",\"strSoldtoName\":\"\",\"strSoldtoId\":\"0020000021\",\"strShiptoName\":\"PEACE VALLEY PRODUCTS\",\"strShiptoId\":\"0020000005\",\"strShiptoAdd\":\"800 PEMBROKE RD55441-2655PlymouthUS\",\"strRequestQty\":\"345.000\",\"strReqId\":\"MD-0000002051-1-1\",\"strReqDelDate\":\"10.01.2024\",\"strProtocolPriceUnit\":\"0.000\",\"strPoNumber\":\"\",\"strPlantAdd\":\"4030Cubatao 1Mosaic Fertilizantes do BrasilAv Engenheiro Plinio de Queiro11570-000BRSP\",\"strPlant\":\"4030\",\"strPackType\":\"Packed\",\"strPackingType\":\"Saco 50 Kg - Paletizado\",\"strMot\":\"Truck\",\"strMaterialDesc\":\"BIOFOS®, MONOCALCIUM PHOSPHATE\",\"strMaterial\":\"1000031\",\"strIncotterms\":\"CIF\",\"strGeneralPrice\":\"1.000\",\"strCustMatnr\":\"\",\"strCreateVia\":\"Mosaic Direct\",\"strCreatedOn\":\"2024-01-10T00:00:00.000\",\"strCreateBy\":\"Liam Smithson\",\"strContractFinalized\":\"\",\"strConfirmedCuttingQty\":\"0.000\",\"strConfirmDelDate\":\"\"}]}';
        String responseData ='{"lstData":[{"strPoNumber":"TEST SELF","strShiptoId":"800 PEMBRO","strConfirmedCuttingQty":"50.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000089-1-1","strMaterial":"1234","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strCustomerReqQty":"100.000","strReqDelDate":"05.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"Test OTC - Customer Test OTC","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"0.000","strGeneralPrice":"0.000","strCreatedOn":"2023-09-29T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"10.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000098-1-1","strMaterial":"1234","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strCustomerReqQty":"10.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-03T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"5.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000099-1-1","strMaterial":"000000000001000031","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strCustomerReqQty":"5.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-04T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"}]}';
        //Boolean isException = false;
        PMC_DH_RequestedOrderEditController.EditRequestWrapper editReqWrapper = new PMC_DH_RequestedOrderEditController.EditRequestWrapper();
        editReqWrapper.responseData = responseData;
        editReqWrapper.strOrderLineId = 'MD-0000002051-1-1';
        editReqWrapper.strReqQty = '345';
        editReqWrapper.strReqShipmentDate = '2024-01-10';
        //try{
            //PMC_DH_RequestedOrderEditController.getUpdatedDetails('S4-0000000089-1-1','15','2023-10-29',responseData); 
            String result = PMC_DH_RequestedOrderEditController.getUpdatedDetails(editReqWrapper);   
            // System.debug('testOrderEdit Resp:'+result);
        // }
        // catch(Exception ex){
        //     isException = true;
        // }
        //system.assert(strCartId != NULL, 'Success');
        Test.stopTest();
        System.assert(result!=null, 'Success');
    }  
}