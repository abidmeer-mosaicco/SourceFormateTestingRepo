/**
    * @description Wrapper class for order request
    * @author  Mosaic Direct Dev 
    **/ 
public class PMC_DH_OrderStatusRequestWrapper {
 /**
    * * @description List of Order items
    * * @return List<PMC_DH_OrderRequestStatusWrapper>
    * */

    public List<PMC_DH_OrderRequestStatusWrapper> listData {get;set;}
     /**
    * * @description wrapper class for order status request
    * * @return PMC_DH_OrderRequestStatusWrapper
    * */
    public class PMC_DH_OrderRequestStatusWrapper{
         /**
    * * @description Account Number
    * * @return String
    * */

        @AuraEnabled
        public string strAccountNumber{get;set;}
    }
}