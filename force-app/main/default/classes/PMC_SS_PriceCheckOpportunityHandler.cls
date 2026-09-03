/**
 * @description This class is used to create an opportunity when customer makes a price check request in digital hub
 * @author Megha Sunhare
 * @storynumber GDASF-7257
 * @TestClass PMC_SS_PriceCheckOpportunityHandlerTest
 */
public without sharing class PMC_SS_PriceCheckOpportunityHandler {

    //Private variables to store the common values used in the class
    @TestVisible
    private static Account objAccount;
    @TestVisible
    private static String strOpportunityName;

    /**
     * @description This method is called from getPrice button on digital hub, it creates an opportunity with user's selected product families
     * @author Megha Sunhare
     * @param strAccountId String to store the recordId of account
     * @param lstProductFamilies List for selected product families
     * @param strCurrency currency selected by user
     * @return String recordId of newly created opportunity
     */
    public static String createOpportunityForGetPriceCall(String strAccountId, List<String> lstProductFamilies, String strCurrency){
        //Variable that stores the Id for new opportunity or the updated opportunity
        String strOppurtunityId='';

        if(String.isBlank(strAccountId) || lstProductFamilies.isEmpty() || String.isBlank(strCurrency)){
            return strOppurtunityId;
        }

        try{
            //initialise the values of class variables
            objAccount = [SELECT Id, Name, OwnerId FROM Account WHERE Id = :strAccountId WITH SECURITY_ENFORCED];

            strOpportunityName = PMC_SS_ConstantClass.PRICE_CHECK_OPPORTUNITY_NAME_SUBSTRING + objAccount.Name;
            //Sorting the list in ascending order
            lstProductFamilies.sort();

            //Query the list of opportunities created on account with getPrice call
            List<Opportunity> lstRelatedOpportunities =  [SELECT Id, PMC_SS_ProductFamilies__c, CloseDate FROM Opportunity WHERE AccountId = :strAccountId AND PMC_SS_OpportunitySource__c =:PMC_SS_ConstantClass.OPPORTUNITY_SOURCE_WEB AND 
                                                            StageName NOT IN (:PMC_SS_ConstantClass.OPPORTUNITY_CLOSED_WON_STAGE, :PMC_SS_ConstantClass.OPPORTUNITY_CLOSED_LOST_STAGE) 
                                                            AND PMC_SS_ProductFamilies__c = :String.join(lstProductFamilies, ';') AND CloseDate >= THIS_MONTH AND CurrencyIsoCode = :strCurrency WITH SECURITY_ENFORCED ORDER BY CloseDate];
            //If there is no existing opportunity creates a new opportunity and returns the Id
            if(lstRelatedOpportunities.isEmpty()){
                strOppurtunityId = createNewOpportunity(lstProductFamilies, strCurrency);
                return strOppurtunityId;
            }else{
                strOppurtunityId = updateExistingOpportunity(lstRelatedOpportunities.get(0));
            }

        }catch(Exception objException){
            PMC_ErrorLogClass.processException(objException);
        }

        return strOppurtunityId;
    }

    /**
     * @description This method is used to create opportunity record
     * @author Megha Sunhare
     * @param lstProductFamilies List of selected product families
     * @param strCurrency currency selected by user
     * @return String Opportunity record Id
     */
    private static String createNewOpportunity(List<String> lstProductFamilies, String strCurrency){

        Opportunity objOpportunity = new Opportunity();
        
        objOpportunity.AccountId = objAccount.Id;
        objOpportunity.CloseDate = System.today() + 30;
        objOpportunity.PMC_SS_ProductFamilies__c = String.join(lstProductFamilies, ';');
        objOpportunity.StageName = PMC_SS_ConstantClass.OPPORTUNITY_PROPOSAL_STAGE;
        objOpportunity.PMC_SS_OpportunitySource__c = PMC_SS_ConstantClass.OPPORTUNITY_SOURCE_WEB;
        objOpportunity.Name = strOpportunityName;
        objOpportunity.OwnerId = objAccount.OwnerId;
        objOpportunity.CurrencyIsoCode = strCurrency;

        if( Schema.sObjectType.Opportunity.isCreateable()){
            Database.insert(objOpportunity, true);
            //return objOpportunity.Id;
        }
        
        if(objOpportunity.Id != NULL){            
            shareRecordWithPortalUser(objOpportunity.Id);            
            return objOpportunity.Id;
        }
        return '';
    }

    /**
     * @description This method is used to update existing opportunity with matching product families
     * @author Megha Sunhare
     * @param objOpportunity opportunity record with same product interests
     * @return String Opportunity record Id
    */
    private static String updateExistingOpportunity(Opportunity objOpportunity){

        Date datThirtyDaysFromToday = System.today() + 30;
        if( Schema.sObjectType.Opportunity.isUpdateable() && ( objOpportunity.CloseDate == NULL || datThirtyDaysFromToday > objOpportunity.CloseDate)){
            objOpportunity.CloseDate = datThirtyDaysFromToday;
            Database.update(objOpportunity, true);            
        }
        
        shareRecordWithPortalUser(objOpportunity.Id);
        
        return objOpportunity.Id;
    }

    /**
     * @description This method is used to share the opportunity record with portal user for quote creation
     * @author Megha Sunhare
     * @param objOppotunityId Id of opportunity we want to insert
    */
    private static void shareRecordWithPortalUser(String objOppotunityId){
        
        OpportunityShare objOppShare = new OpportunityShare();
        objOppShare.OpportunityId = objOppotunityId;
        objOppShare.UserOrGroupId = UserInfo.getUserId();
        objOppShare.OpportunityAccessLevel = 'Edit';
        objOppShare.RowCause = Schema.OpportunityShare.RowCause.Manual;
        
        if(Schema.sObjectType.OpportunityShare.isCreateable() && !Test.isRunningTest()){
            insert objOppShare;
        }        
        
    }
}