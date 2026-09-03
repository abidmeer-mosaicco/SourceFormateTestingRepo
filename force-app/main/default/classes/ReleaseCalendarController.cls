/**
* @File Name : ReleaseCalendarController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 21, 2025 |   | Initial Version
**/

public without sharing class ReleaseCalendarController {

    public class EventDTO {
        @AuraEnabled public Date   startDate;
        @AuraEnabled public Date   endDate;
        @AuraEnabled public String type;
        @AuraEnabled public String environment;
        @AuraEnabled public String description;
    }

    /**
     * Returns all release events overlapping the given year.
     * If End_Date__c is blank, it’s treated as same as Start_Date__c.
     */
    @AuraEnabled(cacheable=true)
    public static List<EventDTO> getEvents(Integer year) {
        if (year == null) year = Date.today().year();
        Date yStart = Date.newInstance(year, 1, 1);
        Date yEnd   = Date.newInstance(year, 12, 31);

        List<Release__c> rows = [
            SELECT Start_Date__c, End_Date__c, Release_Type__c, Environment__c, Description__c
            FROM Release__c
            WHERE Start_Date__c <= :yEnd
              AND (End_Date__c = NULL OR End_Date__c >= :yStart)
            ORDER BY Start_Date__c ASC];

        List<EventDTO> outList = new List<EventDTO>();
        for (Release__c r : rows) {
            EventDTO dto = new EventDTO();
            dto.startDate   = r.Start_Date__c;
            dto.endDate     = (r.End_Date__c == null ? r.Start_Date__c : r.End_Date__c);
            dto.type        = r.Release_Type__c;
            dto.environment = r.Environment__c;
            dto.description = r.Description__c;
            outList.add(dto);
        }
        return outList;
    }

    /**
     * Returns min/max years present across Start/End dates.
     * Used to build the Year picker so older years like 2023 appear.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getYearBounds() {
        Map<String, Integer> result = new Map<String, Integer>{ 'minYear' => null, 'maxYear' => null };
        // If there are no records, return current year
        if ([SELECT COUNT() FROM Release__c] == 0) {
            Integer y = Date.today().year();
            result.put('minYear', y);
            result.put('maxYear', y);
            return result;
        }

        AggregateResult ar = [
            SELECT
                MIN(Start_Date__c) minS,
                MIN(End_Date__c)   minE,
                MAX(Start_Date__c) maxS,
                MAX(End_Date__c)   maxE
            FROM Release__c
        ];

        Date minStart = (Date) ar.get('minS');
        Date minEnd   = (Date) ar.get('minE');
        Date maxStart = (Date) ar.get('maxS');
        Date maxEnd   = (Date) ar.get('maxE');

        Integer minYear = null;
        if (minStart != null) minYear = minStart.year();
        if (minEnd   != null) minYear = (minYear == null ? minEnd.year() : Math.min(minYear, minEnd.year()));

        Integer maxYear = null;
        if (maxStart != null) maxYear = maxStart.year();
        if (maxEnd   != null) maxYear = (maxYear == null ? maxEnd.year() : Math.max(maxYear, maxEnd.year()));

        // Fallback to current year if still nulls
        if (minYear == null) minYear = Date.today().year();
        if (maxYear == null) maxYear = Date.today().year();

        result.put('minYear', minYear);
        result.put('maxYear', maxYear);
        return result;
    }
}