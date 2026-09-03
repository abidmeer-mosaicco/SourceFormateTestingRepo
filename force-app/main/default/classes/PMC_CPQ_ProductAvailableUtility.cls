/** @description This class will house utility functions for Product Available
 *  @author Prakhar Srivastava
 *  @storynumber GDASF-9443
 */
public with sharing class PMC_CPQ_ProductAvailableUtility {

    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstMaterial = new List<PMC_CPQ_IntegrationFieldMap__mdt>(); // GDASF-9443
    static List<PMC_CPQ_IntegrationFieldMap__mdt> lstSchedule = new List<PMC_CPQ_IntegrationFieldMap__mdt>(); // GDASF-9240
    static Map<String, String> mapSchedule = new Map<String, String>();//map of Key and Apex API name
    static Map<String, String> mapMaterialAvailable =  new Map<String, String>();//map of Key and Apex API name for material set
    
	/** 
     * @description filter through integration field map
     * @param lstMapping - list of Integration mapping metadata
     * @return mapObjectToResponseRecord
     */
    public static Map<String,List<PMC_CPQ_IntegrationFieldMap__mdt>> filterResponseMap(List<PMC_CPQ_IntegrationFieldMap__mdt> lstMapping){
        Map<String,List<PMC_CPQ_IntegrationFieldMap__mdt>> mapObjectToResponseRecord = new Map<String, List<PMC_CPQ_IntegrationFieldMap__mdt>>();
        for(PMC_CPQ_IntegrationFieldMap__mdt respVal: lstMapping){
            List<PMC_CPQ_IntegrationFieldMap__mdt> lstMetaRecord = new List<PMC_CPQ_IntegrationFieldMap__mdt>();
            if(mapObjectToResponseRecord.containsKey(respVal.PMC_CPQ_SFObject__c)){
                lstMetaRecord = mapObjectToResponseRecord.get(respVal.PMC_CPQ_SFObject__c);
            }
            lstMetaRecord.add(respVal);
            mapObjectToResponseRecord.put(respVal.PMC_CPQ_SFObject__c,lstMetaRecord);
        }
        lstSchedule = mapObjectToResponseRecord.get('Schedule');
        lstMaterial = mapObjectToResponseRecord.get('MaterialSet');
        return mapObjectToResponseRecord;
        }

        /** 
        * @description filter through integration field map
        * @param lstMapping - list of Integration mapping metadata
        * @return mapOfTargetFields
        */
        public static Map<String,Map<String, String>> createMapOfTargetField(List<PMC_CPQ_IntegrationFieldMap__mdt> lstMapping){
            Map<String,Map<String, String>> mapOfTargetFields = new Map<String,Map<String, String>>();
            for(PMC_CPQ_IntegrationFieldMap__mdt respVal: lstMapping){
                Map<String,String> mapSchedule = new Map<String,String>();
                if(mapOfTargetFields.containsKey(respVal.PMC_CPQ_SFObject__c)){
                    mapSchedule = mapOfTargetFields.get(respVal.PMC_CPQ_SFObject__c);
                }
                mapSchedule.put(respVal.PMC_CPQ_AttributeKey__c, respVal.PMC_CPQ_ApexAPIName__c);
                mapOfTargetFields.put(respVal.PMC_CPQ_SFObject__c,mapSchedule);
            }
            mapSchedule = mapOfTargetFields.get('Schedule');
            mapMaterialAvailable = mapOfTargetFields.get('MaterialSet');
            return mapOfTargetFields;
        }

        /** 
     * @description Parses through the response body and populates Integration fields on the cadence GDASF-9240.
     * @param mapResponseLine - response line from EndPoint
     * @param mapIndividualQLICadence - map of QLI and related Cadence
     * @return cadRecord
     */
    public static PMC_CPQ_Cadence__c getTargetFieldValueMapped(Map<String, Object> mapResponseLine, Map<String, PMC_CPQ_Cadence__c> mapIndividualQLICadence){
        String strAPIName = '';
        PMC_CPQ_Cadence__c cadRecord = new PMC_CPQ_Cadence__c();
        for(PMC_CPQ_IntegrationFieldMap__mdt add: lstSchedule){
                strAPIName = mapSchedule.get((String)add.get('PMC_CPQ_AttributeKey__c'));
                cadRecord = mapIndividualQLICadence.get(mapResponseLine.get('ItmNumber')+'_'+mapResponseLine.get('ReqDate'));
                if(cadRecord != null && add.PMC_CPQ_DataType__c == 'Date'){
                    cadRecord.put(strAPIName, Date.valueOf((String)mapResponseLine.get((String)add.get('PMC_CPQ_AttributeKey__c'))));
                }else if(cadRecord != null && add.PMC_CPQ_DataType__c == 'Decimal'){
                    cadRecord.put(strAPIName, Decimal.valueOf((String)mapResponseLine.get((String)add.get('PMC_CPQ_AttributeKey__c'))));
                }
           // }
        }
        return cadRecord;
    }

     /** 
     * @description update the quote, qli and insert integration log
     * @param lstQuotes - list of quote
     * @param lstQuoteLines - list of quotelines
     * @param mapTransactionLogFields - map of transaction log fields
     */
    public static void updateQuoteNQLI(List<SBQQ__Quote__c> lstQuotes, List<SBQQ__QuoteLine__c> lstQuoteLines, Map<String, String> mapTransactionLogFields){
        List<PMC_CPQ_TransactionLog__c> lstTransactionLogs;
        SBQQ.TriggerControl.disable();
        try {
            SObjectAccessDecision securityDecisionQuote = Security.stripInaccessible(AccessType.UPDATABLE, lstQuotes);
            Database.update(securityDecisionQuote.getRecords());

            SObjectAccessDecision securityDecisionQLine = Security.stripInaccessible(AccessType.UPDATABLE, lstQuoteLines);
            Database.update(securityDecisionQLine.getRecords());

            lstTransactionLogs = PMC_CPQ_TransactionLogUtilityClass.addTransactionLog(mapTransactionLogFields);
            PMC_CPQ_TransactionLogUtilityClass.insertTransactionLogs(lstTransactionLogs);
        }
        catch(Exception e) {
            PMC_ErrorLogClass.processException(e);
        } 
        finally {
            SBQQ.TriggerControl.enable();
        }
    }
}