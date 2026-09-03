/**
* @description       : 
* @author            : Hemant Giri Goswami | hegoswami@deloitte.com
* @group             : 
* @last modified on  : 04-05-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class PMC_DH_RequestForQuoteUtil {
    public static Boolean throwTestException=false;
    
    /**
* @description method to handle validation
* @param businessType            
* @param mapBusinessTypeIncoterm 
* @param mapOfIncoterm           
* @return `List<PMC_DH_PicklistWrapper>`
*/
    public static List<PMC_DH_PicklistWrapper> getRestrcIncoTerms(String businessType, Map<String,List<Schema.PicklistEntry>> mapBusinessTypeIncoterm,  Map<String, Set<String>> mapOfIncoterm)
    {   
        Set<String> setRestrictedIncoterms=new Set<String>();
        List<PMC_DH_PicklistWrapper> lstPicklistWrapper = new List<PMC_DH_PicklistWrapper>();
        PMC_DH_PicklistWrapper picklistWrapper;
        if(mapOfIncoterm.containsKey(businessType)){
            setRestrictedIncoterms=mapOfIncoterm.get(businessType);
        }
        if(mapBusinessTypeIncoterm.containsKey(businessType)){
            for(Schema.PicklistEntry picklistIncotrm: mapBusinessTypeIncoterm.get(businessType)){
                if(!setRestrictedIncoterms.contains(picklistIncotrm.getValue()))
                {
                    picklistWrapper = new PMC_DH_PicklistWrapper();
                    picklistWrapper.label = picklistIncotrm.getLabel();
                    picklistWrapper.value = picklistIncotrm.getValue();
                    lstPicklistWrapper.add(picklistWrapper);
                    
                }
                
            }
        }
        return lstPicklistWrapper;
    }
    
    
    /**
* @description 
* @author Hemant Giri Goswami | hegoswami@deloitte.com | 02-06-2024 
**/
    public static void throwTestIntegrationExceptionForTest(){
        
        if (throwTestException && Test.isRunningTest()) {
            throw new CalloutException(PMC_DH_ConstantClass.TEST_EXCEPTION_MESSAGE);
        }
    }
    
    /*************************************************************************
* @method Name  : insertOpportunityShare
* @description   : to insert opportunity share record
* @param 		  objOppShare
* @return         Boolean
* @author       : Humera
*****************************************************************************/
    Public Static Boolean insertOpportunityShare(OpportunityShare objOppShare){
        Boolean boolIsShared=false; 
        try{
            throwTestIntegrationExceptionForTest();
            if(Schema.sObjectType.OpportunityShare.isCreateable()){
                Database.SaveResult srData = Database.insert(objOppShare, false);
                if(srData.isSuccess()){
                    boolIsShared=true;
                }
            }
        }
        Catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return boolIsShared;
    }
/*************************************************************************
* @method Name  : updateAcceptedQuote
* @description   : update accepted Quote
* @param 		  objQuote
* @author       : Humera
*****************************************************************************/
    public static void updateAcceptedQuote(SBQQ__Quote__c objQuote){
        Boolean boolIsShared=PMC_DH_RequestForQuoteHelper.shareRecordWithPortalUser(objQuote.id);
        if(boolIsShared){
            objQuote.SBQQ__Primary__c=true;
            objQuote.PMC_CPQ_CustomerAcceptanceMethod__c='Accepted by DH Customer';
        }
    }
    

    /**
    * @methodName updateRejectedReason
    * @description update Rejected Reason
    * @author Mosaic Direct | Dev Team | 02-09-2024 
    * @param modelWrapper 
    * @param objQuote 
    **/
    public static void updateRejectedReason(PMC_DH_QuoteMgmtActionController.PMC_DH_ModelWrapper modelWrapper,SBQQ__Quote__c objQuote){
        if(modelWrapper.strSelectedReason!='Other'){
            objQuote.PMC_CPQ_RejectedReason__c=modelWrapper.strSelectedReason;
        }
        else{
            objQuote.PMC_CPQ_RejectedReason__c=modelWrapper.strSelectedReason;   
            objQuote.PMC_CLM_OtherRejectionReason__c=modelWrapper.strReason;
        }
    }

    
    /*************************************************************************
    * @author : Rohan Undale
    * @method Name  : getPackagingTypeForQuote
    * @description  : Method to get Packaging Type
    * @return       : List<PMC_DH_PicklistWrapper>
    *****************************************************************************/
    public static List<PMC_DH_PicklistWrapper> getModeOfTransportationForCPT(){
        List<PMC_DH_PicklistWrapper> lstDeliveryModesCPT = new List<PMC_DH_PicklistWrapper>();
        List<String> lstDeliveryModes = PMC_DH_CommonSystemUtils.getListStoreConfigbyFeature(PMC_DH_ConstantClass.MOT_FOR_CPT);
        for(String strDeliveryMode : lstDeliveryModes){
            PMC_DH_PicklistWrapper picklistWrapper = new PMC_DH_PicklistWrapper();
            picklistWrapper.label = PMC_DH_CommonSystemUtils.getTranslatedValForPicklist(CartItem.PMC_DH_DeliveryMode__c.getDescribe(),strDeliveryMode);
            picklistWrapper.value = strDeliveryMode;
            lstDeliveryModesCPT.add(picklistWrapper);
        }
        return lstDeliveryModesCPT;
    }
     /*************************************************************************
* @method Name  : setPrePaymentDate
* @description   : to set payment date
* @param 		  objectData
* @return         date
* @author       : Lakshmi
*****************************************************************************/
    public static date setPaymentDate(object objectData){
        date returnDate;
        if (objectData instanceof WebCart){
            WebCart wb = (WebCart)objectData;
            returnDate= checkForPaymentTerm(wb.PMC_DH_PaymentTerms__c) ? wb.PMC_DH_PrepaymentDate__c:Date.ValueOf(returnDate);
           
        }
        if (objectData instanceof PMC_DH_QuoteUpdateWrapper){
            PMC_DH_QuoteUpdateWrapper ph = (PMC_DH_QuoteUpdateWrapper)objectData;
            returnDate =  checkForPaymentTerm(ph.strPaymentTerms) ? Date.valueOf(ph.datPrepaymentDate):Date.ValueOf(returnDate);  
        }
        return returnDate;
    }
  /*************************************************************************
* @method Name  : setPrePaymentDate
* @description   : to set payment date
* @param   objWebCart
* @param 	 paymentInfoWrapper 
* @return        date
* @author      Lakshmi
*****************************************************************************/
    public static date setPrePaymentDate(WebCart objWebCart,PMC_DH_PaymentInformationForQuoteWrapper paymentInfoWrapper){
    date returnDate;
    return checkForPaymentTerm(objWebCart.PMC_DH_PaymentTerms__c) ? paymentInfoWrapper.datPrepaymentDate: date.ValueOf(returnDate);
}
/*************************************************************************
* @method Name  : checkForPaymentTerm
* @description   : to check prepayment term
* @param 		  paymentTerm
* @return         boolean
* @author       : Lakshmi
*****************************************************************************/
    public static Boolean checkForPaymentTerm(string paymentTerm){
         Boolean boolisPayterm = PMC_DH_ConstantClass.FIXED_DATE.contains(paymentTerm) || PMC_DH_ConstantClass.PREPAYMENT.contains(paymentTerm);
            return boolisPayterm;
        
    }
	
/*************************************************************************
* @method Name  : getSalesArea
* @description   : method to get Sales Area
* @param 		  strSalesArea
*  @param         objWebCart
* @return         string
* @author       : Humera
*****************************************************************************/    
    public static string getSalesArea(String strSalesArea , WebCart objWebCart){
        String accSalesAreaJuncId  ;  
    if(strSalesArea!=null){
                    //fix as part of GPT-30638
                    List<String> lstUserSalesArea=strSalesArea.split(';');
                    Set<String> setUserSalesArea =new Set<String>(lstUserSalesArea);
                      // handle the null scenario dont query unless params have value
                    accSalesAreaJuncId = PMC_DH_RequestForQuoteHelper.getAccSalesAreaJuncId(objWebCart.AccountId, setUserSalesArea);
                   
                }
                return accSalesAreaJuncId;
            }
}