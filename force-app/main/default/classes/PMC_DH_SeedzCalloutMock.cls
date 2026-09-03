/** @description This class is the test class that provides response for Mock Http Callouts 
*  @author Humera
*  @storynumber GDASF-14530 
*/

@isTest
public class PMC_DH_SeedzCalloutMock implements HttpCalloutMock {
    /**
* @description Status
* @return String
*/
    public String strStatus{get;set;}
    /**
* @description response
* @return String
*/
    public string strRes{get;set;}
    /**
* @description Response code
* @return String
*/
    public Integer intResCode{get;set;}
    /** 
* @description This returns a static response
* @param intResCode
* @param strRes
* @param strStatus
*/
    public PMC_DH_SeedzCalloutMock(Integer intResCode,string strRes,String strStatus){
        this.intResCode=intResCode;
        this.strRes=strRes;
        this.strStatus=strStatus;
    }
    
    /** 
* @description This returns a static response
* @param request - This is the request of HTTP callout
* @return HTTPResponse - returns the response body of HTTP callout
*/
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        
        // Handle POST request
        if (request.getMethod() == 'POST') {
            response.setHeader('Content-Type', 'application/json');
            response.setBody(this.strRes);
            response.setStatusCode(this.intResCode);
        }
        // Handle GET request
        else if (request.getMethod() == 'GET') {
            Map<String, Object> mapRes = new Map<String, Object>();
            mapRes.put('balance',12555);
            String strBody = JSON.serialize(mapRes);
            response.setBody(strBody);
            response.setStatusCode(this.intResCode);
            response.setStatus(this.strStatus);
        }
        return response; 
    }
    
}