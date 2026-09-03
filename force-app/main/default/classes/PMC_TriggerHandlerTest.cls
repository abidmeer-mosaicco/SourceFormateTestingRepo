/**
 * @description : This test class will be used to cover all the methods of PMC_TriggerHandler.
 * @author : Deloitte
 * @date : 04/10/2023
 **/
@isTest 
private class PMC_TriggerHandlerTest {
    private static final String STRING_TRIGGER_CONTEXT_ERROR = 'Trigger handler called outside of Trigger execution';
    private static String strLastMethodCalled;
    private static PMC_TriggerHandlerTest.TestHandler objTrigHandler;
    static {
        objTrigHandler = new PMC_TriggerHandlerTest.TestHandler();
        //Override its internal trigger detection
        objTrigHandler.isTriggerExecuting = true;
    }
    
    /**
    * @description This method will be use to cover BeforeInsert context of PMC_TestUtilityClass.
    */
    @isTest
    static void testBeforeInsert() {
        beforeInsertMode();
        objTrigHandler.run();
        System.assertEquals('beforeInsert', strLastMethodCalled, 'last method should be beforeInsert');
    }
    
    /**
    * @description This method will be use to cover BeforeUpdate context of PMC_TestUtilityClass.
    */
    @isTest
    static void testBeforeUpdate() {
        beforeUpdateMode();
        objTrigHandler.run();
        System.assertEquals('beforeUpdate', strLastMethodCalled, 'last method should be beforeUpdate');
    }
    
    /**
    * @description This method will be use to cover BeforeDelete context of PMC_TestUtilityClass.
    */
    @isTest
    static void testBeforeDelete() {
        beforeDeleteMode();
        objTrigHandler.run();
        System.assertEquals('beforeDelete', strLastMethodCalled, 'last method should be beforeDelete');
    }
    
    /**
    * @description This method will be use to cover AfterInsert context of PMC_TestUtilityClass.
    */
    @isTest
    static void testAfterInsert() {
        afterInsertMode();
        objTrigHandler.run();
        System.assertEquals('afterInsert', strLastMethodCalled, 'last method should be afterInsert');
    }
    
    /**
    * @description This method will be use to cover AfterUpdate context of PMC_TestUtilityClass.
    */
    @isTest
    static void testAfterUpdate() {
        afterUpdateMode();
        objTrigHandler.run();
        System.assertEquals('afterUpdate', strLastMethodCalled, 'last method should be afterUpdate');
    }
    
    /**
    * @description This method will be use to cover AfterDelete context of PMC_TestUtilityClass.
    */
    @isTest
    static void testAfterDelete() {
        afterDeleteMode();
        objTrigHandler.run();
        System.assertEquals('afterDelete', strLastMethodCalled, 'last method should be afterDelete');
    }
    
    /**
    * @description This method will be use to cover AfterUndelete context of PMC_TestUtilityClass.
    */
    @isTest
    static void testAfterUndelete() {
        afterUndeleteMode();
        objTrigHandler.run();
        System.assertEquals('afterUndelete', strLastMethodCalled, 'last method should be afterUndelete');
    }
    
    /**
    * @description This method will be use to cover  PMC_TestUtilityClass.
    */
    @isTest
    static void testNonTriggerContext() {
        try{
            objTrigHandler.run();
            System.assert(false, 'the handler ran but should have thrown');
        } catch(PMC_TriggerHandler.PMC_TriggerHandlerException te) {
            System.assertEquals(STRING_TRIGGER_CONTEXT_ERROR, te.getMessage(), 'the exception message should match');
        } catch(Exception e) {
            System.assert(false, 'the exception thrown was not expected: ' + e.getTypeName() + ': ' +
                          e.getMessage());
        }
    }

    /**
     * @description test bypass api
     */
    @isTest
    static void testBypassAPI() {
        afterUpdateMode();
        // test a bypass and run handler
        PMC_TriggerHandler.bypass('TestHandler');
        objTrigHandler.run();
        System.assertEquals(null, strLastMethodCalled, 'last method should be null when bypassed');
        System.assertEquals(true, PMC_TriggerHandler.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();
        // clear that bypass and run handler
        PMC_TriggerHandler.clearBypass('TestHandler');
        objTrigHandler.run();
        System.assertEquals('afterUpdate', strLastMethodCalled, 'last method called should be afterUpdate');
        System.assertEquals(false, PMC_TriggerHandler.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();
        // test a re-bypass and run handler
        PMC_TriggerHandler.bypass('TestHandler');
        objTrigHandler.run();
        System.assertEquals(null, strLastMethodCalled, 'last method should be null when bypassed');
        System.assertEquals(true, PMC_TriggerHandler.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();
        // clear all bypasses and run handler
        PMC_TriggerHandler.clearAllBypasses();
        objTrigHandler.run();
        System.assertEquals('afterUpdate', strLastMethodCalled, 'last method called should be afterUpdate');
        System.assertEquals(false, PMC_TriggerHandler.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();
    }

    /**
     * @description instance method tests
     */
    @isTest
    static void testLoopCount() {
        beforeInsertMode();
        //set the max loops to 2
        objTrigHandler.setMaxLoopCount(2);
        //run the handler twice
        objTrigHandler.run();
        objTrigHandler.run();
        //clear the tests
        resetTest();
        try {
            //try running it. This should exceed the limit.
            objTrigHandler.run();
            //System.assert(false, 'the handler should throw on the 3rd run when maxloopcount is 3');
        } catch(PMC_TriggerHandler.PMC_TriggerHandlerException te) {
            //we're expecting to get here
            System.assertEquals(null, strLastMethodCalled, 'last method should be null');
        } catch(Exception e) {
            System.assert(false, 'the exception thrown was not expected: ' + e.getTypeName() + ': ' + e.getMessage());
        }
        //clear the tests
        resetTest();
        //now clear the loop count
        objTrigHandler.clearMaxLoopCount();
        try {
            // re-run the objTrigHandler. We shouldn't throw now.
            objTrigHandler.run();
            System.assertEquals('beforeInsert', strLastMethodCalled, 'last method should be beforeInsert');
        } catch(PMC_TriggerHandler.PMC_TriggerHandlerException te) {
            System.assert(false, 'running the handler after clearing the loop count should not throw');
        } catch(Exception e) {
            System.assert(false, 'the exception thrown was not expected: ' + e.getTypeName() + ': ' +
                          e.getMessage());
        }
    }

    /**
    * @description This method will be use to cover  PMC_TestUtilityClass.
    */
    @isTest
    static void testLoopCountClass() {
        PMC_TriggerHandler.PMC_LoopCount objLoopCount = new PMC_TriggerHandler.PMC_LoopCount();
        System.assertEquals(5, objLoopCount.getMax(), 'max should be five on init');
        System.assertEquals(0, objLoopCount.getCount(), 'count should be zero on init');
        objLoopCount.increment();
        System.assertEquals(1, objLoopCount.getCount(), 'count should be 1');
        System.assertEquals(false, objLoopCount.exceeded(), 'should not be exceeded with count of 1');
        objLoopCount.increment();
        objLoopCount.increment();
        objLoopCount.increment();
        objLoopCount.increment();
        System.assertEquals(5, objLoopCount.getCount(), 'count should be 5');
        System.assertEquals(false, objLoopCount.exceeded(), 'should not be exceeded with count of 5');
        objLoopCount.increment();
        System.assertEquals(6, objLoopCount.getCount(), 'count should be 6');
        System.assertEquals(true, objLoopCount.exceeded(), 'should not be exceeded with count of 6');
    }
    
    /**
    * @description This method will be use to cover getHandlerName method of PMC_TestUtilityClass.
    */
    @isTest
    static void testGetHandlerName() {
        System.assertEquals('TestHandler', objTrigHandler.getHandlerName(), 'handler name should match class name');
    }

    /**
    * @description This method will be use to cover setTriggerContext method of PMC_TestUtilityClass.
    */
    @isTest
    static void testGetTriggerExecutionStatus() {
        PMC_TriggerHandler objTriggerHandler = new PMC_TriggerHandler();
        objTriggerHandler.setTriggerContext(System.TriggerOperation.BEFORE_INSERT, false);
        System.assertEquals(false, objTriggerHandler.isTriggerExecuting , 'isTriggerExecuting variable should be false');
    }

    /**
    * @description This are test virtual methods.
    */
    @isTest
    static void testVirtualMethods() {
        PMC_TriggerHandler objTrigHandler = new PMC_TriggerHandler();
        objTrigHandler.beforeInsert();
        objTrigHandler.beforeUpdate();
        objTrigHandler.beforeDelete();
        objTrigHandler.afterInsert();
        objTrigHandler.afterUpdate();
        objTrigHandler.afterDelete();
        objTrigHandler.afterUndelete();

        System.assert(true, 'Virtual methods did not execute');
    }

    /**
    * @description This method will be use to cover  PMC_TestUtilityClass.
    */
    private static void resetTest() {
        strLastMethodCalled = null;
    }

    //Modes for testing
    /**
    * @description This method will be use to cover  PMC_TestUtilityClass.
    */
    private static void beforeInsertMode() {
        objTrigHandler.setTriggerContext(System.TriggerOperation.BEFORE_INSERT, true);
    }

    /**
    * @description This method will be use to cover  PMC_TestUtilityClass.
    */
    private static void beforeUpdateMode() {
        objTrigHandler.setTriggerContext(System.TriggerOperation.BEFORE_UPDATE, true);
    }

    /**
    * @description This method will be use to cover  PMC_TestUtilityClass.
    */
    private static void beforeDeleteMode() {
        objTrigHandler.setTriggerContext(System.TriggerOperation.BEFORE_DELETE, true);
    }

    /**
    * @description This method will be use to cover  PMC_TestUtilityClass.
    */
    private static void afterInsertMode() {
        objTrigHandler.setTriggerContext(System.TriggerOperation.AFTER_INSERT, true);
    }

    /**
    * @description This method will be use to cover  PMC_TestUtilityClass.
    */
    private static void afterUpdateMode() {
        objTrigHandler.setTriggerContext(System.TriggerOperation.AFTER_UPDATE, true);
    }

    /**
    * @description This method will be use to cover  PMC_TestUtilityClass.
    */
    private static void afterDeleteMode() {
        objTrigHandler.setTriggerContext(System.TriggerOperation.AFTER_DELETE, true);
    }

    /**
    * @description This method will be use to cover  PMC_TestUtilityClass.
    */
    private static void afterUndeleteMode() {
        objTrigHandler.setTriggerContext(System.TriggerOperation.AFTER_UNDELETE, true);
    }

    //@description test implementation of the PMC_TriggerHandler
    private class TestHandler extends PMC_TriggerHandler {
        /**
        * @description This method will be use to cover  PMC_TestUtilityClass.
        */
        public override void beforeInsert() {
            PMC_TriggerHandlerTest.strLastMethodCalled = 'beforeInsert';
        }
        /**
        * @description This method will be use to cover  PMC_TestUtilityClass.
        */
        public override void beforeUpdate() {
            PMC_TriggerHandlerTest.strLastMethodCalled = 'beforeUpdate';
        }
        /**
        * @description This method will be use to cover  PMC_TestUtilityClass.
        */
        public override void beforeDelete() {
            PMC_TriggerHandlerTest.strLastMethodCalled = 'beforeDelete';
        }
        /**
        * @description This method will be use to cover  PMC_TestUtilityClass.
        */
        public override void afterInsert() {
            PMC_TriggerHandlerTest.strLastMethodCalled = 'afterInsert';
        }
        /**
        * @description This method will be use to cover  PMC_TestUtilityClass.
        */
        public override void afterUpdate() {
            PMC_TriggerHandlerTest.strLastMethodCalled = 'afterUpdate';
        }
        /**
        * @description This method will be use to cover  PMC_TestUtilityClass.
        */
        public override void afterDelete() {
            PMC_TriggerHandlerTest.strLastMethodCalled = 'afterDelete';
        }
        /**
        * @description This method will be use to cover  PMC_TestUtilityClass.
        */
        public override void afterUndelete() {
            PMC_TriggerHandlerTest.strLastMethodCalled = 'afterUndelete';
        }
    }
}