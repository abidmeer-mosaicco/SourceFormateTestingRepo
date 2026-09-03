/** @description This class is the test class that provides response for Mock Http Callouts 
*  @author Rohan Undale
*  @storynumber GDASF-12218 
*/

@isTest
public class PMC_DH_ContractDocumentCalloutMock implements HttpCalloutMock {
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
    public PMC_DH_ContractDocumentCalloutMock(Integer intResCode,string strRes,String strStatus){
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
        
        // Handle GET request
        if (request.getMethod() == 'POST') {
            response.setHeader('Content-Type', 'application/json');
            response.setBody(this.strRes);
            response.setStatusCode(this.intResCode);
        }
        // Handle POST request
        else if (request.getMethod() == 'GET') {
            // Set the response body as a Blob
            Blob mockBlobResponse = Blob.valueOf('This is a mock Blob response.');
            response.setBodyAsBlob(mockBlobResponse);
            response.setHeader('Content-Type', 'application/octet-stream');
            response.setStatusCode(this.intResCode);
            response.setStatus('OK');
        }
        return response; 
    }
}