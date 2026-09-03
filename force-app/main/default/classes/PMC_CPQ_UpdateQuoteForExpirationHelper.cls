/**
* @description This class is the helper class of PMC_CPQ_UpdateQuoteForExpirationClass
* @author Ridhu Varshini M
* @storynumber GPT-42302
*/
public with sharing class PMC_CPQ_UpdateQuoteForExpirationHelper {
    /**
* @description This method is to assign Expiration date and expiration time when requested expiration is populated.
* @param lstQuotes - list of quotes.
*/    
    @TestVisible private static Boolean testExceptionRequestedExpiration = false;
    @TestVisible private static Boolean testExceptionCalculateDateTime= false;
    public static void updateExpirationDateAndTimeOnRequestedExpiration(List<SBQQ__Quote__c> lstQuotes){
        
        DateTime reqExp = lstQuotes.get(0).PMC_CPQ_RequestedExpirationDateTime__c; 
        lstQuotes.get(0).PMC_CPQ_ExpirationDate__c = null;
        lstQuotes.get(0).PMC_CPQ_ExpirationTime__c = null;
        lstQuotes.get(0).PMC_CPQ_ExpiresOn__c = null;
        String userTZ = [select TimeZoneSidKey from User where Id =: lstQuotes.get(0).SubmittedUser__c ][0].TimeZoneSidKey;
        Timezone tz = Timezone.getTimeZone(userTZ);
        Integer offset = tz.getOffset(reqExp);
        DateTime amLocal =  reqExp.addSeconds(offset/1000);
        lstQuotes.get(0).PMC_CPQ_ExpirationDate__c = amLocal.dateGmt();
        lstQuotes.get(0).PMC_CPQ_ExpirationTime__c = amLocal.timeGmt();
        lstQuotes.get(0).PMC_CPQ_ExpiresOn__c = reqExp;
        try{
            exceptionCheckRequestedExpiration();
            if(Schema.sObjectType.SBQQ__Quote__c.isAccessible() 
               && Schema.sObjectType.SBQQ__Quote__c.isUpdateable()
               && Schema.SObjectType.SBQQ__Quote__c.fields.PMC_CPQ_ExpiresOn__c.isUpdateable()
               && Schema.SObjectType.SBQQ__Quote__c.fields.PMC_CPQ_ExpirationDate__c.isUpdateable()
               && Schema.SObjectType.SBQQ__Quote__c.fields.PMC_CPQ_ExpirationTime__c.isUpdateable())
            {
                update lstQuotes;
            }
        }
        catch(DmlException objException){
            PMC_ErrorLogClass.processException(objException);
        }
    }
      /**
* @description This method is to check exception triggered from test class to cover DML Exception on updateExpirationDateAndTimeOnRequestedExpiration method
*/
    private static void exceptionCheckRequestedExpiration(){
        if(testExceptionRequestedExpiration){
            throw new DmlException();
        }
    }
    /**
* @description This method is to calculate date Time for BR quotes and update it
* @param lstQuotes - list of quotes.
* @param intDays - the days to add
* @param timeConsidered - the hour to set
*/
   
    public static void calculateDateTime(List<SBQQ__Quote__c> lstQuotes, Integer intDays, Time timeConsidered){
        try{
            exceptionCheckCalculateDateTime();
            DateTime datTCreatedDate;
            if(test.isRunningTest()){
                datTCreatedDate = lstQuotes.get(0).PMC_CPQ_CustomCreatedDate__c;
            }
            else{
                datTCreatedDate = system.now();
            }
            Date datTRequiredDate = datTCreatedDate.date() + intDays;
            lstQuotes.get(0).PMC_CPQ_ExpiresOn__c = null;
            lstQuotes.get(0).PMC_CPQ_ExpirationDate__c = null;
            lstQuotes.get(0).PMC_CPQ_ExpirationTime__c = null;
            lstQuotes.get(0).PMC_CPQ_ExpirationDate__c = datTRequiredDate;
            lstQuotes.get(0).PMC_CPQ_ExpirationTime__c = timeConsidered;
            DateTime datTConverted = Datetime.newInstanceGmt(lstQuotes.get(0).PMC_CPQ_ExpirationDate__c, lstQuotes.get(0).PMC_CPQ_ExpirationTime__c);
            String userTZ = [select TimeZoneSidKey from User where Id =: lstQuotes.get(0).SubmittedUser__c ][0].TimeZoneSidKey;
            Timezone tz = Timezone.getTimeZone(userTZ);
            Integer offset = tz.getOffset(datTConverted);
            Integer finalOffset = offset*(-1);
            DateTime amLocal =  datTConverted.addSeconds(finalOffset/1000);
            lstQuotes.get(0).PMC_CPQ_ExpiresOn__c = amLocal;
            
            if(Schema.sObjectType.SBQQ__Quote__c.isAccessible() 
               && Schema.sObjectType.SBQQ__Quote__c.isUpdateable()
               && Schema.SObjectType.SBQQ__Quote__c.fields.PMC_CPQ_ExpiresOn__c.isUpdateable()
               && Schema.SObjectType.SBQQ__Quote__c.fields.PMC_CPQ_ExpirationDate__c.isUpdateable()
               && Schema.SObjectType.SBQQ__Quote__c.fields.PMC_CPQ_ExpirationTime__c.isUpdateable())
            {
                update lstQuotes;
            }
        }
        catch(DmlException objException){
            PMC_ErrorLogClass.processException(objException);
        }
    }
     /**
* @description This method is to check exception triggered from testclass to cover DML exception on calculateDateTime method
*/
    private static void exceptionCheckCalculateDateTime(){
        if(testExceptionCalculateDateTime){
                throw new DmlException();
            }
    }
}