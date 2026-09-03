/**
* @description This class will be used call PMC_ArchiveKnowledgeArticleBatch archive Bulletin article post end date.
* @author Vedashri
* @storynumber GDASF-2189
*/
public without sharing class PMC_SS_ArchiveKnowledgeArticleSchedule implements Schedulable {
    /**
    * @description  This is executable method of Scheduler to archive article.
    * @param objScheduleContext - this object is used to track batch process 
    */
    public void execute(SchedulableContext objScheduleContext) {
       PMC_SS_ArchiveKnowledgeArticleBatch objBatch = new PMC_SS_ArchiveKnowledgeArticleBatch(); 
       Database.executeBatch(objBatch,50);
    }
 }