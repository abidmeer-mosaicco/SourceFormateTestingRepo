/**
* @File Name : ReleaseCalendarController_Test.cls
* @Description : Test class for ReleaseCalendarController
* @Author :
* @Last Modified By :
* @Last Modified On : September 9, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 9, 2025 |   | Initial Version
**/

@IsTest
private class ReleaseCalendarController_Test {

    // Utility method to create sample Release__c records
    private static void createReleaseData() {
        List<Release__c> releases = new List<Release__c>();

        // Record with start and end date
        releases.add(new Release__c(
            Start_Date__c = Date.newInstance(2024, 12, 15),
            End_Date__c = Date.newInstance(2024, 12, 20),
            Release_Type__c = 'Mosaic Regular Release',
            Environment__c = 'Production',
            Description__c = 'Year-end release'
        ));

        // Record without end date (should fallback to start date)
        releases.add(new Release__c(
            Start_Date__c = Date.newInstance(2025, 1, 10),
            Release_Type__c = 'Blackout',
            Environment__c = 'UAT',
            Description__c = 'Bug fixes'
        ));

        // Old release record for minYear calculation
        releases.add(new Release__c(
            Start_Date__c = Date.newInstance(2022, 5, 1),
            End_Date__c = Date.newInstance(2022, 5, 5),
            Release_Type__c = 'Mosaic Regular Release',
            Environment__c = 'QA',
            Description__c = 'Legacy release'
        ));

        insert releases;
    }

    /**
     * Test getEvents() when passing a specific year
     */
    @IsTest
    static void testGetEvents_WithYear() {
        createReleaseData();

        // Act
        Test.startTest();
        List<ReleaseCalendarController.EventDTO> events =
            ReleaseCalendarController.getEvents(2024);
        Test.stopTest();

        // Assert
        System.assertNotEquals(0, events.size(), 'Events should be returned');
        System.assertEquals('Mosaic Regular Release', events[0].type);
        System.assertEquals('Production', events[0].environment);
    }

    /**
     * Test getEvents() when year is NULL
     */
    @IsTest
    static void testGetEvents_DefaultYear() {
        createReleaseData();

        Test.startTest();
        List<ReleaseCalendarController.EventDTO> events =
            ReleaseCalendarController.getEvents(null);
        Test.stopTest();

        System.assert(events.size() > 0, 'Should return events even if year is null');
    }

    /**
     * Test getEvents() when there are NO release records
     */
    @IsTest
    static void testGetEvents_NoRecords() {
        Test.startTest();
        List<ReleaseCalendarController.EventDTO> events =
            ReleaseCalendarController.getEvents(2025);
        Test.stopTest();

        System.assertEquals(0, events.size(), 'Should return empty list when no data');
    }

    /**
     * Test getYearBounds() when records exist
     */
    @IsTest
    static void testGetYearBounds_WithRecords() {
        createReleaseData();

        Test.startTest();
        Map<String, Integer> bounds = ReleaseCalendarController.getYearBounds();
        Test.stopTest();

        System.assert(bounds.containsKey('minYear'), 'minYear key should exist');
        System.assert(bounds.containsKey('maxYear'), 'maxYear key should exist');
        System.assertEquals(2022, bounds.get('minYear'), 'Min year should match oldest release');
        System.assert(bounds.get('maxYear') >= 2025, 'Max year should be the latest');
    }

    /**
     * Test getYearBounds() when NO records exist
     */
    @IsTest
    static void testGetYearBounds_NoRecords() {
        Test.startTest();
        Map<String, Integer> bounds = ReleaseCalendarController.getYearBounds();
        Test.stopTest();

        Integer currentYear = Date.today().year();
        System.assertEquals(currentYear, bounds.get('minYear'));
        System.assertEquals(currentYear, bounds.get('maxYear'));
    }
}