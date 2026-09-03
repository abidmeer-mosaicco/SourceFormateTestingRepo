/**
* @description :  PMC_DH_ProductManagementClass to Update the Product Fileds
* @author      :  Sugunakar Routhu
* @userStory   :  GDASF-14068
* @last modified on 12-12-2023
* @last modified by @Sugunkar Routhu
**/
public without sharing class PMC_DH_ProductManagementClass {

    /**
    * @description   : updateProdutDetails
    * @param objProDataWrapper
    * @return        : PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    * @author        : @Sugunakar Routhu
    * @date          : 2023-12-12
    */

    @AuraEnabled
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper  updateProdutDetails(PMC_DH_ProdcutData objProDataWrapper){
      PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result=new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
      
     try{
      
        Product2 objProduct = new Product2 (Id = objProDataWrapper.strProductId);
        objProduct.PMC_CPQ_ProductClassification__c = objProDataWrapper.strProductClassification;
        objProduct.PMC_DH_CropType__c = objProDataWrapper.strCropType;
        objProduct.PMC_CPQ_GranularType__c = objProDataWrapper.strGranuleType;
        objProduct.PMC_CPQ_BusinessApplication__c = objProDataWrapper.strBusinessApplication;
        objProduct.PMC_DH_Micronutrients__c = objProDataWrapper.strMicronutrient;
        update as system objProduct;
        result=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.SUCCESS_STATUS_CODE, PMC_DH_ConstantClass.PRODUCTUPDATE);

     }Catch(Exception ex){
      result=PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(PMC_DH_ConstantClass.TECHNICAL_ERR_STATUS_CODE, PMC_DH_ConstantClass.ALL);
     }
     return result;
    }


    public class PMC_DH_ProdcutData{

      /**
     * @description product Id
     * @return String
     */
      @AuraEnabled
      public string strProductId {get;set;}

      /**
     * @description product Classification
     * @return String
     */
      @AuraEnabled
      public string strProductClassification {get;set;}

      /**
     * @description product Granular
     * @return String
     */
      @AuraEnabled
      public string strGranuleType {get;set;}

      /**
     * @description product Crop Type
     * @return String
     */
      @AuraEnabled
      public string strCropType {get;set;}

      /**
     * @description product Mircro Nutrient
     * @return String
     */
      @AuraEnabled
      public string strMicronutrient {get;set;}
      /**
     * @description product Business Application
     * @return String
     */
      @AuraEnabled
       public string strBusinessApplication {get;set;}
   }
   
}