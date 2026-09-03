/**
* @File Name : LocationLookupControllerTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 3, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 3, 2025 |   | Initial Version
**/
@isTest
public class LocationLookupControllerTest {
   @isTest
   static void testSearchWithBlankKey() {
       // Insert sample Location records
       List<Schema.Location> testLocations = new List<Schema.Location>();
       for (Integer i = 0; i < 6; i++) {
           testLocations.add(new Schema.Location(Name = 'Test Location ' + i));
       }
       insert testLocations;
       Test.startTest();
       List<Schema.Location> results = LocationLookupController.searchLocations('');
       Test.stopTest();
       System.assertNotEquals(0, results.size(), 'Should return records when searchKey is blank');
       System.assertEquals(5, results.size(), 'Should return latest 5 records');
   }
   @isTest
   static void testSearchWithKey() {
       insert new Schema.Location(Name = 'Unique Test Location');
       Test.startTest();
       List<Schema.Location> results = LocationLookupController.searchLocations('Unique Test');
       Test.stopTest();
       System.assertNotEquals(0, results.size(), 'Should return records when matching searchKey exists');
       System.assert(results[0].Name.contains('Unique Test Location'));
   }
   @isTest
   static void testSearchWithNoMatch() {
       Test.startTest();
       List<Schema.Location> results = LocationLookupController.searchLocations('DoesNotExist123');
       Test.stopTest();
       System.assertEquals(0, results.size(), 'Should return no records when searchKey does not match');
   }
}