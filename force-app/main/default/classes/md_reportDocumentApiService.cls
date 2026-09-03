public without sharing class md_reportDocumentApiService {
    private static final String ENDPOINT_PATH   = '/http/SFDC_Salesdocuments';
    private static final String NFE_XML_ENDPOINT_PATH = '/http/NFeXMLDownload';
    private static final String NAMED_CREDENTIAL = 'callout:PMC_CPQ_NamedCredential';

    public static HttpResponse getDoc(String docCode, String billingDocNumber, String itemNumber) {
        Map<String, Object> objData = new Map<String, Object>{
            'strDocumentCode'     => docCode,
            'strBillingDocNumber' => billingDocNumber
        };
        if (!String.isBlank(itemNumber)) {
            objData.put('strItemNumber', itemNumber);
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + ENDPOINT_PATH);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{ 'objData' => objData }));
        req.setTimeout(120000);

        return new Http().send(req);
    }

    public static HttpResponse getNfeXmlDoc(String accessKey) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + NFE_XML_ENDPOINT_PATH + '?accessKey=' + EncodingUtil.urlEncode(accessKey, 'UTF-8'));
        req.setMethod('GET');
        req.setTimeout(120000);

        return new Http().send(req);
    }
}