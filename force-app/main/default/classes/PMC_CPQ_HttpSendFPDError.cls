/** @description Test class for Get FPD success scenario
 *  @author Prakhar
 *  @storynumber GDASF-12490
 */

@isTest
public class PMC_CPQ_HttpSendFPDError implements HttpCalloutMock {
   /** 
     * @description This returns a static response
     * @param request - This is the request of HTTP callout
     * @return HTTPResponse - returns the response body of HTTP callout
     */
	    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('An internal server error occured: The MPL ID for the failed message is : AGTxz5iPI8e-wogTAmqSF2XzsSB4');
        response.setStatusCode(500);
        return response; 
    }
}