/**
* @description       : Controller for Document Download
* @author            : Humera Rahath
* @last modified on 01-27-2024
* @last modified by Lohitha
* @Created on        : 10-20-2023
**/
public without sharing class PMC_DH_DocumentDownloadController {
    public static final List<Integer> STATUS_CODES = new List<Integer>{200, 201, 400};
    public static final String MESSAGE_INVALID='Invalid Document identifier with document number combination.';
    public static final String ERROR_MESSAGE='Document could not be retrieved, Output is not triggered in SAP for this document';
    //GPT-35254
    public static final String MESSAGE_INVALID_COA='ZCOA document cannot be generated for the delivery as it not Quality management';
    /*************************************************************************
* @method Name  : getDocDownload
* @description  : Method to download document
* @param         objData
* @return       : PMC_DH_DocumentResponseWrapper
*****************************************************************************/
    @AuraEnabled
    public static PMC_DH_DocumentResponseWrapper  getDocDownload(PMC_DH_DocumentWrapper.PMC_DH_ReqWrapper objData){
        PMC_DH_DocumentResponseWrapper resWrapper=new PMC_DH_DocumentResponseWrapper();
        try{
            HttpResponse response = PMC_DH_DocumentFetchService.getDoc(objData);
            if(STATUS_CODES.contains(response.getStatusCode())){
                String responseBody = (String)response.getBody();
                resWrapper = (PMC_DH_DocumentResponseWrapper)JSON.deserialize(responseBody, PMC_DH_DocumentResponseWrapper.class);
                if(response.getStatusCode() == 200){
                    handleStatusCode200(resWrapper);
                    }else {
                    resWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('112', 'Document');
                    }
            }else{
                resWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'TechnicalError');
            }
        }catch(Exception objException)
        {
            PMC_ErrorLogClass.processException(objException);
            resWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100','ALL');
        }
        return resWrapper;
    }

    private static void handleStatusCode200(PMC_DH_DocumentResponseWrapper  resWrapper) {
        String statusCode = resWrapper.objData.strStatusCode;
        String message = resWrapper.objData.strMessage;

        if ('E'.equals(statusCode) && (MESSAGE_INVALID.equals(message) || MESSAGE_INVALID_COA.equals(message))) {//GPT-35254
            resWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'TechnicalError');
        } else if ('E'.equals(statusCode) && ERROR_MESSAGE.equals(message)) {
            resWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('113', 'TryAgain');
        } else {
            resWrapper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('112', 'Document');
        }
    }
}