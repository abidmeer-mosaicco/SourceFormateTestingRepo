/**
 * @description       : Wrapper Class for PMC_DH_DocumentFetchService
 * @author            : Humera Rahath 
 * @last modified on  : 10-26-2023
 * @last modified by  : Humera Rahath
**/
public class PMC_DH_DocumentResponseWrapper {
/**
    * * @description Identifier of Document
    * * @return PMC_DH_ResWrapper
    * */
 @AuraEnabled   
 public  PMC_DH_ResWrapper objData {get;set;}
    /**
    * @description Status Code and message
   * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
   */
  @AuraEnabled
  public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

    /*************************************************************************
* @method Name  : Wrapper class of Document
* @description  : Method to fetch Document response Details
*****************************************************************************/
public class PMC_DH_ResWrapper{
    /**
    * * @description Status Code of  Document Response
    * * @return String
    * */
    @AuraEnabled
    public String strStatusCode { get; set; }
    /**
    * * @description Data of  Document Response
    * * @return String
    * */
    @AuraEnabled
    public String strData { get; set; }
    /**
    * * @description Message of Document Response
    * * @return String
    * */
    @AuraEnabled
    public String strMessage { get; set; }
    }

}