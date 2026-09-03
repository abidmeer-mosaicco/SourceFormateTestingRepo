/**
 * @description This test class will be used to cover all the methods of PMC_ErrorLogClass, Generic class used for all the error handling scenarios
 * @author Sayali Shinde
 */
@isTest
public with sharing class PMC_ErrorLogTest {
 /**
     * @description This method tests the normal scenarios, using all the available methods.
     */
    @isTest
    public static void errorLogMethods() {
        Integer intInteger;
        Test.startTest();
        try {
            intInteger = 1/0;
        } catch(Exception objException) {
            String strResult = PMC_ErrorLogClass.processException(objException);
            System.assertEquals(strResult, 'Divide by 0', 'Invalid message returned  : ' + strResult);
                      
            //Now we test a list of exceptions.
            PMC_ErrorLogClass.PMC_ProcessExceptionParamWrapperClass objNewExceptionParams = new PMC_ErrorLogClass.PMC_ProcessExceptionParamWrapperClass();
            PMC_ErrorLogClass.processException(objException,objNewExceptionParams);
            PMC_ErrorLogClass.processException(objException,objNewExceptionParams,new Account());
            PMC_ErrorLogClass.processException(objException,new Account());
            PMC_ErrorLogClass.processException(objException,new Account(),new Account());
            List<PMC_ErrorLogWrapperClass> lstExceptions = new List<PMC_ErrorLogWrapperClass>();
            PMC_ErrorLogWrapperClass objNewException = new PMC_ErrorLogWrapperClass();
            objNewException.objException = objException;
            lstExceptions.add(objNewException);
            objNewException = new PMC_ErrorLogWrapperClass();
            objNewException.objException = objException;
            objNewException.strClassName = 'TestClassName';
            lstExceptions.add(objNewException);
            PMC_ErrorLogClass.processExceptions(lstExceptions);
        }
        Test.stopTest();
    }
    
     /**
     * @description This method tests when a developer calls the Exception Caller method directly, without proper parameters.
     */
    @isTest
    public static void exceptionScenarioInvalidCaller() {
        Test.startTest();
        PMC_ErrorLogClass.extractExceptionCaller(null, null);
        Test.stopTest();
        Integer intResult = [SELECT Id FROM PMC_ErrorLog__c].size();
        System.assertEquals(intResult, 0, '1 record was expected but ' + intResult + ' were found.');
    }
    
    /**
     * @description This method tests the normal scenarios, using all the available methods.
     */
    @isTest
    public static void skipAttachmentGeneration() {
        Integer intInteger;
        Test.startTest();
        try {
            intInteger = 1/0;
        } catch(Exception objException) {
            String strResult = PMC_ErrorLogClass.processException(objException);
            System.assertEquals(strResult, 'Divide by 0', 'Invalid message returned : ' + strResult);
            String strLongResponse = '';
            for(Integer intCount = 0; intCount <= PMC_ErrorLogClass.INTEGER_LONG_TEXT_AREA_FIELD_LIMIT; intCount++) {
                strLongResponse += 'a';
            }
            PMC_ErrorLogClass.boolSkipAttachmentGeneration = true;
            PMC_ErrorLogClass.processException(objException, strLongResponse, strLongResponse);
        }
        Test.stopTest();
    }
    
    /**
     * @description This method tests when a developer calls the Future method directly, without proper parameters.
     */
    @isTest
    public static void exceptionScenarioInvalidSerializedRecord() {
        Test.startTest();
        PMC_ErrorLogClass.futureInsertErrorLogRecords(JSON.serialize(new List<PMC_ErrorLog__c>()));
        Test.stopTest();
        Integer intResult = [SELECT Id FROM PMC_ErrorLog__c].size();
        System.assertEquals(intResult, 0, '1 record was expected but ' + intResult + ' were found.');
    }
    
    /**
     * @description This method tests the insertAttachmentRecords() method when no attachments are passed.
     */
    @isTest
    public static void exceptionScenarioEmptyAttachmentList() {
        Boolean boolExceptionCaught = false;
        List<Attachment> lstAttachments;
        List<PMC_ErrorLog__c> lstErrorLogs = new List<PMC_ErrorLog__c>();
        Test.startTest();
        PMC_ErrorLog__c objErrorLog = new PMC_ErrorLog__c();
        objErrorLog.PMC_ExternalId__c = 'Testing ExternalId';
        insert objErrorLog;
        lstErrorLogs.add(objErrorLog);
        try{
            PMC_ErrorLogHelperClass.insertAttachmentRecords(lstAttachments,lstErrorLogs);
        }catch(Exception ex){
            boolExceptionCaught = true;
        }
        
        Test.stopTest();
        system.assertEquals(true, boolExceptionCaught, 'Expected no attachment records to be inserted.');
    }
    
    /**
     * @description This method tests the insertErrorLogRecords() method when no error logs are passed.
     */
    @isTest
    public static void exceptionScenarioEmptyErrorLogList() {
        List<PMC_ErrorLog__c> lstErrorLogs;
        Test.startTest();
        PMC_ErrorLogClass.insertErrorLogRecords(lstErrorLogs);
        Test.stopTest();
        Integer intResult = [SELECT Id FROM PMC_ErrorLog__c].size();
        system.assertEquals(0, intResult, 'Expected no error log records to be inserted.');
    }
    
    /**
     * @description This method tests catch block of the processException() method.
     */
    @isTest
    public static void exceptionScenarioProcessExceptionCatchBlock() {
        QueryException objException = new QueryException('Query Exception Occurred');
		Account objAccount = new Account(Name='AccountTest');
        Test.startTest();
        PMC_ErrorLogClass.boolThrowException = true;
        PMC_ErrorLogClass.processException(objException, objAccount, NULL);
        Test.stopTest();
        Integer intResult = [SELECT Id FROM PMC_ErrorLog__c].size();
        system.assertEquals(1, intResult, 'Expected one error log records to be inserted.');
    }
    
    /**
     * @description This method tests the normal scenarios, using all the available methods.
     */
    @isTest
    public static void scenarioAdditonalSerializedObject() {
        Integer intLongTextAreaFieldLimit = 10; 
        Boolean boolSkipAttachmentGeneration = true;
        PMC_ErrorLog__c objErrorLog = new PMC_ErrorLog__c();
        objErrorLog.PMC_AdditionalSerializedObject__c = 'Additonal Serialized Object';
        Test.startTest();
        PMC_ErrorLogHelperClass.processErrorLogRecord(objErrorLog, intLongTextAreaFieldLimit, boolSkipAttachmentGeneration);
        Test.stopTest();
        System.assertEquals(true, objErrorLog.PMC_AdditionalSerializedObject__c.equals('Data Trim'), 'Expected data trimmed message to be added to additionalSerializedObject field');
    }
    
    
}