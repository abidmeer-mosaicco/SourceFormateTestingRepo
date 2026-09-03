/**
* @description : class for Seedz Integration
* @author      : Humera Rahath
* @userStory   : GPDH-14530
* */
public  class PMC_DH_SeedzServiceClass {
    private static final String OAUTH_SEEDZDEVNAME='SeedzOAuth';
    private static final String SEEDZ_POINTSDEVNAME='SeedzPoints';
    private static final String SEEDZ_ORGCACHE='SEEDZDHTOKEN';
    
    
    /*************************************************************************
* @method Name  : getSeedzPoints
* @description : Method to make callout for seedz integration
*@param      strCPForCNPJNumber
* @return  HttpResponse
*****************************************************************************/       
    public static HttpResponse getSeedzPointsCallout(String strCPForCNPJNumber){
        PMC_DH_IntegrationCalloutFramework.PMC_DH_CallOutWrapper callOutWrapper;
        PMC_DH_IntegrationCalloutFramework.PMC_DH_CallOutWrapper callOutWrap;
        Map<String,Object> mapResponse;
        String strAccessToken;
        Boolean boolIsCallOut=false;
        
        
        List<String> lstDevName=getDomainName();
        //For Accesstoken
        PMC_DH_IntegrationSettings__mdt objIntMetaDataAcc=PMC_DH_ContractDocumentServiceClass.getIntegrationMetadata(lstDevName.get(0));
        
        Map<String, String> mapRefreshToken = new Map<String, String>();
        mapRefreshToken.put('email', objIntMetaDataAcc.PMC_DH_ClientId__c);
        mapRefreshToken.put('password', objIntMetaDataAcc.PMC_DH_ClientSecret__c); 
        mapRefreshToken.put('setTimeout',String.valueOf(objIntMetaDataAcc.PMC_DH_Timeout__c));
    	String strBody = JSON.serialize(mapRefreshToken);
        
        Map<String,String> mapOfHeadersAcc=new Map<String,String>();
        PMC_DH_IntegrationCalloutFramework intFrameworkAcc=new PMC_DH_IntegrationCalloutFramework();
        mapOfHeadersAcc.put('ENDPOINT',objIntMetaDataAcc.PMC_DH_EndpointURL__c );
        mapOfHeadersAcc.put('Content-Type',objIntMetaDataAcc.PMC_DH_ContentType__c);
        mapOfHeadersAcc.put('SET_BODY',strBody);
        
        //For SeedzPoints
       PMC_DH_IntegrationSettings__mdt objIntMetaData=PMC_DH_ContractDocumentServiceClass.getIntegrationMetadata(lstDevName.get(1));
        
        Map<String,String> mapOfHeaders=new Map<String,String>();
        mapOfHeaders.put('ENDPOINT',objIntMetaData.PMC_DH_EndpointURL__c+strCPForCNPJNumber);
      
        try
        {
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest(); // added to cover catch block
            //checking if access token is present in cache 
            if(PMC_DH_CacheHelper.isKeyAvailable(SEEDZ_ORGCACHE))
            {
                strAccessToken=(String)PMC_DH_CacheHelper.getOrgPartitionCachebyKey(SEEDZ_ORGCACHE);
            }
            //make a callout and store access token in cache
            else
            {
                callOutWrap = intFrameworkAcc.doCallout('POST', mapOfHeadersAcc);
                boolIsCallOut=true;
               if(callOutWrap.response.getStatusCode() == 200){
                   mapResponse=(Map<String,Object>)JSON.deserializeUntyped(callOutWrap.response.getBody());
                   strAccessToken=(String)mapResponse.GET('token');
                   PMC_DH_CacheHelper.setOrgPartitionCache(SEEDZ_ORGCACHE,strAccessToken,(Integer)objIntMetaDataAcc.PMC_DH_CachedTime__c);
               }
                else
                {
                    throw new PMC_DH_Validation.CustomException('CallOut Failed');
                    
                }
            }
            
            //make a callout for Seedz POints
            callOutWrapper=getPointsCallOut(strAccessToken,objIntMetaData,mapOfHeaders);
            
            //insert transaction logs
            if(boolIsCallOut)
            {
                PMC_DH_LoggingUtils.createDHTransactionLogs(callOutWrap.request,callOutWrap.response, objIntMetaDataAcc.PMC_DH_EndpointURL__c);
            }
           
            PMC_DH_LoggingUtils.createDHTransactionLogs(callOutWrapper.request,callOutWrapper.response, objIntMetaData.PMC_DH_EndpointURL__c+strCPForCNPJNumber);   
             
        }
       catch(PMC_DH_Validation.CustomException ex){
            throw new PMC_DH_Validation.CustomException('CallOut Failed');
        }
        catch (Exception ex) {
            throw  new AuraHandledException(ex.getMessage());
            
        }
        return callOutWrapper.response;
    }
    
    /*************************************************************************
* @method Name  : IntegrationException
* @description : class for exception 
*****************************************************************************/  
    public class IntegrationException extends Exception {
        
    }
    
    
    private static PMC_DH_IntegrationCalloutFramework.PMC_DH_CallOutWrapper getPointsCallOut(String strAccessToken,PMC_DH_IntegrationSettings__mdt objIntMetaDataDoc,Map<String,String> mapOfHeadersDoc){
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
        System.Domain domain = System.DomainParser.parse(URL.getOrgDomainUrl());
        String oAuthDevName=OAUTH_SEEDZDEVNAME;
        String seedzAPIDevName=SEEDZ_POINTSDEVNAME;
        if(String.isNotBlank(domain.getSandboxName()))
        {
            oAuthDevName=OAUTH_SEEDZDEVNAME+'_'+domain.getSandboxName();
            seedzAPIDevName=SEEDZ_POINTSDEVNAME+'_'+domain.getSandboxName();
            lstDevName.add(oAuthDevName);
            lstDevName.add(seedzAPIDevName);
        }
        else{
            lstDevName.add(oAuthDevName);
            lstDevName.add(seedzAPIDevName);  
        }
        return lstDevName;
    } 
}