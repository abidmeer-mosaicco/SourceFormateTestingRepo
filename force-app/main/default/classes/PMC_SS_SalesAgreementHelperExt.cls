/**
* @description This class will be used as an extension of PMC_SS_SalesAgreementHelper.
* @author Chetna
* @storynumber GDASF-15372 
*/

public without sharing class PMC_SS_SalesAgreementHelperExt {
     /**
* @description - Method to create updated map of  Map of Sales Agreement Id and Map of Product and Product Schedules List 
* @param objsalesAgreementProductSchedule - SalesAgreementProductSchedule record to be considered
* @param mapSalesAgreementIdAndMapOfProductAndProductSchedulesList - Map of Sales Agreement Id and Map of Product and Product Schedules List
* @param mapSalesAgreementProductAndSalesAgreementIdMap - Map of Sales Agreement Product and Sales Agreement Id
* @return mapSalesAgreementIdAndMapOfProductAndProductSchedulesList - Updated map
 */
    public static  Map<Id,Map<String,List<SalesAgreementProductSchedule>>> createMapSalesAgreementIdAndMapOfProductAndProductSchedulesList(SalesAgreementProductSchedule objsalesAgreementProductSchedule,Map<Id,Map<String,List<SalesAgreementProductSchedule>>> mapSalesAgreementIdAndMapOfProductAndProductSchedulesList,Map<Id,Id> mapSalesAgreementProductAndSalesAgreementIdMap){
         if(!mapSalesAgreementIdAndMapOfProductAndProductSchedulesList.containsKey(mapSalesAgreementProductAndSalesAgreementIdMap.get(objsalesAgreementProductSchedule.SalesAgreementProductId)) )
         {
                    mapSalesAgreementIdAndMapOfProductAndProductSchedulesList.put(mapSalesAgreementProductAndSalesAgreementIdMap.get(objsalesAgreementProductSchedule.SalesAgreementProductId),new Map<String,List<SalesAgreementProductSchedule>>{objsalesAgreementProductSchedule.SalesAgreementProduct.Product.PMC_CPQ_ProductFamily__c => new List<SalesAgreementProductSchedule>{objsalesAgreementProductSchedule} });
                }else {
                    if(!mapSalesAgreementIdAndMapOfProductAndProductSchedulesList.get(mapSalesAgreementProductAndSalesAgreementIdMap.get(objsalesAgreementProductSchedule.SalesAgreementProductId)).containsKey(objsalesAgreementProductSchedule.SalesAgreementProduct.Product.PMC_CPQ_ProductFamily__c)){
                        mapSalesAgreementIdAndMapOfProductAndProductSchedulesList.get(mapSalesAgreementProductAndSalesAgreementIdMap.get(objsalesAgreementProductSchedule.SalesAgreementProductId)).put(objsalesAgreementProductSchedule.SalesAgreementProduct.Product.PMC_CPQ_ProductFamily__c,new List<SalesAgreementProductSchedule>{objsalesAgreementProductSchedule});     
                    }else{ 
                        mapSalesAgreementIdAndMapOfProductAndProductSchedulesList.get(mapSalesAgreementProductAndSalesAgreementIdMap.get(objsalesAgreementProductSchedule.SalesAgreementProductId)).get(objsalesAgreementProductSchedule.SalesAgreementProduct.Product.PMC_CPQ_ProductFamily__c).add(objsalesAgreementProductSchedule);
                    }
                }
        return mapSalesAgreementIdAndMapOfProductAndProductSchedulesList;
    }
    
    
     /**
* @description - Method to create updated Rebate Program Id and Product Quantity Map
* @param salesAgreeementAndRebate - Wrapper class of Sales Agreement and Rebate details
* @return mapRebateProgramIdAndProductQuantityMap - Updated map
 */
    public static Map<Id,Map<String,Integer>> createRebateProgramIdAndProductQuantityMap(SalesAgreeementAndRebateWrapper salesAgreeementAndRebate)
    {
        Integer intNewQuantity;
      	RebateProgram objRebateProgram = salesAgreeementAndRebate.objRebateProgram;
        SalesAgreementProductSchedule objSalesAgreementProductSchedule = salesAgreeementAndRebate.objSalesAgreementProductSchedule;
        String salesAgreementProduct = salesAgreeementAndRebate.salesAgreementProduct;
        Map<Id,Map<String,Integer>> mapRebateProgramIdAndProductQuantityMap = salesAgreeementAndRebate.mapRebateProgramIdAndProductQuantityMap;
        if (mapRebateProgramIdAndProductQuantityMap.containsKey(objRebateProgram.id) && !mapRebateProgramIdAndProductQuantityMap.get(objRebateProgram.id).containsKey(salesAgreementProduct) && (objSalesAgreementProductSchedule.StartDate >= objRebateProgram.StartDate && objSalesAgreementProductSchedule.EndDate <= objRebateProgram.EndDate))
            {
            mapRebateProgramIdAndProductQuantityMap.get(objRebateProgram.id).put(salesAgreementProduct,objSalesAgreementProductSchedule.ForecastedQuantity);
        }else if(mapRebateProgramIdAndProductQuantityMap.containsKey(objRebateProgram.id) && mapRebateProgramIdAndProductQuantityMap.get(objRebateProgram.id).containsKey(salesAgreementProduct) && (objSalesAgreementProductSchedule.StartDate >= objRebateProgram.StartDate && objSalesAgreementProductSchedule.EndDate <= objRebateProgram.EndDate))
            {
                        intNewQuantity = mapRebateProgramIdAndProductQuantityMap.get(objRebateProgram.id).get(salesAgreementProduct)+objSalesAgreementProductSchedule.ForecastedQuantity;
                        mapRebateProgramIdAndProductQuantityMap.get(objRebateProgram.id).put(salesAgreementProduct,intNewQuantity);
                    }
         return mapRebateProgramIdAndProductQuantityMap;
           
                }
    

     /**
* @description - Method to Calculate Benefit Based On Type
* @param objProgramRebateTypeBenefit - Program Rebate Type Benefit Record
* @param mapProductAndQuantity - Map of Sales Agreement Product and respective Quantity
* @param strProd - Product Id
* @return objProgramRebateTypeBenefit - Updated object record
 */
    public static ProgramRebateTypeBenefit calculateBenefitOnType(ProgramRebateTypeBenefit objProgramRebateTypeBenefit, Map<String,Integer> mapProductAndQuantity,string strProd){
                            if(objProgramRebateTypeBenefit.ProgramRebateType.PMC_SS_Type__c != 'ZRS3'){
                        objProgramRebateTypeBenefit.PMC_SS_Projected_Incentive__c = PMC_SS_SalesAgreementHelper.calculateProjectedIncentiveAtOtherBenefits(mapProductAndQuantity,objProgramRebateTypeBenefit,strProd);
                    }
                    else if(objProgramRebateTypeBenefit.ProgramRebateType.PMC_SS_Type__c == 'ZRS3' ){
                        objProgramRebateTypeBenefit.PMC_SS_Projected_Incentive__c = calculateProjectedIncentiveAtGrowthBenefit(mapProductAndQuantity,objProgramRebateTypeBenefit,strProd);
                    }
        return objProgramRebateTypeBenefit;
    }
    
     /**
* @description - Method to Update Rebate Type And Benefit Map
* @param mapRebateTypeAndBenefit - Map of RebateType And Benefit
* @param objProgramRebateTypeBenefit - Benfit Record
* @return mapRebateTypeAndBenefit - Updated map
 */    
    
    public static Map<Id,List<ProgramRebateTypeBenefit>> updateRebateTypeAndBenefitMap(Map<Id,List<ProgramRebateTypeBenefit>>  mapRebateTypeAndBenefit,ProgramRebateTypeBenefit objProgramRebateTypeBenefit ){
         if(mapRebateTypeAndBenefit.containsKey(objProgramRebateTypeBenefit.ProgramRebateTypeId)){
                        mapRebateTypeAndBenefit.get(objProgramRebateTypeBenefit.ProgramRebateTypeId).add(objProgramRebateTypeBenefit);
                    }else{
                        mapRebateTypeAndBenefit.put(objProgramRebateTypeBenefit.ProgramRebateTypeId,new List<ProgramRebateTypeBenefit>{objProgramRebateTypeBenefit}); 
                    }  
        return mapRebateTypeAndBenefit;
    }
    
     /**
* @description - Method to Update Rebate Program And Rebate Type Map
* @param mapRebateProgramAndRebateTypeMap - Map of Rebate Program And Rebate Type Map
* @param objProgramRebateTyp - Program Rebate Type Record
* @return mapRebateProgramAndRebateTypeMap - Updated map
 */ 
    
    public static Map<Id,List<ProgramRebateType>> updateRebateProgramAndRebateTypeMap(Map<Id,List<ProgramRebateType>> mapRebateProgramAndRebateTypeMap,ProgramRebateType objProgramRebateTyp){
        if(!mapRebateProgramAndRebateTypeMap.containsKey(objProgramRebateTyp.RebateProgramId)){
                mapRebateProgramAndRebateTypeMap.put(objProgramRebateTyp.RebateProgramId,new List<ProgramRebateType>{objProgramRebateTyp});
            }else {
                mapRebateProgramAndRebateTypeMap.get(objProgramRebateTyp.RebateProgramId).add(objProgramRebateTyp);
            }
        return mapRebateProgramAndRebateTypeMap;
    }
    
     /**
* @description - Method to Calculate Projected Incentive At Growth Rebate Type
* @param mapProductAndQuantity - Map of Sales Agreement Product And Quantity
* @param objProgramRebateTypeBenefit - Program Rebate Type Benefit Record
* @param strProd - Sales Agreement Product Id
* @return Projected Incentive 
 */    
     public static Decimal calculateProjectedIncentiveAtGrowthBenefit(Map<String,Integer> mapProductAndQuantity,ProgramRebateTypeBenefit objProgramRebateTypeBenefit, String strProd){
        if( mapProductAndQuantity.get(strProd) > objProgramRebateTypeBenefit.MinimumQualifyingValue){
            objProgramRebateTypeBenefit.PMC_SS_Projected_Incentive__c = (mapProductAndQuantity.get(strProd) - objProgramRebateTypeBenefit.MinimumQualifyingValue)*objProgramRebateTypeBenefit.BenefitValue;
        }else if( mapProductAndQuantity.get(strProd) <= objProgramRebateTypeBenefit.MinimumQualifyingValue){
            objProgramRebateTypeBenefit.PMC_SS_Projected_Incentive__c = 0;
        } 
                
        return objProgramRebateTypeBenefit.PMC_SS_Projected_Incentive__c;
    }
    
       /**
* @description - Method to calculate Forecasted Quantity & Projected Incentives on a rebate type object based on update in related sales agreement
* @param mapRebateTypeAndRebateTypeBenefitMap - Map of mapRebateTypeAndRebateTypeBenefitMap.
*@param lstRebateType - List of lstRebateType
*@return mapRebateProgramAndRebateTypeMap
*  */
    public static Map<Id,List<ProgramRebateType>> calculateIncentiveAtRebateType(Map<Id,List<ProgramRebateTypeBenefit>> mapRebateTypeAndRebateTypeBenefitMap , List<ProgramRebateType> lstRebateType){
        Map<Id,List<ProgramRebateType>> mapRebateProgramAndRebateTypeMap = new Map<Id,List<ProgramRebateType>>();
        Integer intTotalForecastedQuantity;
        Integer intTotalProjectedIncentive;
        for(ProgramRebateType objProgramRebateTyp : lstRebateType){
            intTotalForecastedQuantity = 0;
            intTotalProjectedIncentive = 0;
            mapRebateProgramAndRebateTypeMap = updateRebateProgramAndRebateTypeMap(mapRebateProgramAndRebateTypeMap, objProgramRebateTyp);
            for(ProgramRebateTypeBenefit objProgramRebateTypeBeneft : mapRebateTypeAndRebateTypeBenefitMap.get(objProgramRebateTyp.id)){
                if(objProgramRebateTypeBeneft.PMC_SS_Forecasted_Quantity__c != null && objProgramRebateTypeBeneft.PMC_SS_Projected_Incentive__c != null){
                    intTotalForecastedQuantity = Integer.valueOf(intTotalForecastedQuantity+objProgramRebateTypeBeneft.PMC_SS_Forecasted_Quantity__c);
                    intTotalProjectedIncentive = Integer.valueOf(intTotalProjectedIncentive+objProgramRebateTypeBeneft.PMC_SS_Projected_Incentive__c);
                }
            }
            objProgramRebateTyp.PMC_SS_Forecasted_Quantity__c = intTotalForecastedQuantity;
            objProgramRebateTyp.PMC_SS_Projected_Incentive__c = intTotalProjectedIncentive;
        }
        if(Schema.sObjectType.ProgramRebateType.isUpdateable()){
            update lstRebateType;
        }
        return mapRebateProgramAndRebateTypeMap;
    }
    
    
        /**
* @description - Method to fetch related Rebate object records of updated sales agreement records based on product schedules
* @param mapSalesAgreementIdAndMapOfProductAndProductSchedulesList - Map of sales agreement and related products and product schedules.
* @param setupdatedSAids - set of updated north america sales agreement ids.
*  */
    public static  void fetchRebateObjectsValuesForCalculation(Map<Id,Map<String,List<SalesAgreementProductSchedule>>> mapSalesAgreementIdAndMapOfProductAndProductSchedulesList,Set<id> setupdatedSAids ){
        Set<Id> setRebateProgramIds = new Set<Id>();
        Map<Id,Map<String,Integer>> mapRebateProgramIdAndProductQuantityMap = new Map<Id,Map<String,Integer>>();
        Map<String,List<SalesAgreementProductSchedule>> mapTempSalesProductSchedule = new Map<String,List<SalesAgreementProductSchedule>>();
        List<RebateProgram> lstRebatePrograms = [Select id, PMC_SS_Projected_Incentive__c,PMC_SS_SalesAgreement__c,EndDate,StartDate From RebateProgram where PMC_SS_SalesAgreement__c =:setupdatedSAids WITH USER_MODE ];
        for(RebateProgram objRebateProgram : lstRebatePrograms) {
            mapTempSalesProductSchedule = mapSalesAgreementIdAndMapOfProductAndProductSchedulesList.get(objRebateProgram.PMC_SS_SalesAgreement__c);
            for(String salesAgreementProduct : mapTempSalesProductSchedule.keyset()){
                for(SalesAgreementProductSchedule objSalesAgreementProductSchedule : mapTempSalesProductSchedule.get(salesAgreementProduct)){
                    if(!mapRebateProgramIdAndProductQuantityMap.containsKey(objRebateProgram.id) && (objSalesAgreementProductSchedule.StartDate >= objRebateProgram.StartDate && objSalesAgreementProductSchedule.EndDate <= objRebateProgram.EndDate))
                    {
                        mapRebateProgramIdAndProductQuantityMap.put(objRebateProgram.id,new Map<String,Integer>{salesAgreementProduct => objSalesAgreementProductSchedule.ForecastedQuantity});
                    }
                    else{
                        SalesAgreeementAndRebateWrapper salesAgreeementAndRebate  = new SalesAgreeementAndRebateWrapper();
                        salesAgreeementAndRebate.mapRebateProgramIdAndProductQuantityMap= mapRebateProgramIdAndProductQuantityMap;
                        salesAgreeementAndRebate.objRebateProgram=objRebateProgram;
                        salesAgreeementAndRebate.objSalesAgreementProductSchedule= objSalesAgreementProductSchedule;
                        salesAgreeementAndRebate.salesAgreementProduct = salesAgreementProduct;
                        mapRebateProgramIdAndProductQuantityMap = createRebateProgramIdAndProductQuantityMap(salesAgreeementAndRebate);
                    } 
                   
                }
            }
            setRebateProgramIds.add(objRebateProgram.id);
        } 
        List<ProgramRebateType> lstRebateType = [Select id,name,PMC_SS_Type__c,PMC_SS_Projected_Incentive__c,PMC_SS_Forecasted_Quantity__c,RebateProgramId From ProgramRebateType where Status = 'Active' And RebateProgramId =:setRebateProgramIds WITH USER_MODE ];
        PMC_SS_SalesAgreementHelper.callIncentiveCalculation(mapRebateProgramIdAndProductQuantityMap,lstRebateType,lstRebatePrograms);
        
    }
    
        /**
* @description - Wrapper class to create Sales Agreement and Rebate Details
*  */
    
    public class SalesAgreeementAndRebateWrapper{
          Map<Id,Map<String,Integer>> mapRebateProgramIdAndProductQuantityMap;
          RebateProgram objRebateProgram;
          SalesAgreementProductSchedule objSalesAgreementProductSchedule;
          String salesAgreementProduct;
    }
   
}