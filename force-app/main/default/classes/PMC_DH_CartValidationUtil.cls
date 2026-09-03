/**
 * @description       : 
 * @author            : Hemant Giri Goswami | hegoswami@deloitte.com
 * @group             : 
 * @last modified on  : 02-13-2024
 * @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public without sharing class PMC_DH_CartValidationUtil {
    
    /**
    * @description 
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 11-07-2023 
    * @param wrpDetail 
    * @param wrp 
    * @param lstCartwrp 
    **/
    public static void validateVCO(PMC_DH_CartValidationController.WrapperDetail wrpDetail,PMC_DH_CartValidationController.CartValidationParentWrapper wrp,List<PMC_DH_CartValidationController.CartValidationWrapper> lstCartwrp)
    {
    if(wrpDetail.setVCO.size()==2 && wrpDetail.intFlagCheck==0) 
            {
                wrpDetail.wrpWarning.hasErrors=TRUE;
                wrpDetail.wrpChild.strCartItemId=wrpDetail.cartItem.Id;
                wrpDetail.wrpChild.strSku=wrpDetail.cartItem.Product2.StockKeepingUnit;
                wrpDetail.wrpChild.strFlow=getDeliveryType(wrpDetail.cartItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c);
                wrp.strSubjError=String.ValueOf(Label.PMC_DH_DiffDeliveryErrorMsg);
                wrp.strFooterErr=String.ValueOf(Label.PMC_DH_FooterDiffDelivery);
                wrp.strSource=PMC_DH_ConstantClass.RTD;
                lstCartwrp.add(wrpDetail.wrpChild);
            
            }
    }


private static String getDeliveryType(Boolean boolVCO)
{    String strDelivery=String.ValueOf(Label.PMC_DH_StandardDelivery);
        if(boolVCO)
        {
            strDelivery=String.ValueOf(Label.PMC_DH_ThirdPartyDelivery);
        }
        return strDelivery;
}


/**
* @description prodContractValid
* @author Hemant Giri Goswami | hegoswami@deloitte.com | 01-30-2024 
* @param productSKUContractMap 
* @param cItem 
* @param wrpDetail 
* @return Boolean 
**/
public static Boolean prodContractValid(Map<String,Set<String>> productSKUContractMap,CartItem cItem, PMC_DH_CartValidationController.WrapperDetail wrpDetail )
    {
        return (productSKUContractMap.ContainsKey(cItem.Product2.StockKeepingUnit) && wrpDetail.intFlagCheck!=1 );
    }



    /**
    * @description 
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 03-06-2024 
    * @param mapShipFrom 
    * @param quoteLineObjRecord 
    **/
    public static void mapCreationShipTo(Map<String,PMC_DH_AddressWrapper.AddressViewDetails> mapShipFrom,SBQQ__QuoteLine__c quoteLineObjRecord)
{
    PMC_DH_AddressWrapper.AddressViewDetails wrpAddress;
    
    if(!mapShipFrom.containsKey(quoteLineObjRecord.id))
                {
                    wrpAddress=new PMC_DH_AddressWrapper.AddressViewDetails();
                    wrpAddress.strCity=quoteLineObjRecord.PMC_CPQ_Shipto__r.ShippingCity;
                    wrpAddress.strState=quoteLineObjRecord.PMC_CPQ_Shipto__r.ShippingState;
                    mapShipFrom.put(quoteLineObjRecord.PMC_CPQ_Shipto__c,wrpAddress);
                }
            
}
}