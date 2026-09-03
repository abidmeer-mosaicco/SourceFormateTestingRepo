public class OrderCart_OrderCreateActionClass implements Queueable, Database.AllowsCallouts{
    public List<Order> lstOrders;
    public List<Id> lstIds;
    public Integer weight;
    public Integer baseWeight;
    public Integer startIndex;

    static final String STRING_INTERFACE = 'SAPSalesOrderCreate';
    static final String STRING_NAMEDCREDENTIALS = 'callout:PMC_CPQ_NamedCredential';
    static final String STRING_METHOD = 'POST';

    // Keep original constructor for backward compatibility
    public OrderCart_OrderCreateActionClass(List<Order> lstOrders, List<Id> lstIds)
    {
        this.lstOrders = lstOrders;
        this.lstIds = lstIds;
        this.weight = null;
    }

    // New constructor allowing a weight value to be sent with the payload
    public OrderCart_OrderCreateActionClass(List<Order> lstOrders, List<Id> lstIds, Integer weight)
    {
        this.lstOrders = lstOrders;
        this.lstIds = lstIds;
        this.weight = weight;
    }

    // New constructor to start a chained execution from the first element of lstOrders
    public OrderCart_OrderCreateActionClass(List<Order> lstOrders, Integer startIndex)
    {
        this.lstOrders = lstOrders;
        this.lstIds = null;
        this.weight = null;
        this.startIndex = startIndex;
    }

    // New constructor to start a chained execution with a baseWeight to avoid collisions across batches
    public OrderCart_OrderCreateActionClass(List<Order> lstOrders, Integer startIndex, Integer baseWeight)
    {
        this.lstOrders = lstOrders;
        this.lstIds = null;
        this.weight = null;
        this.startIndex = startIndex;
        this.baseWeight = baseWeight;
    }

    public static void postInfoToCPI(List<Order> lstOrders){
        // Start a chained queueable: enqueue a single job carrying the full list.
        // That job will process the first Order and enqueue the next one upon completion.
        // To avoid weight collisions across different batches (especially when multiple
        // submissions target the same contract), compute a baseWeight per batch and
        // add the sequential startIndex to it when sending each individual Order.
        if (lstOrders == null || lstOrders.isEmpty()) return;
        Integer base = 0;
        try {
            // Use the last 6 digits of epoch millis as a compact base to reduce collision risk
            String s = String.valueOf(DateTime.now().getTime());
            Integer l = s.length();
            String last6 = s.substring(Math.max(0, l - 6));
            base = Integer.valueOf(last6);
            if (base == 0) base = 1;
        } catch (Exception ex) {
            base = 1;
        }
        System.enqueueJob(new OrderCart_OrderCreateActionClass(lstOrders, 1, base));
    }

    public void execute(QueueableContext context){
        PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(STRING_INTERFACE);
        String strEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
        String strCalloutEndpoint = STRING_NAMEDCREDENTIALS+strEndpoint;

        // If this instance was created as a chained executor (lstOrders + startIndex set),
        // process only the first Order in the list and enqueue the remainder on success.
        if (this.lstOrders != null && !this.lstOrders.isEmpty() && this.startIndex != null) {
            Integer seqIndex = (this.startIndex != null) ? this.startIndex : 1;
            Integer currentWeight = ((this.baseWeight != null) ? this.baseWeight : 0) + seqIndex;
            // Process first order
            Order first = this.lstOrders[0];
            List<Order> singleOrder = new List<Order>{ first };
            List<Id> singleId = new List<Id>{ first.Id };

            String payload = OrderCart_CPIRemoteCalloutUtilityClass.createMinimalPayload(singleId, currentWeight);
            try { System.debug('OrderCart_OrderCreateActionClass - chained callout payload: ' + payload + ' weight: ' + currentWeight + ' orderId: ' + first.Id); } catch (Exception e) {}
            HttpResponse response = OrderCart_CPIRemoteCalloutUtilityClass.sendCalloutRequest(STRING_METHOD, strCalloutEndpoint, payload);

            Boolean processed = false;
            if (response != null) {
                // try to parse response for the single order; if parse fails, record error for this order
                try {
                    OrderCart_OrderIntegrationClass.parseJSONOrderInterface(singleOrder, response, singleId);
                    processed = true;
                } catch (Exception pe) {
                    // record parse error on the order/orderlines
                    OrderCart_OrderIntegrationClass.updateOrderandOrderLineErrorExceptionStatusMsg(singleOrder, singleId, 'ParseError: ' + pe.getMessage());
                    try { System.debug('OrderCart_OrderCreateActionClass - parse exception for order ' + String.valueOf(first.Id) + ': ' + pe.getMessage()); } catch (Exception e) {}
                }
            } else {
                // Callout failed: record error for this order (but continue the chain)
                OrderCart_OrderIntegrationClass.updateOrderandOrderLineErrorExceptionStatusMsg(singleOrder, singleId, OrderCart_CPIRemoteCalloutUtilityClass.strExceptionMsg);
                try { System.debug('OrderCart_OrderCreateActionClass - callout failed for order ' + String.valueOf(first.Id) + ': ' + OrderCart_CPIRemoteCalloutUtilityClass.strExceptionMsg); } catch (Exception e) {}
            }

            // Special-case: if response contained SAP 'currently being processed' message for this order,
            // re-enqueue this single order as a separate job (with new baseWeight) so it can be retried later
            Boolean requeuedForProcessing = false;
            try {
                if (response != null) {
                    String respBody = response.getBody();
                    if (respBody != null && respBody.toLowerCase().contains('is currently being processed')) {
                        // compute a fresh base for the retry
                        Integer retryBase = 1;
                        try {
                            String s2 = String.valueOf(DateTime.now().getTime());
                            Integer l2 = s2.length();
                            String last6_2 = s2.substring(Math.max(0, l2 - 6));
                            retryBase = Integer.valueOf(last6_2);
                            if (retryBase == 0) retryBase = 1;
                        } catch (Exception exRetry) { retryBase = 1; }
                        try { System.debug('OrderCart_OrderCreateActionClass - SAP busy detected for order ' + String.valueOf(first.Id) + '. Re-enqueueing single order for retry with base ' + retryBase); } catch (Exception e) {}
                        System.enqueueJob(new OrderCart_OrderCreateActionClass(singleOrder, 1, retryBase));
                        requeuedForProcessing = true;
                    }
                }
            } catch (Exception exCheck) {
                try { System.debug('OrderCart_OrderCreateActionClass - error while checking response body for retry: ' + exCheck.getMessage()); } catch (Exception e) {}
            }

            // Enqueue next job for remaining orders regardless of success/failure of the current one
            if (this.lstOrders.size() > 1) {
                List<Order> remaining = new List<Order>();
                for (Integer i = 1; i < this.lstOrders.size(); i++) remaining.add(this.lstOrders[i]);
                Integer nextSeqIndex = seqIndex + 1;
                System.enqueueJob(new OrderCart_OrderCreateActionClass(remaining, nextSeqIndex, this.baseWeight));
            }

            return;
        }

        // Fallback: legacy behavior when called with single-order payload (lstIds provided)
        String strSerializedBody;
        if (this.weight != null) {
            strSerializedBody = OrderCart_CPIRemoteCalloutUtilityClass.createMinimalPayload(lstIds, this.weight);
        } else {
            strSerializedBody = OrderCart_CPIRemoteCalloutUtilityClass.createMinimalPayload(lstIds);
        }
        try { System.debug('OrderCart_OrderCreateActionClass - callout payload: ' + strSerializedBody + ' endpoint: ' + strCalloutEndpoint + ' orderIds: ' + String.valueOf(lstIds) + ' weight: ' + String.valueOf(this.weight)); } catch (Exception ex) {}
        HttpResponse response = OrderCart_CPIRemoteCalloutUtilityClass.sendCalloutRequest(STRING_METHOD, strCalloutEndpoint, strSerializedBody);

        if(response != null){
            OrderCart_OrderIntegrationClass.parseJSONOrderInterface(lstOrders,response,lstIds);
        } else {
            // Failure: set error status/messages on Order and OrderItem, but do not re-enqueue.
            OrderCart_OrderIntegrationClass.updateOrderandOrderLineErrorExceptionStatusMsg(lstOrders, lstIds, OrderCart_CPIRemoteCalloutUtilityClass.strExceptionMsg);
        }
    }
}