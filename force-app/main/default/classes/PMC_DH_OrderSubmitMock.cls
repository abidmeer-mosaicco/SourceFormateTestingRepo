/** @description This class is the test class that provides response for Mock Http Callouts 
*  @author Mosaic Direct Dev 
*  @storynumber 
*/
public class PMC_DH_OrderSubmitMock implements HTTPCalloutMock {  
        /**
* @description Status
* @return String
*/
    public String strStatus{get;set;}
        /**
* @description Status code
* @return Integer
*/
    public Integer strResCode {get;set;}
        /**
* @description response
* @return String
*/
    public string strResponse {get;set;}
        /**
* @description  PMC_DH_OrderSubmitMock
* @author  Mosaic Direct Dev 
* @param strResCode  
* @param strResponse 
* @param strStatus
*
**/
    public PMC_DH_OrderSubmitMock(Integer strResCode, String strResponse, String strStatus)  {
        this.strResCode = strResCode;
        this.strResponse = strResponse;
        this.strStatus = strStatus;
    }
  /** 
* @description This returns a static response
* @param request - This is the request of HTTP callout
* @return HTTPResponse - returns the response body of HTTP callout
*/
    public HTTPResponse respond(HTTPRequest request){
        //Create a fake response
        HTTPResponse response = new HTTPResponse();
        
        if(request.getMethod() == 'POST'){
            response.setHeader('Content-Type', 'application/json');
            response.setBody(this.strResponse);
            response.setStatusCode(this.strResCode);
        }
        
        return response;
    }
}