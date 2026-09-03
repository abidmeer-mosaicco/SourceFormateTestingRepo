/** @description This class is the test class that provides response for Mock Http Callouts 
 *  @author Shefali Dsouza
 *  @storynumber GDASF-2983, GDASF-2978
 */

@isTest
public class PMC_CPQ_HttpCalloutMockSCodeFailureTest implements HttpCalloutMock {
   /** 
     * @description This returns a static response
     * @param request - This is the request of HTTP callout
     * @return HTTPResponse - returns the response body of HTTP callout
     */
	    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('<?xml version="1.0" encoding="UTF-8"?><QueryResult><done>true</done><totalSize>0</totalSize></QueryResult>');
        response.setStatusCode(500);
        return response; 
    }
}