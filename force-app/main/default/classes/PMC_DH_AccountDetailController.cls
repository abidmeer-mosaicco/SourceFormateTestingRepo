/**
* @description       : Controller for fetching Account and Account Team member detail
* @author            : @Krishan Jangir
* @group             : 
* @last modified on  : 01-19-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/
public without sharing class PMC_DH_AccountDetailController {
    public static Boolean boolThrowException=false;
    /**
    * @description 
    * @author @krishan | 05-19-2023 
    * @param effAccId 
    * @return AccounStatusWrapper
    **/
    @AuraEnabled(cacheable=true)
    public static AccounStatusWrapper getAccountDetail(String effAccId){
        AccounStatusWrapper accountDetails = new AccounStatusWrapper();
        List<AccounDetailWrapper> lstAccountDeatailWrapper = new List<AccounDetailWrapper>();
        List<String> lstTeamMemberRole = new List<String>{PMC_DH_ConstantClass.ACCOUNT_TEAMMEMBERSSR};//PMC_DH_ConstantClass.ACCOUNT_TEAMMEMBERACC,
        AccounDetailWrapper accDetail = new AccounDetailWrapper(); 
        try{ 
            if(!String.isBlank(effAccId)){
                Account objAccRecord;
                if(Schema.sObjectType.Account.isAccessible()){
                    objAccRecord = [SELECT Id, Name, AccountNumber, Phone, ShippingCountry, Owner.Name, Owner.Phone, Owner.Email, Owner.Country, PMC_DH_Email__c  FROM Account WHERE Id=:effAccId WITH SECURITY_ENFORCED];
                }
             
                        accDetail.strAccName = objAccRecord.Name;
                        accDetail.strAccNumber = objAccRecord.AccountNumber;
                        accDetail.strAccPhoneNo = objAccRecord.Phone;
                accDetail.strAccEmail = objAccRecord.PMC_DH_Email__c; //'mosaictest@gmail.com'; // dependency with  GPSSM-1837 Story Number for the Email Field From S&S to map the data
                accDetail.strAccCountry = objAccRecord.ShippingCountry;
                accDetail.strAccManagerName = objAccRecord.Owner.Name;
                accDetail.strAccManagerPhoneNo = getUnformattedPhoneNumber(objAccRecord.Owner.Phone);//accTeam.User.Phone;
                accDetail.strAccManagerEmail = objAccRecord.Owner.Email;
                accDetail.strAccManagerCountry = objAccRecord.Owner.Country;
            
                List<AccountTeamMember> objAccTeamMembers=getAccountTeamMembers(effAccId,lstTeamMemberRole);
                if(!objAccTeamMembers.isEmpty()){
                for (AccountTeamMember accTeam : objAccTeamMembers) {
                    switch on (accTeam.TeamMemberRole) {
                        // when  'Account Manager' {
                        //     accDetail.strAccManagerName = accTeam.Account.Owner.Name;
                        //     accDetail.strAccManagerPhoneNo = getUnformattedPhoneNumber(accTeam.Account.Owner.Phone);//accTeam.User.Phone;
                        //     accDetail.strAccManagerEmail = accTeam.Account.Owner.Email;
                        //     accDetail.strAccManagerCountry = accTeam.Account.Owner.Country;
                        //     //accDetail.strAccountManagerCountryCode = PMC_DH_DigitalHubB2BUtils.getFormattedCountryCode(accTeam.User.CountryCode);
                        // }
                        when  'Sales Support Representative' {
                            accDetail.strSSRName = accTeam.User.Name;
                            accDetail.strSSRPhone = getUnformattedPhoneNumber(accTeam.User.Phone);//accTeam.User.Phone;
                            accDetail.strSSREmail = accTeam.User.Email;
                            accDetail.strSSRCountry = accTeam.User.Country;
                            //accDetail.strSSRCountryCode = PMC_DH_DigitalHubB2BUtils.getFormattedCountryCode(accTeam.User.CountryCode);
                        }
                    }
                   
                }
            }
            
                lstAccountDeatailWrapper.add(accDetail);
            }
            accountDetails.lstAccounts = lstAccountDeatailWrapper;
            accountDetails.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'AccountDetails');
            //return lstAccountDeatailWrapper;
        }
        catch(Exception ex){
            //throw new AuraHandledException(ex.getMessage());
            accountDetails.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
        }
        return accountDetails;
    }

     private static String getUnformattedPhoneNumber(String strFormatterPhone){
        String strUnformattedPhoneNumber = '';
            if(strFormatterPhone!=NULL){
            List<String> lstPhnnumber = strFormatterPhone.split(' ',2);
            if(lstPhnnumber.size()>1){
                strUnformattedPhoneNumber = lstPhnnumber[1];
            }else{
                strUnformattedPhoneNumber = lstPhnnumber[0];
            }
        }
        return strUnformattedPhoneNumber;
    }

    /**
    * @description fetch the list of account team members
    * @author @siddharth.pradhan | 05-19-2023 
    * @param strEffectiveAccountId 
    * @param lstTeamMemberRole 
    * @return List<AccountTeamMember> 
    **/
    private static List<AccountTeamMember> getAccountTeamMembers(String strEffectiveAccountId,List<String> lstTeamMemberRole) {
        List<AccountTeamMember> lstAccTeamMembers=new List<AccountTeamMember>();
        if(Schema.sObjectType.AccountTeamMember.isAccessible()){
            lstAccTeamMembers=[SELECT Id,TeamMemberRole,User.Name, User.Phone,User.Email,User.Country,Account.OwnerId,Account.Owner.Name,Account.Owner.Phone, Account.Owner.Email, Account.Owner.Country FROM AccountTeamMember  WHERE AccountId=:strEffectiveAccountId
 			and TeamMemberRole in:lstTeamMemberRole WITH SECURITY_ENFORCED];
        }
        return lstAccTeamMembers;
    }


/** 
 * @description method to send Account Manager Name 
 * @author @hemant.girigoswami
 * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
 * @param strEffAccId
 **/
@AuraEnabled(cacheable=true)
public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper getAccountManagerName(String strEffAccId)
{   
    PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusWrp = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
   try {
       
       if(boolThrowException && Test.isRunningTest())
       {
           throw new AuraHandledException('Exception Test');
            }
    Account accObjRecord=[SELECT Owner.name from Account WHERE id=:strEffAccId WITH SECURITY_ENFORCED];
    statusWrp = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'AccountDetails');
    statusWrp.strData = accObjRecord.Owner.Name;
    // return strAccountManagerName;
    } catch (Exception e) {
        statusWrp = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All');
         //throw new AuraHandledException('Exception Handled');       
    }
    return statusWrp;
}
 
    /**
 * @description Wrapper class for Account Detail
 * @author @KrishanJangir 
 * 
**/
    public with sharing class AccounDetailWrapper{
        /**
     * @description  Name of Account 
     * @return String
     */
        @AuraEnabled 
        public String strAccName {get;set;}
        /**
     * @description  Account Number of Account 
     * @return String
     */
        @AuraEnabled
        public String strAccNumber {get;set;}
        /**
     * @description  Phone of Account 
     * @return String
     */
        @AuraEnabled
        public String strAccPhoneNo {get;set;}
        /**
     * @description  Email of Account 
     * @return String
     */
        @AuraEnabled
        public String strAccEmail {get;set;}
        /**
     * @description  Country of Account 
     * @return String
     */
        @AuraEnabled 
        public String strAccCountry {get;set;}
        /**
     * @description  Manager name of account team member 
     * @return String
     */
        @AuraEnabled
        public String strAccManagerName {get;set;}
        /**
     * @description  Manager Phone of account team member 
     * @return String
     */
        @AuraEnabled
        public String strAccManagerPhoneNo {get;set;}
        /**
     * @description  Manager email of account team member 
     * @return String
     */
        @AuraEnabled
        public String strAccManagerEmail {get;set;}
        /**
     * @description  Country of Account Manager 
     * @return String
     */
        @AuraEnabled 
        public String strAccManagerCountry {get;set;}
        /**
     * @description  SSR name of account team member 
     * @return String
     */
        @AuraEnabled
        public String strSSRName {get;set;}
        /**
     * @description  SSR Phone of account team member 
     * @return String
     */
        @AuraEnabled
        public String strSSRPhone {get;set;}
        /**
     * @description  SSR email of account team member 
     * @return String
     */
        @AuraEnabled
        public String strSSREmail {get;set;}
        /**
     * @description  Country of SSR 
     * @return String
     */
        @AuraEnabled
        public String strSSRCountry {get;set;}
    }

/**
 * @description Wrapper class for Account Detail Response Handling
 * @author @ManishaSingh 
 * 
**/
public with sharing class AccounStatusWrapper{

    /**
     * @description List of Account Details
     * @return List<AccounDetailWrapper>
     */
    @AuraEnabled 
    public List<AccounDetailWrapper> lstAccounts {get;set;}

    /**
    * @description Status Code and message
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
}
}