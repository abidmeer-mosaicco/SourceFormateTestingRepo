public class CLIBalanceCalculator {
    private Set<Id> CONTRACT_LINE_IDS;

    @TestVisible private static Set<String> ORDER_TYPE_CODES        = Test.isRunningTest() ? new Set<String>{'ZEXP','ZKBB','ZKEB','ZOFA','ZOP','ZOR','ZORB','ZORN','ZORP','ZRCM','ZRFA'} : getTypesFromCMT('ORDER_TYPE_CODES');
    @TestVisible private static Set<String> RETURN_ORDER_TYPE_CODES  = Test.isRunningTest() ? new Set<String>{'ZKAB','ZRE','ZREB','ZREF','ZREM','ZRES','ZROB','ZROF','ZROS'} : getTypesFromCMT('RETURN_ORDER_TYPE_CODES');
    
    private static final Set<String> RETURN_BILLING_DOC_TYPES = new Set<String>{ 'ZRE', 'ZREB', 'ZRES'};

    public CLIBalanceCalculator(Set<Id> clids) {
        clids.remove(null);
        this.CONTRACT_LINE_IDS = clids;
    }

    public void execute() {
        if (CONTRACT_LINE_IDS.isEmpty())
            return;

        Map<Id, Contract_Line_Item__c> cliMap = new Map<Id, Contract_Line_Item__c>([SELECT Id, Quantity__c, Subscription__c, Subscription__r.PMC_CPQ_RejectionReason__c, Original_Subscription_Ref__r.PMC_CPQ_RejectionReason__c, Contract__r.Account.PMC_CPQ_Region__c FROM Contract_Line_Item__c WHERE Id IN :CONTRACT_LINE_IDS]);

        if (cliMap.isEmpty())
            return;

        Map<Id, Set<Id>> cliToSubIds = new Map<Id, Set<Id>>();
        Set<Id> allSubIds = new Set<Id>();

        for (SBQQ__Subscription__c sub : [SELECT Id, Contract_Line_Item__c FROM SBQQ__Subscription__c WHERE Contract_Line_Item__c IN :cliMap.keySet()]) {
            if (!cliToSubIds.containsKey(sub.Contract_Line_Item__c)) {
                cliToSubIds.put(sub.Contract_Line_Item__c, new Set<Id>());
            }
            cliToSubIds.get(sub.Contract_Line_Item__c).add(sub.Id);
            allSubIds.add(sub.Id);
        }

        Map<Id,OrderItem> orderItems = new Map<Id,OrderItem>();
        Set<Id> allOiIds = new Set<Id>();
        List<PMC_CPQ_InvoiceItem__c> invItems = new List<PMC_CPQ_InvoiceItem__c>();

        if (!allSubIds.isEmpty())
            orderItems = new Map<Id,OrderItem>([SELECT Id, Order.Status, Quantity, SBQQ__Subscription__c, Order.PMC_DH_OrderTypeCode__c, PMC_CPQ_ReasonOfRejectionOfItem__c FROM OrderItem WHERE SBQQ__Subscription__c IN :allSubIds]);

        for (OrderItem oi : orderItems.values())
            allOiIds.add(oi.Id);

        if (!allOiIds.isEmpty()) {
            invItems = [SELECT PMC_CPQ_NetInvoicedQuantity__c, PMC_CPQ_OrderProduct__c, PMC_CPQ_Invoice__r.PMC_CPQ_BillingDocType__c,
                               PMC_CPQ_Invoice__r.PMC_CPQ_Cancelled__c, PMC_CPQ_Invoice__r.PMC_CPQ_Type__c
                        FROM PMC_CPQ_InvoiceItem__c
                        WHERE PMC_CPQ_OrderProduct__c IN :allOiIds];
        }

        List<Contract_Line_Item__c> toUpdate = new List<Contract_Line_Item__c>();

        for (Id cliId : CONTRACT_LINE_IDS) {
            Contract_Line_Item__c cli = cliMap.get(cliId);
            if (cli == null) continue;

            Set<Id> subIds      = cliToSubIds.get(cliId) ?? new Set<Id>();
            Set<Id> oiIdsForCli = new Set<Id>();
            Decimal totalOrdered = 0;

            for (OrderItem oi : orderItems.values()) {
                if (!subIds.contains(oi.SBQQ__Subscription__c))
                    continue;

                String typeCode = oi.Order.PMC_DH_OrderTypeCode__c;
                Boolean isStandardType = ORDER_TYPE_CODES.contains(typeCode);
                Boolean isReturnType   = RETURN_ORDER_TYPE_CODES.contains(typeCode);

                if (!isStandardType && !isReturnType)
                    continue;

                oiIdsForCli.add(oi.Id);

                if (isStandardType && oi.PMC_CPQ_ReasonOfRejectionOfItem__c == null && oi.Order.Status != 'Cancelled')
                    totalOrdered += oi.Quantity ?? 0;
            }

            Decimal returnQty   = 0;
            Decimal invoicedQty = 0;

            for (PMC_CPQ_InvoiceItem__c ii : invItems) {
                if (!oiIdsForCli.contains(ii.PMC_CPQ_OrderProduct__c))
                    continue;

                if (ii.PMC_CPQ_Invoice__r.PMC_CPQ_BillingDocType__c == 'FA')
                    continue;

                if (ii.PMC_CPQ_Invoice__r.PMC_CPQ_Cancelled__c == true)
                    continue;

                Boolean isReturn = RETURN_BILLING_DOC_TYPES.contains(ii.PMC_CPQ_Invoice__r.PMC_CPQ_BillingDocType__c);

                if (isReturn) {
                    returnQty += ii.PMC_CPQ_NetInvoicedQuantity__c ?? 0;
                } else {
                    invoicedQty += ii.PMC_CPQ_NetInvoicedQuantity__c ?? 0;
                }
            }

            Boolean isSubscriptionRejected = String.isNotBlank(cli.Subscription__r?.PMC_CPQ_RejectionReason__c)
                || String.isNotBlank(cli.Original_Subscription_Ref__r?.PMC_CPQ_RejectionReason__c);

            
            Decimal c2 = totalOrdered - returnQty;
            Decimal c3 = isSubscriptionRejected ? 0 : (cli.Quantity__c ?? 0) - c2;
            Decimal c5 = invoicedQty - returnQty;
            Decimal c4 = c2 - (invoicedQty - returnQty);
            
            Contract_Line_Item__c contractline = new Contract_Line_Item__c();
            contractline.Id                          = cliId;
            contractline.Total_Ordered_Quantity__c   = c2;
            contractline.Total_Available_Quantity__c = c3;
            contractline.Total_Consumed_Quantity__c  = c4;
            contractline.Invoiced_Quantity__c        = c5;
          
            toUpdate.add(contractline);
        }

        if (!toUpdate.isEmpty())
            update toUpdate;

        Map<Id, SBQQ__Subscription__c> subsToUpdateMap = new Map<Id, SBQQ__Subscription__c>();
        for (Contract_Line_Item__c cliCalc : toUpdate) {
            Id subId = cliMap.get(cliCalc.Id)?.Subscription__c;
            if (subId == null) continue;

            subsToUpdateMap.put(subId, new SBQQ__Subscription__c(
                Id                                = subId,
                PMC_CPQ_TotalAvailableQuantity__c = cliCalc.Total_Available_Quantity__c,
                PMC_CPQ_TotalOrderedQuantity__c   = cliCalc.Total_Ordered_Quantity__c
            ));
        }

        List<SBQQ__Subscription__c> subsToUpdate = subsToUpdateMap.values();

        if (!subsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(subsToUpdate, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    System.debug(LoggingLevel.ERROR,
                        'Falha ao propagar saldo para Subscription ' + subsToUpdate[i].Id + ': '
                        + results[i].getErrors()[0].getMessage());
                }
            }
        }
    }

    private static Set<String> getTypesFromCMT(String developerName) {
        List<PMC_DH_Store_Configuration__mdt> cmts = [
            SELECT PMC_DH_FieldsAPIName__c
            FROM PMC_DH_Store_Configuration__mdt
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];

        if (cmts.isEmpty())
            return new Set<String>();

        Set<String> values = new Set<String>();
        for (String raw : cmts.get(0).PMC_DH_FieldsAPIName__c.split(',')) {
            values.add(raw.trim().removeStart('"').removeEnd('"').trim());
        }
        return values;
    }
}