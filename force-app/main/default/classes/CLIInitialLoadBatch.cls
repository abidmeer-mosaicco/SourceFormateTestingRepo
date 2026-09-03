global class CLIInitialLoadBatch implements Database.Batchable<SObject>, Database.Stateful {
    @TestVisible global Integer total_clis_created  = 0;
    @TestVisible global Integer total_clis_failed   = 0;
    @TestVisible global Integer total_subs_linked   = 0;
    @TestVisible global Integer total_subs_failed   = 0;

    private List<String> error_log   = new List<String>();
    private Set<Id>      target_ids;
    private Datetime     start_time;
    private Boolean      reprocess;

    global CLIInitialLoadBatch() {
        this.target_ids = null;
        this.reprocess  = false;
    }

    global CLIInitialLoadBatch(Set<Id> contractIds) {
        this.target_ids = contractIds;
        this.reprocess  = false;
    }

    global CLIInitialLoadBatch(Set<Id> contractIds, Boolean reprocess) {
        this.target_ids = contractIds;
        this.reprocess  = reprocess == true;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        start_time = Datetime.now();

        if (reprocess) {
            if (target_ids != null && !target_ids.isEmpty()) {
                return Database.getQueryLocator([SELECT Id FROM Contract WHERE Id IN :target_ids]);
            }
            return Database.getQueryLocator([SELECT Id FROM Contract]);
        }

        if (target_ids != null && !target_ids.isEmpty()) {
            return Database.getQueryLocator([
                SELECT Id
                FROM   Contract
                WHERE  Id IN :target_ids
                AND    Id NOT IN (
                    SELECT Contract__c
                    FROM   Contract_Line_Item__c
                    WHERE  Contract__c != null
                )
            ]);
        }

        return Database.getQueryLocator([
            SELECT Id
            FROM Contract
            WHERE Id NOT IN (
                SELECT Contract__c
                FROM   Contract_Line_Item__c
                WHERE  Contract__c != null
            )
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Contract> contracts) {
        Set<Id> contractIds = new Map<Id, Contract>(contracts).keySet();
        List<SBQQ__Subscription__c> allSubs = [
            SELECT Id,
                   SBQQ__Contract__c,
                   SBQQ__Product__c,
                   SBQQ__Quantity__c,
                   SBQQ__OriginalQuoteLine__c,
                   SBQQ__RevisedSubscription__c,
                   PMC_CPQ_LatestSubscription__c,
                   SBQQ__TerminatedDate__c,
                   SBQQ__SubscriptionEndDate__c,
                   PMC_CPQ_RejectionReason__c,
                   CreatedDate,
                   SBQQ__QuoteLine__c,
                   SBQQ__QuoteLine__r.SBQQ__Quote__c,
                   SBQQ__StartDate__c,
                   SBQQ__EndDate__c,
                   SBQQ__NetPrice__c
            FROM   SBQQ__Subscription__c
            WHERE  SBQQ__Contract__c IN :contractIds
            AND    (SBQQ__TerminatedDate__c = null OR SBQQ__TerminatedDate__c >= TODAY)
            ORDER  BY SBQQ__Contract__c, CreatedDate ASC
        ];

        if (allSubs.isEmpty()) return;

        Map<Id, SBQQ__Subscription__c> subById = new Map<Id, SBQQ__Subscription__c>();
        for (SBQQ__Subscription__c s : allSubs) {
            subById.put(s.Id, s);
        }

        Map<Id, Id> subToRoot = new Map<Id, Id>();
        for (SBQQ__Subscription__c sub : allSubs) {
            Id cursor = sub.Id;
            Integer safety = 0;
            while (safety < 30) {
                SBQQ__Subscription__c cur = subById.get(cursor);
                Id revised = cur?.SBQQ__RevisedSubscription__c;
                if (revised == null || !subById.containsKey(revised)) break;
                cursor = revised;
                safety++;
            }
            subToRoot.put(sub.Id, cursor);
        }

        Map<String, List<SBQQ__Subscription__c>> groups =
            new Map<String, List<SBQQ__Subscription__c>>();

        for (SBQQ__Subscription__c sub : allSubs) {
            Id rootId = subToRoot.get(sub.Id);
            String key = (String) sub.SBQQ__Contract__c + '|sub|' + (String) rootId;

            if (!groups.containsKey(key)) {
                groups.put(key, new List<SBQQ__Subscription__c>());
            }
            groups.get(key).add(sub);
        }

        List<Contract_Line_Item__c> clisToInsert = new List<Contract_Line_Item__c>();
        List<String>                insertKeys   = new List<String>();
        List<Contract_Line_Item__c> clisToUpdate = new List<Contract_Line_Item__c>();
        List<String>                updateKeys   = new List<String>();

        Map<Id, Contract_Line_Item__c> existingByRootSub = reprocess
            ? queryExistingClisByRootSub(contractIds)
            : new Map<Id, Contract_Line_Item__c>();

        for (String key : groups.keySet()) {
            List<SBQQ__Subscription__c> grp = groups.get(key);

            Decimal               totalQty   = 0;
            Id                    contractId = grp[0].SBQQ__Contract__c;
            SBQQ__Subscription__c rootSub    = null;
            SBQQ__Subscription__c latestSub  = null;
            Datetime              latestDate = null;

            for (SBQQ__Subscription__c sub : grp) {
                totalQty += sub.SBQQ__Quantity__c ?? 0;

                if (sub.SBQQ__RevisedSubscription__c == null
                        || !subById.containsKey(sub.SBQQ__RevisedSubscription__c)) {
                    rootSub = sub;
                }

                if (latestDate == null || sub.CreatedDate > latestDate) {
                    latestDate = sub.CreatedDate;
                    latestSub  = sub;
                }
            }

            if (rootSub  == null) rootSub  = grp[0];
            if (latestSub == null) latestSub = grp[grp.size() - 1];

            Id      rootId   = rootSub.Id;
            Boolean hasChain = grp.size() > 1;

            Contract_Line_Item__c cliRecord = new Contract_Line_Item__c(
                Contract__c                  = contractId,
                Subscription__c              = rootId,
                Original_Subscription__c     = hasChain,
                Original_Subscription_Id__c  = rootId,
                Original_Subscription_Ref__c = rootId,
                Quantity__c                  = totalQty.setScale(2, RoundingMode.HALF_UP),
                Product__c                   = rootSub.SBQQ__Product__c,
                Quote_Line__c                = rootSub.SBQQ__QuoteLine__c,
                Latest_Quote_Line__c         = latestSub.SBQQ__QuoteLine__c,
                Original_Quote_Line__c       = rootSub.SBQQ__QuoteLine__c,
                Source_Quote__c              = rootSub.SBQQ__QuoteLine__r?.SBQQ__Quote__c,
                Start_Date__c                = rootSub.SBQQ__StartDate__c,
                End_Date__c                  = latestSub.SBQQ__EndDate__c,
                Net_Price__c                 = latestSub.SBQQ__NetPrice__c,
                Line_Status__c               = hasChain ? 'Amended' : 'Active'
            );

            if (reprocess) {
                Contract_Line_Item__c existing = existingByRootSub.get(rootId);
                if (existing != null) {
                    cliRecord.Id = existing.Id;
                    clisToUpdate.add(cliRecord);
                    updateKeys.add(key);
                    continue;
                }
            }

            clisToInsert.add(cliRecord);
            insertKeys.add(key);
        }

        Map<Id, SBQQ__Subscription__c> subsToUpdateMap = new Map<Id, SBQQ__Subscription__c>();
        Set<Id>                        allCliIds        = new Set<Id>();

        if (!clisToInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(clisToInsert, false);

            for (Integer i = 0; i < insertResults.size(); i++) {
                Database.SaveResult sr = insertResults[i];

                if (!sr.isSuccess()) {
                    total_clis_failed++;
                    error_log.add('[CLI INSERT] key=' + insertKeys[i]
                        + ' | ' + sr.getErrors()[0].getMessage());
                    continue;
                }

                total_clis_created++;
                Id newCliId = sr.getId();
                allCliIds.add(newCliId);

                for (SBQQ__Subscription__c sub : groups.get(insertKeys[i])) {
                    subsToUpdateMap.put(sub.Id, new SBQQ__Subscription__c(
                        Id                    = sub.Id,
                        Contract_Line_Item__c = newCliId
                    ));
                }
            }
        }

        if (!clisToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(clisToUpdate, false);

            for (Integer i = 0; i < updateResults.size(); i++) {
                Database.SaveResult sr = updateResults[i];

                if (!sr.isSuccess()) {
                    total_clis_failed++;
                    error_log.add('[CLI UPDATE] key=' + updateKeys[i]
                        + ' | ' + sr.getErrors()[0].getMessage());
                    continue;
                }

                total_clis_created++;
                Id updatedCliId = clisToUpdate[i].Id;
                allCliIds.add(updatedCliId);

                for (SBQQ__Subscription__c sub : groups.get(updateKeys[i])) {
                    subsToUpdateMap.put(sub.Id, new SBQQ__Subscription__c(
                        Id                    = sub.Id,
                        Contract_Line_Item__c = updatedCliId
                    ));
                }
            }
        }

        List<SBQQ__Subscription__c> subsToUpdate = subsToUpdateMap.values();

        if (!subsToUpdate.isEmpty()) {
            SBQQ.TriggerControl.disable();
            Database.SaveResult[] subUpdateResults = Database.update(subsToUpdate, false);
            SBQQ.TriggerControl.enable();
            for (Integer i = 0; i < subUpdateResults.size(); i++) {
                if (subUpdateResults[i].isSuccess()) {
                    total_subs_linked++;
                } else {
                    total_subs_failed++;
                    error_log.add('[SUB UPDATE] subId=' + subsToUpdate[i].Id
                        + ' | ' + subUpdateResults[i].getErrors()[0].getMessage());
                }
            }
        }

        if (!allCliIds.isEmpty()) {
            new CLIBalanceCalculator(allCliIds).execute();
        }
    }

    private Map<Id, Contract_Line_Item__c> queryExistingClisByRootSub(Set<Id> contractIds) {
        Map<Id, Contract_Line_Item__c> result = new Map<Id, Contract_Line_Item__c>();
        for (Contract_Line_Item__c existing : [
            SELECT Id, Subscription__c
            FROM   Contract_Line_Item__c
            WHERE  Contract__c IN :contractIds
            AND    Subscription__c != null
        ]) {
            result.put(existing.Subscription__c, existing);
        }
        return result;
    }

    global void finish(Database.BatchableContext bc) {
        Datetime end_time     = Datetime.now();
        Long     durationMs   = end_time.getTime() - start_time.getTime();
        Long     durationMin  = durationMs / 1000 / 60;
        Long     durationSec  = Math.mod(durationMs / 1000, 60);
        String   durationStr  = durationMin + 'min ' + durationSec + 'seg';

        String summary = String.join(new List<String>{
            'CLIInitialLoadBatch - Carga concluida',
            'Inicio:                  ' + start_time.format('dd/MM/yyyy HH:mm:ss'),
            'Fim:                     ' + end_time.format('dd/MM/yyyy HH:mm:ss'),
            'Duracao:                 ' + durationStr,
            'CLIs criados:            ' + total_clis_created,
            'CLIs com erro:           ' + total_clis_failed,
            'Subscriptions vinculadas:' + total_subs_linked,
            'Subscriptions com erro:  ' + total_subs_failed
        }, '\n');

        System.debug(LoggingLevel.INFO, summary);

        if (!error_log.isEmpty()) {
            System.debug(LoggingLevel.ERROR,
                'Primeiros ' + Math.min(error_log.size(), 50) + ' erros:\n'
                + String.join(firstN(error_log, 50), '\n'));
        }

        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
            mail.setSubject('CLIInitialLoadBatch - ' +
                (total_clis_failed == 0 ? 'Concluido sem erros' : 'Concluido com erros') +
                ' (' + durationStr + ')');
            mail.setPlainTextBody(summary +
                (error_log.isEmpty() ? '' :
                    '\n\nPrimeiros erros:\n' +
                    String.join(firstN(error_log, 20), '\n')));
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Email de notificacao falhou: ' + ex.getMessage());
        }
    }

    private static List<String> firstN(List<String> src, Integer n) {
        List<String> result = new List<String>();
        Integer limitt = Math.min(src.size(), n);
        for (Integer i = 0; i < limitt; i++) {
            result.add(src[i]);
        }
        return result;
    }
}