/**
* @description       : Wrapper for fetching Contract History
* @author            : @Krishan Jangir
* @Created on        : 08-25-2023
**/
public with sharing class PMC_DH_LeadMgmtWrapper {


   
    /**
     * * @description List of Stage
     * * @return List<PMC_DH_PicklistWrapper>
     * */
    @AuraEnabled
    public List<PMC_DH_PicklistWrapper> lstStage { get; set; }
    /**
     * * @description List of ContactMethods
     * * @return List<PMC_DH_PicklistWrapper>
     * */
    @AuraEnabled
    public List<PMC_DH_PicklistWrapper> lstContactMethods { get; set; }
    /**
     * * @description List of RejectionResons
     * * @return List<PMC_DH_PicklistWrapper>
     * */
    @AuraEnabled
    public List<PMC_DH_PicklistWrapper> lstRejectionResons { get; set; }
    /**
     * * @description List of Contracts
     * * @return String
     * */
    @AuraEnabled
    public List<LeadInfoWrapper> lstRecordsData { get; set; }
    /**
    * @description Status Code and message
   * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
   */
   @AuraEnabled
   public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    
    /*************************************************************************
* @method Name  : Wrapper class of Lead
* @description  : Method to fetch Contract Details
*****************************************************************************/
    public class LeadInfoWrapper {
        /**
     * * @description Id of Lead
     * * @return String
     * */
        @AuraEnabled
        public String strRecordId { get; set; }
        /**
     * * @description Last Number
     * * @return String
     * */
    @AuraEnabled
    public String strLastName { get; set; }
        /**
     * * @description First Number
     * * @return String
     * */
    @AuraEnabled
    public String strFirstName { get; set; }
        /**
     * * @description Email
     * * @return String
     * */
    @AuraEnabled
    public String strEmail { get; set; }
        /**
     * * @description Phone
     * * @return String
     * */
    @AuraEnabled
    public String strPhone { get; set; }
        /**
     * * @description Region
     * * @return String
     * */
    @AuraEnabled
    public String strRegion { get; set; }
        /**
     * * @description created date
     * * @return String
     * */
    @AuraEnabled
    public Date datCreatedDate { get; set; }
        /**
     * * @description stage of lead
     * * @return String
     * */
    @AuraEnabled
    public String strStage { get; set; }
        /**
     * * @description city of lead
     * * @return String
     * */
    @AuraEnabled
    public String strCity { get; set; }
        /**
     * * @description state of city
     * * @return String
     * */
    @AuraEnabled
    public String strState { get; set; }
        /**
     * * @description product family
     * * @return String
     * */
    @AuraEnabled
    public String strProductFamily { get; set; }
        
        /**
     * * @description list of product families
     * * @return List<String>
     * */
        @AuraEnabled
        public List<String> lstProductFamiles { get; set; }
        /**
     * * @description crop
     * * @return String
     * */
    @AuraEnabled
    public String strCrop { get; set; }
        /**
     * * @description list opf crops
     * * @return List<String>
     * */
      @AuraEnabled
      public List<String> lstCrops{ get; set; }
        /**
     * * @description quantity
     * * @return Integer
     * */
    @AuraEnabled
    public String strQty { get; set; }
        /**
     * * @description Deal owner
     * * @return String
     * */
    @AuraEnabled
    public String strDealOwner { get; set; }
        /**
     * * @description Farm Size
     * * @return String
     * */
    @AuraEnabled
    public String strFarmSize { get; set; }
        /**
     * * @description Contact Preferences
     * * @return String
     * */
    @AuraEnabled
    public String strContactPreferences { get; set; }
        /**
     * * @description Contacted Date
     * * @return Date
     * */
    @AuraEnabled
    public Date datContactedDate { get; set; }
        
        /**
     * * @description Contact Method
     * * @return String
     * */
        @AuraEnabled
        public String strContactMethod { get; set; }
        /**
     * * @description comment
     * * @return String
     * */
        @AuraEnabled
        public String strComments { get; set; }
        /**
     * * @description search data
     * * @return String
     * */
        @AuraEnabled
        public String strSearchdata { get; set; }
        
    }    

}