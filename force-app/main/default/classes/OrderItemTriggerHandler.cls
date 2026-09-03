/**
* @description This class will be used to handle all trigger operations of OrderItem object
* @author Raphael Soares
* @storynumber GCPM-2396 - FPD I - PM Approval Workflow and Approvers
*/
public without sharing class OrderItemTriggerHandler extends PMC_TriggerHandler  {
    
    /**
* These boolean variables are used to bypass the trigger operations
*/
    private static final Boolean BOOL_BYPASS_BEFORE_UPDATE;
    private static final Boolean BOOL_BYPASS_AFTER_UPDATE;
    private static Boolean HAS_RUN_CLI_BALANCE = false;
    
    @testVisible
    public static Boolean boolBypassTriggerLogic = false;
    
    
    /**
* These variables will hold the copy of trigger variables
*/
    private List<OrderItem> newOrderItems;
    private Map<Id,OrderItem> oldOrderItems;
    
    /**
* @description This static block initializes the trigger switches when the class is invoked
*/
    static{
        
        PMC_TriggerSwitches__mdt operationSwitches = PMC_TriggerSwitches__mdt.getInstance('OrderItem');
        BOOL_BYPASS_AFTER_UPDATE = operationSwitches.PMC_AfterUpdate__c;
        BOOL_BYPASS_BEFORE_UPDATE = operationSwitches.PMC_BeforeUpdate__c;
    }
    
    /**
* @description Constructor method to initialize class level variables and store the trigger collections and add the max loop count of trigger
*/
    
    public OrderItemTriggerHandler(){    
        
        //Instantiating local class variables from trigger variables
        this.newOrderItems = Trigger.new;
        this.oldOrderItems = (Map<Id, OrderItem>)Trigger.oldMap;
        //Set the maximum calls allowed for the class
        this.setMaxLoopCount(8);
    }
    
    public override void afterInsert() {
        if (BOOL_BYPASS_AFTER_UPDATE || boolBypassTriggerLogic) return;

        Set<Id> allOiIds = new Set<Id>();
        for (OrderItem oi : newOrderItems) {
            if (oi.SBQQ__Subscription__c != null) {
                allOiIds.add(oi.Id);
            }
        }

        enqueueCliBalanceIfNeeded(allOiIds);
    }
    
    public override void afterUpdate(){
        if(BOOL_BYPASS_AFTER_UPDATE  || boolBypassTriggerLogic){
            return;
        }
        Set<Id> approvedItems = new Set<Id>();
        Set<Id> itemsWithNewIntegrationMsg = new Set<Id>();
        Set<Id> itemsWithBalanceChange = new Set<Id>();
        
        for (OrderItem item : newOrderItems) {
            if (RecordValidator.isFieldChanged(item, oldOrderItems, 'ApprovalStatus__c', 'Approved')) {
                approvedItems.add(item.Id);
            }
            if (
                (UserInfo.getName() == 'Integration User' || Test.isRunningTest()) &&
                RecordValidator.isFieldChanged(item, oldOrderItems, 'PMC_CPQ_OrderItemIntegrationMessage__c', null)
            ) {
                if (ExecutionController.executeOnce('itemsWithNewIntegrationMsg_' + item.Id)) {
                    itemsWithNewIntegrationMsg.add(item.Id);
                }
            }
            
            OrderItem old = oldOrderItems.get(item.Id);
            
            if (item.Quantity != old.Quantity || item.PMC_CPQ_ReasonOfRejectionOfItem__c != old.PMC_CPQ_ReasonOfRejectionOfItem__c) {
                itemsWithBalanceChange.add(item.Id);
            }
        }
        if (!approvedItems.isEmpty()) {
            List<OrderItem> orderItems = [
                SELECT
                Id,
                OrderItemNumber,
                Order.OrderNumber,
                SBQQ__Contract__r.PMC_CPQ_ContractNumberIdentifier__c,
                PMC_CPQ_LinePONumber__c,
                PMC_CPQ_ShipTo__r.Name,
                Order.Account.Name,
                Product2.Name,
                Quantity,
                PMC_CPQ_PricingDate__c,
                PMC_CPQ_FPDPricefromPriceFx__c,
                PMC_CPQ_FinalAgreedPrice__c,
                PMC_CPQ_OrderLineStatus__c,
                PMC_CPQ_OrderItemIntegrationStatus__c,
                PMC_CPQ_OrderItemIntegrationMessage__c,
                Sent_to_SAP_By__c,
                Order.PMC_CPQ_SAPOrderNumber__c
                FROM OrderItem
                WHERE Id IN :approvedItems
            ];
            System.enqueueJob(new PMC_CPQ_FPDActionClass(orderItems, true));
        }
        if (!itemsWithNewIntegrationMsg.isEmpty()) {
            sendSAPIntegrationEmail(itemsWithNewIntegrationMsg);
            publishIntegrationPlatformEvents(itemsWithNewIntegrationMsg);
        }
        
        enqueueCliBalanceIfNeeded(itemsWithBalanceChange);
    }
    
    private void sendSAPIntegrationEmail(Set<Id> itemIds) {
        try {
            // Group recipients by OrderId
            Map<Id, Set<Id>> mapUserIdsByOrderId = new Map<Id, Set<Id>>();
            // Build a set of all related AccountIds by the affected OrderId(s)
            Set<Id> orderIds = new Set<Id>();
            for (OrderItem oi : newOrderItems) {
                if (itemIds.contains(oi.Id) && oi.OrderId != null) {
                    orderIds.add(oi.OrderId);
                }
            }
            if (orderIds.isEmpty())
                return;
            
            // Query Accounts and AccountTeamMembers for those Orders' Accounts
            Map<Id, Id> orderToAccount = new Map<Id, Id>();
            for (Order ord : [SELECT Id, AccountId FROM Order WHERE Id IN :orderIds]) {
                orderToAccount.put(ord.Id, ord.AccountId);
            }
            Set<Id> accountIds = new Set<Id>(orderToAccount.values());
            Map<Id, Set<Id>> accountToUserIds = new Map<Id, Set<Id>>();
            for (Account acc : [
                SELECT
                Id,
                (SELECT UserId FROM AccountTeamMembers WHERE TeamMemberRole IN ('Sales Support Representative', 'Account Manager'))
                FROM Account
                WHERE Id IN :accountIds
            ]) {
                Set<Id> team = new Set<Id>();
                for (AccountTeamMember atmRecord : acc.AccountTeamMembers) {
                    team.add(atmRecord.UserId);
                }
                accountToUserIds.put(acc.Id, team);
            }
            
            // Add Sent_to_SAP_By__c when applicable and build the map per Order
            for (OrderItem oi : newOrderItems) {
                if (!itemIds.contains(oi.Id) || oi.OrderId == null)
                    continue;
                Id accId = orderToAccount.get(oi.OrderId);
                Set<Id> users = new Set<Id>();
                if (accId != null && accountToUserIds.containsKey(accId)) {
                    users.addAll(accountToUserIds.get(accId));
                }
                Id sentBy = oldOrderItems.get(oi.Id).Sent_to_SAP_By__c;
                if (sentBy != null && !users.contains(sentBy)) {
                    users.add(sentBy);
                }
                if (!users.isEmpty()) {
                    if (!mapUserIdsByOrderId.containsKey(oi.OrderId)) {
                        mapUserIdsByOrderId.put(oi.OrderId, new Set<Id>());
                    }
                    mapUserIdsByOrderId.get(oi.OrderId).addAll(users);
                }
            }
            
            // Send once with all recipients grouped by OrderId
            if (!mapUserIdsByOrderId.isEmpty()) {
                EmailUtils.sendEmailWithTemplateAsync(JSON.serialize(mapUserIdsByOrderId), 'Order_Items_Sent_To_SAP');
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error sending SAP integration success email::: ' + ex.getMessage());
        }
    }
    
    /**
* @description Publishes platform events for Order Items whose Integration Message just changed.
*  We group by current Integration Status (Success / Error) and reuse existing publish logic.
* @param itemIds Set of OrderItem Ids whose integration message changed.
*/
    private void publishIntegrationPlatformEvents(Set<Id> itemIds) {
        if (itemIds == null || itemIds.isEmpty()) {
            return;
        }
        String sendFPDPriceFXURL = PMC_CPQ_sendFPDOrderProductsSAPClass.sendFPDPriceFXURL();
        try {
            // Build events individually so each Order Item keeps its own status & message.
            List<PMC_CPQ_FPDPriceFx__e> platformEvents = new List<PMC_CPQ_FPDPriceFx__e>();
            for (OrderItem oi : newOrderItems) {
                if (!itemIds.contains(oi.Id)) {
                    continue;
                }
                PMC_CPQ_FPDPriceFx__e evt = new PMC_CPQ_FPDPriceFx__e();
                evt.PMC_CPQ_OrderLineIntegrationStatus__c = oi.PMC_CPQ_OrderItemIntegrationStatus__c;
                evt.PMC_CPQ_IntegrationStatusMessage__c = oi.PMC_CPQ_OrderItemIntegrationMessage__c;
                evt.PMC_CPQ_InterfaceURL__c = sendFPDPriceFXURL;
                evt.PMC_CPQ_OrderItemId__c = oi.Id;
                evt.PMC_CPQ_FPDPrice__c = oi.PMC_CPQ_FPDPricefromPriceFx__c;
                platformEvents.add(evt);
            }
            if (!platformEvents.isEmpty()) {
                EventBus.publish(platformEvents);
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error publishing integration platform events: ' + ex.getMessage());
        }
    }
    
    private void enqueueCliBalanceIfNeeded(Set<Id> oiIds) {
        if (oiIds.isEmpty() || HAS_RUN_CLI_BALANCE)
            return;
        
        Set<Id> subIds = new Set<Id>();
        
        for (OrderItem oi : newOrderItems) {
            if (oiIds.contains(oi.Id) && oi.SBQQ__Subscription__c != null) {
                subIds.add(oi.SBQQ__Subscription__c);
            }
        } 
        if (subIds.isEmpty()) return;
        
        Set<Id> cliIds = new Set<Id>();
        
        for (SBQQ__Subscription__c sub : [SELECT Contract_Line_Item__c FROM SBQQ__Subscription__c WHERE Id IN :subIds AND Contract_Line_Item__c != NULL]) {
            cliIds.add(sub.Contract_Line_Item__c);
        }
        
        if (cliIds.isEmpty()) return;
        
        HAS_RUN_CLI_BALANCE = true;
        new CLIBalanceCalculator(cliIds).execute();
    }
}