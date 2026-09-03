public class RecordValidator {
	public static Boolean isFieldChanged(SObject record, Map<Id, SObject> oldMap, String fieldName) {
		return isFieldChanged(record, oldMap, fieldName, null);
	}
	/**
	 * Checks if a field value was changed (optionally to a specific value).
	 */
	public static Boolean isFieldChanged(SObject record, Map<Id, SObject> oldMap, String fieldName, Object expectedValue) {
		if (record == null || oldMap == null || !oldMap.containsKey(record.Id))
			return false;

		Object oldValue = oldMap.get(record.Id).get(fieldName);
		Object newValue = record.get(fieldName);

		Boolean changed = (oldValue != newValue) && (oldValue == null || !oldValue.equals(newValue));
		if (!changed)
			return false;

		if (expectedValue != null) {
			return expectedValue.equals(newValue);
		}

		return true;
	}

	// /**
	//  * Checks if a field is null or (if String) blank.
	//  */
	// public static Boolean isFieldBlank(SObject record, String fieldName) {
	//     Object value = record.get(fieldName);
	//     return value == null || (value instanceof String && String.isBlank((String)value));
	// }

	// /**
	//  * Checks if a field value was changed to one of the expected values.
	//  */
	// public static Boolean hasFieldChangedToAny(
	//     SObject record,
	//     Map<Id, SObject> oldMap,
	//     String fieldName,
	//     List<Object> expectedValues
	// ) {
	//     if (record == null || oldMap == null || !oldMap.containsKey(record.Id)) return false;

	//     Object oldValue = oldMap.get(record.Id).get(fieldName);
	//     Object newValue = record.get(fieldName);

	//     Boolean changed = (oldValue != newValue) && (oldValue == null || !oldValue.equals(newValue));
	//     if (!changed) return false;

	//     return expectedValues.contains(newValue);
	// }

	// /**
	//  * Checks if a field value is one of the valid picklist values.
	//  */
	// public static Boolean isPicklistValue(SObject record, String fieldName, List<String> validValues) {
	//     Object value = record.get(fieldName);
	//     return value != null && validValues.contains(String.valueOf(value));
	// }

	// /**
	//  * Checks if a numeric (Decimal) field is greater than zero.
	//  */
	// public static Boolean isNumericFieldPositive(SObject record, String fieldName) {
	//     Object value = record.get(fieldName);
	//     return value instanceof Decimal && ((Decimal)value) > 0;
	// }

	// /**
	//  * Checks if a Date field is in the future.
	//  */
	// public static Boolean isDateFieldInFuture(SObject record, String fieldName) {
	//     Object value = record.get(fieldName);
	//     return value instanceof Date && ((Date)value) > Date.today();
	// }

	// /**
	//  * Checks if a field exists and matches the expected value.
	//  */
	// public static Boolean isFieldEqual(SObject record, String fieldName, Object expectedValue) {
	//     Object value = record.get(fieldName);
	//     return value != null && value.equals(expectedValue);
	// }
}