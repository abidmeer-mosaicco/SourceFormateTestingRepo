/**
 * @description       : Utility class for SObject manipulations
 * @author            : Raphael Soares
 * @last modified on  : 21-09-2025
 * @last modified by  : raphael.soares@mosaicco.com
 * Modifications Log
 * Ver   Date         Author                      Modification
 * 1.0   21-09-2025   raphael.soares@mosaicco.com   Initial Version
 **/
global class SObjectUtils {
	global static Boolean hasChangedFields(SObject obj, Map<Id, SObject> mapOld, String fieldName) {
		return hasChangedFields(obj, mapOld, new Set<String>{ fieldName });
	}

	//THIS METHOD WILL RETURN FALSE IF IT'S USED IN A BEFORE INSERT OPERATION.
	global static Boolean hasChangedFields(SObject obj, Map<Id, SObject> mapOld, Set<String> fieldsToCheck) {
		if (mapOld == null || fieldsToCheck == null || mapOld.isEmpty() || obj == null || obj.Id == null || fieldsToCheck.isEmpty()) {
			return false;
		}

		for (String field : fieldsToCheck) {
			if (obj.get(field) != mapOld.get(obj.Id).get(field)) {
				return true;
			}
		}

		return false;
	}

	global static SObject copyFieldValues(SObject destination, SObject source, String fieldName) {
		return copyFieldValues(destination, source, new Set<String>{ fieldName }, true);
	}

	global static SObject copyFieldValues(SObject destination, SObject source, String fieldName, Boolean canInsertNullValues) {
		return copyFieldValues(destination, source, new Set<String>{ fieldName }, canInsertNullValues);
	}

	global static SObject copyFieldValues(SObject destination, SObject source, Set<String> fieldNames) {
		return copyFieldValues(destination, source, fieldNames, true);
	}

	global static SObject copyFieldValues(SObject destination, SObject source, Set<String> fieldNames, Boolean canInsertNullValues) {
		return copyFieldValues(destination, source, fieldNames, canInsertNullValues, true);
	}

	global static SObject copyFieldValues(
		SObject destination,
		SObject source,
		Set<String> fieldNames,
		Boolean canInsertNullValues,
		Boolean canOverride
	) {
		// try{
		for (String fieldName : fieldNames) {
			if (
				destination.get(fieldName) == null ||
				canInsertNullValues ||
				(canOverride && (canInsertNullValues || source.get(fieldName) != null))
			) {
				destination.put(fieldName, source.get(fieldName));
			}
		}
		// }catch(Exception ex){}
		return destination;
	}

	global static SObject copyFieldValues(
		SObject destination,
		SObject source,
		Map<String, String> mapFields,
		Boolean canInsertNullValues,
		Boolean canOverride
	) {
		// try{
		for (String destinationField : mapFields.keySet()) {
			String sourceField = mapFields.get(destinationField);
			if ((destination.get(destinationField) == null || canOverride) && (source.get(sourceField) != null || canInsertNullValues)) {
				destination.put(destinationField, source.get(sourceField));
			}
		}
		// }catch(Exception ex){}
		return destination;
	}

	// global static Map<Id, List<SObject>> mapObjectsByField(List<SObject> lstRecords, String fieldName){
	//     return mapObjectsByField(lstRecords, fieldName, false);
	// }

	global static Map<String, List<SObject>> mapObjectsByField(List<SObject> lstRecords, String fieldName) {
		return mapObjectsByField(lstRecords, new Set<String>{ fieldName }, false);
	}

	global static Map<String, List<SObject>> mapObjectsByField(List<SObject> lstRecords, String fieldName, Boolean ignoreNullValues) {
		return mapObjectsByField(lstRecords, new Set<String>{ fieldName }, ignoreNullValues);
	}

	global static Map<String, List<SObject>> mapObjectsByField(List<SObject> lstRecords, Set<String> fieldNames) {
		return mapObjectsByField(lstRecords, fieldNames, false);
	}

	global static Map<String, List<SObject>> mapObjectsByField(List<SObject> lstRecords, Set<String> fieldNames, Boolean ignoreNullValues) {
		if (lstRecords == null || fieldNames == null || fieldNames.isEmpty()) {
			throw new CustomException('Não foram passados todos os parâmetros necessários para a execução do método SObjectUtils.mapObjectsByField!');
		}

		Map<String, List<SObject>> response = new Map<String, List<SObject>>();

		for (SObject item : lstRecords) {
			Boolean hasKeyField = false;
			for (String fieldName : fieldNames) {
				if (item.get(fieldName) != null) {
					String key = (String) item.get(fieldName);
					List<SObject> currentList = response.get(key);
					if (currentList == null) {
						currentList = new List<SObject>();
					}

					currentList.add(item);

					response.put(key, currentList);
					hasKeyField = true;
				}
			}
			if (!ignoreNullValues && !hasKeyField) {
				throw new CustomException('O objeto (' + item.Id + ') não possui os campos ' + JSON.serialize(fieldNames) + '!');
			}
		}
		return response;
	}

	global static Set<Id> getLookupIds(List<SObject> lstRecords, String fieldName, Boolean ignoreNullValues) {
		if (lstRecords == null || String.isEmpty(fieldName)) {
			throw new CustomException('Não foram passados todos os parâmetros necessários para a execução do método SObjectUtils.getLookupIds!');
		}

		Set<Id> response = new Set<Id>();
		for (SObject obj : lstRecords) {
			if (!ignoreNullValues && (!hasSObjectField(fieldName, obj) || obj.get(fieldName) == null)) {
				throw new CustomException('O objeto (' + obj.Id + ') não possui o campo ' + fieldName + '!');
			} else if (obj.get(fieldName) != null) {
				Id lookupId = (ID) obj.get(fieldName); //Object
				if (!response.contains(lookupId)) {
					response.add(lookupId);
				}
			}
		}
		return response;
	}

	global static String getObjectNameById(Id objectId) {
		return getObjectNameById(objectId, true);
	}

	global static String getObjectNameById(String objectId, Boolean throwErrorIfNotSFId) {
		String sobjectName;
		try {
			sobjectName = ((Id) objectId).getSObjectType().getDescribe().getName();
		} catch (Exception ex) {
			if (throwErrorIfNotSFId) {
				throw ex;
			}
		}
		return sobjectName;
	}

	global static boolean hasSObjectField(String fieldName, SObject so) {
		return so.getSobjectType().getDescribe().fields.getMap().containsKey(fieldName.toLowerCase());
	}

	global static boolean validateSObjectType(SObject obj, String type) {
		return validateSOBjectType(obj, new Set<String>{ type });
	}

	global static boolean validateSOBjectType(SObject obj, Set<String> types) {
		if (types == null) {
			throw new CustomException('This method needs a Set<String> of possible SObject Types.');
		}
		return types.contains(obj.getSObjectType().getDescribe().getName());
	}

	global static List<Map<String, String>> getPickListValuesList(String sobjectName, String fieldName) {
		List<Map<String, String>> response = new List<Map<String, String>>();
		List<Schema.PicklistEntry> ple = getPickListValues(sobjectName, fieldName);
		for (Schema.PicklistEntry pickListVal : ple) {
			if (pickListVal.isActive()) {
				response.add(
					new Map<String, String>{
						'value' => pickListVal.getValue(),
						'label' => pickListVal.getLabel(),
						'default' => String.valueOf(pickListVal.isDefaultValue())
					}
				);
			}
		}
		return response;
	}

	global static Map<String, String> getPickListValuesMap(String sobjectName, String fieldName) {
		Map<String, String> response = new Map<String, String>();
		List<Schema.PicklistEntry> ple = getPickListValues(sobjectName, fieldName);
		for (Schema.PicklistEntry pickListVal : ple) {
			if (pickListVal.isActive()) {
				response.put(pickListVal.getValue(), pickListVal.getLabel());
			}
		}
		return response;
	}

	global static List<Schema.PicklistEntry> getPickListValues(String sobjectName, String fieldName) {
		Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap();
		if (fieldMap.containsKey(fieldName.toLowerCase())) {
			// List<PicklistEntry> response = new List<PicklistEntry>();
			Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName.toLowerCase()).getDescribe();
			if (fieldResult.getType() == Schema.DisplayType.Picklist) {
				// List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
				// for( Schema.PicklistEntry pickListVal : ple){
				//     if(pickListVal.isActive()){
				//         response.add(pickListVal);
				//     }
				// }
				return fieldResult.getPicklistValues();
			} else {
				throw new CustomException('O campo "' + fieldName + '" não é do tipo Picklist.');
			}
		} else {
			throw new CustomException('O objeto "' + sobjectName + '" não possui o campo "' + fieldName + '".');
		}
	}

	global static String getFieldType(String objectName, String fieldName) {
		try {
			return String.valueOf(
					((SObject) (Type.forName('Schema.' + objectName).newInstance()))
						.getSObjectType()
						.getDescribe()
						.fields.getMap()
						.get(fieldName)
						.getDescribe()
						.getType()
				)
				.toUpperCase();
		} catch (Exception ex) {
			System.debug('\n\n objectName:::' + objectName + '\nFieldName:::' + fieldName + ExceptionUtils.debug(ex));
			throw new CustomException('Não foi possível encontrar o objeto e/ou campo.');
		}
	}

	global static Map<String, List<String>> getDependentPicklistValues(String sObjectName, String fieldName) {
		Map<String, List<String>> dependentPicklistValues = new Map<String, List<String>>();
		
		//Get dependent field result
		Schema.DescribeFieldResult dependentFieldResult = Schema.getGlobalDescribe()
			.get(sObjectName)
			.getDescribe()
			.fields.getMap()
			.get(fieldName)
			.getDescribe();
		
		//Get dependent field controlling field
		Schema.sObjectField controllerField = dependentFieldResult.getController();
		
		//Check controlling field is not null
		if (controllerField == null) {
			return null;
		}
		
		//Get controlling field result
		Schema.DescribeFieldResult controllerFieldResult = controllerField.getDescribe();
		
		//Get controlling field picklist values if controlling field is not a checkbox
		List<Schema.PicklistEntry> controllerValues = (controllerFieldResult.getType() == Schema.DisplayType.Boolean
			? null
			: controllerFieldResult.getPicklistValues());

		//It is used to decode the characters of the validFor fields.
		String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

		for (Schema.PicklistEntry entry : dependentFieldResult.getPicklistValues()) {
			if (entry.isActive()) {
				//The PicklistEntry is serialized and deserialized using the Apex JSON class and it will check to have a 'validFor' field
				List<String> base64chars = String.valueOf(((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor'))
					.split('');
				for (Integer i = 0; i < controllerValues.size(); i++) {
					Object controllerValue = (controllerValues == null
						? (Object) (i == 1)
						: (Object) (controllerValues[i].isActive() ? controllerValues[i].getLabel() : null));
					Integer bitIndex = i / 6;
					Integer bitShift = 5 - Math.mod(i, 6);
					if (controllerValue == null || (base64chars.size() - 1) < bitIndex || (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0) {
						continue;
					}
					if (!dependentPicklistValues.containsKey(controllerValue.toString())) {
						dependentPicklistValues.put(controllerValue.toString(), new List<String>());
					}
					dependentPicklistValues.get(controllerValue.toString()).add(entry.getLabel());
				}
			}
		}
		return dependentPicklistValues;
	}

	/**
	 * This method is used to get the picklist values of a dependent picklist field and group them by their controlling field values. 
	 * It returns a map where the keys are the controlling field values and the values are lists of dependent picklist values that 
	 * are valid for each controlling field value.
	 * Similar to getDependentPicklistValues but uses the 'value' of the controlling field picklist entries instead of the 'label', 
	 * which can be useful in scenarios where the controlling field values are not unique by label or when the API value is needed 
	 * for processing.	
	 * @param sObjectName The API name of the SObject that contains the dependent picklist field.
	 * @param fieldName The API name of the dependent picklist field.
	 * @return A map where the keys are the controlling field values and the values are lists of dependent picklist values that are 
	 * valid for each controlling field value.
	 * @author Sergio Umlauf
	 */
	global static Map<String, List<String>> getDependentPicklistValues2(String sObjectName, String fieldName) {
		Map<String, List<String>> dependentPicklistValues = new Map<String, List<String>>();
		
		//Get dependent field result
		Schema.DescribeFieldResult dependentFieldResult = Schema.getGlobalDescribe()
			.get(sObjectName)
			.getDescribe()
			.fields.getMap()
			.get(fieldName)
			.getDescribe();
		
		//Get dependent field controlling field
		Schema.sObjectField controllerField = dependentFieldResult.getController();

		//Check controlling field is not null
		if (controllerField == null) {
			return null;
		}
		
		//Get controlling field result
		Schema.DescribeFieldResult controllerFieldResult = controllerField.getDescribe();
		
		//Get controlling field picklist values if controlling field is not a checkbox
		List<Schema.PicklistEntry> controllerValues = (controllerFieldResult.getType() == Schema.DisplayType.Boolean
			? null
			: controllerFieldResult.getPicklistValues());

		//It is used to decode the characters of the validFor fields.
		String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

		for (Schema.PicklistEntry entry : dependentFieldResult.getPicklistValues()) {
			if (entry.isActive()) {
				//The PicklistEntry is serialized and deserialized using the Apex JSON class and it will check to have a 'validFor' field
				List<String> base64chars = String.valueOf(((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor'))
					.split('');
				for (Integer i = 0; i < controllerValues.size(); i++) {
					Object controllerValue = (controllerValues == null
						? (Object) (i == 1)
						: (Object) (controllerValues[i].isActive() ? controllerValues[i].getLabel() : null));
					Integer bitIndex = i / 6;
					Integer bitShift = 5 - Math.mod(i, 6);
					if (controllerValue == null || (base64chars.size() - 1) < bitIndex || (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0) {
						continue;
					}
					if (!dependentPicklistValues.containsKey(controllerValue.toString())) {
						dependentPicklistValues.put(controllerValue.toString(), new List<String>());
						dependentPicklistValues.get(controllerValue.toString()).add(entry.getValue());
					} else {
						List<String> existingValues = dependentPicklistValues.get(controllerValue.toString());
						if (!existingValues.contains(entry.getValue())) {
							existingValues.add(entry.getValue());
						}
					}
				}
			}
		}
		return dependentPicklistValues;
	}

	/**
	 * Adds a value to a semicolon-separated multi-select picklist field on an SObject if not already present.
	 * @param record The SObject record to update
	 * @param fieldName The picklist field name (String)
	 * @param valueToAdd The value to add (String)
	 * @return The updated SObject record
	 */
	global static SObject addPicklistValueToMultiSelect(SObject record, String fieldName, String valueToAdd) {
		if (record == null || String.isBlank(fieldName) || String.isBlank(valueToAdd)) {
			return record;
		}
		String current = (String)record.get(fieldName);
		List<String> values = String.isNotBlank(current) ? current.split(';') : new List<String>();
		Boolean found = false;
		String valueToAddTrimmed = valueToAdd.trim().toLowerCase();
		for (String v : values) {
			if (v != null && v.trim().toLowerCase() == valueToAddTrimmed) {
				found = true;
				break;
			}
		}
		if (!found) {
			values.add(valueToAdd.trim());
		}
		record.put(fieldName, String.join(values, ';'));
		return record;
	}
}