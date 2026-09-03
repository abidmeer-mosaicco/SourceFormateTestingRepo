@isTest
private class CaseExtControllerTests {
    
    @TestSetup
    static void setup() {    
        // Create an Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a Contact
        Contact cont = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert cont;
        
        // Create an Order with the correct Pricebook2Id
        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            PMC_CPQ_SoldToAccount__c = acc.Id,
            PMC_CPQ_SAPOrderNumber__c = '6576512'
        );
        insert ord;
        
        // Create a Case
        Case cs = new Case(
            Subject = 'Test Case Subject',
            Status = 'New',
            Type = 'Inquiry',
            ContactId = cont.Id,
            PMC_SS_AtFaultParty__c = 'Carrier',
            PMC_SS_Order__c = ord.Id
        );
        insert cs;
    }
    
    testMethod static void testSubmit() {
        Case cse = [Select Id from Case LIMIT 1];
        
        Test.startTest();
        CaseExtController con = new CaseExtController(new ApexPages.StandardController(cse));
        con.onSubmit();
        cse = [SELECT ApprovalStatus__c FROM Case WHERE Id = :cse.Id LIMIT 1];
        Test.stopTest();
        System.assertEquals('Approved', cse.ApprovalStatus__c);
    }
    
    testMethod static void testRecall() {
        Case cse = [Select Id from Case LIMIT 1];
        
        Test.startTest();
        CaseExtController con = new CaseExtController(new ApexPages.StandardController(cse));
        con.onRecall();
        cse = [SELECT ApprovalStatus__c FROM Case WHERE Id = :cse.Id LIMIT 1];
        Test.stopTest();
        System.assertEquals('Recalled', cse.ApprovalStatus__c);
    }
    
    testMethod static void testinvokeURLAction() {
        Case cse = [Select Id from Case LIMIT 1];
        
        Test.startTest();
        CaseExtController.invokeURLAction(new List<String>{cse.Id});
        cse = [SELECT ApprovalStatus__c FROM Case WHERE Id = :cse.Id LIMIT 1];
        Test.stopTest();
        System.assertEquals('Approved', cse.ApprovalStatus__c);
    }
}