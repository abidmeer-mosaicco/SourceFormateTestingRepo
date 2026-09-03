/**
* @description This class will be used to make callouts to the Account Creation/Update interface of CPI - PMC_CPI_AccountCreateActionClass
* @author Gideoni Silva
* @storynumber EIDGT-965
*/
public class PMC_CPI_AccountActionClass implements Queueable, Database.AllowsCallouts {
	
    public Account EffectiveAccount;
    public List<Id> lstIds;
    public List<Object> AccountParameters;
    public Map<String, String> JSONPayloadParams;
    public String strAccountGroup;
    public String STRING_INTERFACE;
    static final String STRING_INTEGRATIONSTATUSERROR = 'Error';
    static final String STRING_NAMEDCREDENTIALS = 'callout:PMC_CPQ_NamedCredential';
    static final String STRING_METHOD = 'POST';
    static List<PMC_CPQ_TransactionLog__c> lstTransactionLogs = new List<PMC_CPQ_TransactionLog__c>();
 
    @TestVisible private static Map<String, PMC_CPQ_Integration_Endpoint__mdt> mockMetadata = new Map<String, PMC_CPQ_Integration_Endpoint__mdt>();
 
    /** 
     * @description Constructor of the class. 
     * @param lstAccounts - list of accounts sent from the flow.
     * @param lstIds - lists of ids
     */
    public PMC_CPI_AccountActionClass(Account EffectiveAccount, List<Id> lstIds, String strAccountGroup, String STRING_INTERFACE, Map<String, String> JSONPayloadParams) {
        this.EffectiveAccount = EffectiveAccount; 
        this.lstIds = lstIds;
        this.strAccountGroup = strAccountGroup;
        this.JSONPayloadParams = JSONPayloadParams;
        this.STRING_INTERFACE = STRING_INTERFACE;
    }
    /** 
     * @description This is the apex action that will be invoked from the flow.
     * @param lstAccounts - list of Accounts sent from the flow.
     */
    @InvocableMethod(label='CPI Customer Creation/Update Remote Action' description='Triggers the CPI Interface to create Business Partner records in SAP' category='Account')
    public static void postInfoToCPI(List<AccountActionRequest> AccountParameters) {
        Account EffectiveAccount = AccountParameters[0].inputAccount;
        String strAccountGroup = AccountParameters[0].strAccountGroup;
        String STRING_INTERFACE = AccountParameters[0].strEndpointName;
        
        List<Id> lstIds = new List<Id>();
        lstIds.add(EffectiveAccount.Id);
        Map<String, String> JSONPayloadParams = new Map<String, String>{
            'strAcctAssmtGrpCust' => AccountParameters[0].strAcctAssmtGrpCust,
            'strAccountManager' => AccountParameters[0].strAccountManager,
            'strBillToPartner' => AccountParameters[0].strBillToPartner,                
            'strBPGrouping' => AccountParameters[0].strBPGrouping,
            'strCashPlanningGroup' => AccountParameters[0].strCashPlanningGroup,
            'strCNPJNumber' => AccountParameters[0].strCNPJNumber,
            'strCommissionAgent' => AccountParameters[0].strCommissionAgent,
            'strCPFNumber' => AccountParameters[0].strCPFNumber,
            'strCurrency' => AccountParameters[0].strCurrency,
            'strCustomerGroup' => AccountParameters[0].strCustomerGroup,                
            'strCustomerTaxCategory' => AccountParameters[0].strCustomerTaxCategory,
            'strCustPriceProc' => AccountParameters[0].strCustPriceProc,
            'strCustServRep' => AccountParameters[0].strCustServRep,
            'strDistChannel' => AccountParameters[0].strDistChannel,
            'strDivision' => AccountParameters[0].strDivision,
            'strDomesticBroker' => AccountParameters[0].strDomesticBroker,
            'strInvDates' => AccountParameters[0].strInvDates,
            'strInvListSched' => AccountParameters[0].strInvListSched,
            'strItemOrderProb' => AccountParameters[0].strItemOrderProb,
            'strLanguage' => AccountParameters[0].strLanguage,
            'strLayoutSortingRule' => AccountParameters[0].strLayoutSortingRule,
            'strNaturalPerson' => AccountParameters[0].strNaturalPerson,
            'strOperation' => AccountParameters[0].strEndpointName,
            'strOverDelivTol' => AccountParameters[0].strOverDelivTol, 
            'strPartnerFunction' => AccountParameters[0].strPartnerFunction,
            'strPayerPartner' => AccountParameters[0].strPayerPartner,                
            'strReconcAcc' => AccountParameters[0].strReconcAcc,
            'strRUCPYOrg' => AccountParameters[0].strRUCPYOrg,
            'strRUCPYPerson' => AccountParameters[0].strRUCPYPerson,
            'strSalesOrg' => AccountParameters[0].strSalesOrg,
            'strSalesOffice' => AccountParameters[0].strSalesOffice,
            'strSalesDistrict' => AccountParameters[0].strSalesDistrict,
            'strSalesGroup' => AccountParameters[0].strSalesGroup,
            'strSearchTerm1' => AccountParameters[0].strSearchTerm1,
            'strShipCondition' => AccountParameters[0].strShipCondition,                
            'strShipToPartner' => AccountParameters[0].strShipToPartner,                
            'strSoldToPartner' => AccountParameters[0].strSoldToPartner,
            'strTransportation' => AccountParameters[0].strTransportation,
            'strToleranceGroup' => AccountParameters[0].strToleranceGroup,
            'strTaxClass' => AccountParameters[0].strTaxClass,
            'strTSMManager' => AccountParameters[0].strTSMManager,
            'strUnderDelivTol' => AccountParameters[0].strUnderDelivTol

                
        };

       	System.enqueueJob(new PMC_CPI_AccountActionClass(EffectiveAccount, lstIds, strAccountGroup, STRING_INTERFACE, JSONPayloadParams));
    }
    /** 
     * @description Makes a request to callout class.
     * @param context - Receives the context of the flow. In this case it is the list of accounts.
     */
    public void execute(QueueableContext context) {		
        PMC_CPQ_Integration_Endpoint__mdt strIntegrationEndpointRecord = PMC_CPQ_Integration_Endpoint__mdt.getInstance(STRING_INTERFACE); 
        String strEndpoint = strIntegrationEndpointRecord.PMC_CPQ_Endpoint__c;
        String strCalloutEndpoint = STRING_NAMEDCREDENTIALS+strEndpoint;
        String strSerializedBody;

        switch on strAccountGroup {
            when 'Ship-to' {
                strSerializedBody = PMC_CPIAccountCalloutUtilityClass.createShipToPayload(lstIds,JSONPayloadParams);
            }
            when 'Sold-to' {
                strSerializedBody = PMC_CPIAccountCalloutUtilityClass.createSoldToPayload(lstIds,JSONPayloadParams);
            }
            when 'Bill-to' {
                strSerializedBody = PMC_CPIAccountCalloutUtilityClass.createBillToPayload(lstIds,JSONPayloadParams);
            }
            when 'Payer' {
                strSerializedBody = PMC_CPIAccountCalloutUtilityClass.createPayerPayload(lstIds,JSONPayloadParams);
            }
        }		

        HttpResponse response = PMC_CPIAccountCalloutUtilityClass.sendCalloutRequest(STRING_METHOD, strCalloutEndpoint, strSerializedBody);
        if(response != null && STRING_INTERFACE == 'BPCreation')
        {
            PMC_CPIAccountIntegrationClass.parseJSONAccountInterface(EffectiveAccount, response, strEndpoint);
        }
        else if(response != null && STRING_INTERFACE == 'BPModification')
        {
            PMC_CPIAccountIntegrationClass.parseXMLAccountInterface(EffectiveAccount, response, strEndpoint);
        }
        else if(response != null && STRING_INTERFACE == 'BPExtension')
        {
            PMC_CPIAccountIntegrationClass.parseXMLAccountInterface(EffectiveAccount, response, strEndpoint);
        }
        else if(response == null)
        {   
            Boolean boolRetry = PMC_CPIAccountCalloutUtilityClass.autoRetryQueueableApex(AsyncInfo.getCurrentQueueableStackDepth(),PMC_CPQ_CPIRemoteCalloutUtilityClass.strExceptionMsg);
            PMC_CPIAccountIntegrationClass.updateAccountExceptionStatusMsg(EffectiveAccount, strEndpoint); 
            
            if(boolRetry)
            {
                System.enqueueJob(new PMC_CPI_AccountActionClass(EffectiveAccount, lstIds, strAccountGroup, STRING_INTERFACE, JSONPayloadParams));
            } 
        }
    }

    public class AccountActionRequest {
        @InvocableVariable(required=true)
        public Account inputAccount;
    
        @InvocableVariable(required=true)
        public String strAccountGroup;

        @InvocableVariable(required=false)
        public String strAccountManager;

        @InvocableVariable(required=false)
        public String strAcctAssmtGrpCust;
        
        @InvocableVariable(required=true)
        public String strBPGrouping;
        
        @InvocableVariable(required=false)
        public String strBillToPartner;  
        
        @InvocableVariable(required=false)
        public String strCashPlanningGroup;   
        
        @InvocableVariable(required=false)
        public String strCommissionAgent;

        @InvocableVariable(required=false)
        public String strCustomerTaxCategory;  

        @InvocableVariable(required=false)
        public String strCustServRep;  
        
        @InvocableVariable(required=false)
        public String strDivision;

        @InvocableVariable(required=false)
        public String strCNPJNumber;
        
        @InvocableVariable(required=false)
        public String strCPFNumber;
        
        @InvocableVariable(required=false)
        public String strCurrency;

        @InvocableVariable(required=false)
        public String strCustomerGroup;

        @InvocableVariable(required=false)
        public String strCustPriceProc;

        @InvocableVariable(required=false)
        public String strDistChannel;

        @InvocableVariable(required=false)
        public String strDomesticBroker;

        @InvocableVariable(required=true)
        public String strEndpointName;     
        
        @InvocableVariable(required=false)
        public String strInvDates;   
        
        @InvocableVariable(required=false)
        public String strInvListSched;   

        @InvocableVariable(required=false)
        public String strItemOrderProb;
        
        @InvocableVariable(required=false)
        public String strLanguage;   
               
        @InvocableVariable(required=false)
        public String strLayoutSortingRule;  
        
        @InvocableVariable(required=false)
        public Boolean boolRecordPmntHistory;   
        
        @InvocableVariable(required=false)
        public String strNaturalPerson;
        
        @InvocableVariable(required=false)
        public String strOverDelivTol; 

        @InvocableVariable(required=true)
        public String strPartnerFunction;
        
        @InvocableVariable(required=false)
        public String strPayerPartner;  
        
        @InvocableVariable(required=false)
        public String strReconcAcc; 
        
        @InvocableVariable(required=false)
        public String strRUCPYOrg;       

        @InvocableVariable(required=false)
        public String strRUCPYPerson;
        
        @InvocableVariable(required=false)
        public String strSalesOrg;

        @InvocableVariable(required=false)
        public String strSalesOffice;

        @InvocableVariable(required=false)
        public String strSalesDistrict;

        @InvocableVariable(required=false)
        public String strSalesGroup;

        @InvocableVariable(required=false)
        public String strSearchTerm1;

        @InvocableVariable(required=false)
        public String strShipCondition;
        
        @InvocableVariable(required=false)
        public String strShipToPartner;  
        
        @InvocableVariable(required=false)
        public String strSoldToPartner;          

        @InvocableVariable(required=false)
        public String strTaxClass;

        @InvocableVariable(required=false)
        public String strToleranceGroup; 

        @InvocableVariable(required=false)
        public String strTransportation;

        @InvocableVariable(required=false)
        public String strTSMManager; 

        @InvocableVariable(required=false)
        public String strUnderDelivTol;         
	}
}