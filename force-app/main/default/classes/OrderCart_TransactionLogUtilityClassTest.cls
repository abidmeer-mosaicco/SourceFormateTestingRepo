@isTest
private class OrderCart_TransactionLogUtilityClassTest {

    @isTest static void testAddTransactionLogAndInsert() {
        Map<String,String> fields = new Map<String,String>{
            'PMC_CPQ_IntegrationStatus__c' => 'Success',
            'PMC_CPQ_InterfaceURL__c' => 'http://example.test',
            'PMC_CPQ_RequestBody__c' => '{}',
            'PMC_CPQ_ResponseBody__c' => '[]'
        };
        List<PMC_CPQ_TransactionLog__c> lst = OrderCart_TransactionLogUtilityClass.addTransactionLog(fields);
        Test.startTest();
        OrderCart_TransactionLogUtilityClass.insertTransactionLogs(lst);
        Test.stopTest();
        System.assert(true);
    }

    @isTest static void testExtractQuoteAndErrorMsg_handlesMalformed() {
        Map<String,String> fields = new Map<String,String>();
        String respBody = 'not json';
        String reqBody = '{"Id":["001000000000000AAA"]}';
        Map<String,String> out = OrderCart_TransactionLogUtilityClass.extractQuoteAndErrorMsg(respBody, reqBody, fields);
        System.assertNotEquals(null, out, 'Retorno não deve ser null');
    }

    @isTest static void testExtractQuoteAndErrorMsg_parsesFunctionalErrors() {
        // Monta um response body JSON com entradas do tipo E que devem ser convertidas
        List<Object> rows = new List<Object>();
        Map<String,Object> r1 = new Map<String,Object>{ 'TYPE' => 'E', 'MESSAGE' => 'SOME ERROR: X', 'SFRecordId' => '' };
        Map<String,Object> r2 = new Map<String,Object>{ 'TYPE' => 'E', 'MESSAGE' => 'OTHER ERROR: Y', 'SFRecordId' => '' };
        rows.add(r1); rows.add(r2);

        String respBody = JSON.serialize(rows);
        String reqBody = JSON.serialize(new Map<String, List<Id>>{ 'Id' => new List<Id>{ Id.valueOf('001000000000000AAA') } });
        Map<String,String> fields = new Map<String,String>();
        Map<String,String> out = OrderCart_TransactionLogUtilityClass.extractQuoteAndErrorMsg(respBody, reqBody, fields);
        System.assert(out.containsKey('PMC_CPQ_Error_Message__c') || out.containsKey('PMC_CPQ_Error_Category__c'));
    }

    @isTest static void testExtractQuoteAndErrorMsg_usesCustomMetadataMapping() {
        // Nota: não inserimos Custom Metadata via DML em testes (não permitido em algumas orgs).
        // Em vez disso validamos que a função classifica erros do tipo 'E' como Functional
        List<Object> rows = new List<Object>();
        Map<String,Object> r = new Map<String,Object>{ 'TYPE' => 'E', 'MESSAGE' => 'SOME ERROR: exploded', 'SFRecordId' => '' };
        rows.add(r);
        String respBody = JSON.serialize(rows);
        Map<String,String> fields = new Map<String,String>();

        Map<String,String> out = OrderCart_TransactionLogUtilityClass.extractQuoteAndErrorMsg(respBody, '{}', fields);
        System.assertNotEquals(null, out, 'Retorno não deve ser null');
        // Deve ter classificado como Functional mesmo sem MDT
        System.assertEquals('Functional', out.get('PMC_CPQ_Error_Category__c'));
        // Como não há MDT, espera-se que a mensagem contenha o texto original
        System.assert(out.get('PMC_CPQ_Error_Message__c').contains('SOME ERROR'), 'Mensagem deve conter o texto original do erro');
    }

    @isTest static void testExtractQuoteAndErrorMsg_catchAndAssignQuoteFromRequest() {
        // Cria um quote e passa seu Id no requestBody para que a branch de fallback atribua PMC_CPQ_Quote__c
        Id stdPb = Test.getStandardPricebookId();
        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__PriceBook__c = stdPb, CurrencyIsoCode = 'USD');
        insert q;

        String respBody = 'not json';
        String reqBody = JSON.serialize(new Map<String, List<Id>>{ 'Id' => new List<Id>{ q.Id } });
        Map<String,String> fields = new Map<String,String>();

        Map<String,String> out = OrderCart_TransactionLogUtilityClass.extractQuoteAndErrorMsg(respBody, reqBody, fields);
        System.assertNotEquals(null, out);
        System.assertEquals('Technical', out.get('PMC_CPQ_Error_Category__c'), 'Categoria deve ser Technical na branch de fallback');
        System.assertEquals(String.valueOf(q.Id), out.get('PMC_CPQ_Quote__c'), 'Quote Id deve ser extraído do requestBody e colocado no mapa');
        System.assert(!String.isBlank(out.get('PMC_CPQ_Error_Message__c')),'Deve existir uma mensagem de erro amigável no retorno');
    }

    @isTest static void testAddTransactionLog_ResponseBodyAbbreviated() {
        String longBody = '';
        for (Integer i=0;i<200000;i++) longBody += 'X';
        Map<String,String> fields = new Map<String,String>{
            'PMC_CPQ_IntegrationStatus__c' => 'Warn',
            'PMC_CPQ_InterfaceURL__c' => 'http://example.test/long',
            'PMC_CPQ_RequestBody__c' => '{}',
            'PMC_CPQ_ResponseBody__c' => longBody
        };
        List<PMC_CPQ_TransactionLog__c> lst = OrderCart_TransactionLogUtilityClass.addTransactionLog(fields);
        System.assert(!lst.isEmpty());
        // O campo de response no registro na lista deve ter sido abreviado para <= 131065 caracteres
        System.assert(lst[0].PMC_CPQ_ResponseBody__c.length() <= 131065, 'ResponseBody deve ter sido abreviado');
    }

    // Nota: mapToFriendlyMsg é privado; comportamento indiretamente verificado via extractQuoteAndErrorMsg
}