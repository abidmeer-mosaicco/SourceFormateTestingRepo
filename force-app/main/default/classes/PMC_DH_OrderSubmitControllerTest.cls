@isTest
public with sharing class PMC_DH_OrderSubmitControllerTest {
    Public static final string STRING_SUBMIT_SUCCESS = '{"ETY_INBOUND":{"PaymentTermsn":"","CutomerMaterial":"","AccMngName":"","PackRequested":"","ReqDelDat":"2023-10-11","ReqId":"MD-0000001-1-1","ProtocolPrice":"0.000","Selfconsind":"","GenPricePerunit":"0.000","Plant":"4000","MaterialDesc":"","CreatedVia":"Mosaic Direct","ContractReq":"","TotPrice":"0.000","CreatedOn":"2023-10-11T00:00:00.000","FormulaKeyDesc":"","CreatedBy":"Ben laster","PoNo":"","DelInstr":"","Material":"FFALM","CustomerId":"20000021","FormulaKey":"","NfeCoopCustomer":"","NfeBillingDate":"","ContractFinalized":"","CustomerReqQty":"6.000","Mot":"","SoldToName":"","ContractItemNo":"000000","ShipTo":"","Incoterms":"FOB","Week":"","BusinessScenario":"","Key":"","ManagerId":""}}';
    Public static final String STRING_FETCH_SUCCESS = '{"lstData":[{"strPoNumber":"TEST SELF","strShiptoId":"800 PEMBRO","strConfirmedCuttingQty":"50","strContractFinalized":"20001347","strShiptoAdd":"PEACE VALLEY PRODUCTS","strCreateBy":"PSARADHI","strReqId":"S4-0000000089-1-1","strMaterial":"1234","strConfirmDelDate":"21.09.2023","strCustMatnr":"12345","strCreateVia":"SAP","strRequestQty":"100.000","strReqDelDate":"2023-10-05","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"Test OTC - Customer Test OTC","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"Truck","strTotPrice":"0.000","strProtocolPriceUnit":"0.000","strGeneralPrice":"0.000","strCreatedOn":"2023-09-29T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP","strProtocolNo":"M5922622f3","strSalesOrder":""},{"strPoNumber":"ZRCM TEST","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"10.000","strContractFinalized":"20001347","strShiptoAdd":"PEACE VALLEY PRODUCTS","strCreateBy":"PSARADHI","strReqId":"S4-0000000089-1-2","strMaterial":"1234","strConfirmDelDate":"13-12-2023","strCustMatnr":"1234","strCreateVia":"SAP","strRequestQty":"10.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"Barge","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-03T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP","strProtocolNo":"M5922622f3","strSalesOrder":""},{"strPoNumber":"ZRCM TEST","strShiptoId":"","strConfirmedCuttingQty":"5.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000099-1-1","strMaterial":"000000000001000031","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"5.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-04T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP","strAccIdentifier":"12345678900","strProtocolNo":"M5922622f4","strSalesOrder":""}]}';
    Public static final string STRING_OUTBOUND_EXCEPTION = '{"lstData""strPoNumber":"TEST SELF","strShiptoId":"800 PEMBRO","strConfirmedCuttingQty":"50","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000089-1-1","strMaterial":"1234","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"100.000","strReqDelDate":"05.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"Test OTC - Customer Test OTC","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"0.000","strGeneralPrice":"0.000","strCreatedOn":"2023-09-29T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"10.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000098-1-1","strMaterial":"1234","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"10.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-03T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"5.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000099-1-1","strMaterial":"000000000001000031","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"5.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-04T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"}';
    Public static final string STRING_INBOUND_EXCEPTION = '{"ETY_INBOUND""PaymentTermsn":"","CutomerMaterial":"","AccMngName":"","PackRequested":"","ReqDelDat":"2023-10-11","ReqId":"MD-0000001-1-1","ProtocolPrice":"0.000","Selfconsind":"","GenPricePerunit":"0.000","Plant":"4000","MaterialDesc":"","CreatedVia":"Mosaic Direct","ContractReq":"","TotPrice":"0.000","CreatedOn":"2023-10-11T00:00:00.000","FormulaKeyDesc":"","CreatedBy":"Ben laster","PoNo":"","DelInstr":"","Material":"FFALM","CustomerId":"20000021","FormulaKey":"","NfeCoopCustomer":"","NfeBillingDate":"","ContractFinalized":"","CustomerReqQty":"6.000","Mot":"","SoldToName":"","ContractItemNo":"000000","ShipTo":"","Incoterms":"FOB","Week":"","BusinessScenario":"","Key":"","ManagerId":""}';
    Public static final String STRING_EDIT_SUCCESS = '{"lstResultData":{"strReqId":"S4-0000000089-1-","strPlant":"4000","strCustomerId":"20000022","strMaterial":"1234","strIncoterms":"FOB","strCreatedBy":"Ben laster","strCreatedVia":"Mosaic Direct","strNfeCoopCustomer":"","strNfeBillingDate":"","strGenPricePerunit":"0.000","strTotPrice":"0.000","strCustomerReqQty":"7.000","strReqDelDat":"2023-10-15","strContractReq":"","strContractItemNo":"000000","strShipTo":"","strProtocolPrice":"0.000","strDelInstr":"","strMot":"","strPoNo":"","strPaymentTermsn":"","strSelfConsInd":"","strCutomerMaterial":""}}';

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
        Id lstPermSet4=[select id from PermissionSet where Name ='PMC_DH_CR_TransactionLogs'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet4);
        String strContactId=[SELECT contactId FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1][0].contactId;
        
        WebStore webStore=PMC_DH_TestDataFactoryClass.createTestWebStore();
                Account shipToAcc=PMC_DH_TestDataFactoryClass.createShipToTestAccount(acc);
       shipToAcc.PMC_SS_CPF__c = '12345678900';
        update shipToAcc;
        system.runAs(user){

        WebCart cartObj=PMC_DH_TestDataFactoryClass.buildCart(webStore.Id,acc.Id);
        insert cartObj;
        Product2 prod = PMC_DH_TestDataFactoryClass.createProduct();
        insert prod;
        Product2 prod2 = new Product2(name='Test21',StockKeepingUnit='944876',isactive=true);
        insert prod2;
        Opportunity opp=PMC_DH_TestDataFactoryClass.createOpportunity(acc);
        SBQQ__Quote__c testQuote=PMC_DH_TestDataFactoryClass.createQuote(acc,strContactId,opp);
        SBQQ__QuoteLine__c testQuoteLine = PMC_DH_TestDataFactoryClass.creatQuoteLine(testQuote,prod);
        Test.startTest();     
        // SBQQ__QuoteLine__c testQuoteLine2 = PMC_DH_TestDataFactoryClass.creatQuoteLine2(testQuote,prod2);    
        CartDeliveryGroup testCartDeliveryGroup=PMC_DH_TestDataFactoryClass.buildCartDeliveryGroup(cartObj.id);
        insert testCartDeliveryGroup;              
        Contract testContract = PMC_DH_TestDataFactoryClass.createContract(testQuote.id,acc.id);
        testContract.Status='Activated';
        update testContract;

        BuyerGroup byrgrp=PMC_DH_TestDataFactoryClass.createBuyerGroup();
        PMC_DH_TestDataFactoryClass.createBuyerGroupMember(acc.Id,byrgrp.Id);
        CommerceEntitlementPolicy commrceEntPolicy=PMC_DH_TestDataFactoryClass.createEntitlementPolicy();
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementBuyerGroup(commrceEntPolicy.Id,byrgrp.Id);
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementProduct(commrceEntPolicy.Id,prod.Id);
        PMC_DH_TestDataFactoryClass.createCommerceEntitlementProduct(commrceEntPolicy.Id,prod2.Id);


        Schema.Location loc = PMC_DH_TestDataFactoryClass.createLocation();
        loc.PMC_CPQ_Plant__c = 'Test';
        update loc;
        PMC_CPQ_ProductLocation__c prodLocation = PMC_DH_TestDataFactoryClass.createProductLocation(prod, loc);
        // PMC_CPQ_ProductLocation__c prodLocation2 = PMC_DH_TestDataFactoryClass.createProductLocation(prod2, loc);
        testQuoteLine.PMC_CPQ_PackType__c='';
        testQuoteLine.PMC_CPQ_PackageType__c='';
        testQuoteLine.PMC_CPQ_ShipTo__c = shipToAcc.id;
        testQuoteLine.PMC_CPQ_ProductLocation__c = prodLocation.id;
        testQuoteLine.PMC_CPQ_VCOQuotation__c = true;
        update testQuoteLine;
        PMC_DH_TestDataFactoryClass.CartItemObject objCartItem=new PMC_DH_TestDataFactoryClass.CartItemObject();
        objCartItem.strCartId=cartObj.id;
        objCartItem.strProductId=prod.id;
        objCartItem.strDeliveryGroupId=testCartDeliveryGroup.id;
        objCartItem.strShipToAccId=shipToAcc.id;
        objCartItem.strQuoteLineId = testQuoteLine.Id;
        objCartItem.strShipFromId=prodLocation.id;
        objCartItem.strContractId = testContract.Id;
        CartItem cartItem1=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem);
        cartItem1.Quantity = 10;
        cartItem1.TotalLineAmount = 100;
        cartItem1.PMC_DH_Source__c='RFQ';
        cartItem1.PMC_DH_Contract__c=testContract.id;
        cartItem1.PMC_DH_PackType__c='Packed';
        cartItem1.PMC_DH_PackageType__c='Saco 50 Kg';
        insert cartItem1;
        SBQQ__Subscription__c testSubscriptionNew = PMC_DH_TestDataFactoryClass.createSubscription(objCartItem);
           testSubscriptionNew.PMC_CPQ_FinalPricePerTonne__c=20;
            update testSubscriptionNew;
        cartItem1.PMC_DH_Subscription__c = testSubscriptionNew.Id;
        update cartItem1;
        
        PMC_DH_TestDataFactoryClass.CartItemObject objCartItem2=new PMC_DH_TestDataFactoryClass.CartItemObject();
        objCartItem2.strProductId=prod.id;
        objCartItem2.strDeliveryGroupId=testCartDeliveryGroup.id;
        objCartItem2.strShipToAccId=shipToAcc.id;
        objCartItem2.strShipFromId=prodLocation.id;
        objCartItem2.strContractId = testContract.Id;
        objCartItem2.strQuoteLineId = testQuoteLine.Id;
        objCartItem2.strAccId = acc.Id;
        CartItem cartItem2=PMC_DH_TestDataFactoryClass.buildCartItem1(objCartItem2);
        cartItem2.Quantity = 10;
        cartItem2.CartId =cartObj.id;
        cartItem2.TotalLineAmount = 100;
        cartItem2.PMC_DH_Source__c='RFQ';
        cartItem2.PMC_DH_Contract__c=testContract.id;
        cartItem2.PMC_DH_PackType__c='Bulk';
        cartItem2.PMC_DH_PackageType__c='';
        insert cartItem2;
        SBQQ__Subscription__c testSubscription = PMC_DH_TestDataFactoryClass.createSubscription(objCartItem2);
             testSubscription.PMC_CPQ_FinalPricePerTonne__c=20;
            update testSubscription;
        cartItem2.PMC_DH_Subscription__c = testSubscription.Id;
        update cartItem2;
            
      //  PMC_DH_TestDataFactoryClass.createSoldToShipToAccountJunction(shipToAcc.id, acc.Id);
        Test.stopTest();
        }
    }
    
    
    @isTest
    public static void testOrderSubmit(){
        Test.setMock(HTTPCalloutMock.Class, new PMC_DH_OrderSubmitMock(200,STRING_SUBMIT_SUCCESS, 'Success'));
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT Id FROM WebCart WHERE Name='Test Web Cart'][0].Id;
        Boolean isException = false;
        system.runAs(user) {
            try{
                PMC_DH_OrderSubmitController.submitOrder(strCartId);  
            }
            catch(Exception ex){
                isException = false;
            }
        }
        system.assert(strCartId != NULL, 'Success');
        Test.stopTest();
    } 
    
    @isTest
    public static void testOrderSubmitWithInAnalysisadd2(){
        Test.setMock(HTTPCalloutMock.Class, new PMC_DH_OrderSubmitMock(200,STRING_SUBMIT_SUCCESS, 'Success'));
        Test.startTest();
        Account acc=[select id,PMC_SS_CPF__c,PMC_SS_TaxIDOrCNPJOrCPF__c from account where PMC_SS_CPF__c='12345678900' limit 1];
        acc.PMC_SS_CPF__c='';
         acc.PMC_SS_TaxIDOrCNPJOrCPF__c  ='12123412345123';
        update acc;
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT Id FROM WebCart WHERE Name='Test Web Cart'][0].Id;
        List<Cartitem> cartList=[select id,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.Id,cartId from cartItem where cartId=:strCartId];
        set<String> qidSet=new Set<String>();

        set<String> subIdSet=new Set<String>();
        for(cartItem item:cartList)
        {

            if(item.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.Id !=null)
            {
                            qidSet.add(item.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.Id);
                             subIdSet.add(item.PMC_DH_Subscription__r.id);
            }

        }

       List<SBQQ__QuoteLine__c> tempQ=[select id,PMC_CPQ_VCOQuotation__c from  SBQQ__QuoteLine__c where id IN:qidSet ];
        for(SBQQ__QuoteLine__c item:tempQ)
        {
                    item.PMC_CPQ_VCOQuotation__c=false;



        }
               List<SBQQ__Subscription__c> subTemp=[select id,PMC_CPQ_FinalPricePerTonne__c from  SBQQ__Subscription__c where id IN:subIdSet ];
        for(SBQQ__Subscription__c item:subTemp)
        {
                    item.PMC_CPQ_FinalPricePerTonne__c=34.54;



        }
        if(tempQ.size()>0)
        {
             update tempQ;
            system.debug('tempQ---'+tempQ);
        }
         if(subTemp.size()>0)
        {
             update subTemp;
            system.debug('subTemp---'+subTemp);
        }

        Boolean isException = false;
        system.runAs(user) {
            try{
                PMC_DH_OrderSubmitController.submitOrder(strCartId);  
            }
            catch(Exception ex){
                isException = false;
            }
        }
        system.assert(strCartId != NULL, 'Success');
        Test.stopTest();
    }

    
   @isTest
    public static void testOrderSubmitWithInAnalysisadd3(){
        Test.setMock(HTTPCalloutMock.Class, new PMC_DH_OrderSubmitMock(200,STRING_SUBMIT_SUCCESS, 'Success'));
        Test.startTest();
        Account acc=[select id,PMC_SS_CPF__c,PMC_SS_TaxIDOrCNPJOrCPF__c from account where PMC_SS_CPF__c='12345678900' limit 1];
        acc.PMC_SS_CPF__c='';
         acc.PMC_SS_TaxIDOrCNPJOrCPF__c  ='12123412345123';
     acc.type='sold-to';
        update acc;
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT Id FROM WebCart WHERE Name='Test Web Cart'][0].Id;
        List<Cartitem> cartList=[select id,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.Id,cartId from cartItem where cartId=:strCartId];
        system.debug('cartList'+cartList);
        set<String> qidSet=new Set<String>();

        set<String> subIdSet=new Set<String>();
        for(cartItem item:cartList)
        {

            if(item.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.Id !=null)
            {
                            qidSet.add(item.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.Id);
                             subIdSet.add(item.PMC_DH_Subscription__r.id);
            }

        }

       List<SBQQ__QuoteLine__c> tempQ=[select id,PMC_CPQ_VCOQuotation__c from  SBQQ__QuoteLine__c where id IN:qidSet ];
        for(SBQQ__QuoteLine__c item:tempQ)
        {
                    item.PMC_CPQ_VCOQuotation__c=true;



        }
               List<SBQQ__Subscription__c> subTemp=[select id,PMC_CPQ_FinalPricePerTonne__c from  SBQQ__Subscription__c where id IN:subIdSet ];
        for(SBQQ__Subscription__c item:subTemp)
        {
                    item.PMC_CPQ_FinalPricePerTonne__c=34.54;



        }
        if(tempQ.size()>0)
        {
             update tempQ;
            system.debug('tempQ---'+tempQ);
        }
         if(subTemp.size()>0)
        {
             update subTemp;
            system.debug('subTemp---'+subTemp);
        }
PMC_DH_OrderRequestWrapper.PMC_DH_RequestWrapper reqWrap=new PMC_DH_OrderRequestWrapper.PMC_DH_RequestWrapper();
        Boolean isException = false;
        system.runAs(user) {
            try{
                PMC_DH_OrderSubmitController.submitOrder(strCartId);  
            }
            catch(Exception ex){
                isException = false;
            }
        }
        system.assert(strCartId != NULL, 'Success');
        Test.stopTest();
    }

    
    
    @isTest
    public static void testOrderSubmitWithInAnalysisAddress(){
        Test.setMock(HTTPCalloutMock.Class, new PMC_DH_OrderSubmitMock(200,STRING_SUBMIT_SUCCESS, 'Success'));
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT Id FROM WebCart WHERE Name='Test Web Cart'][0].Id;
        Boolean isException = false;
        system.runAs(user) {
            try{
                PMC_DH_OrderSubmitController.submitOrder(strCartId);  
            }
            catch(Exception ex){
                isException = false;
            }
        }
        system.assert(strCartId != NULL, 'Success');
        Test.stopTest();
    }


      @isTest
    public static void testOrderSubmitException(){
        Test.setMock(HTTPCalloutMock.Class, new PMC_DH_OrderSubmitMock(500,STRING_SUBMIT_SUCCESS, 'Success'));
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT Id FROM WebCart WHERE Name='Test Web Cart'][0].Id;
        Boolean isException = false;
        system.runAs(user) {
            try{
                PMC_DH_OrderSubmitController.boolThrowException = true;
                PMC_DH_OrderSubmitController.submitOrder(strCartId);              
            }
            catch(Exception ex){
                isException = true;
            }
        }
        system.assert(strCartId != NULL, 'Success');
        Test.stopTest();
    } 
    
    
     @isTest
    public static void testOrderSubmitWithInAnalysisAddress1(){
        Test.setMock(HTTPCalloutMock.Class, new PMC_DH_OrderSubmitMock(200,STRING_SUBMIT_SUCCESS, 'Success'));
        Test.startTest();
        Account acc=[select id,PMC_SS_CPF__c,PMC_SS_TaxIDOrCNPJOrCPF__c from account where PMC_SS_CPF__c='12345678900' limit 1];
        acc.PMC_SS_CPF__c='';
         acc.PMC_SS_TaxIDOrCNPJOrCPF__c  ='12123412345123';
        update acc;
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strCartId=[SELECT Id FROM WebCart WHERE Name='Test Web Cart'][0].Id;
        List<Cartitem> cartList=[select id,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.Id,cartId from cartItem where cartId=:strCartId];
        system.debug('cartList'+cartList);
        set<String> qidSet=new Set<String>();
        
        set<String> subIdSet=new Set<String>();
        for(cartItem item:cartList)
        {
           
            if(item.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.Id !=null)
            {
                            qidSet.add(item.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.Id);
                             subIdSet.add(item.PMC_DH_Subscription__r.id);
            }
            
        }
        
       List<SBQQ__QuoteLine__c> tempQ=[select id,PMC_CPQ_VCOQuotation__c from  SBQQ__QuoteLine__c where id IN:qidSet ];
        for(SBQQ__QuoteLine__c item:tempQ)
        {
                    item.PMC_CPQ_VCOQuotation__c=false;

            
            
        }
               List<SBQQ__Subscription__c> subTemp=[select id,PMC_CPQ_FinalPricePerTonne__c from  SBQQ__Subscription__c where id IN:subIdSet ];
        for(SBQQ__Subscription__c item:subTemp)
        {
                    item.PMC_CPQ_FinalPricePerTonne__c=34.54;

            
            
        }
        if(tempQ.size()>0)
        {
             update tempQ;
            system.debug('tempQ---'+tempQ);
        }
         if(subTemp.size()>0)
        {
             update subTemp;
            system.debug('subTemp---'+subTemp);
        }
     
        Boolean isException = false;
        system.runAs(user) {
            try{
                PMC_DH_OrderSubmitController.submitOrder(strCartId);  
            }
            catch(Exception ex){
                isException = false;
            }
        }
        system.assert(strCartId != NULL, 'Success');
        Test.stopTest();
    }
    
    
  
    
    
    
    
    @isTest
    public static void testFetchOrderHistory(){
        Test.setMock(HTTPCalloutMock.Class, new PMC_DH_OrderSubmitMock(200,STRING_FETCH_SUCCESS, 'success'));
        Test.startTest();
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        String strAccountId = [SELECT Id FROM Account WHERE Name = 'Parent Test Account'][0].Id;
        PMC_DH_OrderListViewWrapper result;
        System.runAs(user){
            result = PMC_DH_OrderSubmitController.fetchOrderHistory(strAccountId);
        }
        system.Assert(result != Null, 'Success');        
        Test.stopTest();
    }   
    
    @isTest
    public static void testFetchOrderHistoryException(){
        Test.setMock(HTTPCalloutMock.Class, new PMC_DH_OrderSubmitMock(500,STRING_OUTBOUND_EXCEPTION, 'Error'));
        Test.startTest();
        Boolean isException = false;
        String strAccountId = [SELECT Id FROM Account WHERE Name = 'Parent Test Account'][0].Id;
        PMC_DH_OrderListViewWrapper result;
        try{
            result = PMC_DH_OrderSubmitController.fetchOrderHistory(strAccountId);
        }
        catch(Exception ex){
            isException = true;
        }
        system.Assert(strAccountId !=Null,'success');
        
        Test.stopTest();
    }   
    
    @isTest
    public static void testFetchOrderHistoryNoData(){
        String strEmptyResponse = '{"lstData":[]}"';
        Test.setMock(HTTPCalloutMock.Class, new PMC_DH_OrderSubmitMock(500,strEmptyResponse, 'Error'));
        Test.startTest();
        String strAccountId = [SELECT Id FROM Account WHERE Name = 'Parent Test Account'][0].Id;
        PMC_DH_OrderListViewWrapper result;
        result = PMC_DH_OrderSubmitController.fetchOrderHistory(strAccountId);
        system.Assert(strAccountId != Null, 'Success');
        
        Test.stopTest();
    }  
    @isTest
    public static void testOrderEdit(){
        Test.setMock(HTTPCalloutMock.Class, new PMC_DH_OrderSubmitMock(202,STRING_EDIT_SUCCESS, 'Success'));
        Test.startTest();
        String result;
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Contract con = [select ContractNumber,PMC_CPQ_ContractNumberIdentifier__c, Status, Account.name from contract LIMIT 1]; 
        CartItem ci = [SELECT Id, PMC_DH_SAPRequestReferenceNumber__c FROM CartItem LIMIT 1];
        system.runAs(user){
            PMC_DH_RequestedOrderEditController.EditRequestWrapper editWrapper= new PMC_DH_RequestedOrderEditController.EditRequestWrapper();
            editWrapper.strOrderLineId =ci.PMC_DH_SAPRequestReferenceNumber__c;//'S4-0000000089-1-1';
            editWrapper.strReqQty = '15';
            editWrapper.strReqShipmentDate ='2023-11-03';
            editWrapper.responseData ='{"lstData":[{"strPoNumber":"TEST SELF","strShiptoId":"5389421474","strConfirmedCuttingQty":"50.000","strIncotterms":"CIF","strMot":"Vessel","strContractFinalized":"'+con.PMC_CPQ_ContractNumberIdentifier__c +'","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"'+editWrapper.strOrderLineId+'","strMaterial":"1234","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"100.000","strReqDelDate":"05.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"Test OTC - Customer Test OTC","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"Test","strTotPrice":"0.000","strProtocolPriceUnit":"0.000","strGeneralPrice":"0.000","strCreatedOn":"2023-09-29T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP","strPackType":"Packed","strPackingType":"Big Bag 1500 Kg"}]}';//,{"strPoNumber":"ZRCM TEST","strShiptoId":"FAZENDA PR","strIncotterms":"CIF","strConfirmedCuttingQty":"10.000","strContractFinalized":"'+con.PMC_CPQ_ContractNumberIdentifier__c +'","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"'+editWrapper.strOrderLineId+'","strMaterial":"1234","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"10.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-03T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strIncotterms":"FOB","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"5.000","strContractFinalized":"'+con.PMC_CPQ_ContractNumberIdentifier__c +'","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"'+editWrapper.strOrderLineId+'","strMaterial":"000000000001000031","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"5.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-04T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"}
            Boolean isException = false;
            try{

                result = PMC_DH_RequestedOrderEditController.getUpdatedDetails(editWrapper);              
            }
            catch(Exception ex){
                isException = true;
            }
            system.assert(result != NULL, 'Success');
        }
        Test.stopTest();
    } 
    @isTest
    public static void testOrderEditResponse(){
        PMC_DH_OrderEditWrapper orderEditResponse = new PMC_DH_OrderEditWrapper();
        PMC_DH_OrderEditWrapper.PMC_DH_RequestWrapper resp = new PMC_DH_OrderEditWrapper.PMC_DH_RequestWrapper();
        resp.strReqId = 'MD-0000002051-1-1';
        resp.strPlant = '4030';
        resp.strCustomerId = '20000021';
        resp.strMaterial = '1000031';
        resp.strIncoterms = 'CIF';
        resp.strCreatedBy = 'Liam Smithson';
        resp.strCreatedVia = 'Mosaic Direct';
        resp.strNfeCoopCustomer = '';
        resp.strNfeBillingDate = '';
        resp.strGenPricePerunit = '1.00';
        resp.strTotPrice = '1.00';
        resp.strCustomerReqQty = '34.00';
        resp.strReqDelDat = '10.01.2024';
        resp.strContractReq = '';
        resp.strContractItemNo = '';
        resp.strShipTo = '20000005';
        resp.strProtocolPrice = '0.00';
        resp.strDelInstr = 'Deliver safely';
        resp.strMot = 'Truck';
        resp.strPoNo = 'ABC123';
        resp.strPaymentTermsn = '';
        resp.strSelfConsInd = '';
        resp.strCutomerMaterial = '';
        orderEditResponse.lstResultData = resp;
        System.assert(orderEditResponse != NULL, 'Success');
    } 
    @isTest
    public static void testOrderFetchResponse(){
        PMC_DH_OrderFetchWrapper orderFetchResponse = new PMC_DH_OrderFetchWrapper();
        List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> responseWrapper = new List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>();
        PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper resp = new PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper();
        resp.strReqId = 'MD-0000002051-1-1';
        resp.strPlant = '4030';
        resp.strMaterial = '1000031';
        resp.strIncotterms = 'CIF';
        resp.strCreateBy = 'Liam Smithson';
        resp.strCreateVia = 'Mosaic Direct';
        resp.strGeneralPrice = '1.00';
        resp.strTotPrice = '1.00';
        resp.strConfirmDelDate = '2024-01-10';
        resp.strShiptoId = '20000005';
        resp.strConfirmedCuttingQty = '23';
        resp.strContractFinalized = '';
        resp.strRequestQty = '20';
        resp.strPlantAdd = '';
        resp.strMaterialDesc = 'KMAG';
        resp.strShiptoAdd = 'test address, New York, United States';
        resp.strReqDelDate = '2024-01-10';
        resp.strSoldtoName = 'Mosaic BR';
        resp.strShiptoName = 'ship to address, New York, United States';
        resp.strSoldtoId = '1000013';
        resp.strProtocolPriceUnit = '0.00';
        resp.strMot = 'Truck';
        resp.strPoNumber = 'ABC123';
        resp.strCustMatnr = '';
        responseWrapper.add(resp);
        orderFetchResponse.lstData = responseWrapper;
        System.assert(orderFetchResponse != NULL, 'Success');
    }
    
    @isTest
    public static void testOrderEditException(){
        Test.setMock(HTTPCalloutMock.Class, new PMC_DH_OrderSubmitMock(500,'', 'Error'));
        Test.startTest();
        String result;
        PMC_DH_RequestedOrderEditController.EditRequestWrapper editWrapper= new PMC_DH_RequestedOrderEditController.EditRequestWrapper();
        editWrapper.strOrderLineId = '';
        editWrapper.strReqQty = '';
        editWrapper.strReqShipmentDate ='';
        editWrapper.responseData ='{"lstData":[{"strPoNumber":"TEST SELF","strShiptoId":"800 PEMBRO","strConfirmedCuttingQty":"50.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000089-1-1","strMaterial":"1234","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"100.000","strReqDelDate":"05.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"Test OTC - Customer Test OTC","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"0.000","strGeneralPrice":"0.000","strCreatedOn":"2023-09-29T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"10.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000098-1-1","strMaterial":"1234","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"10.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-03T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"},{"strPoNumber":"ZRCM TEST","strShiptoId":"FAZENDA PR","strConfirmedCuttingQty":"5.000","strContractFinalized":"20001347","strShiptoAdd":"","strCreateBy":"PSARADHI","strReqId":"S4-0000000099-1-1","strMaterial":"000000000001000031","strConfirmDelDate":"  1","strCustMatnr":"","strCreateVia":"SAP","strRequestQty":"5.000","strReqDelDate":"10.10.2023","strSoldtoName":"NF-E EMITIDA EM AMBIENTE DE HOMOLOG ACAO - SEM VALOR FISCAL","strShiptoName":"JOSE HAROLDO DETONI","strSoldtoId":"20000021","strMaterialDesc":"BIOFOS®, MONOCALCIUM PHOSPHATE","strPlant":"4030","strMot":"","strTotPrice":"0.000","strProtocolPriceUnit":"200.000","strGeneralPrice":"0.000","strCreatedOn":"2023-10-04T00:00:00.000","strPlantAdd":"4030Cubatao 1Av Engenheiro Plinio de Queiro11570-000BRSP"}]}';
        Boolean isException = false;
        try{
            result = PMC_DH_RequestedOrderEditController.getUpdatedDetails(editWrapper);              
        }
        catch(Exception ex){
            isException = true;
        }
        system.assert(result != NULL, 'Success');
        Test.stopTest();
    }  
    
    
}