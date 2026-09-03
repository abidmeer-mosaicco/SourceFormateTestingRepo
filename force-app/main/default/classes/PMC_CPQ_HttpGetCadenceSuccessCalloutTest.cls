/** @description This class is the test class that provides response for Mock Http Callouts 
 *  @author Prakhar Srivastava
 *  @storynumber GDASF-9240
 */

@isTest
public class PMC_CPQ_HttpGetCadenceSuccessCalloutTest implements HttpCalloutMock {
   /** 
     * @description This returns a static response
     * @param request - This is the request of HTTP callout
     * @return HTTPResponse - returns the response body of HTTP callout
     */

	    public HTTPResponse respond(HTTPRequest request) {
            
        Date dateToday = System.today();
        String strMonth = dateToday.month().toString();
        strMonth = strMonth.leftpad(2,'0');
        String strDay = dateToday.day().toString();
        strDay = strDay.leftpad(2,'0');
        String strDate = dateToday.year().toString()+'-'+strMonth+'-'+strDay;
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"HeaderSet":{"Header":{"PriceDate":"2023-10-12","AmedInd":"","ReturnSet":"","SalesAgrStartDate":"2023-01-01T00:00:00.000","ReqDateH":"'+strDate+'","DistrChan":"00","Price_CondSet":[{"Price_Cond":[{"Ztransid":"Q-02671","Currency":"USD","CondValue":"100.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZLSA"},{"Ztransid":"Q-02671","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZDSX"},{"Ztransid":"Q-02671","Currency":"USD","CondValue":"10.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZF01"},{"Ztransid":"Q-02671","Currency":"","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"SKTV"},{"Ztransid":"Q-02671","Currency":"","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZITE"},{"Ztransid":"Q-02671","Currency":"USD","CondValue":"120.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZMCS"},{"Ztransid":"Q-02671","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"PCIP"},{"Ztransid":"Q-02671","Currency":"","CondValue":"100.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZSFT"},{"Ztransid":"Q-02671","Currency":"","CondValue":"100.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZFIT"},{"Ztransid":"Q-02671","Currency":"USD","CondValue":"100.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZPMN"},{"Ztransid":"Q-02671","Currency":"USD","CondValue":"0.000000000","ZrefTransid":"","ItmNumber":"1","CondType":"ZNTB"}]}],"RegStrGrp":"","SalesAgrEndDate":"2023-12-12T00:00:00.000","SalesOrg":"1002","Currency":"USD","Division":"10","VcoInd":"","DocType":"ZQP","Ztransid":"Q-02671","QtValidT":"2024-07-29","PrimBusType":"","PartnerSet":{"Partner":[{"PartnRole":"SH","Ztransid":"Q-02671","PartnNumb":"20000005","ZrefTransid":"","ItmNumber":"1"},{"PartnRole":"SP","Ztransid":"Q-02671","PartnNumb":"20000059","ZrefTransid":"","ItmNumber":"0"}]},"Credit_LimitSet":{"Credit_Limit":[{"CredLimit":"12716004.2600","Ztransid":"Q-02671","Currency":"","ZrefTransid":"","CredLiab":"0.0000"}]},"SalesOff":"","QtValidF":"2023-09-29","PurchNoC":"","Pmnttrms":"0001","ItemSet":{"Item":[{"Origin":"","Ztransid":"Q-02671","ZDirtydis":"3.30000","CondValue":"0.000","ReqQty":"0000000001300","SalesUnit":"MTN","Material":"1000229","Incoterms2":"Origin","Incoterms1":"FOB","ZRoaddis":"2.40000","TargetQty":"0000000001300","Plant":"1002","PrevListPrice":"X","ZPmntDuedt":"2023-10-10T00:00:00.000","PurchNoC":"","ShipCond":"Z1","ExpeditionPoint":"","DelvRegVco":"","TargetQu":"MTN","HarvestPeriod":"","ContractType":"Priced","ZFreightmonth":"Freight","ZrefTransid":"","ItmNumber":"1","CondType":""}]},"SchedAgreement":"123","B2cB2bInd":"","ZrefTransid":"","PurchDate":"2023-10-12","Raw_MaterialSet":{"Raw_Material":[{"Zsoldcfr":"0.000000000","Zzcompqty":"1.000","Zlistcfr":"0.000000000","Ztransid":"Q-02671","ZzMatDesc":"","Zzcomponent":"1000229","ItmNumber":"1","ZrefTransid":""}]},"ParQuoteTimStmp":"","Item_RSet":{"Item_R":[{"TaxAmount":"0.0000","Zpricerefresh":"false","HgLvItem":"000000","Zconprcfrml":"","Ztransid":"Q-02671","NetValue":"111.0231","Material":"1000229","ZrefTransid":"","ItmNumber":"1","ZvldStrtdt":"2023-10-12","ZvldEnddt":"2023-10-12","Zprcduedt":"2023-08-08","ScheduleSet":{"Schedule":[{"SchedLine":"0001","Ztransid":"Q-02671","ConfirQty":"0.000","ZrefTransid":"","ItmNumber":"1","ReqDate":"'+strDate+'"},{"SchedLine":"0002","Ztransid":"Q-02671","ConfirQty":"1300.000","ZrefTransid":"","ItmNumber":"1","ReqDate":"'+strDate+'"}]}}]},"Material_AvailabilitySet":{"Material_Availability":[{"Ztransid":"Q-03291","ZrefTransid":"","ItmNumber":"1","Material":"1000229","Uom":"MTN","Plant":"1002","ReqDate":"'+strDate+'","ReqQty":"100.000","ComDate":"2023-11-16","ComQty":"100.000"},{"Ztransid":"Q-03291","ZrefTransid":"","ItmNumber":"1","Material":"1000229","Uom":"MTN","Plant":"1002","ReqDate":"'+strDate+'","ReqQty":"100.000","ComDate":"2023-11-20","ComQty":"100.000"}]},"Schedule_INSet":{"Schedule_IN":[{"SchedLine":"0001","Ztransid":"Q-02671","ReqQty":"108.000","ZrefTransid":"","ItmNumber":"1","ReqDate":"2023-10-29T00:00:00.000"},{"SchedLine":"0002","Ztransid":"Q-02671","ReqQty":"108.000","ZrefTransid":"","ItmNumber":"1","ReqDate":"2024-07-29T00:00:00.000"}]}}}}');
        response.setStatusCode(200);
        return response; 
    }
}