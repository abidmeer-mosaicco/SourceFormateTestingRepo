/**
* @description : Wrapper class for PMC_DH_OrderManagementController
* @author      : Nikhilesh
* @userStory   : GDASF-609
* @last modified on 07-27-2023
* @last modified by @Nikhilesh
**/
public with sharing class PMC_DH_OrderDetailsWrapper{
    /**
* @description Web Reference Number (SF Order Id)
* @author @Nikhilesh    
*/
    @AuraEnabled
    public String strWebReferenceNumber {get;set;}
    /**
* @description SAP Order Number
* @author @Nikhilesh    
*/
    @AuraEnabled
    public String strOrderNumber {get;set;}
    /**
* @description Status of Order
* @author @Nikhilesh    
*/
    @AuraEnabled
    public String strOrderStatus {get;set;}
    /**
* @description VCO flag
* @author @Manisha    
*/
    @AuraEnabled
    public Boolean boolVCOFlag {get;set;}

    /**
* @description Wrapper class for Order Summary
* @author @Nikhilesh    
*/
    @AuraEnabled
    public OrderSummaryWrapper orderSummaryWrapper {get;set;}
    /**
* @description Wrapper class for Contract Info
* @author @Nikhilesh    
*/
    @AuraEnabled
    public ContractInfoWrapper contractInfoWrapper {get;set;}
    /**
* @description Wrapper class for Product Info
* @author @Nikhilesh    
*/
    @AuraEnabled
    public List<ProductInfoWrapper> productInfoWrapper {get;set;}
     /**
* @description Wrapper class for Contract information for validation
* @author @Nikhilesh    
*/
    @AuraEnabled
    public List<ContractWrapper> lstContractWrapper {get;set;}
/**
 * @description Status Code and message
 * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
 */
@AuraEnabled
public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    
    /**
* @description Wrapper class for Order Summary
* @author @Nikhilesh    
*/
    public class OrderSummaryWrapper{
        /**
* @description Customer Name of Order
* @author @Nikhilesh    
*/
        @AuraEnabled
        public string strCustomerName{get;set;}
        /**
* @description Order placed by
* @author @Nikhilesh    
*/
        @AuraEnabled
        public string strOrderPlacedBy{get;set;}
        /**
* @description Status of Order
* @author @Nikhilesh    
*/
        @AuraEnabled
        public string strSummaryStatus{get;set;}
        /**
* @description Date Placed of Order
* @author @Nikhilesh    
*/
        @AuraEnabled
        public Date datDatePlaced{get;set;}
        /**
* @description Sales Channel of Order
* @author @Nikhilesh    
*/
        @AuraEnabled
        public String strSalesChannel{get;set;}
        /**
* @description Currency ISO Code of Order
* @author @Nikhilesh    
*/
        @AuraEnabled
        public String strCurrencyIsoCode{get;set;}
        //GDASF-21528
      /**
* @description Request Number of Order
* @author @Humera    
*/
        @AuraEnabled
        public List<String> lstRequestNo{get;set;}
      //GDASF-21528  
  /**
* @description Protocol Number of Order
* @author @Humera    
*/   
         @AuraEnabled
        public String strProtocolNo{get;set;}
    }
    /**
* @description Wrapper class for Contract Info
* @author @Nikhilesh    
*/
    public class ContractInfoWrapper{
        /**
* @description Contract Id
* @author @Nikhilesh    
*/
        @AuraEnabled
        public String strContractId{get;set;}
        /**
* @description Contract Number
* @author @Nikhilesh    
*/
        @AuraEnabled
        public String strContractNumber{get;set;}
        /**
* @description PO Number of Contract
* @author @Nikhilesh    
*/
        @AuraEnabled
        public string strPoNumber{get;set;}
        /**
* @description Start Date of Contract
* @author @Nikhilesh    
*/
        @AuraEnabled
        public Date datContractStartDate{get;set;}
        /**
* @description End Date of Contract
* @author @Nikhilesh    
*/
        @AuraEnabled
        public Date datContractEndDate{get;set;}
        /**
* @description Type of Contract
* @author @Nikhilesh    
*/
        @AuraEnabled
        public string strContractType{get;set;}
        /**
* @description Payment Terms of Contract
* @author @Nikhilesh    
*/
        @AuraEnabled
        public string strPaymentTerms{get;set;}
        /**
* @description Boolean to check if User is Logistics Manager
* @author @Nikhilesh    
*/
        @AuraEnabled
        public Boolean boolIsLogisticsManager{get;set;}
        /**
* @description Contract Status
* @author @Rohan    
*/
        @AuraEnabled
        public String strContractStatus{get;set;}
    }
    /**
* @description Wrapper class for Product Info
* @author @Nikhilesh    
*/
    public class ProductInfoWrapper{
        /**
* @description Product Name of Order Item
* @return  String 
*/
        @AuraEnabled
        public String strProductName{get;set;}
        /**
* @description Product Id of Order Item
* @return  String 
*/
        @AuraEnabled
        public String strProductId{get;set;}
        /**
* @description Product Sku of Order
* @return  String 
*/
        @AuraEnabled
        public String strSku{get;set;}
        /**
* @description Product Img Url of Order Item
* @return  String 
*/
        @AuraEnabled
        public String strImgSrc{get;set;}
        /**
* @description Family of Product
* @return String  
* @author Nikhilesh  
*/
        @AuraEnabled
        public string strProductFamily{get;set;}
        /**
* @description UOM of Product
* @return String  
* @author Nikhilesh  
*/
        @AuraEnabled
        public string strProductUOM{get;set;}
        /**
* @description Translated UOM of Product
* @return String  
* @author Manisha  
*/
@AuraEnabled
public string strProductUOMLabel{get;set;}
        /**
* @description Item number of Product
* @return String  
* @author Nikhilesh  
*/
        @AuraEnabled
        public string strItemNumber{get;set;}
        /**
* @description Requested Qty
* @return Double  
* @author Nikhilesh  
*/
        @AuraEnabled
        public Double intRequestedQty{get;set;}
        /**
* @description Confirmed Qty
* @return Double  
* @author Nikhilesh  
*/
        @AuraEnabled
        public Double intConfirmedQty{get;set;}
        /**
* @description Total Priced Qty
* @author @Mosaic Direct Dev  
*/
        @AuraEnabled
        public Double intTotalPricedQty{get;set;}
        /**
* @description Total Unpriced Qty
* @author @Mosaic Direct Dev   
*/
        @AuraEnabled
        public Double intTotalUnpricedQty{get;set;}
        /**
* @description Delivery mode of Order Item
* @return String  
* @author Nikhilesh  
*/
        // @AuraEnabled
        // public string strDeliveryMode{get;set;}
        /**
* @description Boolean to check if user is Buyer/Super Buyer
* @return Boolean  
* @author Nikhilesh  
*/
        @AuraEnabled
        public Boolean boolIsBuyerOrSuperBuyer{get;set;}
        /**
* @description List of Shipment Items of Product
* @return 		List<ShipmentItemsWrapper>
*/
        @AuraEnabled
        public List<ShipmentItemsWrapper> lstShipmentItems{get;set;}
        /**
* @description Total Volume of product
* @return 		Double
*/
        @AuraEnabled
        public Double intVolume{get;set;}
        /**
* @description price per unit of product
* @return 		Double
*/
        @AuraEnabled
        public double pricePerUnit{get;set;}
    }
    /**
* @description Wrapper class for Shipment Items
* @author @Nikhilesh    
*/
    public class ShipmentItemsWrapper {
        /**
* @description Id of Order Item
* @author @Nikhilesh    
*/
        @AuraEnabled
        public string strOrderItemId{get;set;}
        /**
* @description Requested Shipment Date
* @author @Nikhilesh    
*/
        @AuraEnabled
        public String strRequestedShipmentDate{get;set;}
        /**
* @description Requested Qty
* @author @Nikhilesh    
*/
        @AuraEnabled
        public Double intRequestedQty{get;set;}
        /**
* @description Confirmed Qty
* @author @Nikhilesh    
*/
        @AuraEnabled
        public Double intConfirmedQty{get;set;}
        /**
* @description Total Priced Qty
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public Double intTotalPricedQty{get;set;}
        /**
* @description Total Unpriced Qty
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public Double intTotalUnpricedQty{get;set;}
        /**
* @description Ship To of Order Item
* @author @Nikhilesh    
*/
        @AuraEnabled
        public PMC_DH_PicklistWrapper wrpShipTo{get;set;}
        /**
* @description Ship From of Order Item
* @author @Nikhilesh    
*/
        @AuraEnabled
        public PMC_DH_PicklistWrapper wrpShipFrom{get;set;}
        /**
* @description MoT of Order Item
* @author @Nikhilesh    
*/
        @AuraEnabled
        public string strDeliveryMode{get;set;}
        /**
* @description Translated MoT of Order Item
* @author @Manisha    
*/
        @AuraEnabled
        public string strDeliveryModeLabel{get;set;}
        /**
* @description Incoterm of Order Item
* @author @Nikhilesh    
*/
        @AuraEnabled
        public string strIncoterm{get;set;}
         /**
* @description Translated Incoterm of Order Item
* @author @Manisha    
*/
        @AuraEnabled
        public string strIncotermLabel{get;set;}
        /**
* @description Total price of Order Item
* @author @Nikhilesh    
*/
        // @AuraEnabled
        // public Decimal decTotalPrice{get;set;}
        /**
* @description Boolean flag for shipment plan
* @author @Nikhilesh    
*/
        @AuraEnabled
        public Boolean boolShipmentPlan{get;set;}
        /**
* @description List of shipment plan of Order Item
* @author @Nikhilesh    
*/
        @AuraEnabled
        public List<ShipmentPlanWrapper> lstShipmentPlan{get;set;}
        
        /**
* @description List of Order Line of Order
* @return List<OrderLineWrapper>
*/
        @AuraEnabled
        public List<OrderLineWrapper> lstOrderLines{get;set;}


/**
* @description str Pack Type
* @return  String 
*/
@AuraEnabled
public String strPackType{get;set;}

/**
* @description Translated Pack Type
* @return  String 
*/
@AuraEnabled
public String strPackTypeLabel{get;set;}

/**
* @description str Package Type
* @return  String 
*/
@AuraEnabled
public String strPackageType{get;set;}

/**
* @description Translated Package Type
* @return  String 
*/
@AuraEnabled
public String strPackageTypeLabel{get;set;}

/** added by Lohitha
* @description str Unit of measure
* @return  String 
*/
@AuraEnabled
public String strProductUOM{get;set;}

/** added by Manisha
* @description Translated Unit of measure
* @return  String 
*/
@AuraEnabled
public String strProductUOMLabel{get;set;}
    }
    /**
* @description Wrapper class for Shipment Plan
* @author @Nikhilesh    
*/
    public class ShipmentPlanWrapper{
        /**
* @description Id of Shipment Plan Item
* @author @Nikhilesh    
*/
        @AuraEnabled
        public string strOrderItemId{get;set;}
        /**
* @description Requested Shipment Date
* @author @Nikhilesh    
*/
        @AuraEnabled
        public String strRequestedShipmentDate{get;set;}
        /**
* @description Requested Qty
* @author @Nikhilesh    
*/
        @AuraEnabled
        public Double intRequestedQty{get;set;}
        /**
* @description Confirmed Qty
* @author @Nikhilesh    
*/
@AuraEnabled
public Double intConfirmedQty{get;set;}
        
          /**
* @description Falg to check if shipment plan is editable
* @author @Mosaic Direct Dev    
*/
        @AuraEnabled
        public Boolean isEditDisabled{get;set;}
                  /**
* @description string containg pack type value
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public String strPackType{get;set;}
        
                          /**
* @description string containg package type value
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public String strPackageType{get;set;}

                 /**
* @description Sales Order Number
* @author @Manisha    
*/
        @AuraEnabled
        public string strSalesOrder{get;set;}
 /**
* @description Protocol Id
* @author @Manisha    
*/
        @AuraEnabled
        public string strProtocolNo{get;set;}
    }
    
    /**
* @description Wrapper class for Order Line
* @author @Rohan    
*/
    public class OrderLineWrapper{
        /**
* @description Id of Order Line
* @author @Rohan
*/
        @AuraEnabled
        public string strOrderItemId{get;set;}
        /**
* @description Order Item Number
* @author @Rohan
*/
        @AuraEnabled
        public string strOrderItemNumber{get;set;}
        /**
* @description Requested Shipment Date
* @author @Rohan    
*/
        @AuraEnabled
        public Date datRequestedShipmentDate{get;set;}
        /**
        /**
* @description PMC_CPQ_SAPOrderLineID
* @author @Azaam - GSMD-1867    
*/
        @AuraEnabled
        public string strSapOrderLine{get;set;}
        /**
* @description Pending Quantity
* @author @Rohan
*/
        @AuraEnabled
        public string strPendingQuantity{get;set;}
        /**
* @description Shipped Quantity
* @author @Rohan
*/
        @AuraEnabled
        public string strShippedQuantity{get;set;}
        /**
* @description Deliver Quantity
* @author @Rohan
*/
        @AuraEnabled
        public string strDeliverQuantity{get;set;}
        /**
* @description Delivery Status
* @author @Rohan
*/
        @AuraEnabled
        public string strDeliveryStatus{get;set;}
        /**
* @description Date field to store Call Price Date 
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public Date datCallPriceDate{get;set;}
        /**
* @description Boolean field to store Customer Call Price Date 
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public Boolean boolCustomerCallPriceDate{get;set;}
        /**
* @description Boolean field to store CallPriceRequestedBySystem
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public Boolean boolCallPriceRequestedBySystem{get;set;}        
        /**
* @description Boolean field to store AM FPD Price 
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public Boolean boolAMFPDPrice{get;set;}
        /**
* @description Boolean field to store Validation of Date after 24 hours 
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public Boolean boolDateValidation{get;set;}
        /**
* @description String field to store Total Quantity
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public String strTotalQuantity{get;set;}
        /**
* @description String field to store Price Per Ton
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public String strPricePerTon{get;set;}
        /**
* @description String field to store Total Price
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public String strTotalPrice{get;set;}
        /**
* @description Boolean field to store Price Requested or Not Value
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public Boolean boolPriceNotRequested{get;set;}
        /**
* @description String field to UnitOfMeasure
* @author @Mosaic Direct Dev     
*/
        @AuraEnabled
        public String strUnitOfMeasure{get;set;}
    }
    /**
* @description Wrapper class to Validate Contract information
* @author Mosaic Direct Dev 
*/
    public class ContractWrapper{
        /**
* @description SKU of product
* @return String
*/
        @AuraEnabled
        public string strSku{get;set;}
        /**
* @description Incoterm
* @return String   
*/
        @AuraEnabled
        public string strIncoterm{get;set;}
        /**
* @description Ship To
* @return String   
*/
        @AuraEnabled
        public string strShipTo{get;set;}
        /**
* @description Ship From
* @return String   
*/
        @AuraEnabled
        public string strShipFrom{get;set;}

        /**
* @description Available Quantity
* @return String   
*/
		@AuraEnabled
        public string strAvailableQty{get;set;}
                /**
* @description Mode of Transportation
* @return String   
*/
        @AuraEnabled
        public string strDeliveryMode{get;set;}
}
    
}