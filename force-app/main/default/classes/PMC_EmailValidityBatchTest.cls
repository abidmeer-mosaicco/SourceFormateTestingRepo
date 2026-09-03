/**
 * @description       : 
 * @author            : nokrause@valgroupco.com.gaugedev
 * @group             : 
 * @last modified on  : 25-06-2025
 * @last modified by  : nokrause@valgroupco.com.gaugedev
**/
@IsTest
public class PMC_EmailValidityBatchTest {
    @TestSetup
    static void setupData() {
        // Leads
        Lead l1 = new Lead(LastName='Lead One', Company='CompA', Email='valid@lead.com');
        Lead l2 = new Lead(LastName='Lead Two', Company='CompB', Email='vali2d@lead.com');
        insert new List<Lead>{l1, l2};

        // Contacts
        Account acc = new Account(Name='Test Account');
        insert acc;
        Contact c1 = new Contact(LastName='Contact One', AccountId=acc.Id, Email='user@contact.com');
        Contact c2 = new Contact(LastName='Contact Two', AccountId=acc.Id, Email='user2@contact.com');
        insert new List<Contact>{c1, c2};
    }

    @IsTest
    static void testBatchForLeadAndContact() {
        // Run batch for Lead
        Test.startTest();
        Database.executeBatch(new PMC_EmailValidityBatch('Lead'), 200);
        Test.stopTest();

        // Check Leads
        List<Lead> leads = [SELECT Email, PMC_SS_EmailValid__c FROM Lead];
        for (Lead l : leads) {
            if (l.Email == 'valid@lead.com') {
                System.assertEquals(true, l.PMC_SS_EmailValid__c, 'Valid Lead email should be true');
            } else if (l.Email == 'not-an-email') {
                System.assertEquals(false, l.PMC_SS_EmailValid__c, 'Invalid Lead email should be false');
            }
        }

        // Check Contacts
        List<Contact> contacts = [SELECT Email, PMC_SS_EmailValid__c FROM Contact];
        for (Contact c : contacts) {
            if (c.Email == 'user@contact.com') {
                System.assertEquals(true, c.PMC_SS_EmailValid__c, 'Valid Contact email should be true');
            } else if (c.Email == 'invalidemail') {
                System.assertEquals(false, c.PMC_SS_EmailValid__c, 'Invalid Contact email should be false');
            }
        }
    }
}