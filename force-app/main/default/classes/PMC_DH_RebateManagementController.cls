/**
* @description       : Controller for Rebate Management
* @author            : Rohan Undale
* @Created on        : 11-04-2023
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
* @last modified date: 11-11-2023
**/
public without sharing class PMC_DH_RebateManagementController {
    // added without sharing latest changes added
    private static final String GROWTH_TYPE = 'ZRS3'; //'Growth';
    private static final String PORTFOLIO_TYPE = 'ZRS2'; //'Portfolio';
    private static final String INDIVIDUAL_TYPE =  'ZRS1'; //'Individual';
     private static final String ACTIVE = 'Active'; 

    private static Map<String, Integer> mapProductFamilyPlannedQty = new Map<String, Integer>();
    private static Map<String, Decimal> mapProductFamilyAccumulatedPrice = new Map<String, Decimal>();
    private static Map<String, Decimal> mapProductFamilyNextTarget = new Map<String, Decimal>();
    private static Map<String, String> mapProductFamilyUnitOfMeasure = new Map<String, String>();
    
    /**
    * @description get List Of Rebate Program Options
    * @param strEffectiveAccId Effective Account Id
    * @return PMC_DH_RebateProgramWrapper
    * @author Rohan Undale
    * @date 11-04-2023
    */
    @AuraEnabled
    public static PMC_DH_RebateProgramWrapper getListOfRebateProgramOptions(String strEffectiveAccId){ //changes as part of GDASF-19642
        List<RebateProgram> lstRebateProgram = [SELECT Id, Name, PMC_SS_SalesAgreement__r.AccountId 
                                                FROM RebateProgram
                                                WHERE PMC_SS_SalesAgreement__r.AccountId =: strEffectiveAccId
                                                AND Status=:ACTIVE 
                                                WITH SYSTEM_MODE Order BY CreatedDate DESC];
        PMC_DH_RebateProgramWrapper wrpRebatePrograms = new PMC_DH_RebateProgramWrapper(); //changes as part of GDASF-19642
        List<PMC_DH_PicklistWrapper> lstRebateProgramOptions = new List<PMC_DH_PicklistWrapper>();
        for(RebateProgram objRebateProgram : lstRebateProgram){
            PMC_DH_PicklistWrapper objPicklistWrapper = new PMC_DH_PicklistWrapper();
            objPicklistWrapper.value = objRebateProgram.Id;
            objPicklistWrapper.label = objRebateProgram.Name;
            lstRebateProgramOptions.add(objPicklistWrapper);
        }
        wrpRebatePrograms.lstRebateProgramOptions = lstRebateProgramOptions; //changes as part of GDASF-19642
        wrpRebatePrograms.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'RebateDetails'); //changes as part of GDASF-19642
        //return lstRebateProgramOptions;
        return wrpRebatePrograms; //changes as part of GDASF-19642
    }

    /**
    * @description get Rebate Details
    * @param strRebateProgramId Rebate Program Id
    * @param strEffectiveAccId Account Id
    * @return PMC_DH_RebateManagementWrapper
    * @author Rohan Undale
    * @date 11-10-2023
    */
    @AuraEnabled
    public static PMC_DH_RebateManagementWrapper getRebateDetails(String strRebateProgramId, String strEffectiveAccId){
        PMC_DH_RebateManagementWrapper result = new PMC_DH_RebateManagementWrapper();        
        List<RebateProgram> lstRebateProgram = [SELECT Id FROM RebateProgram WHERE PMC_SS_SalesAgreement__r.AccountId =: strEffectiveAccId AND Status=:ACTIVE 
                                                WITH SYSTEM_MODE Order BY CreatedDate DESC LIMIT 1];
        Id rebateProgramId= strRebateProgramId == '' ?  lstRebateProgram.isEmpty() ? NULL : lstRebateProgram[0].Id : strRebateProgramId;
        try {
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            if(rebateProgramId != NULL){
            result.objSalesAgreementSummaryWrapper = getSalesAgreementSummary(rebateProgramId);
            Map<String, List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper>> mapProductFamilyListOfTiersDataIndividual = getMapProductFamilyListOfTiersDataWrapper(rebateProgramId, INDIVIDUAL_TYPE);
            getCaluculatedData(mapProductFamilyListOfTiersDataIndividual, rebateProgramId);
            result.lstIndividualData = getRebateDataList(mapProductFamilyListOfTiersDataIndividual);

            resetCaluculatedData(); //Reset mapProductFamilyPlannedQty, mapProductFamilyAccumulatedPrice, mapProductFamilyNextTarget

            Map<String, List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper>> mapProductFamilyListOfTiersDataPortfolio = getMapProductFamilyListOfTiersDataWrapper(rebateProgramId, PORTFOLIO_TYPE);
            getCaluculatedData(mapProductFamilyListOfTiersDataPortfolio, rebateProgramId);
            result.lstPortfolioData = getRebateDataList(mapProductFamilyListOfTiersDataPortfolio);

            resetCaluculatedData(); //Reset mapProductFamilyPlannedQty, mapProductFamilyAccumulatedPrice, mapProductFamilyNextTarget

            Map<String, List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper>> mapProductFamilyListOfTiersDataGrowth = getMapProductFamilyListOfTiersDataWrapper(rebateProgramId, GROWTH_TYPE);
            getCaluculatedData(mapProductFamilyListOfTiersDataGrowth, rebateProgramId);
            calculateProductFamilyAccumulatedPriceGrowthMap(mapProductFamilyListOfTiersDataGrowth);
            result.lstGrowthData = getRebateDataList(mapProductFamilyListOfTiersDataGrowth);
            result.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'RebateDetails');
            }
        } catch (Exception ex) {
            PMC_ErrorLogClass.processException(ex);
            result.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
            //throw new AuraHandledException(ex.getLineNumber()+ex.getMessage()+ex.getStackTraceString()+ex.getCause());
        }
        return result;
    }

    /**
    * @description get Sales Agreement Summary
    * @param strRebateProgramId Rebate Program Id
    * @return PMC_DH_RebateManagementWrapper.PMC_DH_SalesAgreementSummaryWrapper
    * @author Rohan Undale
    * @date 11-04-2023
    */
    public static PMC_DH_RebateManagementWrapper.PMC_DH_SalesAgreementSummaryWrapper getSalesAgreementSummary(String strRebateProgramId){
        PMC_DH_RebateManagementWrapper.PMC_DH_SalesAgreementSummaryWrapper objSalesAgreementSummaryWrapper = new PMC_DH_RebateManagementWrapper.PMC_DH_SalesAgreementSummaryWrapper();
        RebateProgram objRebateProgram = [SELECT Id, Name, StartDate, EndDate, PMC_SS_SalesAgreement__r.Name 
                                          FROM RebateProgram
                                          WHERE Id =: strRebateProgramId
                                          WITH SYSTEM_MODE LIMIT 1];
        objSalesAgreementSummaryWrapper.strRebateProgramName = objRebateProgram.Name;
        objSalesAgreementSummaryWrapper.datStartDate = objRebateProgram.StartDate;
        objSalesAgreementSummaryWrapper.datEndDate = objRebateProgram.EndDate;
        objSalesAgreementSummaryWrapper.strSalesAgreementName = objRebateProgram.PMC_SS_SalesAgreement__r.Name;

        return objSalesAgreementSummaryWrapper;
    }

    /**
    * @description get Map of Product Family to List of Tiers data wrapper wrt type (Individual\Portfolio\Growth)
    * @param strRebateProgramId Rebate Program Id
    * @param strType : Individual\Portfolio\Growth
    * @return Map<String, List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper>>
    * @author Rohan Undale
    * @date 11-04-2023
    */
    public static Map<String, List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper>> getMapProductFamilyListOfTiersDataWrapper(String strRebateProgramId, String strType){
        Map<String, List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper>> mapProductFamilyListOfTiersDataWrapper = new Map<String, List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper>>();
        List<ProgramRebateTypeBenefit> lstProgramRebateTypeBenefit = [SELECT Id, PMC_SS_ProductFamily__c, MinimumQualifyingValue, BenefitValue, PMC_SS_Projected_Incentive__c, ProgramRebateType.PMC_SS_Type__c, ProgramRebateType.RebateProgram.Id 
                                                                      FROM ProgramRebateTypeBenefit
                                                                      WHERE ProgramRebateType.PMC_SS_Type__c =: strType AND ProgramRebateType.RebateProgram.Id =: strRebateProgramId 
                                                                      WITH SYSTEM_MODE Order By PMC_SS_ProductFamily__c ASC, MinimumQualifyingValue DESC];

        for(ProgramRebateTypeBenefit objProgramRebateTypeBenefit : lstProgramRebateTypeBenefit){
            PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper objTiersDataWrap = new PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper();
            objTiersDataWrap.decTierStartLimit = objProgramRebateTypeBenefit.MinimumQualifyingValue;
            objTiersDataWrap.decIndividualIncentive = objProgramRebateTypeBenefit.BenefitValue;
            objTiersDataWrap.decProjectedIncentive = objProgramRebateTypeBenefit.PMC_SS_Projected_Incentive__c;
            String productFamily = objProgramRebateTypeBenefit.PMC_SS_ProductFamily__c;
            if(!mapProductFamilyListOfTiersDataWrapper.containsKey(productFamily.toUpperCase()))
            {
                mapProductFamilyListOfTiersDataWrapper.put(productFamily.toUpperCase(), new List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper>());
            }
            mapProductFamilyListOfTiersDataWrapper.get(productFamily.toUpperCase()).add(objTiersDataWrap);
        }

        return mapProductFamilyListOfTiersDataWrapper;
    }
    
    /**
    * @description get Caluculated Data for mapProductFamilyPlannedQty, mapProductFamilyAccumulatedPrice, mapProductFamilyNextTarget
    * @param mapTierData map Tier Data
    * @param strRebateProgramId : Rebate Program Id
    * @author Sugunakar Routhu
    * @date 11-09-2023
    * @last modified by : Hemant Giri Goswami | hegoswami@deloitte.com
    * @last modified date : 11-10-2023
    */
    public static void getCaluculatedData(Map<String, List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper>> mapTierData , String strRebateProgramId){
        RebateProgram objRebateProgram = [SELECT Id, StartDate, EndDate, PMC_SS_SalesAgreement__c FROM RebateProgram WHERE Id =: strRebateProgramId WITH SYSTEM_MODE LIMIT 1];
        
        for(SalesAgreementProduct  objSalAgreePro:  [SELECT Id, SalesAgreement.PMC_SS_UnitofMeasure__c, Product.PMC_CPQ_ProductFamily__c, 
                                                     Product.PMC_CPQ_QuantityUnitOfMeasure__c, SalesAgreement.Name, 
                                                     (SELECT Id,Name,StartDate,EndDate, ActualQuantity from SalesAgreementProductSchedules 
                                                      Where (StartDate >=:objRebateProgram.StartDate AND EndDate <=:objRebateProgram.EndDate) 
                                                      OR (StartDate <:objRebateProgram.StartDate AND EndDate >:objRebateProgram.StartDate  ) 
                                                      OR  (StartDate <:objRebateProgram.EndDate AND EndDate >:objRebateProgram.EndDate))
                                                     FROM SalesAgreementProduct Where Product.PMC_CPQ_ProductFamily__c!=NULL 
                                                     AND SalesAgreementId=:objRebateProgram.PMC_SS_SalesAgreement__c
                                                     WITH SYSTEM_MODE])
        {
            Integer totalPlannedQty = 0;
            String productFamily = objSalAgreePro.Product.PMC_CPQ_ProductFamily__c;

            for(SalesAgreementProductSchedule scheRec: objSalAgreePro.SalesAgreementProductSchedules){
                  totalPlannedQty += scheRec.ActualQuantity;
            }
           
            if(mapProductFamilyPlannedQty.containsKey(productFamily.toUpperCase())){
                mapProductFamilyPlannedQty.put(productFamily.toUpperCase(),  mapProductFamilyPlannedQty.get(productFamily.toUpperCase()) + totalPlannedQty);
            }else{
                mapProductFamilyPlannedQty.put(productFamily.toUpperCase(), totalPlannedQty);
            }
          
            if((objSalAgreePro.SalesAgreement.PMC_SS_UnitofMeasure__c != null) && !mapProductFamilyUnitOfMeasure.containsKey(productFamily.toUpperCase())){
                mapProductFamilyUnitOfMeasure.put(productFamily.toUpperCase(), objSalAgreePro.SalesAgreement.PMC_SS_UnitofMeasure__c);
            }
        }
       
        for(String tierData : mapTierData.KeySet()){
            setAccumulatedPriceNextTargetMaps(mapTierData, tierData);
        }
    }

    private static void setAccumulatedPriceNextTargetMaps(Map<String, List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper>> mapTierData, String tierData){
        List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper> mapTierDataList = mapTierData.get(tierData);
        if(mapProductFamilyPlannedQty.containsKey(tierData)){
            Integer totalInvoicedQty = mapProductFamilyPlannedQty.get(tierData);
            //Decimal tierQuantityEligible = 0;
            Decimal incentiveAmount = 0;
            Integer nextTargetIndex =  0 ;
            for( Integer i=0; i<mapTierDataList.size(); i++){
                if( mapTierDataList[i].decTierStartLimit <= totalInvoicedQty){ // mapTierDataList[i].decTierStartLimit > tierQuantityEligible &&
                        //tierQuantityEligible = mapTierDataList[i].decTierStartLimit;
                        incentiveAmount = mapTierDataList[i].decIndividualIncentive;
                        nextTargetIndex = i;
                        break;
                    }
            }
            nextTargetIndex =  nextTargetIndex > 0 ? nextTargetIndex - 1  :  mapTierDataList.size() - 1;
            mapProductFamilyAccumulatedPrice.put(tierData, totalInvoicedQty * incentiveAmount);
            Decimal nextTargetQty = (mapTierDataList[nextTargetIndex].decTierStartLimit - totalInvoicedQty) > 0 ?  mapTierDataList[nextTargetIndex].decTierStartLimit - totalInvoicedQty : 0;
            mapProductFamilyNextTarget.put(tierData, nextTargetQty );
        }else{
            mapProductFamilyAccumulatedPrice.put(tierData, 0);
            mapProductFamilyNextTarget.put(tierData, mapTierDataList[ mapTierDataList.size() - 1].decTierStartLimit);
        }
    }

    private static List<PMC_DH_RebateManagementWrapper.RebateData> getRebateDataList(Map<String, List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper>> mapProductFamilyListOfTiersData){
        List<PMC_DH_RebateManagementWrapper.RebateData> lstRebateData = new List<PMC_DH_RebateManagementWrapper.RebateData>();
        Set<String> setKeySet = mapProductFamilyListOfTiersData.keySet();
        for(String productFamily : setKeySet){
            PMC_DH_RebateManagementWrapper.RebateData objRebateData = new PMC_DH_RebateManagementWrapper.RebateData();
            objRebateData.strProductName = productFamily;
            objRebateData.intInvoicedQty = 0;
            if(mapProductFamilyPlannedQty.containsKey(productFamily)){
                objRebateData.intInvoicedQty = mapProductFamilyPlannedQty.get(productFamily);
            }
            objRebateData.decTonsRemForNextTarget = 0;
            if(mapProductFamilyNextTarget.containsKey(productFamily)){
                objRebateData.decTonsRemForNextTarget = mapProductFamilyNextTarget.get(productFamily);
            }
            objRebateData.decAccumulatedRebatesToDate = 0;
            if(mapProductFamilyAccumulatedPrice.containsKey(productFamily)){
                objRebateData.decAccumulatedRebatesToDate = mapProductFamilyAccumulatedPrice.get(productFamily);
            }
            if(mapProductFamilyUnitOfMeasure.containsKey(productFamily)){
                objRebateData.strUOM = mapProductFamilyUnitOfMeasure.get(productFamily);
            }
            if(mapProductFamilyListOfTiersData.containsKey(productFamily)){
                objRebateData.lstTiers = mapProductFamilyListOfTiersData.get(productFamily);
            }
            lstRebateData.add(objRebateData);
        }
        return lstRebateData;
    }

    private static void resetCaluculatedData(){
        mapProductFamilyPlannedQty = new Map<String, Integer>();
        mapProductFamilyAccumulatedPrice = new Map<String, Decimal>();
        mapProductFamilyNextTarget = new Map<String, Decimal>();
    }

    private static void calculateProductFamilyAccumulatedPriceGrowthMap(Map<String, List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper>> mapTierData){
        mapProductFamilyAccumulatedPrice = new Map<String, Decimal>();
        
        for(String tierData : mapTierData.KeySet()){
            if(mapProductFamilyPlannedQty.containsKey(tierData)){
                Decimal decAccumulatedPrice = 0;
                Integer totalInvoicedQty = mapProductFamilyPlannedQty.get(tierData);
                List<PMC_DH_RebateManagementWrapper.PMC_DH_TiersDataWrapper> lstTierData = mapTierData.get(tierData);
                if(lstTierData[0].decTierStartLimit < Decimal.valueOf(totalInvoicedQty)){
                    decAccumulatedPrice = (Decimal.valueOf(totalInvoicedQty) - lstTierData[0].decTierStartLimit) * lstTierData[0].decIndividualIncentive;
                }
                mapProductFamilyAccumulatedPrice.put(tierData, decAccumulatedPrice);
            }
        }
    }

    // added as part of GDASF-19642
    /**
* @description : Wrapper for Rebate Program Optios
* @author      : Nikhilesh Mohanty
* @last modified on 2024-01-10
**/ 
    public with sharing class PMC_DH_RebateProgramWrapper
    {
        /**
        * @description List<PMC_DH_PicklistWrapper> of rebate program options
        * @author Nikhilesh
        * @return List<PMC_DH_PicklistWrapper>
        **/ 
        @AuraEnabled
        public List<PMC_DH_PicklistWrapper> lstRebateProgramOptions{get;set;}

        /**
        * @description Status Code and message
        * @author Nikhilesh
        * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }
}