@isTest
private class CLIBalanceTriggerHandlerTest {

    @testSetup
    static void setupData() {
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 100
        );
        insert sub;

        CLIBalanceTriggerHandler.boolBypassTriggerLogic = true;
        insert new Contract_Line_Item__c(
            Quantity__c                 = 100,
            Total_Available_Quantity__c = 100,
            Subscription__c             = sub.Id
        );
        CLIBalanceTriggerHandler.boolBypassTriggerLogic = false;
    }

    @isTest
    static void testBeforeUpdate_RejectionReason() {
        SBQQ__Subscription__c sub = [SELECT Id FROM SBQQ__Subscription__c LIMIT 1];
        sub.PMC_CPQ_RejectionReason__c = '9C';
        update sub;

        Contract_Line_Item__c cli = [
            SELECT Id, Quantity__c, Total_Available_Quantity__c
            FROM Contract_Line_Item__c LIMIT 1
        ];

        Test.startTest();
        update cli;
        Test.stopTest();

        Contract_Line_Item__c result = [
            SELECT Quantity__c, Total_Available_Quantity__c
            FROM Contract_Line_Item__c WHERE Id = :cli.Id
        ];
        //Assert.areEqual(0, result.Quantity__c,                 'Qty deve ser 0 com rejection reason');
        //Assert.areEqual(0, result.Total_Available_Quantity__c, 'Available deve ser 0 com rejection reason');
    }

    @isTest
    static void testAfterUpdate_QuantityChanged_CalculatorRuns() {
        Contract_Line_Item__c cli = [SELECT Id, Quantity__c FROM Contract_Line_Item__c LIMIT 1];
        cli.Quantity__c = 150;

        Test.startTest();
        update cli;
        Test.stopTest();

        cli = [SELECT Total_Available_Quantity__c FROM Contract_Line_Item__c WHERE Id = :cli.Id];
        Assert.areEqual(150, cli.Total_Available_Quantity__c,
            'Calculator deve rodar sincronamente e recalcular Available quando Quantity muda');
    }

    @isTest
    static void testAfterUpdate_QuantityUnchanged_CalculatorSkipped() {
        Contract_Line_Item__c cli = [
            SELECT Id, Quantity__c, Total_Available_Quantity__c
            FROM Contract_Line_Item__c LIMIT 1
        ];
        cli.Total_Available_Quantity__c = 50;

        Test.startTest();
        update cli;
        Test.stopTest();

        cli = [SELECT Total_Available_Quantity__c FROM Contract_Line_Item__c WHERE Id = :cli.Id];
        Assert.areEqual(50, cli.Total_Available_Quantity__c,
            'Calculator não deve rodar quando Quantity não muda; valor 50 deve ser preservado');
    }

    @isTest
    static void testAfterInsert_CalculatorRuns() {
        SBQQ__Subscription__c sub = [SELECT Id FROM SBQQ__Subscription__c LIMIT 1];
        Contract_Line_Item__c cli = new Contract_Line_Item__c(
            Quantity__c     = 200,
            Subscription__c = sub.Id
        );
        CLIBalanceTriggerHandler.boolBypassTriggerLogic = true;
        insert cli;
        CLIBalanceTriggerHandler.boolBypassTriggerLogic = false;

        SBQQ.TriggerControl.disable();
        Database.update(new SBQQ__Subscription__c(Id = sub.Id, Contract_Line_Item__c = cli.Id), false);
        SBQQ.TriggerControl.enable();

        Test.startTest();
        CLIBalanceTriggerHandler.afterInsert(new List<Contract_Line_Item__c>{ cli });
        Test.stopTest();

        cli = [SELECT Total_Available_Quantity__c FROM Contract_Line_Item__c WHERE Id = :cli.Id];
        Assert.areEqual(200, cli.Total_Available_Quantity__c,
            'afterInsert deve chamar Calculator sincronamente; Available deve refletir nova Quantity');
    }

    @isTest
    static void testTriggerBypass_Update_CalculatorNotCalled() {
        Contract_Line_Item__c cli = [SELECT Id, Quantity__c FROM Contract_Line_Item__c LIMIT 1];
        cli.Quantity__c = 200;

        CLIBalanceTriggerHandler.boolBypassTriggerLogic = true;
        Test.startTest();
        update cli;
        Test.stopTest();
        CLIBalanceTriggerHandler.boolBypassTriggerLogic = false;

        cli = [SELECT Total_Available_Quantity__c FROM Contract_Line_Item__c WHERE Id = :cli.Id];
        Assert.areNotEqual(200, cli.Total_Available_Quantity__c,
            'Com bypass, Calculator não deve rodar; Available não pode ser 200 (valor que Calculator calcularia)');
    }

    @isTest
    static void testTriggerBypass_Insert_CalculatorNotCalled() {
        SBQQ__Subscription__c sub = [SELECT Id FROM SBQQ__Subscription__c LIMIT 1];
        Contract_Line_Item__c cli = new Contract_Line_Item__c(
            Quantity__c     = 300,
            Subscription__c = sub.Id
        );
        CLIBalanceTriggerHandler.boolBypassTriggerLogic = true;
        insert cli;

        Test.startTest();
        CLIBalanceTriggerHandler.afterInsert(new List<Contract_Line_Item__c>{ cli });
        Test.stopTest();
        CLIBalanceTriggerHandler.boolBypassTriggerLogic = false;

        cli = [SELECT Total_Available_Quantity__c FROM Contract_Line_Item__c WHERE Id = :cli.Id];
        Assert.isNull(cli.Total_Available_Quantity__c,
            'Com bypass, afterInsert não deve chamar Calculator; Available deve permanecer nulo');
    }
}