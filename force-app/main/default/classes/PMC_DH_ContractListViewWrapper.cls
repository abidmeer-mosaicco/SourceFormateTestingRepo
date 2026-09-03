/**
* @description       : Wrapper for fetching Contract History
* @author            : @Lohitha sai
* @Created on        : 07-13-2023
**/
public with sharing class PMC_DH_ContractListViewWrapper {
  /**
    * * @description List of Contracts
    * * @return String
    * */
  @AuraEnabled
  public List<ContractInfoWrapper> lstContracts { get; set; }
  /**
    * * @description List of Products in Contract
    * * @return String
    * */
  @AuraEnabled
  public List<PMC_DH_PicklistWrapper> lstProductFilters { get; set; }
  /**
    * * @description List of Contract types in Contract
    * * @return String
    * */
  @AuraEnabled
  public List<PMC_DH_PicklistWrapper> lstContractType { get; set; }
  /**
    * @description Status Code and message
  * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
  */
  @AuraEnabled
  public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

      /*************************************************************************
* @method Name  : Wrapper class of Contract
* @description  : Method to fetch Contract Details
*****************************************************************************/
  public class ContractInfoWrapper {
      /**
    * * @description Id of Contract
    * * @return String
    * */
      @AuraEnabled
      public String strContractId { get; set; }
      /**
    * * @description Number of Contract
    * * @return String
    * */
  @AuraEnabled
  public String strContractNumber { get; set; }
      /**
    * * @description Set of SKUs
    * * @return List<String>
    * */
      @AuraEnabled
      public List<String> setSKU { get; set; }
      /**
    * * @description Set of Contract Types
    * * @return List<String>
    * */
      @AuraEnabled
      public List<String> setContractTypes{ get; set; }
      /**
    * * @description contract PONumber
    * * @return String
    * */
      @AuraEnabled
      public String strPONumber { get; set; }
      /**
    * * @description Contract type of contract
    * * @return String
    * */
      @AuraEnabled
      public String strContractType { get; set; }
      /**
    * * @description deliveryMode of Contract
    * * @return String
    * */
      @AuraEnabled
      public String strDeliveryMode { get; set; }
      /**
    * * @description incoterm of Quote
    * * @return String
    * */
  @AuraEnabled
  public String strIncoterm { get; set; }
      /**
    * * @description products of Contract
    * * @return String
    * */
      @AuraEnabled
      public String strProducts { get; set; }

      @AuraEnabled
      /**
    * * @description startDate of QuContractote
    * * @return String
    * */
      public Date datContractStartDate { get; set; }
      /**
    * * @description endDate of Contract
    * * @return String
    * */
      @AuraEnabled
      public Date datContractEndDate { get; set; }
      /**
    * * @description status of Contract
    * * @return String
    * */
      @AuraEnabled
      public String strStatus { get; set; }
      /**
    * * @description contractDetailLink of Contract
    * * @return String
    * */
      @AuraEnabled
      public String strContractDetailLink { get; set; }
      /**
    * * @description decTotalQuantity of Contract
    * * @return String
    * */
      @AuraEnabled
      public Decimal decTotalQuantity { get; set; }
      /**
    * * @description strTotalPrice of Contract
    * * @return String
    * */
      @AuraEnabled
      public Decimal decTotalPrice { get; set; }
        /**
    * * @description strCurrency of Contract
  * * @return String
  * */
  //added for GSMD-1669
     @AuraEnabled
      public String decPricePerTon{ get; set; }
      /**
      * * @description PriceperTon of Contract
      * * @return String
  * */
   
      @AuraEnabled
      public String strCurrencyIsoCode { get; set; }
    /**
     * @description shipTo| CR | GDASF-20981
     * @return PMC_DH_AddressWrapper.AddressViewDetails
     */
    @AuraEnabled
    public PMC_DH_AddressWrapper.AddressViewDetails shipTo{get;set;}

    /**
     * @description shipFrom  | CR | GDASF-20981
     * @return PMC_DH_AddressWrapper.AddressViewDetails
     */
    @AuraEnabled
    public PMC_DH_AddressWrapper.AddressViewDetails shipFrom{get;set;}
  

      /**
       * @description Available Quantity | CR | GDASF-20981
       * @return Decimal
       */
      @AuraEnabled
      public Decimal decAvailableQuantity{get;set;}
    }
}