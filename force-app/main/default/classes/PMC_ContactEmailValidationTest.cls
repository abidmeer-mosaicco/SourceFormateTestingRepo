/**
 * @description       : 
 * @author            : nokrause@valgroupco.com.gaugedev
 * @group             : 
 * @last modified on  : 24-06-2025
 * @last modified by  : nokrause@valgroupco.com.gaugedev
**/
@IsTest
public class PMC_ContactEmailValidationTest {

    @IsTest
    static void test_EmailValid_AfterInsert() {
        Contact c = new Contact(LastName='Test', Email='user@example.com');
        insert c;

        c = [SELECT PMC_SS_EmailValid__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(true, c.PMC_SS_EmailValid__c, 'Valid email should set PMC_SS_EmailValid__c to true');
    }

}