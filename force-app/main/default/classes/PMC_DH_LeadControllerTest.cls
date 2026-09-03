/**
 * @description Test class for PMC_DH_LeadManagementController
 * @author hemant giri goswami
 * @since  08-30-2023
 */
@isTest
public with sharing class PMC_DH_LeadControllerTest {
    

    @testSetup  static void setup()
    {
        
         Account acc=PMC_DH_TestDataFactoryClass.createParentTestAccount();
          Profile profile = [SELECT Id FROM Profile WHERE Name =: PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
        PMC_DH_TestDataFactoryClass.createTestUser(acc.Id,profile.Id);       
        User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Id lstPermSet1=[select id from PermissionSet where Name ='PMC_DH_SuperBuyer'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet1);
         Id lstPermSet2=[select id from PermissionSet where Name ='PMC_DH_CPQ_PermissionSetLicense'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet2);
        Id lstPermSet=[select id from PermissionSet where Name ='SteelBrickDHCPQPartnerUser'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet);
        Id lstPermSet3=[select id from PermissionSet where Name ='PMC_DH_AccountCRE'][0].id;
        PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(user.Id,lstPermSet3);
		Lead ldTestRecord=new Lead();
        
        ldTestRecord.firstName='testF';
        ldTestRecord.lastName='testLastName';
        ldTestRecord.email='test2fg@fgmail.com';
        ldTestRecord.phone='1234553';
        ldTestRecord.Country='India';
        ldTestRecord.ownerid=user.id;
        ldTestRecord.PMC_SS_ProductFamilyCategoryInterests__c='DAP-MAP;BORON';
        ldTestRecord.PMC_SS_Crops__c='Soybean;Canola;Spring Wheat;Winter Wheat';
		ldTestRecord.PMC_SS_ProductInterestVolumeEstimate__c='122';
        ldTestRecord.status='Sales Qualified';
        ldTestRecord.PMC_DH_FarmSize__c='100 hectares';
        ldTestRecord.company='company 1';
        insert ldTestRecord;
        
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(ldTestRecord.id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Converted');

        Database.convertLead(lc);
         
         
    }
    @istest
    public static void getRecordTest(){
        
    Lead ld=[Select id,ConvertedOpportunity.AccountId from lead where firstname='testF'];
    PMC_DH_LeadMgmtWrapper leadsWrapper=new PMC_DH_LeadMgmtWrapper();
    leadsWrapper=PMC_DH_LeadManagementController.getRecord(ld.ConvertedOpportunity.AccountId,'Opportunities');
    System.assertEquals(leadsWrapper!=null,true,'Success');
}
    @istest
public static void getRecordTest1(){
	
          User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
        Test.startTest();
        System.runAs(user)
            {
    Lead ldTestRecord=new Lead();
        ldTestRecord.firstName='testF';
        ldTestRecord.lastName='testLastName';
            ldTestRecord.email='test3fg@fgmail.com';
            ldTestRecord.phone='1209853';
            ldTestRecord.Country='India';
            ldTestRecord.Status ='Sales Qualified';
            ldTestRecord.OwnerId =user.id ;
            ldTestRecord.PMC_SS_ProductFamilyCategoryInterests__c='DAP-MAP;BORON';
            ldTestRecord.PMC_SS_Crops__c='Soybean;Canola;Spring Wheat;Winter Wheat';
            ldTestRecord.PMC_SS_ProductInterestVolumeEstimate__c='122';   
        ldTestRecord.PMC_DH_FarmSize__c='100 hectares';
        ldTestRecord.company='company 1';
        insert ldTestRecord;

         
    PMC_DH_LeadMgmtWrapper leadsWrapper=new PMC_DH_LeadMgmtWrapper();
    leadsWrapper=PMC_DH_LeadManagementController.getRecord('123','New');
    System.assertEquals(leadsWrapper!=null,true,'Success');
}
            Test.stopTest();
    }
    @istest
public static void rejectLeadTest(){
	
    Lead ld=[Select id from lead where firstname='testF'];
    PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
    result=PMC_DH_LeadManagementController.rejectLead(ld.id,'Opportunities');
    System.assertEquals(result!=null,true,'Success');
}
    @istest
public static void updateAcceptedLeadsTest(){
	Lead ld=[Select id,ConvertedOpportunityId from lead where firstname='testF'];
    PMC_DH_LeadMgmtWrapper.LeadInfoWrapper leadWrapper = new PMC_DH_LeadMgmtWrapper.LeadInfoWrapper();
    leadWrapper.strStage = 'Prospecting';
    leadWrapper.datContactedDate = Date.parse('12/15/23');
    leadWrapper.strContactMethod = 'Email';
    leadWrapper.strComments='testcomment';
    PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        PMC_DH_LeadManagementController.getLostOpportunityModal();
       result= PMC_DH_LeadManagementController.updateAcceptedLeads(ld.ConvertedOpportunityId,leadWrapper);
        System.assertEquals(result!=null,true,'Success');
    }
     @istest
    public static void updateAcceptedLeadsRemTest(){
        Lead ld=[Select id,ConvertedOpportunityId from lead where firstname='testF'];
        PMC_DH_LeadMgmtWrapper.LeadInfoWrapper leadWrapper = new PMC_DH_LeadMgmtWrapper.LeadInfoWrapper();
        leadWrapper.strStage = 'closed lost';
        leadWrapper.datContactedDate = Date.parse('12/15/23');
        leadWrapper.strContactMethod = 'Email';
        leadWrapper.strComments='testcomment';
        PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = new PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper();
        PMC_DH_LeadManagementController.getLostOpportunityModal();
   result= PMC_DH_LeadManagementController.updateAcceptedLeads(ld.ConvertedOpportunityId,leadWrapper);
    System.assertEquals(result!=null,true,'Success');
}
    
        @isTest
        public static void updateOpportunitytoLostTest()
        {
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result;
            Test.startTest();
            User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
            Lead ld=[Select id,ConvertedOpportunity.AccountId,ConvertedOpportunity.id from lead where firstname='testF'];    
            System.runAs(user)
            {
                result=PMC_DH_LeadManagementUtil.updateOpportunitytoLost(ld.ConvertedOpportunity.id,'Price','');
                System.assertEquals(result!=null,true,'Success');           
           }
            Test.stopTest();
            
        }
        
        @isTest
        public static void updateOppExceptionTest()
        {	String strResult;
             Test.startTest();
            User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
            System.runAs(user)
            {
                PMC_DH_DigitalHubB2BUtils.throwTestException=true;
                PMC_DH_LeadManagementUtil.updateOpportunitytoLost('idMock123','Price','');
                strResult='pass';     
           }
          System.assertEquals(strResult=='pass',true,'Success');
            Test.stopTest();
            
        }
    
        @isTest
        public static void leadConversionTest(){
            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result;
            Test.startTest();
            User user=[SELECT id FROM User WHERE UserName = 'demouser@test.com.testuser' limit 1];
            Lead ldTestRecord=new Lead();
            ldTestRecord.firstName='testF22';
            ldTestRecord.lastName='testLastName';
            ldTestRecord.email='test3fg@fgmail.com';
            ldTestRecord.phone='1209853';
            ldTestRecord.Country='India';
            ldTestRecord.Status ='Sales Qualified';
            ldTestRecord.OwnerId =user.id ;
            ldTestRecord.PMC_SS_ProductFamilyCategoryInterests__c='DAP-MAP;BORON';
            ldTestRecord.PMC_SS_Crops__c='Soybean;Canola;Spring Wheat;Winter Wheat';
            ldTestRecord.PMC_SS_ProductInterestVolumeEstimate__c='122';   
            ldTestRecord.PMC_DH_FarmSize__c='100 hectares';
            ldTestRecord.company='company 1';
            insert ldTestRecord;      
            System.runAs(user)
            {
                result=PMC_DH_LeadManagementController.leadConversion(ldTestRecord.id);
                System.assertEquals(result!=null,true,'Success');           
           }
            Test.stopTest();
        }

}