@isTest
public class PMC_LeadFieldUpdateTest {
   
    @isTest
   static void testMethod1(){
       
       
       Event e=new Event();
       //e.WhoId='00QDT000009q2bx2AA';
       e.StartDateTime=Date.newInstance(2023, 12, 9);
       e.Subject='Connect with Mosaic Meeting Schdeuled';
       e.DurationInMinutes=30;
       e.Type='Lead';
     
       e.Description=System.label.PMC_Event_Description;
       insert e;
       System.assertEquals('Mosaic Expert',e.Description,'Description is Mosaic Expert');
       
       Lead l=new Lead();
        l.FirstName='TestLead';
        l.LastName='data';
        l.Company='HCL';
        l.leadsource='Web';
        l.PMC_scheduled__c=False;
        l.PMC_Scheduled_DateTime__c=e.StartDateTime;
        l.Id=e.WhoId;
        l.PMC_Event_Name__c=e.Subject;
        insert l;
       
       
       e.WhoId=l.id;
       update e;
       
       Test.startTest();
        PMC_LeadFieldUpdate ba= new PMC_LeadFieldUpdate();
        Id jobid= Database.executeBatch(ba,1);
      
        Test.stopTest();
   }
}