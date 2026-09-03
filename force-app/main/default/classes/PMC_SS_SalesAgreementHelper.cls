/**
* @description This class will be used to handle all triggers on Sales Agreement object.
* @author Isha Gupta
* @storynumber GDASF-15372 
*/

public without sharing class PMC_SS_SalesAgreementHelper {
    /**
* @description - Method to calculate Forecasted Quantity(NA) & Projected Incentives on a rebate related objects based on update in related sales agreement
* @param mapNewSalesAgreement - Map of new values of sales agreement records.
* @param mapOldSalesAgreement - Map of old values of sales agreement records.
*  */
    public static void updateForecastedQuantityAndProjectedIncentive(Map<id,SalesAgreement> mapNewSalesAgreement, Map<id,SalesAgreement> mapOldSalesAgreement) {
        Set<Id> setupdatedSAids = new Set<Id>();
        for(Id idSalesAgreement : mapNewSalesAgreement.keySet() ){
            if(mapNewSalesAgreement.get(idSalesAgreement).PMC_SS_ApprovalStatus__c != mapOldSalesAgreement.get(idSalesAgreement).PMC_SS_ApprovalStatus__c &&  mapNewSalesAgreement.get(idSalesAgreement).PMC_SS_ApprovalStatus__c == 'Under Revision') {
                setupdatedSAids.add(idSalesAgreement);
            }
        }
        if(setupdatedSAids.size() > 0){
            updateForecastedQuantityAndProjectedIncentive(setupdatedSAids);
        }
        
    }
 
    
    /**
* @description - Method to calculate Forecasted Quantity(NA) & Projected Incentives on a rebate benefit object based on update in related sales agreement for north America
* @param setupdatedSAids - set of updated north america sales agreement ids.
*  */
    public static  void updateForecastedQuantityAndProjectedIncentive(Set<id> setupdatedSAids ){
        Set<Id> setSalesAgreementProductIds = new Set<Id>();
        Map<Id,Id> mapSalesAgreementProductAndSalesAgreementIdMap = new Map<Id,Id>();
        Map<Id,Map<String,List<SalesAgreementProductSchedule>>> mapSalesAgreementIdAndMapOfProductAndProductSchedulesList = new Map<Id,Map<String,List<SalesAgreementProductSchedule>>>();
        try{
           for(SalesAgreementProduct objSalesAgreementProduct : [Select id,Product.PMC_CPQ_ProductFamily__c,TotalForecastedQuantity,SalesAgreementId FROM SalesAgreementProduct where SalesAgreementId =:setupdatedSAids WITH USER_MODE ]){
                setSalesAgreementProductIds.add(objSalesAgreementProduct.id);
                mapSalesAgreementProductAndSalesAgreementIdMap.put(objSalesAgreementProduct.id,objSalesAgreementProduct.SalesAgreementId);
            }
            for(SalesAgreementProductSchedule objsalesAgreementProductSchedule : [Select id, ForecastedQuantity, SalesAgreementProductId,SalesAgreementProduct.Product.PMC_CPQ_ProductFamily__c, EndDate, StartDate From SalesAgreementProductSchedule Where SalesAgreementProductId in :setSalesAgreementProductIds WITH USER_MODE]){
                 mapSalesAgreementIdAndMapOfProductAndProductSchedulesList = PMC_SS_SalesAgreementHelperExt.createMapSalesAgreementIdAndMapOfProductAndProductSchedulesList(objsalesAgreementProductSchedule,mapSalesAgreementIdAndMapOfProductAndProductSchedulesList,mapSalesAgreementProductAndSalesAgreementIdMap);
                    }
            
            PMC_SS_SalesAgreementHelperExt.fetchRebateObjectsValuesForCalculation(mapSalesAgreementIdAndMapOfProductAndProductSchedulesList,setupdatedSAids);
        }catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
        }
        
    }
    
    
    /**
* @description - Method to calculate Forecasted Quantity(NA) & Projected Incentives on a rebate object based on update in related sales agreement
* @param mapRebateProgramIdAndProductQuantityMap - Map of mapRebateProgramIdAndProductQuantityMap.
* @param lstRebateType - list of rebate type records.
@param lstRebatePrograms - list of rebate program records.
*  */
    public static  void callIncentiveCalculation(Map<Id,Map<String,Integer>> mapRebateProgramIdAndProductQuantityMap,List<ProgramRebateType> lstRebateType,List<RebateProgram> lstRebatePrograms){
        Set<Id> setProgramRebateTypeIds = new Set<Id>();
        Map<Id,Id> mapRebateProgramIdAndPrgRebateTypeIdMap = new Map<Id,Id>();
     Map<Id,List<ProgramRebateType>> mapRebateProgramAndRebateTypeMap = new Map<Id,List<ProgramRebateType>>();
     Map<Id,List<ProgramRebateTypeBenefit>> mapRebateTypeAndRebateTypeBenefitMap = new Map<Id,List<ProgramRebateTypeBenefit>>();  
            for(ProgramRebateType objProgramRebateType : lstRebateType) {
                setProgramRebateTypeIds.add(objProgramRebateType.id);
                mapRebateProgramIdAndPrgRebateTypeIdMap.put(objProgramRebateType.id,objProgramRebateType.RebateProgramId);
            } 
            mapRebateTypeAndRebateTypeBenefitMap = calculateIncentiveAtBenefit(mapRebateProgramIdAndProductQuantityMap,mapRebateProgramIdAndPrgRebateTypeIdMap,setProgramRebateTypeIds);
        
           	if(lstRebateType.size()>0) {
            mapRebateProgramAndRebateTypeMap = PMC_SS_SalesAgreementHelperExt.calculateIncentiveAtRebateType(mapRebateTypeAndRebateTypeBenefitMap,lstRebateType);
            }
            if(lstRebatePrograms.size()>0) { 
                calculateIncentiveAtRebateProgram(mapRebateProgramAndRebateTypeMap,lstRebatePrograms);
            }
    }
    
   
    
    /**
* @description - Method to calculate Forecasted Quantity(NA) & Projected Incentives on a rebate benefit object based on update in related sales agreement
* @param mapRebateProgramIdAndProductQuantityMap - Map of mapRebateProgramIdAndProductQuantityMap.
* @param mapRebateProgramIdAndPrgRebateTypeIdMap - Map of mapRebateProgramIdAndPrgRebateTypeIdMap.
@param setProgramRebateTypeIds - Set of setProgramRebateTypeIds
@return temp
*  */
    public static  Map<Id,List<ProgramRebateTypeBenefit>> calculateIncentiveAtBenefit(Map<Id,Map<String,Integer>> mapRebateProgramIdAndProductQuantityMap ,Map<Id,Id> mapRebateProgramIdAndPrgRebateTypeIdMap,Set<Id> setProgramRebateTypeIds){
        Map<Id,List<ProgramRebateTypeBenefit>>  mapRebateTypeAndBenefit = new Map<Id,List<ProgramRebateTypeBenefit>>();
        Map<String,Integer> mapProductAndQuantity = new Map<String,Integer>();
        List<ProgramRebateTypeBenefit> lstProgramRebateTypeBenefits = [Select id,name,PMC_SS_Projected_Incentive__c,PMC_SS_Forecasted_Quantity__c,BenefitValue,MinimumQualifyingValue,MaximumQualifyingValue,PMC_SS_ProductFamily__c,Product.Name,ProgramRebateTypeId,ProgramRebateType.Name,ProgramRebateType.PMC_SS_Type__c  From ProgramRebateTypeBenefit where Status = 'Active' And ProgramRebateTypeId =:setProgramRebateTypeIds WITH USER_MODE];
        for(ProgramRebateTypeBenefit objProgramRebateTypeBenefit : lstProgramRebateTypeBenefits) {
            mapProductAndQuantity = mapRebateProgramIdAndProductQuantityMap.get(mapRebateProgramIdAndPrgRebateTypeIdMap.get(objProgramRebateTypeBenefit.ProgramRebateTypeId));
            for (string strProd : mapProductAndQuantity.keyset()){
                if(objProgramRebateTypeBenefit.PMC_SS_ProductFamily__c == strProd || objProgramRebateTypeBenefit.Product.Name == strProd){
                    objProgramRebateTypeBenefit.PMC_SS_Forecasted_Quantity__c = mapProductAndQuantity.get(strProd);
                   
                    objProgramRebateTypeBenefit = PMC_SS_SalesAgreementHelperExt.calculateBenefitOnType(objProgramRebateTypeBenefit,mapProductAndQuantity,strProd);
                   
                    mapRebateTypeAndBenefit = PMC_SS_SalesAgreementHelperExt.updateRebateTypeAndBenefitMap(mapRebateTypeAndBenefit,objProgramRebateTypeBenefit);
                }
            }
                            
        }
        if(Schema.sObjectType.ProgramRebateTypeBenefit.isUpdateable()){
            update lstProgramRebateTypeBenefits;
        }
        return mapRebateTypeAndBenefit;
        
    }
    
     
    /**
* @description - Method to calculate Forecasted Quantity(NA) & Projected Incentives on a rebate type object based on update in related sales agreement
* @param mapProductAndQuantity - Map of product and quantity of the related sales agreement
*@param objProgramRebateTypeBenefit - record of ProgramRebateTypeBenefit
*@param strProd - Product name
*@return Decimal
*  */
      
    public static Decimal calculateProjectedIncentiveAtOtherBenefits(Map<String,Integer> mapProductAndQuantity,ProgramRebateTypeBenefit objProgramRebateTypeBenefit, String strProd){
      
                        
                    if(!objProgramRebateTypeBenefit.ProgramRebateType.Name.contains('Growth') &&
                      (
                          ((objProgramRebateTypeBenefit.MinimumQualifyingValue != null && objProgramRebateTypeBenefit.MaximumQualifyingValue != null) && mapProductAndQuantity.get(strProd) >= objProgramRebateTypeBenefit.MinimumQualifyingValue && mapProductAndQuantity.get(strProd) <= objProgramRebateTypeBenefit.MaximumQualifyingValue ) 
                       ||
                       		((objProgramRebateTypeBenefit.MinimumQualifyingValue != null && objProgramRebateTypeBenefit.MaximumQualifyingValue == null) && mapProductAndQuantity.get(strProd) >= objProgramRebateTypeBenefit.MinimumQualifyingValue)
                       )
                        )
                       
                    {
                        objProgramRebateTypeBenefit.PMC_SS_Projected_Incentive__c = mapProductAndQuantity.get(strProd)*objProgramRebateTypeBenefit.BenefitValue;
                    }
        return objProgramRebateTypeBenefit.PMC_SS_Projected_Incentive__c;
    }
     

            
    
    /**
* @description - Method to calculate Forecasted Quantity(NA) & Projected Incentives on a rebate program object based on update in related sales agreement
* @param mapRebateProgramAndRebateTypeMap - Map of mapRebateTypeAndRebateTypeBenefitMap.
*@param lstRebatePrograms - List of lstRebatePrograms
*  */
    public static void calculateIncentiveAtRebateProgram( Map<Id,List<ProgramRebateType>> mapRebateProgramAndRebateTypeMap , List<RebateProgram> lstRebatePrograms){
        Integer intTotalProjectedIncentive;
        for(RebateProgram objRebatePrg : lstRebatePrograms){
            intTotalProjectedIncentive = 0;
            for(ProgramRebateType objPrgRebateType:mapRebateProgramAndRebateTypeMap.get(objRebatePrg.id)){
                if(objPrgRebateType.PMC_SS_Projected_Incentive__c != null){
                    intTotalProjectedIncentive = Integer.valueOf(intTotalProjectedIncentive+objPrgRebateType.PMC_SS_Projected_Incentive__c);
                }
            }
            objRebatePrg.PMC_SS_Projected_Incentive__c = intTotalProjectedIncentive;
        }
        if(Schema.sObjectType.RebateProgram.isUpdateable()){
            update lstRebatePrograms;
        }
    }
    
}