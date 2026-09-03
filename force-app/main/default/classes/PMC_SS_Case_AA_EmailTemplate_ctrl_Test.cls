@isTest
public class PMC_SS_Case_AA_EmailTemplate_ctrl_Test {

    @isTest
    static void testControllerMethods() {
        
        // Create test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        //Create test Contact
        Contact con = new Contact (FirstName = 'Test FName', LastName = 'Test LName', Email = 'test@test.Mosaic.com',AccountId = acc.Id);
        insert con;
        
		Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PMC_SS_CaseGeneral').getRecordTypeId();
        // Create test Case
        Case cs = new Case(
            Subject = 'Test Case Subject', 
            Description = 'Test Description',
            AccountId = acc.Id,
            ContactId = con.Id,
            PMC_SS_AtFaultParty__c = 'Customer',
            PMC_SS_OriginalInvoiceAmount__c = 456.789,
            PMC_SS_RebillAmount__c = 123.456,
            PMC_SS_InvoiceDifference__c = 333.333,
            RecordTypeId = caseRecordTypeId
        );
        insert cs;

        // Create test Users
        User approverUser = [SELECT Id,Name FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        User assignedToUser = approverUser;
        
        sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__User__c = approverUser.Id, Name = approverUser.Name);

        // Create test sbaa__Approval__c record
        sbaa__Approval__c approval = new sbaa__Approval__c(
            sbaa__Approver__c = approver.Id,
            sbaa__AssignedTo__c = assignedToUser.Id,
            sbaa__ApprovalStep__c = 1,
            sbaa__RecordField__c = 'Case__c'
        );
        insert approval;

        // Instantiate the controller and set parameters
        Test.startTest();
        PMC_SS_Case_AA_EmailTemplate_ctrl controller = new PMC_SS_Case_AA_EmailTemplate_ctrl();
        controller.caseId = cs.Id;
        controller.approvalId = approval.Id;

        // Call methods results
        Case fetchedCase = controller.getcaseRecord();
        sbaa__Approval__c fetchedApproval = controller.getapprovalRecord();
        String caseLink = controller.getcaseLink();
        String approvalLink = controller.getapprovalLink();
        String rebillFormatted = controller.getFormattedRebillAmount();
        String originalFormatted = controller.getFormattedOriginalInvoiceAmount();
        String diffFormatted = controller.getFormattedInvoiceDifference();
        Test.stopTest();
         //Assert values
        System.assertNotEquals(null, fetchedCase);
        System.assertEquals(cs.Id, fetchedCase.Id);
        System.assertNotEquals(null, fetchedApproval);
        System.assertEquals(approval.Id, fetchedApproval.Id);
        System.assert(caseLink.contains(cs.Id));
        System.assert(approvalLink.contains(approval.Id));
        System.assertEquals('123.46', rebillFormatted);
        System.assertEquals('456.79', originalFormatted);
        System.assertEquals('333.33', diffFormatted);
    }
}