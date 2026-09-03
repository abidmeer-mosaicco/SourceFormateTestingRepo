/**
* @description       : Controller for cart validation
* @author            : @Nikhilesh Mohanty
* @group             : 
* @last modified on  : 06-25-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public with sharing class PMC_DH_CartValidationController {

    
    /*************************************************************************
* @method Name  : WrapCartDetail
* @description  :  wrapper class for variables
*****************************************************************************/
public class WrapCartDetail{
    public Set<String>srcValues;
    public set<String>setContNum;
    public Set<String>  setRFQProducts;
    public Set<String>  setDeliveryMode;
    public Set<String>  setContractType;
    public Set<Boolean> setVCO;
    public String  effAccRecId;
    public Set<Boolean> setProdStatus;
    public Integer intFlagCheck;
    }
    /*************************************************************************
* @method Name  : WrapperDetail
* @description  :  wrapper class for variables
*****************************************************************************/ 
public class WrapperDetail{
    public Set<String> setProdSource;
    public WrapWarnings wrpWarning; // added as a fix for 'too many field' violation
    public Set<String> setRFQProducts;
    public Set<String> setInactProd;
    public Set<String> setContractNumb;
    public String effAccRecId;
    public Set<String> setDeliveryModes;
    public Set<String> setContractTypes;
    public Set<Boolean> setVCO;
    public List<CartItem> lstCartitems;
    public CartItem cartItem;
    public CartValidationWrapper wrpChild;
    public List<CartValidationWrapper> lstValidationWrapper;
    public Integer intFlagCheck;
    public Set<Boolean> setProdStatus;
    
}
/**
 * @method Name  : WrapWarnings
* @description  :  wrapper class for Warning attributes
 */
public class WrapWarnings   // added as a fix for 'too many field' violation
    {
        public Boolean hasErrors;
        public Boolean hasWarnings;  
}

/*************************************************************************
* @method Name  : CartValidationParentWrapper
* @description  : Parent wrapper class for Cart Validation
*****************************************************************************/
public class CartValidationParentWrapper {

   

    /**
     * @description Contract Id
     * @return 		String
    **/
    @AuraEnabled
    public String strContractId{get;set;}

    /**
     * @description Source of cart item
     * @return 		String
    **/
    @AuraEnabled 
    public String strSource{get;set;}
    /**
     * @description Boolean variable to show whether cart item has errors
     * @return 		Boolean
    **/
    @AuraEnabled 
    public Boolean boolHasErrors{get;set;}
    /**
     * @description Boolean variable to show whether cart item has warning
     * @return 		Boolean
    **/
    @AuraEnabled 
    public Boolean boolHasWarnings{get;set;}

    /**
     * @description string
     * @return 		String
    **/
    @AuraEnabled 
    public String strSubjError{get;set;}

    /**
     * @description string
     * @return 		String
    **/
    @AuraEnabled 
    public String strFooterErr{get;set;}

    /**
     * @description List of CartValidationWrapper items
     * @return 		List<CartValidationWrapper>
    **/
    @AuraEnabled 
    public List<CartValidationWrapper> lstCartValidationWrapper{get;set;}

    /**
    * @description Status Code and message
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
}
/*************************************************************************
* @method Name  : CartValidationWrapper
* @description  : Wrapper class for Cart Validation
*****************************************************************************/
public class CartValidationWrapper {

    /**
     * @description CartItem Id
     * @return 		String
    **/
    @AuraEnabled 
    public String strCartItemId{get;set;}


    /**
     * @description Product SKU
     * @return 		String
    **/
    @AuraEnabled 
    public String strSku{get;set;}
    /**
     * @description Product Name
     * @return 		String
    **/
    
    @AuraEnabled 
    public String strName{get;set;}
    
    
    /**
     * @description Flow Message
     * @return 		String
    **/
    @AuraEnabled 
    public String strFlow{get;set;}
    
}




        /*************************************************************************
* @method Name  : validateCart
* @description  : Method to validate if cart is error free
* @param        strCartId
* @return       : String
*****************************************************************************/
@AuraEnabled 
public static CartValidationParentWrapper validateCart(String strCartId) {
    
    CartValidationParentWrapper wrpFlag=new CartValidationParentWrapper();
    WrapCartDetail wrapCart = new WrapCartDetail();
    wrapCart.srcValues=new Set<String>();
    wrapCart.setContNum=new Set<String>();
    wrapCart.setRFQProducts =new Set<String>();
    wrapCart.setDeliveryMode =new Set<String>();
    wrapCart.setContractType =new Set<String>();
    wrapCart.setVCO=new Set<Boolean> ();
    wrapCart.setProdStatus=new Set<Boolean> ();
    wrapCart.effAccRecId = '';
    try {
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        
        List<CartItem>lstCartItems=[SELECT ID, Product2Id, Cart.AccountId, Product2.StockKeepingUnit, Product2.IsActive, PMC_DH_Source__c, 
                                    PMC_DH_Contract__c,toLabel(PMC_DH_DeliveryMode__c),toLabel(PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c),
                                    PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c,PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c,
                                    PMC_DH_Subscription__r.SBQQ__Account__r.RecordType.name
                                    FROM CartItem WHERE Cart.Id=: strCartId WITH SECURITY_ENFORCED];
        for(CartItem ci: lstCartItems) {
            wrapCart.srcValues.add(ci.PMC_DH_Source__c);
            wrapCart.setContNum.add(ci.PMC_DH_Contract__c);
            wrapCart.setVCO.add(ci.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c);
            wrapCart.setProdStatus.add(ci.Product2.isActive);
            
            if(ci.PMC_DH_Source__c == PMC_DH_ConstantClass.RFQ){
                wrapCart.setRFQProducts.add(ci.Product2Id);
                wrapCart.effAccRecId=  ci.Cart.AccountId;
            }else{
                wrapCart.setDeliveryMode.add(ci.PMC_DH_DeliveryMode__c);
                wrapCart.setContractType.add(ci.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c);
            }
        }

            wrpFlag = getCartWrapDetail(wrapCart,lstCartItems,wrpFlag);
        
    }
    catch(Exception ex) {
        wrpFlag.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); 
        PMC_ErrorLogClass.processException(ex); // MDErrorLog
    }
    return wrpFlag;
}

 
private static boolean mixedContractsCheck(Set<String> setProdSource, Set<String> setInactProd, Set<String> setContractNumb )
{
    return ((setProdSource.size()==1) && (setProdSource.contains(PMC_DH_ConstantClass.RTD)) && (setInactProd.isEmpty()) && (setContractNumb.size()>1));
}

private static boolean mixedFlowCheck(Set<String> setProdSource,Set<String> setInactProd,WrapperDetail wrpDetail)
{
    return ((setProdSource.size()>1)  && setInactProd.isEmpty() && wrpDetail.intFlagCheck!=1);
}
private static boolean checkDeliveryModes(Set<String> setDeliveryModes, Integer intFlag)
{
    return (setDeliveryModes.size()>1 && intFlag!=1 );
}
private static boolean checkContractTypesBool(Set<String> setContractTypes,Integer intFlag)
{
    return (setContractTypes.size()>1 && intFlag!=1 );
}
private static void getInactiveValid(WrapperDetail wrpDetail,CartValidationParentWrapper wrp,CartValidationWrapper wrpChild)
    {
        if(wrpDetail.setProdStatus.size()>=2 ||wrpDetail.setProdStatus.contains(FALSE) ) {
            wrpDetail.wrpWarning.hasErrors=TRUE;
            wrp.strSubjError=String.ValueOf(Label.PMC_DH_ProdNotAvail);
            wrp.strFooterErr=String.ValueOf(Label.PMC_DH_ProdUnvldFooterMsg);
            wrpDetail.intFlagCheck=1;
            if(!(wrpDetail.cartItem.Product2.isActive))
            {
            wrpDetail.setInactProd.add(wrpDetail.cartItem.Product2Id);
            wrpChild.strFlow=PMC_DH_ConstantClass.BLANK_STRING;
            wrpDetail.lstValidationWrapper.add(wrpChild);
            
            }
        }
    }
	@testVisible
    private static String getFlowName(Map<String,Set<String>> productSKUContractMap, String sku){
        String strFlow= '';
        if(productSKUContractMap.get(sku).size()>1){
            strFlow  = System.label.pmc_requestToDeliverShippingInformation_multiple + ' ' + System.label.pmc_quoteDetailsFlow_contracts;//PMC_DH_ConstantClass.MULTIPLE_CONTRACT;
        }else{
            strFlow = System.label.pmc_contractDetails_contract+PMC_DH_ConstantClass.CONTRACTNUM + new List<String>(productSKUContractMap.get(sku))[0];
        }
        return strFlow;
    }
    private static CartValidationParentWrapper getCartWrapDetail(WrapCartDetail wrapCart,List<CartItem> lstCartItems,CartValidationParentWrapper wrpFlag){
        Map<String,Set<String>> productSKUContractMap = getMapValues(wrapCart.setRFQProducts, wrapCart.effAccRecId);
        
        for(CartItem ci: lstCartItems) {
            wrpFlag.strSource=ci.PMC_DH_Source__c;
            wrpFlag.boolHasWarnings=FALSE;
            wrpFlag.boolHasErrors=FALSE;  
            wrpFlag.strContractId=getContractId(wrapCart.setContNum);
            wrapCart.intFlagCheck=0;
            if(prodValidation(wrapCart.setProdStatus,wrapCart.srcValues,wrapCart.setContNum) )
            {
                wrpFlag.boolHasWarnings=FALSE;
                wrpFlag.boolHasErrors=TRUE;
                wrapCart.intFlagCheck=1;
                break;
            }
            else if(productSKUContractMap.ContainsKey(ci.Product2.StockKeepingUnit)){
                wrpFlag.boolHasWarnings=TRUE;
                wrpFlag.boolHasErrors=FALSE;
                wrapCart.intFlagCheck=2;
                break;
            }
            else if(checkDeliveryModes(wrapCart.setDeliveryMode,wrapCart.intFlagCheck))
            {
                wrpFlag.boolHasWarnings=FALSE;
                wrpFlag.boolHasErrors=TRUE;
                break;
            }
            else if(checkContractTypesBool(wrapCart.setContractType,wrapCart.intFlagCheck))
            {
                wrpFlag.boolHasWarnings=FALSE;
                wrpFlag.boolHasErrors=TRUE;
                break;
            }
            else if(wrapCart.setVCO.size()==2 )
            {
                    wrpFlag.boolHasWarnings=TRUE;
                    wrpFlag.boolHasErrors=TRUE;
                    break;
                }
            }
            wrpFlag.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.CART_VALIDATE_SUCCESS_MODULE);
        
        return wrpFlag;
    }

private static boolean prodValidation(Set<Boolean> setProdStatus, Set<String> srcValues,Set<String>  setContNum)
{ 
    
    return ((setProdStatus.contains(False) ) || (srcValues.size()>1)|| (setContNum.size()>1));
}
/**
 * @description method for cart page validation
 * @since 07-15-2023
 * @author hegoswami@deloitte.com
 * @param strCartId 
 * @return          `List<CartValidationParentWrapper>`
 */

    @AuraEnabled 
    public static CartValidationParentWrapper cartPageValidation(String strCartId) {
    WrapperDetail wrpDetail = new WrapperDetail();
    WrapWarnings wrpWarning =new WrapWarnings();
    wrpWarning.hasErrors=false;
    wrpWarning.hasWarnings=false;
    wrpDetail.wrpWarning=wrpWarning;
    wrpDetail.setProdSource = new Set<String>();
    wrpDetail.setRFQProducts = new Set<String>();
    wrpDetail.setDeliveryModes = new Set<String>();
    wrpDetail.setInactProd = new Set<String>();
    wrpDetail.setContractNumb = new Set<String>();
    wrpDetail.setContractTypes = new Set<String>();
    wrpDetail.setVCO=new Set<Boolean>();
    wrpDetail.setProdStatus=new Set<Boolean>();
    wrpDetail.lstValidationWrapper=new List<CartValidationWrapper>();
    
    
    CartValidationParentWrapper wrp = new CartValidationParentWrapper();
    try {

        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        List<CartItem>lstCartItems=[SELECT Id, sku, Name, Product2.StockKeepingUnit, Product2Id, Cart.AccountId,toLabel(PMC_DH_DeliveryMode__c),
                                    toLabel(PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c),
                                    Product2.IsActive, PMC_DH_Source__c, PMC_DH_Contract__r.Id, Product2.Name, PMC_DH_Contract__r.CONTRACTNUMBER,
                                    PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c,PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c,
                                    PMC_DH_Subscription__r.SBQQ__Account__r.RecordType.name
                                    FROM CartItem WHERE Cart.Id=: strCartId WITH SECURITY_ENFORCED ORDER BY product2.IsActive asc, PMC_DH_Source__c];
        wrpDetail.lstCartitems=lstCartItems;
        for(CartItem cItem: lstCartItems) {
            wrpDetail.setProdSource.add(cItem.PMC_DH_Source__c);
            wrpDetail.setVCO.add(cItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_VCOQuotation__c);
            wrpDetail.setProdStatus.add(cItem.Product2.isActive);
            if(cItem.PMC_DH_Source__c==PMC_DH_ConstantClass.RTD) {
                wrpDetail.setContractNumb.add(cItem.PMC_DH_Contract__r.Id);
                wrpDetail.setDeliveryModes.add(cItem.PMC_DH_DeliveryMode__c);
                wrpDetail.setContractTypes.add(cItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c);
                
            }else{
                wrpDetail.setRFQProducts.add(cItem.Product2Id);
                wrpDetail.effAccRecId=cItem.Cart.AccountId;
            }
        }
        wrp.lstCartValidationWrapper=getWrapDetail(wrpDetail,wrp);
        wrp.strSource=lstCartItems[0].PMC_DH_Source__C;
        wrp.strContractId=getContractId(wrpDetail.setContractNumb);
        wrp.boolHasErrors=wrpDetail.wrpWarning.hasErrors;
        wrp.boolHasWarnings = wrpDetail.wrpWarning.hasWarnings;
        wrp.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.CART_VALIDATE_SUCCESS_MODULE);
    }
    catch(Exception ex) {
        wrp.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); 
        PMC_ErrorLogClass.processException(ex); // MDErrorLog
    }
    return wrp;
    
}

    private static String getContractId(Set<String> setContractNumb)
    {   String strReturn;
        if(setContractNumb.size()==1)
        {
        strReturn=new List<String>(setContractNumb).get(0);
        
    }
    return strReturn;
}

   

    /*************************************************************************
* @method Name  : getMapValues
* @description  : Method to get Product to Sku map
* @param         setRFQProducts
* @param         effAccRecId
* @return       : Map<String,Set<String>>
*****************************************************************************/
        private static Map<String,Set<String>> getMapValues(Set<String> setRFQProducts, String effAccRecId){
        Map<String,Set<String>> productSKUContactMap = new Map<String,Set<String>>();
        List<SBQQ__Subscription__c> lstSub=[SELECT Id,SBQQ__Product__r.StockKeepingUnit,SBQQ__Contract__r.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c FROM SBQQ__Subscription__c  
                                            Where SBQQ__Product__c IN : setRFQProducts AND SBQQ__Contract__r.AccountId=:effAccRecId AND SBQQ__Contract__r.EndDate >= TODAY 
                                            AND PMC_CPQ_TotalAvailableQuantity__c > 0 WITH SECURITY_ENFORCED  ORDER by SBQQ__Contract__r.CONTRACTNUMBER];
        for(SBQQ__Subscription__c sub : lstSub){
            if(!productSKUContactMap.containsKey(sub.SBQQ__Product__r.StockKeepingUnit)){
                productSKUContactMap.put(sub.SBQQ__Product__r.StockKeepingUnit, new Set<String>());
            }
            productSKUContactMap.get(sub.SBQQ__Product__r.StockKeepingUnit).add(sub.SBQQ__Contract__r.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c);
        }
            return productSKUContactMap;
        }
    
    
    /**
    * @description 
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 11-07-2023 
    * @param wrpDetail 
    * @param wrp 
    * @return List<CartValidationWrapper> 
    **/
    private static List<CartValidationWrapper> getWrapDetail(WrapperDetail wrpDetail,CartValidationParentWrapper wrp){
        Map<String,Set<String>> productSKUContractMap = getMapValues(wrpDetail.setRFQProducts, wrpDetail.effAccRecId);
        List<CartValidationWrapper> lstCartwrp = new List<CartValidationWrapper>();
        wrpDetail.intFlagCheck=0;
        wrpDetail.wrpWarning=new WrapWarnings();
        for(CartItem cItem:wrpDetail.lstCartItems) {
            CartValidationWrapper wrpChild=new CartValidationWrapper();
            wrpDetail.cartItem=cItem;
            wrpChild.strCartItemId=cItem.Id;
            wrpChild.strName=cItem.Product2.Name;
            wrpChild.strSku=cItem.Product2.StockKeepingUnit;
            wrpDetail.wrpChild=wrpChild;
            getInactiveValid(wrpDetail,wrp,wrpChild);
            lstCartwrp=wrpDetail.lstValidationWrapper;
            if(mixedContractsCheck(wrpDetail.setProdSource, wrpDetail.setInactProd,  wrpDetail.setContractNumb) && wrpDetail.intFlagCheck!=1  ) {
                wrpDetail.wrpWarning.hasErrors=TRUE;
                wrpChild.strFlow=System.label.pmc_contractDetails_contract+PMC_DH_ConstantClass.CONTRACTNUM+cItem.PMC_DH_Contract__r.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c;
                wrp.strSubjError=String.ValueOf(Label.PMC_DH_DiffContrctErrMsg);
                wrp.strFooterErr=String.ValueOf(Label.PMC_DH_MixedcontrErr);
                lstCartwrp.add(wrpChild);
                wrpDetail.intFlagCheck=2; 
            }

            else if(mixedFlowCheck(wrpDetail.setProdSource,wrpDetail.setInactProd,wrpDetail)  ) {
            
                wrpDetail.wrpWarning.hasErrors=TRUE;
                wrp.strSubjError=String.ValueOf(Label.PMC_DH_MixedQtContrct);
                wrp.strFooterErr=String.ValueOf(Label.PMC_DH_MxedFlowFooterErr);
                wrpChild.strFlow=cItem.PMC_DH_Source__c;
                lstCartwrp.add(wrpChild);
                wrpDetail.intFlagCheck=2;
                
            }
            else if(PMC_DH_CartValidationUtil.prodContractValid(productSKUContractMap,cItem,wrpDetail))//productSKUContractMap.ContainsKey(cItem.Product2.StockKeepingUnit) ) {
            { 
                wrpDetail.wrpWarning.hasWarnings=TRUE;
                wrpChild.strFlow= getFlowName(productSKUContractMap,cItem.Product2.StockKeepingUnit);
                wrp.strSubjError=String.ValueOf(Label.PMC_DH_Checkout_Warning_Msg);
                wrp.strSource=PMC_DH_ConstantClass.RFQ;
                lstCartwrp.add(wrpChild);
                wrpDetail.intFlagCheck=2; 
            
            }
            else if(checkDeliveryModes(wrpDetail.setDeliveryModes,wrpDetail.intFlagCheck) ) {
            
                wrpDetail.wrpWarning.hasErrors=TRUE;
                wrpChild.strFlow= cItem.PMC_DH_DeliveryMode__c;
                wrp.strSubjError=String.ValueOf(Label.PMC_DH_Diff_Delivery_Modes);
                wrp.strFooterErr=String.ValueOf(Label.PMC_DH_Delivery_Modes_Footer);
                wrp.strSource=PMC_DH_ConstantClass.RTD;
                lstCartwrp.add(wrpChild);
                wrpDetail.intFlagCheck=2;
            }
            else if(checkContractTypesBool(wrpDetail.setContractTypes,wrpDetail.intFlagCheck)) {
            
                wrpDetail.wrpWarning.hasErrors=TRUE;
                wrpChild.strFlow=cItem.PMC_DH_Subscription__r.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c;
                wrp.strSubjError=String.ValueOf(Label.PMC_DH_Diff_Contract_Type);
                wrp.strFooterErr=String.ValueOf(Label.PMC_DH_Contract_Type_footer);
                wrp.strSource=PMC_DH_ConstantClass.RTD;
                lstCartwrp.add(wrpChild);
                wrpDetail.intFlagCheck=2;
                
            }
            PMC_DH_CartValidationUtil.validateVCO(wrpDetail,wrp,lstCartwrp);
        
        }
        return lstCartwrp;
    }
    
}