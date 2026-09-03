public class CLIBalanceTriggerHandler {

    private static final String INTEGRATION_USER_NAME = 'Integration User';
    private static final Boolean BOOL_BYPASS_BEFORE_UPDATE;
    private static final Boolean BOOL_BYPASS_AFTER_UPDATE;

    @TestVisible public static Boolean boolBypassTriggerLogic = false;

    private static final Set<Id> QUEUED_INSERT_IDS = new Set<Id>();
    private static final Set<Id> QUEUED_UPDATE_IDS = new Set<Id>();

    static {
        Boolean bypassBefore = false;
        Boolean bypassAfter  = false;
        if (UserInfo.getName() != INTEGRATION_USER_NAME) {
            PMC_TriggerSwitches__mdt switches = PMC_TriggerSwitches__mdt.getInstance('Contract_Line_Item');
            if (switches != null) {
                bypassBefore = switches.PMC_BeforeUpdate__c;
                bypassAfter  = switches.PMC_AfterUpdate__c;
            }
        }
        BOOL_BYPASS_BEFORE_UPDATE = bypassBefore;
        BOOL_BYPASS_AFTER_UPDATE  = bypassAfter;
    }

    public static void beforeUpdate(List<Contract_Line_Item__c> newList, Map<Id, Contract_Line_Item__c> oldMap) {
        if (BOOL_BYPASS_BEFORE_UPDATE || boolBypassTriggerLogic) return;
        applyRejectionReset(newList);
    }

    public static void afterInsert(List<Contract_Line_Item__c> newList) {
        if (BOOL_BYPASS_AFTER_UPDATE || boolBypassTriggerLogic) return;

        Set<Id> toEnqueue = new Set<Id>();
        for (Contract_Line_Item__c cli : newList) {
            if (QUEUED_INSERT_IDS.add(cli.Id))
                toEnqueue.add(cli.Id);
        }

        if (!toEnqueue.isEmpty())
            new CLIBalanceCalculator(toEnqueue).execute();
    }

    public static void afterUpdate(List<Contract_Line_Item__c> newList, Map<Id, Contract_Line_Item__c> oldMap) {
        if (BOOL_BYPASS_AFTER_UPDATE || boolBypassTriggerLogic) return;

        Set<Id> toEnqueue = new Set<Id>();
        for (Contract_Line_Item__c cli : newList) {
            if ((cli.Quantity__c != oldMap.get(cli.Id).Quantity__c || cli.PMC_CPQ_RejectionReason__c != oldMap.get(cli.Id).PMC_CPQ_RejectionReason__c)
                    && !QUEUED_INSERT_IDS.contains(cli.Id)
                    && QUEUED_UPDATE_IDS.add(cli.Id)) {
                toEnqueue.add(cli.Id);
            }
        }
        if (!toEnqueue.isEmpty())
            new CLIBalanceCalculator(toEnqueue).execute();
    }

    private static void applyRejectionReset(List<Contract_Line_Item__c> newList) {
        Set<Id> subIds = new Set<Id>();
        for (Contract_Line_Item__c item : newList) {
            if (item.Subscription__c != null)
                subIds.add(item.Subscription__c);
            if (item.Original_Subscription_Ref__c != null)
                subIds.add(item.Original_Subscription_Ref__c);
        }
        if (subIds.isEmpty()) return;

        Map<Id, SBQQ__Subscription__c> subMap = new Map<Id, SBQQ__Subscription__c>([
            SELECT Id, PMC_CPQ_RejectionReason__c
            FROM SBQQ__Subscription__c
            WHERE Id IN :subIds
        ]);

        for (Contract_Line_Item__c item : newList) {
            SBQQ__Subscription__c sub = item.Subscription__c != null ? subMap.get(item.Subscription__c) : null;
            if (sub == null && item.Original_Subscription_Ref__c != null)
                sub = subMap.get(item.Original_Subscription_Ref__c);

            if (sub != null && String.isNotBlank(sub.PMC_CPQ_RejectionReason__c)) {
                item.Total_Available_Quantity__c = 0;
            }
        }
    }
}