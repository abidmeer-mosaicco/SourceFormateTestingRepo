/**
* @author : Deloitte
* @date : 04/10/2023
* @description : TriggerHandler
**/
public virtual class PMC_TriggerHandler {
    private static Map<String, PMC_LoopCount> mapLoopCount;
    private static Set<String> setBypassedHandlers;
    @TestVisible
    private TriggerContext context;
    @TestVisible
    private Boolean isTriggerExecuting;

    //These vriables are used to skip the trigger operation execution
    @TestVisible private static final Boolean BOOL_BYPASS_BEFORE_INSERT_VIR = false;
    @TestVisible private static final Boolean BOOL_BYPASS_BEFORE_UPDATE_VIR = false;
    @TestVisible private static final Boolean BOOL_BYPASS_BEFORE_DELETE_VIR = false;
    @TestVisible private static final Boolean BOOL_BYPASS_AFTER_INSERT_VIR = false;
    @TestVisible private static final Boolean BOOL_BYPASS_AFTER_UPDATE_VIR = false;
    @TestVisible private static final Boolean BOOL_BYPASS_AFTER_DELETE_VIR = false;
    @TestVisible private static final Boolean BOOL_BYPASS_AFTER_UNDELETE_VIR = false;
    
    /**
     * @description Initialization of static variables
    */
    static {
        mapLoopCount = new Map<String, PMC_LoopCount>();
        setBypassedHandlers = new Set<String>();
        System.debug('Static block initialized: mapLoopCount=' + mapLoopCount + ', setBypassedHandlers=' + setBypassedHandlers);
    }
    
    /**
     * @description Trigger Handler Constructor
     */
    public PMC_TriggerHandler() {
        this.setTriggerContext(Trigger.operationType, Test.isRunningTest());
        System.debug('Constructor called: context=' + this.context + ', isTriggerExecuting=' + this.isTriggerExecuting);
    }
    
    /**
    * @description This is the main method that will be called during trigger execution.
    * Inside this method context specific methods are being called.
    */
    public void run() {
        System.debug('Run method called: context=' + this.context + ', isTriggerExecuting=' + this.isTriggerExecuting);
        if (!validateRun() || PMC_ProcessSwitches__c.getOrgDefaults().PMC_BypassTrigger__c) {
            System.debug('Trigger execution bypassed');
            return;
        }
        /* Updating the Recursion Logic - Prashanth Kamma - 08/05/2025 */
        if (!Test.isRunningTest()) {
    		String phaseKey = getHandlerName() + '_' + String.valueOf(this.context);
    	if (!PMC_SS_TriggerRecursionGuard.isAlreadyProcessed(phaseKey)) {
        	addToLoopCount();
    } else {
        System.debug('Loop count skipped due to recursion guard: ' + phaseKey);
    }
}
        /*if (!Test.isRunningTest()) {
            addToLoopCount();
        }*/
        //Dispatch to the correct handler method
        switch on this.context {
            when BEFORE_INSERT { 
                System.debug('Executing beforeInsert method'); 
                this.beforeInsert(); 
            }
            when BEFORE_UPDATE { 
                System.debug('Executing beforeUpdate method'); 
                this.beforeUpdate(); 
            }
            when BEFORE_DELETE { 
                System.debug('Executing beforeDelete method'); 
                this.beforeDelete(); 
            }
            when AFTER_INSERT { 
                System.debug('Executing afterInsert method'); 
                this.afterInsert(); 
            }
            when AFTER_UPDATE { 
                System.debug('Executing afterUpdate method'); 
                this.afterUpdate(); 
            }
            when AFTER_DELETE { 
                System.debug('Executing afterDelete method'); 
                this.afterDelete(); 
            }
            when AFTER_UNDELETE { 
                System.debug('Executing afterUndelete method'); 
                this.afterUndelete(); 
            }
        }
    }
    
    /**
    * @description This method will be use to set the maximum loop count.
    * @param intMax - Integer value.
    */
    public void setMaxLoopCount(Integer intMax) {
        String strHandlerName = getHandlerName();
        if (!PMC_TriggerHandler.mapLoopCount.containsKey(strHandlerName)) {
            PMC_TriggerHandler.mapLoopCount.put(strHandlerName, new PMC_LoopCount(intMax));
        } else {
            PMC_TriggerHandler.mapLoopCount.get(strHandlerName).setIntMax(intMax);
        }
        System.debug('Max loop count set: strHandlerName=' + strHandlerName + ', intMax=' + intMax);
    }
    
    /**
    * @description This method is used to clear the max loop count
    */
    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
        System.debug('Max loop count cleared');
    }
    
    /**
    * @description This is static method which is defined for bypassing the trigger execution.
    * @param strHandlerName - string
    */
    public static void bypass(String strHandlerName) {
        PMC_TriggerHandler.setBypassedHandlers.add(strHandlerName);
        System.debug('Bypass added: strHandlerName=' + strHandlerName);
    }
    
    /**
    * @description This is static method which is defined for clearing bypassing trigger values.
    * @param strHandlerName - String 
    */
    public static void clearBypass(String strHandlerName) {
        PMC_TriggerHandler.setBypassedHandlers.remove(strHandlerName);
        System.debug('Bypass cleared: strHandlerName=' + strHandlerName);
    }
    
    /**
    * @description This is static method which is defined for checking if the trigger is bypasses
    * @param strHandlerName -String 
    * @return Boolean
    */
    public static Boolean isBypassed(String strHandlerName) {
        Boolean result = PMC_TriggerHandler.setBypassedHandlers.contains(strHandlerName);
        System.debug('Is bypassed: strHandlerName=' + strHandlerName + ', result=' + result);
        return result;
    }
    
    /**
    * @description This is static method which is defined for clearing all the bypassed triggers
    */
    public static void clearAllBypasses() {
        PMC_TriggerHandler.setBypassedHandlers.clear();
        System.debug('All bypasses cleared');
    }
    
    /**
    * @description This method will set the trigger execution context.
    * @param operationType This variable holds the trigger context
    * @param boolTestMode This variable is used to check if the test is executing
    */
    @TestVisible
    private void setTriggerContext(System.TriggerOperation operationType, Boolean boolTestMode) {
        if (!Trigger.isExecuting && !boolTestMode) {
            this.isTriggerExecuting = false;
            System.debug('Trigger is not executing and not in test mode');
            return;
        } else {
            this.isTriggerExecuting = true;
        }
        
        switch on operationType {
            when BEFORE_INSERT { this.context = TriggerContext.BEFORE_INSERT; }
            when BEFORE_UPDATE { this.context = TriggerContext.BEFORE_UPDATE; }
            when BEFORE_DELETE { this.context = TriggerContext.BEFORE_DELETE; }
            when AFTER_INSERT { this.context = TriggerContext.AFTER_INSERT; }
            when AFTER_UPDATE { this.context = TriggerContext.AFTER_UPDATE; }
            when AFTER_DELETE { this.context = TriggerContext.AFTER_DELETE; }
            when AFTER_UNDELETE { this.context = TriggerContext.AFTER_UNDELETE; }
        }
        System.debug('Trigger context set: context=' + this.context);
    }
    
    /**
     * @description Increment the loop count
     */
    @TestVisible
    private void addToLoopCount() {
        String strHandlerName = getHandlerName();
        if (PMC_TriggerHandler.mapLoopCount.containsKey(strHandlerName)) {
            Boolean boolExceeded = PMC_TriggerHandler.mapLoopCount.get(strHandlerName).increment();
            if (boolExceeded) {
                Integer intMax = PMC_TriggerHandler.mapLoopCount.get(strHandlerName).intMax;
                throw new PMC_TriggerHandlerException('intMaximum loop count of ' + String.valueOf(intMax) + ' reached in' + strHandlerName);
            }
        }
        System.debug('Loop count added: strHandlerName=' + strHandlerName);
    }
    
    /**
    * @description This method will make sure this trigger should continue to run.
    * @return This method returns a boolean value
    */
    @TestVisible
    private Boolean validateRun() {
        if (!this.isTriggerExecuting || this.context == null) {
            throw new PMC_TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }
        if (PMC_TriggerHandler.setBypassedHandlers.contains(getHandlerName())) {
            System.debug('Trigger handler is bypassed: handlerName=' + getHandlerName());
            return false;
        }
        return true;
    }
    
    /**
    * @description This method will give us the trigger handler name.
    * @return This method will return the handler name of the trigger.
    */
    @TestVisible
    private String getHandlerName() {
        String handlerName = String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
        System.debug('Handler name: ' + handlerName);
        return handlerName;
    }
    
    /**
    * context-specific methods for override
    */
    /**
    * @description Before Insert virtual method
    */
    @TestVisible
    protected virtual void beforeInsert() {
        /**
         * Creating this condition to avoid empty-block statement
         */
        if (BOOL_BYPASS_BEFORE_INSERT_VIR) {
            return;
        }
        System.debug('Executing beforeInsert method');
    }

    /**
    * @description Before Update virtual method
    */
    @TestVisible
    protected virtual void beforeUpdate() {
        /**
         * Creating this condition to avoid empty-block statement
         */
        if (BOOL_BYPASS_BEFORE_UPDATE_VIR) {
            return;
        }
        System.debug('Executing beforeUpdate method');
    }

    /**
    * @description Before Delete virtual method
    */
    @TestVisible
    protected virtual void beforeDelete() {
        /**
         * Creating this condition to avoid empty-block statement
         */
        if (BOOL_BYPASS_BEFORE_DELETE_VIR) {
            return;
        }
        System.debug('Executing beforeDelete method');
    }

    /**
    * @description After Insert virtual method
    */
    @TestVisible
    protected virtual void afterInsert() {
        /**
         * Creating this condition to avoid empty-block statement
         */
        if (BOOL_BYPASS_AFTER_INSERT_VIR) {
            return;
        }
        System.debug('Executing afterInsert method');
    }

    /**
    * @description After Update virtual method
    */
    @TestVisible
    protected virtual void afterUpdate() {
        /**
         * Creating this condition to avoid empty-block statement
         */
        if (BOOL_BYPASS_AFTER_UPDATE_VIR) {
            return;
        }
        System.debug('Executing afterUpdate method');
    }

    /**
    * @description After Delete virtual method
    */
    @TestVisible
    protected virtual void afterDelete() {
        /**
         * Creating this condition to avoid empty-block statement
         */
        if (BOOL_BYPASS_AFTER_DELETE_VIR) {
            return;
        }
        System.debug('Executing afterDelete method');
    }

    /**
    * @description After Undelete virtual method
    */
    @TestVisible
    protected virtual void afterUndelete() {
        /**
         * Creating this condition to avoid empty-block statement
         */
        if (BOOL_BYPASS_AFTER_UPDATE_VIR) {
            return;
        }
        System.debug('Executing afterUndelete method');
    }
    
    /**
    * @description Inner class for managing the loop count per handler
    */
    @TestVisible
    private class PMC_LoopCount {
        private Integer intMax;
        private Integer intCount;

        /**
        * @description Inner class constructor
        */
        public PMC_LoopCount() {
            this.intMax = 5;
            this.intCount = 0;
            System.debug('PMC_LoopCount initialized: intMax=' + this.intMax + ', intCount=' + this.intCount);
        }

        /**
        * @description Method to set the max loop count
        * @param intMax - integer
        */
        public PMC_LoopCount(Integer intMax) {
            this.intMax = intMax;
            this.intCount = 0;
            System.debug('PMC_LoopCount initialized with intMax: intMax=' + this.intMax + ', intCount=' + this.intCount);
        }

        /**
        * @description Method increases the count with every iteration
        * @return Boolean
        */
        public Boolean increment() {
            this.intCount++;
            System.debug('Loop count incremented: intCount=' + this.intCount);
            return this.exceeded();
        }

        /**
        * @description Method checks if the loop limit is exceeded
        * @return Boolean
        */
        public Boolean exceeded() {
            if (this.intMax < 0) {
                return false;
            }
            if (this.intCount > this.intMax) {
                return true;
            }
            return false;
        }
        
        /**
        * @description Method to get the max number of iterations
        * @return Integer
        */
        public Integer getMax() {
            return this.intMax;
        }

        /**
        * @description Method to get the max number of iterations
        * @return Integer
        */
        public Integer getCount() {
            return this.intCount;
        }

        /**
        * @description Method to set the max number of iterations
        * @param intMax - Integer 
        */
        public void setIntMax(Integer intMax) {
            this.intMax = intMax;
        }
    }
    
    //@description Trigger contexts
    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT,
        BEFORE_UPDATE,
        BEFORE_DELETE,
        AFTER_INSERT,
        AFTER_UPDATE,
        AFTER_DELETE,
        AFTER_UNDELETE
    }
    
    /**
     * @description Exception Class
     */
    public class PMC_TriggerHandlerException extends Exception {}
}