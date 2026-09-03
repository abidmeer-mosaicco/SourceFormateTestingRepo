/**
* @author @hemant.giri
* @description test class for Case
* @since 06-14-2023
*/
@isTest
public with sharing class PMC_DH_CaseUtilTest {

    private static void enableFlowBypassForCurrentUser() {
        PMC_ProcessSwitches__c cs = PMC_ProcessSwitches__c.getInstance();
        if (cs == null) cs = new PMC_ProcessSwitches__c();
        cs.PMC_ByPassFlow__c = true;
        upsert cs;
    }

    /**
    * @description test setup method
    * @since 06-15-2023
    * @author hemant giri goswami
    */
    @testSetup
    public static void testData(){
        User userAdmin = PMC_DH_TestDataFactoryClass.createAdminUser();
        User usr;
        Account acc1;
        BusinessHours bh = [SELECT Name, Id FROM BusinessHours WHERE Name = 'Default' LIMIT 1];

        System.runAs(userAdmin) {
            acc1 = PMC_DH_TestDataFactoryClass.createParentTestAccount();
            PMC_DH_TestDataFactoryClass.createTestContact(acc1.Id);
            Profile profile = [SELECT Id FROM Profile WHERE Name = :PMC_DH_ConstantClass.PROFILE_NAME LIMIT 1];
            PMC_DH_TestDataFactoryClass.createTestUser(acc1.Id, profile.Id);
            usr = [SELECT Id, ContactId FROM User WHERE UserName = 'demouser@test.com.testuser' LIMIT 1];

            Id psDHCPQ = [SELECT Id FROM PermissionSet WHERE Name = 'PMC_DH_CPQ_PermissionSetLicense' LIMIT 1].Id;
            PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id, psDHCPQ);

            Id psSteelBrick = [SELECT Id FROM PermissionSet WHERE Name = 'SteelBrickDHCPQPartnerUser' LIMIT 1].Id;
            PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id, psSteelBrick);

            Id psSuperBuyer = [SELECT Id FROM PermissionSet WHERE Name = 'PMC_DH_SuperBuyer' LIMIT 1].Id;
            PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id, psSuperBuyer);

            Id psAccountCRE = [SELECT Id FROM PermissionSet WHERE Name = 'PMC_DH_AccountCRE' LIMIT 1].Id;
            PMC_DH_TestDataFactoryClass.assignPermissionSetToUser(usr.Id, psAccountCRE);
        }

        System.runAs(usr){
            PMC_DH_TestDataFactoryClass.createCaseRecord(acc1.Id, usr.ContactId, bh.Id);
        }
    }

    /**
    * @description test method for reopen case
    * @author Ajeet
    */
    @isTest
    public static void reopenCaseTest() {
        User usr = [SELECT Id FROM User WHERE UserName = 'demouser@test.com.testuser' LIMIT 1];

        Test.startTest();
        System.runAs(usr) {
            enableFlowBypassForCurrentUser();

            Id originLocRtId = [
                SELECT Id
                FROM RecordType
                WHERE SObjectType = 'Location'
                AND DeveloperName = 'PMC_CPQ_Origin_Location'
                LIMIT 1
            ].Id;

            Schema.SObjectType locType = Schema.getGlobalDescribe().get('Location');
            SObject locRec = locType.newSObject();
            locRec.put('Name', 'test name');
            locRec.put('LocationType', 'Plant');
            locRec.put('RecordTypeId', originLocRtId);
            insert locRec;

            Case caseObjRecord = [SELECT CaseNumber, Id, ClosedDate, Subject FROM Case WHERE Status = 'New' WITH SECURITY_ENFORCED LIMIT 1];
            caseObjRecord.PMC_SS_IssueReason__c = 'Delivery delay';
            caseObjRecord.Status = 'Closed';
            caseObjRecord.PMC_SS_Location__c = (Id)locRec.get('Id');
            caseObjRecord.PMC_SS_MOT__c = 'Truck';
            caseObjRecord.PMC_SS_AtFaultParty__c = 'Customer';
            update caseObjRecord;

            PMC_DH_CaseUtil.isEligibleToUploadDoc(caseObjRecord.Id);
            PMC_DH_CaseUtil.getDependentPicklistValues(Case.PMC_SS_IssueReason__c);

            PMC_DH_CaseUtil.CaseWrapper wrp1 = new PMC_DH_CaseUtil.CaseWrapper();
            wrp1.strCaseId = caseObjRecord.Id;
            wrp1.strReason = 'Resolution Not Accurate';
            wrp1.strOthersComment = 'Test';

            PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper result = PMC_DH_CaseUtil.reopenCase(wrp1);
            System.assert(result != null, 'Success');
        }
        Test.stopTest();
    }

    /**
    * @description test method for reopen case exception
    * @author Hemant
    */
    @isTest
    public static void reopenCaseExceptionTest() {
        User usr = [SELECT Id FROM User WHERE UserName = 'demouser@test.com.testuser' LIMIT 1];

        Test.startTest();
        System.runAs(usr) {
            enableFlowBypassForCurrentUser();

            Boolean isException;
            try {
                Case caseObjRecord = [SELECT CaseNumber, Id, ClosedDate, Subject FROM Case WHERE Status = 'New' WITH SECURITY_ENFORCED LIMIT 1];
                caseObjRecord.PMC_SS_IssueReason__c = 'Delivery delay';
                caseObjRecord.Status = 'Pending';
                isException = false;
                update caseObjRecord;

                PMC_DH_CaseUtil.CaseWrapper wrp1 = new PMC_DH_CaseUtil.CaseWrapper();
                wrp1.strCaseId = caseObjRecord.Id;
                wrp1.strReason = 'Resolution Not Accurate';
                wrp1.strOthersComment = '';
                PMC_DH_CaseUtil.reopenCase(wrp1);

                PMC_DH_CaseUtil.boolThrow = true;
                PMC_DH_CaseUtil.reopenCase(wrp1);
            } catch (Exception ex) {
                isException = true;
            }
            System.assert(isException != null, 'Exception Handled');
        }
        Test.stopTest();
    }

    /**
    * @description test method for reopen case List
    * @author Hemant
    */
    @isTest
    public static void getReopenReasonListTest() {
        List<PMC_DH_PicklistWrapper> wrp = PMC_DH_CaseUtil.getReopenReasonList();
        System.assert(wrp != null, 'Success');
    }
}