@IsTest
private class ServiceAppointmentOwnerUpdaterTest {
@TestSetup
static void setup() {
    // 1) Conta + Contato (para cumprir validação que exige ContactId)
    Account acc = new Account(Name = 'Conta Teste');
    insert acc;

    Contact con = new Contact(
        FirstName = 'Teste',
        LastName  = 'Contato',
        AccountId = acc.Id,
        Email     = 'contato+' + System.now().getTime() + '@teste.com'
    );
    insert con;

    // 2) Lead para ser o PAI do ServiceAppointment
    Lead ld = new Lead(
        FirstName = 'Pai',
        LastName  = 'Lead',
        Company   = 'Empresa Lead',
        email = 'email@gmail.com',
        Status    = 'Open - Not Contacted' // ajuste para um Status válido na sua org se necessário
    );
    insert ld;

    // 3) (Opcional) ServiceTerritory/Status, se sua org exigir
    // ServiceTerritory st = new ServiceTerritory(Name = 'Território de Teste');
    // insert st;

    // 4) ServiceAppointment com Parent = Lead e ContactId preenchido
    ServiceAppointment sa = new ServiceAppointment();
    sa.Subject           = 'SA de Teste (Parent=Lead)';
    sa.ParentRecordId    = ld.Id;     // <<< PAI = LEAD
    sa.ContactId         = con.Id;    // <<< Cumpre validação "Please select contact"
    sa.EarliestStartTime = System.now().addHours(1);
    sa.DueDate           = System.now().addHours(2);
    // Se necessário na sua org:
    // sa.Status = 'New';
    // sa.ServiceTerritoryId = st.Id;

    insert sa;

    // 5) Usuário para virar Owner
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User u = new User(
        Alias             = 'towner',
        Email             = 'towner' + System.now().getTime() + '@test.com',
        EmailEncodingKey  = 'UTF-8',
        LastName          = 'Owner',
        LanguageLocaleKey = 'pt_BR',
        LocaleSidKey      = 'pt_BR',
        TimeZoneSidKey    = 'America/Sao_Paulo',
        Username          = 'towner' + System.now().getTime() + '@test.com',
        ProfileId         = p.Id
    );
    insert u;

    // 6) Registro auxiliar para teste de Owner inválido
    Account accOwnerInvalido = new Account(Name = 'Conta para Owner Inválido');
    insert accOwnerInvalido;
}


    @IsTest
    static void testUpdateOwner_Sucesso() {
        // Dados de teste
        ServiceAppointment sa = [
            SELECT Id, OwnerId
            FROM ServiceAppointment
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        User newOwner = [
            SELECT Id
            FROM User
            WHERE Alias = 'towner'
            LIMIT 1
        ];

        // Monta a requisição
        ServiceAppointmentOwnerUpdater.Request req = new ServiceAppointmentOwnerUpdater.Request();
        req.serviceAppointmentId = sa.Id;
        req.ownerId = newOwner.Id;

        Test.startTest();
        List<ServiceAppointmentOwnerUpdater.Response> res =
            ServiceAppointmentOwnerUpdater.updateOwner(new List<ServiceAppointmentOwnerUpdater.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size(), 'Deve retornar uma resposta');
        System.assertEquals('OK', res[0].status, 'Status deve ser OK');
        System.assertEquals('Owner updated successfully.', res[0].message, 'Mensagem de sucesso esperada');

        // Verifica se o Owner foi realmente alterado
        ServiceAppointment saAfter = [
            SELECT OwnerId
            FROM ServiceAppointment
            WHERE Id = :sa.Id
        ];
        System.assertEquals(newOwner.Id, saAfter.OwnerId, 'OwnerId deve ter sido atualizado');
    }

    @IsTest
    static void testUpdateOwner_ErroCamposObrigatorios() {
        // Requisições com campos faltando
        ServiceAppointmentOwnerUpdater.Request rNull = null;

        ServiceAppointmentOwnerUpdater.Request rSemSA = new ServiceAppointmentOwnerUpdater.Request();
        rSemSA.serviceAppointmentId = null;
        rSemSA.ownerId = UserInfo.getUserId();

        ServiceAppointmentOwnerUpdater.Request rSemOwner = new ServiceAppointmentOwnerUpdater.Request();
        rSemOwner.serviceAppointmentId = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
        rSemOwner.ownerId = null;

        Test.startTest();
        List<ServiceAppointmentOwnerUpdater.Response> res =
            ServiceAppointmentOwnerUpdater.updateOwner(new List<ServiceAppointmentOwnerUpdater.Request>{
                rNull, rSemSA, rSemOwner
            });
        Test.stopTest();

        System.assertEquals(3, res.size(), 'Devem existir 3 respostas');

        for (ServiceAppointmentOwnerUpdater.Response r : res) {
            System.assertEquals('ERROR', r.status, 'Todos devem falhar por falta de campos');
            System.assertEquals('Both serviceAppointmentId and ownerId are required.', r.message);
        }
    }

    @IsTest
    static void testUpdateOwner_ErroOwnerInvalido() {
        // Usa um Id que não é de User para provocar DMLException (ex.: Account.Id)
        Id invalidOwnerId = [SELECT Id FROM Account LIMIT 1].Id;
        Id saId = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;

        ServiceAppointmentOwnerUpdater.Request req = new ServiceAppointmentOwnerUpdater.Request();
        req.serviceAppointmentId = saId;
        req.ownerId = invalidOwnerId;

        Test.startTest();
        List<ServiceAppointmentOwnerUpdater.Response> res =
            ServiceAppointmentOwnerUpdater.updateOwner(new List<ServiceAppointmentOwnerUpdater.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals('ERROR', res[0].status, 'Deve falhar por ownerId inválido');
        System.assertNotEquals(null, res[0].message, 'Mensagem de erro deve vir preenchida');
        System.assert(res[0].message.contains('INVALID_CROSS_REFERENCE_KEY')
                      || res[0].message.contains('OwnerId'),
            'Mensagem deve indicar problema no OwnerId: ' + res[0].message);
    }
}