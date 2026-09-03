// GMDP-2612 - Added NOMOVEMENT/DaysNotMoved__c data into PMC_Shipment_Data__c
public class PMC_CPQ_FetchAndStoreData implements Schedulable {

    private static final String GET_TOKEN_NAME = 'IntelliTransGetToken';
    private static final String GET_SHIPMENT_NAME = 'IntelliTransGetShipmentData';
    private static final Integer HTTP_TIMEOUT_VALUE = 120000;

    public void execute(SchedulableContext sc) {
        // Make callouts to API, process data, and insert records in intellitrans shipment
        fetchAndInsertData();
        // Database.executeBatch(new PMC_IntellitransShipmentBatchUpdate(), 200);
    }

    public static PMC_DH_IntegrationSettings__mdt getIntegrationSettings(String developerName) {
        return [
            SELECT Id, DeveloperName, PMC_DH_CalloutMethod__c, PMC_DH_ContentType__c,
                   PMC_DH_EndpointURL__c, PMC_DH_RefreshToken__c, PMC_DH_Accept__c,
                   PMC_DH_RetryCount__c, PMC_DH_RetryTimeout__c, PMC_DH_Timeout__c,
                   PMC_DH_Authorization__c, PMC_DH_CachedTime__c, PMC_DH_ClientId__c,
                   PMC_DH_ClientSecret__c
            FROM PMC_DH_IntegrationSettings__mdt 
            WHERE DeveloperName = :developerName 
            WITH USER_MODE
            LIMIT 1
        ];
    }

    public class ShipmentData {
        @AuraEnabled public String DELIVERYNUMBER { get; set; }
        @AuraEnabled public String EQUIPMENTID { get; set; }
        @AuraEnabled public Datetime ETA { get; set; }
        @AuraEnabled public String BOL { get; set; }
        @AuraEnabled public String BOLNUMBER { get; set; }
        @AuraEnabled public String CUSTORDERNO { get; set; }
        @AuraEnabled public String SHIPMENTNUMBER_CNTORDER { get; set; }
        @AuraEnabled public String PONUMBER { get; set; }
        @AuraEnabled public String CURRENTCARRIER { get; set; }
        @AuraEnabled public String DESTINATIONCARRIER { get; set; }
        @AuraEnabled public String FLEETTOWNAME { get; set; }
        @AuraEnabled public String COMMENTS { get; set; }
        @AuraEnabled public String SIGHTINGLOADOREMPTY { get; set; }
        @AuraEnabled public String CURRENTLOCATION { get; set; }
        @AuraEnabled public String DESTINATIONMM { get; set; }
        @AuraEnabled public String LATESTTRIPSIGHTINGID { get; set; }
        @AuraEnabled public String LATESTINTERNALCOMMENT { get; set; }
        @AuraEnabled public String SIGHTINGDESTINATION { get; set; }
        @AuraEnabled public Double LATITUDE { get; set; }
        @AuraEnabled public Double LONGITUDE { get; set; }
        @AuraEnabled public String STATUSCODE { get; set; }
        @AuraEnabled public Double NOMOVEMENT { get; set; }
    }
    
    @future(callout=true)
    public static void fetchAndInsertData() {
        String token = '';
        PMC_DH_IntegrationSettings__mdt tokenSettings = getIntegrationSettings(GET_TOKEN_NAME);
        
        HttpRequest tokenRequest = new HttpRequest();
        tokenRequest.setMethod('GET');
        tokenRequest.setTimeout(HTTP_TIMEOUT_VALUE);
        tokenRequest.setEndpoint(tokenSettings.PMC_DH_EndpointURL__c);
        tokenRequest.setHeader('loginid', tokenSettings.PMC_DH_ClientId__c);
        tokenRequest.setHeader('pwd', tokenSettings.PMC_DH_ClientSecret__c);		
        tokenRequest.setHeader('Content-Type', tokenSettings.PMC_DH_ContentType__c);
        
        Http http = new Http();
        HttpResponse tokenResponse = new HttpResponse();
        
        try {
            tokenResponse = http.send(tokenRequest);
            if (tokenResponse.getStatusCode() == 200) {
                token = (String) JSON.deserializeUntyped(tokenResponse.getBody());
            }
        } catch (PMC_DH_Validation.CustomException ex) {
            throw new PMC_DH_Validation.CustomException('Callout Failed');
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }

        PMC_DH_IntegrationSettings__mdt shipmentSettings = getIntegrationSettings(GET_SHIPMENT_NAME);
        
        Map<String, String> bodyMap = new Map<String, String>{
            'equipmentNumbers' => '',
            'shipDateFrom' => '',
            'shipDateTo' => '',
            'searchTemplateName' => 'Salesforce API',
            'resultTemplateName' => 'Salesforce API',
            'loginId' => 'Salesforce_API',
            'shipmentType' => 'Current'
        };     

        HttpRequest shipmentRequest = new HttpRequest();
        shipmentRequest.setMethod('GET');
        shipmentRequest.setTimeout(HTTP_TIMEOUT_VALUE);
        shipmentRequest.setEndpoint(shipmentSettings.PMC_DH_EndpointURL__c);
        shipmentRequest.setBody(JSON.serialize(bodyMap));
        shipmentRequest.setHeader('TokenID', token);
        shipmentRequest.setHeader('Content-Type', shipmentSettings.PMC_DH_ContentType__c);
        
        HttpResponse shipmentResponse = new HttpResponse();

        try {
            shipmentResponse = http.send(shipmentRequest);
            
            if (shipmentResponse.getStatusCode() == 200) {       
                List<ShipmentData> shipmentDataList = (List<ShipmentData>) JSON.deserialize(
                    shipmentResponse.getBody(),
                    List<ShipmentData>.class
                );
                
                Map<String, PMC_Shipment_Data__c> recordsToUpsertMap = new Map<String, PMC_Shipment_Data__c>();
                
                for (ShipmentData dataRow : shipmentDataList) {
                    PMC_Shipment_Data__c customObj = new PMC_Shipment_Data__c();
                    customObj.PMC_CPQ_SAPDeliveryID__c = dataRow.DELIVERYNUMBER;
                    customObj.PMC_DELIVERYNUMBER__c = dataRow.DELIVERYNUMBER;
                    customObj.PMC_EQUIPMENTID__c = dataRow.EQUIPMENTID;
                    customObj.PMC_ETA__c = dataRow.ETA;
                    customObj.PMC_BOL__c = dataRow.BOL;
                    customObj.PMC_BOLNUMBER__c = dataRow.BOLNUMBER;
                    
                    customObj.DaysNotMoved__c = dataRow.NOMOVEMENT != null ? String.valueOf(dataRow.NOMOVEMENT) : null;
                    
                    String custOrdNumber = dataRow.CUSTORDERNO;
                    if (custOrdNumber != null) {
                        customObj.PMC_CUSTORDERNO__c = custOrdNumber.removeStart('00');
                    } else {
                        customObj.PMC_CUSTORDERNO__c = dataRow.CUSTORDERNO;
                    }
                    
                    customObj.PMC_SHIPMENTNUMBER_CNTORDER__c = dataRow.SHIPMENTNUMBER_CNTORDER;
                    customObj.PMC_PONUMBER__c = dataRow.PONUMBER;
                    customObj.PMC_CURRENTCARRIER__c = dataRow.CURRENTCARRIER;
                    customObj.PMC_DESTINATIONCARRIER__c = dataRow.DESTINATIONCARRIER;
                    customObj.PMC_FLEETTOWNAME__c = dataRow.FLEETTOWNAME;
                    customObj.PMC_COMMENTS__c = dataRow.COMMENTS;
                    customObj.PMC_SIGHTINGLOADOREMPTY__c = dataRow.SIGHTINGLOADOREMPTY;
                    customObj.PMC_DESTINATIONMM__c = dataRow.DESTINATIONMM;
                    customObj.PMC_LATESTTRIPSIGHTINGID__c = dataRow.LATESTTRIPSIGHTINGID;
                    customObj.PMC_LATESTINTERNALCOMMENT__c = dataRow.LATESTINTERNALCOMMENT;
                    customObj.PMC_SIGHTINGDESTINATION__c = dataRow.SIGHTINGDESTINATION;
                    customObj.PMC_CPQ_CurrentCoordinates__latitude__s = dataRow.LATITUDE;
                    customObj.PMC_CPQ_CurrentCoordinates__longitude__s = dataRow.LONGITUDE;
                    // customObj.Status__c = dataRow.STATUSCODE;
                    customObj.Intransit_Status__c = dataRow.STATUSCODE;
                    customObj.PMC_CURRENTLOCATION__c = dataRow.CURRENTLOCATION;
                    customObj.PMC_CPQ_Shipment_PO__c = dataRow.CUSTORDERNO + dataRow.EQUIPMENTID;
                    customObj.Name = dataRow.CUSTORDERNO;
                    customObj.PMC_Deliveries_Updated__c = false;
                    
                    recordsToUpsertMap.put(customObj.PMC_CPQ_Shipment_PO__c, customObj);
                }
                
                PMC_DH_LoggingUtils.createDHTransactionLogs(
                    shipmentRequest,
                    shipmentResponse,
                    shipmentSettings.PMC_DH_EndpointURL__c
                );
                
                if (!recordsToUpsertMap.isEmpty()) {
                    try {
                        Schema.SObjectField extIdField = PMC_Shipment_Data__c.Fields.PMC_CPQ_Shipment_PO__c;
                        Database.UpsertResult[] srList = Database.upsert(recordsToUpsertMap.values(), extIdField, false);
                        
                        Integer successCount = 0;
                        for (Integer idx = 0; idx < srList.size(); idx++) {
                            if (srList[idx].isSuccess()) {
                                successCount++;
                            } else {
                                String errorMsg = '';
                                for (Database.Error err : srList[idx].getErrors()) {
                                    errorMsg += err.getStatusCode() + ': ' + err.getMessage() + ' (Fields: ' + err.getFields() + ') | ';
                                }
                                System.debug('>>> FALHA NO UPSERT: ERRO: ' + errorMsg);
                            }
                        }
                        System.debug('Records inserted/updated successfully: ' + successCount + ' out of ' + recordsToUpsertMap.size());
                    } catch (Exception e) {
                        System.debug('>>> EXCEPTION FATAL NO UPSERT: ' + e.getMessage());
                    }
                }
            } else {
                System.debug('HTTP Error: ' + shipmentResponse.getStatusCode() + ' - ' + shipmentResponse.getStatus());
                System.debug('HTTP Error Details: Req: ' + shipmentRequest + ' - Res: ' + shipmentResponse);
                PMC_DH_LoggingUtils.createDHTransactionLogs(
                    shipmentRequest,
                    shipmentResponse,
                    shipmentSettings.PMC_DH_EndpointURL__c
                );
            }
        } catch (PMC_DH_Validation.CustomException ex) {
            throw new PMC_DH_Validation.CustomException('Callout Failed');
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        } finally {
            // Database.executeBatch(new PMC_IntellitransShipmentBatchUpdate(), 200);
        }
    }
}