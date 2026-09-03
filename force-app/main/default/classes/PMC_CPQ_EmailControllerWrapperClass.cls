/**
* @description This is a Wrapper class for  PMC_CPQ_ApprovalRequestEmailTempClass to avoid exceeded public count violation.
* @author Jaswanth Vaithiswaran,Jeyanthi Muthaiah
* @storynumber GDASF-19713
*/public with sharing class PMC_CPQ_EmailControllerWrapperClass {

   /**
* @description rawMaterialQuantitySum -to store the Sum of Quantity Tons of Same Raw Materilas which have same Product SKU
*/
   public Map<String, Decimal> rawMaterialQuantitySum { get; set; }   
    /**
* @description rawMaterialListCFRAvg -to store the Avg ListCFR of Same Raw Materilas which have same Product SKU
*/
  public Map<String, Decimal> rawMaterialListCFRAvg { get; set; }  
    /**
* @description rawMaterialSoldCFRAvg -to store the Avg SoldCFR of Same Raw Materilas which have same Product SKU
*/
     public Map<String, Decimal> rawMaterialSoldCFRAvg { get; set; }
    /**
* @description rawMaterialName -to store the Names of Raw Materilas which have same Product SKU
*/
   public Map<String, String> rawMaterialName { get; set; }  
    /**
* @description rawMaterialSumsKey -to store the Unique Raw Materials in a List
*/
   public Set<String> rawMaterialSumsKey { get; set; }
  /**
* @description This method is the constructor of this class
*/	 
    public PMC_CPQ_EmailControllerWrapperClass(){
        
        rawMaterialQuantitySum = new Map<String,Decimal>();
        rawMaterialSumsKey = new Set<String>();            
        rawMaterialListCFRAvg = new Map<String,Decimal>();
        rawMaterialSoldCFRAvg = new Map<String,Decimal>();
        rawMaterialName=new Map<String,String>();
    }
    
}