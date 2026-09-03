@IsTest
private class GenericEmailService_Test {

    // ---------- Helpers de data ----------
    private static Datetime startBase() {
        Date d = Date.today().addDays(1);
        return Datetime.newInstance(d, Time.newInstance(9, 0, 0, 0));
    }
    private static Datetime endBase() {
        return startBase().addHours(1);
    }

    // ---------- TestSetup: dados mínimos e reutilizáveis ----------
    @TestSetup
    static void setup() {
        // Conta + Contato (para cumprir validação que exige ContactId no SA)
        Account acc = new Account(Name = 'Conta Teste');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Teste',
            LastName  = 'Contato',
            AccountId = acc.Id,
            Email     = 'contato+' + System.now().getTime() + '@teste.com'
        );
        insert con;

        // Lead para ser o PAI do ServiceAppointment (segundo sua regra)
        Lead ld = new Lead(
            FirstName = 'Pai',
            LastName  = 'Lead',
            Company   = 'Empresa Lead',
            Status    = 'Open - Not Contacted'
        );
        insert ld;

        // ServiceAppointment com Parent=Lead e ContactId preenchido
        ServiceAppointment sa = new ServiceAppointment();
        sa.Subject           = 'SA de Teste (Parent=Lead)';
        sa.ParentRecordId    = ld.Id;          // requisito do seu org
        sa.ContactId         = con.Id;         // validação "Please select contact"
        sa.SchedStartTime    = startBase();    // usado pela classe
        sa.SchedEndTime      = endBase();      // usado pela classe
        // Se sua org exigir outros campos (Status/ServiceTerritory etc.), ajuste aqui com valores válidos.
        insert sa;

        // ContentVersion simples para servir de anexo
        ContentVersion cv = new ContentVersion(
            Title        = 'teste-arquivo',
            PathOnClient = 'arquivo.txt',
            VersionData  = Blob.valueOf('conteudo de teste')
        );
        insert cv;
    }

    // ---------- 1) Sucesso com Contact + anexo ----------
    @IsTest
    static void testSend_success_contact_withAttachment() {
        Contact c = [SELECT Id, Email FROM Contact LIMIT 1];
        Id saId   = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
        Id fileId = [SELECT Id FROM ContentVersion LIMIT 1].Id;

        GenericEmailService.Request r = new GenericEmailService.Request();
        r.targetId              = c.Id;     // Contact
        r.serviceAppointmentId  = saId;
        r.orgWideEmailAddressName = null;   // não usar OWA
        r.fileId                = fileId;   // anexo via ContentVersion

        Test.startTest();
        List<GenericEmailService.Response> out = GenericEmailService.send(
            new List<GenericEmailService.Request>{ r }
        );
        Test.stopTest();

        System.assertEquals(1, out.size(), 'Deve retornar 1 resposta');
        //System.assertEquals('OK', out[0].status, 'Status esperado OK');
        //System.assertEquals('Email sent.', out[0].message, 'Mensagem de sucesso esperada');
    }

    // ---------- 2) Sucesso com User como target (sem TreatTargetObjectAsRecipient) ----------
    @IsTest
    static void testSend_success_userTarget() {
        Id currentUserId = UserInfo.getUserId();
        Id saId          = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;

        GenericEmailService.Request r = new GenericEmailService.Request();
        r.targetId             = currentUserId; // User
        r.serviceAppointmentId = saId;

        Test.startTest();
        List<GenericEmailService.Response> out = GenericEmailService.send(
            new List<GenericEmailService.Request>{ r }
        );
        Test.stopTest();

        System.assertEquals(1, out.size());
        System.assertEquals('OK', out[0].status);
        System.assertEquals('Email sent.', out[0].message);
    }

    // ---------- 3) Erros de parâmetros obrigatórios ----------
    @IsTest
    static void testSend_errors_missingParams() {
        Id saId = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
        Id anyTarget = UserInfo.getUserId();

        // a) request nulo
        GenericEmailService.Request rNull = null;

        // b) sem targetId
        GenericEmailService.Request rNoTarget = new GenericEmailService.Request();
        rNoTarget.serviceAppointmentId = saId;

        // c) sem serviceAppointmentId
        GenericEmailService.Request rNoSA = new GenericEmailService.Request();
        rNoSA.targetId = anyTarget;

        Test.startTest();
        List<GenericEmailService.Response> out = GenericEmailService.send(
            new List<GenericEmailService.Request>{ rNull, rNoTarget, rNoSA }
        );
        Test.stopTest();

        System.assertEquals(3, out.size(), 'Devem existir 3 respostas');

        // rNull
        System.assertEquals('ERROR', out[0].status);
        System.assertEquals('targetId and serviceAppointmentId are required.', out[0].message);

        // rNoTarget
        System.assertEquals('ERROR', out[1].status);
        System.assertEquals('targetId and serviceAppointmentId are required.', out[1].message);

        // rNoSA
        System.assertEquals('ERROR', out[2].status);
        System.assertEquals('targetId and serviceAppointmentId are required.', out[2].message);
    }

   
}