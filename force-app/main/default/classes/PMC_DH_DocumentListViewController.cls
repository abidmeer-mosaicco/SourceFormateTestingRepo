/**
* @description       : Controller for fetching Document History
* @author            : @Nikhilesh
* @last modified on 02-05-2024
* @last modified by Nikhilesh Mohanty
* @Created on        : 10-19-2023
**/
public without sharing class PMC_DH_DocumentListViewController {
    // private static final List<String> NA_COUNTRIES = new List<String>{'United States', 'Canada'};
    // private static final String BRAZIL_COUNTRY = 'Brazil';
    /**
* @description   : To fetch the Document records
* @return        : PMC_DH_DocumentListViewWrapper
* @param           searchParams
* @param           strEffectiveAccId
* @author        : @Nikhilesh
*/
    @AuraEnabled
    public static PMC_DH_DocumentListViewWrapper fetchDocumentRecords(PMC_DH_DocumentListViewHelper.PMC_DH_DocumentSearchParameterWrapper searchParams, String strEffectiveAccId){
        PMC_DH_DocumentListViewWrapper docWrapper = new PMC_DH_DocumentListViewWrapper();
        try{
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            Set<String> setDocNames = new Set<String>();
          //  String strQuery = PMC_DH_DocumentListViewHelper.getDocumentSearchQuery(searchParams, strEffectiveAccId);
            //String queryRes = strQuery.replace('\\', '');
                List<OrderItem> lstDocument  =PMC_DH_DocumentListViewHelper.getDocumentSearchQuery(searchParams, strEffectiveAccId);

            //lstDocument = Database.query(String.escapeSingleQuotes(queryRes).replace('\\', ''));
            // added espace single quotes in the getDocumentSearchQuery method.
           // lstDocument = Database.query(queryRes);
            
            // Fetch all the custom metadata records
            // Create a List<String> to store the Document Codes
            // Create a map where label = Identifier and value = List<String>
            // Iterate through each metadata record and populate the map accordingly
            
            Map<String, PMC_DH_DocumentType__mdt> mapDocTypeMetadata = PMC_DH_DocumentType__mdt.getAll();
            //List<PMC_DH_DocumentType__mdt> lstMetadata = mapDocTypeMetadata.values();            
            
            
            // List<Wrapper> to contain 3 values: 
            // 1. Identifier Type (eg - Billing Document Number)
            // 2. Identifier value (eg - ShipmentItemNumber value = 00001)
            // 3. Added Date of Shipment/Invoice Item (the PMC_DH fields which SAP will populate)
            
            // Innermost map to have key = Identifier (eg - Shipment Item Number) and value = List<Wrapper>
            
            // Next, we will create a second map (let's call it middle map).
            // Middle map to have key = Identifier type (eg - Billing Document Number) and value = innermost map
            
            // Finally, we have a third map (let's call it the final map).
            // Final map to have key = order number and value = middle map
            
            List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> lstDocInfoWrapper = getDocumentRecordsMap(lstDocument, mapDocTypeMetadata, setDocNames);
            List<PMC_DH_PicklistWrapper> lstTotalDocTypes = PMC_DH_DocumentListViewHelper.getDocTypes(lstDocInfoWrapper, searchParams);
            docWrapper.lstDocumentTypes = lstTotalDocTypes;
            docWrapper.lstDocuments = PMC_DH_DocumentListViewHelper.getDocumentsbyDocType(lstDocInfoWrapper, searchParams);
            // --- FINAL global dedupe by strInvoiceNumber ---
System.debug('@@ Starting final global dedupe: total before=' + docWrapper.lstDocuments.size());

Set<String> seenInvoiceNums = new Set<String>();
List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> finalDedupedList = new List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper>();

for (PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper d : docWrapper.lstDocuments) {
    System.debug('@@ RAW InvoiceNumber: " ' + d.strInvoiceNumber + '"');
    if (String.isNotBlank(d.strInvoiceNumber)) {
        if (!seenInvoiceNums.contains(d.strInvoiceNumber)) {
            seenInvoiceNums.add(d.strInvoiceNumber);
            finalDedupedList.add(d);
            System.debug('@@ Keeping InvoiceNumber: ' + d.strInvoiceNumber);
        } else {
            System.debug('@@ Removing duplicate InvoiceNumber: ' + d.strInvoiceNumber);
        }
    } else {
        finalDedupedList.add(d); // Keep if no invoice number
        System.debug('@@ Keeping (no invoice number): ' + d.strDocumentName);
    }
}
docWrapper.lstDocuments = finalDedupedList;
System.debug('@@ Final Deduped List Size: ' + docWrapper.lstDocuments.size());
 
            docWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'DocumentRecord');
            
            
        }
        catch(Exception ex){
            docWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
            PMC_ErrorLogClass.processException(ex); // MDErrorLog
            //throw new AuraHandledException(ex.getMessage()+ex.getStackTraceString());
        }
        // --- Exact match filter for Invoice Number ---
        String searchTerm = searchParams != null ? searchParams.strSearchTerm : null;
        if (String.isNotBlank(searchTerm)) {
            // Clean up spaces just in case
            String cleanSearch = searchTerm.trim();
            List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> exactFiltered = new List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper>();
          if( docWrapper.lstDocuments.size()>0)
          {
            for (PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper d : docWrapper.lstDocuments) {
                if (String.isNotBlank(d.strInvoiceNumber) && d.strInvoiceNumber.trim() == cleanSearch) {
                    exactFiltered.add(d);
                }
            }
          }
            
            
            // If we found exact matches, replace the list with only those
            if (!exactFiltered.isEmpty()) {
                System.debug('@@ Exact InvoiceNumber match found. Filtering from ' + docWrapper.lstDocuments.size() + ' down to ' + exactFiltered.size() + ' records.');
                docWrapper.lstDocuments = exactFiltered;
            }
        }
        return docWrapper;
    }
    
    private static List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> getDocumentRecordsMap(List<OrderItem> lstDocument, Map<String, PMC_DH_DocumentType__mdt> mapDocTypeMetadata, Set<String> setDocNames){
        Map<String, Map<String, Map<String, List<PMC_DH_DocIdentifierWrapper>>>> mapRecords = new Map<String, Map<String, Map<String, List<PMC_DH_DocIdentifierWrapper>>>>();
        List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> lstDocInfoWrapper = new List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper>();
        String strCountry = getUserCountry();
        // From user's country (United States/Canada/Brazil), get the region (NA/BR)
        String strRegion = PMC_DH_CommonSystemUtils.getUserRegion(strCountry); //GPT-44509
        for(OrderItem oi : lstDocument){    
            Map<String, Map<String, List<PMC_DH_DocIdentifierWrapper>>> mapIdentifierToInnerMap = new Map<String, Map<String, List<PMC_DH_DocIdentifierWrapper>>>();
            Map<String, List<PMC_DH_DocIdentifierWrapper>> mapIdentifierToList = new Map<String, List<PMC_DH_DocIdentifierWrapper>>();
            
            PMC_DH_RecordParamsWrapper wrpParams = new PMC_DH_RecordParamsWrapper();
            wrpParams.orderItem = oi;
            wrpParams.mapDocTypeMetadata = mapDocTypeMetadata;
            wrpParams.mapIdentifierToList = mapIdentifierToList;
            wrpParams.strCountry = strRegion; //GPT-44509
            
            mapIdentifierToList = getInvoiceRecords(wrpParams);
            mapIdentifierToList = getShipmentRecords(wrpParams);
            
            // Next, traverse through the list in the innermost map
            // Based on the Identifier, populate the middle map 
            List<PMC_DH_DocIdentifierWrapper> lstValues = new List<PMC_DH_DocIdentifierWrapper>();
            for(List<PMC_DH_DocIdentifierWrapper> wrp : mapIdentifierToList.values()){
                lstValues.addAll(wrp);
            }
            for(PMC_DH_DocIdentifierWrapper doc : lstValues){
                mapIdentifierToInnerMap = PMC_DH_DocumentListViewHelper.getMiddleMap(mapIdentifierToInnerMap, mapIdentifierToList, doc);
                // check if document name is duplicate
                // if not, assign the values to the wrapper attributes
                String docName = doc.strDocType + '_' + doc.mapIdentifier.get(doc.strIdentifierType) + '_' + oi.Order.PMC_CPQ_SAPOrderNumber__c;
                if(!setDocNames.contains(docName)){
                    setDocNames.add(docName);
                    lstDocInfoWrapper = addDocWrapperToList(lstDocInfoWrapper, doc, oi);
                }
            }
            mapRecords.put(oi.Order.OrderNumber, mapIdentifierToInnerMap);
        }
        return lstDocInfoWrapper;
    }
    
    private static String getUserCountry(){
        String strCountry = [SELECT Id, Country FROM User WHere Id =: UserInfo.getUserId() WITH USER_MODE LIMIT 1].Country;
        return strCountry;
    }
    
    private static Map<String, List<PMC_DH_DocIdentifierWrapper>> getInvoiceRecords(PMC_DH_RecordParamsWrapper wrpParams){
        List<PMC_DH_DocumentType__mdt> lstMetadata = wrpParams.mapDocTypeMetadata.values();
        Map<String, List<String>> mapIdentifierToDocType = PMC_DH_DocumentListViewHelper.getIdentifierToDocTypeMap(lstMetadata);
        for(PMC_CPQ_InvoiceItem__c invItem : wrpParams.orderItem.InvoiceItems__r){
            // When we have identifier = Billing Document Number, we have 4 document types:
            // CreditMemo, DebitMemo, Invoice, NotaFiscal
            List<String> lstDocTypes = mapIdentifierToDocType.get('strBillingDocNumber');
            if(invItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c != null && invItem.PMC_CPQ_Invoice__r.PMC_DH_SAPInvoiceCreatedDate__c != null && invItem.PMC_CPQ_Invoice__r.PMC_CPQ_BillingDocType__c != null){
                for(String docType : lstDocTypes){
                    PMC_DH_DocumentType__mdt mdt = wrpParams.mapDocTypeMetadata.get(docType);
                    getInvRecords(wrpParams, mdt, invItem);
                }
            }
        }
        return wrpParams.mapIdentifierToList;
    }
    
    private static Map<String, List<PMC_DH_DocIdentifierWrapper>> getInvRecords(PMC_DH_RecordParamsWrapper wrpParams, PMC_DH_DocumentType__mdt mdt, PMC_CPQ_InvoiceItem__c invItem){
		// changes added by Nikhilesh
        if(mdt.PMC_DH_Billing_Type__c != null){
            List<String> lstBillingTypes = mdt.PMC_DH_Billing_Type__c.split(';');
            // Get the list of regions for which the document is available
            List<String> lstRegions = mdt.PMC_DH_Region__c.split(';'); //GPT-44509
            if(lstBillingTypes.size() > 0 && lstBillingTypes.contains(invItem.PMC_CPQ_Invoice__r.PMC_CPQ_BillingDocType__c) 
               && (lstRegions.contains(wrpParams.strCountry))){
                 //check if user's region matches the document's region
                PMC_DH_DocIdentifierWrapper docIdWrapper = PMC_DH_DocumentListViewHelper.getDocTypeInfo(mdt, invItem);
                wrpParams.mapIdentifierToList = addToIdentifierListMap(wrpParams.mapIdentifierToList, invItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c, docIdWrapper);
            }
            /* if(lstBillingTypes.size() > 0 && lstBillingTypes.contains(invItem.PMC_CPQ_Invoice__r.PMC_CPQ_BillingDocType__c) 
               && ((mdt.PMC_DH_DocumentCode__c == 'NFE' && !NA_COUNTRIES.contains(wrpParams.strCountry)) || mdt.PMC_DH_DocumentCode__c != 'NFE')){ //(mdt.PMC_DH_DocumentCode__c == 'INV' && !BRAZIL_COUNTRY.contains(wrpParams.strCountry)))
                PMC_DH_DocIdentifierWrapper docIdWrapper = PMC_DH_DocumentListViewHelper.getDocTypeInfo(mdt, invItem);
                wrpParams.mapIdentifierToList = addToIdentifierListMap(wrpParams.mapIdentifierToList, invItem.PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c, docIdWrapper);
            } */
        }
        return wrpParams.mapIdentifierToList;
    }    
    
    private static Map<String, List<PMC_DH_DocIdentifierWrapper>> getShipmentRecords(PMC_DH_RecordParamsWrapper wrpParams){
        for(ShipmentItem si : wrpParams.orderItem.Delivery_Items__r){
            // When we have Delivery Number, Document Type = 'Bill of Lading'
            // When we have Delivery Item Number (and Delivery Number), Document Type = 'Certificate of Analysis'
            // Create a map with key = Identifier Type and value = List<Wrapper>
            // NOTE: Use Identifier Type to fetch metadata records 
            
            // First, let us populate the wrapper for BOL values    
            // GPT-44509
            PMC_DH_DocumentType__mdt mdtBOL = wrpParams.mapDocTypeMetadata.get('BillOfLading');
            List<String> lstBOLRegions = mdtBOL.PMC_DH_Region__c.split(';');
            if(si.Shipment.PMC_CPQ_SAPDeliveryID__c != null && si.Shipment.PMC_DH_SAPDeliveryCreatedDate__c != null && lstBOLRegions.contains(wrpParams.strCountry)){ //&& NA_COUNTRIES.contains(wrpParams.strCountry)
                //PMC_DH_DocumentType__mdt mdtBOL = wrpParams.mapDocTypeMetadata.get('BillOfLading'); //should not be hardcoded, check with Siddharth
                PMC_DH_DocIdentifierWrapper docBOLWrapper = PMC_DH_DocumentListViewHelper.getDocTypeInfo(mdtBOL, si);
                wrpParams.mapIdentifierToList = addToIdentifierListMap(wrpParams.mapIdentifierToList, si.Shipment.PMC_CPQ_SAPDeliveryID__c, docBOLWrapper);
                
                // Next, let us populate the wrapper for COA values
                PMC_DH_DocumentType__mdt mdtCOA = wrpParams.mapDocTypeMetadata.get('CertificateOfAnalysis');
                List<String> lstCOARegions = mdtCOA.PMC_DH_Region__c.split(';');
                if(si.PMC_CPQ_DeliveryItemID__c != null && lstCOARegions.contains(wrpParams.strCountry)){
                    //PMC_DH_DocumentType__mdt mdtCOA = wrpParams.mapDocTypeMetadata.get('CertificateOfAnalysis'); //should not be hardcoded, check with Siddharth
                    PMC_DH_DocIdentifierWrapper docCOAWrapper = PMC_DH_DocumentListViewHelper.getDocTypeInfo(mdtCOA, si);
                    wrpParams.mapIdentifierToList = addToIdentifierListMap(wrpParams.mapIdentifierToList, si.PMC_CPQ_DeliveryItemID__c, docCOAWrapper);
                }
            }
            
			/* if(si.Shipment.PMC_CPQ_SAPDeliveryID__c != null && si.Shipment.PMC_DH_SAPDeliveryCreatedDate__c != null){ //&& NA_COUNTRIES.contains(wrpParams.strCountry)
                PMC_DH_DocumentType__mdt mdtBOL = wrpParams.mapDocTypeMetadata.get('BillOfLading'); //should not be hardcoded, check with Siddharth
                PMC_DH_DocIdentifierWrapper docBOLWrapper = PMC_DH_DocumentListViewHelper.getDocTypeInfo(mdtBOL, si);
                wrpParams.mapIdentifierToList = addToIdentifierListMap(wrpParams.mapIdentifierToList, si.Shipment.PMC_CPQ_SAPDeliveryID__c, docBOLWrapper);
                
                // Next, let us populate the wrapper for COA values
                if(si.PMC_CPQ_DeliveryItemID__c != null && NA_COUNTRIES.contains(wrpParams.strCountry)){
                    PMC_DH_DocumentType__mdt mdtCOA = wrpParams.mapDocTypeMetadata.get('CertificateOfAnalysis'); //should not be hardcoded, check with Siddharth
                    PMC_DH_DocIdentifierWrapper docCOAWrapper = PMC_DH_DocumentListViewHelper.getDocTypeInfo(mdtCOA, si);
                    wrpParams.mapIdentifierToList = addToIdentifierListMap(wrpParams.mapIdentifierToList, si.PMC_CPQ_DeliveryItemID__c, docCOAWrapper);
                }
            } */			
            
        }
        return wrpParams.mapIdentifierToList;
    }
    
    private static Map<String, List<PMC_DH_DocIdentifierWrapper>> addToIdentifierListMap(Map<String, List<PMC_DH_DocIdentifierWrapper>> mapIdentifierToList, String strIdentifier, PMC_DH_DocIdentifierWrapper docIdWrapper){
        if(!mapIdentifierToList.containsKey(strIdentifier))
        {
            mapIdentifierToList.put(strIdentifier,new List<PMC_DH_DocIdentifierWrapper>{docIdWrapper});
        }
        else{
            List<PMC_DH_DocIdentifierWrapper> lstDocWrapper = mapIdentifierToList.get(strIdentifier);
            if(!lstDocWrapper.contains(docIdWrapper)){
                lstDocWrapper.add(docIdWrapper);
            }
            mapIdentifierToList.put(strIdentifier,lstDocWrapper);   
        }
        return mapIdentifierToList;
    }
    
    private static List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> addDocWrapperToList(List<PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper> lstDocInfoWrapper, PMC_DH_DocIdentifierWrapper doc, OrderItem oi){
        PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docInfo = new PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper();
        //1171
        PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper docInfoQuality = new PMC_DH_DocumentListViewWrapper.DocumentInfoWrapper();

        docInfo.strOrderNumber = oi.Order.PMC_CPQ_SAPOrderNumber__c;
        docInfo.strDocumentType = doc.strDocType;
        docInfoQuality.strOrderNumber = oi.Order.PMC_CPQ_SAPOrderNumber__c;
        Map<String, PMC_DH_DocumentType__mdt> mapDocTypeMetadata = PMC_DH_DocumentType__mdt.getAll();
		System.debug('doc'+ doc);
        if(doc.strDocType =='Nota Fiscal'){
            //1171
            docInfoQuality.strDocumentType =System.label.pmc_QualityDocuments_SerachPage;
            docInfoQuality.strDocumentName =System.label.pmc_QualityDocuments_SerachPage + '_' + doc.notaIdentifier.get(doc.strIdentifierType);
            docInfo.strDocumentName = doc.strDocType + '_' + doc.notaIdentifier.get(doc.strIdentifierType);
            
			//docInfo.strNotaFiscal = doc.strDocType + '_' + doc.mapIdentifier.get(doc.strIdentifierType);
            
        }
        else{
            docInfo.strDocumentName = doc.strDocType + '_' + doc.mapIdentifier.get(doc.strIdentifierType);
        }
        docInfo.datDocumentAddedDate = doc.datIdentifierDate;
        docInfo.strDocumentCode = doc.strDocCode;
        docInfo.mapDocumentIdentifier = doc.mapIdentifier;
        docInfo.inspLotUsageDecision = doc.inspLotUsageDecision; 
        //1171
        docInfoQuality.datDocumentAddedDate = doc.datIdentifierDate;
        docInfoQuality.strDocumentCode = doc.strDocCode;
        docInfo.strInvoiceNumber = doc.strInvNumber;
        docInfoQuality.mapDocumentIdentifier = doc.mapIdentifier;
        docInfoQuality.inspLotUsageDecision = doc.inspLotUsageDecision;
        docInfoQuality.mapDocumentIdentifier=doc.qDIdentifier;
        if(doc.inspLotUsageDecision=='Approved' && doc.strDocType =='Nota Fiscal')
        {
             for (PMC_DH_DocumentType__mdt mdt : mapDocTypeMetadata.values()) {
          if(mdt.label=='Quality Document')
          {
            docInfoQuality.strDocumentCode = mdt.PMC_DH_DocumentCode__c;
            
          }
        }
            lstDocInfoWrapper.add(docInfoQuality);
        }
        lstDocInfoWrapper.add(docInfo);
        return lstDocInfoWrapper;
    }
    
    /*************************************************************************
* @method Name  : Wrapper class for get Invoice/Shipment parameters
* @description  : Method to create wrapper of parameters 
* @author		: Nikhilesh
*****************************************************************************/
// added with sharing 
    public with sharing class PMC_DH_RecordParamsWrapper {
        /**
* * @description Order Item
* * @return OrderItem
* */
        @AuraEnabled
        public OrderItem orderItem { get; set; }
        
        /**
* * @description Map of Document Type and Metadata
* * @return List<OrderItem>
* */
        @AuraEnabled
        public Map<String, PMC_DH_DocumentType__mdt> mapDocTypeMetadata { get; set; }
        
        /**
* * @description Map of Document Identifier and List of Document Wrapper
* * @return Map<String, List<DocIdentifierWrapper>>
* */
        @AuraEnabled
        public Map<String, List<PMC_DH_DocIdentifierWrapper>> mapIdentifierToList { get; set; }
        
        /**
* * @description User's country
* * @return String
* */
        @AuraEnabled
        public String strCountry { get; set; }
        
    }
    /*************************************************************************
* @method Name  : Wrapper class for Document Identifier
* @description  : Method to fetch metadata details for document
* @author		: Nikhilesh
*****************************************************************************/
// added with sharing
    public with sharing class PMC_DH_DocIdentifierWrapper {

        @AuraEnabled
        public String inspLotUsageDecision { get; set; }
        
        /**
* * @description Identifier Type
* * @return String
* */
        @AuraEnabled
        public String strIdentifierType { get; set; }
        /**
* * @description Identifier Name
* * @return Map<String,String>
* */
        @AuraEnabled
        public Map<String,String> mapIdentifier { get; set; }
         /**
* * @description Identifier Name
* * @return Map<String,String>
* */
        @AuraEnabled
        public Map<String,String> notaIdentifier { get; set; }
        /**
          /**
* * @description Identifier Name
* * @return Map<String,String>
* */
        @AuraEnabled
        public Map<String,String> qDIdentifier { get; set; }
        /**
* * @description Identifier Date
* * @return Date
* */
        @AuraEnabled
        public Date datIdentifierDate { get; set; }
        /**
* * @description Document Code
* * @return String
* */
        @AuraEnabled
        public String strDocCode { get; set; }
        /**
* * @description Document Type
* * @return String
* */
        @AuraEnabled
        public String strDocType { get; set; }
        /**
* * @description Document Type GSMD-2233
* * @return String
* */
        @AuraEnabled
        public String strInvNumber { get; set; }
    }
    
}