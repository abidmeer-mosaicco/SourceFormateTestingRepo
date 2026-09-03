/* Test class for PMC_SS_TriggerRecursionGuard Class - Prashanth Kamma - 08/05/2025.*/

@isTest
private class PMC_SS_TriggerRecursionGuardTest {

    @isTest
    static void testRecursionGuardMethods() {
        // Initially nothing should be marked
        System.assertEquals(false, PMC_SS_TriggerRecursionGuard.isAlreadyProcessed('TestKey1'), 'Should not be marked yet');

        // Mark a key and verify
        PMC_SS_TriggerRecursionGuard.markProcessed('TestKey1');
        System.assertEquals(true, PMC_SS_TriggerRecursionGuard.isAlreadyProcessed('TestKey1'), 'Should now be marked');

        // Mark another and verify
        PMC_SS_TriggerRecursionGuard.markProcessed('TestKey2');
        System.assertEquals(true, PMC_SS_TriggerRecursionGuard.isAlreadyProcessed('TestKey2'), 'Second key should be marked');

        // Reset all and verify none are marked
       PMC_SS_TriggerRecursionGuard.reset();
        System.assertEquals(false, PMC_SS_TriggerRecursionGuard.isAlreadyProcessed('TestKey1'), 'Should be cleared after reset');
        System.assertEquals(false, PMC_SS_TriggerRecursionGuard.isAlreadyProcessed('TestKey2'), 'Should be cleared after reset');
    }
}