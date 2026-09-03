public with sharing class QuoteAccountSyncService {

    public class SyncRequest {
        @AuraEnabled public Id     opportunityId;
        @AuraEnabled public Id     accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountPhone;
        @AuraEnabled public Id     quoteId;
        @AuraEnabled public String quoteName;
        @AuraEnabled public Date   quoteExpiry;
      
    }

    public class SyncResult {
        @AuraEnabled public Id           accountId;
        @AuraEnabled public Id           quoteId;
        @AuraEnabled public Boolean      success;
        @AuraEnabled public String       message;
        @AuraEnabled public List<String> errors = new List<String>();
    }

    @AuraEnabled
    public static SyncResult syncQuoteAndAccount(SyncRequest req) {
        if (req == null) throw new AuraHandledException('Request is required.');

        Savepoint sp = Database.setSavepoint();
        SyncResult out = new SyncResult();

        try {
            // -------- 1) Resolve Account (reuse > insert) --------
            Account acc = null;
            Opportunity oppRef = null;
            Id oppAccountId = null;

            // If Opportunity provided, load once and capture its Account
            if (req.opportunityId != null) {
                List<Opportunity> opps = [
                    SELECT Id, AccountId
                    FROM Opportunity
                    WHERE Id = :req.opportunityId
                    LIMIT 1
                ];
                if (!opps.isEmpty()) {
                    oppRef = opps[0];
                    oppAccountId = oppRef.AccountId;
                }
            }

            if (req.accountId != null) {
                // 1a) Explicit AccountId
                acc = [
                    SELECT Id, Name, Phone
                    FROM Account
                    WHERE Id = :req.accountId
                    LIMIT 1
                ];
                // gentle updates
                if (req.accountPhone != null && (acc.Phone == null || acc.Phone != req.accountPhone)) {
                    acc.Phone = req.accountPhone;
                }
                if (req.accountName != null && acc.Name != req.accountName) {
                    acc.Name = req.accountName;
                }
                update acc;

            } else if (oppAccountId != null) {
                // 1b) Reuse the Opportunity's Account
                acc = [
                    SELECT Id, Name, Phone
                    FROM Account
                    WHERE Id = :oppAccountId
                    LIMIT 1
                ];
                Boolean needsUpdate = false;
                if (!String.isBlank(req.accountPhone) && String.isBlank(acc.Phone)) {
                    acc.Phone = req.accountPhone; needsUpdate = true;
                }
                // Avoid renaming existing accounts here unless business wants that
                if (needsUpdate) update acc;

            } else {
                // 1c) Find-or-insert by Name (+Phone).
                String nameNorm  = (req.accountName  == null) ? null : req.accountName.trim();
                String phoneNorm = (req.accountPhone == null) ? null : req.accountPhone.trim();

                Account existing = findExistingAccountByNamePhone(nameNorm, phoneNorm);

                if (existing != null) {
                    acc = existing;
                    // Top-up blank phone if provided
                    if (!String.isBlank(phoneNorm) && String.isBlank(acc.Phone)) {
                        acc.Phone = phoneNorm;
                        try { update acc; } catch (Exception ignore) {}
                    }
                } else {
                    // Attempt a normal insert first
                    Account toInsert = new Account(
                        Name  = String.isBlank(nameNorm) ? 'New Account' : nameNorm,
                        Phone = phoneNorm
                    );

                    // Use partial DML to inspect duplicate rule failures safely
                    Database.SaveResult sr = Database.insert(toInsert, false);

                    if (sr.isSuccess()) {
                        acc = toInsert; // inserted successfully
                    } else {
                        // Look for DUPLICATES_DETECTED and try to reuse a matched Account
                        Database.Error e0 = sr.getErrors()[0];
                        if (e0.getStatusCode() == StatusCode.DUPLICATES_DETECTED) {
                            Account fallback = findExistingAccountByNamePhone(nameNorm, phoneNorm);
                            if (fallback != null) {
                                acc = fallback; // reuse
                            } else {
                                Database.rollback(sp);
                                SyncResult err = new SyncResult();
                                err.success = false;
                                err.message = 'Account insert blocked by Duplicate Rule and no reusable Account found.';
                                err.errors.add(e0.getStatusCode() + ': ' + e0.getMessage());
                                return err;
                            }
                        } else {
                            // Non-duplicate error—surface it
                            Database.rollback(sp);
                            SyncResult err = new SyncResult();
                            err.success = false;
                            err.message = 'Account insert failed.';
                            err.errors.add(e0.getStatusCode() + ': ' + e0.getMessage());
                            return err;
                        }
                    }
                }
            }
            out.accountId = acc.Id;

            // -------- 2) Ensure an Opportunity to attach the Quote --------
            if (oppRef == null) {
                if (req.opportunityId != null) {
                    List<Opportunity> qs = [
                        SELECT Id, AccountId
                        FROM Opportunity
                        WHERE Id = :req.opportunityId
                        LIMIT 1
                    ];
                    if (!qs.isEmpty()) oppRef = qs[0];
                } else {
                    oppRef = new Opportunity(
                        Name      = String.isBlank(req.accountName) ? 'Quote Sync Opp' : req.accountName,
                        StageName = 'Prospecting',
                        CloseDate = Date.today().addDays(30),
                        AccountId = acc.Id
                    );
                    insert oppRef;
                }
            }
            // If business approves moving Opp to the resolved Account, uncomment:
            // if (oppRef != null && oppRef.AccountId != acc.Id) { oppRef.AccountId = acc.Id; update oppRef; }

            // -------- 3) Upsert Quote (NEVER set Quote.AccountId; set OpportunityId) --------
            Quote q;
            try {
                if (req.quoteId != null) {
                    List<Quote> qs = [
                        SELECT Id, Name, OpportunityId, ExpirationDate
                        FROM Quote
                        WHERE Id = :req.quoteId
                        LIMIT 1
                    ];
                    if (qs.isEmpty()) {
                        throw new AuraHandledException('Quote not found for provided quoteId: ' + String.valueOf(req.quoteId));
                    }
                    q = qs[0];

                    if (req.quoteName   != null) q.Name           = req.quoteName;
                    if (req.quoteExpiry != null) q.ExpirationDate = req.quoteExpiry;
                    if (oppRef != null)          q.OpportunityId  = oppRef.Id;

                    update q;

                } else {
                    q = new Quote(
                        Name           = String.isBlank(req.quoteName) ? 'New Quote' : req.quoteName,
                        OpportunityId  = (oppRef != null ? oppRef.Id : null),
                        ExpirationDate = req.quoteExpiry
                    );
                    insert q;
                }
                out.quoteId = q.Id;

            } catch (DmlException dmx2) {
                SyncResult err = new SyncResult();
                err.success = false;
                err.message = 'Quote DML failed.';
                err.errors.add(dmx2.getMessage());
                if (dmx2.getNumDml() > 0 && dmx2.getDmlFieldNames(0) != null && !dmx2.getDmlFieldNames(0).isEmpty()) {
                    err.errors.add('Field: ' + String.valueOf(dmx2.getDmlFieldNames(0)[0]));
                }
                return err;

            } catch (Exception ex2) {
                SyncResult err = new SyncResult();
                err.success = false;
                err.message = 'Unexpected error during Quote upsert.';
                err.errors.add(ex2.getMessage());
                return err;
            }

            // --- Success ---
            out.success = true;
            out.message = 'Account and Quote synced (Account reused/updated when applicable).';
            return out;

        } catch (DmlException e) {
            Database.rollback(sp);
            out.success = false;
            out.message = 'Sync failed.';
            out.errors.add(e.getMessage());
            return out;

        } catch (Exception e) {
            Database.rollback(sp);
            out.success = false;
            out.message = 'Unexpected error.';
            out.errors.add(e.getMessage());
            return out;
        }
    }

    // -----------------------
    // Helpers (no DML here)
    // -----------------------

    // Find an existing Account by Name (+ optional Phone) — best-effort
    private static Account findExistingAccountByNamePhone(String nameNorm, String phoneRaw) {
        if (String.isBlank(nameNorm)) return null;

        List<Account> rows = [
            SELECT Id, Name, Phone
            FROM Account
            WHERE Name = :nameNorm
            ORDER BY LastModifiedDate DESC
            LIMIT 20
        ];
        if (rows.isEmpty()) return null;

        String phoneDigits = digitsOnly(phoneRaw);
        if (!String.isBlank(phoneDigits)) {
            for (Account a : rows) {
                String ap = digitsOnly(a.Phone);
                if (ap == phoneDigits) return a;
            }
        }
        // Fallback: return most recent name match
        return rows[0];
    }

    // Keep digits only from a phone-like string
    private static String digitsOnly(String v) {
        if (String.isBlank(v)) return null;
        String out = '';
        for (Integer i = 0; i < v.length(); i++) {
            String ch = v.substring(i, i+1);
            if (ch >= '0' && ch <= '9') out += ch;
        }
        return String.isBlank(out) ? null : out;
    }
}