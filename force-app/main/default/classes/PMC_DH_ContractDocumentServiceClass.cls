/**
* @description : class for Contract documents - DocuSign CLM Integration
* @author      : Humera Rahath
* @userStory   : GPDH-12218
* */
public with sharing class PMC_DH_ContractDocumentServiceClass {

    private static final String OAUTH_DEVELOPERNAME='ContractDocusignOAuth';
    private static final String CONTRACT_DOWNLOAD='ContractDownloadDocusign';
/*************************************************************************
* @method Name  : getIntegrationMetadata
* @description : Method to fetch integration metadata
*@param      strDevName
* @return  PMC_DH_IntegrationSettings__mdt
*****************************************************************************/ 
   public static PMC_DH_IntegrationSettings__mdt getIntegrationMetadata(String strDevName){
        PMC_DH_IntegrationSettings__mdt objIntField=new PMC_DH_IntegrationSettings__mdt();
        List<PMC_DH_IntegrationSettings__mdt> lstIntMetadata;
        try{
            lstIntMetadata=[Select id,DeveloperName,PMC_DH_CalloutMethod__c, PMC_DH_ContentType__c, PMC_DH_EndpointURL__c,
                            PMC_DH_RefreshToken__c, PMC_DH_Accept__c,PMC_DH_RetryCount__c, PMC_DH_RetryTimeout__c, PMC_DH_Timeout__c,
                            PMC_DH_Authorization__c,PMC_DH_CachedTime__c,PMC_DH_ClientId__c,PMC_DH_ClientSecret__c from PMC_DH_IntegrationSettings__mdt 
                             WHERE DeveloperName=:strDevName WITH USER_MODE]; 
            if(!lstIntMetadata.isEmpty()){
                objIntField=lstIntMetadata[0];
            }
        }
        catch(exception ex){
            throw new AuraHandledException(ex.getMessage()); 
        }
        return objIntField;
    }
    
    /*************************************************************************
* @method Name  : getContractDocResponse
* @description : Method to get access token through api callout
*@param      strContractDocId
* @return  HttpResponse
*****************************************************************************/    
    public static HttpResponse getContractDocResponse(String strContractDocId){
        
        String strAccessToken; 
        Map<String,Object> mapResponse;
        HttpResponse response;
        Boolean boolIsCallOut=false;
        PMC_DH_IntegrationCalloutFramework.PMC_DH_CallOutWrapper callOutWrap;
        PMC_DH_IntegrationCalloutFramework.PMC_DH_CallOutWrapper callOutWrapDoc;
       
        List<String> lstDevName=getDomainName();
        
        PMC_DH_IntegrationSettings__mdt objIntMetaData=getIntegrationMetadata(lstDevName.get(0));
        PMC_DH_IntegrationSettings__mdt objIntMetaDataDoc=getIntegrationMetadata(lstDevName.get(1));
        
        Map<String, String> mapRefreshToken = new Map<String, String>();
        mapRefreshToken.put('grant_type', 'refresh_token');
        mapRefreshToken.put('refresh_token', objIntMetaData.PMC_DH_RefreshToken__c);
        String strBody = JSON.serialize(mapRefreshToken);
        
        Map<String,String> mapOfHeaders=new Map<String,String>();
        PMC_DH_IntegrationCalloutFramework intFramework=new PMC_DH_IntegrationCalloutFramework();
        mapOfHeaders.put('ENDPOINT',objIntMetaData.PMC_DH_EndpointURL__c );
        mapOfHeaders.put('Content-Type',objIntMetaData.PMC_DH_ContentType__c);
        mapOfHeaders.put('Authorization',objIntMetaData.PMC_DH_Authorization__c);
        mapOfHeaders.put('SET_BODY',strBody);
        
        Map<String,String> mapOfHeadersDoc=new Map<String,String>();
        mapOfHeadersDoc.put('ENDPOINT',objIntMetaDataDoc.PMC_DH_EndpointURL__c+strContractDocId);
        mapOfHeadersDoc.put('Content-Type',objIntMetaDataDoc.PMC_DH_ContentType__c);
        mapOfHeadersDoc.put('Accept',objIntMetaDataDoc.PMC_DH_Accept__c);
        
        try{
            if(PMC_DH_CacheHelper.isKeyAvailable('CLMDHAUTHORIZATIONTOKEN'))
            {
                strAccessToken=(String)PMC_DH_CacheHelper.getOrgPartitionCachebyKey('CLMDHAUTHORIZATIONTOKEN');
            }
            else
            {
                callOutWrap = intFramework.doCallout('POST', mapOfHeaders);
                boolIsCallOut=true;
                if(callOutWrap.response.getStatusCode() == 200){
                    mapResponse=(Map<String,Object>)JSON.deserializeUntyped(callOutWrap.response.getBody());
                    strAccessToken=(String)mapResponse.GET('access_token');
                    PMC_DH_CacheHelper.setOrgPartitionCache('CLMDHAUTHORIZATIONTOKEN', (Object)strAccessToken,(Integer)objIntMetaData.PMC_DH_CachedTime__c);
                }
                else{
                    throw new IntegrationException('Callout Failed');
                }
                
            }
            callOutWrapDoc =getDocCallOut(strAccessToken,objIntMetaDataDoc,mapOfHeadersDoc);
            
            if(boolIsCallOut){
                PMC_DH_LoggingUtils.createDHTransactionLogs(callOutWrap.request,callOutWrap.response, objIntMetaData.PMC_DH_EndpointURL__c);
            }
            PMC_DH_LoggingUtils.createDHTransactionLogs(callOutWrapDoc.request,callOutWrapDoc.response, objIntMetaDataDoc.PMC_DH_EndpointURL__c+strContractDocId);
            
        }
        catch(exception ex){
            throw new AuraHandledException(ex.getMessage()); 
        }
        return callOutWrapDoc.response;
    }
    
   /*************************************************************************
* @method Name  : IntegrationException
* @description : class for exception 
*****************************************************************************/  
    public class IntegrationException extends Exception {}
    
    private static PMC_DH_IntegrationCalloutFramework.PMC_DH_CallOutWrapper getDocCallOut(String strAccessToken,PMC_DH_IntegrationSettings__mdt objIntMetaDataDoc,Map<String,String> mapOfHeadersDoc){
    PMC_DH_IntegrationCalloutFramework intFramework=new PMC_DH_IntegrationCalloutFramework();
    PMC_DH_IntegrationCalloutFramework.PMC_DH_CallOutWrapper callOutDocWrap=new PMC_DH_IntegrationCalloutFramework.PMC_DH_CallOutWrapper();
        if(string.isNotBlank(strAccessToken))
            {
                mapOfHeadersDoc.put('Authorization',objIntMetaDataDoc.PMC_DH_Authorization__c+' '+strAccessToken);
                callOutDocWrap= intFramework.doCallout('GET', mapOfHeadersDoc);
    
            }
            return callOutDocWrap;
        }

       private static List<String> getDomainName(){
        List<String> lstDevName=new List<String>();
 // prepare domain parse logic
 System.Domain d = System.DomainParser.parse(URL.getOrgDomainUrl());
 String oAuthDevName=OAUTH_DEVELOPERNAME;
 String contractAPIDevName=CONTRACT_DOWNLOAD;
 if(String.isNotBlank(d.getSandboxName()))
 {
     oAuthDevName=oAuthDevName+'_'+d.getSandboxName();
    contractAPIDevName=contractAPIDevName+'_'+d.getSandboxName();
    lstDevName.add(oAuthDevName);
    lstDevName.add(contractAPIDevName);
 }
 else{
    lstDevName.add(oAuthDevName);
    lstDevName.add(contractAPIDevName);  
}
 return lstDevName;
       } 
    
}