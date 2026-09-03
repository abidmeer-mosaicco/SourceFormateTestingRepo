@isTest
private class RecordValidatorTest {
	@isTest
	static void testIsFieldChanged() {
		Account oldAcc = new Account(Id = '001000000000001AAA', Name = 'Old Name');
		Account newAcc = new Account(Id = '001000000000001AAA', Name = 'New Name');

		Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldAcc.Id => oldAcc };

		System.assert(RecordValidator.isFieldChanged(newAcc, oldMap, 'Name'));
		System.assert(RecordValidator.isFieldChanged(newAcc, oldMap, 'Name', 'New Name'));
		System.assert(!RecordValidator.isFieldChanged(newAcc, oldMap, 'Name', 'Wrong Value'));
	}

	// @isTest static void testIsFieldBlank() {
	//     Account acc = new Account(Name = '');
	//     System.assert(RecordValidator.isFieldBlank(acc, 'Name'));

	//     acc.Name = 'Not Blank';
	//     System.assert(!RecordValidator.isFieldBlank(acc, 'Name'));

	//     acc.put('Custom__c', null);
	//     System.assert(RecordValidator.isFieldBlank(acc, 'Custom__c'));
	// }

	// @isTest static void testHasFieldChangedToAny() {
	//     Account oldAcc = new Account(Type = 'Prospect');
	//     Account newAcc = new Account(Id = '001000000000002AAA', Type = 'Customer');

	//     Map<Id, SObject> oldMap = new Map<Id, SObject>{ oldAcc.Id => oldAcc };
	//     List<Object> expected = new List<Object>{ 'Customer', 'Partner' };

	//     System.assert(RecordValidator.hasFieldChangedToAny(newAcc, oldMap, 'Type', expected));
	//     System.assert(!RecordValidator.hasFieldChangedToAny(newAcc, oldMap, 'Type', new List<Object>{ 'Other' }));
	// }

	// @isTest static void testIsPicklistValue() {
	//     Account acc = new Account(Type = 'Customer');
	//     System.assert(RecordValidator.isPicklistValue(acc, 'Type', new List<String>{ 'Customer', 'Partner' }));
	//     System.assert(!RecordValidator.isPicklistValue(acc, 'Type', new List<String>{ 'Prospect' }));
	// }

	// @isTest static void testIsNumericFieldPositive() {
	//     Opportunity opp = new Opportunity(Amount = 100);
	//     System.assert(RecordValidator.isNumericFieldPositive(opp, 'Amount'));

	//     opp.Amount = 0;
	//     System.assert(!RecordValidator.isNumericFieldPositive(opp, 'Amount'));
	// }

	// @isTest static void testIsDateFieldInFuture() {
	//     Opportunity opp = new Opportunity(CloseDate = Date.today().addDays(5));
	//     System.assert(RecordValidator.isDateFieldInFuture(opp, 'CloseDate'));

	//     opp.CloseDate = Date.today().addDays(-1);
	//     System.assert(!RecordValidator.isDateFieldInFuture(opp, 'CloseDate'));
	// }

	// @isTest static void testIsFieldEqual() {
	//     Account acc = new Account(Industry = 'Technology');
	//     System.assert(RecordValidator.isFieldEqual(acc, 'Industry', 'Technology'));
	//     System.assert(!RecordValidator.isFieldEqual(acc, 'Industry', 'Finance'));
	// }
}