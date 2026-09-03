/**
* @description This class will be used to Mock Response
* @author Vedashri
*/
@isTest
    public class PMC_SS_ServiceNowMockHttpResponse implements HttpCalloutMock {
     /**
    * @description This class will be used to Mock Response
    * @param req - Request for Servicenow.
    * @return res - Mock response.
    */
        public HTTPResponse respond(HTTPRequest req){
            try{
                HttpResponse res= new HttpResponse();
                res.setHeader('Content-Type','application/json');
                res.setBody('{"access_token":"testResponse_access_token","refresh_token":"testResponse_refresh_token","scope":"useraccount","token_type":"Bearer","expires_in":1799}');
                res.setStatusCode(200);
                return res;
        }catch(Exception ex){
                PMC_ErrorLogClass.processException(ex);
        }
            return null;
         }
    }