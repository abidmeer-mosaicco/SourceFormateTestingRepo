/**
* @description : Wrapper class for PMC_DH_RequestToDeliverController
* @author      : Krishan Jangir
* @userStory   : GDASF-8927
* @last modified on 06-28-2023
* @last modified by @krishanjangir
**/
public class PMC_DH_RequestToDeliverWrapper {
                /**
* @description bool value
* @return  Boolean 
* 
**/
        @AuraEnabled
        public Boolean isVCO{get;set;}
    /**
* @description Wrapper List for Cart Info
* @author @krishanjangir 
* 
**/
    @AuraEnabled
    public List<CartWrapper> lstCartWrapper{get;set;}

   /**
 * @description Status Code and message
 * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
 */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    
    /**
* @description Wrapper Class for Cart Wrapper
* @author @krishanjangir 
* 
**/
    public class CartWrapper{
        /**
* @description bool value
* @return  Boolean 
* 
**/
        @AuraEnabled
        public Boolean boolThirdParty{get;set;}
        /**
* @description Name for Product
* @return  String 
* 
**/
        @AuraEnabled
        public String strProductName{get;set;}
        /**
* @description Id for Product
* @return  String  
* 
**/
        @AuraEnabled
        public String strProductId{get;set;}
        /**
* @description SKU for Product
* @return  String 
* 
**/
        @AuraEnabled
        public String strSku{get;set;}
        /**
* @description Product Img Url of Product
* @return  String 
*/
        @AuraEnabled
        public String strImgSrc{get;set;}
        /**
* @description Id of Contract
* @return  String 
*/
        @AuraEnabled
        public String strContractId{get;set;}
        /**
* @description Start Date of Contract
* @return  Date 
*/
        @AuraEnabled
        public Date datContractStartDate{get;set;}
        /**
* @description End Date of Contract
* @return  Date 
*/
        @AuraEnabled
        public Date datContractEndDate{get;set;}
        /**
* @description PO no. of Contract
* @return  String 
*/
        @AuraEnabled
        public String strContractPONumber{get;set;}
        /**
* @description total quantity
* @return  Long 
*/
        @AuraEnabled
        public Long intTotalQuantity{get;set;}
        /**
* @description Item no of product
* @return  String 
*/
        @AuraEnabled
        public String strItemNumber{get;set;}
        /**
* @description List for value label picklist
* @return 		List<PMC_DH_PicklistWrapper>
*/
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstDeliverAddressValidated{get;set;}
        /**
* @description List for value label picklist
* @return 		List<PMC_DH_PicklistWrapper>
*/
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstShipTo{get;set;}
        /**
* @description List for value label picklist
* @return 		List<PMC_DH_PicklistWrapper>
*/
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstIncoterms{get;set;}
        /**
* @description List for value label picklist
* @return 		List<PMC_DH_PicklistWrapper>
*/
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstShipFrom{get;set;}
        /**
* @description List for value label picklist
* @return 		List<PMC_DH_PicklistWrapper>
*/
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstDeliveryModes{get;set;}
        /**
* @description List for value label picklist
* @return 		List<PMC_DH_PicklistWrapper>
*/
        @AuraEnabled
        public List<CartItemWrapper> lstCartItems{get;set;}
        /**
* @description Wrapper List for ContractListItem
* @author @krishanjangir 
* 
**/
        @AuraEnabled
        public List<ContractItem> lstContractItems{get;set;}
        /**
* @description object of ContractSummaryWrapper
* @return ContractSummaryWrapper 
* 
**/
        @AuraEnabled
        public ContractSummaryWrapper objContractSummaryWrapper{get;set;}
        
        /**
* @description Wrapper List for Frequency
* @return 		List<PMC_DH_PicklistWrapper> 
* 
**/
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstFrequency{get;set;}
        
           
        /**
* @description Wrapper List for Pack Type
* @return 		List<PMC_DH_PicklistWrapper> 
* 
**/
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstPackType{get;set;}
        
           
        /**
* @description Wrapper List for Package type
* @return 		List<PMC_DH_PicklistWrapper> 
* 
**/
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstPackagingType{get;set;}
        
                /**
        * @description Wrapper List for strCartReferenceNumber
        * @return 		String
        * 
        **/
        @AuraEnabled
        public String strCartReferenceNumber{get;set;}
    }
    
    /**
* @description Wrapper class for CartItem
* @author @krishanjangir
* 
**/
    public class ContractItem{
        /**
* @description RecordId of Subscription
* @return  String 
*/
        @AuraEnabled
        public String strContractItemId{get;set;}
        /**
* @description Total Quantity of CartItem
* @return  Long 
*/
        @AuraEnabled
        public Long intQuantity{get;set;}
        /**
* @description Total Quantity of CartItem
* @return  Long 
*/
        @AuraEnabled
        public Long intAvailableQuantity{get;set;}
        /**
* @description Total Quantity of CartItem
* @return  Long 
*/
        @AuraEnabled
        public Long intOrderQuantity{get;set;}
        /**
* @description Delivery Address of CartItem
* @return  String 
*/
        @AuraEnabled
        public String strShipTo{get;set;}
        /**
* @description Delivery Mode of CartItem
* @return  String 
*/
        @AuraEnabled
        public String strDeliveryMode{get;set;}
        /**
* @description Incoterms of CartItem
* @return  String 
*/
        @AuraEnabled
        public String strIncoterms{get;set;}
        /**
* @description Ship From of CartItem
* @return  String 
*/
        @AuraEnabled
        public String strShipFrom{get;set;}
    }
    /**
* @description Wrapper class for CartItem
* @author @krishanjangir
* 
**/
    public class CartItemWrapper{
                    /**

* @description strPackageTypeFlag of CartItem

* @return  String 

*/

        @AuraEnabled

        public Boolean strPackageTypeFlag{get;set;}
        /**
* @description CartItemNumber of CartItem
* @return  String 
*/
        @AuraEnabled
        public string strCartItemNumber{get;set;}
        /**
* @description customer name of CartItem
* @return  String 
*/
        @AuraEnabled
        public String strCustomerName{get;set;}
        /**
* @description Fiscal number of CartItem
* @return  Integer 
*/
        @AuraEnabled
        public Integer intFiscalNumber{get;set;}
        /**
* @description Fiscal date of CartItem
* @return  Date 
*/
@AuraEnabled
public Date datNotaFiscalDate{get;set;}
        /**
* @description Sell out price of CartItem
* @return  Decimal 
*/
        @AuraEnabled
        public Decimal decSellOutPrice{get;set;}
        /**
* @description RecordId of CartItem
* @return  String 
*/
        @AuraEnabled
        public String strCartItemId{get;set;}
        /**
* @description Total Quantity of CartItem
* @return  Long 
*/
        @AuraEnabled
        public Long intQuantity{get;set;}
        /**
* @description Delivery Address of CartItem
* @return  String 
*/
        @AuraEnabled
        public String strShipTo{get;set;}
        /**
* @description Delivery Mode of CartItem
* @return  String 
*/
        @AuraEnabled
        public String strDeliveryMode{get;set;}
         /**
* @description Delivery Mode label of CartItem
* @return  String 
*/
@AuraEnabled
public String strDeliveryModeLabel{get;set;}

        /**
* @description Incoterms of CartItem
* @return  String 
*/
        @AuraEnabled
        public String strIncoterms{get;set;}
         /**
* @description Incoterms label of CartItem
* @return  String 
*/
@AuraEnabled
public String strIncotermsLabel{get;set;}

        /**
* @description Ship From of CartItem
* @return  String 
*/
        @AuraEnabled
        public String strShipFrom{get;set;}
        /**
* @description Requested date of CartItem
* @return  Date 
*/
        @AuraEnabled
        public Date datRequestedShipmentDate{get;set;}
        
        /**
* @description Source RFQ/RTD
* @return  String 
*/
        @AuraEnabled
        public String strSource{get;set;}
        
        /**
* @description Delivery PO Number
* @return  String 
*/
        @AuraEnabled
        public String strDeliveryPONumber{get;set;}
        /**
* @description Frequency
* @return  String 
*/
        @AuraEnabled
        public String strFrequency{get;set;}
        /**
* @description PO Number increment
* @return  Integer 
*/
        @AuraEnabled
        public Integer intPONumberIncrement{get;set;}
        /**
* @description Boolean check on Shipment plan
* @return  Boolean 
*/
        @AuraEnabled
        public Boolean boolShipmentPlan{get;set;}
        /**
* @description List for Shipment Plan
* @return 		List<ShipmentPlanWrapper>
*/
        @AuraEnabled
        public List<ShipmentPlanWrapper> lstShipmentPlan{get;set;}
        
        
        
        /**
* @description Delivery Instrucitons
* return String
*/
        @AuraEnabled
        public String strDeliveryInstructions{get;set;}
        
        /**
* @description Subscription Id
* return String
*/
        @AuraEnabled
        public String strSubscriptionId{get;set;}
        

         /**
        * @description Cart Reference Number MD-0000000001-1-1
        * return String
        */
        @AuraEnabled
        public String strCartItemReferenceNumber{get;set;}
         /**
        * @description Cart Reference Number MD-0000000001-1-1
        * return String
        */
        @AuraEnabled
        public String strPackType{get;set;}
     
          /**
        * @description Cart Reference Number MD-0000000001-1-1
        * return String
        */
        @AuraEnabled
        public String strPackageType{get;set;}
          /**
        * @description Cart Reference Number MD-0000000001-1-1
        * return String
        */
        @AuraEnabled
        public String strPackageTypeOld{get;set;}
       
        /**
* @description str SKU Pack Type
* @return  String 
*/
@AuraEnabled
public String strSkuPackType{get;set;}
        /**
* @description Net Unit Price of Contract Item
* @author @rohan    
*/
        /*@AuraEnabled
public Decimal decNetUnitPrice{get;set;}*/
        
        
    }
    /**
* @description Wrapper class for Shipment Plan
* @author @Nikhilesh
**/
    public class ShipmentPlanWrapper{
        /**
* @description Cart Item Id
* @return  String 
*/
        @AuraEnabled
        public String strCartItemId{get;set;}
        /**
* @description Delivery PO Number
* @return  String 
*/
        @AuraEnabled
        public String strDeliveryPONumber{get;set;}
        /**
* @description Quantity
* @return Long 
*/
        @AuraEnabled
        public Long intQuantity{get;set;}
        /**
* @description Requested Shipment Date
* @return  Date 
*/
        @AuraEnabled
        public Date datRequestedShipmentDate{get;set;}

 /**
        * @description Cart Reference Number MD-0000000001-1-1
        * return String
        */
        @AuraEnabled
        public String strCartItemReferenceNumber{get;set;}
        
    }
    
    /**
* @description Wrapper class for Contract Summary
* @author @ajeet
**/
    public class ContractSummaryWrapper{
        /**
* @description Contract Number
* @return  String 
*/
        @AuraEnabled
        public String strContractNumber{get;set;}
        /**
* @description PO Number
* @return  String 
*/
        @AuraEnabled
        public String strPoNumber{get;set;}
        /**
* @description Contract Type
* @return  String 
*/
        @AuraEnabled
        public String strContractType{get;set;}
        /**
* @description Contract Start date
* @return  Date
*/
        @AuraEnabled
        public Date datContractStartDate{get;set;}
        /**
* @description Contract End date
* @return  Date
*/
        @AuraEnabled
        public Date datContractEndDate{get;set;}
        /**
* @description Payment term selected
* @return  String 
*/
        @AuraEnabled
        public String strPaymentTermSelected{get;set;}
        /**
* @description Contract Status
* @author @Rohan    
*/
        @AuraEnabled
        public String strContractStatus{get;set;}
        /**
* @description CurrencyIsoCode
* @author @Manisha    
*/
        @AuraEnabled
        public String strCurrencyIsoCode{get;set;}
         /**
        * @description Status Code and message
        * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }
}