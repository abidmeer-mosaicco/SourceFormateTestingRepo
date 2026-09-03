/**
 * @description       : Helper class for fetching Document History
 * @author            : @Nikhilesh
 * @last modified on  : 10-25-2023
 * @last modified by  : Nikhilesh Mohanty
 * @Created on        : 10-25-2023
 **/
public without sharing class PMC_DH_DocumentListViewHelper {
    private static final List<String> NA_COUNTRIES = new List<String>{ 'United States', 'Canada' };
    private static final String BRAZIL_COUNTRY = 'Brazil';

    private static Map<String, PMC_DH_DocumentType__mdt> DOC_TYPE_METADATA_CACHE;

    private static Map<String, PMC_DH_DocumentType__mdt> getDocTypeMetadataCache() {
        if (DOC_TYPE_METADATA_CACHE == null) {
            DOC_TYPE_METADATA_CACHE = PMC_DH_DocumentType__mdt.getAll();
        }
        return DOC_TYPE_METADATA_CACHE;
    }

    /**
     * @description       : Class for Searching and Filtering Documents
     * @author            : @Mosaic Direct Dev
     * @Created on        : 10-26-2023
     * @return            : List<OrderItem>
     * @param             searchParams
     * @param             strEffectiveAccId
     **/
    public static List<OrderItem> getDocumentSearchQuery(
        PMC_DH_DocumentSearchParameterWrapper searchParams,
        String strEffectiveAccId
    ) {
        System.debug('Entering getDocumentSearchQuery...');
        System.debug('searchParams: ' + searchParams);
        System.debug('strEffectiveAccId: ' + strEffectiveAccId);

        String strSearchPattern123;
        String statusDeleted = 'Delivery Deleted';

        Map<String, Date> mapDateValues = getDateFilters(searchParams);
        System.debug('mapDateValues: ' + mapDateValues);

        Date datFromDate = mapDateValues.get('datFromDate');
        Date datToDate = mapDateValues.get('datToDate');
        System.debug('datFromDate: ' + datFromDate);
        System.debug('datToDate: ' + datToDate);

        String strQuery =
            'SELECT Id,PMC_CPQ_LinePONumber__c,PMC_CPQ_SAPOrderLineID__c, ' +
            'Order.OrderNumber,Order.Contract.SBQQ__Quote__r.PMC_CPQ_SAPContractReference__c,' +
            'Order.Contract.SBQQ__Quote__c, Order.PMC_CPQ_SAPOrderNumber__c, ' +
            'Order.PMC_DH_SAPOrderCreatedDate__c,';
        strQuery +=
            ' (SELECT Id, PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c,' +
            'PMC_CPQ_Invoice__r.Nota_Fiscal_Number__c, ' +
            'PMC_CPQ_Invoice__r.PMC_DH_SAPInvoiceCreatedDate__c,' +
            'PMC_CPQ_Invoice__r.PMC_CPQ_BillingDocType__c,' +
            'PMC_CPQ_Invoice__r.PMC_CPQ_Delivery__r.Status,' +
            'PMC_CPQ_DeliveryItem__r.Shipment.Insp_Lot_Usage_Decision__c,' +
            'PMC_CPQ_DeliveryItem__r.Shipment.PMC_CPQ_SAPDeliveryID__c, ' +
            'PMC_CPQ_DeliveryItem__r.PMC_CPQ_DeliveryItemID__c ' +
            'FROM InvoiceItems__r ' +
            'WHERE PMC_CPQ_Invoice__r.PMC_DH_SAPInvoiceCreatedDate__c >= ' +
            String.valueOf(datFromDate) +
            ' AND PMC_CPQ_Invoice__r.PMC_DH_SAPInvoiceCreatedDate__c <= ' +
            String.valueOf(datToDate) +
            ' AND PMC_CPQ_Invoice__r.PMC_CPQ_Delivery__r.Status!=\'Delivery Deleted\'),';
        strQuery +=
            ' (SELECT Id, Shipment.ShipmentNumber, Shipment.PMC_CPQ_SAPDeliveryID__c, ' +
            'ShipmentItemNumber, ShipmentItem.PMC_CPQ_DeliveryItemID__c, ' +
            'Shipment.PMC_DH_SAPDeliveryCreatedDate__c, Shipment.PMC_CPQ_VehicleID__c, ' +
            'Shipment.Insp_Lot_Usage_Decision__c ' +
            'FROM Delivery_Items__r ' +
            'WHERE Shipment.PMC_DH_SAPDeliveryCreatedDate__c >= ' +
            String.valueOf(datFromDate) +
            ' AND Shipment.PMC_DH_SAPDeliveryCreatedDate__c <= ' +
            String.valueOf(datToDate) +
            ')';
        strQuery += ' FROM OrderItem WHERE Order.AccountId = :strEffectiveAccId AND Order.PMC_DH_SAPOrderCreatedDate__c != null';
        strQuery += ' AND Order.PMC_DH_OrderTypeCode__c IN ';
        strQuery += Label.PMC_DH_OrderTypesForDocuments;
        System.debug('Initial strQuery: ' + strQuery);

        String InitQuery = strQuery;
        String queryRes = strQuery + ' WITH SYSTEM_MODE Order BY Order.PMC_DH_SAPOrderCreatedDate__c DESC LIMIT 500'.replace('\\', '');

        List<OrderItem> lstDocument = new List<OrderItem>();

        // Cenário sem searchTerm: usa só a query base limitada a 500
        if (searchParams == null || String.isBlank(searchParams.strSearchTerm)) {
            System.debug('No search term. Running base query only (current year, max 500)...');
            for (OrderItem oi : Database.query(queryRes)) {
                lstDocument.add(oi);
            }
            System.debug('Exiting getDocumentSearchQuery (no search term), rows: ' + lstDocument.size());
            return lstDocument;
        }

        Map<Id, OrderItem> finalMapFromList = new Map<Id, OrderItem>(lstDocument);

        String strSearchPattern3;
        if (String.isNotBlank(searchParams.strSearchTerm)) {
            System.debug('searchParams.strSearchTerm is not blank: ' + searchParams.strSearchTerm);

            String strSearchPattern = searchParams.strSearchTerm;
            System.debug('strSearchPattern: ' + strSearchPattern);

            List<String> lstSearchPatterns = strSearchPattern.split('_');
            System.debug('lstSearchPatterns: ' + lstSearchPatterns);

            String strSearchPattern1;
            String strSearchPattern2;

            if (lstSearchPatterns.size() > 1) {
                strSearchPattern3 = lstSearchPatterns[0];
                strSearchPattern1 = '\'%' + String.escapeSingleQuotes(strSearchPattern) + '%\'';
                strSearchPattern2 = '\'%' + String.escapeSingleQuotes(lstSearchPatterns[1]) + '%\'';
                if ((String.escapeSingleQuotes(lstSearchPatterns[1])).length() < 4) {
                    strSearchPattern2 = strSearchPattern1;
                }
                System.debug('strSearchPattern3: ' + strSearchPattern3);
                System.debug('strSearchPattern1: ' + strSearchPattern1);
                System.debug('strSearchPattern2: ' + strSearchPattern2);
            } else {
                strSearchPattern2 = '\'%' + String.escapeSingleQuotes(lstSearchPatterns[0]) + '%\'';
                strSearchPattern1 = '\'%' + String.escapeSingleQuotes(strSearchPattern) + '%\'';
                System.debug('Single search pattern, strSearchPattern1: ' + strSearchPattern2);
            }

            Map<String, String> mapOfAllDocTypes = getMapOfAllDocTypes();
            System.debug('mapOfAllDocTypes: ' + mapOfAllDocTypes);

            // Busca por ShipmentItem (Delivery / Vehicle / DeliveryItemID)
            String strQuery1 =
                InitQuery +
                ' AND (Id IN(SELECT PMC_CPQ_OrderProduct__c FROM ShipmentItem ' +
                'WHERE Shipment.PMC_CPQ_SAPDeliveryID__c LIKE ' +
                strSearchPattern2 +
                ' OR ShipmentItem.PMC_CPQ_DeliveryItemID__c LIKE ' +
                strSearchPattern2 +
                ' OR Shipment.PMC_CPQ_VehicleID__c LIKE ' +
                strSearchPattern2 +
                '))';
            String queryRes1 = strQuery1 + ' WITH SYSTEM_MODE Order BY Order.PMC_DH_SAPOrderCreatedDate__c DESC LIMIT 500'.replace('\\', '');
            List<OrderItem> lstDocument1 = Database.query(queryRes1);
            Map<Id, OrderItem> MapFromList1 = new Map<Id, OrderItem>(lstDocument1);
            finalMapFromList.putAll(MapFromList1);
            strQuery1 = '';

            // Busca por InvoiceItem (InvoiceNumber / Nota Fiscal)
            strQuery1 =
                InitQuery +
                ' AND (Id IN(SELECT PMC_CPQ_OrderProduct__c FROM PMC_CPQ_InvoiceItem__c ' +
                'WHERE (PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c LIKE ' +
                strSearchPattern2 +
                ') OR (PMC_CPQ_Invoice__r.Nota_Fiscal_Number__c LIKE ' +
                strSearchPattern2 +
                ')))';

            String queryRes3 = strQuery1 + ' WITH SYSTEM_MODE Order BY Order.PMC_DH_SAPOrderCreatedDate__c DESC LIMIT 500'.replace('\\', '');
            lstDocument = Database.query(queryRes3);
            strQuery1 = '';
            Map<Id, OrderItem> MapFromList2 = new Map<Id, OrderItem>(lstDocument);
            finalMapFromList.putAll(MapFromList2);

            // Remove duplicados por InvoiceNumber
            Map<String, OrderItem> uniqueInvoices = new Map<String, OrderItem>();
            for (OrderItem oi : finalMapFromList.values()) {
                if (oi.InvoiceItems__r != null && !oi.InvoiceItems__r.isEmpty()) {
                    String invNum = oi.InvoiceItems__r[0].PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c;
                    if (String.isNotBlank(invNum) && !uniqueInvoices.containsKey(invNum)) {
                        uniqueInvoices.put(invNum, oi);
                    }
                }
            }
            lstDocument = new List<OrderItem>(uniqueInvoices.values());

            // Busca por Order / Quote / PO / SAP Order Line ID
            strQuery1 = InitQuery + ' AND ((Order.PMC_CPQ_SAPOrderNumber__c LIKE ' + strSearchPattern2 + ')';
            strQuery1 += ' OR (Order.Contract.SBQQ__Quote__r.PMC_CPQ_SAPContractReference__c LIKE ' + strSearchPattern2 + ')';
            strQuery1 += ' OR (Order.Contract.SBQQ__Quote__r.Name LIKE ' + strSearchPattern2 + ')';
            strQuery1 += ' OR (PMC_CPQ_LinePONumber__c LIKE ' + strSearchPattern2 + ')';
            strQuery1 += ' OR (PMC_CPQ_SAPOrderLineID__c LIKE ' + strSearchPattern1 + '))';

            String queryRes2 = strQuery1 + ' WITH SYSTEM_MODE Order BY Order.PMC_DH_SAPOrderCreatedDate__c DESC LIMIT 500'.replace('\\', '');
            lstDocument = Database.query(queryRes2);
            strQuery1 = '';
            Map<Id, OrderItem> MapFromList3 = new Map<Id, OrderItem>(lstDocument);
            finalMapFromList.putAll(MapFromList3);
            strSearchPattern123 = strSearchPattern2;
        }

        Set<Id> allIds = finalMapFromList.keySet();
        Boolean isInvoicetheSearchterm = false;

        if (!String.isBlank(strSearchPattern123)) {
            List<OrderItem> orderItemsList = [
                SELECT Id, OrderId
                FROM OrderItem
                WHERE Id IN :allIds
            ];

            Set<Id> OrdersSet = new Set<Id>();
            for (OrderItem o : orderItemsList) {
                OrdersSet.add(o.OrderId);
            }

            List<PMC_CPQ_Invoice__c> invoiceList = [
                SELECT Id, Nota_Fiscal_Number__c, PMC_CPQ_Order__c, PMC_CPQ_InvoiceNumber__c
                FROM PMC_CPQ_Invoice__c
                WHERE PMC_CPQ_Order__c IN :OrdersSet
            ];

            for (PMC_CPQ_Invoice__c i : invoiceList) {
                String NotaFiscal = i.Nota_Fiscal_Number__c;
                String InvoiceNum = i.PMC_CPQ_InvoiceNumber__c;

                Integer patternsize = strSearchPattern123.length();
                String finalSearchTerm = strSearchPattern123.substring(2, patternsize - 2);

                if (String.isNotBlank(NotaFiscal)) {
                    if (NotaFiscal.contains(finalSearchTerm) || InvoiceNum.contains(finalSearchTerm)) {
                        isInvoicetheSearchterm = true;
                    }
                }
            }
        }

        InitQuery += 'AND ID IN:allIds WITH SYSTEM_MODE Order BY Order.PMC_DH_SAPOrderCreatedDate__c DESC LIMIT 500';
        System.debug('Final strQuery: ' + InitQuery);
        String queryResFinal = InitQuery.replace('\\', '');
        List<OrderItem> lstDocumentFinal = new List<OrderItem>();

        if (isInvoicetheSearchterm) {
            String Seperatr = 'InvoiceItems__r WHERE';
            String MyQuery =
                'InvoiceItems__r WHERE (PMC_CPQ_Invoice__r.Nota_Fiscal_Number__c Like' +
                strSearchPattern123 +
                ' OR PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c Like' +
                strSearchPattern123 +
                ') AND ';
            String queryResFinal2 = queryResFinal.substringBefore(Seperatr) + MyQuery + queryResFinal.substringAfter(Seperatr);
            queryResFinal = queryResFinal2;
        }

        lstDocumentFinal = Database.query(queryResFinal);

        // Limita em 500 sem usar subList
        if (lstDocumentFinal.size() > 500) {
            List<OrderItem> limitedList = new List<OrderItem>();
            Integer maxSize = 500;
            for (Integer i = 0; i < maxSize; i++) {
                limitedList.add(lstDocumentFinal[i]);
            }
            lstDocumentFinal = limitedList;
        }

        System.debug('Exiting getDocumentSearchQuery... rows=' + lstDocumentFinal.size());
        return lstDocumentFinal;
    }

    /**
     * @description       : Class for get Map of All Doc Types From Custom Metadata
     * @author            : @Mosaic Direct Dev
     * @Created on        : 10-29-2023
     * @return            : Map<String, String>
     **/
    public static Map<String, String> getMapOfAllDocTypes() {
        return getMapOfAllDocTypes(null); // Overloaded method called with null for default behavior
    }

    public static Map<String, String> getMapOfAllDocTypes(Map<String, PMC_DH_DocumentType__mdt> mockMetadata) {
        Map<String, PMC_DH_DocumentType__mdt> mapDocTypeMetadata =
            (mockMetadata != null) ? mockMetadata : getDocTypeMetadataCache();
        Map<String, String> mapDocTypes = new Map<String, String>();

        for (PMC_DH_DocumentType__mdt mdt : mapDocTypeMetadata.values()) {
            mapDocTypes.put(mdt.DeveloperName, mdt.Label);
        }

        return mapDocTypes;
    }

    public static Map<String, Date> getDateFilters(PMC_DH_DocumentSearchParameterWrapper searchParams) {
        Map<String, Date> mapValues = new Map<String, Date>();

        if (searchParams != null && searchParams.datFromDate != null && searchParams.datToDate != null) {
            mapValues.put('datFromDate', searchParams.datFromDate);
            mapValues.put('datToDate', searchParams.datToDate);
        } else {
            Date today = Date.today();
            Date startOfYear = Date.newInstance(today.year(), 1, 1);
            mapValues.put('datFromDate', startOfYear);
            mapValues.put('datToDate', today);
        }

        return mapValues;
    }

    public static List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> getDocumentsbyDocType(
        List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> lstDocumentInfoWrapper,
        PMC_DH_DocumentSearchParameterWrapper searchParams
    ) {
        List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> lstDocumentInfo =
            new List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper>();

        if (String.isNotBlank(searchParams.documentType)) {
            String strSearchPatternInput = searchParams.documentType;
            List<String> lstSearchPatterns = new List<String>();
            lstSearchPatterns = strSearchPatternInput.split('_');
            String strSearchPattern = lstSearchPatterns[0];

            Map<String, PMC_DH_DocumentType__mdt> mapDocTypeMetadata = getDocTypeMetadataCache();
            Map<String, String> mapTypes = getMapOfAllDocTypes(mapDocTypeMetadata);

            for (PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docInfo : lstDocumentInfoWrapper) {
                if (docInfo.strDocumentType == mapTypes.get(strSearchPattern)) {
                    lstDocumentInfo.add(docInfo);
                }
            }
        }
        if (lstDocumentInfo.isEmpty()) {
            lstDocumentInfo.addAll(lstDocumentInfoWrapper);
        }
        return lstDocumentInfo;
    }

    public static List<PMC_DH_PicklistWrapper> getDocTypes(
        List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> lstDocumentWrapper,
        PMC_DH_DocumentSearchParameterWrapper searchParams
    ) {
        List<PMC_DH_PicklistWrapper> lstTotalDocTypes = new List<PMC_DH_PicklistWrapper>();
        if (String.isNotBlank(searchParams.strSearchTerm)) {
            String strSearchPatternInput = searchParams.strSearchTerm;
            List<String> lstSearchPatterns = new List<String>();
            lstSearchPatterns = strSearchPatternInput.split('_');
            String strSearchPattern = lstSearchPatterns[0];
            for (PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper doctype : lstDocumentWrapper) {
                PMC_DH_PicklistWrapper documentWrapper = new PMC_DH_PicklistWrapper();
                if (doctype.strDocumentType == strSearchPattern) {
                    documentWrapper.label = doctype.strDocumentType;
                    documentWrapper.value = doctype.strDocumentType;
                    lstTotalDocTypes.add(documentWrapper);
                }
            }
        }
        if (lstTotalDocTypes.isEmpty()) {
            for (PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper doctype : lstDocumentWrapper) {
                PMC_DH_PicklistWrapper documentWrapper = new PMC_DH_PicklistWrapper();
                documentWrapper.label = doctype.strDocumentType;
                documentWrapper.value = doctype.strDocumentType;
                lstTotalDocTypes.add(documentWrapper);
            }
        }
        return lstTotalDocTypes;
    }

    public static PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper getDocTypeInfo(
        PMC_DH_DocumentType__mdt mdt,
        PMC_CPQ_InvoiceItem__c invItem
    ) {
        PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper docIdWrapper =
            new PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper();

        Map<String, PMC_DH_DocumentType__mdt> mapDocTypeMetadata = getDocTypeMetadataCache();
        PMC_DH_DocumentType__mdt mdtQD = mapDocTypeMetadata.get('QualityDocument');
        System.debug('mdt nota' + mdt);
        System.debug('mdtQD' + mdtQD);

        Map<String, String> qualityIdentifierNameToValue = new Map<String, String>();

        if (mdt != null) {
            docIdWrapper.strIdentifierType = mdt.PMC_DH_Identifier__c;
            docIdWrapper.strDocCode = mdt.PMC_DH_DocumentCode__c;
            docIdWrapper.strDocType = mdt.Label;
            docIdWrapper.inspLotUsageDecision = invItem.PMC_CPQ_DeliveryItem__r.Shipment.Insp_Lot_Usage_Decision__c;
        }

        if (invItem != null && invItem.PMC_CPQ_Invoice__r != null) {
            docIdWrapper.datIdentifierDate = invItem.PMC_CPQ_Invoice__r.PMC_DH_SAPInvoiceCreatedDate__c;
            docIdWrapper.strInvNumber = invItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c;

            Map<String, String> mapIdentifierNameToValue = new Map<String, String>();
            mapIdentifierNameToValue.put(
                mdt.PMC_DH_Identifier__c,
                invItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c
            );
            docIdWrapper.mapIdentifier = mapIdentifierNameToValue;

            Map<String, String> notaIdentifierNameToValue = new Map<String, String>();
            notaIdentifierNameToValue.put(
                mdt.PMC_DH_Identifier__c,
                invItem.PMC_CPQ_Invoice__r.Nota_Fiscal_Number__c
            );

            String strIdentifierType = mdtQD.PMC_DH_Identifier__c.split(';')[1];
            qualityIdentifierNameToValue.put(
                mdtQD.PMC_DH_Identifier__c.split(';')[0],
                invItem.PMC_CPQ_DeliveryItem__r.Shipment.PMC_CPQ_SAPDeliveryID__c
            );
            qualityIdentifierNameToValue.put(
                strIdentifierType,
                invItem.PMC_CPQ_DeliveryItem__r.PMC_CPQ_DeliveryItemID__c
            );

            docIdWrapper.notaIdentifier = notaIdentifierNameToValue;
            docIdWrapper.qDIdentifier = qualityIdentifierNameToValue;
        }
        System.debug('docIdWrapper' + docIdWrapper.qDIdentifier);
        return docIdWrapper;
    }

    public static PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper getDocTypeInfo(
        PMC_DH_DocumentType__mdt mdt,
        ShipmentItem shipmentItem
    ) {
        PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper docIdWrapper =
            new PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper();
        Map<String, String> mapIdentifierNameToValue = new Map<String, String>();

        System.debug('--- Processing shipmentItem: ' + JSON.serialize(shipmentItem));
        docIdWrapper.strDocCode = mdt.PMC_DH_DocumentCode__c;
        docIdWrapper.strDocType = mdt.Label;
        docIdWrapper.inspLotUsageDecision = String.isBlank(shipmentItem.Shipment.Insp_Lot_Usage_Decision__c)
            ? 'Not Approved'
            : shipmentItem.Shipment.Insp_Lot_Usage_Decision__c;
        docIdWrapper.datIdentifierDate = shipmentItem.Shipment.PMC_DH_SAPDeliveryCreatedDate__c;

        if (mdt.PMC_DH_DocumentCode__c == 'BOL') {
            docIdWrapper.strIdentifierType = mdt.PMC_DH_Identifier__c;
            mapIdentifierNameToValue.put(
                mdt.PMC_DH_Identifier__c,
                shipmentItem.Shipment.PMC_CPQ_SAPDeliveryID__c
            );
        } else {
            String strIdentifierType = mdt.PMC_DH_Identifier__c.split(';')[1];
            docIdWrapper.strIdentifierType = strIdentifierType;
            mapIdentifierNameToValue.put(
                mdt.PMC_DH_Identifier__c.split(';')[0],
                shipmentItem.Shipment.PMC_CPQ_SAPDeliveryID__c
            );
            mapIdentifierNameToValue.put(
                strIdentifierType,
                shipmentItem.PMC_CPQ_DeliveryItemID__c
            );
        }

        docIdWrapper.mapIdentifier = mapIdentifierNameToValue;
        return docIdWrapper;
    }

    public static Map<String, Map<String, List<PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper>>> getMiddleMap(
        Map<String, Map<String, List<PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper>>> mapIdentifierToInnerMap,
        Map<String, List<PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper>> mapIdentifierToList,
        PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper doc
    ) {
        String strIdentifierValue = doc.mapIdentifier.get(doc.strIdentifierType);
        if (!mapIdentifierToInnerMap.containsKey(doc.strIdentifierType)) {
            mapIdentifierToInnerMap.put(
                doc.strIdentifierType,
                new Map<String, List<PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper>>{
                    strIdentifierValue =>
                        new List<PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper>{ doc }
                }
            );
        } else {
            List<PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper> lstDocWrapper =
                mapIdentifierToList.get(strIdentifierValue);
            Map<String, List<PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper>> mapIdToList =
                new Map<String, List<PMC_DH_DocumentListViewController.PMC_DH_DocIdentifierWrapper>>{
                    strIdentifierValue => lstDocWrapper
                };
            mapIdentifierToInnerMap.put(doc.strIdentifierType, mapIdToList);
        }
        return mapIdentifierToInnerMap;
    }

    public static Map<String, List<String>> getIdentifierToDocTypeMap(List<PMC_DH_DocumentType__mdt> lstMetadata) {
        Map<String, List<String>> mapIdentifierToDocType = new Map<String, List<String>>();
        for (PMC_DH_DocumentType__mdt mdt : lstMetadata) {
            List<String> lstDocTypes;
            if (mapIdentifierToDocType.get(mdt.PMC_DH_Identifier__c) == null) {
                lstDocTypes = new List<String>();
            } else {
                lstDocTypes = mapIdentifierToDocType.get(mdt.PMC_DH_Identifier__c);
            }
            lstDocTypes.add(mdt.DeveloperName);
            mapIdentifierToDocType.put(mdt.PMC_DH_Identifier__c, lstDocTypes);
        }
        return mapIdentifierToDocType;
    }

    public class PMC_DH_DocumentSearchParameterWrapper {
        @AuraEnabled
        public String strSearchTerm { get; set; }
        @AuraEnabled
        public String documentType { get; set; }
        @AuraEnabled
        public Date datFromDate { get; set; }
        @AuraEnabled
        public Date datToDate { get; set; }
    }
}