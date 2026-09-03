/**
* @description Management Class for QuoteRelated Item
* @author hemant giri goswami
* @since  07-03-2023
*/
public without sharing class PMC_DH_QuoteMgmtRelatedItemsClass {

    /**
* @description throw exception
* @return Boolean
*/
    public static Boolean boolThrExc=false;
    /**
     * @description method for quote database
     * @author hemant.girigoswami
     * @since 07-04-2023
     * @param strParentId 
     * @return            `List<SBQQ__Quote__History>`
     */
@testVisible
    private static List<SBQQ__Quote__History> lstQuoteDatabase(String strParentId)
    {
        try{
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();  
        List<String> lstQuoteFields=PMC_DH_CommonSystemUtils.getListStoreConfigbyFeature(PMC_DH_ConstantClass.LST_QUOTE_FIELDS); 
        return  [SELECT ParentId,CreatedBy.Name,CreatedById ,CreatedDate,
                        toLabel(Field),CreatedBy.Profile.Name, NewValue, OldValue 
                        FROM SBQQ__Quote__History
                        WHERE ParentId=:strParentId  AND Field!='Created' 
                        AND Field in :lstQuoteFields
                        WITH SYSTEM_MODE ORDER by CreatedDate desc];//where strQuoteId
        }
        catch (Exception e) {
        PMC_ErrorLogClass.processException(e); // MDErrorLog
        throw new AuraHandledException(PMC_DH_ConstantClass.EXCEPTION_TEST);
        
    }

    }

    /**
     * @description method for quote line history
     * @author hemant.girigoswami
     * @since 07-04-2023
     * @param strParentId
     * @param lstQLFields
     * @return            `List<SBQQ__QuoteLine__History>`
     */
@testVisible
    private static List<SBQQ__QuoteLine__History> lstQuoteLineDatabase(String strParentId,List<String> lstQLFields)
    {
        try{
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
                return [SELECT CreatedBy.Name, CreatedDate,
                    CreatedBy.Profile.Name,Parent.SBQQ__Quote__c,  
                    toLabel(Field), NewValue, OldValue  FROM SBQQ__QuoteLine__History 
                    WHERE Parent.SBQQ__Quote__c=:strParentId 
                    AND Field!='Created' 
                    AND Field in :lstQLFields
                    WITH SYSTEM_MODE ORDER by CreatedDate desc] ;//where strQuoteId
        }
        catch (Exception e) {
        throw new AuraHandledException(PMC_DH_ConstantClass.EXCEPTION_TEST);
        
    }
    }

    
    
/**
    * @description method to process history for objects
    * @param lstQHistrdB
    * @param lstQLHistrdB
    * @author hemant giri goswami
    * @since 04-07-2023
    * @return    PMC_DH_ConversationHistoryWrapper
    */
    public static PMC_DH_ConversationHistoryWrapper processConvo(list<SBQQ__Quote__History> lstQHistrdB, List<SBQQ__QuoteLine__History>lstQLHistrdB) //changes as part of GDASF-19642
    {   
        PMC_DH_ConversationHistoryWrapper wrpConvHistory = new PMC_DH_ConversationHistoryWrapper(); //changes as part of GDASF-19642
        List<PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper> lsQtHistory;
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        lsQtHistory=getQouteHistory(lstQHistrdB);

        Map<String,String> mapAccShipTo=getShipTos(lstQLHistrdB);
        for(SBQQ__QuoteLine__History qlHistory:lstQLHistrdB)
        {	
            PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper qlWrapperI=new PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper();          	
            if(!Test.isRunningTest())
            {
                qlWrapperI.strUsrName=getUserPersona(qlHistory.CreatedBy.Profile.Name,qlHistory.CreatedBy.Name);//profile check based on which name should be assigned
            }
        if(conditnCheck(qlHistory))
        {	
            continue;
        }
        if(qlHistory.Field==PMC_DH_ConstantClass.SHIPTO)
        {	
        qlWrapperI.strOriginalValue=mapAccShipTo.get(String.Valueof(qlHistory.OldValue));
        qlWrapperI.strNewValue=mapAccShipTo.get(String.Valueof(qlHistory.NewValue));
        
        }
        else
        {
            qlWrapperI.strOriginalValue=String.Valueof(qlHistory.OldValue);
            qlWrapperI.strNewValue=String.Valueof(qlHistory.NewValue);
            }
            qlWrapperI.strFieldName=qlHistory.Field;
            qlWrapperI.datModifiedDate=qlHistory.CreatedDate;
            lsQtHistory.add(qlWrapperI);     
        }
    lsQtHistory.sort();
        wrpConvHistory.lstQtHistory = lsQtHistory; //changes as part of GDASF-19642
        wrpConvHistory.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, 'ConversationHistory'); //changes as part of GDASF-19642
    }
    catch (Exception e) {
        wrpConvHistory.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); //changes as part of GDASF-19642
        PMC_ErrorLogClass.processException(e); // MDErrorLog
    }
    return wrpConvHistory; //changes as part of GDASF-19642
    }

    private static Boolean conditnCheck( SBQQ__QuoteLine__History qlHistory)
    {
        return ((qlHistory.OldValue instanceof Id && qlHistory.NewValue instanceof Id &&  qlHistory.Field==PMC_DH_ConstantClass.PRODLOC) ||
        (!(qlHistory.OldValue instanceof Id) && 
        !(qlHistory.NewValue instanceof Id) &&  qlHistory.Field==PMC_DH_ConstantClass.SHIPTO) );
    }
@testVisible
    private static List<PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper> getQouteHistory(list<SBQQ__Quote__History> lstQHtry){
        List<PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper> lstQtHistory=new List<PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper>();
        for (SBQQ__Quote__History qHistory:lstQHtry)
        {   
            PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper qWrapperI=new PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper();
            if(!Test.isRunningTest())
            {
            qWrapperI.strUsrName=getUserPersona(qHistory.CreatedBy.Profile.Name,qHistory.CreatedBy.Name);//profile check based on which name should be assigned
            }
            qWrapperI.strOriginalValue=qHistory.OldValue;
            qWrapperI.strNewValue=qHistory.NewValue;
            qWrapperI.strFieldName=qHistory.Field;
            qWrapperI.datModifiedDate=qHistory.CreatedDate;  
            lstQtHistory.add(qWrapperI);     
        }
        return lstQtHistory;
    }


@testVisible
    private static map<String,String> getShipTos(List<SBQQ__QuoteLine__History> lstQtLineHistory){
        Set<Id> stShipToName=new Set<Id>() ;
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        for(SBQQ__QuoteLine__History qlHistory:lstQtLineHistory)
        {
                if(shipToCondCheck(qlHistory))
            {	stShipToName.add(String.Valueof(qlHistory.OldValue));
                stShipToName.add(String.Valueof(qlHistory.NewValue));
            }
        }
        }
        catch (Exception e) {
        throw new AuraHandledException(PMC_DH_ConstantClass.EXCEPTION_TEST);
        
    }
    return getAccountList(stShipToName);
    }
    
private static boolean shipToCondCheck(SBQQ__QuoteLine__History qlHistory)
{
    return (qlHistory.Field==PMC_DH_ConstantClass.SHIPTO && qlHistory.OldValue instanceof Id 
    && qlHistory.NewValue instanceof Id && qlHistory.Field!=null);
}

    @testVisible
    private static map<String,String> getAccountList(Set<Id> stShipToName){
        Map<String,String> mapAccountShipTo=new Map<String,String>();
        try{
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        List<Account> lstShip=[SELECT Name,Id,ShippingStreet, ShippingState,
                                                    ShippingCity, ShippingCountry, ShippingPostalCode 
                                                    FROM account WHERE Id in: stShipToName WITH SECURITY_ENFORCED];
        
        for(Account objShipTo:lstShip)
        { 	    String strShipToLabel = objShipTo.Name + ' ' + objShipTo.ShippingStreet + ', ' + objShipTo.ShippingCity + ', ' + objShipTo.ShippingState + ' ' + objShipTo.ShippingPostalCode;  
                mapAccountShipTo.put(objShipTo.id,strShipToLabel);
            }
            
        }
        catch (Exception e) {
        throw new AuraHandledException(PMC_DH_ConstantClass.EXCEPTION_TEST);
        
    }
    return mapAccountShipTo;
    }
    /**
* @description method to get the history of Quote fields changes
* @author @hegoswami
* @since 06-28-2023
* @return PMC_DH_ConversationHistoryWrapper

* @param strQuoteId
*/
    @AuraEnabled 
    public static PMC_DH_ConversationHistoryWrapper getConversationHistory(String strQuoteId)//strQuoteId
    {   
        
        List<SBQQ__Quote__History> lstHistory=new List<SBQQ__Quote__History>();
        List<SBQQ__QuoteLine__History > lstQLHistory=new List<SBQQ__QuoteLine__History >();
        Map<String,List<String>> mapFields=new Map<String,List<String>>();
        List<String> lstFieldQL=new List<String>();
        List<String> lstQuoteFieldsBR=PMC_DH_CommonSystemUtils.getListStoreConfigbyFeature(PMC_DH_ConstantClass.LST_QUOTELINE_FIELDS); 
        List<String> lstQuoteFieldsNA=PMC_DH_CommonSystemUtils.getListStoreConfigbyFeature(PMC_DH_ConstantClass.LST_QUOTELINE_FIELDS_NA); 
        try {
        mapFields.put(PMC_DH_ConstantClass.BRAZIL,lstQuoteFieldsBR);
        mapFields.put(PMC_DH_ConstantClass.UNITEDSTATES,lstQuoteFieldsNA);
        mapFields.put(PMC_DH_ConstantClass.CANADA,lstQuoteFieldsNA);
        String strCountry=([Select id,country from User where id=:UserInfo.getUserId() WITH SYSTEM_MODE ].Country).capitalize();
        lstFieldQL=mapFields.get(strCountry);
        //PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
        lstHistory=lstQuoteDatabase(strQuoteId);
        lstQLHistory=lstQuoteLineDatabase(strQuoteId,lstFieldQL);
    }
    catch (Exception e) {
        PMC_ErrorLogClass.processException(e); // MDErrorLog
        throw new AuraHandledException(PMC_DH_ConstantClass.EXCEPTION_TEST);
        
    }
    return processConvo(lstHistory,lstQLHistory);
    
    }
    
    
    /**
* @description method to validate whether the user is Admin or Buyer
* @author @hegoswami
* @since 06-30-2023
* @return String
* @param strPersona
* @param strName
* 
*/
@testVisible
private static String getUserPersona(String strPersona,String strName){
    String strAssignedName=PMC_DH_ConstantClass.ADMIN_NAME;
    try{  
        PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
    if(strPersona.contains(PMC_DH_ConstantClass.PMC_DH_APPNAME))
        {	
            strAssignedName=strName;   
        }
        
    }
    catch(Exception e){
        PMC_ErrorLogClass.processException(e);
        throw new AuraHandledException(PMC_DH_ConstantClass.EXCEPTION_TEST);
    }
    return strAssignedName;
}
    

    /*************************************************************************
* @method Name  : getContracts
* @param        strQuoteId
* @description  : Method to get Contracts
* @return       : PMC_DH_ContractListWrapper
*****************************************************************************/
    @AuraEnabled 
    public static PMC_DH_ContractListWrapper getContracts(String strQuoteId){
        PMC_DH_ContractListWrapper wrpContractList = new PMC_DH_ContractListWrapper();
        List<PMC_DH_QuoteDetailsWrapper.ContractsWrapper> lstContractWrapper=new List<PMC_DH_QuoteDetailsWrapper.ContractsWrapper>();
        //PMC_DH_QuoteDetailsWrapper.ContractsWrapper objContract;
        List <Contract> lstContract;
        try{
            PMC_DH_Store_Configuration__mdt config = PMC_DH_Store_Configuration__mdt.getInstance('ContractUrl');
            lstContract=[SELECT Id, PMC_CPQ_Contract_Blocked__c,PMC_CPQ_ContractType__c, StartDate, EndDate, tolabel(Status), AccountId, 
                        SBQQ__Quote__c, SBQQ__Quote__r.Name, SBQQ__Quote__r.SBQQ__Status__c, SBQQ__Quote__r.PMC_CPQ_ContractStageName__c, SBQQ__Quote__r.PMC_CLM_DocumentNumber__c, SBQQ__Quote__r.PMC_CPQ_PO__c, SBQQ__Quote__r.PMC_CPQ_PrimaryContact__r.Name, SBQQ__Quote__r.SBQQ__PaymentTerms__c, SBQQ__Quote__r.PMC_DH_PaymentMethod__c, SBQQ__Quote__r.PMC_CPQ_Currency__c, SBQQ__Quote__r.PMC_CPQ_TotalQuantity__c, SBQQ__Quote__r.PMC_CPQ_ModeOfTransportation__c,
                        (SELECT Id, PMC_CPQ_TotalOrderedQuantity__c, PMC_CPQ_TotalAvailableQuantity__c, SBQQ__Product__r.StockKeepingUnit,
                            SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__c, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingStreet, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingCity, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingState, SBQQ__QuoteLine__r.PMC_CPQ_ShipTo__r.ShippingPostalCode, SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__c,SBQQ__QuoteLine__r.PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name, SBQQ__QuoteLine__r.PMC_CPQ_Incoterms1__c, SBQQ__QuoteLine__r.PMC_CPQ_ModeofTransportation__c, SBQQ__QuoteLine__r.SBQQ__NetPrice__c, SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c
                            FROM SBQQ__Subscriptions__r) from Contract WHERE ID in (Select SBQQ__Contract__c from SBQQ__Subscription__c where SBQQ__Quoteline__r.SBQQ__Quote__c=:strQuoteId) AND Status='Activated' WITH SECURITY_ENFORCED];
            if(!lstContract.isEmpty()){
                for(Contract con:lstContract){
                    PMC_DH_QuoteDetailsWrapper.ContractsWrapper objContract=new PMC_DH_QuoteDetailsWrapper.ContractsWrapper();
                    List<String> lstStatusAndReason = PMC_DH_ContractManagementHelper.getContractStatusAndReason(con);
                    objContract.strContractStatus = lstStatusAndReason[0];
                    objContract.strContractNumber =PMC_DH_ConstantClass.DOC_TAG+con.SBQQ__Quote__r.PMC_CLM_DocumentNumber__c;
                    objContract.strContractUrl = config.PMC_DH_PageUrl__c + con.id;
                    lstContractWrapper.add(objContract);
                }
            }
            wrpContractList.lstContractWrapper = lstContractWrapper; //changes as part of GDASF-19642
            wrpContractList.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, 'ContractRecord'); //changes as part of GDASF-19642
        }
        Catch(Exception ex){
            wrpContractList.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL); //changes as part of GDASF-19642
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
        }
        return wrpContractList; //changes as part of GDASF-19642
    }

    // added as part of GDASF-19642
    /**
    * @description : Wrapper for Conversation History
    * @author      : Nikhilesh Mohanty
    * @last modified on 2024-01-10
    **/ 
    public with sharing class PMC_DH_ConversationHistoryWrapper
    {
        /**
        * @description Return URL
        * @author Nikhilesh
        * @return List<PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper>
        **/ 
        @AuraEnabled
        public List<PMC_DH_QuoteDetailsWrapper.QuoteHistoryWrapper> lstQtHistory{get;set;}

        /**
        * @description Status Code and message
        * @author Nikhilesh
        * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }

    /**
    * @description : Wrapper for list of contracts
    * @author      : Nikhilesh Mohanty
    * @last modified on 2024-01-10
    **/ 
    public with sharing class PMC_DH_ContractListWrapper
    {
        /**
        * @description List of Contracts Wrapper
        * @author Nikhilesh
        * @return List<PMC_DH_QuoteDetailsWrapper.ContractsWrapper>
        **/ 
        @AuraEnabled
        public List<PMC_DH_QuoteDetailsWrapper.ContractsWrapper> lstContractWrapper{get;set;}

        /**
        * @description Status Code and message
        * @author Nikhilesh
        * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }
}