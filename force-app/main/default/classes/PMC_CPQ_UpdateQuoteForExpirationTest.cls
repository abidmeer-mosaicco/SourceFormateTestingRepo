/*
* This class is the test class for PMC_CPQ_UpdateQuoteForExpirationClass.
* @author Ridhu Varshini M
* @storynumber GDASF-3200,GDASF-5383
*/
@isTest(seeAllData=false)
public with sharing class PMC_CPQ_UpdateQuoteForExpirationTest {
    public static final Time TIME5 = Time.newInstance(17, 0, 0, 0);
    public static final Time TIME6 = Time.newInstance(18, 0, 0, 0);
    public static final Time TIME4 = Time.newInstance(16, 0, 0, 0);
    public static final Time TIME6AM = Time.newInstance(6, 0, 0, 0);
    public static final Time TIME9 = Time.newInstance(21, 0, 0, 0);
    public static final Time TIME10 = Time.newInstance(22, 0, 0, 0);  
    public static final Time TIME2 = Time.newInstance(14, 0, 0, 0);
    /*
* This Method will be used to setup the data for the test class execution.
*/
    @TestSetup
    private static void setup(){
        List<String>lstProfileNames = New List<String>{'System Administrator','Sales User'};
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SLS_Permission_Set_Group'};
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        Integer intuserCount =0;
        User objSystemNAUser;  
        User objSystemBRUser;
        List<User> lstUser = PMC_TestUtilityClass.createUser(2);
        for(User objUser : lstUser) {
            objUser.LastName = 'Admin User Test'+intuserCount;
            objUser.ProfileId = mapOfProfiles.get('System Administrator'); 
            objUser.FederationIdentifier = objUser.Username + 'Admin';
            objUser.isActive = true;                
            objUser.MobilePhone = '1234567890';
            objUser.UserPermissionsKnowledgeUser =true;
            objUser.LanguageLocaleKey = 'en_US';
            intuserCount = intuserCount + 1;
        }            
        insert lstUser;
        objSystemNAUser = lstUser[0];
        objSystemNAUser.PMC_CPQ_PrimaryBusinessType__c='Fertilizer';
        objSystemNAUser.PMC_CPQ_SalesRegion__c = 'North America';
        update objSystemNAUser;
        objSystemBRUser = lstUser[1];
        objSystemBRUser.PMC_CPQ_PrimaryBusinessType__c='B2B - Potash';
        objSystemBRUser.PMC_CPQ_SalesRegion__c = 'Brazil';
        update objSystemBRUser;
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemNAUser,objSystemBRUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        system.runAs(objSystemNAUser){
            List<Opportunity> lstOpportunities;
            lstOpportunities = PMC_TestUtilityClass.createOpportunity(2,'Master');
            List<Contact> lstContacts;
            lstContacts = PMC_TestUtilityClass.createContact(1,'Master');
        }
    }
    /* 
* This method will be used to cover the updateExpirationForNA method of the PMC_CPQ_UpdateQuoteForExpirationClass.
*/ 
    @isTest private static void testUpdateExpirationForNA(){
        
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();
        test.startTest();
        User objUser = [select Id, Name from User where LastName =: 'Admin User Test0'];
        System.runAs(objUser){
            List<Opportunity> lstOppty = [select Id, AccountId from Opportunity LIMIT 1 ];
            List<Account> lstAccount = [select Id,PMC_SS_CustomerType__c from Account where Id =:lstOppty.get(0).AccountId];
            lstAccount.get(0).PMC_SS_SAPCustomerNumber__c = '6531895430';
            update lstAccount;
            List<Contact> lstCont = [select Id from Contact LIMIT 1];
            lstCont.get(0).AccountId = lstAccount.get(0).Id;
            update lstCont;
            
            SBQQ__Quote__c objQuote1 = new SBQQ__Quote__c(SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(3,TIME4));//Wednesday 6am
            insert objQuote1;
            objQuote1.SubmittedUser__c = objUser.Id;
            objQuote1.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote1;
            lstQuote.add(objQuote1);
            //GCPM-298 Start
            SBQQ__Quote__c objQuote2 = new SBQQ__Quote__c(SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(3,TIME6));//Wednesday 6pm
            insert objQuote2;
            objQuote2.SubmittedUser__c = objUser.Id;
            objQuote2.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote2;
            lstQuote.add(objQuote2);
            
            SBQQ__Quote__c objQuote3 = new SBQQ__Quote__c(SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(5,TIME6));//Friday 6pm
            insert objQuote3;
            objQuote3.SubmittedUser__c = objUser.Id;
            objQuote3.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote3;
            lstQuote.add(objQuote3);
            
            //GCPM-298 End
            /*SBQQ__Quote__c objQuote6 = new SBQQ__Quote__c(SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(5,TIME9));//Friday 9pm
            insert objQuote6;
            objQuote6.SubmittedUser__c = objUser.Id;
            objQuote6.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote6;
            lstQuote.add(objQuote6);
            system.assert(lstQuote != null, true);*/
        }
        test.stopTest();
    }
     /* 
* This method will be used to cover the updateExpirationForNA method of the PMC_CPQ_UpdateQuoteForExpirationClass cover exception.
*/ 
    @isTest private static void testUpdateExpirationForNAException(){
        
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();
        test.startTest();
        PMC_CPQ_UpdateQuoteForExpirationHelper.testExceptionCalculateDateTime = true;
        User objUser = [select Id, Name from User where LastName =: 'Admin User Test0'];
        System.runAs(objUser){
            List<Opportunity> lstOppty = [select Id, AccountId from Opportunity LIMIT 1 ];
            List<Account> lstAccount = [select Id,PMC_SS_CustomerType__c from Account where Id =:lstOppty.get(0).AccountId];
            lstAccount.get(0).PMC_SS_SAPCustomerNumber__c = '6531895430';
            update lstAccount;
            List<Contact> lstCont = [select Id from Contact LIMIT 1];
            lstCont.get(0).AccountId = lstAccount.get(0).Id;
            update lstCont;
            
            SBQQ__Quote__c objQuote1 = new SBQQ__Quote__c(SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(3,TIME4));//Wednesday 6am
            insert objQuote1;
            objQuote1.SubmittedUser__c = objUser.Id;
            objQuote1.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote1;
            lstQuote.add(objQuote1);
            //GCPM-298 Start
            SBQQ__Quote__c objQuote2 = new SBQQ__Quote__c(SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(3,TIME6));//Wednesday 6pm
            insert objQuote2;
            objQuote2.SubmittedUser__c = objUser.Id;
            objQuote2.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote2;
            lstQuote.add(objQuote2);
            
            SBQQ__Quote__c objQuote3 = new SBQQ__Quote__c(SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(5,TIME6));//Friday 6pm
            insert objQuote3;
            objQuote3.SubmittedUser__c = objUser.Id;
            objQuote3.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote3;
            lstQuote.add(objQuote3);
            
            //GCPM-298 End
           /*SBQQ__Quote__c objQuote6 = new SBQQ__Quote__c(SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(5,TIME9));//Friday 9pm
            insert objQuote6;
            objQuote6.SubmittedUser__c = objUser.Id;
            objQuote6.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote6;
            lstQuote.add(objQuote6);
            system.assert(lstQuote != null, true);*/
        }
        test.stopTest();
    }

    /* 
* This method will be used to cover the updateExpirationForNA method of the PMC_CPQ_UpdateQuoteForExpirationClass.
*/ 
    @isTest private static void testUpdateExpirationForNA1(){
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();
        test.startTest();
        User objUser = [select Id, Name from User where LastName =: 'Admin User Test0'];
        System.runAs(objUser){
            List<Opportunity> lstOppty = [select Id, AccountId from Opportunity LIMIT 1 ];
            List<Account> lstAccount = [select Id,PMC_SS_CustomerType__c from Account where Id =:lstOppty.get(0).AccountId];
            lstAccount.get(0).PMC_SS_SAPCustomerNumber__c = '6531895430';
            update lstAccount;
            List<Contact> lstCont = [select Id from Contact LIMIT 1];
            lstCont.get(0).AccountId = lstAccount.get(0).Id;
            update lstCont;
            
            SBQQ__Quote__c objQuote2 = new SBQQ__Quote__c(SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(0,TIME4));//Sunday 4pm
            insert objQuote2;
            objQuote2.SubmittedUser__c = objUser.Id;
            objQuote2.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote2;
            lstQuote.add(objQuote2);
            SBQQ__Quote__c objQuote4 = new SBQQ__Quote__c(SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(6,TIME4));//Saturday 4pm
            insert objQuote4;
            objQuote4.SubmittedUser__c = objUser.Id;
            objQuote4.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote4;
            lstQuote.add(objQuote4);
            system.assert(lstQuote != null, true);
        }
        test.stopTest();    
    }
    /* 
* This method will be used to calculate a future datetime value
* @param intWeekDay - the integer representation for the weekday to be calculated
* @param timeVariable - the time to consider
* @return datTRequiredDateTime - the calculated datetime 
*/
    private static DateTime calculateFutureDateTime(Integer intWeekDay, Time timeVariable){
        DateTime datTNow = system.now();
        Integer intDay;
        Switch on datTNow.format('EEEE'){
            when 'Sunday'{
                intDay = 0;
            }
            when 'Monday'{
                intDay = 1;
            }
            when 'Tuesday'{
                intDay = 2;
            }
            when 'Wednesday'{
                intDay = 3;
            }
            when 'Thursday'{
                intDay = 4;
            }
            when 'Friday'{
                intDay = 5;
            }
            when 'Saturday'{
                intDay = 6;
            }
        }
        
        Integer intFutureday = Math.mod((7 + intWeekDay - intDay) , 7);
        DateTime datTfutureDay = datTNow.addDays(intFutureday);
        DateTime datTRequiredDateTime = DateTime.newInstance(datTfutureDay.date(), timeVariable);
        return datTRequiredDateTime;
    }
    
    /* 
* This method will be used to cover the updateExpirationForBR method for List quotes of the PMC_CPQ_UpdateQuoteForExpirationClass.
*/ 
    @isTest private static void testUpdateExpirationForBR(){
        
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();
        User objUser = [select Id, Name from User where LastName =: 'Admin User Test1'];
        List<RecordType> quoRecType = [select Id,DeveloperName,SobjectType from RecordType where DeveloperName = 'PMC_CPQ_DomesticBR' and SobjectType = 'SBQQ__Quote__c' LIMIT 1];
        
        test.startTest();
        system.runAs(objUser){
            List<Opportunity> lstOppty = [select Id, AccountId from Opportunity ];
            
            List<Account> lstAccount = [select Id,PMC_SS_CustomerType__c from Account where Id =:lstOppty.get(0).AccountId];
            lstAccount.get(0).Type = 'Agents';
            lstAccount.get(0).PMC_SS_Channel__c = 'Seller';
            lstAccount.get(0).PMC_SS_CustomerType__c = 'B2B';
            lstAccount.get(0).PMC_SS_SAPCustomerNumber__c = '6541895430';
            update lstAccount;
            List<Contact> lstCont = [select Id from Contact LIMIT 1];
            lstCont.get(0).AccountId = lstAccount.get(0).Id;
            update lstCont;
            
            SBQQ__Quote__c objQuote1 = new SBQQ__Quote__c(RecordTypeId=quoRecType[0].Id,SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_AccountManager__c = objUser.Id, PMC_CPQ_QuoteClassification__c='Bid',PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(3,TIME4),PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, SBQQ__Opportunity2__c = lstOppty.get(0).Id, SBQQ__Status__c = 'Draft',PMC_CPQ_Region__c='Brazil');
            insert objQuote1;
            objQuote1.SubmittedUser__c = objUser.Id;
            objQuote1.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote1;
            lstQuote.add(objQuote1);
            
            SBQQ__Quote__c objQuote2 = new SBQQ__Quote__c(RecordTypeId=quoRecType[0].Id,SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_AccountManager__c = objUser.Id, PMC_CPQ_QuoteClassification__c='Bid',PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(3,TIME9),PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, SBQQ__Opportunity2__c = lstOppty.get(1).Id, SBQQ__Status__c = 'Draft',PMC_CPQ_Region__c='Brazil');
            insert objQuote2;
            objQuote2.SubmittedUser__c = objUser.Id;
            objQuote2.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote2;
            lstQuote.add(objQuote2);
            
            SBQQ__Quote__c objQuote3 = new SBQQ__Quote__c(RecordTypeId=quoRecType[0].Id,SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_AccountManager__c = objUser.Id, PMC_CPQ_QuoteClassification__c='Bid',PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(5,TIME6),PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, SBQQ__Opportunity2__c = lstOppty.get(1).Id, SBQQ__Status__c = 'Draft',PMC_CPQ_Region__c='Brazil');
            insert objQuote3;
            objQuote3.SubmittedUser__c = objUser.Id;
            objQuote3.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote3;
            lstQuote.add(objQuote3);
            
            /*SBQQ__Quote__c objQuote3 = new SBQQ__Quote__c(RecordTypeId=quoRecType[0].Id,SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_AccountManager__c = objUser.Id, PMC_CPQ_QuoteClassification__c='Bid',PMC_CPQ_CustomCreatedDate__c =calculateFutureDateTime(3,TIME6AM),PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, SBQQ__Opportunity2__c = lstOppty.get(1).Id, SBQQ__Status__c = 'Draft',PMC_CPQ_Region__c='Brazil');
            insert objQuote3;
            objQuote3.SubmittedUser__c = objUser.Id;
            objQuote3.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote3;
            lstQuote.add(objQuote3);*/
            system.assert(lstQuote != null, true);
        }    
        test.stopTest();
    }
    /* 
* This method will be used to cover the updateExpirationDateAndTimeOnRequestedExpiration method for List quotes of the PMC_CPQ_UpdateQuoteForExpirationClass.
*/ 
    @isTest private static void testReqExp(){
        test.startTest();
        User objUser = [select Id, Name from User where LastName =: 'Admin User Test0'];
        System.runAs(objUser){
            List<Opportunity> lstOppty = [select Id, AccountId from Opportunity LIMIT 1 ];
            List<Account> lstAccount = [select Id,PMC_SS_CustomerType__c from Account where Id =:lstOppty.get(0).AccountId];
            lstAccount.get(0).PMC_SS_SAPCustomerNumber__c = '6531895430';
            update lstAccount;
            List<Contact> lstCont = [select Id from Contact LIMIT 1];
            lstCont.get(0).AccountId = lstAccount.get(0).Id;
            update lstCont;
            
            SBQQ__Quote__c objQuote1 = new SBQQ__Quote__c(SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, PMC_CPQ_RequestedExpirationDateTime__c =calculateFutureDateTime(3,TIME6AM));//Wednesday 6am
            insert objQuote1;
            objQuote1.SubmittedUser__c = objUser.Id;
            objQuote1.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote1;
            system.assert(objQuote1 != null, true);
        }
        test.stopTest();
    }
      /* 
* This method will be used to cover the updateExpirationDateAndTimeOnRequestedExpiration method for List quotes of the PMC_CPQ_UpdateQuoteForExpirationClass to cover exception.
*/ 
    @isTest private static void testReqExpException(){
        
        test.startTest();
        PMC_CPQ_UpdateQuoteForExpirationHelper.testExceptionRequestedExpiration = true;
        User objUser = [select Id, Name from User where LastName =: 'Admin User Test0'];
        System.runAs(objUser){
            List<Opportunity> lstOppty = [select Id, AccountId from Opportunity LIMIT 1 ];
            List<Account> lstAccount = [select Id,PMC_SS_CustomerType__c from Account where Id =:lstOppty.get(0).AccountId];
            lstAccount.get(0).PMC_SS_SAPCustomerNumber__c = '6531895430';
            update lstAccount;
            List<Contact> lstCont = [select Id from Contact LIMIT 1];
            lstCont.get(0).AccountId = lstAccount.get(0).Id;
            update lstCont;
            
            SBQQ__Quote__c objQuote1 = new SBQQ__Quote__c(SBQQ__Account__c = lstAccount.get(0).Id,PMC_CPQ_PrimaryContact__c=lstCont.get(0).Id, PMC_CPQ_RequestedExpirationDateTime__c =calculateFutureDateTime(3,TIME6AM));//Wednesday 6am
            insert objQuote1;
            objQuote1.SubmittedUser__c = objUser.Id;
            objQuote1.ApprovalStatus__c = Label.PMC_CPQ_QuoteStatusApproved;
            update objQuote1;
            system.assert(objQuote1 != null, true);
        }
        test.stopTest();
    }
}