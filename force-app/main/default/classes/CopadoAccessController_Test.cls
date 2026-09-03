/**
* @File Name : CopadoAccessController_Test.cls
* @Description : Unit tests for CopadoAccessController.
 *              - Verifies request creation.
 *              - Exercises email path only when labels enable it (no hardcoding).
 *              - Validates picklist helper methods.
* @Author :
* @Last Modified By :
* @Last Modified On : August 28, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 28, 2025 |   | Initial Version
**/


@IsTest(SeeAllData=true)
private class CopadoAccessController_Test {

    /**
     * @description If labels enable email, ensure: (1) a merge Contact exists, (2) an EmailTemplate exists
     *              with DeveloperName = System.Label.Copado_Access_Email_Template in an existing Email folder.
     *              No Folder DML is performed.
     */
    private static void ensureEmailPathPrereqs() {
        final String recipients = System.Label.Copado_Admin_Users;
        final String tmplDev    = System.Label.Copado_Access_Email_Template;

        // If no recipients, controller will skip email — nothing to prep.
        if (String.isBlank(recipients)) return;
        // If recipients exist but template dev name missing, let controller skip (avoid brittle assumptions).
        if (String.isBlank(tmplDev)) return;

        // 1) Ensure at least one Contact exists for template merge
        if ([SELECT COUNT() FROM Contact] == 0) {
            insert new Contact(LastName = 'Merge User', Email = 'merge@example.com');
        }

        // 2) Reuse an existing Email folder (common: 'unfiled$public'); fall back to any Email folder
        Id emailFolderId;
        List<Folder> f = [
            SELECT Id FROM Folder
            WHERE Type = 'Email' AND DeveloperName = 'unfiled$public' LIMIT 1
        ];
        if (f.isEmpty()) {
            f = [SELECT Id FROM Folder WHERE Type = 'Email' LIMIT 1];
        }
        System.assert(!f.isEmpty(), 'No Email folder available in org to store EmailTemplate.');
        emailFolderId = f[0].Id;

        // 3) Create the EmailTemplate only if one with the exact DeveloperName doesn't already exist
        if ([SELECT COUNT() FROM EmailTemplate WHERE DeveloperName = :tmplDev] == 0) {
            insert new EmailTemplate(
                Name          = 'Copado Access Test Template',
                DeveloperName = tmplDev,
                FolderId      = emailFolderId,
                Subject       = 'Copado Access Request: {!Copado_Access_Request__c.Name}',
                HtmlValue     = '<html><body>' +
                                'Hello {!Contact.Name},<br/>' +
                                'Request: {!Copado_Access_Request__c.Name}<br/>' +
                                'Env: {!Copado_Access_Request__c.Environment__c}, ' +
                                'Role: {!Copado_Access_Request__c.Copado_Role__c}' +
                                '</body></html>'
            );
        }
    }

    /**
     * @description Creates a request and (optionally) exercises the email path based on labels.
     * @expectedResults A Copado_Access_Request__c is created with Status = 'New'.
     */
    @IsTest
    static void test_createRequest() {
        ensureEmailPathPrereqs();

        Test.startTest();
        Id reqId = CopadoAccessController.createCopadoAccessRequest(
            'John Doe', 'john.doe@example.com','salesforceuser@dev.com', 'Project A', 'Admin', 'Need access for QA', 
            'manager@example.com');
        Test.stopTest();

        Copado_Access_Request__c rec = [
            SELECT Id, Full_Name__c, Email__c, Status__c, Project_Name__c, Copado_Role__c
            FROM Copado_Access_Request__c WHERE Id = :reqId
        ];
        System.assertEquals('John Doe', rec.Full_Name__c);
        System.assertEquals('john.doe@example.com', rec.Email__c);
        System.assertEquals('New', rec.Status__c);
        System.assertEquals('Project A', rec.Project_Name__c);
        System.assertEquals('Admin', rec.Copado_Role__c);
    }


    /**
     * @description Verifies Copado_Role__c picklist labels are returned.
     */
    @IsTest
    static void test_getCopadoRolePicklistValues() {
        Test.startTest();
        List<String> vals = CopadoAccessController.getCopadoRolePicklistValues();
        Test.stopTest();
        System.assertNotEquals(null, vals);
    }
}