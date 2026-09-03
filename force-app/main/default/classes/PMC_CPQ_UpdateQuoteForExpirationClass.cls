/**
* @description This class will be used to update Expiration Date for Quotes.
* @author Ridhu Varshini M
* @storynumber GDASF-3200
*/
public with sharing class PMC_CPQ_UpdateQuoteForExpirationClass {
    
    public static final Time TIME5 = Time.newInstance(17, 0, 0, 0);
    public static final Time TIME6 = Time.newInstance(18, 0, 0, 0);
    public static final Time TIME6AM = Time.newInstance(6, 0, 0, 0);
    public static final Time TIME10 = Time.newInstance(22, 0, 0, 0);
    
    /**
* @description This method is invoked from the flow - PMC CPQ After Create/Update Quote where on quote creation and update the flow runs
* and calls this Apex Action.
* @param lstQuote - list of quote records sent from the flow.		 
*/
    @InvocableMethod(label='Update Expiration for Quotes Optimized')
    public static void updateExpirationDateForQuotes(List<Id> lstQuote){
        List<SBQQ__Quote__c> lstQuotes = [SELECT Id, SBQQ__Status__c,PMC_CPQ_RequestedExpirationDateTime__c,SubmittedUser__c,CreatedById,PMC_CPQ_CustomCreatedDate__c,PMC_CPQ_QuoteClassification__c,ApprovalStatus__c,PMC_CPQ_ExpirationDate__c,PMC_CPQ_ExpirationTime__c, PMC_CPQ_ExpiresOn__c, PMC_CPQ_QuoteRecordSubType__c,PMC_CPQ_Region__c from SBQQ__Quote__c where Id IN: lstQuote WITH SECURITY_ENFORCED LIMIT 1];
        String strRegion = [select PMC_CPQ_SalesRegion__c from User where Id =: lstQuotes.get(0).SubmittedUser__c][0].PMC_CPQ_SalesRegion__c;//Get the Region of the AM user created the quote
        if(!lstQuotes.isEmpty()){
            if(lstQuotes.get(0).PMC_CPQ_RequestedExpirationDateTime__c != NULL && lstQuotes.get(0).SBQQ__Status__c == Label.PMC_CPQ_QuoteStatusApproved){
                PMC_CPQ_UpdateQuoteForExpirationHelper.updateExpirationDateAndTimeOnRequestedExpiration(lstQuotes);
            }
            else{
                callExpMethods(lstQuotes,strRegion);
            }
        }
    }
    /**
* @description This method is to call the respective method based on region.
* @param lstQuotes - list of quotes.
* @param strRegion - region of user.
*/   
    public static void callExpMethods(List<SBQQ__Quote__c> lstQuotes, string strRegion){
        SBQQ__Quote__c quo = lstQuotes.get(0);
        if((strRegion == Label.PMC_CPQ_NorthAmerica || strRegion == Label.PMC_CPQ_Global) && quo.SBQQ__Status__c == Label.PMC_CPQ_QuoteStatusApproved && quo.PMC_CPQ_RequestedExpirationDateTime__c == NULL){ // checking if user's sales region is NA
            updateExpirationForNA( lstQuotes );
        }
        if(strRegion == Label.PMC_CPQ_Brazil && quo.SBQQ__Status__c == Label.PMC_CPQ_QuoteStatusApproved && quo.PMC_CPQ_RequestedExpirationDateTime__c == NULL ){ // checking if user's sales region is BR
            updateExpirationForBR(lstQuotes);
        }
    }
   
    /**
* @description This method is to calculate Expiration date for NA quotes and update it.
* @param lstQuotes - list of quotes.
*/    
    public static void updateExpirationForNA(List<SBQQ__Quote__c> lstQuotes){
        DateTime datTCreatedDate;
        if(test.isRunningTest()){
            datTCreatedDate = lstQuotes.get(0).PMC_CPQ_CustomCreatedDate__c;
        }
        else{
            datTCreatedDate = System.now();
        }
        String userTZ = [select TimeZoneSidKey from User where Id =: lstQuotes.get(0).SubmittedUser__c ][0].TimeZoneSidKey;//Convert the current time to AM's timezone
        Timezone tz = Timezone.getTimeZone(userTZ);//Convert the current time to AM's timezone
        Integer offset = tz.getOffset(datTCreatedDate);//Convert the current time to AM's timezone
        DateTime amLocal =  datTCreatedDate.addSeconds(offset/1000);//Convert the current time to AM's timezone
        String strWeekday = amLocal.formatGmt('EEEE'); // function to find the weekday
        Time timeCreatedTime = amLocal.timeGmt(); // The local time of the quote CreatedTime
        
        if(strWeekday == 'Saturday'){
            PMC_CPQ_UpdateQuoteForExpirationHelper.calculateDateTime(lstQuotes,2,TIME10);// GCPM-298 checks if created date/time is on saturday and should be the next monday 10pm.
        }
        if(strWeekday == 'Sunday'){
            PMC_CPQ_UpdateQuoteForExpirationHelper.calculateDateTime(lstQuotes,1,TIME10);// GCPM-298 checks if created date/time is on sunday and should be the next monday 10pm.
        }
        if(timeCreatedTime >= TIME5) // checks if created time is after 5pm
        {
            if(strWeekday == 'Friday') // checks if created date/time is on Friday
            {
                PMC_CPQ_UpdateQuoteForExpirationHelper.calculateDateTime(lstQuotes,3,TIME10);// GCPM-298 Should be the next monday 10pm.
            }
            else{
                PMC_CPQ_UpdateQuoteForExpirationHelper.calculateDateTime(lstQuotes,1,TIME10); // GCPM-298 should be the next day 10pm
            }
        }
        else
        {
            if(timeCreatedTime.hour() >= 15 && timeCreatedTime.hour() < 17){ // checking if quote creation is between 3pm and 5pm
              PMC_CPQ_UpdateQuoteForExpirationHelper.calculateDateTime(lstQuotes,0,TIME10); // GCPM-298 should be the same day 10pm 
            }
            else{
                PMC_CPQ_UpdateQuoteForExpirationHelper.calculateDateTime(lstQuotes,0,TIME10); // GCPM-298 should be the same day 5pm
            }
        } 
    }    
    /**
* @description This method is to calculate Expiration date for BR quotes and update it.
* @param lstQuotes - list of quotes.
*/    
    public static void updateExpirationForBR(List<SBQQ__Quote__c> lstQuotes){
        DateTime datTSubmittedDateTime;
        if(test.isRunningTest()){
            datTSubmittedDateTime = lstQuotes.get(0).PMC_CPQ_CustomCreatedDate__c;
        }
        else{
            datTSubmittedDateTime = System.now();
        }
        String userTZ = [select TimeZoneSidKey from User where Id =: lstQuotes.get(0).SubmittedUser__c ][0].TimeZoneSidKey;//Convert the current time to AM's timezone
        Timezone tz = Timezone.getTimeZone(userTZ);//Convert the current time to AM's timezone
        Integer offset = tz.getOffset(datTSubmittedDateTime);//Convert the current time to AM's timezone
        DateTime amLocal =  datTSubmittedDateTime.addSeconds(offset/1000);//Convert the current time to AM's timezone
        Time timeSubmittedTime = amLocal.timeGmt();//Convert the current time to AM's timezone
        
        SBQQ__Quote__c objQuote = lstQuotes.get(0);
        List<PMC_CPQ_BRExpirationValidityTable__mdt> lstBrMdt = [select PMC_CPQ_Classification__c, PMC_CPQ_NumberOfDays__c, PMC_CPQ_BusinessType__c from PMC_CPQ_BRExpirationValidityTable__mdt where PMC_CPQ_Classification__c =: objQuote.PMC_CPQ_QuoteClassification__c AND PMC_CPQ_BusinessType__c =: objQuote.PMC_CPQ_QuoteRecordSubType__c  WITH SECURITY_ENFORCED LIMIT 1];
        if(!lstBrMdt.isEmpty()){
            if(lstBrMdt.get(0).PMC_CPQ_NumberOfDays__c == 0 && (timeSubmittedTime.hour() >= 15 && timeSubmittedTime.hour() < 17)){ // when no.of days to be added = 0 and approved between 3 and 5pm
                PMC_CPQ_UpdateQuoteForExpirationHelper.calculateDateTime(lstQuotes,Integer.valueOf(lstBrMdt.get(0).PMC_CPQ_NumberOfDays__c),TIME10); //GCPM-298 should be same day 10pm
            }
            else if(lstBrMdt.get(0).PMC_CPQ_NumberOfDays__c == 0 && (timeSubmittedTime.hour() >= 17 && timeSubmittedTime.hour() <= 23)){// when no.of days to be added = 0 and approved between 5 and 11.59pm
                PMC_CPQ_UpdateQuoteForExpirationHelper.calculateDateTime(lstQuotes,Integer.valueOf(lstBrMdt.get(0).PMC_CPQ_NumberOfDays__c)+1,TIME10); //GCPM-298 should be next day 10pm
            }
            else{
                PMC_CPQ_UpdateQuoteForExpirationHelper.calculateDateTime(lstQuotes,Integer.valueOf(lstBrMdt.get(0).PMC_CPQ_NumberOfDays__c),TIME10); //GCPM-298 should be no.of days added 10pm
            }
        }
    }
}