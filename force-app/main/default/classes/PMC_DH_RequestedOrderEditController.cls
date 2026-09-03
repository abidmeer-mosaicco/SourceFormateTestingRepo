/** 
* @description Controller class for editing Requested orders
* @author Mosaic Direct Dev
* Created On       :2023-Oct-19
**/
public class PMC_DH_RequestedOrderEditController {
    
    /*************************************************************************
* @method Name  : getUpdatedDetails
* @description  : Method to return updated order details for requested order
* @param         editRequestWrapper
* @author        Mosaic Direct Dev 
* @return        String 
*****************************************************************************/
    @AuraEnabled
    public static String getUpdatedDetails(EditRequestWrapper editRequestWrapper){
        HTTPResponse response;
        String responseBody;
        PMC_DH_OrderEditWrapper ordWrapper = new PMC_DH_OrderEditWrapper();
        PMC_DH_OrderEditWrapper.PMC_DH_RequestWrapper ordResponseWrapper = new PMC_DH_OrderEditWrapper.PMC_DH_RequestWrapper();        
        PMC_DH_OrderEditResponseWrapper resultWrapper = new PMC_DH_OrderEditResponseWrapper();
        try{
            response = PMC_DH_OrderSchedulingService.updateSchedulingRequest(editRequestWrapper);
            if((response.getStatusCode()==200 || response.getStatusCode()==201 || response.getStatusCode()==202)){
                responseBody = (String)response.getBody();
                ordWrapper = (PMC_DH_OrderEditWrapper)JSON.deserialize(responseBody,PMC_DH_OrderEditWrapper.class);
                ordResponseWrapper = ordWrapper.lstResultData;
                resultWrapper.strMessage = 'Success';
                resultWrapper.strQty = ordResponseWrapper.strCustomerReqQty;
                resultWrapper.strReqId = ordResponseWrapper.strReqId;
                resultWrapper.strShipmentDate = ordResponseWrapper.strReqDelDat;
            }
            else{
                resultWrapper.strMessage = 'Error';
            }
            resultWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'OrderEdit');
        }
        catch(Exception ex){
            resultWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            //throw new AuraHandledException(ex.getMessage() + ex.getStackTraceString());
        }
        return JSON.serialize(resultWrapper);
    }
    /**
* @description        
* @author              Mosaic Direct Dev 
* @group              
* @last modified on   10-27-2023
* @last modified by    Mosaic Direct Dev 
**/
   
    public class EditRequestWrapper{
            /**
* * @description strOrderLineId
* * @return string
* */
    
        @AuraEnabled
        public string strOrderLineId{get;set;}
            /**
* * @description strReqQty
* * @return string
* */
    
                @AuraEnabled
        public string strReqQty{get;set;}
            /**
* * @description strReqShipmentDate
* * @return string
* */
    
                @AuraEnabled
        public string strReqShipmentDate{get;set;}
            /**
* * @description responseData
* * @return responseData
* */
    
                @AuraEnabled
        public string responseData{get;set;}
    }
}