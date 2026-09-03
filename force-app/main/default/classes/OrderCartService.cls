// Service to create OrderCart__c and OrderCartItem__c from LWC payload
public without sharing class OrderCartService {

    // DTO para retorno da criação
    public class OrderCartCreateResult {
        @AuraEnabled public Id cartId;
        @AuraEnabled public List<Id> itemIds;
    }

    @AuraEnabled
    public static List<OrderCartCreateResult> createOrderCarts(String cartsJson) {
        if (String.isBlank(cartsJson)) return new List<OrderCartCreateResult>();

        List<Object> cartsRaw = (List<Object>) JSON.deserializeUntyped(cartsJson);

        List<SObject> cartsToInsert = new List<SObject>();
        List<List<SObject>> itemsByCart = new List<List<SObject>>();
        Set<Id> quoteLineIds = new Set<Id>();

        for (Object cObj : cartsRaw) {
            Map<String, Object> cMap = (Map<String, Object>) cObj;

            Boolean oneOrderPerTruck = false;
            Integer trucks = 0;

            if (cMap.containsKey('oneOrderPerTruck') && cMap.get('oneOrderPerTruck') != null) {
                oneOrderPerTruck = Boolean.valueOf(String.valueOf(cMap.get('oneOrderPerTruck')));
            }

            if (cMap.containsKey('trucks') && cMap.get('trucks') != null) {
                try { trucks = Integer.valueOf(String.valueOf(cMap.get('trucks'))); } catch (Exception ex) { trucks = 0; }
            }

            // Se oneOrderPerTruck == true: criar N OrderCart__c (N = trucks), cada um com os items do payload replicados
            if (oneOrderPerTruck && trucks > 0) {
                // Prepara lista de items do payload (pode ser vazia)
                List<Map<String, Object>> payloadItems = new List<Map<String, Object>>();
                if (cMap.containsKey('items') && cMap.get('items') instanceof List<Object>) {
                    for (Object itObj : (List<Object>) cMap.get('items')) {
                        payloadItems.add((Map<String, Object>) itObj);
                    }
                }

                for (Integer t = 0; t < trucks; t++) {
                    SObject oc = Schema.getGlobalDescribe().get('OrderCart__c').newSObject();

                    if (cMap.containsKey('contractItem') && cMap.get('contractItem') != null) oc.put('Contract_Item__c', String.valueOf(cMap.get('contractItem')));
                        if (cMap.containsKey('contractId') && cMap.get('contractId') != null) {
                        String cid = String.valueOf(cMap.get('contractId'));
                        if (!String.isBlank(cid)) {
                            try { oc.put('Contract__c', Id.valueOf(cid)); } catch (Exception ex) { /* IGNORED invalid id */ }
                        }
                    }

                    // Accept explicit account Id from payload (modal passes selectedRecord.Account into `account` prop)
                    if (cMap.containsKey('account') && cMap.get('account') != null) {
                        try {
                            Id acctId = Id.valueOf(String.valueOf(cMap.get('account')));
                            oc.put('Account__c', acctId);
                            // Also persist PMC_CPQ_SoldToAccount__c on the cart with same value
                            try { oc.put('PMC_CPQ_SoldToAccount__c', acctId); } catch (Exception e) { /* ignore if field missing */ }
                        } catch (Exception ex) { /* IGNORED invalid id */ }
                    }

                    // Accept explicit quote Id from payload and store as text on OrderCart__c.Quote__c
                    if (cMap.containsKey('quote') && cMap.get('quote') != null) {
                        try { oc.put('Quote__c', String.valueOf(cMap.get('quote'))); } catch (Exception ex) { /* IGNORED */ }
                    }

                    // Accept explicit opportunity Id from payload and store on cart (SBQQ_Opportunity2__c)
                    if (cMap.containsKey('opportunity') && cMap.get('opportunity') != null) {
                        try { oc.put('SBQQ_Opportunity2__c', String.valueOf(cMap.get('opportunity'))); } catch (Exception ex) { /* ignore if field missing */ }
                    }

                    oc.put('Status__c', 'Active');

                    // Persist Purchase Order Date (startDate) from payload into PMC_CPQ_PurchaseOrderDate__c on OrderCart
                    if (cMap.containsKey('startDate') && cMap.get('startDate') != null) {
                        try { oc.put('PMC_CPQ_PurchaseOrderDate__c', Date.valueOf(String.valueOf(cMap.get('startDate')))); } catch (Exception ex) { /* ignore bad format or missing field */ }
                    }

                    // Propagate PO from payload into OrderCart.PMC_CPQ_PO__c when provided
                    if (cMap.containsKey('poNumber') && cMap.get('poNumber') != null) {
                        try { oc.put('PMC_CPQ_PO__c', String.valueOf(cMap.get('poNumber'))); } catch (Exception ex) { /* ignore if field missing */ }
                    }

                    // Persist Payment Terms from payload into SBQQ_PaymentTerm__c on OrderCart
                    if (cMap.containsKey('paymentTerms') && cMap.get('paymentTerms') != null) {
                        try { oc.put('SBQQ_PaymentTerm__c', String.valueOf(cMap.get('paymentTerms'))); } catch (Exception ex) { /* ignore if field missing */ }
                    }

                    if (cMap.containsKey('contractDescription') && cMap.get('contractDescription') != null) oc.put('Description__c', String.valueOf(cMap.get('contractDescription')));
                    if (cMap.containsKey('itemQtyAvailable') && cMap.get('itemQtyAvailable') != null) {
                        try { oc.put('Item_Qty_Available__c', Decimal.valueOf(String.valueOf(cMap.get('itemQtyAvailable')))); } catch (Exception ex) { /* IGNORED bad format */ }
                    }

                    cartsToInsert.add(oc);

                    // Para cada cart criado, copiamos todos os items do payload (cada cart terá os mesmos items)
                    List<SObject> singleItemList = new List<SObject>();

                    for (Map<String, Object> itMap : payloadItems) {
                        SObject oci = Schema.getGlobalDescribe().get('OrderCartItem__c').newSObject();
                        if (itMap.containsKey('reqShipmentDate') && itMap.get('reqShipmentDate') != null) {
                            try { oci.put('ReqShipmentDate__c', Date.valueOf(String.valueOf(itMap.get('reqShipmentDate')))); } catch (Exception ex) { /* IGNORED */ }
                        }

                        if (itMap.containsKey('orderPoNumber') && itMap.get('orderPoNumber') != null) {
                            try { oci.put('OrderPoNumber__c', String.valueOf(itMap.get('orderPoNumber'))); } catch (Exception ex) { /* IGNORED */ }
                        }

                        // orderQty replicado para cada carga
                        if (itMap.containsKey('orderQty') && itMap.get('orderQty') != null) {
                            try { oci.put('OrderQty__c', Decimal.valueOf(String.valueOf(itMap.get('orderQty')))); } catch (Exception ex) { /* IGNORED */ }
                        }

                        if (itMap.containsKey('shipMethod') && itMap.get('shipMethod') != null) oci.put('Ship_Method__c', String.valueOf(itMap.get('shipMethod')));

                        // Map incoterm/shipMethod into OrderCartItem custom fields (oneOrderPerTruck branch)
                        if (itMap.containsKey('incoterm') && itMap.get('incoterm') != null) {
                            try { oci.put('PMC_CPQ_Incoterms__c', String.valueOf(itMap.get('incoterm'))); } catch (Exception ex) { /* ignore */ }
                        } else if (cMap.containsKey('incoterm') && cMap.get('incoterm') != null) {
                            try { oci.put('PMC_CPQ_Incoterms__c', String.valueOf(cMap.get('incoterm'))); } catch (Exception ex) { /* ignore */ }
                        }

                        if (itMap.containsKey('transportMode') && itMap.get('transportMode') != null) {
                            try { oci.put('PMC_CPQ_ModeofTransportation__c', String.valueOf(itMap.get('transportMode'))); } catch (Exception ex) { /* ignore */ }
                        }

                        if (itMap.containsKey('origin') && itMap.get('origin') != null) oci.put('Origin__c', String.valueOf(itMap.get('origin')));
                        if (itMap.containsKey('shipTo') && itMap.get('shipTo') != null) oci.put('Ship_To__c', String.valueOf(itMap.get('shipTo')));

                        // Persist human-readable ship-to label sent by the modal into ShipToDisplay__c when provided
                        try {
                            String shipToDisplayVal = null;
                            if (itMap.containsKey('shipToDisplay') && itMap.get('shipToDisplay') != null) shipToDisplayVal = String.valueOf(itMap.get('shipToDisplay'));
                            else if (itMap.containsKey('shipToLabel') && itMap.get('shipToLabel') != null) shipToDisplayVal = String.valueOf(itMap.get('shipToLabel'));
                            else if (itMap.containsKey('shipToName') && itMap.get('shipToName') != null) shipToDisplayVal = String.valueOf(itMap.get('shipToName'));
                            else if (cMap.containsKey('shipToLabel') && cMap.get('shipToLabel') != null) shipToDisplayVal = String.valueOf(cMap.get('shipToLabel'));
                            if (shipToDisplayVal != null) {
                                oci.put('ShipToDisplay__c', shipToDisplayVal);
                            }
                        } catch (Exception ex) { /* ignore if field missing or read-only */ }
                        if (itMap.containsKey('subscriptionId') && itMap.get('subscriptionId') != null) {
                            // Only persist as lookup Subscription__c when payload contains a valid Id
                            try {
                                Id sid = Id.valueOf(String.valueOf(itMap.get('subscriptionId')));
                                oci.put('Subscription__c', sid);
                            } catch (Exception ex) {
                                // invalid id format: per new requirement, do not persist as string field
                            }
                        }

                        // Persist quote line id (raw) into Quote_Line__c on the OrderCartItem when provided
                        if (itMap.containsKey('quoteLine') && itMap.get('quoteLine') != null) {
                            try {
                                Id qlId = Id.valueOf(String.valueOf(itMap.get('quoteLine')));
                                oci.put('Quote_Line__c', qlId);

                                quoteLineIds.add(qlId);
                            } catch (Exception ex) {
                                // invalid id format: IGNORED
                            }
                        }

                        if (itMap.containsKey('uom') && itMap.get('uom') != null) oci.put('UOM__c', String.valueOf(itMap.get('uom')));

                        // Persist product location and unit of measure from payload into OrderCartItem
                        if (itMap.containsKey('productLocation') && itMap.get('productLocation') != null) {
                            try { oci.put('PMC_CPQ_ProductLocation__c', String.valueOf(itMap.get('productLocation'))); } catch (Exception ex) { /* ignore if field missing */ }
                        } else if (cMap.containsKey('productLocation') && cMap.get('productLocation') != null) {
                            try { oci.put('PMC_CPQ_ProductLocation__c', String.valueOf(cMap.get('productLocation'))); } catch (Exception ex) { /* ignore */ }
                        }

                        if (itMap.containsKey('unitOfMeasure') && itMap.get('unitOfMeasure') != null) {
                            try { oci.put('PMC_CPQ_UnitOfMeasure__c', String.valueOf(itMap.get('unitOfMeasure'))); } catch (Exception ex) { /* ignore if field missing */ }
                        } else if (cMap.containsKey('unitOfMeasure') && cMap.get('unitOfMeasure') != null) {
                            try { oci.put('PMC_CPQ_UnitOfMeasure__c', String.valueOf(cMap.get('unitOfMeasure'))); } catch (Exception ex) { /* ignore */ }
                        }

                        // Persist advanceBilling/incoterm2/exchangeRate from payload into OrderCartItem custom fields
                        if (itMap.containsKey('advanceBilling') && itMap.get('advanceBilling') != null) {
                            try { oci.put('PMC_CPQ_DefaultBillingBlock__c', String.valueOf(itMap.get('advanceBilling'))); } catch (Exception ex) { /* ignore */ }
                        }

                        if (itMap.containsKey('incoterm2') && itMap.get('incoterm2') != null) {
                            try { oci.put('PMC_CPQ_Destination__c', String.valueOf(itMap.get('incoterm2'))); } catch (Exception ex) { /* ignore */ }
                        }

                        if (itMap.containsKey('exchangeRate') && itMap.get('exchangeRate') != null) {
                            try { oci.put('PMC_CPQ_ExchangeRate__c', String.valueOf(itMap.get('exchangeRate'))); } catch (Exception ex) { /* ignore */ }
                        }

                        singleItemList.add(oci);
                    }

                    itemsByCart.add(singleItemList);
                }
            } else {
                // comportamento atual: um OrderCart__c com os items do payload
                SObject oc = Schema.getGlobalDescribe().get('OrderCart__c').newSObject();
                if (cMap.containsKey('contractItem') && cMap.get('contractItem') != null) oc.put('Contract_Item__c', String.valueOf(cMap.get('contractItem')));
                if (cMap.containsKey('contractId') && cMap.get('contractId') != null) {
                    String cid = String.valueOf(cMap.get('contractId'));
                    if (!String.isBlank(cid)) {
                        try { oc.put('Contract__c', Id.valueOf(cid)); } catch (Exception ex) { /* IGNORED invalid id */ }
                    }
                }

                // Accept explicit account Id from payload (modal passes selectedRecord.Account into `account` prop)
                if (cMap.containsKey('account') && cMap.get('account') != null) {
                    try {
                        Id acctId = Id.valueOf(String.valueOf(cMap.get('account')));
                        oc.put('Account__c', acctId);
                        // Also persist PMC_CPQ_SoldToAccount__c on the cart with same value
                        try { oc.put('PMC_CPQ_SoldToAccount__c', acctId); } catch (Exception e) { /* ignore if field missing */ }
                    } catch (Exception ex) { /* IGNORED invalid id */ }
                }

                // Accept explicit quote Id from payload and store as text on OrderCart__c.Quote__c
                if (cMap.containsKey('quote') && cMap.get('quote') != null) {
                    try { oc.put('Quote__c', String.valueOf(cMap.get('quote'))); } catch (Exception ex) { /* IGNORED */ }
                }

                // Accept explicit opportunity Id from payload and store on cart (SBQQ_Opportunity2__c)
                if (cMap.containsKey('opportunity') && cMap.get('opportunity') != null) {
                    try { oc.put('SBQQ_Opportunity2__c', String.valueOf(cMap.get('opportunity'))); } catch (Exception ex) { /* ignore if field missing */ }
                }

                oc.put('Status__c', 'Active');

                // Propagate PO from payload into OrderCart.PMC_CPQ_PO__c when provided
                if (cMap.containsKey('poNumber') && cMap.get('poNumber') != null) {
                    try { oc.put('PMC_CPQ_PO__c', String.valueOf(cMap.get('poNumber'))); } catch (Exception ex) { /* ignore if field missing */ }
                }

                // Persist Payment Terms from payload into SBQQ_PaymentTerm__c on OrderCart
                if (cMap.containsKey('paymentTerms') && cMap.get('paymentTerms') != null) {
                    try { oc.put('SBQQ_PaymentTerm__c', String.valueOf(cMap.get('paymentTerms'))); } catch (Exception ex) { /* ignore if field missing */ }
                }

                // Persist Purchase Order Date (startDate) from payload into PMC_CPQ_PurchaseOrderDate__c on OrderCart
                if (cMap.containsKey('startDate') && cMap.get('startDate') != null) {
                    try { oc.put('PMC_CPQ_PurchaseOrderDate__c', Date.valueOf(String.valueOf(cMap.get('startDate')))); } catch (Exception ex) { /* ignore bad format or missing field */ }
                }

                if (cMap.containsKey('contractDescription') && cMap.get('contractDescription') != null) oc.put('Description__c', String.valueOf(cMap.get('contractDescription')));
                if (cMap.containsKey('itemQtyAvailable') && cMap.get('itemQtyAvailable') != null) {
                    try { oc.put('Item_Qty_Available__c', Decimal.valueOf(String.valueOf(cMap.get('itemQtyAvailable')))); } catch (Exception ex) { /* IGNORED bad format */ }
                }

                cartsToInsert.add(oc);

                List<SObject> itemsList = new List<SObject>();
                // build payload items as list of maps (may be empty)
                List<Map<String, Object>> payloadItems = new List<Map<String, Object>>();
                if (cMap.containsKey('items') && cMap.get('items') instanceof List<Object>) {
                    for (Object itObj : (List<Object>) cMap.get('items')) {
                        payloadItems.add((Map<String, Object>) itObj);
                    }
                }

                Integer effectiveTrucks = trucks;
                // If trucks is not set or zero, but payload contains items, use payload length
                if (effectiveTrucks == null || effectiveTrucks <= 0) {
                    effectiveTrucks = payloadItems.size();
                }

                // Ensure we create exactly effectiveTrucks items for this cart
                for (Integer idx = 0; idx < effectiveTrucks; idx++) {
                    Map<String, Object> itMap = null;
                    if (idx < payloadItems.size()) {
                        itMap = payloadItems[idx];
                    } else if (!payloadItems.isEmpty()) {
                        // replicate first item as template
                        itMap = payloadItems[0];
                    }

                    SObject oci = Schema.getGlobalDescribe().get('OrderCartItem__c').newSObject();

                    if (itMap != null) {
                        if (itMap.containsKey('reqShipmentDate') && itMap.get('reqShipmentDate') != null) {
                            try { oci.put('ReqShipmentDate__c', Date.valueOf(String.valueOf(itMap.get('reqShipmentDate')))); } catch (Exception ex) { /* IGNORED */ }
                        }

                        if (itMap.containsKey('orderPoNumber') && itMap.get('orderPoNumber') != null) {
                            try { oci.put('OrderPoNumber__c', String.valueOf(itMap.get('orderPoNumber'))); } catch (Exception ex) { /* IGNORED */ }
                        }

                        if (itMap.containsKey('orderQty') && itMap.get('orderQty') != null) {
                            try { oci.put('OrderQty__c', Decimal.valueOf(String.valueOf(itMap.get('orderQty')))); } catch (Exception ex) { /* IGNORED */ }
                        }

                        if (itMap.containsKey('shipMethod') && itMap.get('shipMethod') != null) oci.put('Ship_Method__c', String.valueOf(itMap.get('shipMethod')));

                        // Map incoterm/shipMethod/poNumber from payload into OrderCartItem fields
                        if (itMap.containsKey('incoterm') && itMap.get('incoterm') != null) {
                            try { oci.put('PMC_CPQ_Incoterms__c', String.valueOf(itMap.get('incoterm'))); } catch (Exception ex) { /* ignore */ }
                        } else if (cMap.containsKey('incoterm') && cMap.get('incoterm') != null) {
                            try { oci.put('PMC_CPQ_Incoterms__c', String.valueOf(cMap.get('incoterm'))); } catch (Exception ex) { /* ignore */ }
                        }

                        if (itMap.containsKey('transportMode') && itMap.get('transportMode') != null) {
                            try { oci.put('PMC_CPQ_ModeofTransportation__c', String.valueOf(itMap.get('transportMode'))); } catch (Exception ex) { /* ignore */ }
                        }

                        if (itMap.containsKey('orderPoNumber') && itMap.get('orderPoNumber') != null) {
                            try { oci.put('OrderPoNumber__c', String.valueOf(itMap.get('orderPoNumber'))); } catch (Exception ex) { /* IGNORED */ }
                        } else if (cMap.containsKey('poNumber') && cMap.get('poNumber') != null) {
                            try { oci.put('OrderPoNumber__c', String.valueOf(cMap.get('poNumber'))); } catch (Exception ex) { /* IGNORED */ }
                        }

                        // Map modal/incoterm and ship method into OrderCartItem custom fields when present
                        if (itMap.containsKey('incoterm') && itMap.get('incoterm') != null) {
                            try { oci.put('PMC_CPQ_Incoterms__c', String.valueOf(itMap.get('incoterm'))); } catch (Exception ex) { /* ignore if field missing */ }
                        } else if (cMap.containsKey('incoterm') && cMap.get('incoterm') != null) {
                            try { oci.put('PMC_CPQ_Incoterms__c', String.valueOf(cMap.get('incoterm'))); } catch (Exception ex) { /* ignore */ }
                        }

                        if (itMap.containsKey('origin') && itMap.get('origin') != null) oci.put('Origin__c', String.valueOf(itMap.get('origin')));
                        if (itMap.containsKey('shipTo') && itMap.get('shipTo') != null) oci.put('Ship_To__c', String.valueOf(itMap.get('shipTo')));

                        // Persist human-readable ship-to label sent by the modal into ShipToDisplay__c when provided
                        try {
                            String shipToDisplayVal = null;

                            if (itMap.containsKey('shipToDisplay') && itMap.get('shipToDisplay') != null) shipToDisplayVal = String.valueOf(itMap.get('shipToDisplay'));
                            else if (itMap.containsKey('shipToLabel') && itMap.get('shipToLabel') != null) shipToDisplayVal = String.valueOf(itMap.get('shipToLabel'));
                            else if (itMap.containsKey('shipToName') && itMap.get('shipToName') != null) shipToDisplayVal = String.valueOf(itMap.get('shipToName'));
                            else if (cMap.containsKey('shipToLabel') && cMap.get('shipToLabel') != null) shipToDisplayVal = String.valueOf(cMap.get('shipToLabel'));

                            if (shipToDisplayVal != null) {
                                oci.put('ShipToDisplay__c', shipToDisplayVal);
                            }
                        } catch (Exception ex) { /* ignore if field missing or read-only */ }

                        if (itMap.containsKey('subscriptionId') && itMap.get('subscriptionId') != null) {
                            try {
                                Id sid = Id.valueOf(String.valueOf(itMap.get('subscriptionId')));
                                oci.put('Subscription__c', sid);
                            } catch (Exception ex) {
                                // invalid id format: do not persist per requirement
                            }
                        }

                        // Persist quote line id (raw) into Quote_Line__c on the OrderCartItem when provided
                        if (itMap.containsKey('quoteLine') && itMap.get('quoteLine') != null) {
                            try {
                                Id qlId = Id.valueOf(String.valueOf(itMap.get('quoteLine')));
                                oci.put('Quote_Line__c', qlId);

                                quoteLineIds.add(qlId);
                            } catch (Exception ex) {
                                // invalid id format: IGNORED
                            }
                        }

                        if (itMap.containsKey('uom') && itMap.get('uom') != null) oci.put('UOM__c', String.valueOf(itMap.get('uom')));
                        // Persist advanceBilling/incoterm2/exchangeRate from payload into OrderCartItem custom fields
                        if (itMap.containsKey('advanceBilling') && itMap.get('advanceBilling') != null) {
                            try { oci.put('PMC_CPQ_DefaultBillingBlock__c', String.valueOf(itMap.get('advanceBilling'))); } catch (Exception ex) { /* ignore */ }
                        }

                        if (itMap.containsKey('incoterm2') && itMap.get('incoterm2') != null) {
                            try { oci.put('PMC_CPQ_Destination__c', String.valueOf(itMap.get('incoterm2'))); } catch (Exception ex) { /* ignore */ }
                        }

                        if (itMap.containsKey('exchangeRate') && itMap.get('exchangeRate') != null) {
                            try { oci.put('PMC_CPQ_ExchangeRate__c', String.valueOf(itMap.get('exchangeRate'))); } catch (Exception ex) { /* ignore */ }
                        }
                    }

                    itemsList.add(oci);
                }

                itemsByCart.add(itemsList);
            }
        }

        if (!cartsToInsert.isEmpty()) {
            insert cartsToInsert;

            Map<String, String> quoteLineIdShipToMap = new Map<String, String>();
            List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, PMC_CPQ_ShipTo__c FROM SBQQ__QuoteLine__c WHERE Id IN :quoteLineIds];

            System.debug('quoteLineIds:: ' + quoteLineIds);
            System.debug('quoteLines:: ' + quoteLines);

            for (SBQQ__QuoteLine__c qtLine : quoteLines) {
                quoteLineIdShipToMap.put(qtLine.Id, qtLine.PMC_CPQ_ShipTo__c);
                System.debug('qtLine.Id:: ' + qtLine.Id);
                System.debug('qtLine.PMC_CPQ_ShipTo__c:: ' + qtLine.PMC_CPQ_ShipTo__c);
            }

            List<SObject> itemsToInsert = new List<SObject>();
            for (Integer i = 0; i < cartsToInsert.size(); i++) {

                SObject insertedCart = cartsToInsert[i];
                Id parentId = (Id) insertedCart.get('Id');

                for (SObject oci : itemsByCart[i]) {
                    if (oci.get('Quote_Line__c') != null) {
                        String quoteLineId = (String) oci.get('Quote_Line__c');
                        String shipToId = quoteLineIdShipToMap.get(quoteLineId);
                        String incoterm = (String) oci.get('PMC_CPQ_Incoterms__c');
                        String mot = (String) oci.get('PMC_CPQ_ModeofTransportation__c');

                        System.debug('quoteLineId:: ' + quoteLineId);
                        System.debug('shipToId:: ' + shipToId);
                        System.debug('incoterm:: ' + incoterm);
                        System.debug('mot:: ' + mot);

                        if (mot.toUpperCase() != 'TRUCK') {
                            oci.put('Ship_To__c', shipToId);
                        }

                        if (mot.toUpperCase() == 'TRUCK') {
                            if (incoterm.toUpperCase() != 'FCA' && incoterm.toUpperCase() != 'FOB') oci.put('Ship_To__c', shipToId);
                        }
                    }

                    oci.put('OrderCart__c', parentId);
                    itemsToInsert.add(oci);
                }
            }

            if (!itemsToInsert.isEmpty()) insert itemsToInsert;

            // ---------- Post-insert: populate CPQ price/pricebook fields based on Quote/QuoteLine links ----------
            try {
                // Collect new cart Ids
                List<Id> newCartIds = new List<Id>();
                for (SObject cIns : cartsToInsert) {
                    try { if (cIns != null && cIns.get('Id') != null) newCartIds.add((Id) cIns.get('Id')); } catch (Exception e) { /* IGNORED */ }
                }

                if (!newCartIds.isEmpty()) {
                    List<OrderCartItem__c> createdItems = [SELECT Id, Quote_Line__c FROM OrderCartItem__c WHERE OrderCart__c IN :newCartIds AND Quote_Line__c != null];
                    Set<Id> qlIds = new Set<Id>();
                    for (OrderCartItem__c ci : createdItems) {
                        try { if (ci.Quote_Line__c != null) qlIds.add(ci.Quote_Line__c); } catch (Exception ex) { /* IGNORED */ }
                    }

                    Map<Id, SBQQ__QuoteLine__c> qlById = new Map<Id, SBQQ__QuoteLine__c>();
                    if (!qlIds.isEmpty()) {
                        for (SBQQ__QuoteLine__c ql : [SELECT Id, SBQQ__PricebookEntryId__c, PMC_CPQ_NetUnitPrice__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE Id IN :qlIds]) {
                            qlById.put(ql.Id, ql);
                        }
                    }

                    List<OrderCartItem__c> itemsToUpdate = new List<OrderCartItem__c>();
                    for (OrderCartItem__c ci : createdItems) {
                        try {
                            Id refQl = ci.Quote_Line__c;
                            if (refQl != null && qlById.containsKey(refQl)) {
                                SBQQ__QuoteLine__c ql = qlById.get(refQl);
                                OrderCartItem__c upd = new OrderCartItem__c(Id = ci.Id);
                                Boolean needs = false;
                                try {
                                    if (ql.SBQQ__PricebookEntryId__c != null) { upd.SBQQ_PricebookEntryId__c = ql.SBQQ__PricebookEntryId__c; needs = true; }
                                } catch (Exception e) { }
                                try {
                                    if (ql.get('PMC_CPQ_NetUnitPrice__c') != null) { upd.PMC_CPQ_NetUnitPrice__c = (Decimal) ql.get('PMC_CPQ_NetUnitPrice__c'); needs = true; }
                                } catch (Exception e) { }
                                try {
                                    if (ql.get('SBQQ__Product__c') != null) { upd.SBQQ_Product__c = (Id) ql.get('SBQQ__Product__c'); needs = true; }
                                } catch (Exception e) { }
                                if (needs) itemsToUpdate.add(upd);
                            }
                        } catch (Exception ex) { }
                    }
                    if (!itemsToUpdate.isEmpty()) update itemsToUpdate;

                    // 2) For OrderCart__c: populate SBQQ_PriceBook__c from linked SBQQ__Quote__c when Quote__c stores a valid Id
                    List<OrderCart__c> createdCartsWithQuote = [SELECT Id, Quote__c FROM OrderCart__c WHERE Id IN :newCartIds AND Quote__c != null];
                    Set<Id> quoteIds = new Set<Id>();
                    Map<Id, Id> cartToQuoteId = new Map<Id, Id>();
                    for (OrderCart__c oc : createdCartsWithQuote) {
                        try {
                            String qref = String.valueOf(oc.Quote__c);
                            if (!String.isBlank(qref)) {
                                try {
                                    Id qid = Id.valueOf(qref);
                                    quoteIds.add(qid);
                                    cartToQuoteId.put(oc.Id, qid);
                                } catch (Exception logEx) {
                                    // not an Id - ignore (Quote__c is free-text in some flows)
                                }
                            }
                        } catch (Exception ex) { /* ignore */ }
                    }

                    if (!quoteIds.isEmpty()) {
                        Map<Id, SBQQ__Quote__c> quoteById = new Map<Id, SBQQ__Quote__c>();
                        for (SBQQ__Quote__c q : [SELECT Id, SBQQ__PriceBook__c, CurrencyIsoCode FROM SBQQ__Quote__c WHERE Id IN :quoteIds]) quoteById.put(q.Id, q);

                        List<OrderCart__c> cartsToUpdate2 = new List<OrderCart__c>();
                        for (Id cartId : cartToQuoteId.keySet()) {
                            Id qid = cartToQuoteId.get(cartId);
                            if (qid != null && quoteById.containsKey(qid)) {
                                SBQQ__Quote__c q = quoteById.get(qid);
                                    try {
                                        OrderCart__c u = new OrderCart__c(Id = cartId);
                                        Boolean add = false;
                                        if (q.get('SBQQ__PriceBook__c') != null) {
                                            try { u.SBQQ_PriceBook__c = (Id) q.get('SBQQ__PriceBook__c'); add = true; } catch (Exception ex) { }
                                        }
                                        try { if (q.CurrencyIsoCode != null) { u.CurrencyIsoCode = q.CurrencyIsoCode; add = true; } } catch (Exception ex) { }
                                        if (add) cartsToUpdate2.add(u);
                                    } catch (Exception ex) { }
                            }
                        }
                        if (!cartsToUpdate2.isEmpty()) update cartsToUpdate2;
                    }
                }
            } catch (Exception outerEx) {
                // non-fatal: do not prevent create from returning; log for diagnostics
                try { System.debug('OrderCartService.createOrderCarts - post-insert CPQ populate failed: ' + outerEx); } catch (Exception e) { }
            }
        }

        // Montar retorno com cartId e itemIds por cart, preservando a ordem original
        List<OrderCartCreateResult> results = new List<OrderCartCreateResult>();
        for (Integer i = 0; i < cartsToInsert.size(); i++) {
            OrderCartCreateResult r = new OrderCartCreateResult();
            r.cartId = (Id) cartsToInsert[i].get('Id');
            List<Id> itemIds = new List<Id>();

            if (i < itemsByCart.size()) {
                for (SObject it : itemsByCart[i]) {
                    if (it != null && it.get('Id') != null) itemIds.add((Id) it.get('Id'));
                }
            }

            r.itemIds = itemIds;
            results.add(r);
        }
        return results;
    }

    @AuraEnabled
    public static Id updateOrderCartItem(String itemJson) {
        if (String.isBlank(itemJson)) return null;
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(itemJson);
        if (!data.containsKey('Id') || data.get('Id') == null) return null;

        Id itemId = Id.valueOf(String.valueOf(data.get('Id')));
        //GSMD-4906
         List<OrderCartItem__c> cartItems=new List<OrderCartItem__c>();
        OrderCart__c orderCartUpdate=new OrderCart__c();
       
      String orderId  = [SELECT Id, OrderCart__c,  OrderPoNumber__c FROM OrderCartItem__c WHERE id=: itemId].OrderCart__c;
     cartItems = [SELECT Id, OrderCart__c,  OrderPoNumber__c FROM OrderCartItem__c WHERE OrderCart__c=: orderId];
         orderCartUpdate = [SELECT Id,  PMC_CPQ_PO__c FROM OrderCart__c WHERE Id=:orderId ];
      
       

if(cartItems.size()==1)
{
    
        if (data.containsKey('orderNumber') && data.get('orderNumber') != null) {
            try {
                String orderPoNumber = String.valueOf(data.get('orderNumber'));
                if (orderPoNumber != null)  orderCartUpdate.PMC_CPQ_PO__c=orderPoNumber;
            } catch (Exception ex) { /* ignore bad format */ }
        }
  
}

        SObject toUpdate = Schema.getGlobalDescribe().get('OrderCartItem__c').newSObject();
        toUpdate.put('Id', itemId);

        if (data.containsKey('orderQty') && data.get('orderQty') != null) {
            try { toUpdate.put('OrderQty__c', Decimal.valueOf(String.valueOf(data.get('orderQty')))); } catch (Exception ex) { /* ignore bad format */ }
        }

        if (data.containsKey('orderNumber') && data.get('orderNumber') != null) {
            try {
                String orderPoNumber = String.valueOf(data.get('orderNumber'));
                if (orderPoNumber != null) toUpdate.put('OrderPoNumber__c', orderPoNumber);
            } catch (Exception ex) { /* ignore bad format */ }
        }

        if (data.containsKey('reqShipmentDate') && data.get('reqShipmentDate') != null) {
            try { toUpdate.put('ReqShipmentDate__c', Date.valueOf(String.valueOf(data.get('reqShipmentDate')))); } catch (Exception ex) { /* ignore */ }
        }
   
   
        try {
            update toUpdate;
       if(orderCartUpdate!=null)
       {
           update orderCartUpdate;
       }
            return (Id) toUpdate.get('Id');
        } catch (Exception ex) {
            system.debug('exxxx'+ex);
            throw new AuraHandledException('Failed to update OrderCartItem: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteOrderCartItem(String itemId) {
        if (String.isBlank(itemId)) return false;
        try {
            Id i = Id.valueOf(itemId);
            SObject toDelete = Schema.getGlobalDescribe().get('OrderCartItem__c').newSObject();
            toDelete.put('Id', i);
            delete toDelete;
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException('Failed to delete OrderCartItem: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteOrderCart(String cartId) {
        if (String.isBlank(cartId)) return false;
        try {
            Id cid = Id.valueOf(cartId);
            List<SObject> items = Database.query('SELECT Id FROM OrderCartItem__c WHERE OrderCart__c = :cid');
            if (!items.isEmpty()) delete items;
            SObject cart = Schema.getGlobalDescribe().get('OrderCart__c').newSObject();
            cart.put('Id', cid);
            delete cart;
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException('Failed to delete OrderCart: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteOrderCarts(List<Id> cartIds) {
        if (cartIds == null || cartIds.isEmpty()) return false;
        try {
            // Delete order cart items in bulk
            List<OrderCartItem__c> items = [SELECT Id FROM OrderCartItem__c WHERE OrderCart__c IN :cartIds];
            if (!items.isEmpty()) delete items;

            // Delete the carts
            List<OrderCart__c> cartsToDelete = [SELECT Id FROM OrderCart__c WHERE Id IN :cartIds];
            if (!cartsToDelete.isEmpty()) delete cartsToDelete;
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException('Failed to delete OrderCarts: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Id> submitOrderCarts(String cartIdsJson) {

        // Expects a JSON array of cart Id strings
        Map<String, Id> resultMap = new Map<String, Id>();
        if (String.isBlank(cartIdsJson)) return resultMap;

        List<Object> raw = (List<Object>) JSON.deserializeUntyped(cartIdsJson);
        List<Id> cartIds = new List<Id>();

        for (Object o : raw) {
            try { cartIds.add(Id.valueOf(String.valueOf(o))); } catch (Exception ex) { /* ignore invalid ids */ }
        }

        if (cartIds.isEmpty()) return resultMap;

        // Query carts and related items (include stored pricebook and CurrencyIsoCode on cart and price fields on items)
        List<OrderCart__c> carts = [SELECT Id, Contract__c, Contract_Item__c, Account__c, Quote__c, SBQQ_PriceBook__c, CurrencyIsoCode, SBQQ_Opportunity2__c, PMC_CPQ_SoldToAccount__c, SBQQ_PaymentTerm__c, PMC_CPQ_PO__c, PMC_CPQ_PurchaseOrderDate__c FROM OrderCart__c WHERE Id IN :cartIds];

        Map<Id, List<OrderCartItem__c>> itemsByCart = new Map<Id, List<OrderCartItem__c>>();

        List<OrderCartItem__c> cartItems = [SELECT Id, OrderCart__c, ReqShipmentDate__c, OrderPoNumber__c, OrderQty__c, UOM__c, Ship_Method__c, Ship_To__c, Subscription__c, SBQQ_PricebookEntryId__c, PMC_CPQ_NetUnitPrice__c, PMC_CPQ_Incoterms__c, PMC_CPQ_ModeofTransportation__c, PMC_CPQ_DefaultBillingBlock__c, PMC_CPQ_Destination__c, PMC_CPQ_ExchangeRate__c, PMC_CPQ_ProductLocation__c, PMC_CPQ_UnitOfMeasure__c, Quote_Line__c, Quote_Line__r.PMC_CPQ_ProductLocation__c FROM OrderCartItem__c WHERE OrderCart__c IN :cartIds];

        for (OrderCartItem__c it : cartItems) {
            if (!itemsByCart.containsKey(it.OrderCart__c)) itemsByCart.put(it.OrderCart__c, new List<OrderCartItem__c>());
            itemsByCart.get(it.OrderCart__c).add(it);
        }

        // Reorder the carts list to match the incoming cartIds order. This ensures
        // we build ordersToInsert in the same sequence as the requested cart ids
        // so each Order corresponds to the intended OrderCart even when items
        // across carts are identical.
        try {
            Map<Id, OrderCart__c> cartsById = new Map<Id, OrderCart__c>();

            for (OrderCart__c c : carts) cartsById.put(c.Id, c);

            List<OrderCart__c> ordered = new List<OrderCart__c>();

            for (Id cid : cartIds) {
                if (cartsById.containsKey(cid)) ordered.add(cartsById.get(cid));
            }

            // If ordering removed some (e.g., invalid ids), append the rest to preserve behavior
            if (!ordered.isEmpty()) {
                for (OrderCart__c c : carts) {
                    if (!ordered.contains(c)) ordered.add(c);
                }

                carts = ordered;
            }
        } catch (Exception ex) { /* non-fatal: leave 'carts' as returned by SOQL */ }

        // Reorder the carts list to match the incoming cartIds order. This ensures
        // we build ordersToInsert in the same sequence as the requested cart ids
        // so each Order corresponds to the intended OrderCart even when items
        // across carts are identical.
        try {
            Map<Id, OrderCart__c> cartsById = new Map<Id, OrderCart__c>();

            for (OrderCart__c c : carts) cartsById.put(c.Id, c);

            List<OrderCart__c> ordered = new List<OrderCart__c>();

            for (Id cid : cartIds) {
                if (cartsById.containsKey(cid)) ordered.add(cartsById.get(cid));
            }

            // If ordering removed some (e.g., invalid ids), fall back to original list appended
            if (!ordered.isEmpty()) {
                // Append any carts not present in ordered to preserve behaviour
                for (OrderCart__c c : carts) {
                    if (!ordered.contains(c)) ordered.add(c);
                }

                carts = ordered;
            }
        } catch (Exception ex) { /* non-fatal: leave 'carts' as returned by SOQL */ }

        List<Order> ordersToInsert = new List<Order>();
        Map<Id, Order> cartToOrder = new Map<Id, Order>();
        // Preserve the cart Ids in the same order we build ordersToInsert so we can
        // correctly map Database.SaveResult positions back to the originating cart.
        List<Id> cartIdsOrdered = new List<Id>();

        // Helper: try find Quote by ContractId__c (assumed to be text storing quote number or id)
        // and Account by ContractId__c (assumed to be related). We'll attempt lookup by Id first, else by Name.
        for (OrderCart__c cart : carts) {
            Order o = new Order();
            o.Status = 'Draft';
            // EffectiveDate: set to today if available
            o.EffectiveDate = Date.today();

            // Populate AccountId from OrderCart__c.Account__c if present
            if (cart.get('Account__c') != null) {
                try { o.AccountId = (Id) cart.get('Account__c'); } catch (Exception ex) { /* ignore */ }
            }

            // Map SBQQ_Opportunity2__c from cart into Order.OpportunityId when present (defensive)
            try {
                if (cart.get('SBQQ_Opportunity2__c') != null) {
                    Object oppVal = cart.get('SBQQ_Opportunity2__c');

                    if (oppVal != null && String.valueOf(oppVal) != '') o.OpportunityId = Id.valueOf(String.valueOf(oppVal));
                }
            } catch (Exception ex) { /* ignore schema issues */ }

            // If the cart carried PMC_CPQ_SoldToAccount__c, pass it into the Order (priority copy)
            try {
                Object soldTo = cart.get('PMC_CPQ_SoldToAccount__c');
                if (soldTo != null) o.put('PMC_CPQ_SoldToAccount__c', soldTo);
            } catch (Exception e) { /* ignore */ }

            // Populate ContractId from OrderCart__c.Contract__c if present
            if (cart.get('Contract__c') != null) {
                try { o.ContractId = (Id) cart.get('Contract__c'); } catch (Exception ex) { /* ignore */ }
            }

            // Try to populate SBQQ__Quote__c from OrderCart__c.Quote__c when it contains a valid Id
            if (cart.get('Quote__c') != null) {
                String quoteRef = String.valueOf(cart.get('Quote__c'));
                if (!String.isBlank(quoteRef)) {
                    try {
                        Id qid = Id.valueOf(quoteRef);
                        // Confirm existence and also read CurrencyIsoCode to avoid cross-currency validation errors
                        List<SBQQ__Quote__c> qFound = [SELECT Id, CurrencyIsoCode FROM SBQQ__Quote__c WHERE Id = :qid LIMIT 1];
                        if (!qFound.isEmpty()) {
                            o.put('SBQQ__Quote__c', qFound[0].Id);
                            // If Quote has CurrencyIsoCode, assign it to Order to satisfy validation rules

                            if (qFound[0].get('CurrencyIsoCode') != null) {
                                o.CurrencyIsoCode = (String) qFound[0].get('CurrencyIsoCode');
                            }
                        }
                    } catch (Exception ex) { /* If not an Id, ignore (Quote__c is a free text field) */ }
                }
            }

            // If cart stores CurrencyIsoCode (populated during createOrderCarts), use it on the Order as priority
            try {
                if (cart.get('CurrencyIsoCode') != null && String.valueOf(cart.get('CurrencyIsoCode')) != '') {
                    o.CurrencyIsoCode = String.valueOf(cart.get('CurrencyIsoCode'));
                }
            } catch (Exception ex) { /* ignore for orgs without multicurrency */ }

            // Try to set Pricebook2Id on Order from OrderCart.SBQQ_PriceBook__c if available (defensive)
            try {
                if (cart.get('SBQQ_PriceBook__c') != null) {
                    o.put('Pricebook2Id', cart.get('SBQQ_PriceBook__c'));
                }

                // Copy PO field from OrderCart to Order if present
                if (cart.get('PMC_CPQ_PO__c') != null) {
                    o.put('PMC_CPQ_PO__c', cart.get('PMC_CPQ_PO__c'));
                }

                // Copy Payment Terms from OrderCart into Order.SBQQ__PaymentTerm__c when present
                if (cart.get('SBQQ_PaymentTerm__c') != null) {
                    o.put('SBQQ__PaymentTerm__c', cart.get('SBQQ_PaymentTerm__c'));
                }

                // Copy Purchase Order Date from OrderCart into Order.PMC_CPQ_PurchaseOrderDate__c when present
                if (cart.get('PMC_CPQ_PurchaseOrderDate__c') != null) {
                    // cart['PMC_CPQ_PurchaseOrderDate__c'] is expected to be a Date already when persisted in createOrderCarts
                    try { o.put('PMC_CPQ_PurchaseOrderDate__c', cart.get('PMC_CPQ_PurchaseOrderDate__c')); } catch (Exception innerEx) {
                        // fallback: try to coerce string representation to Date
                        o.put('PMC_CPQ_PurchaseOrderDate__c', Date.valueOf(String.valueOf(cart.get('PMC_CPQ_PurchaseOrderDate__c'))));
                    }
                }
            } catch (Exception ex) { /* ignore if field missing or invalid */ }

            ordersToInsert.add(o);
            cartIdsOrdered.add(cart.Id);
            cartToOrder.put(cart.Id, o);
        }

        // If any carts reference a Contract, ensure the Orders' AccountId matches the Contract.AccountId
        // Also: populate Order.BillToContactId from Contract.PMC_CPQ_PrimaryContact__c and
        // populate Order.PMC_CPQ_SoldToAccount__c from Account.PMC_SS_SoldToAccount__c when available.
        try {
            Set<Id> contractIdsToCheck = new Set<Id>();
            Set<Id> accountIdsToCheck = new Set<Id>();

            for (OrderCart__c c : carts) {
                try {
                    if (c.Contract__c != null) contractIdsToCheck.add((Id) c.Contract__c);
                } catch (Exception ex) { /* ignore */ }

                try {
                    if (c.Account__c != null) accountIdsToCheck.add((Id) c.Account__c);
                } catch (Exception ex) { /* ignore */ }
            }

            Map<Id, Account> accountById = new Map<Id, Account>();
            if (!accountIdsToCheck.isEmpty()) {
                for (Account a : [SELECT Id, PMC_SS_SoldToAccount__c FROM Account WHERE Id IN :accountIdsToCheck]) accountById.put(a.Id, a);
            }

            Map<Id, Contract> contractById = new Map<Id, Contract>();
            if (!contractIdsToCheck.isEmpty()) {
                for (Contract ct : [SELECT Id, AccountId, StartDate, PMC_CPQ_PrimaryContact__c FROM Contract WHERE Id IN :contractIdsToCheck]) contractById.put(ct.Id, ct);
            }

            // Schema checks
            Boolean canSetBillTo = false;
            Boolean canSetSoldTo = false;
            try {
                if (Schema.sObjectType.Order.isCreateable()) {
                    canSetBillTo = Schema.sObjectType.Order.fields.BillToContactId != null ? Schema.sObjectType.Order.fields.BillToContactId.isCreateable() : false;
                    canSetSoldTo = Schema.sObjectType.Order.fields.PMC_CPQ_SoldToAccount__c != null ? Schema.sObjectType.Order.fields.PMC_CPQ_SoldToAccount__c.isCreateable() : false;
                }
            } catch (Exception ex) { /* ignore schema reflection errors */ }

            for (OrderCart__c c : carts) {
                try {
                    if (c.Contract__c != null && contractById.containsKey((Id) c.Contract__c)) {
                        Contract ct = contractById.get((Id) c.Contract__c);
                        Order ord = cartToOrder.get(c.Id);

                        if (ord != null) {
                            // If Order.AccountId is null or doesn't match contract.AccountId, enforce the contract's account
                            Id contractAccount = ct.AccountId;
                            if (contractAccount != null) {
                                if (ord.AccountId == null || ord.AccountId != contractAccount) {
                                    ord.AccountId = contractAccount;
                                    System.debug('OrderCartService: Overriding Order.AccountId to match Contract.AccountId for cart ' + c.Id + ' -> contract ' + ct.Id);
                                }
                            }

                            // Set BillToContactId from Contract.PMC_CPQ_PrimaryContact__c when available
                            if (canSetBillTo && ct.PMC_CPQ_PrimaryContact__c != null) {
                                ord.BillToContactId = ct.PMC_CPQ_PrimaryContact__c;
                            }

                            // Override EffectiveDate from Contract.StartDate when available
                            if (ct.StartDate != null) ord.EffectiveDate = ct.StartDate;
                        }
                    }

                    // Populate PMC_CPQ_SoldToAccount__c on Order from Account.PMC_SS_SoldToAccount__c when available
                    Order ord2 = cartToOrder.get(c.Id);
                    if (ord2 != null && ord2.AccountId != null && accountById.containsKey(ord2.AccountId)) {
                        Account a = accountById.get(ord2.AccountId);

                        if (canSetSoldTo && a.PMC_SS_SoldToAccount__c != null) {
                            ord2.put('PMC_CPQ_SoldToAccount__c', a.PMC_SS_SoldToAccount__c);
                        }
                    }
                } catch (Exception ex) { /* continue with next contract/account */ }
            }
        } catch (Exception e) {
            // non-fatal: log and continue; we'll let DML surface any remaining integrity issues
            try { System.debug('OrderCartService.submitOrderCarts - contract/account reconciliation failed: ' + e); } catch (Exception e2) { /* swallow logging errors */ }
        }

        // Insert Orders non-atomically to capture per-record errors and return clearer messages
        // PRE-INSERT VALIDATION: check referenced records (Account, Contract, Pricebook2, SBQQ__Quote__c, Contact) exist and are accessible
        try {
            // Collect referenced ids from ordersToInsert where present
            Set<Id> referencedAccountIds = new Set<Id>();
            Set<Id> referencedContractIds = new Set<Id>();
            Set<Id> referencedPricebookIds = new Set<Id>();
            Set<Id> referencedQuoteIds = new Set<Id>();
            Set<Id> referencedContactIds = new Set<Id>();

            Integer ordIdx = 0;
            for (Order ord : ordersToInsert) {
                if (ord.AccountId != null) referencedAccountIds.add(ord.AccountId);
                if (ord.ContractId != null) referencedContractIds.add(ord.ContractId);

                Object pricebook = null;
                try { pricebook = ord.get('Pricebook2Id'); } catch (Exception e) { pricebook = null; }
                if (pricebook != null) referencedPricebookIds.add((Id) pricebook);

                Object quote = null;
                try { quote = ord.get('SBQQ__Quote__c'); } catch (Exception e) { quote = null; }
                if (quote != null) referencedQuoteIds.add((Id) quote);

                Object billingContactId = null;
                try { billingContactId = ord.get('BillToContactId'); } catch (Exception e) { billingContactId = null; }
                if (billingContactId != null) referencedContactIds.add((Id) billingContactId);

                ordIdx++;
            }

            // Query these ids to confirm existence / access
            Map<Id, Account> accById = new Map<Id, Account>();
            if (!referencedAccountIds.isEmpty()) {
                for (Account a : [SELECT Id FROM Account WHERE Id IN :referencedAccountIds]) accById.put(a.Id, a);
            }
            Map<Id, Contract> ctById = new Map<Id, Contract>();
            if (!referencedContractIds.isEmpty()) {
                for (Contract c : [SELECT Id FROM Contract WHERE Id IN :referencedContractIds]) ctById.put(c.Id, c);
            }
            Map<Id, Pricebook2> pbById = new Map<Id, Pricebook2>();
            if (!referencedPricebookIds.isEmpty()) {
                for (Pricebook2 p : [SELECT Id FROM Pricebook2 WHERE Id IN :referencedPricebookIds]) pbById.put(p.Id, p);
            }
            Map<Id, SBQQ__Quote__c> qById = new Map<Id, SBQQ__Quote__c>();
            if (!referencedQuoteIds.isEmpty()) {
                for (SBQQ__Quote__c q : [SELECT Id FROM SBQQ__Quote__c WHERE Id IN :referencedQuoteIds]) qById.put(q.Id, q);
            }
            Map<Id, Contact> cById = new Map<Id, Contact>();
            if (!referencedContactIds.isEmpty()) {
                for (Contact c : [SELECT Id FROM Contact WHERE Id IN :referencedContactIds]) cById.put(c.Id, c);
            }

            // Build human-friendly problems list when referenced ids are not visible / do not exist
            List<String> preInsertProblems = new List<String>();
            for (Order ord : ordersToInsert) {
                ord.isMosaicDirect__c = true;

                try {
                    if (ord.AccountId != null && !accById.containsKey(ord.AccountId)) preInsertProblems.add('Order referencing Account not accessible or not found: ' + String.valueOf(ord.AccountId));
                } catch (Exception e) {}
                try {
                    if (ord.ContractId != null && !ctById.containsKey(ord.ContractId)) preInsertProblems.add('Order referencing Contract not accessible or not found: ' + String.valueOf(ord.ContractId));
                } catch (Exception e) {}
                try {
                    Object pb = null; try { pb = ord.get('Pricebook2Id'); } catch (Exception e) { pb = null; }
                    if (pb != null && !pbById.containsKey((Id) pb)) preInsertProblems.add('Order referencing Pricebook2 not accessible or not found: ' + String.valueOf(pb));
                } catch (Exception e) {}
                try {
                    Object q = null; try { q = ord.get('SBQQ__Quote__c'); } catch (Exception e) { q = null; }
                    if (q != null && !qById.containsKey((Id) q)) preInsertProblems.add('Order referencing Quote not accessible or not found: ' + String.valueOf(q));
                } catch (Exception e) {}
                try {
                    Object b2 = null; try { b2 = ord.get('BillToContactId'); } catch (Exception e) { b2 = null; }
                    if (b2 != null && !cById.containsKey((Id) b2)) preInsertProblems.add('Order referencing BillTo Contact not accessible or not found: ' + String.valueOf(b2));
                } catch (Exception e) {}
            }

            if (!preInsertProblems.isEmpty()) {
                throw new AuraHandledException('Pre-insert validation failed: ' + String.join(preInsertProblems, '; '));
            }
        } catch (AuraHandledException aex) {
            throw aex;
        } catch (Exception ex) {
            // non-fatal: continue to DML and rely on SaveResult for final diagnostics
            try { System.debug('OrderCartService.submitOrderCarts - pre-insert validation skipped due to error: ' + ex); } catch (Exception e) {}
        }
        Map<Id, Id> tempCartToOrderId = new Map<Id, Id>();
        List<Database.SaveResult> orderResults = new List<Database.SaveResult>();
        if (!ordersToInsert.isEmpty()) {
            // Debug: log carts and orders before insert
            try { System.debug('DEBUG submitOrderCarts - pre-insert carts.size=' + String.valueOf(carts.size()) + ' cartIdsOrdered=' + String.valueOf(cartIdsOrdered)); } catch (Exception e) { }
            try { System.debug('DEBUG submitOrderCarts - pre-insert ordersToInsert.size=' + String.valueOf(ordersToInsert.size()) + ' ordersToInsert=' + String.valueOf(ordersToInsert)); } catch (Exception e) { }
            // Extra granular debug: log each ordersToInsert entry and its corresponding cartId index
            try {
                for (Integer iIdx = 0; iIdx < ordersToInsert.size(); iIdx++) {
                    Order ordTmp = ordersToInsert[iIdx];
                    Id cartIdTmp = (iIdx < cartIdsOrdered.size()) ? cartIdsOrdered[iIdx] : null;
                    try {
                        System.debug('DEBUG submitOrderCarts - pre-insert index=' + iIdx + ' cartId=' + String.valueOf(cartIdTmp) + ' OrderObj=' + String.valueOf(ordTmp));
                    } catch (Exception e) { }
                }
            } catch (Exception e) { }

            SBQQ.TriggerControl.disable();
            try {
                orderResults = Database.insert(ordersToInsert, false);
                try { System.debug('DEBUG submitOrderCarts - post-insert orderResults.size=' + String.valueOf(orderResults.size())); } catch (Exception e) { }
            } catch (Exception ex) {
                // unexpected failure in Database.insert - fallback to throwing
                try { System.debug('OrderCartService.submitOrderCarts - Database.insert unexpected failure: ' + ex); } catch (Exception e2) { }
                throw new AuraHandledException('Failed to insert Orders: ' + ex.getMessage());
            } finally {
                SBQQ.TriggerControl.enable();
            }

            // Walk results and map successful order Ids back to carts by position.
            // Important: explicitly assign the returned Id into the corresponding
            // ordersToInsert instance and update cartToOrder with that instance so
            // later OrderItem creation uses the correct OrderId per cart.
            Integer pos = 0;
            List<String> orderErrors = new List<String>();
            for (Database.SaveResult sr : orderResults) {
                try {
                    System.debug('DEBUG submitOrderCarts - SaveResult pos=' + String.valueOf(pos) + ' isSuccess=' + String.valueOf(sr.isSuccess()) + ' errors=' + String.valueOf(sr.getErrors()));
                } catch (Exception e) { }
                Id cartIdAtPos = (pos < cartIdsOrdered.size()) ? cartIdsOrdered[pos] : null;
                Integer currentPos = pos;
                if (sr.isSuccess()) {
                    // sr.getId() is the Order Id: attach it to the in-memory Order instance
                    try {
                        if (currentPos < ordersToInsert.size()) {
                            // set Id on the Order instance so downstream logic can read it
                            System.debug('DEBUG submitOrderCarts - assigning sr.getId()=' + String.valueOf(sr.getId()) + ' to ordersToInsert['+currentPos+'] for cartIdAtPos=' + String.valueOf(cartIdAtPos));
                            ordersToInsert[currentPos].Id = sr.getId();
                            // ensure cart->order mapping points to the same instance
                            if (cartIdAtPos != null) {
                                cartToOrder.put(cartIdAtPos, ordersToInsert[currentPos]);
                            }
                            // also keep the temp map of ids for backward compatibility
                            if (cartIdAtPos != null) tempCartToOrderId.put(cartIdAtPos, sr.getId());
                            try { System.debug('DEBUG submitOrderCarts - ordersToInsert['+currentPos+'].Id now=' + String.valueOf(ordersToInsert[currentPos].Id)); } catch (Exception e) { }
                        } else {
                            // fallback: store id only
                            if (cartIdAtPos != null) tempCartToOrderId.put(cartIdAtPos, sr.getId());
                        }
                    } catch (Exception e) {
                        if (cartIdAtPos != null) tempCartToOrderId.put(cartIdAtPos, sr.getId());
                    }
                try {
                    // log mapping progress
                    System.debug('DEBUG submitOrderCarts - after mapping pos=' + String.valueOf(pos) + ' cartIdAtPos=' + String.valueOf(cartIdAtPos) + ' tempCartToOrderId=' + String.valueOf(tempCartToOrderId.get(cartIdAtPos)) + ' cartToOrderInstanceId=' + (cartToOrder.containsKey(cartIdAtPos) ? String.valueOf(cartToOrder.get(cartIdAtPos).Id) : 'null'));
                } catch (Exception e) { }
                } else {
                    // collect errors for this position to include in exception; include reference fields to help debug permission issues
                    String cartRef = cartIdAtPos != null ? String.valueOf(cartIdAtPos) : String.valueOf(currentPos);
                    // Retrieve the Order object we attempted to insert at this position when possible
                    Order attempted = null;
                    try {
                        if (currentPos < ordersToInsert.size()) attempted = ordersToInsert[currentPos];
                    } catch (Exception e) { attempted = null; }

                    // Build refs string
                    List<String> refs = new List<String>();
                    try { if (attempted != null && attempted.AccountId != null) refs.add('AccountId=' + String.valueOf(attempted.AccountId)); } catch (Exception e) {}
                    try { if (attempted != null && attempted.ContractId != null) refs.add('ContractId=' + String.valueOf(attempted.ContractId)); } catch (Exception e) {}
                    try { Object pb = null; try { pb = attempted.get('Pricebook2Id'); } catch (Exception e) { pb = null; } if (pb != null) refs.add('Pricebook2Id=' + String.valueOf(pb)); } catch (Exception e) {}
                    try { Object q = null; try { q = attempted.get('SBQQ__Quote__c'); } catch (Exception e) { q = null; } if (q != null) refs.add('SBQQ__Quote__c=' + String.valueOf(q)); } catch (Exception e) {}
                    try { Object b2 = null; try { b2 = attempted.get('BillToContactId'); } catch (Exception e) { b2 = null; } if (b2 != null) refs.add('BillToContactId=' + String.valueOf(b2)); } catch (Exception e) {}

                    for (Database.Error err : sr.getErrors()) {
                        String base = 'Order['+currentPos+'] cartId=' + cartRef + ': ' + err.getStatusCode() + ' - ' + err.getMessage();
                        if (!refs.isEmpty()) base += ' refs: ' + String.join(refs, ', ');
                        orderErrors.add(base);
                    }
                }
                pos++;
            }

            // If any order insert failed, surface clear error messages and abort
            if (!orderErrors.isEmpty()) {
                throw new AuraHandledException('Order insert problems: ' + String.join(orderErrors, '\n'));
            }

            // cartToOrder already references the Order instances where possible
            // (we populated ordersToInsert[currentPos].Id and updated cartToOrder above),
            // so avoid overwriting them with minimal Order(Id) instances.

            // (Deferred) Do not update OrderCart__c to Closed immediately after Order insert.
            // We'll decide which carts to close later once OrderItems are inserted
            // successfully. This avoids marking carts as Closed when subsequent
            // OrderItem creation fails.
        }

        // Debug: log created Orders and build cart->order mapping
        try {
            System.debug('OrderCartService.submitOrderCarts - Orders inserted (full list): ' + ordersToInsert);
            Map<Id, Id> cartToOrderIdMap = new Map<Id, Id>();
            Integer idx = 0;
            for (Order o : ordersToInsert) {
                // ordersToInsert maintains same order as carts iteration above; we map by cartIdsOrdered list
                if (idx < cartIdsOrdered.size()) {
                    cartToOrderIdMap.put(cartIdsOrdered[idx], o.Id);
                }
                idx++;
            }
            System.debug('OrderCartService.submitOrderCarts - cartId -> OrderId map: ' + cartToOrderIdMap);
        } catch (Exception ex) { /* ignore debug errors */ }

        // After insert, ordersToInsert have Ids; build OrderItems
        List<OrderItem> itemsToInsert = new List<OrderItem>();
        // Map to collect created OrderItem ids per OrderId. Declared here so it's
        // available after the insert attempt and can be used to decide whether
        // to mark the originating OrderCart as Closed (only if OrderItems were
        // actually created for the Order).
        Map<Id, List<Id>> orderToOrderItemIds = new Map<Id, List<Id>>();
            for (OrderCart__c cart : carts) {
                // Resolve the OrderId for this cart exclusively from tempCartToOrderId when possible
                // tempCartToOrderId was populated directly from the Database.SaveResult positions and
                // is the authoritative map that ties a cart Id to the inserted Order Id.
                Id resolvedOrderId = null;
                try {
                    if (tempCartToOrderId.containsKey(cart.Id)) {
                        resolvedOrderId = tempCartToOrderId.get(cart.Id);
                    } else {
                        // Defensive fallback ONLY for diagnostics: try to map by preserved positions
                        Integer idx = cartIdsOrdered.indexOf(cart.Id);
                        if (idx != -1 && idx >= 0 && idx < ordersToInsert.size()) {
                            try { resolvedOrderId = ordersToInsert[idx].Id; } catch (Exception e) { resolvedOrderId = null; }
                            try { System.debug('DEBUG submitOrderCarts - fallback resolvedOrderId for cart ' + cart.Id + ' from ordersToInsert['+idx+'] = ' + String.valueOf(resolvedOrderId)); } catch (Exception e) { }
                        } else {
                            try { System.debug('DEBUG submitOrderCarts - missing mapping for cart ' + cart.Id + ', no tempCartToOrderId and no matching ordersToInsert'); } catch (Exception e) { }
                        }
                    }
                } catch (Exception e) { /* ignore */ }

                if (resolvedOrderId == null) { resultMap.put(String.valueOf(cart.Id), null); continue; }
                resultMap.put(String.valueOf(cart.Id), resolvedOrderId);

                List<OrderCartItem__c> items = itemsByCart.containsKey(cart.Id) ? itemsByCart.get(cart.Id) : new List<OrderCartItem__c>();
                for (OrderCartItem__c ci : items) {
                    OrderItem oi = new OrderItem();
                    // Standard OrderItem requires PricebookEntry and UnitPrice — this mapping assumes org has a default PricebookEntry or managed package that allows omission.
                    // We'll try to populate the custom fields requested and set Quantity and other simple fields.
                    try {
                        oi.put('OrderId', resolvedOrderId);
                    } catch (Exception ex) { /* ignore */ }

                    // Set pricing date to today's date (Date field) so OrderItem.PMC_CPQ_PricingDate__c records creation date
                    try { oi.put('PMC_CPQ_PricingDate__c', Date.today()); } catch (Exception ex) { /* ignore if field missing */ }

                    // Map fields per user mapping
                    if (ci.ReqShipmentDate__c != null) oi.put('PMC_CPQ_RequestedShipDate__c', ci.ReqShipmentDate__c);
                    if (ci.OrderPoNumber__c != null) oi.put('PMC_CPQ_LinePONumber__c', String.valueOf(ci.OrderPoNumber__c));
                    if (ci.OrderQty__c != null) oi.Quantity = ci.OrderQty__c;
                    if (ci.UOM__c != null) oi.put('PMC_CPQ_UnitOfMeasure__c', ci.UOM__c);
                    if (ci.Ship_Method__c != null) oi.put('PMC_CPQ_ShippingType__c', ci.Ship_Method__c);
                    // Copy Incoterms and ModeOfTransportation from OrderCartItem into OrderItem custom fields
                    try { if (ci.get('PMC_CPQ_Incoterms__c') != null) oi.put('PMC_CPQ_Incoterms__c', ci.get('PMC_CPQ_Incoterms__c')); } catch (Exception ex) { }
                    try { if (ci.get('PMC_CPQ_ModeofTransportation__c') != null) oi.put('PMC_CPQ_ModeofTransportation__c', ci.get('PMC_CPQ_ModeofTransportation__c')); } catch (Exception ex) { }
                    // Copy DefaultBillingBlock, Destination and ExchangeRate from OrderCartItem into OrderItem
                    try { if (ci.get('PMC_CPQ_DefaultBillingBlock__c') != null) oi.put('PMC_CPQ_DefaultBillingBlock__c', ci.get('PMC_CPQ_DefaultBillingBlock__c')); } catch (Exception ex) { }
                    try { if (ci.get('PMC_CPQ_Destination__c') != null) oi.put('PMC_CPQ_Destination__c', ci.get('PMC_CPQ_Destination__c')); } catch (Exception ex) { }
                    try { if (ci.get('PMC_CPQ_ExchangeRate__c') != null) oi.put('PMC_CPQ_ExchangeRate__c', ci.get('PMC_CPQ_ExchangeRate__c')); } catch (Exception ex) { }
                    // Copy ProductLocation and UnitOfMeasure from OrderCartItem into OrderItem
                    // Also map legacy Origin__c into PMC_CPQ_ProductLocation__c when present
                    try {
                        // Source priority: 1) PMC_CPQ_ProductLocation__c on cart item; 2) Quote_Line__r.PMC_CPQ_ProductLocation__c
                        if (ci.get('PMC_CPQ_ProductLocation__c') != null) {
                            oi.put('PMC_CPQ_ProductLocation__c', ci.get('PMC_CPQ_ProductLocation__c'));
                        } else {
                            try {
                                SObject qlr = (SObject) ci.getSObject('Quote_Line__r');
                                if (qlr != null) {
                                    Object qlpVal = qlr.get('PMC_CPQ_ProductLocation__c');
                                    if (qlpVal != null) {
                                        oi.put('PMC_CPQ_ProductLocation__c', qlpVal);
                                    }
                                }
                            } catch (Exception qEx) {
                                // ignore — leave ProductLocation blank if not accessible
                            }
                        }
                    } catch (Exception ex) { }
                    try { if (ci.get('PMC_CPQ_UnitOfMeasure__c') != null) oi.put('PMC_CPQ_UnitOfMeasure__c', ci.get('PMC_CPQ_UnitOfMeasure__c')); } catch (Exception ex) { }
                    if (ci.Ship_To__c != null) {
                        // Ship_To__c in OrderCartItem__c may contain either an Id or a user-entered name.
                        // Avoid assigning non-Id values to a lookup field (causes MALFORMED_ID). Try to resolve safely:
                        try {
                            // Try to treat as Id first
                            Id shipToId = Id.valueOf(String.valueOf(ci.Ship_To__c));
                            oi.put('PMC_CPQ_ShipTo__c', shipToId);
                        } catch (Exception idEx) {
                            // Not an Id — try to resolve by Account Name (best-effort)
                            try {
                                String candidateName = String.valueOf(ci.Ship_To__c);
                                if (!String.isBlank(candidateName)) {
                                    List<Account> found = [SELECT Id FROM Account WHERE Name = :candidateName LIMIT 1];
                                    if (!found.isEmpty()) {
                                        oi.put('PMC_CPQ_ShipTo__c', found[0].Id);
                                    } else {
                                        // leave unset to avoid MALFORMED_ID; caller will get clearer validation if required
                                    }
                                }
                            } catch (Exception qEx) {
                                // ignore and leave unset to prevent MALFORMED_ID
                            }
                        }
                    }

                    // Try to set PMC_CPQ_Account__c on OrderItem from Order.AccountId
                    Order ordForCart = null;
                    try { ordForCart = cartToOrder.containsKey(cart.Id) ? cartToOrder.get(cart.Id) : null; } catch (Exception e) { ordForCart = null; }
                    try { if (ordForCart != null && ordForCart.AccountId != null) oi.put('PMC_CPQ_Account__c', ordForCart.AccountId); } catch (Exception ex) { /* ignore */ }

                    // Copy Payment Terms from the parent OrderCart into OrderItem.PMC_CPQ_PaymentTerms__c when available
                    try {
                        if (cart != null && cart.SBQQ_PaymentTerm__c != null) {
                            oi.put('PMC_CPQ_PaymentTerms__c', cart.SBQQ_PaymentTerm__c);
                        }
                    } catch (Exception ex) { /* ignore if field missing or not createable */ }
                    // Populate Contract references on OrderItem from the parent OrderCart__c.Contract__c when available
                    try {
                        if (ci.get('OrderCart__c') != null && ci.OrderCart__c != null) {
                            // Safely query the parent Cart's Contract__c if present on the cart record we already have in memory
                            try {
                                Id parentCartId = ci.OrderCart__c;
                                // We have `cart` variable in outer loop, but to be defensive use the current cart variable
                                if (cart != null && cart.Id == parentCartId) {
                                    if (cart.get('Contract__c') != null) {
                                        oi.put('SBQQ__Contract__c', cart.get('Contract__c'));
                                        oi.put('ContractId', cart.get('Contract__c'));
                                    }
                                }
                            } catch (Exception ex) { /* ignore retrieval errors */ }
                        }
                    } catch (Exception ex) { /* defensive: ignore if fields missing */ }

                    try {
                        if (ci.Subscription__c != null) {
                            oi.put('SBQQ__Subscription__c', ci.Subscription__c);
                        }
                    } catch (Exception ex) { /* ignore if field doesn't exist in org */ }
                    try {
                        if (ci.SBQQ_Product__c != null) {
                            oi.Product2Id = ci.SBQQ_Product__c;
                        }
                    } catch (Exception ex) { }
                    
                    // Set PricebookEntryId and UnitPrice on OrderItem from OrderCartItem fields when present (defensive)
                    try {
                        if (ci.get('SBQQ_PricebookEntryId__c') != null) {
                            oi.put('PricebookEntryId', ci.get('SBQQ_PricebookEntryId__c'));
                        }
                    } catch (Exception ex) { /* ignore if field missing or invalid */ }
                    try {
                        if (ci.get('PMC_CPQ_NetUnitPrice__c') != null) {
                            oi.put('UnitPrice', ci.get('PMC_CPQ_NetUnitPrice__c'));
                        }
                    } catch (Exception ex) { /* ignore if field missing or invalid */ }

                    itemsToInsert.add(oi);
                }
            }

            // Insert OrderItems if any; perform validation first to produce clearer errors
            if (!itemsToInsert.isEmpty()) {
                // Validation: ensure required fields present and PricebookEntry belongs to Order.Pricebook2Id when possible
                List<String> problems = new List<String>();

                // Map OrderId -> Pricebook2Id for created Orders
                Map<Id, Id> orderPricebook = new Map<Id, Id>();
                for (Order o : ordersToInsert) {
                    if (o != null && o.Id != null) {
                        try {
                            if (o.get('Pricebook2Id') != null) orderPricebook.put(o.Id, (Id) o.get('Pricebook2Id'));
                        } catch (Exception ex) { /* ignore */ }
                    }
                }

                // Collect PricebookEntry Ids to validate
                Set<Id> pbeIds = new Set<Id>();
                for (OrderItem oi : itemsToInsert) {
                    try {
                        if (oi.get('PricebookEntryId') != null) pbeIds.add((Id) oi.get('PricebookEntryId'));
                    } catch (Exception ex) { /* ignore */ }
                }

                Map<Id, PricebookEntry> pbeById = new Map<Id, PricebookEntry>();
                if (!pbeIds.isEmpty()) {
                    for (PricebookEntry pbe : [SELECT Id, Pricebook2Id, IsActive FROM PricebookEntry WHERE Id IN :pbeIds]) pbeById.put(pbe.Id, pbe);
                }

                Integer idx = 0;
                for (OrderItem oi : itemsToInsert) {
                    idx++;
                    // OrderId
                    Id ordId = null;
                    try { ordId = (Id) oi.get('OrderId'); } catch (Exception ex) { }
                    if (ordId == null) problems.add('OrderItem['+idx+'] missing OrderId');

                    // Quantity
                    try {
                        if (oi.Quantity == null || oi.Quantity <= 0) problems.add('OrderItem['+idx+'] has invalid Quantity: ' + String.valueOf(oi.Quantity));
                    } catch (Exception ex) { problems.add('OrderItem['+idx+'] Quantity check failed'); }

                    // UnitPrice or PricebookEntryId required
                    Object upObj = null; Object pbeObj = null;
                    try { upObj = oi.get('UnitPrice'); } catch (Exception ex) { }
                    try { pbeObj = oi.get('PricebookEntryId'); } catch (Exception ex) { }
                    if (upObj == null && pbeObj == null) problems.add('OrderItem['+idx+'] requires UnitPrice or PricebookEntryId');

                    // If PricebookEntryId present, check pricebook matches Order (if we have order.Pricebook2Id)
                    if (ordId != null && pbeObj != null) {
                        try {
                            Id pbeId = (Id) pbeObj;
                            if (pbeById.containsKey(pbeId)) {
                                PricebookEntry pbe = pbeById.get(pbeId);
                                Id orderPb = orderPricebook.containsKey(ordId) ? orderPricebook.get(ordId) : null;
                                if (orderPb != null && pbe.Pricebook2Id != orderPb) {
                                    problems.add('OrderItem['+idx+'] PricebookEntry ('+pbeId+') does not belong to Order.Pricebook2Id');
                                }
                                if (!pbe.IsActive) problems.add('OrderItem['+idx+'] PricebookEntry ('+pbeId+') is not active');
                            } else {
                                problems.add('OrderItem['+idx+'] PricebookEntry ('+String.valueOf(pbeId)+') not found');
                            }
                        } catch (Exception ex) { problems.add('OrderItem['+idx+'] PricebookEntry validation failed'); }
                    }
                }

                if (!problems.isEmpty()) {
                    String msg = 'OrderItem validation failed: ' + String.join(problems, '; ');
                    throw new AuraHandledException(msg);
                }

                try {
                    // Use non-atomic insert to collect per-record failures
                    List<Database.SaveResult> itemResults = Database.insert(itemsToInsert, false);

                    // Build order->orderItem id map from successful results into the
                    // external map declared above so it's visible later when deciding
                    // which carts to close.
                    for (Integer i = 0; i < itemResults.size(); i++) {
                        Database.SaveResult sr = itemResults[i];
                        if (sr.isSuccess()) {
                            OrderItem createdOi = (OrderItem) itemsToInsert[i];
                            Id createdId = sr.getId();
                            try {
                                if (!orderToOrderItemIds.containsKey(createdOi.OrderId)) orderToOrderItemIds.put(createdOi.OrderId, new List<Id>());
                                orderToOrderItemIds.get(createdOi.OrderId).add(createdId);
                            } catch (Exception e) { /* ignore mapping errors */ }
                        }
                    }

                    try {
                        System.debug('OrderCartService.submitOrderCarts - OrderItems inserted (ids map): ' + orderToOrderItemIds);
                    } catch (Exception ex) { /* ignore */ }

                    // Collect failures to return clearer messages
                    List<String> itemErrors = new List<String>();
                    for (Integer i = 0; i < itemResults.size(); i++) {
                        Database.SaveResult sr = itemResults[i];
                        if (!sr.isSuccess()) {
                            // Map back to cartId where possible
                            String cartRef = '';
                            try {
                                OrderItem oiRef = (OrderItem) itemsToInsert[i];
                                cartRef = oiRef.get('OrderId') != null ? String.valueOf(oiRef.get('OrderId')) : '';
                            } catch (Exception e) { }
                            for (Database.Error err : sr.getErrors()) {
                                itemErrors.add('OrderItem['+i+'] cartOrderRef='+cartRef+': ' + err.getStatusCode() + ' - ' + err.getMessage());
                            }
                        }
                    }
                    if (!itemErrors.isEmpty()) {
                        throw new AuraHandledException('OrderItem insert problems: ' + String.join(itemErrors, '\n'));
                    }
                } catch (AuraHandledException aex) {
                    // rethrow known formatted error
                    throw aex;
                } catch (Exception ex) {
                    // Catch-all: unexpected failure
                    throw new AuraHandledException('Failed to insert OrderItems: ' + ex.getMessage());
                }
            }

            // Mark processed OrderCarts as Closed and link created Order Ids
            // Only update carts that have a successfully created Order. Use tempCartToOrderId
            // as the authoritative source for cart -> Order Id mapping (populated from SaveResult).
            List<OrderCart__c> cartsToUpdate = new List<OrderCart__c>();
            for (OrderCart__c cart : carts) {
                try {
                    if (tempCartToOrderId.containsKey(cart.Id) && tempCartToOrderId.get(cart.Id) != null) {
                        Id createdOrderId = tempCartToOrderId.get(cart.Id);
                        // Only mark the cart Closed if the corresponding Order has at
                        // least one successfully created OrderItem. This prevents
                        // closing carts when OrderItem creation failed.
                        Boolean hasItems = orderToOrderItemIds.containsKey(createdOrderId) && orderToOrderItemIds.get(createdOrderId) != null && !orderToOrderItemIds.get(createdOrderId).isEmpty();
                        if (hasItems) {
                            try {
                                OrderCart__c upd = new OrderCart__c(Id = cart.Id);
                                upd.Status__c = 'Closed';
                                upd.Order__c = createdOrderId;
                                cartsToUpdate.add(upd);
                            } catch (Exception innerEx) { /* per-record defensive: skip problematic mapping */ }
                        } else {
                            try { System.debug('OrderCartService.submitOrderCarts - skipping Close for cart ' + cart.Id + ' because no OrderItems were created for Order ' + String.valueOf(createdOrderId)); } catch (Exception e) { }
                        }
                    }
                } catch (Exception ex) { /* ignore per-record errors */ }
            }
            if (!cartsToUpdate.isEmpty()) {
                try { update cartsToUpdate; } catch (Exception ex) { /* non-fatal */ }
            }

            // Disparar integração externa para SAP usando a nova implementação OrderCart_* se existirem Orders criados
            try {
                if (!ordersToInsert.isEmpty()) {
                    List<Order> ordersToReplicate = new List<Order>();
                    for (Order o : ordersToInsert) {
                        if (o != null && o.Id != null) ordersToReplicate.add(o);
                    }
                    if (!ordersToReplicate.isEmpty()) {
                        // Enfileira uma requisição separada por Order para garantir que cada Order
                        // seja enviada isoladamente ao CPI/SAP, conforme requisito.
                        for (Order o : ordersToReplicate) {
                            try {
                                List<Order> single = new List<Order>{ o };
                                OrderCart_OrderCreateActionClass.postInfoToCPI(single);
                            } catch (Exception ex) {
                                try { System.debug('OrderCartService.submitOrderCarts - failed to enqueue single-order replication for Order ' + o.Id + ': ' + ex); } catch (Exception ignore) { }
                            }
                        }
                    }
                }
            } catch (Exception ex) {
                try { System.debug('OrderCartService.submitOrderCarts - failed to trigger OrderCart replication: ' + ex); } catch (Exception ignore) { }
            }

            return resultMap;
    }
}