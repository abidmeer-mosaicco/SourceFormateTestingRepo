/** @description Controlled class invoked from its associated VF Page <name>.
 *  @creator Prakhar Srivastava
 *  @storynumber GDASF-9240,9443
 */
public with sharing class PMC_CPQ_CadenceController {
	
    public String baseUrl = '';
    public String quoteId = '';
    
    /** @description Constructor of the class which is used to intialize variables using parameter.
     *  @param controller : Standard Controller Object
     */
    public PMC_CPQ_CadenceController(ApexPages.StandardController controller){
        quoteId = ApexPages.currentPage().getParameters().get('id');
        //baseUrl = 'https://globaldigitalacceleration--devp1.sandbox.lightning.force.com/lightning/r/Report/00ODT000001X5hc2AC/view?queryScope=userFolders&fv0=';
    }
    
    /** @description Action method invoked from its associated VF Page <name>. This is referencing a
     *  callout method which will make a callout to SAP to get the quantity available for the products added to the cart.
     *  @return redirectToReport
     */
    public PageReference redirect1()
    {
        
        Map<String, Schema.SObjectField> fieldMap = SBQQ__Quote__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
                
        // Get all of the fields on the object
        Set<String> setFieldNames = fieldMap.keySet();
        list<String> lstFieldNames = new List<String>(setFieldNames);
                
        // Dynamic Query String.
        List<SBQQ__Quote__c> lstQuotes = Database.query('SELECT ' + String.escapeSingleQuotes(String.join(lstFieldNames, ',')) + ', RecordType.DeveloperName FROM SBQQ__Quote__c where Id  = \''+ String.escapeSingleQuotes(quoteId) + '\'');// WITH SECURITY_ENFORCED');
        List<SBQQ__QuoteLine__c> lstQuoteLine = [select id,SBQQ__Quote__c,PMC_CPQ_IsQuantityUpdated__c, SBQQ__Quantity__c, SBQQ__Quote__r.PMC_CPQ_IsContractPeriodChanged__c, SBQQ__Quote__r.name, SBQQ__Quote__r.PMC_CPQ_LastContractStart__c, 
                                         SBQQ__Quote__r.PMC_CPQ_LastContractEnd__c, SBQQ__Quote__r.PMC_CPQ_QuantityChangedCount__c, SBQQ__Quote__r.PMC_CPQ_ContractPeriod__c, SBQQ__Quote__r.PMC_CPQ_ContractStart__c, SBQQ__Quote__r.PMC_CPQ_ContractEnd__c   
                                         from SBQQ__QuoteLine__c where SBQQ__Quote__c=: quoteId WITH SECURITY_ENFORCED];
        List<PMC_CPQ_Cadence__c> lstCadence = [select id, PMC_CPQ_QuoteLine__c from PMC_CPQ_Cadence__c where PMC_CPQ_QuoteLine__r.SBQQ__Quote__c =: quoteId WITH SECURITY_ENFORCED];
        // GCPM-5506: Changed report name to 'PMC_CPQ_ProductAvailabilityWithCadence_EKH' to get the report id for redirecting to the report page.
        List<Report> lstreportId = [select id from report where developername = 'PMC_CPQ_ProductAvailabilityWithCadence_EKH' WITH SECURITY_ENFORCED];
        //When there are no quote lines in the cart to get prices, display the warning message to the AM.
        if(lstQuoteLine.size() == 0){
            String cstmWarningLabel = System.Label.PMC_CPQ_GetPriceNoQuoteLineWarningMessage;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, cstmWarningLabel));
            return null;
        }
        
        Id reportId = !lstreportId.isEmpty()?lstreportId[0].Id:null;
    
        baseUrl = URL.getOrgDomainUrl().toExternalForm()+'/lightning/r/Report/'+reportId+'/view?queryScope=userFolders&fv0='+lstQuoteLine[0].SBQQ__Quote__r.name;
        PageReference redirectToReport = new PageReference(baseUrl);

        try{
            callCreateCadence(lstQuoteLine,lstCadence);
            String strInterface = 'ProductsExternalPricing';
            PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(strInterface); 
            String strEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
            //HttpResponse response = PMC_CPQ_GetPriceOnQuickSave.makeCalloutRequestCadence(lstQuotes,strEndpoint, false);  
            PMC_CPQ_CadenceJSONCreation.makeCalloutRequestCadence(lstQuotes,strEndpoint);
            //Check mandatory values
            if(PMC_CPQ_GetPriceOnQuickSave.strErrorMessage != '<br/>'){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, PMC_CPQ_GetPriceOnQuickSave.strErrorMessage));
                return null;
            }
        }
        catch(Exception e){
            PMC_ErrorLogClass.processException(e);
        }
        return redirectToReport;
    }

    /** @description this method will create cadence record for respective QLI
	 * @param lstQuoteLine - list of quote line on which cadence to be created
     * @param lstCadence - list of existing cadence
     */
    public static void callCreateCadence(List<SBQQ__QuoteLine__c> lstQuoteLine, List<PMC_CPQ_Cadence__c> lstCadence){
        /* if user check availability for the first time then create cadence record*/
            
        if(lstQuoteLine[0].SBQQ__Quote__r.PMC_CPQ_LastContractStart__c ==null && lstQuoteLine[0].SBQQ__Quote__r.PMC_CPQ_LastContractEnd__c ==null && lstCadence.isEmpty()){
            createCadenceRecord(lstQuoteLine);
            }
        /*if contract period is changed then create cadence record for all QLI under quote and delete existing Cadence*/
        else if(lstQuoteLine[0].SBQQ__Quote__r.PMC_CPQ_IsContractPeriodChanged__c && !lstCadence.isEmpty()){
                // delete existing cadence record from all Quote Lines under the quote.
                deleteCadenceRecord(lstCadence);
                createCadenceRecord(lstQuoteLine);
        }
        /*if QLI quantity is changed then create cadence record for that QLI and delete existing Cadence*/
        else if(!lstQuoteLine[0].SBQQ__Quote__r.PMC_CPQ_IsContractPeriodChanged__c && lstQuoteLine[0].SBQQ__Quote__r.PMC_CPQ_QuantityChangedCount__c > 0 
            && !lstCadence.isEmpty()){
               
                Map<Id,List<PMC_CPQ_Cadence__c>> mapQLIOfCadence = new Map<Id,List<PMC_CPQ_Cadence__c>>();
                //create map of QLI and Cadence which will be used to determine which Cadence to delete
                mapQLIOfCadence = getMapOfQLICadence(lstCadence);
                // run loop on list to determine Quote Line where quantity is changed and delete cadence linked to those QLI.
                verifyQuantityUpdated(lstQuoteLine,mapQLIOfCadence);

            }
    }
    
	/** @description this method will create cadence record for respective QLI
	 * @param lstQuoteLine - list of quote line on which cadence to be created
     */
    public static void createCadenceRecord(List<SBQQ__QuoteLine__c> lstQuoteLine){
        List<PMC_CPQ_Cadence__c> lstCadenceInsert = new List<PMC_CPQ_Cadence__c>();
        // run loop on Quote Line and create cadence record
        for(SBQQ__QuoteLine__c qLine: lstQuoteLine){
            Integer quantityCounter = 0;
            Integer contractPeriod = (Integer)(qLine.SBQQ__Quote__r.PMC_CPQ_ContractPeriod__c + 1);
            /* GDASF-9443 cadence record to be created from the start date of contract till end date of contract 
            so to determine quantity for each cadence divide total quantity by contract period + 1 */
            Integer cadQuantityCount = (Integer)(qLine.SBQQ__Quantity__c/contractPeriod);
           
            /* GDASF-9443 running loop on contract period and creating cadence record */
            for(Integer cadCount = 0; cadCount <=qLine.SBQQ__Quote__r.PMC_CPQ_ContractPeriod__c; cadCount++){
                PMC_CPQ_Cadence__c cadRec = new PMC_CPQ_Cadence__c();
                cadRec.PMC_CPQ_QuoteLine__c = qLine.Id;
                cadRec.PMC_CPQ_RequestedQuantity__c = cadCount==qLine.SBQQ__Quote__r.PMC_CPQ_ContractPeriod__c?qLine.SBQQ__Quantity__c - quantityCounter:cadQuantityCount;
                cadRec.PMC_CPQ_RequestedDate__c = cadCount==qLine.SBQQ__Quote__r.PMC_CPQ_ContractPeriod__c?qLine.SBQQ__Quote__r.PMC_CPQ_ContractEnd__c:qLine.SBQQ__Quote__r.PMC_CPQ_ContractStart__c.addMonths(cadCount);
                quantityCounter = quantityCounter+cadQuantityCount;
                lstCadenceInsert.add(cadRec);
            	}
        	
        }
        try{
            SBQQ.TriggerControl.disable();
        if(!lstCadenceInsert.isEmpty()){
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, lstCadenceInsert);
        	Database.insert(decision.getRecords(),false);
        }
    }    
        catch(Exception e) {
            PMC_ErrorLogClass.processException(e);
        }
        finally{
             SBQQ.TriggerControl.enable();
        }
    }    

    /** @description this method will create cadence record for respective QLI
	 * @param lstCadence - list of cadence to be deleted
     */
    public static void deleteCadenceRecord(List<PMC_CPQ_Cadence__c> lstCadence){
        try{
            SBQQ.TriggerControl.disable();
            if (PMC_CPQ_Cadence__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isDeletable()) {
                Database.delete(lstCadence, false);
            }
        }
        catch(Exception e) {
            PMC_ErrorLogClass.processException(e);
        }
        finally{
             SBQQ.TriggerControl.enable();
        }
    }

    /** @description this method will create cadence record for respective QLI
	 * @param lstCadence - list of cadence
     * @return Map<Id,List<PMC_CPQ_Cadence__c>>
     */
    public static Map<Id,List<PMC_CPQ_Cadence__c>> getMapOfQLICadence(List<PMC_CPQ_Cadence__c> lstCadence){

        Map<Id,List<PMC_CPQ_Cadence__c>> mapQLIOfCadence = new Map<Id,List<PMC_CPQ_Cadence__c>>();
        for(PMC_CPQ_Cadence__c cad: lstCadence){
            List<PMC_CPQ_Cadence__c> lstQLICad = new List<PMC_CPQ_Cadence__c>();
            if(mapQLIOfCadence.containsKey(cad.PMC_CPQ_QuoteLine__c)){
                lstQLICad = mapQLIOfCadence.get(cad.PMC_CPQ_QuoteLine__c);
            }
            lstQLICad.add(cad);
            mapQLIOfCadence.put(cad.PMC_CPQ_QuoteLine__c,lstQLICad);   
        }
        return mapQLIOfCadence;
    }

    /** @description this method will create cadence record for respective QLI
	 * @param lstQuoteLine - list of quote lines
     * @param mapQLIOfCadence - map of QLI and related cadence
     */
    public static void verifyQuantityUpdated(List<SBQQ__QuoteLine__c> lstQuoteLine, Map<Id,List<PMC_CPQ_Cadence__c>> mapQLIOfCadence){
        
            List<SBQQ__QuoteLine__c> lstQLI = new List<SBQQ__QuoteLine__c>();
            List<PMC_CPQ_Cadence__c> lstCadenceToDelete = new List<PMC_CPQ_Cadence__c>();
            // run loop on list to determine Quote Line where quantity is changed and delete cadence linked to those QLI.
            for(SBQQ__QuoteLine__c qLine: lstQuoteLine){
                if(qLine.PMC_CPQ_IsQuantityUpdated__c){
                    lstQLI.add(qLine);
                    // GDASF-9443, if any product is added afterwards then to prevent error of null on cadence.
                    if(mapQLIOfCadence.containsKey(qLine.Id)){
                    for(PMC_CPQ_Cadence__c cad: mapQLIOfCadence.get(qLine.Id)){
                        lstCadenceToDelete.add(cad);
                    }
                }
            }
            }
            if(!lstCadenceToDelete.isEmpty()){
                deleteCadenceRecord(lstCadenceToDelete);
            }
            createCadenceRecord(lstQLI);
    }
}