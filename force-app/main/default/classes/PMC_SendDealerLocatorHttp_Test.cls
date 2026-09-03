@IsTest
private class PMC_SendDealerLocatorHttp_Test {

    // ==== Controles globais do mock (top-level, pode ser static) ====
    private static Integer statusToReturn = 200;
    private static String  bodyToReturn   = '{"ok":true}';

    // ==== Mock de callout ====
    private class DealerLocatorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            Integer sc = (PMC_SendDealerLocatorHttp_Test.statusToReturn == null
                          ? 200 : PMC_SendDealerLocatorHttp_Test.statusToReturn);
            res.setStatusCode(sc);
            res.setBody(PMC_SendDealerLocatorHttp_Test.bodyToReturn);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    // ===== Helpers =====
    private static Id getRtId(String devName) {
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE SobjectType = 'Account' AND DeveloperName = :devName
            LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    private static Account makeAccount(Id rtId, String name) {
        Account a = new Account(
            Name = name,
            Phone = '555-0000',
            ShippingStreet = 'R1',
            ShippingCity = 'Rio de Janeiro',
            ShippingState = 'Texas',
            ShippingPostalCode = '00000',
            PMC_IsActive__c = true,
            PMC_SS_Address_Coordinates__Latitude__s  = 10.123456,
            PMC_SS_Address_Coordinates__Longitude__s = -50.654321
        );
        if (rtId != null) a.RecordTypeId = rtId;
        insert a;
        return a;
    }

    private static PMC_SendDealerLocatorHttp.Request reqOf(Account a, String path, String body) {
        PMC_SendDealerLocatorHttp.Request r = new PMC_SendDealerLocatorHttp.Request();
        r.accountId   = a == null ? null : a.Id;
        r.path        = path;
        r.method      = 'POST';
        r.contentType = 'application/json';
        r.secret      = 'abc';
        r.body        = body;
        return r;
    }

    // ===== Tests =====

    @IsTest
    static void test_non_retailer_skipped_no_log() {
        // tenta achar um RT que NÃO seja Retailer. Se não houver, roda sem RT (já gera skip 204)
        Id rtNonRetailer = null;
        List<RecordType> rts = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType='Account' LIMIT 10];
        for (RecordType rt : rts) if (rt.DeveloperName != 'Retailer') { rtNonRetailer = rt.Id; break; }

        Account a = makeAccount(rtNonRetailer, 'Customer X');

        List<PMC_SendDealerLocatorHttp.Request> reqs = new List<PMC_SendDealerLocatorHttp.Request>{
            reqOf(a, '/v1/account2', '{"ID":"' + a.Id + '"}')
        };

        Test.setMock(HttpCalloutMock.class, new DealerLocatorMock());
        statusToReturn = 200;
        bodyToReturn   = '{"ok":true}';

        Test.startTest();
        List<PMC_SendDealerLocatorHttp.Response> out = PMC_SendDealerLocatorHttp.send(reqs);
        Test.stopTest();

        System.assertEquals(1, out.size());
        System.assertEquals(204, out[0].statusCode, 'non-retailer deve ser skipped 204');

        Integer cnt = [SELECT COUNT() FROM PMC_IntegrationLog__c WHERE AccountId__c = :a.Id];
        System.assertEquals(0, cnt, 'Não deve criar log para non-retailer');
    }

    @IsTest
    static void test_dedupe_same_transaction_no_log_for_second() {
        Id rtRetailer = getRtId('Retailer');
        if (rtRetailer == null) {
            System.assert(true, 'RecordType Retailer ausente nesta org de teste.');
            return;
        }

        Account a = makeAccount(rtRetailer, 'Retailer Dedupe');

        List<PMC_SendDealerLocatorHttp.Request> reqs = new List<PMC_SendDealerLocatorHttp.Request>{
            reqOf(a, '/v1/account3', '{"ID":"' + a.Id + '","seq":1}'),
            reqOf(a, '/v1/account3', '{"ID":"' + a.Id + '","seq":2}')
        };

        Test.setMock(HttpCalloutMock.class, new DealerLocatorMock());
        statusToReturn = 200;
        bodyToReturn   = '{"ok":true}';

        Test.startTest();
        List<PMC_SendDealerLocatorHttp.Response> out = PMC_SendDealerLocatorHttp.send(reqs);
        Test.stopTest();

        System.assertEquals(2, out.size());
        System.assertEquals(200, out[0].statusCode);
        System.assertEquals(204, out[1].statusCode);

        List<PMC_IntegrationLog__c> logs = [
            SELECT Id, StatusCode__c, Success__c, RequestBody__c
            FROM PMC_IntegrationLog__c
            WHERE AccountId__c = :a.Id AND Path__c = '/v1/account3'
        ];
        System.assertEquals(1, logs.size(), 'Somente 1 log devido ao dedupe');
        System.assertEquals(200, logs[0].StatusCode__c);
        System.assertEquals(true, logs[0].Success__c);
    }

    @IsTest
    static void test_204_response_no_log() {
        Id rtRetailer = getRtId('Retailer');
        if (rtRetailer == null) {
            System.assert(true, 'RecordType Retailer ausente nesta org de teste.');
            return;
        }

        Account a = makeAccount(rtRetailer, 'Retailer 204');

        List<PMC_SendDealerLocatorHttp.Request> reqs = new List<PMC_SendDealerLocatorHttp.Request>{
            reqOf(a, '/v1/account4', '{"ID":"' + a.Id + '"}')
        };

        Test.setMock(HttpCalloutMock.class, new DealerLocatorMock());
        statusToReturn = 204;
        bodyToReturn   = '';

        Test.startTest();
        List<PMC_SendDealerLocatorHttp.Response> out = PMC_SendDealerLocatorHttp.send(reqs);
        Test.stopTest();

        System.assertEquals(1, out.size());
        System.assertEquals(204, out[0].statusCode, 'Resposta 204');

        Integer cnt = [SELECT COUNT() FROM PMC_IntegrationLog__c WHERE AccountId__c = :a.Id AND Path__c = '/v1/account4'];
        System.assertEquals(0, cnt, 'Não deve logar quando status 204');
    }
}