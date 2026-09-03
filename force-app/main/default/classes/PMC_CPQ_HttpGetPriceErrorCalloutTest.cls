/** @description This class is the test class that provides response for Mock Http Callouts 
 *  @author Prakhar
 *  @storynumber GDASF-6819, GDASF-9437 
 */

@isTest
public class PMC_CPQ_HttpGetPriceErrorCalloutTest implements HttpCalloutMock {
   /** 
     * @description This returns a static response
     * @param request - This is the request of HTTP callout
     * @return HTTPResponse - returns the response body of HTTP callout
     */
	    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"error":{"code":"/IWBEP/CM_MGW_RT/022","message":{"@xml:lang":"en","$":"Exception raised without specific error"},"innererror":{"application":{"component_id":"","service_namespace":"/SAP/","service_id":"ZOTC_I060_QUOTATION_PRICE_CAL_SRV","service_version":"0001"},"transactionid":"400cb41ec4584a8988cf9a31b7a541fb","timestamp":"","Error_Resolution":{"SAP_Transaction":"","SAP_Note":"See SAP Note 1797736 for error analysis (https://service.sap.com/sap/support/notes/1797736)"},"errordetails":{"errordetail":[{"ContentID":"","code":"CZ/115","message":"Sales area 1002 00 ? does not exist","longtext_url":"Test","propertyref":"","severity":"error","target":"","transition":"false"},{"ContentID":"","code":"/IWBEP/CX_MGW_BUSI_EXCEPTION","message":"Exception raised without specific error","propertyref":"","severity":"error","target":"","transition":"false"}]}}}}');
        response.setStatusCode(400);
        return response; 
    }
}