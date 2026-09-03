/**
* @File Name : LocationLookupController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 2, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 2, 2025 |   | Initial Version*/

public with sharing class LocationLookupController {
 @AuraEnabled(cacheable=true)
     public static List<Schema.Location> searchLocations(String searchKey) {
      if (String.isBlank(searchKey)) {
         return [SELECT Id, Name FROM Location ORDER BY CreatedDate DESC LIMIT 5];
        }
       return [SELECT Id, Name FROM Location WHERE Name LIKE :('%' + searchKey + '%') ORDER BY Name LIMIT 10];
 }
}