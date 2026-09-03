/** @description This class is the test class that provides response for Mock Http Callouts 
 *  @author Shefali Dsouza
 *  @storynumber GDASF-2983, GDASF-2978
 */

@isTest
public class PMC_CPQ_HttpOrderCalloutMockSuccess implements HttpCalloutMock {
   /** 
     * @description This returns a static response
     * @param request - This is the request of HTTP callout
     * @return HTTPResponse - returns the response body of HTTP callout
     */
	    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('[{"OBJ_NUM": "0030000819","OBJ_ITEM": 10,"SF_ORDERITEM_ID":"'+ PMC_CPQ_OrderIntegrationTest.lstPayloadOrderLineIds[0]+'","TYPE": "S","ID": "V4","NUMBER": 233,"MESSAGE": "SALES_HEADER_IN has been processed successfully","MESSAGE_V1":"VBAKKOM","SFOrderId":"'+PMC_CPQ_OrderIntegrationTest.lstPayloadOrderIds[0]+'","ObjectName":"Order","statusCode":201,"responsetext":"Created"}]');
        response.setStatusCode(200);
        return response; 
    }
}