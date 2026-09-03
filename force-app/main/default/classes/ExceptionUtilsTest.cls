@IsTest
private class ExceptionUtilsTest {

    @IsTest
    static void testDebugWithGenericException() {
        CustomException ex = new CustomException('generic failure');

        Test.startTest();
        String output = ExceptionUtils.debug(ex);
        Test.stopTest();

        System.assertNotEquals(null, output, 'debug should return a string');
        System.assert(output.contains('Type:'), 'Output should include Type label');
        System.assert(output.contains('Message:'), 'Output should include Message label');
        System.assert(output.contains('generic failure'), 'Output should include the exception message');
        System.assert(output.contains('StackTrace:'), 'Output should include StackTrace');
    }

    @IsTest
    static void testDebugWithNullPointerException() {
        // Construct and throw a NullPointerException to produce stack trace/cause
        NullPointerException npe = new NullPointerException();

        Test.startTest();
        String out = ExceptionUtils.debug(npe);
        Test.stopTest();

        System.assertNotEquals(null, out, 'debug should return a string for NullPointerException');
        System.assert(out.contains('NullPointerException') || out.contains('Type:'), 'Output should mention NullPointerException or include Type');
    }

    @IsTest
    static void testDebugWithDmlExceptionContainsErrors() {
        // Create a DmlException by attempting an invalid DML (insert a read-only field)
        Account a = new Account(Name='T');
        insert a;

        // Force a DmlException by attempting to insert an Account with an invalid field via sObject.put
        Account bad = new Account();
        try {
            // Intentionally cause a DmlException: insert null required fields by using an invalid operation
            // Use Database.insert with allOrNone true and pass an sobject expected to fail
            bad.Id = null; // ensure no ID set
            // This will succeed normally since Name is not set, so we force an exception by doing update on a non-inserted record
            update bad;
            System.assert(false, 'Expected DmlException not thrown');
        } catch (DmlException de) {
            String dbg = ExceptionUtils.debug(de);
            System.assertNotEquals(null, dbg, 'debug should return string for DmlException');
            System.assert(dbg.contains('DmlException') || dbg.contains('Type:'), 'Output should indicate DmlException type');
            System.assert(dbg.contains('StackTrace:'), 'Output should include StackTrace');
        }
    }
}