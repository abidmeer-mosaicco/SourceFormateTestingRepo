/** @description This class is the test class that provides response for Mock Http Callouts 
 *  @author Shefali Dsouza
 *  @storynumber GDASF-2983, GDASF-2978
 */

@isTest
public class PMC_CPQ_HttpCalloutMockSuccessTest implements HttpCalloutMock {
   /** 
     * @description This returns a static response
     * @param request - This is the request of HTTP callout
     * @return HTTPResponse - returns the response body of HTTP callout
     */
	    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('[{"TYPE":"S","ID":"V1","NUMBER":311,"MESSAGE":"Prepay Qty Contract 4500867 has been saved.","MESSAGE_V1":"Prepay Qty Contract","OBJECT_NUMBER":"0004500867","SFRecordId":"'+PMC_CPQ_CPIRemoteCalloutUtilityTest.lstPayloadQuoteIds[0]+'","ObjectName":"Contract","statusCode":201,"responsetext":"Created"},{"TYPE":"S","ID":"V1","NUMBER":311,"MESSAGE":"Quotation 3000852 has been saved.","MESSAGE_V1":"Quotation","OBJECT_NUMBER":"0003000852","SFRecordId":"'+PMC_CPQ_CPIRemoteCalloutUtilityTest.lstPayloadQuoteIds[0]+'","ObjectName":"Quote","statusCode":201,"responsetext":"Created"}]');
        response.setStatusCode(200);
        return response; 
    }
}