/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-05-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class PMC_SS_ObjectDetailsWrapper {
    /**
    * @description - holds the object Id
    */
        @AuraEnabled
        public Id idRecord{get;set;}
        
        /**
    * @description - holds the object name
    */
        @AuraEnabled
        public String strRecordName{get;set;}
        
        /**
    * @description - constructor for wrapper class
    * @param idRecord - Record Id
    * @param strRecordName - Record Name
    */
        public PMC_SS_ObjectDetailsWrapper(Id idRecord, String strRecordName) {
            this.idRecord =  idRecord;
            this.strRecordName = strRecordName;
        }
    
}