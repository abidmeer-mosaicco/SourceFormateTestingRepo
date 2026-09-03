/** 
* @description Helper class for Order Management 
* @author Manisha
* @last modified on 2023-Dec-08
* @last modified by Manisha
* Created On       :2023-Dec-08
**/
public without sharing class PMC_DH_OrderManagementUtil {
    
    private static final String NORTH_AMERICA_REGION = 'Domestic NA';
    private static final String SOUTH_AMERICA_REGION = 'Domestic SA';
    
    /*************************************************************************
* @method Name  : getCartItemTotalPrice
* @description : Method to calculate total price of order item
* @param        objPriceQuantityWrapper
* @param        objCartItem
*****************************************************************************/
    public static void getCartItemTotalPrice(PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper objPriceQuantityWrapper,CartItem objCartItem){
        if ((objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_QuoteRecordType__c == NORTH_AMERICA_REGION) && (objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_CustomerPrice__c != null) && (objCartItem.Quantity != null)) {
            objPriceQuantityWrapper.decPrice = objPriceQuantityWrapper.decPrice + (objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_CustomerPrice__c * objCartItem.Quantity.longValue());// GDASF-10697
        }
        if ((objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_QuoteRecordType__c == SOUTH_AMERICA_REGION) && (objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_FinalPricePerTonne__c != null) && (objCartItem.Quantity != null)) {
            objPriceQuantityWrapper.decPrice = objPriceQuantityWrapper.decPrice + (objCartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_FinalPricePerTonne__c * objCartItem.Quantity.longValue());// GDASF-10697
        }
    }
    
    /*************************************************************************
* @method Name  : getLstQuoteLine
* @description : Method to get list of quote lines
* @param        lstQuoteLine
* @return       List<PMC_DH_PricingDetailWrapper.PMC_DH_QuoteLineWrapper>
*****************************************************************************/
    public static List<PMC_DH_PricingDetailWrapper.PMC_DH_QuoteLineWrapper> getLstQuoteLine(List<SBQQ__QuoteLine__c> lstQuoteLine){
        List<PMC_DH_PricingDetailWrapper.PMC_DH_QuoteLineWrapper> lstCartLineItem = new List<PMC_DH_PricingDetailWrapper.PMC_DH_QuoteLineWrapper>();
        for(SBQQ__QuoteLine__c objQuoteLine : lstQuoteLine){
            PMC_DH_PricingDetailWrapper.PMC_DH_QuoteLineWrapper objCartLineItem = new PMC_DH_PricingDetailWrapper.PMC_DH_QuoteLineWrapper();
            //Added as part of GPT-16862
            if ((objQuoteLine.PMC_CPQ_QuoteRecordType__c =='Domestic NA') && (objQuoteLine.PMC_CPQ_CustomerPrice__c != null)) {
                objCartLineItem.strQuoteLineId = objQuoteLine.Id;
                objCartLineItem.decPrice = objQuoteLine.PMC_CPQ_CustomerPrice__c.setScale(2, RoundingMode.HALF_UP);
            }
            //Added as part of GPT-16862
            if ((objQuoteLine.PMC_CPQ_QuoteRecordType__c =='Domestic SA') && (objQuoteLine.PMC_CPQ_FinalPricePerTonne__c != null)) {
                objCartLineItem.strQuoteLineId = objQuoteLine.Id;
                objCartLineItem.decPrice = objQuoteLine.PMC_CPQ_FinalPricePerTonne__c.setScale(2, RoundingMode.HALF_UP); 
            }
            lstCartLineItem.add(objCartLineItem);
        }
        return lstCartLineItem;
    }
    
    /*************************************************************************
* @method Name  : updatePriceAndQuantity
* @description : Method to update price and quantity fields
* @param        objPriceQuantityWrapper
* @param        objQuoteLine

*****************************************************************************/
    public static void updatePriceAndQuantity(PMC_DH_OrderManagementController.PMC_DH_PriceQuantityWrapper objPriceQuantityWrapper, SBQQ__QuoteLine__c objQuoteLine){
        //Added as part of GPT-16862
        if (objQuoteLine.PMC_CPQ_LineTotalPrice__c != null) {
            objPriceQuantityWrapper.decPrice =objPriceQuantityWrapper.decPrice + objQuoteLine.PMC_CPQ_LineTotalPrice__c; 
        }
        if(objQuoteLine.SBQQ__Quantity__c != null){
            objPriceQuantityWrapper.intQuantity = objPriceQuantityWrapper.intQuantity + objQuoteLine.SBQQ__Quantity__c.longValue();// GDASF-10697    
        }       
    } 
    
    /*************************************************************************
* @method Name  : getProtocolNo
* @description : Method to get Protocol Identifier for orderItem
* @param        order
* @return        String
*****************************************************************************/    
    //GDASF-21528
    public static String getProtocolNo(Order order){
        Set<String> setProtocolNo=new Set<String>();
        for(OrderItem oi:order.orderItems){
            if(oi.PMC_DH_RequestNumber__c!=null && oi.PMC_DH_ProtocolIdentifier__c!=null){
                setProtocolNo.add(oi.PMC_DH_ProtocolIdentifier__c);
            }
        }
        List<String> lstProtocolNo=new List<String>(setProtocolNo);
        if(lstProtocolNo.size()>0) {
            return lstProtocolNo.get(0);
        }
        return '';
    }
    /*************************************************************************
* @method Name  : getRequestNo
* @description : Method to get Request Id for OrderItem
* @param        order
* @return        Set<String>

*****************************************************************************/
    //GDASF-21528
    public static Set<String> getRequestNo(Order order){
        Set<String> setReqIds=new set<String>();
        for(OrderItem oi:order.orderItems){
            if(oi.PMC_DH_RequestNumber__c!=null){
                List<String> lstReqSplit=oi.PMC_DH_RequestNumber__c.split(';');
                if(!lstReqSplit.isEmpty()){
                    for(String strReqId:lstReqSplit){
                        Integer str=strReqId.indexOf('-',strReqId.indexof('-')+1);
                        String strReq=strReqId.substring(0,str);
                        setReqIds.add(strReq);
                    }
                }
              }
        }
        return setReqIds;
    }
}