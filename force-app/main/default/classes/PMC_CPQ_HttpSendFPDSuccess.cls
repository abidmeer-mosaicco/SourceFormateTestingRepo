/** @description Test class for Get FPD success scenario
 *  @author Prakhar
 *  @storynumber GDASF-12490
 */

@isTest
public class PMC_CPQ_HttpSendFPDSuccess implements HttpCalloutMock {
    public id orderItemId;
    /** @description Constructor of the class which is used to intialize record id for trigger to cater to response
     *  @param orderItm - Id of triggering record
     */
    public PMC_CPQ_HttpSendFPDSuccess(id orderItm){
        this.orderItemId = orderItm;
    }
   /** 
     * @description This returns a static response
     * @param request - This is the request of HTTP callout
     * @return HTTPResponse - returns the response body of HTTP callout
     */
	    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('[{"Status":"S","Nav_Return":{"Return":[{"Message":"ORDER_HEADER_IN has been processed successfully","LogNo":"","ObjNum":"30000230","System":"DA1CLNT110","Field":"","Type":"S","Number":"233","ObjItem":"000010","MessageV4":"","MessageV3":"","Parameter":"ORDER_HEADER_IN","Id":"V4","Row":"0","LogMsgNo":"000000","MessageV2":"","MessageV1":"VBAKKOM"},{"Message":"ITEM_IN has been processed successfully","LogNo":"","ObjNum":"30000230","System":"DA1CLNT110","Field":"","Type":"S","Number":"233","ObjItem":"000010","MessageV4":"","MessageV3":"","Parameter":"ITEM_IN","Id":"V4","Row":"1","LogMsgNo":"000000","MessageV2":"000010","MessageV1":"VBAPKOM"},{"Message":"SCHEDULE_IN has been processed successfully","LogNo":"","ObjNum":"30000230","System":"DA1CLNT110","Field":"","Type":"S","Number":"233","ObjItem":"000010","MessageV4":"","MessageV3":"","Parameter":"SCHEDULE_IN","Id":"V4","Row":"1","LogMsgNo":"000000","MessageV2":"","MessageV1":"VBEPKOM"},{"Message":"SCHEDULE_IN has been processed successfully","LogNo":"","ObjNum":"30000230","System":"DA1CLNT110","Field":"","Type":"S","Number":"233","ObjItem":"000010","MessageV4":"","MessageV3":"","Parameter":"SCHEDULE_IN","Id":"V4","Row":"2","LogMsgNo":"000000","MessageV2":"","MessageV1":"VBEPKOM"},{"Message":"KONVKOM has been processed successfully","LogNo":"","ObjNum":"30000230","System":"DA1CLNT110","Field":"","Type":"S","Number":"233","ObjItem":"000010","MessageV4":"","MessageV3":"","Parameter":"KONVKOM","Id":"V4","Row":"1","LogMsgNo":"000000","MessageV2":"","MessageV1":"KONVKOM"},{"Message":"Standard Sales Order 30000230 has been saved.","LogNo":"","ObjNum":"30000230","System":"DA1CLNT110","Field":"","Type":"S","Number":"311","ObjItem":"000010","MessageV4":"","MessageV3":"","Parameter":"ORDER_HEADER_IN","Id":"V1","Row":"0","LogMsgNo":"000000","MessageV2":"30000230","MessageV1":"Standard Sales Order"}]},"Orderitem":"000010","Pricecallbydate":"2023-01-01T00:00:00.000","Orderid":"30000230","Finalprice":"0.000","Recordid":"' + orderItemId + '","Statuscode":201,"Responsetext":"CREATED"}]');
        response.setStatusCode(200);
        return response; 
    }
}