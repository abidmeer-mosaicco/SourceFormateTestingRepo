/** @description Test class for Get FPD success scenario
 *  @author Shefali Dsouza
 *  @storynumber GDASF-2983, GDASF-2978
 */

@isTest
public class PMC_CPQ_HttpGetFPDCalloutMockPartSuccess implements HttpCalloutMock {
   /** 
     * @description This returns a static response
     * @param request - This is the request of HTTP callout
     * @return HTTPResponse - returns the response body of HTTP callout
     */
	    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('[{"LineId":"0000000205","ListPrice":120,"FloorPrice":0.0,"CeilingPrice":0.0,"TargetPrice":0.0,"Netback":25,"AvgPricePerProduct":98,"SameCustomerSameProductLastTransactedPrice":96,"ReplacementCostStandardProduct":100,"PriceRefreshFlag":"Y","ReplacementCostBlendedProduct":100,"ExchangeRate":null,"Status":"Success","ErrorMessage":"","OrderItemId":"'+PMC_CPQ_GetFPDOrderLineTest.lstPayloadOrderLineIds[0]+'"},{"LineId":"0000000205","ListPrice":120,"FloorPrice":0.0,"CeilingPrice":0.0,"TargetPrice":0.0,"Netback":25,"AvgPricePerProduct":98,"SameCustomerSameProductLastTransactedPrice":96,"ReplacementCostStandardProduct":100,"PriceRefreshFlag":"Y","ReplacementCostBlendedProduct":100,"ExchangeRate":null,"Status":"Error","ErrorMessage":"","OrderItemId":"'+PMC_CPQ_GetFPDOrderLineTest.lstPayloadOrderLineIds[0]+'"}]');
        response.setStatusCode(200);
        return response; 
    }
}