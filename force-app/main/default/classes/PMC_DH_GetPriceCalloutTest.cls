/** @description This class is the test class that provides response for Mock Http Callouts 
 *  @author Humera
 *  @storynumber GDASF-6862
 */

@isTest
public class PMC_DH_GetPriceCalloutTest implements HttpCalloutMock {
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
    public  PMC_DH_GetPriceCalloutTest(Integer intResCode,string strRes,String strStatus){
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
        response.setHeader('Content-Type', 'application/json');
        //response.setBody('{"HeaderSet":{"Header":{"PriceDate":"2023-08-03","Ztransid":"Q-01305","QtValidT":"2023-11-11","ReturnSet":"","ReqDateH":"2023-07-28","PartnerSet":{"Partner":[{"PartnRole":"SH","Ztransid":"Q-01305","PartnNumb":"20000005","ZrefTransid":"","ItmNumber":"1"},{"PartnRole":"SP","Ztransid":"Q-01305","PartnNumb":"20000005","ZrefTransid":"","ItmNumber":"0"}]},"Credit_LimitSet":{"Credit_Limit":[{"CredLimit":"28117500.0000","Ztransid":"Q-01305","Currency":"","ZrefTransid":""}]},"DistrChan":"00","QtValidF":"2023-07-04","PurchNoC":"","Price_CondSet":[{"Price_Cond":[{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01305","Currency":"USD","CondValue":"220.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZLST"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01305","Currency":"USD","CondValue":"10.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZF01"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01305","Currency":"","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"SKTV"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01305","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZLTX"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01305","Currency":"","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZITE"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01305","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"PCIP"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01305","Currency":"","CondValue":"50.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZFIT"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01305","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZPMN"},{"ValidEndDate":"0000-00-00","ValidStartDate":"0000-00-00","Ztransid":"Q-01305","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZNTB"}]}],"Pmnttrms":"0001","ItemSet":{"Item":[{"Ztransid":"Q-01305","CondValue":"0.000","ReqQty":"0000000000001","SalesUnit":"MTN","Material":"1000229","Incoterms2":"SAP/Supply chain","Incoterms1":"CFR","TargetQty":"0000000000001","Plant":"1002","PurchNoC":"","TargetQu":"MTN","ZrefTransid":"","ItmNumber":"1","CondType":""}]},"SalesOrg":"1002","Currency":"USD","Division":"10","ZrefTransid":"","PurchDate":"2023-08-03","Raw_MaterialSet":{"Raw_Material":{"Ztransid":"","ZrefTransid":""}},"DocType":"ZQP","ShipCond":"Z1","Item_RSet":{"Item_R":[{"TaxAmount":"0.0000","Zpricerefresh":"false","HgLvItem":"000000","Ztransid":"Q-01305","NetValue":"231.0200","Material":"1000229","ZrefTransid":"","ItmNumber":"1","Zprcduedt":"2023-08-08"}]}}}}');
response.setBody(this.strRes);
        response.setStatusCode(this.intResCode);
        return response; 
    }
    
    
}