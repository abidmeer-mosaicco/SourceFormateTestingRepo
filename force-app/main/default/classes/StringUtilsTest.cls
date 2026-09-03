@IsTest
private class StringUtilsTest {
    @IsTest
    static void testDateToString() {
        Date testDate = Date.newInstance(2025, 11, 23);
        String expected = '2025-11-23';
        Test.startTest();
        String actual = StringUtils.dateToString(testDate);
        Test.stopTest();
        System.assertEquals(expected, actual, 'Result should be 2025-11-23.');
    }

    @IsTest
    static void testToDate() {
        String testDate = '2025-11-23';
        Date expected = Date.newInstance(2025, 11, 23);
        Test.startTest();
        Date actual = StringUtils.toDate(testDate);
        Test.stopTest();
        System.assertEquals(expected, actual, 'Result should be a Date instance of 2025-11-23.');
    }

    @IsTest
    static void testConvertListToSet() {
        List<String> testList = new List<String>{'a', 'b', 'c'};
        Set<String> expected = new Set<String>{'a', 'b', 'c'};
        Test.startTest();
        Set<String> actual = StringUtils.convertListToSet(testList);
        Test.stopTest();
        System.assertEquals(expected, actual, 'Result should be a Set instance of {a, b, c}.');
    }

    @IsTest
    static void testAddPicklistValueToMultiSelect() {
        String testMultiSelect = 'a;b;c';
        String testPicklistValue = 'd';
        String expected = 'a;b;c;d';
        Test.startTest();
        String actual = StringUtils.addPicklistValueToMultiSelect(testMultiSelect, testPicklistValue);
        Test.stopTest();
        System.assertEquals(expected, actual, 'Result should be a String instance of a;b;c;d.');
    }

    @IsTest
    static void testPadLeftZeros() {
        Test.startTest();
        String result1 = StringUtils.padLeftZeros('123', 10);
        String result2 = StringUtils.padLeftZeros('1234567890', 10);
        String result3 = StringUtils.padLeftZeros('12345', 10);
        String result4 = StringUtils.padLeftZeros('', 10);
        String result5 = StringUtils.padLeftZeros(null, 10);
        String result6 = StringUtils.padLeftZeros('  456  ', 10);
        Test.stopTest();
        System.assertEquals('0000000123', result1, 'Should pad 123 to 10 digits');
        System.assertEquals('1234567890', result2, 'Should not pad when already 10 digits');
        System.assertEquals('0000012345', result3, 'Should pad 12345 to 10 digits');
        System.assertEquals('', result4, 'Should return empty string for empty input');
        System.assertEquals(null, result5, 'Should return null for null input');
        System.assertEquals('0000000456', result6, 'Should trim spaces and pad to 10 digits');
    }
}