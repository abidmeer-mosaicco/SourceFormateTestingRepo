/**
 * @description This class helps to process all the Exceptions in the Apex code.
 * 
 * @author Sachin Seshabhattar
 */
public without sharing class PMC_ErrorLogClass {
    
    //Public variables.
    public static Boolean boolSkipAttachmentGeneration = false;
    public static final String STRING_EXCEPTION_MATCHER = '(?i)^(?:class\\.)?([^.]+)\\.?([^\\.\\:]+)?[\\.\\:]?([^\\.\\:]*): line (\\d+), column (\\d+)$';
    public static final String STRING_BREAK_LINE = '\n';
    public static final String STRING_CLASS_METHOD_SEPARATOR = '.';
    public static final String STRING_CONSTRUCTOR_TOKEN = '<init>';
    public static final String STRING_CONSTRUCTOR_TOKEN_REPLACEMENT = '(constructor)';
    public static final String STRING_GETTER_SETTER_TOKEN = '__sfdc_';
    public static final String STRING_GETTER_SETTER_TOKEN_REPLACEMENT = '(getter/setter)';
    public static final String STRING_HELPER_PARAMETER_NAME = 'errorLogRecordSerialized';
    public static final String STRING_HELPER_PARAMETER_NAME_SUFFIX = '=';
    public static final String STRING_HELPER_URL_ENCODING = 'UTF-8';
    public static final Integer INTEGER_URL_LIMIT = 4096;
    public static final Integer INTEGER_LONG_TEXT_AREA_FIELD_LIMIT = 131072;
    
    @TestVisible
    private static Boolean boolThrowException = false;
    
    
    /**
     * @description This is a custom exception class for Error Log Insert Fail
     */
    public class PMC_ErrorLogInsertFailedException extends Exception {}
    
    /**
     * @description This method processes the exception, extracting the error message and creating the Error Log record.
     *
     * @param objException    Exception to be processed.
     * @return String with Exception message.
     */
    public static String processException(Exception objException) {
        return extractSingleExceptionMessage(processExceptions(prepareSingleExceptionRecord(objException, null, null), new PMC_ProcessExceptionParamWrapperClass()));
    }
    
    /**
     * @description This method processes the exception, extracting the error message and creating the Error Log record.
     *
     * @param objException    Exception to be processed.
     * @param paramList Wrapper class object having following variables:
     * 		boolCreateApexPageMessage    Indicates if the method should include the exception message in the current ApexPage messages.
     * 		strUserFriendlyMessage    User-friendly message related to the exception.
     * 		objSeverity    Message Severity for ApexPage Messages.
     * @return String with Exception message.
     */
    public static String processException(Exception objException,PMC_ProcessExceptionParamWrapperClass paramList) {
        return extractSingleExceptionMessage(processExceptions(prepareSingleExceptionRecord(objException, null, null), paramList));
    }
    
    /**
     * @description This method processes the exception, extracting the error message and creating the Error Log record.
     *
     * @param objException    Exception to be processed.
     * @param paramList Wrapper class object having following variables:
     * 		boolCreateApexPageMessage    Indicates if the method should include the exception message in the current ApexPage messages.
     * 		strUserFriendlyMessage    User-friendly message related to the exception.
     * 		objSeverity    Message Severity for ApexPage Messages.
     * @param objClass    Object to be serialized, with all its values.
     * @return String with Exception message.
     */
    public static String processException(Exception objException,PMC_ProcessExceptionParamWrapperClass paramList, Object objClass) {
        return extractSingleExceptionMessage(processExceptions(prepareSingleExceptionRecord(objException, objClass, null), paramList));
    }
    
    /**
     * @description This method processes the exception, extracting the error message and creating the Error Log record.
     *
     * @param objException    Exception to be processed.
     * @param objClass    Object to be serialized, with all its values.
     * @return String with Exception message.
     */
    public static String processException(Exception objException, Object objClass) {
        return extractSingleExceptionMessage(processExceptions(prepareSingleExceptionRecord(objException, objClass, null), new PMC_ProcessExceptionParamWrapperClass()));
    }
    
    /**
     * @description This method processes the exception, extracting the error message and creating the Error Log record.
     *
     * @param objException    Exception to be processed.
     * @param objClass    Object to be serialized, with all its values.
     * @param objAdditionalObject    Object to be serialize, to provide additional details to the developer.
     * @return String with Exception message.
     */
    public static String processException(Exception objException, Object objClass, Object objAdditionalObject) {
        return extractSingleExceptionMessage(processExceptions(prepareSingleExceptionRecord(objException, objClass, objAdditionalObject),new PMC_ProcessExceptionParamWrapperClass()));
    }
    
    /**
     * @description This method extracts the error message from the first error log record.
     *
     * @param lstExceptions    List of wrapped error logs.
     * @return Error message.
     */
    public static String extractSingleExceptionMessage(List<PMC_ErrorLogWrapperClass> lstExceptions) {
        String strResult = Label.PMC_ErrorLog_Class_UnableToProcessException;
        if(lstExceptions != null) {
            for(PMC_ErrorLogWrapperClass objNewException : lstExceptions) {
                strResult = objNewException.strErrorMessage;
                break;
            }
        }
        return strResult;
    }
    
    /**
     * @description This method prepares the list for the generic method, with one single exception record.
     *
     * @param objException    Exception to be processed.
     * @param objClass    Object to be serialized, with all its values.
     * @param objAdditionalObject    Object to be serialize, to provide additional details to the developer.
     * @return List of Wrapped records.
     */
    public static List<PMC_ErrorLogWrapperClass> prepareSingleExceptionRecord(Exception objException, Object objClass, Object objAdditionalObject) {
        List<PMC_ErrorLogWrapperClass> lstExceptions = new List<PMC_ErrorLogWrapperClass>();
        if(objException != null) {
            PMC_ErrorLogWrapperClass objNewException = new PMC_ErrorLogWrapperClass();
            objNewException.objException = objException;
            objNewException.objClass = objClass;
            objNewException.objAdditionalObject = objAdditionalObject;
            lstExceptions.add(objNewException);
        }
        return lstExceptions;
    }
    
    /**
     * @description This method processes a list of exceptions, extracting the error message and creating the Error Log records.
     *
     * @param lstExceptions    Exceptions to be processed.
     * @return Wrapped Error Logs.
     */
    public static List<PMC_ErrorLogWrapperClass> processExceptions(List<PMC_ErrorLogWrapperClass> lstExceptions) {
        return processExceptions(lstExceptions, new PMC_ProcessExceptionParamWrapperClass());
    }
    
    /**
     * @description This method processes the exception, extracting the error message and creating the Error Log record.
     *
     * @param lstExceptions    Exceptions to be processed.
     * @param paramList Wrapper class object having following variables:
     * 		boolCreateApexPageMessage    Indicates if the method should include the exception message in the current ApexPage messages.
     * 		strUserFriendlyMessage    User-friendly message related to the exception.
     * 		objSeverity    Message Severity for ApexPage Messages.
     * @return String with Exception message.
     */
    public static List<PMC_ErrorLogWrapperClass> processExceptions(List<PMC_ErrorLogWrapperClass> lstExceptions, PMC_ProcessExceptionParamWrapperClass paramList) {
        List<PMC_ErrorLog__c> lstErrorLogs = new List<PMC_ErrorLog__c>();
        
        //Now we process the exceptions.
        PMC_ErrorLog__c objNewException;
        for(PMC_ErrorLogWrapperClass objExceptionWrapper : lstExceptions) {
            if(objExceptionWrapper.objException != null) {
                objNewException = new PMC_ErrorLog__c();
                objNewException = extractExceptionCaller(objExceptionWrapper.objException, objNewException);
                objNewException.PMC_Message__c = objExceptionWrapper.objException.getMessage();
                objNewException.PMC_StackTrace__c = objExceptionWrapper.objException.getStackTraceString();
                objNewException.PMC_Type__c = 'Apex';
                objNewException.PMC_SerializedClass__c = objExceptionWrapper.objClass != null?JSON.serialize(objExceptionWrapper.objClass):'';
                objExceptionWrapper.strErrorMessage = objExceptionWrapper.objException.getMessage();
                lstErrorLogs.add(objNewException);
            }
        }
        //Now, we send the record to the future method, to store the data.
        try {   
            if(boolThrowException){
                throw new QueryException('Covering the catch block');
            }
            futureInsertErrorLogRecords(JSON.serialize(lstErrorLogs));
            
        } catch(Exception objInternalException) {
            insertErrorLogRecords(lstErrorLogs);
        }
        
        return lstExceptions;
    }
    
    /**
     * @description Returns the patter to find the Class Name and Method of the excepsion causer.
     *
     * @param objException    Exception.
     * @param objNewException    Error log record.
     * @return Error Log object.
     */
    public static PMC_ErrorLog__c extractExceptionCaller(Exception objException, PMC_ErrorLog__c objNewException) {
        if(objNewException == null) {
            objNewException = new PMC_ErrorLog__c();
        }
        if(objException != null) {
            Matcher objMatcher = Pattern.compile(STRING_EXCEPTION_MATCHER).matcher(objException.getStackTraceString().substringBefore(STRING_BREAK_LINE));
            if(objMatcher.find() && String.isBlank(objMatcher.group(3))) {
                    objNewException.PMC_ClassName__c = objMatcher.group(1);
                    objNewException.PMC_MethodName__c = prettifyMethodName(objMatcher.group(2));
                } else {
                    objNewException.PMC_ClassName__c = objMatcher.group(1) + STRING_CLASS_METHOD_SEPARATOR + objMatcher.group(2);
                    objNewException.PMC_MethodName__c = prettifyMethodName(objMatcher.group(3));
                }
            }
        return objNewException;
    }
    
    /**
     * @description Extracts and prettifies the method names from the exception caller.
     *
     * @param strName    Method name.
     * @return Prettified name.
     */
    public static String prettifyMethodName(String strName) {
        if(String.IsNotBlank(strName)) {
            strName = strName.replace(STRING_CONSTRUCTOR_TOKEN, STRING_CONSTRUCTOR_TOKEN_REPLACEMENT).replace(STRING_GETTER_SETTER_TOKEN, STRING_GETTER_SETTER_TOKEN_REPLACEMENT);
        }
        return strName;
    }
    
    /**
     * @description This method inserts the Error log records, based on the serialized data.
     *
     * @param strSerializedErrorLogRecords    Serialized Error Log Record.
     */
    @future
    public static void futureInsertErrorLogRecords(String strSerializedErrorLogRecords) {
        try {
            insertErrorLogRecords((List<PMC_ErrorLog__c>) JSON.deserialize(strSerializedErrorLogRecords, List<PMC_ErrorLog__c>.class));
        } catch(Exception objInternalException) {
            //Catching the exception in the block
            throw new PMC_ErrorLogInsertFailedException(objInternalException.getMessage());
        }
    }
    
    /**
     * @description This method inserts Error log records.
     *
     * @param lstErrorLogRecords    List of Error Log records.
     */
    public static void insertErrorLogRecords(List<PMC_ErrorLog__c> lstErrorLogRecords) {
        if(lstErrorLogRecords == NULL || lstErrorLogRecords.size() == 0){
            return;
        }
        
            Integer intCounter = 0;
            Attachment objAttachment;
            List<Attachment> lstAttachments = new List<Attachment>();
            
            //We first prepare all the Error Logs and Attachments (if any).
            for(PMC_ErrorLog__c objError : lstErrorLogRecords) {
                intCounter++;
                objError.PMC_ExternalId__c = Userinfo.getUserId() + DateTime.now() + ':' + DateTime.now().millisecond() + ':' + intCounter;
            objAttachment = PMC_ErrorLogHelperClass.processErrorLogRecord(objError, INTEGER_LONG_TEXT_AREA_FIELD_LIMIT, boolSkipAttachmentGeneration);
            if(objAttachment != null){
                lstAttachments.add(objAttachment);
            }
        }
        
        //Now we insert the error logs
        if(Schema.sObjectType.PMC_ErrorLog__c.isCreateable()){
            insert lstErrorLogRecords;
        }
        
        //Now we create the attachments.
        if(!boolSkipAttachmentGeneration && lstAttachments.size() > 0) {
            PMC_ErrorLogHelperClass.insertAttachmentRecords(lstAttachments, lstErrorLogRecords);
        }
        
    }

    
    /**
     * @description wrapper class for parameters of processException/processExceptions methods.
     * 
     */
    public class PMC_ProcessExceptionParamWrapperClass {
       //public variables 
      public Boolean boolCreateApexPageMessage;
      public String strUserFriendlyMessage;
      public ApexPages.Severity objSeverity;
    }
}