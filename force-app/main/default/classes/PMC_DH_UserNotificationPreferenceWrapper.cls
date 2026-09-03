/**
* @description : Wrapper class for User Notification Preference
* @author      : Rohan Undale
* @userStory   : GDASF-543
* @last modified on 08-24-2023
* @last modified by @rravindraundale
**/
public without sharing class PMC_DH_UserNotificationPreferenceWrapper {
    /**
     * @description  List of Parent Notification wrapper
     * @return list<PMC_DH_ParentNotificationWrapper>
     */
    @AuraEnabled
    public List<PMC_DH_ParentNotificationWrapper> lstAllUserNofications{get;set;}

     /**
     * @description Status Code and message
     * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

    /**
     * @description  wrapper class for Parent Notification
     * @author Rohan Undale
     */
    public class PMC_DH_ParentNotificationWrapper{
        /**
         * @description Parent Notification Id
         * @return String
         */
        @AuraEnabled
        public String strParentNotificationId{get;set;}
        
        /**
         * @description Parent Notification Name
         * @return String
         */
        @AuraEnabled
        public String strParentNotificationName{get;set;}
        
        /**
         * @description Sequence
         * @return Integer
         */
        @AuraEnabled
        public Integer intSequence{get;set;}

        /**
         * @description  List of Parent Notification wrapper
         * @return list<PMC_DH_ChildNotificationWrapper>
         */
        @AuraEnabled
        public List<PMC_DH_ChildNotificationWrapper> lstChildNotifications{get;set;}
    }

    /**
     * @description  wrapper class for Child Notification
     * @author Rohan Undale
     */
    public class PMC_DH_ChildNotificationWrapper{
        /**
         * @description Notification Name
         * @return String
         */
        @AuraEnabled
        public String strNotificationName{get;set;}
        
        /**
         * @description Sequence
         * @return Integer
         */
        @AuraEnabled
        public Integer intSequence{get;set;}

        /**
         * @description  List of Channel Types wrapper
         * @return list<PMC_DH_ChannelTypeWrapper>
         */
        @AuraEnabled
        public List<PMC_DH_ChannelTypeWrapper> lstChannelTypes{get;set;}
    }

    /**
     * @description  wrapper class for Child Notification
     * @author Rohan Undale
     */
    public class PMC_DH_ChannelTypeWrapper{
        /**
         * @description Notification Id
         * @return String
         */
        @AuraEnabled
        public String strNotificationId{get;set;}
        
        /**
         * @description Notification Channel Type
         * @return String
         */
        @AuraEnabled
        public String strNotificationChannelType{get;set;}

        /**
         * @description Selected Value
         * @return Boolean
         */
        @AuraEnabled
        public Boolean boolSelectedValue{get;set;}

        /**
         * @description Disabled Notification
         * @return Boolean
         */
        @AuraEnabled
        public Boolean boolDisabledNotification{get;set;}

        /**
         * @description Is Notification Visible
         * @return Boolean
         */
        @AuraEnabled
        public Boolean boolIsNotificationVisible{get;set;}
    }
}