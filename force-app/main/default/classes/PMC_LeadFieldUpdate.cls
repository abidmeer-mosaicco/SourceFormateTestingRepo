/**
* @description This class will be used to Update the event details from salesforce scheduler on the lead object.
* @author Monika Watts
*/
public class PMC_LeadFieldUpdate implements Database.Batchable <SObject> {

set<Id> leadId=new set<Id>();
List<Lead> leadList=new List<Lead>();
List<Lead> leadtoUpdate=new List<Lead>();
set<ID> evtToReturnIds=new Set<ID>();
Map<ID,List<Event>> mapofEvents = new Map<ID,List<Event>>();
    
 /** @description Start method of the class which is used to get all the events created in last 15 days with description as Mosaic Expert.
     @param bc
     @return Event[]
 */

    public Database.QueryLocator start(Database.BatchableContext bc){
       List<Event> evtList=[Select id,whoId,Who.Type,StartDateTime,CreatedDate,Subject,Description from event where who.Type='Lead' and CreatedDate=LAST_N_DAYS:15 and subject like 'Connect with Mosaic%'];
        if(evtList.size()>0)
        {
            for(Event e:evtList)
            {
                if(e.Description.contains(System.label.PMC_Event_Description))
                {
                    evtToReturnIds.add(e.id);
                }
            }
        }
      
            return Database.getQueryLocator([Select id,whoId,Who.Type,StartDateTime,CreatedDate,Subject,Description from event where id in:evtToReturnIds]); // who.Type='Lead' and CreatedDate=LAST_N_DAYS:15 and subject like 'Connect with Mosaic%']); //whoId='00QDT000009q5492AA']); // and CreatedDate=LAST_N_DAYS:15]);
            }

    /** @description execute method of the class which is used to populate the values from event fields to lead fields object
        @param bc
        @param scope
    */
    
    public void execute(Database.BatchableContext bc, List<Event> scope){
        for(Event e: scope){
           leadId.add(e.whoId);
         }
        
        if(leadId.size()>0)
           {
               leadList=[select id, Email,firstname,(select StartDateTime,Description,Subject from Events order by StartDateTime desc limit 1),PMC_Event_Name__c,PMC_scheduled__c,PMC_Scheduled_DateTime__c from Lead where Id in:leadId]; //and scheduled__c=:False];
               for(Lead le:leadList) 
               {
                  for(Event evtt:le.Events)
                 //  Event evtt=[select id,StartDateTime,Subject,Description from Event where whoId=:le.Id order by StartDateTime desc limit 1]  ;      
                  {
                    le.PMC_scheduled__c=true;
                    le.PMC_Scheduled_DateTime__c= evtt.StartDateTime;
                    le.PMC_Event_Name__c=evtt.Subject;
                     leadtoUpdate.add(le);
              } 
               }
            if(leadtoUpdate.size()>0)
            {
              update leadtoUpdate;
            }
        }
    }
/** @description finish method of the class
    @param bc 
*/
    
   
     public void finish(Database.BatchableContext bc){
         if(!Test.isRunningTest()) {
       System.scheduleBatch(new PMC_LeadFieldUpdate(),'PMC_Lead_Update_Scheduler',Integer.valueOf(System.label.PMC_LeadUpdateInterval),200); 
       
    
    }
    }
}