@isTest(seeAllData = false)
public with sharing class PMC_SS_CustomLookupFieldControllerTest {

     /**
    * @description This Method will be used to setup the test data for the test class execution.
    */
    
    @testsetup
    private static void setup() {
        
        List<String>lstProfileNames = New List<String>{'System Administrator','Service User'};
        List<String>lstPermissionNames = New List<String>{'PMC_Administrator_Permission_Set_Group','PMC_SRV_Permission_Set_Group'};
        Map<String,Id>mapOfProfiles = PMC_TestUtilityClass.getProfiles(lstProfileNames);
        Map<String,PermissionSetGroup>mapOfPermissionGrp = PMC_TestUtilityClass.getPemissionsetGroups(lstPermissionNames);
        Integer intuserCount =0;
        User objSystemAdminUser;  
        User objServiceUser;
        List<User> lstUser = PMC_TestUtilityClass.createUser(2);
            for(User objUser : lstUser) {
                If(intuserCount==0){
                   objUser.LastName = 'Admin User Test';
                   objUser.ProfileId = mapOfProfiles.get('System Administrator'); 
                   objUser.FederationIdentifier = objUser.Username + 'Admin';
                }else if(intuserCount==1){
                    objUser.LastName = 'Service User Test';
                    objUser.ProfileId = mapOfProfiles.get('Service User'); 
                   objUser.FederationIdentifier = objUser.Username + 'Service';
                }
                objUser.isActive = true;                
                objUser.MobilePhone = '1234567890';
                objUser.UserPermissionsKnowledgeUser =true;
                objUser.LanguageLocaleKey = 'en_US';
                intuserCount = intuserCount + 1;
            }            
            insert lstUser;
            objSystemAdminUser = lstUser[0];
            objServiceUser = lstUser[1];
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objSystemAdminUser}, mapOfPermissionGrp.get('PMC_Administrator_Permission_Set_Group'));
        PMC_TestUtilityClass.assignPermissionSetGroupToUsers(new List<User>{objServiceUser}, mapOfPermissionGrp.get('PMC_SRV_Permission_Set_Group'));
            Account objAccount;
            System.runAs(objServiceUser){    
            objAccount = PMC_TestUtilityClass.createAccount('Deloitte 1','PMC_SS_Customer');
            }
        System.runAs(objSystemAdminUser){ 
                PMC_TestUtilityClass.createOrders(1, new List<Account>{objAccount});
            }    
        }
    
    
    @isTest
    public static void testSearchOrder() {
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User Where LastName='Service User Test' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(objUser) {
        Order objOrder = [SELECT Id, OrderNumber, AccountId FROM Order WITH SECURITY_ENFORCED LIMIT 1];
        if(objOrder != null) {
                List<SObject> lstSobjects = new List<SObject>();
                lstSobjects = PMC_SS_CustomLookupFieldController.searchOrder(objOrder.OrderNumber, 'Order', objOrder.AccountId);
                lstSobjects = PMC_SS_CustomLookupFieldController.searchOrder('', 'Order', '');
                lstSobjects = PMC_SS_CustomLookupFieldController.searchOrder(objOrder.OrderNumber, 'Order', '');
                System.assertEquals(1, lstSobjects.size(), 'Retrieved Order Successfully');
        }
        }
        Test.stopTest();
    }
}