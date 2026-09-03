public with sharing class PMC_SendDealerLocatorHttp {

    // ====== Tipos de I/O ======
    public class Request {
        @InvocableVariable(required=true) public String body;
        @InvocableVariable public String path;
        @InvocableVariable public String method;
        @InvocableVariable public String contentType;
        @InvocableVariable public Id accountId;
        @InvocableVariable public String secret;
    }
    public class Response {
        @InvocableVariable public Integer statusCode;
        @InvocableVariable public String  responseBody;
        @InvocableVariable public String  errorMessage;
    }

    // ====== Apoio ======
    private class Batch {
        String method, contentType, endpoint, secret, path;
        List<String> bodies = new List<String>();
        List<Integer> idxs  = new List<Integer>();
    }

    private static final Integer MAX_ITEMS_PER_CALL = 100;
    private static final String REQUIRED_RT_NAME = 'Retailer';
    private static final Set<String> sentKeys = new Set<String>();

    // ====== ENTRYPOINT ======
    @InvocableMethod
    public static List<Response> send(List<Request> requests) {
        if (requests == null || requests.isEmpty()) return new List<Response>();

        List<Response> out = new List<Response>();
        for (Integer i = 0; i < requests.size(); i++) out.add(new Response());

        // Cache de RT.Name
        Set<Id> accIds = new Set<Id>();
        for (Request r : requests) if (r != null && r.accountId != null) accIds.add(r.accountId);

        Map<Id, String> accRtName = new Map<Id, String>();
        if (!accIds.isEmpty()) {
            for (Account a : [SELECT Id, RecordType.Name FROM Account WHERE Id IN :accIds]) {
                accRtName.put(a.Id, a.RecordType.Name);
            }
        }

        Map<String,List<Batch>> groups = new Map<String,List<Batch>>();
        List<PMC_IntegrationLog__c> logsToInsert = new List<PMC_IntegrationLog__c>();

        for (Integer i = 0; i < requests.size(); i++) {
            Request r = requests[i];
            Response res = out[i];

            try {
                if (r == null) {
                    res.statusCode = 204;
                    res.responseBody = 'Skipped: null request';
                    continue;
                }

                final String method      = String.isBlank(r.method) ? 'POST' : r.method.trim().toUpperCase();
                final String contentType = String.isBlank(r.contentType) ? 'application/json' : r.contentType.trim();
                final String path        = String.isBlank(r.path) ? '' : r.path.trim();
                final String endpoint    = 'callout:DealerLocator' + (path == '/' ? '' : path);
                final String secret      = String.isBlank(r.secret) ? null : r.secret;
                final String dedupeKey   = (r.accountId == null ? 'NA' : String.valueOf(r.accountId)) + '|' + path;

                // Filtro por Retailer
                if (r.accountId != null) {
                    String rtName = accRtName.get(r.accountId);
                    if (rtName == null || rtName != REQUIRED_RT_NAME) {
                        res.statusCode = 204;
                        res.responseBody = 'Skipped (non-Retailer or missing RT).';
                        continue;
                    }
                }

                // Dedupe
                if (sentKeys.contains(dedupeKey)) {
                    res.statusCode = 204;
                    res.responseBody = 'Skipped (duplicate in same transaction)';
                    continue;
                }
                sentKeys.add(dedupeKey);

                // Agrupar
                String key = method + '|' + contentType + '|' + path + '|' + (secret == null ? '' : secret);
                if (!groups.containsKey(key)) groups.put(key, new List<Batch>());
                List<Batch> listForKey = groups.get(key);

                Batch b;
                if (!listForKey.isEmpty() && listForKey.get(listForKey.size()-1).bodies.size() < MAX_ITEMS_PER_CALL) {
                    b = listForKey.get(listForKey.size()-1);
                } else {
                    b = new Batch();
                    b.method = method; b.contentType = contentType; b.endpoint = endpoint; b.secret = secret; b.path = path;
                    listForKey.add(b);
                }

                String cleaned = (r.body == null) ? '{}' : sanitizeBody(r.body);
                b.bodies.add(cleaned);
                b.idxs.add(i);

            } catch (Exception e) {
                res.errorMessage = e.getMessage();
                logsToInsert.add(makeLog(r, null, null, r == null ? null : r.body, null, e.getMessage(), false));
            }
        }

        // ====== Callouts ======
        List<Batch> allBatches = new List<Batch>();
        for (List<Batch> lb : groups.values()) allBatches.addAll(lb);

        Integer available = Limits.getLimitCallouts() - Limits.getCallouts();
        Integer canRunNow = Math.max(0, available);

        List<Batch> now = new List<Batch>();
        List<Batch> later = new List<Batch>();
        for (Integer i = 0; i < allBatches.size(); i++) {
            if (i < canRunNow) now.add(allBatches[i]);
            else later.add(allBatches[i]);
        }

        if (!now.isEmpty()) doSend(now, requests, out, logsToInsert);
        if (!later.isEmpty()) System.enqueueJob(new QueueableSender(later, requests, out));

        // Insere logs apenas se válidos
        if (!logsToInsert.isEmpty()) {
            try {
                List<PMC_IntegrationLog__c> filtered = new List<PMC_IntegrationLog__c>();
                for (PMC_IntegrationLog__c l : logsToInsert) {
                    if (l.Success__c == true && l.StatusCode__c != 204 && l.StatusCode__c != null) {
                        filtered.add(l);
                    }
                }
                if (!filtered.isEmpty()) insert filtered;
            } catch (Exception ignore) {}
        }

        return out;
    }

    // ====== Execução dos callouts ======
    private static void doSend(List<Batch> batches, List<Request> requests, List<Response> out, List<PMC_IntegrationLog__c> extraLogs) {
        List<PMC_IntegrationLog__c> logs = new List<PMC_IntegrationLog__c>();

        for (Batch b : batches) {
            if (b.bodies.isEmpty()) continue;

            String payload = '[' + String.join(b.bodies, ',') + ']';

            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(b.endpoint);
                req.setMethod(b.method);
                req.setHeader('Content-Type', b.contentType);
                req.setHeader('Accept', 'application/json');
                if (b.secret != null) req.setHeader('X-SFDL-Secret', b.secret);
                req.setTimeout(20000);
                req.setBody(payload);

                Http http = new Http();
                HttpResponse hr = http.send(req);

                Integer sc = hr.getStatusCode();
                String rb = '(endpoint=' + b.endpoint + ', batch=' + b.bodies.size() + ') ' + hr.getBody();

                for (Integer k = 0; k < b.idxs.size(); k++) {
                    Integer idx = b.idxs[k];
                    Request r = requests[idx];
                    Response rr = out[idx];
                    rr.statusCode = sc; rr.responseBody = rb; rr.errorMessage = null;

                    String perItemBody = '[' + b.bodies[k] + ']';
                    PMC_IntegrationLog__c log = makeLog(r, b.method, b.path, perItemBody, sc, rb, (sc != null && sc < 400));

                    // ✅ Grava apenas se Success__c = true, StatusCode != 204 e != null
                    if (log != null && log.Success__c == true && log.StatusCode__c != null && log.StatusCode__c != 204) {
                        logs.add(log);
                    }
                }
            } catch (Exception e) {
                for (Integer k = 0; k < b.idxs.size(); k++) {
                    Integer idx = b.idxs[k];
                    Request r = requests[idx];
                    Response rr = out[idx];
                    rr.errorMessage = e.getMessage();
                    makeLog(r, b.method, b.path, '[' + b.bodies[k] + ']', null, e.getMessage(), false);
                }
            }
        }

        if (extraLogs != null) logs.addAll(extraLogs);

        // Filtra logs válidos novamente
        List<PMC_IntegrationLog__c> validLogs = new List<PMC_IntegrationLog__c>();
        for (PMC_IntegrationLog__c l : logs) {
            if (l != null && l.Success__c == true && l.StatusCode__c != null && l.StatusCode__c != 204) {
                validLogs.add(l);
            }
        }

        if (!validLogs.isEmpty()) {
            try { insert validLogs; } catch (Exception ignore) {}
        }

        if (extraLogs != null) extraLogs.clear();
    }

    // ====== Queueable ======
    public class QueueableSender implements Queueable, Database.AllowsCallouts {
        private List<Batch> toSend;
        private List<Request> reqs;
        private List<Response> outs;
        public QueueableSender(List<Batch> b, List<Request> r, List<Response> o) {
            toSend = b; reqs = r; outs = o;
        }
        public void execute(QueueableContext qc) {
            doSend(toSend, reqs, outs, new List<PMC_IntegrationLog__c>());
        }
    }

    // ====== Helpers ======
    private static PMC_IntegrationLog__c makeLog(Request r, String method, String path, String requestBody,
                                                 Integer status, String responseOrFault, Boolean success) {
        PMC_IntegrationLog__c log = new PMC_IntegrationLog__c();
        log.AccountId__c   = (r == null ? null : r.accountId);
        log.Method__c      = (method == null ? 'POST' : method);
        log.Path__c        = (path == null ? '/v1/account' : path);
        log.RequestBody__c = (requestBody == null ? '(built in class)' : requestBody);
        if (status != null) log.StatusCode__c = status;
        log.Success__c     = (success == null ? false : success);
        if (success == true)  log.ResponseBody__c = responseOrFault;
        else                  log.FaultMessage__c = responseOrFault;
        return log;
    }

    private static String sanitizeBody(String body) {
        String cleaned = body == null ? null : body.replace('\r',' ').replace('\n',' ');
        if (cleaned == null) return null;
        cleaned = cleaned.replaceAll('[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]', ' ');
        return cleaned;
    }
}