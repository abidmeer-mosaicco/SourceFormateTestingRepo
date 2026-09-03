@IsTest
private class IcsInviteService_Test {

  private static Datetime baseStart() {
    // Dia de amanhã às 09:00
    Date d = Date.today().addDays(1);
    return Datetime.newInstance(d, Time.newInstance(9, 0, 0, 0));
}

private static Datetime baseEnd() {
    return baseStart().addHours(1);
}


    @IsTest
    static void testCreate_basicSuccess_single() {
        // Request com todos os campos preenchidos
        IcsInviteService.Request req = new IcsInviteService.Request();
        req.startTime       = baseStart();
        req.endTime         = baseEnd();
        req.subject         = 'Reunião, vendas; Q3'; // tem vírgula e ponto e vírgula para testar sanitize
        req.descriptionText = 'Linha 1\nLinha 2';    // testar \n -> \\n
        req.organizerName   = 'Equipe Scheduler';
        req.organizerEmail  = 'organizer@example.com';
        req.attendeeEmails  = 'a1@example.com; a2@example.com, a3@example.com'; // mistura ; e ,
        // sem linkEntityId aqui

        Test.startTest();
        List<IcsInviteService.Response> out = IcsInviteService.create(
            new List<IcsInviteService.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, out.size(), 'Deve retornar 1 Response');
        System.assertNotEquals(null, out[0].contentVersionId, 'ContentVersion deve ter sido criado');
        System.assertEquals('invite.ics', out[0].fileName, 'Nome do arquivo deve ser invite.ics');

        // Verifica ContentVersion salvo
        ContentVersion cv = [
            SELECT Id, Title, PathOnClient, VersionData, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :out[0].contentVersionId
            LIMIT 1
        ];
        System.assertEquals('Reunião, vendas; Q3'.left(80), cv.Title, 'Title deve ser subject limitado a 80 chars');
        System.assertEquals('invite.ics', cv.PathOnClient);

        // Verifica conteúdo do ICS (sanitizações e campos essenciais)
        String ics = cv.VersionData.toString();
        System.assert(ics.contains('BEGIN:VCALENDAR'), 'Deve conter BEGIN:VCALENDAR');
        System.assert(ics.contains('METHOD:REQUEST'), 'Deve conter METHOD:REQUEST');
        System.assert(ics.contains('BEGIN:VEVENT'), 'Deve conter BEGIN:VEVENT');
        System.assert(ics.contains('DTSTART:'), 'Deve conter DTSTART');
        System.assert(ics.contains('DTEND:'), 'Deve conter DTEND');
        System.assert(ics.contains('DTSTAMP:'), 'Deve conter DTSTAMP');

        // SUMMARY com vírgula e ; devem estar escapados
        System.assert(ics.contains('SUMMARY:Reunião\\, vendas\\; Q3'), 'Vírgula e ; devem ser escapados em SUMMARY');

        // DESCRIPTION com \n -> \\n
       System.assert(ics.contains('DESCRIPTION:Linha 1\\\\nLinha 2'), 'Quebra de linha deve ser \\\\n');

        // ORGANIZER
        System.assert(ics.contains('ORGANIZER;CN=Equipe Scheduler:MAILTO:organizer@example.com'),
                      'Organizer deve estar formatado corretamente');

        // ATTENDEE lines para 3 e-mails
        System.assert(ics.contains('ATTENDEE;CN=a1@example.com;RSVP=TRUE:MAILTO:a1@example.com'));
        System.assert(ics.contains('ATTENDEE;CN=a2@example.com;RSVP=TRUE:MAILTO:a2@example.com'));
        System.assert(ics.contains('ATTENDEE;CN=a3@example.com;RSVP=TRUE:MAILTO:a3@example.com'));
    }

    @IsTest
    static void testCreate_defaults_and_linkEntity() {
        // Entidade para publicar (Account usada como exemplo)
        Account acc = new Account(Name = 'Conta Link');
        insert acc;

        // Request com vários campos em branco/nulos -> usa defaults
        IcsInviteService.Request req = new IcsInviteService.Request();
        req.startTime       = baseStart();
        req.endTime         = baseEnd();
        req.subject         = '';           // default -> "Appointment"
        req.descriptionText = null;         // default -> ''
        req.organizerName   = null;         // default -> "Organizer"
        req.organizerEmail  = '';           // default -> UserInfo.getUserEmail()
        req.attendeeEmails  = null;         // sem attendees
        req.linkEntityId    = acc.Id;       // publica no registro

        Test.startTest();
        List<IcsInviteService.Response> out = IcsInviteService.create(
            new List<IcsInviteService.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, out.size());
        System.assertNotEquals(null, out[0].contentVersionId);

        ContentVersion cv = [
            SELECT Id, Title, PathOnClient, VersionData, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :out[0].contentVersionId
            LIMIT 1
        ];
        // Subject default
        System.assertEquals('Appointment', cv.Title, 'Quando subject vazio, Title deve ser "Appointment"');
        String ics = cv.VersionData.toString();

        // Organizer defaults
        System.assert(ics.contains('ORGANIZER;CN=Organizer:MAILTO:' + UserInfo.getUserEmail()),
                      'Organizer default deve usar CN=Organizer e email do usuário atual');

        // DESCRIPTION vazio e sem ATTENDEE
        System.assert(ics.contains('DESCRIPTION:'), 'Deve ter linha DESCRIPTION (vazia é ok)');
        System.assertEquals(-1, ics.indexOf('ATTENDEE;CN='), 'Não deve ter nenhuma linha de attendee');

        // Verifica que foi publicado no registro passado (ContentDocumentLink criado)
        // O insert com FirstPublishLocationId cria automaticamente o link
        ContentDocumentLink cdl = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            LIMIT 1
        ];
        System.assertEquals(acc.Id, cdl.LinkedEntityId, 'ContentDocument deve estar linkado à entidade informada');
    }

    @IsTest
    static void testCreate_multiple_and_null_tail_and_null_dates() {
        // Dois válidos + um null no FINAL (importante para cobrir o caminho sem quebrar o mapeamento por índice)
        IcsInviteService.Request r1 = new IcsInviteService.Request();
        r1.startTime       = baseStart();
        r1.endTime         = baseEnd();
        r1.subject         = 'S1';
        r1.descriptionText = 'D1';
        r1.organizerName   = 'Org1';
        r1.organizerEmail  = 'o1@example.com';
        r1.attendeeEmails  = 'x@y.com';

        IcsInviteService.Request r2 = new IcsInviteService.Request();
        // De propósito, datas nulas para exercitar formatIcsDate fallback
        r2.startTime       = null;
        r2.endTime         = null;
        r2.subject         = 'S2';
        r2.descriptionText = 'D2';
        r2.organizerName   = 'Org2';
        r2.organizerEmail  = 'o2@example.com';
        r2.attendeeEmails  = 'z@y.com';

        IcsInviteService.Request rNull = null;

        Test.startTest();
        List<IcsInviteService.Response> out = IcsInviteService.create(
            new List<IcsInviteService.Request>{ r1, r2, rNull }
        );
        Test.stopTest();

        // Deve haver 3 responses (o último é vazio)
        System.assertEquals(3, out.size(), 'Deve retornar 3 responses');

        // Os dois primeiros devem ter ContentVersionId
        System.assertNotEquals(null, out[0].contentVersionId, 'Primeiro válido deve ter CV Id');
        System.assertNotEquals(null, out[1].contentVersionId, 'Segundo válido deve ter CV Id');

        // O último (null) permanece sem Id
        System.assertEquals(null, out[2].contentVersionId, 'Response do request null não deve ter CV Id');

        // Verifica r2 com datas nulas gerou ICS com DTSTART/DTEND
        ContentVersion cv2 = [
            SELECT Id, VersionData
            FROM ContentVersion
            WHERE Id = :out[1].contentVersionId
            LIMIT 1
        ];
        String ics2 = cv2.VersionData.toString();
        System.assert(ics2.contains('DTSTART:'), 'Mesmo com datas nulas, deve gerar DTSTART');
        System.assert(ics2.contains('DTEND:'), 'Mesmo com datas nulas, deve gerar DTEND');
        // Não validamos o valor exato pois é baseado em now() dentro do método
    }
}