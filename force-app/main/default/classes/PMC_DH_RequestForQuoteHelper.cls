/**
* @description util class for RFQ
* @author hemant giri goswami
* @since  07-27-2023
*/
public without sharing class PMC_DH_RequestForQuoteHelper {
    Private Static Final Set<String> SETSALESAREADIVISION = new Set<String>{'10'};
    /*************************************************************************
* @method Name  : getQuoteRecordType 
* @description  : Method to create the quote Record type id
* @param       	strUserRegion  
* @return       : String
*****************************************************************************/
    public static String getQuoteRecordType(String strUserRegion){
        String strQuoteRecId='';        
    //strQuoteRecId= Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get(system.label.PMC_DH_DomesticNa).getRecordTypeId();
        strQuoteRecId=[SELECT ID FROM RECORDTYPE WHERE NAME=:PMC_DH_ConstantClass.DOMESTIC_NA AND SobjectType=:PMC_DH_ConstantClass.QUOTE_SOBJECT_TYPE WITH SECURITY_ENFORCED LIMIT 1].id;
        if(strUserRegion=='BR'){
        //  strQuoteRecId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Domestic SA').getRecordTypeId();
            strQuoteRecId=[SELECT ID FROM RECORDTYPE WHERE NAME=: PMC_DH_ConstantClass.DOMESTIC_SA AND SobjectType=:PMC_DH_ConstantClass.QUOTE_SOBJECT_TYPE WITH SECURITY_ENFORCED LIMIT 1].id;

        }
        return strQuoteRecId;
    }
    
    /*************************************************************************
* @method Name  : getAccSalesAreaJuncId
* @description  : Method to get the Id of Account Sales Area Relationship junction object
* @param 		  effAccId
* @param		  setSalesArea
* @return       : String
*****************************************************************************/
    public static Id getAccSalesAreaJuncId(String effAccId, set<String> setSalesArea){
        String accSalesAreaJuncId;
        List<PMC_SS_AccountSalesAreaRelationship__c> lstAccSalesAreaJunc = [SELECT Id FROM PMC_SS_AccountSalesAreaRelationship__c
                                                                            WHERE PMC_SS_Account__c =: effAccId
                                                                            AND PMC_SS_SalesArea__r.PMC_DH_SalesArea__c IN: setSalesArea WITH SECURITY_ENFORCED];
        if(!lstAccSalesAreaJunc.isEmpty()){
            accSalesAreaJuncId = lstAccSalesAreaJunc[0].Id;
        }
        return accSalesAreaJuncId;
    }
    
    
    /*************************************************************************
* @method Name  : getExpiryDate
* @description  : Method to get Expiry Date
* @param       	quoteDetails 
*@param 		quoteStatusWrapper
* @return       : PMC_DH_QuoteMgmtActionController.PMC_DH_QuoteStatusWrapper
*****************************************************************************/
    
    public  static  PMC_DH_QuoteMgmtActionController.PMC_DH_QuoteStatusWrapper getExpiryDate(SBQQ__Quote__c quoteDetails,PMC_DH_QuoteMgmtActionController.PMC_DH_QuoteStatusWrapper quoteStatusWrapper)
    {
        PMC_DH_QuoteMgmtActionController.PMC_DH_QuoteStatusWrapper objQuoteWrapper=new PMC_DH_QuoteMgmtActionController.PMC_DH_QuoteStatusWrapper();
        objQuoteWrapper.strProgressIndicatorStatus=quoteStatusWrapper.strProgressIndicatorStatus;
        objQuoteWrapper.strSummaryStatus=quoteStatusWrapper.strSummaryStatus; 
        if(quoteDetails.PMC_CPQ_ExpiresOn__c!=null){
            if((system.now()<quoteDetails.PMC_CPQ_ExpiresOn__c) && (quoteDetails.SBQQ__Status__c==PMC_DH_ConstantClass.PRESENTED)){
                String gmtFormattedStringExp =quoteDetails.PMC_CPQ_ExpiresOn__c.formatGMT(PMC_DH_ConstantClass.GMT_FORMAT);
                objQuoteWrapper.datTExpiresIn=DateTime.valueOfGMT(gmtFormattedStringExp);
                
                String gmtFormattedString =DateTime.now().formatGMT(PMC_DH_ConstantClass.GMT_FORMAT);
                objQuoteWrapper.datTCurrentDateTime= DateTime.valueOfGMT(gmtFormattedString);
            }
            else  if(quoteDetails.SBQQ__Status__c==PMC_DH_ConstantClass.STATUS_EXPIRED) {
                
                objQuoteWrapper.strProgressIndicatorStatus=PMC_DH_ConstantClass.REJECTED;
                objQuoteWrapper.strSummaryStatus=PMC_DH_ConstantClass.ACCOUNT_INACTIVE_STATUS;
            }
        }
        return objQuoteWrapper;
    }
    
    
    /*************************************************************************
* @method Name  : getQuoteRecordTypeName
* @description  : Method to get Recordtype name   
* @return       : String
*****************************************************************************/
    public static String getQuoteRecordTypeName()
    {   String strTemplabel;
        String strTempVar;
        String strUserId=userInfo.getUserId();
        List<User> lstUser=PMC_DH_UserUtil.getUserData(strUserId);
        String strUserRegion = PMC_DH_CommonSystemUtils.getUserRegion(lstUser[0].country);
        String strRecordTypeId = PMC_DH_RequestForQuoteHelper.getQuoteRecordType(strUserRegion);
        String strRecordTypeName = [SELECT Id,name from RecordType WHERE id =: strRecordTypeId][0].Name;
        strTempVar=strRecordTypeName.replace(' ','');
        strTemplabel=System.label.get(null,strRecordTypeName=PMC_DH_ConstantClass.LABEL_HEADER+strTempVar,userinfo.getLocale());// added as fix for translation GPT-29606
        return strTemplabel;
    }  
    /*************************************************************************
* @method Name  : getUserBusinessType
* @description  : Method to get BusinessType name   
* @param effAccId
* @return       : String
*****************************************************************************/
    public static String getUserBusinessType(String effAccId){
        String strBusinessType='';
        String strAMUserId= [SELECT Id,OwnerId FROM Account WHERE Id =: effAccId WITH SYSTEM_MODE LIMIT 1].OwnerId;
        User userAM = [SELECT Id, PMC_CPQ_PrimaryBusinessType__c, PMC_CPQ_SalesArea__c FROM User WHERE Id =: strAMUserId WITH SYSTEM_MODE LIMIT 1]; 
        if(userAM.PMC_CPQ_PrimaryBusinessType__c!=null){
            String strTemp=PMC_DH_ConstantClass.LABEL_HEADER+userAM.PMC_CPQ_PrimaryBusinessType__c.replace('-','').replace(' ','');
            //String strLabelName=PMC_DH_ConstantClass.LABEL_HEADER+strTemp2; // added as fix for translation GPT-29606
            strBusinessType = System.label.get(null,strTemp,userinfo.getLocale());//userAM.PMC_CPQ_PrimaryBusinessType__c;
            //strBusinessType=userAM.PMC_CPQ_PrimaryBusinessType__c;
        }
        return strBusinessType;
        
    }

    
    /**
* @description method to handle validation
* @param lstProductLocation 
* @param mapShipFrom        
* @return                   `Map<String,List<PMC_DH_PicklistWrapper>>`
*/
    public static Map<String,List<PMC_DH_PicklistWrapper>> getShipFromValidation(List<PMC_CPQ_ProductLocation__c> lstProductLocation,Map<String,List<PMC_DH_PicklistWrapper>> mapShipFrom)
    {
        PMC_DH_PicklistWrapper shipFrom;
        if(!lstProductLocation.isEmpty()){
            for(PMC_CPQ_ProductLocation__c loc : lstProductLocation){
                
                shipFrom = new PMC_DH_PicklistWrapper();
                shipFrom.label = loc.PMC_CPQ_Location__r.Name;
                shipFrom.value = loc.Id;
                if(!mapShipFrom.containsKey(loc.PMC_CPQ_ProductName__r.StockKeepingUnit))
                {
                    mapShipFrom.put(loc.PMC_CPQ_ProductName__r.StockKeepingUnit,new List<PMC_DH_PicklistWrapper>());
                }
                mapShipFrom.get(loc.PMC_CPQ_ProductName__r.StockKeepingUnit).add(shipFrom); 
            }
        }
        return mapShipFrom;
    }
    /**
* @description Method to handle restricted rules for incoterms
* @param strCategory
* @return Map<String, Set<String>>
*/
    
    public static Map<String, Set<String>> getRestrictionRulesForIncoterm(String strCategory) {
        Map<String, Set<String>> mapOfIncoterm = new Map<String,Set<String>>();
        List<PMC_DH_Digital_Hub_Restriction_Setting__mdt> lstRules= [SELECT PMC_DH_Category__c, PMC_DH_Type__c, PMC_DH_Restricted_Value__c  FROM PMC_DH_Digital_Hub_Restriction_Setting__mdt WHERE PMC_DH_Category__c=:strCategory WITH SECURITY_ENFORCED ];
        for(PMC_DH_Digital_Hub_Restriction_Setting__mdt key : lstRules){
            if(!mapOfIncoterm.containsKey(key.PMC_DH_Type__c)){
                mapOfIncoterm.put(key.PMC_DH_Type__c, new Set<String>());       
            }
            mapOfIncoterm.get(key.PMC_DH_Type__c).add(key.PMC_DH_Restricted_Value__c);       
        }
        return mapOfIncoterm;
    }
    
    
    /*************************************************************************
* @method Name  : getSalesAreaForCart
* @description  : Method to get the Sales area 
* @param 		  strCartId
* @return       : PMC_DH_SalesAreaForCartWrapper
*****************************************************************************/
    
    public static PMC_DH_SalesAreaForCartWrapper getSalesAreaForCart(String strCartId){
        PMC_DH_SalesAreaForCartWrapper salesAreaCartWrapper=new PMC_DH_SalesAreaForCartWrapper();
        try{
            Set<String> setProdIds = new Set<String>();
            Set<String> setSalesAreaIds = new Set<String>();
            List<Cartitem> lstCartItem = [SELECT Id, Product2Id, Cart.AccountId FROM CartItem WHERE CartId =: strCartId WITH SECURITY_ENFORCED];
            if(!lstCartItem.isEmpty()){
                String accountId = lstCartItem[0].Cart.AccountId;
                for(CartItem ci : lstCartItem){
                    setProdIds.add(ci.Product2Id);
                }
                List<PMC_DH_CommerceEntitlementSalesArea__c> lstCESalesArea = [SELECT Id, PMC_DH_SalesArea__c FROM PMC_DH_CommerceEntitlementSalesArea__c
                                                                            WHERE PMC_DH_Account__c =: accountId 
                                                                            AND PMC_DH_Product__c IN: setProdIds AND PMC_DH_SalesArea__r.PMC_SS_Division__c IN :SETSALESAREADIVISION
                                                                            WITH SECURITY_ENFORCED];
                for(PMC_DH_CommerceEntitlementSalesArea__c cesa : lstCESalesArea){
                    setSalesAreaIds.add(cesa.PMC_DH_SalesArea__c);
                }
                salesAreaCartWrapper.boolIsPriceEnabled=false;
                if(setSalesAreaIds.size()==1)
                {
                    List<String> lstSalesArea = new List<String>(setSalesAreaIds);
                    salesAreaCartWrapper.boolIsPriceEnabled=true;
                    salesAreaCartWrapper.strSalesArea=lstSalesArea.get(0);
                }
            } 
        }
        catch(Exception ex){
            PMC_ErrorLogClass.processException(ex);// MDErrorLog
        }
        return salesAreaCartWrapper;
    }
    
    /**
* @description  wrapper class for Sales Area Info
* @author Humera
* @since 10-10-2023
*/ 
// added with sharing
    public with sharing class PMC_DH_SalesAreaForCartWrapper{
        /**
* @description Sales Area
* @return String
*/
        public string strSalesArea{get;set;}
        /**
* @description Price widget visibility
* @return Boolean
*/
        public Boolean boolIsPriceEnabled{get;set;}
    }
    
/*************************************************************************
* @method Name  : shareRecordWithPortalUser
* @description   :This method is used to share the opportunity record 
* @param 		  strQuoteId
* @return         Boolean
* @author       : Humera
*****************************************************************************/
    public  static Boolean shareRecordWithPortalUser(String strQuoteId){
        Boolean boolIsShared=false;
        try{
            String strOppId =[SELECT SBQQ__Opportunity2__c FROM sbqq__quote__c WHERE ID=:strQuoteId WITH SECURITY_ENFORCED][0].SBQQ__Opportunity2__c;
            If(string.isnotBlank(strOppId)){
                OpportunityShare objOppShare = new OpportunityShare();
                objOppShare.OpportunityId = strOppId;
                objOppShare.UserOrGroupId = UserInfo.getUserId();
                objOppShare.OpportunityAccessLevel = PMC_DH_ConstantClass.EDIT;
                objOppShare.RowCause = Schema.OpportunityShare.RowCause.Manual;
                boolIsShared=PMC_DH_RequestForQuoteUtil.insertOpportunityShare(objOppShare);
            }
        }
        Catch(Exception ex){
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return boolIsShared;
    }
    /**
    * @description stampOwner
    * @author Hemant Giri Goswami | hegoswami@deloitte.com | 01-20-2024 
    * @param objQuote 
    * @param objWebCart 
    **/
    public static void stampOwner(SBQQ__Quote__c objQuote,WebCart objWebCart)
    {
        if(Schema.sObjectType.SBQQ__Quote__c.isUpdateable()){
            objQuote.OwnerId = objWebCart.PMC_DH_Account__r.OwnerId;
            update objQuote;
        }
    }
    
    
}