/**
* @description Controller for Contract Document
* @since 09-07-2023
*/

public with sharing class PMC_DH_ContractDocumentController {
    public final static String AMENDMENT_TYPE = 'Amendment';
    /**
* 
* @description method for contract document on page load
* @author Hemant giri goswami
* @since 09-07-2023
* @return List<PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfo>
* @param strContractId
*/
    @AuraEnabled
    public static PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfo getContractDocInfo(String strContractId)//on page load
    {
        PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfo contractDocWrp=new PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfo();
        map<String,PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfoInst> mapContractDoc=new map<String,PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfoInst>();
        List<Contract> lstConObjRecord=new List<Contract>();
        try {
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            lstConObjRecord=[SELECT ID,PMC_CPQ_Contract_Blocked__c,PMC_CPQ_ContractType__c , SBQQ__Quote__r.SBQQ__Type__c, PMC_CPQ_LatestQuote__r.SBQQ__Type__c,PMC_CPQ_LatestQuote__c,
                                    (SELECT Id, SBQQ__QuoteLine__r.PMC_CLM_ContractDocumentName__c,SBQQ__QuoteLine__r.name,
                                    SBQQ__QuoteLine__r.PMC_CLM_ContractDocumentId__c,
                                    toLabel(SBQQ__QuoteLine__r.PMC_CPQ_ModeOfTransportation__c),
                                    toLabel(SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c),SBQQ__QuoteLine__r.SBQQ__Number__c 
                                    FROM SBQQ__Subscriptions__r where SBQQ__QuoteLine__r.PMC_CLM_ContractDocumentId__c!=null  ORDER BY CREATEDDATE DESC)  
                                    FROM Contract WHERE ID=:strContractId
                                    WITH SECURITY_ENFORCED ORDER BY CREATEDDATE DESC];
            
            if(!lstConObjRecord.isEmpty())
            {
                if(lstConObjRecord[0].PMC_CPQ_LatestQuote__c != null && lstConObjRecord[0].PMC_CPQ_LatestQuote__r.SBQQ__Type__c == AMENDMENT_TYPE)
                {
                    List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, PMC_CLM_QuoteLineNumber__c,SBQQ__Quote__r.Name,SBQQ__Quote__c,SBQQ__Quote__r.SBQQ__Status__c,
                                        PMC_CPQ_ShipTo__c, PMC_CPQ_ShipTo__r.Name, PMC_CPQ_ShipTo__r.ShippingStreet, SBQQ__Quantity__c,PMC_CLM_ContractDocumentId__c,
                                        PMC_CPQ_ShipTo__r.ShippingCity, PMC_CPQ_ShipTo__r.ShippingState, PMC_CPQ_ShipTo__r.ShippingPostalCode,PMC_CLM_ContractDocumentName__c,
                                        PMC_CPQ_ProductLocation__c,PMC_CPQ_ProductLocation__r.PMC_CPQ_Location__r.Name,toLabel( PMC_CPQ_Incoterms1__c),toLabel( PMC_CPQ_ModeofTransportation__c), SBQQ__NetPrice__c,toLabel( PMC_CPQ_ContractType__c), 
                                        PMC_CPQ_PackageType__c, PMC_CPQ_PackType__c,PMC_CPQ_UnitofMeasure__c,SBQQ__Product__c,SBQQ__Product__r.StockKeepingUnit
                                        FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=:lstConObjRecord[0].PMC_CPQ_LatestQuote__c 
                                        WITH SECURITY_ENFORCED];
                createQuotelineInfo( quoteLineList, mapContractDoc);
                }// quotleine- check on type for amendment
                else{
            for(SBQQ__Subscription__c subItem:lstConObjRecord[0].SBQQ__Subscriptions__r)
            {   
                String strDocId=subItem.SBQQ__QuoteLine__r.PMC_CLM_ContractDocumentId__c;
                String strContractType=subItem.SBQQ__QuoteLine__r.PMC_CPQ_ContractType__c;
                String strDeliveryMode=subItem.SBQQ__QuoteLine__r.PMC_CPQ_ModeOfTransportation__c;
                String strUniq=strDocId+strContractType+strDeliveryMode;
                if(!mapContractDoc.containsKey(strUniq))
                {
                PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfoInst contrDocInfo=new PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfoInst();
                ContrDocInfo.strDocId=strDocId;
                ContrDocInfo.strDocName=subItem.SBQQ__QuoteLine__r.PMC_CLM_ContractDocumentName__c;
                ContrDocInfo.strContractType=strContractType;
                ContrDocInfo.strDeliveryMode=strDeliveryMode;
                //String strConc=ContrDocInfo.strDocId+ContrDocInfo.strContractType+ContrDocInfo.strDeliveryMode;
                mapContractDoc.put(strUniq,ContrDocInfo);
                }
            }
        }
        }
            if(!mapContractDoc.isEmpty()){
                contractDocWrp.lstContractDoc=mapContractDoc.Values();
            }
           
            contractDocWrp.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'ContractDoc');
        } catch (Exception ex) {
            PMC_ErrorLogClass.processException(ex);
            contractDocWrp.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
            //throw  new AuraHandledException(ex.getMessage());
            
        }
        return contractDocWrp;
    }
    private static void createQuotelineInfo(List<SBQQ__QuoteLine__c>  quoteLineList, map<String,PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfoInst> mapContractDoc)
    {
        for(SBQQ__QuoteLine__c quoteLineObjRecord: quoteLineList)
                    {
                        String strQuoteLineDocId=quoteLineObjRecord.PMC_CLM_ContractDocumentId__c;
                        String strQuotelineContractType=quoteLineObjRecord.PMC_CPQ_ContractType__c;
                        String strQuotelineDeliveryMode=quoteLineObjRecord.PMC_CPQ_ModeOfTransportation__c;
                        String strQuotelineUniq=strQuoteLineDocId+strQuotelineContractType+strQuotelineDeliveryMode+quoteLineObjRecord.PMC_CLM_QuoteLineNumber__c;//PMC_CLM_QuoteLineNumber__c added to handle unique document lines at Quoteline Level
                        if(!mapContractDoc.containsKey(strQuotelineUniq))
                        {
                        PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfoInst contrDocInfo=new PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocInfoInst();
                        ContrDocInfo.strDocId=strQuoteLineDocId;
                        ContrDocInfo.strDocName=quoteLineObjRecord.PMC_CLM_ContractDocumentName__c;
                        ContrDocInfo.strContractType=strQuotelineContractType;
                        ContrDocInfo.strDeliveryMode=strQuotelineDeliveryMode;
                        mapContractDoc.put(strQuotelineUniq,ContrDocInfo);
                        }
                    }

    }
    
    /**
* @description  method for  contract document widget to handle download feature
* @since 09-08-2023
* @author Hemant Giri Goswami
* @param strAction  String
* @param  strDocId String
* @return         `PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocData`
*/
    @AuraEnabled
    public static PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocData getContractDocData(String strAction, String strDocId)
    {   
        
        PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocData contrDoc=new PMC_DH_ContractDocumentWrapper.PMC_DH_ContractDocData();
        Set<Id> setQuotelineIds =new Set<Id>();
        HttpResponse res;
        Set<String> setContDocId=new Set<String>();
        try{
            
            List<SBQQ__QuoteLine__c> lstQuoteLine=[SELECT Id,PMC_CPQ_ModeOfTransportation__c,PMC_CPQ_ContractType__c,PMC_CLM_ContractDocumentId__c,PMC_CLM_ContractDocumentName__c
                                                FROM SBQQ__QuoteLine__c WHERE PMC_CLM_ContractDocumentId__c=:strDocId 
                                                   WITH SECURITY_ENFORCED];
            String strDocName=lstQuoteLine[0].PMC_CLM_ContractDocumentName__c;
            for(SBQQ__QuoteLine__c subQuoteLine:lstQuoteLine)
            {   
                setQuotelineIds.add(subQuoteLine.id);
            }
            List<PMC_DH_CaseMgmtClass.PMC_DH_FileWrapper> lstFileWrap = new List<PMC_DH_CaseMgmtClass.PMC_DH_FileWrapper>();
            PMC_DH_CaseMgmtClass.PMC_DH_FileWrapper insertFileWrap;
            String strDocumentName= strDocName +'.pdf';
            List<ContentDocumentLink> lstContentDocLink = [SELECT Id, ContentDocumentId, ContentDocument.Title,ContentDocument.LatestPublishedVersion.VersionData
                                                     FROM ContentDocumentLink WHERE LinkedEntityId in: setQuotelineIds 
                                                     AND ContentDocument.Title = :strDocumentName WITH SECURITY_ENFORCED ];

        
            if(lstContentDocLink.isEmpty())
            {
                res=PMC_DH_ContractDocumentServiceClass.getContractDocResponse(strDocId);
                for(Id quoteLineId:setQuotelineIds)
                {
                    insertFileWrap=new PMC_DH_CaseMgmtClass.PMC_DH_FileWrapper();
                    insertFileWrap.parentId=quoteLineId;
                    insertFileWrap.strBase64Data=EncodingUtil.base64Encode(res.getBodyAsBlob());
                    insertFileWrap.strFileName=strDocName +'.pdf';
                    lstFileWrap.add(insertFileWrap);
                    
                }
                if(res.getStatusCode()==200 )
                {
                    PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=PMC_DH_CaseMgmtClass.saveTheChunkFile(lstFileWrap);
                    List<ContentDistribution> lstContentDist=getContentResult(result,setQuotelineIds,strDocName);
                    contrDoc.strDownloadLink=lstContentDist[0].ContentDownloadUrl;
                   contrDoc.strViewData=EncodingUtil.base64Encode(res.getBodyAsBlob());
                 }
                }
            else 
            {
                for(ContentDocumentLink ins:lstContentDocLink)
                {
                   setContDocId.add(ins.ContentDocumentId);
                }
                List<ContentDistribution>  lstContentDis = [Select Id,ContentDocumentId,ContentDownloadUrl,DistributionPublicUrl,CreatedBy.name 
                                                from ContentDistribution where ContentDocumentId in: setContDocId
                                                WITH SECURITY_ENFORCED];
                contrDoc.strDownloadLink=lstContentDis[0].ContentDownloadUrl;
                contrDoc.strViewData=EncodingUtil.base64Encode(lstContentDocLink[0].ContentDocument.LatestPublishedVersion.VersionData);
                
            }
            contrDoc.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'ContractDoc');
        }
        catch(Exception ex)
        {
            contrDoc.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
            //throw new AuraHandledException(ex.getMessage());
        }
        return contrDoc;
    }
    
    
    private static List<ContentDistribution> getContentResult(PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result,Set<Id> setQuotelineIds,String strDocName){
        List<ContentDistribution> lstContDis;
        Set<String> setContDocId=new Set<String>();
        String strDocumentName= strDocName +'.pdf';
        if(result.strStatusCode.contains('000'))
        {
            List<ContentDocumentLink> lstCVersion = [SELECT Id, ContentDocumentId, ContentDocument.Title,ContentDocument.LatestPublishedVersion.VersionData
                                                    FROM ContentDocumentLink WHERE LinkedEntityId in: setQuotelineIds 
                                                    AND ContentDocument.Title  =:strDocumentName WITH SECURITY_ENFORCED ];
            for(ContentDocumentLink ins:lstCVersion)
            {
                setContDocId.add(ins.ContentDocumentId);
            }
            lstContDis= [Select Id,ContentDocumentId,ContentDownloadUrl,DistributionPublicUrl,CreatedBy.name 
                            from ContentDistribution where ContentDocumentId in: setContDocId
                                                WITH SECURITY_ENFORCED];
            }
        return lstContDis;
    }
}