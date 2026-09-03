/**
* @description : Wrapper class for PMC_DH_RequestForQuoteController
* @author      : Humera Rahath
* @userStory   : GDASF-37 & GDASF-140 & GDASF-78 & GDASF-23 
* @last modified on 05-18-2023
* @last modified by @mhumerarahath
**/
public class PMC_DH_RequestForQuoteWrapper {
        /**
    * @description Wrapper List for Cart
    * @author @mhumerarahath 
    * 
    **/
        @AuraEnabled
        public List<CartWrapper> lstCartWrapper{get;set;}
        /**
    * @description List of Product Families
    * @return 		List<String>
    */
        @AuraEnabled
        public List<String> lstProductFamilies{get;set;}  
        /**
    * @description Status Code and message
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
        
        /**
    * @description Wrapper class for Cart
    * @author @mhumerarahath 
    * 
    **/
        public class CartWrapper 
        {
            
            /**
    * @description Product Name of CartItem
    * @return  String 
    */
            @AuraEnabled
            public String strProductName{get;set;}
            /**
    * @description Product Id of CartItem
    * @return  String 
    */
            @AuraEnabled
            public String strProductId{get;set;}
            /**
    * @description Product Sku of CartItem
    * @return  String 
    */
            @AuraEnabled
            public String strSku{get;set;}
            /**
    * @description Total Quantity of CartItem
    * @return  String 
    */
            @AuraEnabled
            public Double strTotalQty{get;set;}
            /**
    * @description Product Img Url of CartItem
    * @return  String 
    */
            @AuraEnabled
            public String strImgSrc{get;set;}
            /**
    * @description MoT of Product
    * @return String    
    */
            @AuraEnabled
            public string strDeliveryMode{get;set;}
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
            public List<PMC_DH_PicklistWrapper> lstDeliveryModes{get;set;}
            /**
    * @description List for value label picklist
    * @return 		List<PMC_DH_PicklistWrapper>
    */
            @AuraEnabled
            public List<PMC_DH_PicklistWrapper> lstShipFrom{get;set;}
            /**
    * @description List for CartItemWrapper
    * @return 		List<CartItemWrapper>
    */
            @AuraEnabled
            public List<CartItemWrapper> lstCartItems{get;set;}
            /**
    * @description List of Contract Items of Product
    * @return 		List<ContractItemsWrapper>
    */
            @AuraEnabled
            public List<ContractItemsWrapper> lstContractItems{get;set;}
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
         * @description label for UOM
         * @author Hemant Giri Goswami
         */
        @AuraEnabled
        public string strProductUOMLabel{get;set;} // addded to handle translation for UOM
        
            /**
    * @description Item number of Product
    * @return String  
    * @author Nikhilesh  
    */
            @AuraEnabled
            public string strItemNumber{get;set;}
            /**
    * @description Requested Qty
    * @return Integer  
    * @author Nikhilesh  
    */
            @AuraEnabled
            public Integer intRequestedQty{get;set;}
            /**
    * @description Confirmed Qty
    * @return Integer  
    * @author Nikhilesh  
    */
            @AuraEnabled
            public Integer intConfirmedQty{get;set;}
            /**
    * @description List for value label picklist
    * @return 		List<PMC_DH_PicklistWrapper>
    */
            @AuraEnabled
            public List<PMC_DH_PicklistWrapper> lstProductUOM{get;set;}
            /**
    * @description List for value label picklist
    * @return 		List<PMC_DH_PicklistWrapper>
    */
            @AuraEnabled
            public List<PMC_DH_PicklistWrapper> lstPackType{get;set;}
            /**
    * @description List for value label picklist
    * @return 		List<PMC_DH_PicklistWrapper>
    */
            @AuraEnabled
            public List<PMC_DH_PicklistWrapper> lstPackagingType{get;set;}
            /**
    * @description List for value label picklist for Mode of transportation for incoterm CPT
    * @return 		List<PMC_DH_PicklistWrapper>
    */
            @AuraEnabled
            public List<PMC_DH_PicklistWrapper> lstDeliveryModesCPT{get;set;}
        }
        
        /**
    * @description Wrapper class for CartItem
    * @author @mhumerarahath 
    * 
    **/ 
        public class CartItemWrapper 
        {
            /**
    * @description RecordId of CartItem
    * @return  String 
    */
            @AuraEnabled
            public String strCartItemId{get;set;}
            /**
    * @description Quantity of CartItem
    * @return  String 
    */
            @AuraEnabled
            public Double strQuantity{get;set;}
            /**
    * @description Ship To of CartItem
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
            /**
    * @description Product Sku of CartItem
    * @return  String 
    */
            @AuraEnabled
            public String strSku{get;set;}
            
            /**
    * @description Product Name of Product
    * @return  String 
    */
            @AuraEnabled
            public String strProductName{get;set;}
            /**
    * @description Product Id of Product
    * @return  String 
    */
            @AuraEnabled
            public String strProductId{get;set;}
            /**
    * @description Source RFQ/RTD
    * @return  String 
    */
            @AuraEnabled
            public String strSource{get;set;}
            
            /**
    * @description str Contract Item Id
    * @return  String 
    */
            @AuraEnabled
            public String strContractItemId{get;set;}
            
            /**
    * @description UOM of Product
    * @return String  
    */
            @AuraEnabled
            public string strProductUOM{get;set;}
            
            /**
    * @description str Pack Type
    * @return  String 
    */
            @AuraEnabled
            public String strPackType{get;set;}
            
            /**
    * @description str SKU Pack Type
    * @return  String 
    */
            @AuraEnabled
            public String strSkuPackType{get;set;}
            
            /**
    * @description str Package Type
    * @return  String 
    */
            @AuraEnabled
            public String strPackageType{get;set;}
            
            
            /**
    * @description Contract Type
    * @return  String 
    */
            @AuraEnabled
            public string strContractType{get;set;} // GPT-34482
            
        }
        
        
        /**
    * @description Wrapper class for Contract Items
    * @author @Nikhilesh    
    */
        public class ContractItemsWrapper{
            /**
    * @description Contract Type of shipment line
    * @author @Hemant    
    */
            @AuraEnabled
            public String strContractType{get;set;}
            /**
            /**
    * @description Contract Type Label of shipment line
    * @author @Hemant    
    */
            @AuraEnabled
            public String strContractTypeLabel{get;set;} //GPT-43943
            /**
    /**
    * @description Id of Contract Item
    * @author @Nikhilesh    
    */
            @AuraEnabled
            public string strContractItemId{get;set;}
            
            // /**
            // * @description str Revised Contract Item Id
            // * @return  String 
            // */
            // @AuraEnabled
            // public String strRevisedContractItemId{get;set;}
            
            /**
    * @description Ship To of Contract Item
    * @author @Nikhilesh    
    */
            @AuraEnabled
            public PMC_DH_PicklistWrapper wrpShipTo{get;set;}
            /**
    * @description Ship From of Contract Item
    * @author @Nikhilesh    
    */
            @AuraEnabled
            public PMC_DH_PicklistWrapper wrpShipFrom{get;set;}
            /**
    * @description MoT of Contract Item
    * @author @Nikhilesh    
    */
            @AuraEnabled
            public string strDeliveryMode{get;set;}
            /**
    * @description MoT Label of Contract Item
    * @author @Nikhilesh    
    */
            @AuraEnabled
            public string strDeliveryModeLabel{get;set;} //GPT-43943
            /**
    * @description Incoterm of Contract Item
    * @author @Nikhilesh    
    */
            @AuraEnabled
            public string strIncoterm{get;set;}
            /**
    * @description Incoterm Label of Contract Item
    * @author @Nikhilesh    
    */
            @AuraEnabled
            public string strIncotermLabel{get;set;} //GPT-43943
            /**
    * @description Quantity of Contract Item
    * @author @Nikhilesh    
    */
            @AuraEnabled
            public Double intQty{get;set;}
            /**
    * @description Ordered Quantity of Contract Item
    * @author @Nikhilesh    
    */
            @AuraEnabled
            public Double intOrderedQty{get;set;}
            /**
    * @description Available Quantity of Contract Item
    * @author @Nikhilesh    
    */
            @AuraEnabled
            public Double intAvailableQty{get;set;}
            /**
    * @description Net Unit Price of Contract Item
    * @author @rohan    
    */
            /*@AuraEnabled
    public Decimal decNetUnitPrice{get;set;}*/
            
            /**
    * @description str Pack Type
    * @return  String 
    */
            @AuraEnabled
            public String strPackType{get;set;}
            /**
    * @description Pack Type Label
    * @return  String 
    */
            @AuraEnabled
            public String strPackTypeLabel{get;set;} //GPT-43943
            /**
    * @description str Package Type
    * @return  String 
    */
            @AuraEnabled
            public String strPackageType{get;set;}
            /**
    * @description Package Type Label
    * @return  String 
    */
            @AuraEnabled
            public String strPackageTypeLabel{get;set;} //GPT-43943
            /**
    * @description UOM of Product
    * @return String  
    * @author Lohitha  
    */
            @AuraEnabled
            public string strProductUOM{get;set;}
            /**
    * @description UOM Label of Product
    * @return String  
    */
            @AuraEnabled
            public string strProductUOMLabel{get;set;} //GPT-43943
            
        }
        
    }