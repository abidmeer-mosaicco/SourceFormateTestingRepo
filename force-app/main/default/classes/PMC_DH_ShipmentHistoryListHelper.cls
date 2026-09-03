/** 
* @description Helper Class for PMC_DH_ShipmentHistoryList class
* @author Mosaic Direct Dev
* Created On       :2023-Nov-08
**/
public without sharing class PMC_DH_ShipmentHistoryListHelper {
    private static final String SCHEDULED_STATUS = 'Scheduled';
    private static final String IN_TRANSIT_STATUS = 'In Transit';
/*************************************************************************
* @method Name  : getShipmentQuery
* @description  : Method for querying the Shipment Records
* @param 		  searchParams
* @param 		  effAccountId
* @return       : String
*****************************************************************************/    
    public static String getShipmentQuery(PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentSearchParameterWrapper searchParams,String effAccountId){

            String strQuery = 'SELECT Id, OrderId, PMC_CPQ_ShipTo__c, PMC_CPQ_ShipTo__r.Name,';
            strQuery += ' (SELECT Id, ShipmentId, shipment.ActualDeliveryDate, PMC_CPQ_OrderProduct__r.Order.PMC_CPQ_SAPOrderNumber__c, PMC_CPQ_OrderProduct__c,Product2.Name,PMC_CPQ_LinePONumber__c, PMC_CPQ_ShippedDate__c, ExpectedDeliveryDate, PMC_CPQ_DeliveryQuantity__c,PMC_CPQ_DeliveryLineStatus__c, PMC_CPQ_Destination__c, ShipmentItemNumber,PMC_CPQ_DeliveryItemID__c,Shipment.PMC_CPQ_SAPDeliveryID__c, Shipment.ShipmentNumber, Shipment.PMC_CPQ_DeliveryPlannedGIDate__c, Shipment.PMC_CPQ_ShippedDate__c, Shipment.PMC_CPQ_VehicleID__c,Shipment.PMC_CPQ_ETA__c,Shipment.PMC_CPQ_CurrentLocation__c FROM Delivery_Items__r '; // GDASF-20651
            if(String.isNotBlank(searchParams.strSearchTerm)){
                String strSearchPattern = '\'%' + String.escapeSingleQuotes(searchParams.strSearchTerm) + '%\'';
                strQuery += 'WHERE (PMC_CPQ_OrderProduct__r.PMC_CPQ_ShipTo__r.Name LIKE '+ strSearchPattern +' OR PMC_CPQ_OrderProduct__r.Order.PMC_CPQ_SAPOrderNumber__c LIKE '+ strSearchPattern +' OR PMC_CPQ_LinePONumber__c LIKE '+ strSearchPattern +' OR Product2.Name LIKE '+ strSearchPattern +' OR Shipment.PMC_CPQ_VehicleID__c LIKE '+ strSearchPattern +' OR PMC_CPQ_DeliveryLineStatus__c LIKE '+ strSearchPattern +')';// Vehicle Id change part of GDASF-20651
            }
            strQuery = getDateFilters(searchParams,strQuery);
            if(String.isNotBlank(searchParams.strSearchTerm) && searchParams.datFromDate != NULL && searchParams.datToDate != NULL){
                if(String.isNotBlank(searchParams.strStatus) && searchParams.strStatus == SCHEDULED_STATUS){
                	strQuery += 'AND (Shipment.PMC_CPQ_DeliveryPlannedGIDate__c >='+ String.valueOf(searchParams.datFromDate) +' AND Shipment.PMC_CPQ_DeliveryPlannedGIDate__c <= '+ String.valueOf(searchParams.datToDate)+')';
                }
                else if(String.isNotBlank(searchParams.strStatus) && searchParams.strStatus == IN_TRANSIT_STATUS){
                	strQuery += 'AND (PMC_CPQ_ShippedDate__c >='+ String.valueOf(searchParams.datFromDate) +' AND PMC_CPQ_ShippedDate__c <= '+ String.valueOf(searchParams.datToDate)+')'; 
                }
            }
            strQuery +='),';
            strQuery += '(SELECT id, PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c, PMC_CPQ_DeliveryItem__c FROM InvoiceItems__r)';
            strQuery += ' FROM OrderItem  WHERE Order.AccountId =: effAccountId';
            strQuery += ' AND Order.PMC_CPQ_SAPOrderNumber__c != null';
        
            //strQuery += ' AND (Order.Type = \'Standard Sales Order\' OR Order.Type = \'Pre-pay Sales Order\')';
            // added as part of GPT-28211 and Updated as part of GDASF-20299
        	strQuery += ' AND Order.PMC_DH_OrderTypeCode__c IN ';
        	strQuery += Label.PMC_DH_OrderTypesforShipment;
            strQuery += ' WITH SYSTEM_MODE ORDER BY Order.CreatedDate DESC LIMIT 1001';
        return strQuery;
    }
    
/*************************************************************************
* @method Name  : getDateFilters
* @description  : Method for Filtering the shipment records
* @param 		  searchParams
* @param 		  strQuery
* @return       : String
*****************************************************************************/
    public static String getDateFilters(PMC_DH_ShipmentHistoryList.PMC_DH_ShipmentSearchParameterWrapper searchParams, String strQuery){

        if(searchParams.datFromDate != NULL && searchParams.datToDate != NULL && !(String.isNotBlank(searchParams.strSearchTerm))){
            if(String.isNotBlank(searchParams.strStatus) && searchParams.strStatus == SCHEDULED_STATUS){
                strQuery += 'WHERE Shipment.PMC_CPQ_DeliveryPlannedGIDate__c >='+ String.valueOf(searchParams.datFromDate) +' AND Shipment.PMC_CPQ_DeliveryPlannedGIDate__c <= '+ String.valueOf(searchParams.datToDate);
            }
            else if(String.isNotBlank(searchParams.strStatus) && searchParams.strStatus == IN_TRANSIT_STATUS){
                strQuery += 'WHERE PMC_CPQ_ShippedDate__c >='+ String.valueOf(searchParams.datFromDate) +' AND PMC_CPQ_ShippedDate__c <= '+ String.valueOf(searchParams.datToDate); 
            }
        }
        return strQuery;
    }
    
    //GPT-44509
    /*************************************************************************
* @method Name  : getUserRegion
* @description  : Method to get the user's region (NA/BR)
* @return       : String
*****************************************************************************/
    public static String getUserRegion(){
        String strCountry = [SELECT Id, Country FROM User WHere Id =: UserInfo.getUserId() WITH USER_MODE LIMIT 1].Country;
        String strRegion = PMC_DH_CommonSystemUtils.getUserRegion(strCountry);
        return strRegion;
    }
}