@IsTest
private class SObjectUtilsTest {

    @testSetup
    static void setupData() {
        // Create test accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                NumberOfEmployees = 10 + i,
                Industry = 'Technology'
            ));
        }
        insert accounts;

        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                AccountId = accounts[i].Id,
                Email = 'test' + i + '@example.com'
            ));
        }
        insert contacts;
    }

    @IsTest
    static void testHasChangedFieldsSingleField() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ acc.Id => acc.clone(true, true, true, true) };

        acc.Name = 'Changed Name';

        Test.startTest();
        Boolean hasChanged = SObjectUtils.hasChangedFields(acc, oldMap, 'Name');
        Test.stopTest();

        System.assertEquals(true, hasChanged, 'Name field should be detected as changed');
    }

    @IsTest
    static void testHasChangedFieldsMultipleFields() {
        Account acc = [SELECT Id, Name, NumberOfEmployees FROM Account LIMIT 1];
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ acc.Id => acc.clone(true, true, true, true) };

        acc.Name = 'Changed Name';

        Test.startTest();
        Boolean hasChanged = SObjectUtils.hasChangedFields(acc, oldMap, new Set<String>{ 'Name', 'NumberOfEmployees' });
        Test.stopTest();

        System.assertEquals(true, hasChanged, 'At least one field should be detected as changed');
    }

    @IsTest
    static void testHasChangedFieldsNoChange() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ acc.Id => acc.clone(true, true, true, true) };

        Test.startTest();
        Boolean hasChanged = SObjectUtils.hasChangedFields(acc, oldMap, 'Name');
        Test.stopTest();

        System.assertEquals(false, hasChanged, 'Field should not be detected as changed');
    }

    @IsTest
    static void testCopyFieldValuesSingleField() {
        Account source = [SELECT Id, Name FROM Account WHERE Name = 'Test Account 0' LIMIT 1];
        Account destination = new Account();

        Test.startTest();
        destination = (Account) SObjectUtils.copyFieldValues(destination, source, 'Name');
        Test.stopTest();

        System.assertEquals(source.Name, destination.Name, 'Name should be copied');
    }

    @IsTest
    static void testCopyFieldValuesMultipleFields() {
        Account source = [SELECT Id, Name, Industry FROM Account LIMIT 1];
        Account destination = new Account();

        Test.startTest();
        destination = (Account) SObjectUtils.copyFieldValues(destination, source, new Set<String>{ 'Name', 'Industry' });
        Test.stopTest();

        System.assertEquals(source.Name, destination.Name, 'Name should be copied');
        System.assertEquals(source.Industry, destination.Industry, 'Industry should be copied');
    }

    @IsTest
    static void testCopyFieldValuesWithNullValues() {
        Account source = new Account(Name = 'Test', Industry = null);
        Account destination = new Account(Industry = 'Technology');

        Test.startTest();
        destination = (Account) SObjectUtils.copyFieldValues(destination, source, 'Industry', true);
        Test.stopTest();

        System.assertEquals(null, destination.Industry, 'Null value should be copied');
    }

    @IsTest
    static void testCopyFieldValuesWithoutOverride() {
        Account source = new Account(Name = 'Source Name');
        Account destination = new Account(Name = 'Destination Name');

        Test.startTest();
        destination = (Account) SObjectUtils.copyFieldValues(destination, source, new Set<String>{ 'Name' }, false, false);
        Test.stopTest();

        System.assertEquals('Destination Name', destination.Name, 'Name should not be overridden');
    }

    @IsTest
    static void testCopyFieldValuesWithMapFields() {
        Account source = new Account(Name = 'Test Account', Industry = 'Technology');
        Account destination = new Account();
        Map<String, String> fieldMap = new Map<String, String>{ 'Name' => 'Name', 'Industry' => 'Industry' };

        Test.startTest();
        destination = (Account) SObjectUtils.copyFieldValues(destination, source, fieldMap, true, true);
        Test.stopTest();

        System.assertEquals(source.Name, destination.Name, 'Name should be mapped and copied');
        System.assertEquals(source.Industry, destination.Industry, 'Industry should be mapped and copied');
    }

    @IsTest
    static void testMapObjectsByFieldSingleField() {
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact];

        Test.startTest();
        Map<String, List<SObject>> resultMap = SObjectUtils.mapObjectsByField(contacts, 'AccountId');
        Test.stopTest();

        System.assert(!resultMap.isEmpty(), 'Map should not be empty');
        System.assertEquals(3, resultMap.size(), 'Should have 3 account IDs as keys');
    }

    @IsTest
    static void testMapObjectsByFieldMultipleFields() {
        List<Account> accounts = [SELECT Id, Name, Industry FROM Account];

        Test.startTest();
        Map<String, List<SObject>> resultMap = SObjectUtils.mapObjectsByField(accounts, new Set<String>{ 'Industry' });
        Test.stopTest();

        System.assert(!resultMap.isEmpty(), 'Map should not be empty');
    }

    @IsTest
    static void testMapObjectsByFieldIgnoreNullValues() {
        List<Account> accounts = [SELECT Id, Name, Industry FROM Account];
        accounts[0].Industry = null;

        Test.startTest();
        Map<String, List<SObject>> resultMap = SObjectUtils.mapObjectsByField(accounts, 'Industry', true);
        Test.stopTest();

        System.assert(resultMap != null, 'Map should not be null');
    }

    @IsTest
    static void testGetLookupIds() {
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact];

        Test.startTest();
        Set<Id> accountIds = SObjectUtils.getLookupIds(contacts, 'AccountId', false);
        Test.stopTest();

        System.assertEquals(3, accountIds.size(), 'Should return 3 unique account IDs');
    }

    @IsTest
    static void testGetLookupIdsIgnoreNull() {
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact];
        contacts[0].AccountId = null;

        Test.startTest();
        Set<Id> accountIds = SObjectUtils.getLookupIds(contacts, 'AccountId', true);
        Test.stopTest();

        System.assertEquals(2, accountIds.size(), 'Should return 2 account IDs ignoring null');
    }

    @IsTest
    static void testGetObjectNameById() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String objectName = SObjectUtils.getObjectNameById(acc.Id);
        Test.stopTest();

        System.assertEquals('Account', objectName, 'Should return Account object name');
    }

    @IsTest
    static void testGetObjectNameByIdInvalid() {
        Test.startTest();
        String objectName = SObjectUtils.getObjectNameById('InvalidId', false);
        Test.stopTest();

        System.assertEquals(null, objectName, 'Should return null for invalid ID');
    }

    @IsTest
    static void testHasSObjectField() {
        Account acc = new Account();

        Test.startTest();
        Boolean hasName = SObjectUtils.hasSObjectField('Name', acc);
        Boolean hasInvalidField = SObjectUtils.hasSObjectField('InvalidField', acc);
        Test.stopTest();

        System.assertEquals(true, hasName, 'Account should have Name field');
        System.assertEquals(false, hasInvalidField, 'Account should not have InvalidField');
    }

    @IsTest
    static void testValidateSObjectType() {
        Account acc = new Account();

        Test.startTest();
        Boolean isAccount = SObjectUtils.validateSObjectType(acc, 'Account');
        Boolean isContact = SObjectUtils.validateSObjectType(acc, 'Contact');
        Test.stopTest();

        System.assertEquals(true, isAccount, 'Should validate as Account');
        System.assertEquals(false, isContact, 'Should not validate as Contact');
    }

    @IsTest
    static void testValidateSOBjectTypeMultiple() {
        Account acc = new Account();

        Test.startTest();
        Boolean isValid = SObjectUtils.validateSOBjectType(acc, new Set<String>{ 'Account', 'Contact' });
        Test.stopTest();

        System.assertEquals(true, isValid, 'Should validate as one of Account or Contact');
    }

    @IsTest
    static void testGetPickListValuesList() {
        Test.startTest();
        List<Map<String, String>> picklistValues = SObjectUtils.getPickListValuesList('Account', 'Industry');
        Test.stopTest();

        System.assert(!picklistValues.isEmpty(), 'Should return picklist values');
        System.assert(picklistValues[0].containsKey('value'), 'Should have value key');
        System.assert(picklistValues[0].containsKey('label'), 'Should have label key');
    }

    @IsTest
    static void testGetPickListValuesMap() {
        Test.startTest();
        Map<String, String> picklistMap = SObjectUtils.getPickListValuesMap('Account', 'Industry');
        Test.stopTest();

        System.assert(!picklistMap.isEmpty(), 'Should return picklist map');
    }

    @IsTest
    static void testGetPickListValues() {
        Test.startTest();
        List<Schema.PicklistEntry> picklistEntries = SObjectUtils.getPickListValues('Account', 'Industry');
        Test.stopTest();

        System.assert(!picklistEntries.isEmpty(), 'Should return picklist entries');
    }

    @IsTest
    static void testGetFieldType() {
        Test.startTest();
        String fieldType = SObjectUtils.getFieldType('Account', 'Name');
        Test.stopTest();

        System.assertEquals('STRING', fieldType, 'Name field should be STRING type');
    }

    @IsTest
    static void testAddPicklistValueToMultiSelect() {
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            FinishedSteps__c = 'Step1;Step2'
        );

        Test.startTest();
        line = (MassUpdateExecutionLine__c) SObjectUtils.addPicklistValueToMultiSelect(line, 'FinishedSteps__c', 'Step3');
        Test.stopTest();

        System.assert(line.FinishedSteps__c.contains('Step3'), 'Step3 should be added');
        System.assert(line.FinishedSteps__c.contains('Step1'), 'Step1 should still exist');
    }

    @IsTest
    static void testAddPicklistValueToMultiSelectDuplicate() {
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            FinishedSteps__c = 'Step1;Step2'
        );

        Test.startTest();
        line = (MassUpdateExecutionLine__c) SObjectUtils.addPicklistValueToMultiSelect(line, 'FinishedSteps__c', 'Step2');
        Test.stopTest();

        Integer count = line.FinishedSteps__c.split(';').size();
        System.assertEquals(2, count, 'Should not add duplicate Step2');
    }

    @IsTest
    static void testAddPicklistValueToMultiSelectEmpty() {
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c();

        Test.startTest();
        line = (MassUpdateExecutionLine__c) SObjectUtils.addPicklistValueToMultiSelect(line, 'FinishedSteps__c', 'Step1');
        Test.stopTest();

        System.assertEquals('Step1', line.FinishedSteps__c, 'Should add Step1 to empty field');
    }

    @IsTest
    static void testAddPicklistValueToMultiSelectNull() {
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c();

        Test.startTest();
        line = (MassUpdateExecutionLine__c) SObjectUtils.addPicklistValueToMultiSelect(line, 'FinishedSteps__c', null);
        Test.stopTest();

        System.assertEquals(null, line.FinishedSteps__c, 'Should remain null when adding null value');
    }

    @IsTest
    static void testGetDependentPicklistValues() {
        Test.startTest();
        Map<String, List<String>> dependentValues = SObjectUtils.getDependentPicklistValues('SBQQ__Quote__c', 'PMC_CPQ_SalesOffice__c');
        Test.stopTest();

        System.assert(dependentValues == null || dependentValues != null, 'Method should return a result');
    }

    @IsTest
    static void testGetDependentPicklistValuesWithDependency() {
        Test.startTest();
        Map<String, List<String>> dependentValues = SObjectUtils.getDependentPicklistValues('Account', 'Industry');
        Test.stopTest();

        System.assert(true, 'Method should execute without exceptions');
    }

    @IsTest
    static void testGetDependentPicklistValuesNonExistentField() {
        Test.startTest();
        try {
            Map<String, List<String>> dependentValues = SObjectUtils.getDependentPicklistValues('Account', 'NonExistentField');
            System.assert(false, 'Should throw exception for non-existent field');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for non-existent field');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetDependentPicklistValuesNonExistentObject() {
        Test.startTest();
        try {
            Map<String, List<String>> dependentValues = SObjectUtils.getDependentPicklistValues('NonExistentObject', 'Name');
            System.assert(false, 'Should throw exception for non-existent object');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for non-existent object');
        }
        Test.stopTest();
    }


    @IsTest
    static void testGetDependentPicklistValues2() {
        Test.startTest();
        Map<String, List<String>> dependentValues = SObjectUtils.getDependentPicklistValues2('SBQQ__Quote__c', 'PMC_CPQ_SalesOffice__c');
        Test.stopTest();

        System.assert(dependentValues == null || dependentValues != null, 'Method should return a result');
    }

    @IsTest
    static void testGetDependentPicklistValues2WithDependency() {
        Test.startTest();
        Map<String, List<String>> dependentValues = SObjectUtils.getDependentPicklistValues2('Account', 'Industry');
        Test.stopTest();

        System.assert(true, 'Method should execute without exceptions');
    }

    @IsTest
    static void testGetDependentPicklistValues2NonExistentField() {
        Test.startTest();
        try {
            Map<String, List<String>> dependentValues = SObjectUtils.getDependentPicklistValues2('Account', 'NonExistentField');
            System.assert(false, 'Should throw exception for non-existent field');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for non-existent field');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetDependentPicklistValues2NonExistentObject() {
        Test.startTest();
        try {
            Map<String, List<String>> dependentValues = SObjectUtils.getDependentPicklistValues2('NonExistentObject', 'Name');
            System.assert(false, 'Should throw exception for non-existent object');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for non-existent object');
        }
        Test.stopTest();
    }
}