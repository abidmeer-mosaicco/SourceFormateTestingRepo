/**
 * @description       : Utility class for String manipulations
 * @author            : Raphael Soares
 * @last modified on  : 21-09-2025
 * @last modified by  : raphael.soares@mosaicco.com
 * Modifications Log
 * Ver   Date         Author                      Modification
 * 1.0   21-09-2025   raphael.soares@mosaicco.com   Initial Version
 **/
global class StringUtils {
	global static String dateToString(Date value) {
		String sMonth = String.valueOf(value.month());
		String sDay = String.valueOf(value.day());
		if (sMonth.length() == 1) {
			sMonth = '0' + sMonth;
		}
		if (sDay.length() == 1) {
			sDay = '0' + sDay;
		}
		return String.valueof(value.year()) + '-' + sMonth + '-' + sDay;
	}

	global static Date toDate(String dateString) {
		if (String.isBlank(dateString)) {
			return null;
		}
		List<String> dateParts = dateString.split('-');

		if (dateParts.size() != 3) {
			throw new IllegalArgumentException('Invalid date format');
		}

		return Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
	}

	global static Set<String> convertListToSet(List<String> lstStr){
	    Set<String> result = new Set<String>();
	    result.addAll(lstStr);
	    return result;
	}

	global static String addPicklistValueToMultiSelect(String value, String valueToAdd) {
		if (String.isBlank(valueToAdd)) {
			return value;
		}
		if(String.isBlank(value)){
			return valueToAdd;
		}
		Set<String> values = convertListToSet(value.split(';'));
		if (!values.contains(valueToAdd)) {
			values.add(valueToAdd);
		}
		return String.join(values, ';');
	}

	global static String padLeftZeros(String value, Integer minLength) {
		if (String.isBlank(value)) {
			return value;
		}
		String trimmedValue = value.trim();
		if (trimmedValue.length() >= minLength) {
			return trimmedValue;
		}
		Integer zerosToAdd = minLength - trimmedValue.length();
		return '0'.repeat(zerosToAdd) + trimmedValue;
	}

	// global static String cutByFieldLength(Schema.SObjectField theField, String value) {
	//     return cutByFieldLength(theField.getDescribe(), value);
	// }

	// global static String cutByFieldLength(Schema.DescribeFieldResult dfr, String value) {
	//     // Schema.DescribeFieldResult dfr = Account.Description.getDescribe();
	//     if(String.isEmpty(value) || value.length() <= dfr.getLength()){
	//         return value;
	//     } else {
	//         return value.left(dfr.getLength());
	//     }
	// }

	// global static String removeNonNumericCharacters(String value){
	//     return removeCharacters(value, '[^0-9]');
	// }

	// global static String removeCharacters(String value, String filter){
	//     return replaceCharacters(value, filter, '');
	// }

	// global static String replaceCharacters(String value, String filter, String newValue){
	//     // filter example '[^a-zA-Z0-9]'
	//     if(String.isEmpty(value)){
	//         return value;
	//     } else {
	//         return Pattern.compile(filter).matcher(value).replaceAll(newValue);
	//     }
	// }

	// global static String replaceSpecialCharacters(String value, Map<String,String> mapNewValues){
	//     return replaceSpecialCharacters(new List<String>{value}, mapNewValues)[0];
	// }

	// global static List<String> replaceSpecialCharacters(List<String> values, Map<String,String> mapNewValues){
	//     List<String> response = new List<String>();
	//     if(values != null && mapNewValues != null && !values.isEmpty() && !mapNewValues.isEmpty()){
	//         for(String value: values){
	//             if(!String.isEmpty(value)){
	//                 for(String filter: mapNewValues.keySet()){
	//                     value = replaceCharacters(value, filter, mapNewValues.get(filter));
	//                 }
	//             }
	//             response.add(value);
	//         }
	//     } else {
	//         response = values;
	//     }
	//     return response;
	// }
}