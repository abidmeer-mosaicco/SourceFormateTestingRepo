/**
* @description       : 
* @author            : Mosaic Direct | Dev Team
* @group             : 
* @last modified on  : 03-01-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public without sharing class PMC_DH_CreateOrderRequestAPIUtility {
    private static final String APP_NAME='Mosaic Direct';
    /**
* @description Request Structure Mapping in Mosaic Direct
* @author siddharth.pradhan@mosaicco.com | Mosaic Direct | 10-07-2023 
* @return String
* @param strCartId 
**/
    public static String createOrderRequestForAPI(Id strCartId) {
        
        // get all the cart item for the web cart specified
        // get webstore id
        // get effective account id
        // get cartId
        PMC_DH_OrderRequestWrapper orderSubWrap= new PMC_DH_OrderRequestWrapper();
        PMC_DH_OrderRequestWrapper.PMC_DH_RequestWrapper reqWrap;
        List<PMC_DH_OrderRequestWrapper.PMC_DH_RequestWrapper> lstReqWrap=new List<PMC_DH_OrderRequestWrapper.PMC_DH_RequestWrapper>();
        List<CartItem> cartItems=PMC_DH_CommerceCartQueryUtilsClass.getCartItemsForSingleCart(strCartId);
        
        //GSMD-1116
        

        Map<String,cartItem> productUniqueMap=new Map<String,cartItem>();

        List<CartItem> cartItemsDuplicate=new List<CartItem> ();

        List<CartItem> cartItemsDuplicateFinal=new List<CartItem> ();

         List<CartItem> cartItemsOriginal=new List<CartItem> ();

        Set<String> proSkuSet=new Set<String>();

        for (CartItem ci : cartItems)   

            {

                if(productUniqueMap.containsKey(ci.product2.StockKeepingUnit))

                {

                    cartItemsDuplicate.add(ci);

                    proSkuSet.add(ci.product2.name+'_'+ci.id);
                }

                else

                {

                    productUniqueMap.put(ci.product2.StockKeepingUnit,ci);

                    cartItemsOriginal.add(ci);

                }

                   

               

            }

      

        List<Cartitem> cartItemList=new List<CartItem>();

     system.debug('cartItemsDuplicate----'+cartItemsDuplicate);

         if(cartItemsDuplicate.size()>0)

        {

        

                cartItemList=[select id,PMC_DH_ProtocolNumber__c,cartId,PMC_DH_SAPRequestReferenceNumber__c,PMC_DH_PackType__c,PMC_DH_PackageType__c,Cart.AccountId,PMC_DH_PlantShipFrom__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c,product2.StockKeepingUnit,Product2.Name,PMC_DH_Incoterms__c,cart.CreatedBy.Name,PMC_DH_NotaFiscalNumber__c,PMC_DH_NotaFiscalDate__c,

            TotalPrice,PMC_DH_RequestedShipmentDate__c,PMC_DH_Contract__r.ContractNumber,PMC_DH_ItemNumber__c,PMC_DH_PlantShipFrom__r.PMC_CPQ_Address__c, PMC_DH_ShipTo__r.ShippingAddress,PMC_DH_ShipTo__r.PMC_SS_SAPCustomerNumber__c,PMC_DH_SellOutPrice__c,PMC_DH_DeliveryInstructions__c,PMC_DH_DeliveryMode__c,

            cart.PMC_DH_Account__r.RecordType.name,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c,PMC_DH_ShipTo__r.Type,PMC_DH_DeliveryPONumber__c,cart.PMC_DH_PaymentTerms__c,PMC_DH_ShipTo__r.PMC_SS_Channel__c,Quantity,cart.PMC_DH_Account__r.PMC_SS_AccountExternalID__c,PMC_DH_Subscription__r.Name,PMC_DH_ShipTo__r.PMC_SS_AccountExternalID__c,

            PMC_DH_UnitofMeasure__c, PMC_DH_Contract__r.PMC_CPQ_ContractNumberIdentifier__c, PMC_DH_Subscription__r.PMC_CPQ_SubscriptionNumberIdentifier__c,PMC_DH_Subscription__r.PMC_CPQ_FinalPricePerTonne__c,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_FinalPricePerTonne__c, PMC_DH_Contract__r.SBQQ__Quote__r.SBQQ__PaymentTerms__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c, 

            PMC_DH_ShipTo__r.PMC_SS_CPF__c, PMC_DH_ShipTo__r.PMC_SS_TaxIDOrCNPJOrCPF__c,PMC_DH_ShipTo__r.PMC_SS_StateTaxNumber__c, PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c,PMC_DH_Contract__r.PMC_CPQ_LatestQuote__r.Name,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.SBQQ__UpgradedSubscription__r.Name,PMC_DH_Subscription__r.SBQQ__QuoteLine__r.SBQQ__Product__r.Name from cartitem where cart.accountID=:cartItems[0].cart.AccountId and name IN:proSkuSet WITH SECURITY_ENFORCED];

        

            system.debug('cartItemList----'+cartItemList);

       

        }

     

       

        List<Cartitem> finalCartItemList=new List<CartItem>();  

        if(cartItemList.size()>0)

        {

        finalCartItemList.addAll(cartItemList);

        }

        if(cartItemsOriginal.size()>0)

        {

        finalCartItemList.addAll(cartItemsOriginal);

        }

        if(finalCartItemList.size()>0)

        {

            cartItems=finalCartItemList;

        }

      system.debug('cartItems----'+cartItems);
        //GSMD-4261//

//GSMD-4682
        String contractId = cartItems.get(0).PMC_DH_Contract__c;
   //GSMD-4795
   List<SBQQ__Subscription__c> ContractitemList =[select Id,PMC_CPQ_SubscriptionNumberIdentifier__c,name from SBQQ__Subscription__c where SBQQ__Contract__c =:contractId ];
      Map<String,String> nameidentifierMAp=new Map<String,String>();
      for(SBQQ__Subscription__c  ci:ContractitemList)
      {
        nameidentifierMAp.put(ci.Name,ci.PMC_CPQ_SubscriptionNumberIdentifier__c);
      }
System.debug('nameidentifierMAp'+nameidentifierMAp);
Map<String,Boolean> revisedPresent=New Map<String,boolean>();
for (CartItem ci1 : cartItems)   {
            {
if(ci1.PMC_DH_Subscription__r.SBQQ__RevisedSubscription__c!=null)
{
   revisedPresent.put(ci1.id,true);
}
            }

         for (CartItem ci : cartItems)   {
            {
                 String quoteLineName;
                reqWrap=new PMC_DH_OrderRequestWrapper.PMC_DH_RequestWrapper();

                String amendmentQuoteName = ci.PMC_DH_Contract__r.PMC_CPQ_LatestQuote__r.Name;
                if(revisedPresent.containsKey(ci.id))
                {
                quoteLineName = ci.PMC_DH_Subscription__r.SBQQ__RevisedSubscription__r.Name;

                system.debug('ci.PMC_DH_Subscription__r.PMC_CPQ_FinalPricePerTonne__c=='+ci.PMC_DH_Subscription__r.SBQQ__RevisedSubscription__r.PMC_CPQ_FinalPricePerTonne__c);
                reqWrap.strGenPricePerunit=String.valueOf(ci.PMC_DH_Subscription__r.SBQQ__RevisedSubscription__r.PMC_CPQ_FinalPricePerTonne__c);  //change log - query update for GPT-28361 | added PMC_CPQ_FinalPricePerTonne__c
                  //gsmd4682
                reqWrap.strContractItemNo=nameidentifierMAp.get(ci.PMC_DH_Subscription__r.SBQQ__RevisedSubscription__r.Name);
               
                               reqWrap.strUnitOfMeasure= ci.PMC_DH_Subscription__r.SBQQ__RevisedSubscription__r.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c;//ci.PMC_DH_UnitofMeasure__c;

                }
                else
                {
                     quoteLineName = ci.PMC_DH_Subscription__r.Name;
                    system.debug('ci.PMC_DH_Subscription__r.PMC_CPQ_FinalPricePerTonne__c=='+ci.PMC_DH_Subscription__r.PMC_CPQ_FinalPricePerTonne__c);
                reqWrap.strGenPricePerunit=String.valueOf(ci.PMC_DH_Subscription__r.PMC_CPQ_FinalPricePerTonne__c);  //change log - query update for GPT-28361 | added PMC_CPQ_FinalPricePerTonne__c
                
                  //gsmd4682
                reqWrap.strContractItemNo=nameidentifierMAp.get(ci.PMC_DH_Subscription__r.Name);
                                reqWrap.strUnitOfMeasure= ci.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c;//ci.PMC_DH_UnitofMeasure__c;

                }
                
			


                //GSMD-2109//
                String strAmendmentQuoteNumber = (amendmentQuoteName != null && amendmentQuoteName.startsWith('Q-')) ? amendmentQuoteName.replace('Q-', '') : amendmentQuoteName;
                String strQuoteLineNumber = (quoteLineName != null && quoteLineName.startsWith('SUB-')) ? quoteLineName.replace('SUB-', '') : quoteLineName;
                
                reqWrap.strAmendmentQuoteNumber = strAmendmentQuoteNumber;
                reqWrap.strQuoteLineNumber = strQuoteLineNumber;    //GSMD-2109//
                
                reqWrap.strReqId= ci.PMC_DH_SAPRequestReferenceNumber__c;
                reqWrap.strPlant=ci.PMC_DH_PlantShipFrom__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c;//'4000';

                reqWrap.strCustomerId = PMC_DH_CommerceCartQueryUtilsClass.getAccountExternalId(ci.cart.AccountId);
                reqWrap.strMaterial=ci.Product2.StockKeepingUnit ;//'FFALM';
                reqWrap.strIncoterms=ci.PMC_DH_Incoterms__c;//'FOB';
                reqWrap.strCreatedBy=ci.cart.CreatedBy.Name;
                reqWrap.strCreatedVia=APP_NAME;
                //reqWrap.strCreatedOn=String.valueOf(System.today()); // attribute was removed from SAP
                reqWrap.strNfeCoopCustomer=String.ValueOf(ci.PMC_DH_NotaFiscalNumber__c);//'';
                reqWrap.strNFEBillingDate=ci.PMC_DH_NotaFiscalDate__c != Null?formatRequestedDate(String.ValueOf(ci.PMC_DH_NotaFiscalDate__c)):'';               
               reqWrap.strTotPrice=String.valueOf(ci.Quantity*Decimal.valueOf(reqWrap.strGenPricePerunit));
                reqWrap.strCustomerReqQty=String.ValueOf(ci.Quantity);
                reqWrap.strReqDelDat=ci.PMC_DH_RequestedShipmentDate__c != Null?formatRequestedDate(String.ValueOf(ci.PMC_DH_RequestedShipmentDate__c)):'';
              
                reqWrap.strProtocolPrice=String.valueOf(ci.PMC_DH_SellOutPrice__c);
                reqWrap.strDelInstr=ci.PMC_DH_DeliveryInstructions__c;//'Test Instruction';//Third party scenarios
                reqWrap.strMot=ci.PMC_DH_DeliveryMode__c;
                reqWrap.strPoNo=ci.PMC_DH_DeliveryPONumber__c;
                reqWrap.strPaymentTermsn=ci.PMC_DH_Contract__r.SBQQ__Quote__r.SBQQ__PaymentTerms__c;//ci.cart.PMC_DH_PaymentTerms__c;
                reqWrap.strSelfConsInd='';
                if(( ci.PMC_DH_ShipTo__r.PMC_SS_Channel__c==PMC_DH_ConstantClass.COOPERATIVE_CHNL ||
                    ci.PMC_DH_ShipTo__r.Type==PMC_DH_ConstantClass.SOLD_TO)
                   && ci.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c==true)
                {
                    reqWrap.strSelfConsInd=PMC_DH_ConstantClass.SELF_CONSMPT_X;
                }
                reqWrap.strCutomerMaterial=ci.PMC_DH_ItemNumber__c;
                reqWrap.strContractReq = ci.PMC_DH_Contract__r.PMC_CPQ_ContractNumberIdentifier__c;
                reqWrap.strPackType = '';
                //reqWrap.strShipTo=ci.PMC_DH_ShipTo__r.PMC_SS_AccountExternalID__c;
                if(ci.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c==true) {
                    reqWrap.strProtocolNo = ci.PMC_DH_ProtocolNumber__c;
                    reqWrap.strPackingType = PMC_DH_CommerceCartQueryUtilsClass.getPackOrPackageType(ci.PMC_DH_PackType__c,ci.PMC_DH_PackageType__c);
                    // added as part of GDASF-19767
                    //reqWrap.strShipTo = (getShipToIdOrAccIdentifier(ci)).get('strShipTo');
                    //reqWrap.strAccIdentifier = (getShipToIdOrAccIdentifier(ci)).get('strAccIdentifier');
                    reqWrap = getShipToIdOrAccIdentifier(ci, reqWrap);
                }
                else
                {
                    reqWrap.strShipTo = ci.PMC_DH_ShipTo__r.PMC_SS_AccountExternalID__c;
                     if(revisedPresent.containsKey(ci.id))
                {
                    reqWrap.strPackingType = PMC_DH_CommerceCartQueryUtilsClass.getPackOrPackageType(ci.PMC_DH_PackType__c,ci.PMC_DH_Subscription__r.SBQQ__RevisedSubscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c);// Added as part of GDASF-20003
                }
                else
                {
                     reqWrap.strPackingType = PMC_DH_CommerceCartQueryUtilsClass.getPackOrPackageType(ci.PMC_DH_PackType__c,ci.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_PackageType__c);// Added as part of GDASF-20003

                }
                }
                }
                // end of changes added as part of GDASF-19767
                lstReqWrap.add(reqWrap);
            }
        }
        orderSubWrap.lstResultData=lstReqWrap;
        return Json.serialize(orderSubWrap);
    }

    // GDASF-19767
    private static PMC_DH_OrderRequestWrapper.PMC_DH_RequestWrapper getShipToIdOrAccIdentifier(CartItem ci, PMC_DH_OrderRequestWrapper.PMC_DH_RequestWrapper reqWrap){
        if(ci.PMC_DH_ShipTo__r.PMC_SS_AccountExternalID__c == null)
        {
            if(ci.PMC_DH_ShipTo__r.PMC_SS_CPF__c != null){
                //reqWrap.strAccIdentifier = ci.PMC_DH_ShipTo__r.PMC_SS_CPF__c; //CPF Number
                  //reqWrap.strAccIdentifier = ci.PMC_DH_ShipTo__r.PMC_SS_CPF__c +'-'+ci.PMC_DH_ShipTo__r.PMC_SS_StateTaxNumber__c;
                //Character Limit is 25 
            String strdentifierCPF=ci.PMC_DH_ShipTo__r.PMC_SS_CPF__c +'-'+ci.PMC_DH_ShipTo__r.PMC_SS_StateTaxNumber__c;
           if(strdentifierCPF.length()>25){
            String strdentifierCPF2=   strdentifierCPF.right(25);
            reqWrap.strAccIdentifier =strdentifierCPF2;
           }else{
               reqWrap.strAccIdentifier = ci.PMC_DH_ShipTo__r.PMC_SS_CPF__c +'-'+ci.PMC_DH_ShipTo__r.PMC_SS_StateTaxNumber__c;
           }
            }
            else
            {
                //reqWrap.strAccIdentifier = ci.PMC_DH_ShipTo__r.PMC_SS_TaxIDOrCNPJOrCPF__c; //CNPJ Number
            //reqWrap.strAccIdentifier = ci.PMC_DH_ShipTo__r.PMC_SS_TaxIDOrCNPJOrCPF__c +'-'+ci.PMC_DH_ShipTo__r.PMC_SS_StateTaxNumber__c;
           //Character Limit is 25 
            String strdentifierCNPJ=ci.PMC_DH_ShipTo__r.PMC_SS_TaxIDOrCNPJOrCPF__c +'-'+ci.PMC_DH_ShipTo__r.PMC_SS_StateTaxNumber__c;
             if(strdentifierCNPJ.length()>25){
                        String strdentifierCNPJ2=   strdentifierCNPJ.right(25);
                        reqWrap.strAccIdentifier =strdentifierCNPJ2;
             }else{
                 reqWrap.strAccIdentifier = ci.PMC_DH_ShipTo__r.PMC_SS_TaxIDOrCNPJOrCPF__c +'-'+ci.PMC_DH_ShipTo__r.PMC_SS_StateTaxNumber__c;
             }
            
            }
        }
        else
        {
            reqWrap.strShipTo = ci.PMC_DH_ShipTo__r.PMC_SS_AccountExternalID__c;
     
     }
        return reqWrap;
    }
    
    private static String formatRequestedDate(String strReqDate) {
        List<String> datParamsList;
        String strFormattedDate;
        datParamsList = strReqDate.split('-');
        strFormattedDate=String.ValueOf(datParamsList[2]+'.'+datParamsList[1]+'.'+datParamsList[0]);  
        return strFormattedDate;     
    }
    /**
* @description Request Structure Mapping in Mosaic Direct
* @author  Mosaic Direct Dev 
* @return String
* @param strEffectiveAccountId 
**/
    public static String createRequestForOrderRequestStatus(String strEffectiveAccountId) {
        
        List<Account> lstAccount =[SELECT Id, AccountNumber FROM Account WHERE Id =:strEffectiveAccountId WITH SECURITY_ENFORCED];
        PMC_DH_OrderStatusRequestWrapper ordFetchWrapper = new PMC_DH_OrderStatusRequestWrapper();
        List<PMC_DH_OrderStatusRequestWrapper.PMC_DH_OrderRequestStatusWrapper> ordStatusWrapper = new List<PMC_DH_OrderStatusRequestWrapper.PMC_DH_OrderRequestStatusWrapper>();
        PMC_DH_OrderStatusRequestWrapper.PMC_DH_OrderRequestStatusWrapper wrap = new PMC_DH_OrderStatusRequestWrapper.PMC_DH_OrderRequestStatusWrapper();
        wrap.strAccountNumber = lstAccount[0].AccountNumber;
        ordStatusWrapper.add(wrap);
        /*for(Account acc : lstAccount){
PMC_DH_OrderStatusRequestWrapper.PMC_DH_OrderRequestStatusWrapper wrap = new PMC_DH_OrderStatusRequestWrapper.PMC_DH_OrderRequestStatusWrapper();
wrap.strAccountNumber = acc.AccountNumber;//'002000002'+ i;
ordStatusWrapper.add(wrap);
}*/
        ordFetchWrapper.listData = ordStatusWrapper; 
        return JSON.serialize(ordFetchWrapper);
    }
    
    /**
* @description Request Structure Mapping in Mosaic Direct
* @author Mosaic Direct Dev 
* @param  editWrapper
* @return String
**/
    public static String createOrderRequestForEdit(PMC_DH_RequestedOrderEditController.editRequestWrapper editWrapper) {
        PMC_DH_OrderRequestWrapper ordReqWrapper = new PMC_DH_OrderRequestWrapper();
        PMC_DH_OrderRequestWrapper.PMC_DH_RequestWrapper reqWrap=new PMC_DH_OrderRequestWrapper.PMC_DH_RequestWrapper();
        List<PMC_DH_OrderRequestWrapper.PMC_DH_RequestWrapper> lstReqWrap=new List<PMC_DH_OrderRequestWrapper.PMC_DH_RequestWrapper>();
        List<CartItem> cartItems=PMC_DH_CommerceCartQueryUtilsClass.getSingleCartItem(editWrapper.strOrderLineId);      
        if(!cartItems.isEmpty()){
            PMC_DH_OrderFetchWrapper responseWrapper = (PMC_DH_OrderFetchWrapper)JSON.deserialize(editWrapper.responseData, PMC_DH_OrderFetchWrapper.Class);
            Map<String,PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> mapLineIdOriginalPayload = getMapLineIdOriginalPayload(responseWrapper.lstData,editWrapper);
            PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper wrapData = mapLineIdOriginalPayload.get(editWrapper.strOrderLineId);
            Map<String,ProductPriceAndSubs> mapOfContractDetails=getContractItemNo(wrapData.strContractFinalized);
            ProductPriceAndSubs wrapProdPriceSub=new ProductPriceAndSubs();
            String strGetKey='';
            if(cartItems[0].PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c==true){
                reqWrap.strProtocolNo = cartItems[0].PMC_DH_ProtocolNumber__c;
                strGetKey=wrapData.strMaterial+wrapData.strIncotterms+wrapData.strMot+wrapData.strPlant;
                // added as part of GDASF-19767
                //reqWrap.strShipTo = (getShipToIdOrAccIdentifier(cartItems[0])).get('strShipTo');
                //reqWrap.strAccIdentifier = (getShipToIdOrAccIdentifier(cartItems[0])).get('strAccIdentifier');
                reqWrap = getShipToIdOrAccIdentifier(cartItems[0] ,reqWrap);
            }
            else
            {
                reqWrap.strShipTo = wrapData.strShiptoId; //ci.PMC_DH_ShipTo__r.PMC_SS_AccountExternalID__c;
                strGetKey=wrapData.strMaterial+wrapData.strShiptoId+wrapData.strIncotterms+wrapData.strMot+wrapData.strPlant;
            }
            // end of changes added as part of GDASF-19767
            if(mapOfContractDetails.containsKey(strGetKey)){
                wrapProdPriceSub=mapOfContractDetails.get(strGetKey);
            }//key=SKU+SHIPTO+INCOTERM+MOT+PLANT
            reqWrap.strReqId= editWrapper.strOrderLineId ;
            reqWrap.strPlant= wrapData.strPlant;//'4000';
            reqWrap.strCustomerId = wrapData.strSoldtoId;//ci.cart.PMC_DH_Account__r.PMC_SS_AccountExternalID__c;
            reqWrap.strMaterial=wrapData.strMaterial;//ci.Product2.StockKeepingUnit ;//'FFALM';
            reqWrap.strIncoterms=wrapData.strIncotterms;//ci.PMC_DH_Incoterms__c;//'FOB';
            reqWrap.strCreatedBy=wrapData.strCreateBy;//ci.cart.CreatedBy.Name;
            reqWrap.strCreatedVia=APP_NAME;
            //reqWrap.strCreatedOn=wrapData.strCreatedOn;//String.valueOf(System.today());
            reqWrap.strNfeCoopCustomer=String.ValueOf(cartItems[0].PMC_DH_NotaFiscalNumber__c);//'';
            reqWrap.strNFEBillingDate=cartItems[0].PMC_DH_NotaFiscalDate__c != Null?formatRequestedDate(String.ValueOf(cartItems[0].PMC_DH_NotaFiscalDate__c)):'';
            reqWrap.strGenPricePerunit=String.valueOf(wrapProdPriceSub.decPrice);
            reqWrap.strCustomerReqQty=editWrapper.strReqQty;//String.ValueOf(ci.Quantity);
            reqWrap.strTotPrice=String.valueOf(Double.valueOf(editWrapper.strReqQty)*wrapProdPriceSub.decPrice);//GPT-32983
            reqWrap.strReqDelDat=editWrapper.strReqShipmentDate != Null?formatRequestedDate(String.ValueOf(editWrapper.strReqShipmentDate)):'';
            reqWrap.strContractItemNo=wrapProdPriceSub.strContractItemNumber;//ci.PMC_DH_Subscription__r.Name;
            reqWrap.strProtocolPrice=String.valueOf(cartItems[0].PMC_DH_SellOutPrice__c);//Third party scenarios
            reqWrap.strDelInstr=cartItems[0].PMC_DH_DeliveryInstructions__c;//Third party scenarios
            reqWrap.strMot=wrapData.strMot;//ci.PMC_DH_DeliveryMode__c;
            reqWrap.strPoNo=wrapData.strPoNumber;//ci.PMC_DH_DeliveryPONumber__c;
            reqWrap.strPaymentTermsn=cartItems[0].PMC_DH_Contract__r.SBQQ__Quote__r.SBQQ__PaymentTerms__c;
            reqWrap.strSelfConsInd=selfConsumptionIndicator(cartItems);
            reqWrap.strCutomerMaterial=wrapData.strCustMatnr;
            reqWrap.strContractReq = wrapData.strContractFinalized;
            reqWrap.strUnitOfMeasure= cartItems[0].PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_UnitofMeasure__c;
            
            //reqWrap.strShipTo=wrapData.strShiptoId;//ci.PMC_DH_ShipTo__r.PMC_SS_AccountExternalID__c;
            
            reqWrap.strPackingType = wrapData.strPackingType;//(PMC_DH_CommerceCartQueryUtilsClass.getPackOrPackageType(wrapData.strPackType,wrapData.strPackingType)).get('strPackageType');
            reqWrap.strPackType = '';//(PMC_DH_CommerceCartQueryUtilsClass.getPackOrPackageType(wrapData.strPackType,wrapData.strPackingType)).get('strPackType');

               
            //GSMD-2109//
            String amendmentQuoteName =  cartItems[0].PMC_DH_Contract__r.PMC_CPQ_LatestQuote__r.Name;
            String quoteLineName =  cartItems[0].PMC_DH_Subscription__r.Name;
            String strAmendmentQuoteNumber = (amendmentQuoteName != null && amendmentQuoteName.startsWith('Q-')) ? amendmentQuoteName.replace('Q-', '') : amendmentQuoteName;
            String strQuoteLineNumber = (quoteLineName != null && quoteLineName.startsWith('SUB-')) ? quoteLineName.replace('SUB-', '') : quoteLineName;
            
            reqWrap.strAmendmentQuoteNumber = strAmendmentQuoteNumber;
            reqWrap.strQuoteLineNumber = strQuoteLineNumber;    //GSMD-2109//
        }
        lstReqWrap.add(reqWrap);
        ordReqWrapper.lstResultData = lstReqWrap;
        return JSON.serialize(ordReqWrapper);
    }
    
    private static String selfConsumptionIndicator(List<CartItem> lstCartItem)
    {
        String strIndicator='';
        if( !lstCartItem.isEmpty() && (lstCartItem[0].PMC_DH_ShipTo__r.PMC_SS_Channel__c==PMC_DH_ConstantClass.COOPERATIVE_CHNL ||
                                       lstCartItem[0].PMC_DH_ShipTo__r.Type==PMC_DH_ConstantClass.SOLD_TO)
           && lstCartItem[0].PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c==true)
        { 
            strIndicator=PMC_DH_ConstantClass.SELF_CONSMPT_X;
        }
        return strIndicator;
    }
    /**
* @description  method to get map of Contract item number and price per unit cost
* @author  Mosaic Direct Dev 
* @param  strContractNumber
* @return Map<String,ProductPriceAndSubs>
**/ 
    //changelog : GPT-28361 | get price per unit , contract item number
    public static Map<String,ProductPriceAndSubs> getContractItemNo(String strContractNumber){
        Map<String,ProductPriceAndSubs> mapOfProductToPriceAndSubs=new Map<String,ProductPriceAndSubs>(); //key=SKU+SHIPTO+INCOTERM+MOT+PLANT
        List<SBQQ__Subscription__c> lstSubs= [ Select id, PMC_CPQ_SubscriptionNumberIdentifier__c, SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c,SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit,SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c,SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c,
                                              SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_SS_SAPCustomerNumber__c,SBQQ__QuoteLine__r.PMC_CPQ_FinalPricePerTonne__c, SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c from SBQQ__Subscription__c 
                                              where SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c=:strContractNumber WITH SECURITY_ENFORCED];
        
        for (SBQQ__Subscription__c sub : lstSubs) {
            ProductPriceAndSubs wrapProdPriceSub=new ProductPriceAndSubs();
            wrapProdPriceSub.strContractItemNumber=sub.PMC_CPQ_SubscriptionNumberIdentifier__c;
            wrapProdPriceSub.decPrice=sub.SBQQ__QuoteLine__r.PMC_CPQ_FinalPricePerTonne__c;
            String strKey=sub.SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit+sub.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c+sub.SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c+sub.SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c;
            if(!sub.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c) {
                strKey=sub.SBQQ__QuoteLine__r.SBQQ__Product__r.StockKeepingUnit+sub.SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.PMC_SS_SAPCustomerNumber__c+sub.SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c+sub.SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c+sub.SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.PMC_CPQ_Plant__c;
            }
            mapOfProductToPriceAndSubs.put(strKey,wrapProdPriceSub);
        }
        return mapOfProductToPriceAndSubs;
        
    }
    
    /**
* @description  method to get mapLineId Original Payload
* @author  Mosaic Direct Dev 
* @param  responseWrapper
* @param  editWrapper
* @return Map<String,PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>
**/   
    public static Map<String,PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> getMapLineIdOriginalPayload(List<PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> responseWrapper, PMC_DH_RequestedOrderEditController.editRequestWrapper editWrapper){
        
        Map<String,PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper> mapLineIdOriginalPayload = new Map<String,PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper>();
        
        for(PMC_DH_OrderFetchWrapper.PMC_DH_ResponseWrapper responseWrap : responseWrapper){
            if(!mapLineIdOriginalPayload.containsKey(editWrapper.strOrderLineId)){
                mapLineIdOriginalPayload.put(responseWrap.strReqId, responseWrap);
            }
        }
        return mapLineIdOriginalPayload;
    }
    
    /*************************************************************************
* @method Name  : QuoteInfoWrapper
* @description  : Wrapper class for quote Info
*****************************************************************************/
    public with sharing class ProductPriceAndSubs{
        /**
* @description Quote ID
* @return  String 
*/
        public Decimal decPrice{get;set;}
        /**
* @description Quote Number
* @return  String 
*/
        public String strContractItemNumber{get;set;}
    }
}