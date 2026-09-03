@IsTest
private class ApprovalHistoryControllerTest {

    @IsTest
    static void testGetApprovalHistory_WithRealInsert() {
        // Get two active users
        List<User> users = [SELECT Id, Name FROM User WHERE IsActive = true LIMIT 2];
        User reviewer = users[0];
        User approver = users[1];

        // Create dummy Contact
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert testContact;

        // Create dummy Case with ContactId (to bypass validation rule)
        Case testCase = new Case(
            Subject = 'Test Case for Approval History',
            ContactId = testContact.Id
        );
        insert testCase;

        // Create ApprovalWorkItemClone__c record
        ApprovalWorkItemClone__c approvalItem = new ApprovalWorkItemClone__c(
            RelatedRecordId__c = testCase.Id,
            Name = 'Test Approval Item',
            Comments__c = 'This is a test comment.',
            Status__c = 'Pending',
            ReviewedById__c = reviewer.Id,
            Assigned_To__c = approver.Id,
            ReviewedDate__c = System.now()
        );
        insert approvalItem;

        // Call controller
        Test.startTest();
        List<ApprovalHistoryController.ApprovalWorkItemWrapper> result =
            ApprovalHistoryController.getApprovalHistory(testCase.Id);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, result.size(), 'Expected one approval item');
        System.assertEquals('Test Approval Item', result[0].name, 'Expected name');
        System.assertEquals('This is a test comment.', result[0].comments, 'Expected comments');
        System.assertEquals('Pending', result[0].status, 'Expected status');
        System.assertEquals(reviewer.Id, result[0].reviewedById, 'Expected reviewer ID');
        System.assertEquals(approver.Id, result[0].assignedToId, 'Expected assignedTo ID');
    }
}