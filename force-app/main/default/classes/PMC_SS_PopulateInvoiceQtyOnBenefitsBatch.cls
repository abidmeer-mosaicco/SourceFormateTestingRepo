/**
* @description       : Batch Class to populate Invoice Quantity and Actual Incentives of Rebate Type Benefits
* @author            : Aravind Chaganti
* @last modified on  : 03-11-2024
* @last modified by  : Aravind Chaganti
**/
public with sharing class PMC_SS_PopulateInvoiceQtyOnBenefitsBatch implements Database.Batchable<sObject>,Database.stateful {
    private static final String GROWTH_TYPE = 'ZRS3'; //'Growth';
    private Integer intFailureRecordCount = 0 ;
    private final String strErrorMessage = 'Actual Quantity on Sales Agreement Product Schedules were not updated';
    /**
	* @description Start method of batchable
    * @param objBC
    * @return  Database.QueryLocator
  */
    public Database.QueryLocator start(Database.BatchableContext objBC){
        /*String query;
        if(!Test.isRunningTest()){
            query = 'Select AccountId,Id FROM SalesAgreement WHERE Status = \'Activated\'';
          }else{
            query = 'Select AccountId,Id FROM SalesAgreement Status = \'Activated\' LIMIT 1'; 
        }*/
        return Database.getQueryLocator([SELECT Id, AccountId,Name FROM SalesAgreement WHERE Status = 'Activated' WITH SECURITY_ENFORCED]);
    }
    
    /**
    * @description execute method of batchable
    * @param objBC
    * @param lstSalesAgreement
    */    
    public void execute(Database.BatchableContext objBC, List<SalesAgreement> lstSalesAgreement)
    {
        Database.SaveResult[] lstUpdationResult;
        List<RebateProgram>lstRebatePrograms=new List<RebateProgram>();
        List<ProgramRebateTypeBenefit> lstProgramRebateTypeBenefits=new List<ProgramRebateTypeBenefit>();
        List<ProgramRebateTypeBenefit> lstProgramRebateTypeBenefitsUpdate=new List<ProgramRebateTypeBenefit>();
        lstRebatePrograms=[SELECT ID,StartDate,EndDate,Status,PMC_SS_SalesAgreement__c FROM RebateProgram WHERE Status='Active' AND PMC_SS_SalesAgreement__c!=null AND PMC_SS_SalesAgreement__c IN:lstSalesAgreement ORDER BY PMC_SS_SalesAgreement__c];
        lstProgramRebateTypeBenefits=[SELECT Id,BenefitValue,MaximumQualifyingValue,MinimumQualifyingValue,PMC_SS_ProductFamily__c,ProgramRebateType.PMC_SS_Type__c,ProgramRebateType.RebateProgram.PMC_SS_SalesAgreement__c,ProgramRebateType.RebateProgram.StartDate,ProgramRebateType.RebateProgram.EndDate FROM ProgramRebateTypeBenefit WHERE PMC_SS_ProductFamily__c!=null AND ProgramRebateType.RebateProgramId=:lstRebatePrograms ORDER BY ProgramRebateType.RebateProgramId];
        if(!lstProgramRebateTypeBenefits.isEmpty()){
            for(ProgramRebateTypeBenefit prtypeBenefit:lstProgramRebateTypeBenefits){
                Map<String,Integer> mapProductFamilyInvoiceQty=getInvoiceQtyFromSchedules(prtypeBenefit.ProgramRebateType.RebateProgram.PMC_SS_SalesAgreement__c,prtypeBenefit.ProgramRebateType.RebateProgram.StartDate,prtypeBenefit.ProgramRebateType.RebateProgram.EndDate);
                Integer invoiceQtyValue=mapProductFamilyInvoiceQty!=null?mapProductFamilyInvoiceQty.get(prtypeBenefit.PMC_SS_ProductFamily__c):null;
                //prtypeBenefit.PMC_SS_InvoiceQuantity__c=(prtypeBenefit.MaximumQualifyingValue!=0 && invoiceQtyValue>=prtypeBenefit.MinimumQualifyingValue && invoiceQtyValue<=prtypeBenefit.MaximumQualifyingValue)||(prtypeBenefit.MaximumQualifyingValue==null && invoiceQtyValue>= prtypeBenefit.MinimumQualifyingValue)?invoiceQtyValue:null;
                prtypeBenefit.PMC_SS_InvoiceQuantity__c=getInvoiceQuantity(prtypeBenefit,invoiceQtyValue);
                prtypeBenefit.PMC_SS_ActualIncentives__c=getIncentives(prtypeBenefit,invoiceQtyValue);
                lstProgramRebateTypeBenefitsUpdate.add(prtypeBenefit);
            }
            
            lstUpdationResult=Database.Update(lstProgramRebateTypeBenefitsUpdate,false); 
            for(Database.SaveResult updationResult: lstUpdationResult){
                if(!updationResult.isSuccess()){
                    intFailureRecordCount++;
                }
            }
        }
   	}
    
    /**
   * @description finish method of batchable
   * @param salesAgreementId
   * @param rebateProgramStartDate
   * @param rebateProgramEndDate
   * @return mapProductFamilyInvoiceQuantity
  */    
    public static Map<String,Integer> getInvoiceQtyFromSchedules(Id salesAgreementId,Date rebateProgramStartDate, Date rebateProgramEndDate){
        Map<String,Integer>mapProductFamilyInvoiceQuantity=new Map<String,Integer>();
        List<SalesAgreementProductSchedule>lstSalesAgreementProductSchedules = new List<SalesAgreementProductSchedule>();
        lstSalesAgreementProductSchedules =[SELECT SalesAgreementProductId,ActualQuantity,SalesAgreementProduct.Product.PMC_CPQ_ProductFamily__c 
                     FROM SalesAgreementProductSchedule
                     WHERE SalesAgreementProduct.SalesAgreementId=:salesAgreementId
                     AND SalesAgreementProduct.Product.PMC_CPQ_ProductFamily__c != NULL
                     AND ((StartDate >= :rebateProgramStartDate AND EndDate <= :rebateProgramEndDate)
                     OR (StartDate < :rebateProgramStartDate AND EndDate > :rebateProgramStartDate)
                     OR (StartDate < :rebateProgramEndDate AND EndDate > :rebateProgramEndDate))];
        for(SalesAgreementProductSchedule saps:lstSalesAgreementProductSchedules){
            String productFamily=saps.SalesAgreementProduct.Product.PMC_CPQ_ProductFamily__c;
            if(!mapProductFamilyInvoiceQuantity.containsKey(productFamily.toUpperCase())){
                mapProductFamilyInvoiceQuantity.put(productFamily.toUpperCase(),saps.ActualQuantity);
            }
            else{
                Integer totalPlannedQuantity=mapProductFamilyInvoiceQuantity.get(productFamily.toUpperCase())+saps.ActualQuantity;
                mapProductFamilyInvoiceQuantity.put(productFamily.toUpperCase(),totalPlannedQuantity);
            }     
        }
        return mapProductFamilyInvoiceQuantity;
    }
    
     /**
   * @description To calculate incentives depending on Program Rebate Type
   * @param prtb
   * @param invoiceQtyValue
   * @return incentive
  */    
    public static Decimal getIncentives(ProgramRebateTypeBenefit prtb,Integer invoiceQtyValue){
        Decimal incentive=0;
        if(prtb.ProgramRebateType.PMC_SS_Type__c!=GROWTH_TYPE){
            incentive=(prtb.MaximumQualifyingValue!=0 && invoiceQtyValue>=prtb.MinimumQualifyingValue && invoiceQtyValue<=prtb.MaximumQualifyingValue)||(prtb.MaximumQualifyingValue==null && invoiceQtyValue>= prtb.MinimumQualifyingValue)?invoiceQtyValue*prtb.BenefitValue:null;
        }
        else if (prtb.ProgramRebateType.PMC_SS_Type__c==GROWTH_TYPE){
            incentive=(invoiceQtyValue>= prtb.MinimumQualifyingValue)?(invoiceQtyValue-prtb.MinimumQualifyingValue)*prtb.BenefitValue:null;
        }
        return incentive;
    }
    
     /**
    * @description finish method of batchable
    * @param prtypeBenefit
    * @param invoiceQtyValue
    * @return Decimal - Return the Invoice Quantity
    */    
    public static Decimal getInvoiceQuantity(ProgramRebateTypeBenefit prtypeBenefit,Integer invoiceQtyValue){
        
        return (prtypeBenefit.MaximumQualifyingValue!=0 && invoiceQtyValue>=prtypeBenefit.MinimumQualifyingValue && invoiceQtyValue<=prtypeBenefit.MaximumQualifyingValue)||(prtypeBenefit.MaximumQualifyingValue==null && invoiceQtyValue>= prtypeBenefit.MinimumQualifyingValue)?invoiceQtyValue:null;
        
    }
    
    /**
    * @description finish method of batchable
    * @param objBC
    */    
   public void finish(Database.BatchableContext objBC){
     PMC_ErrorLog__c objErrorLog;
       if (Test.isRunningTest()){
             intFailureRecordCount = 1;
        }
        if(intFailureRecordCount != 0 ) {
            objErrorLog = new PMC_ErrorLog__c();
        	objErrorLog.PMC_Message__c = intFailureRecordCount + strErrorMessage;
            objErrorLog.PMC_Type__c = 'Apex';
        	objErrorLog.PMC_MethodName__c = 'finish';
        	objErrorLog.PMC_ClassName__c = PMC_SS_PopulateInvoiceQtyOnBenefitsBatch.class.getName();
        	Database.insert(objErrorLog, false);
   	}
   }
}