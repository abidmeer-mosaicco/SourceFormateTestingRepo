/**
 * @description       : 
 * @author            : siddharth.pradhan@mosaicco.com | Digital Hub
 * @group             : 
* @last modified on  : 10-13-2023
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public with sharing class PMC_DH_IntegrationCalloutFramework {
   
    
    /**
    * @description 
    * @author siddharth.pradhan@mosaicco.com | Digital Hub | 09-12-2023 
    * @param calloutMethod 
    * @param mapOfHeader 
    * @return HttpResponse 
    **/
    public  PMC_DH_CallOutWrapper doCallout(String calloutMethod,Map<String,String> mapOfHeader) {
        PMC_DH_CallOutWrapper callOutWrap=new PMC_DH_CallOutWrapper();
        HttpRequest request = new HttpRequest();
        switch on calloutMethod {
            when  'GET'{
            request.setMethod('GET');
            callOutWrap.request=createRequestPayload(request,mapOfHeader);
            }
            when 'POST' {
                
            request.setMethod('POST');  
            callOutWrap.request=createRequestPayload(request,mapOfHeader);
            }
            
           
        }
        callOutWrap.response=sendHttpRequest(request);
        return callOutWrap;
        
    }

        
    
    /**
    * @description 
    * @author siddharth.pradhan@mosaicco.com | Digital Hub | 09-12-2023 
    * @param request 
    * @param mapOfHeader 
    * @return HttpRequest 
    **/
    public static HttpRequest createRequestPayload(HttpRequest request,Map<String,String> mapOfHeader) {
        try{
        for (String headerKey : mapOfHeader.keySet()) {
            if(headerKey=='SET_BODY'){
                request.setBody(String.valueOf(mapOfHeader.get(headerKey)));
                
            }
            else if(headerKey=='ENDPOINT'){
                request.setEndpoint(mapOfHeader.get(headerKey));
                
            }
            else{
                request.setHeader(headerKey,mapOfHeader.get(headerKey));
                
            }
        }
    }
    catch(System.CalloutException objException)
    {
        PMC_ErrorLogClass.processException(objException);
    }
        return request;
    } 
   
    /**
    * @description 
    * @author siddharth.pradhan@mosaicco.com | Digital Hub | 09-12-2023 
    * @param request 
    * @return HttpResponse 
    **/
    private  HttpResponse sendHttpRequest(HttpRequest request) {
        Http http = new Http();
        HttpResponse response = new HttpResponse();

        try {
            response = http.send(request);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return response;
    }
   
 /**
     * @description wrapper class for CallOut Response
     * @author Humera
     * @since 09-14-2023
     */   
	public  class PMC_DH_CallOutWrapper{
    /**
     * @description HttpResponse
     * @return HttpResponse
     */
        public HttpResponse response{get;set;}
    /**
     * @description HttpRequest
     * @return HttpRequest
     */
        public HttpRequest request{get;set;}
    }
}