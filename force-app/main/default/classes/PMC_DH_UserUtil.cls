/** 
* @description Util for fetch and update user detail 
* @author Krishan
* Created On       :2023-June-26
**/
public with sharing class PMC_DH_UserUtil {
    private static final String USERINFO = 'UserInfo';
    private static final String CLASS_CONST_VARIABLE2 = '000';
    private static final String CLASS_CONST_VARIABLE3 = '001';
    
    /**
* @description returns List<User>
*
* @param strUserId String strUserId 
* @return List<User>
* @author Humera Rahath
* @date 2023-05-23
*/
    public static List<User> getUserData(String strUserId){
        List<User> lstUser ;
        if(Schema.sObjectType.User.isAccessible()){
            lstUser= [SELECT id, Name,ContactId, FirstName, LastName, Phone, Email, Country, Contact.PMC_DH_CountryCode__c,
                      Contact.LastName, Contact.Phone, Contact.Birthdate, Username from User WHERE Id =:strUserId];
        }
        return lstUser;
    }
    
    /**
* @description returns validation status code and other information
*
* @param lstUser - List of users
* @param usr - User object
* @param lstMatchingContact - List of contacts
* @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper status Code Message
* @author rravindraundale@deloitte.com
* @date 2023-05-19
*/
    public static PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper validateUserInfo(List<User> lstUser, User usr, List<Contact> lstMatchingContact){
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        if(lstMatchingContact.isEmpty()
          ){
              statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(CLASS_CONST_VARIABLE2, USERINFO);
              lstUser.add(usr);
          }else{
              statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode(CLASS_CONST_VARIABLE3, USERINFO);
          }
        return statusCodeMessage;
    }
    /**
* @description returns validation status code and other information
*
* @param lstUsers - List of users
* @param lstContact - List of Contacts
*
* @author rravindraundale@deloitte.com
* @date 2023-05-19
*/
    public static void updateUserInfo(List<User> lstUsers, List<Contact> lstContact){
        if(!lstUsers.isEmpty() && !lstcontact.isEmpty())
        {
            if(Schema.sObjectType.User.isUpdateable()){
                Database.update(lstUsers, false);
            }
            
            if(Schema.sObjectType.Contact.isUpdateable()){
                Database.update(lstContact, false);
            }
            
            
        }
    }
}