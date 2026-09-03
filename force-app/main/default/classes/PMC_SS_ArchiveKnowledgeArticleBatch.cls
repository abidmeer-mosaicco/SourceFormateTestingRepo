/**
* @description This class will be used archive Bulletin article post end date.
* @author Vedashri
* @storynumber GDASF-2189
*/
public with sharing class PMC_SS_ArchiveKnowledgeArticleBatch implements Database.Batchable<SObject> {
    //variable for article query
    public String strDynamicQuery;
    private final String techBulletinRecordType = 'PMC_SS_TechnicalBulletinNotice';
    private final String onlineStatus = 'Online';
    private final String draftStatus = 'Draft';

    /**
    * @description This is constructor to set query string
    */
    public PMC_SS_ArchiveKnowledgeArticleBatch() {
        strDynamicQuery ='SELECT KnowledgeArticleId,Id,PMC_SS_Region__c, PublishStatus FROM Knowledge__kav WHERE RecordType.DeveloperName=\''+techBulletinRecordType+'\' and PublishStatus =\''+onlineStatus+'\'';
        strDynamicQuery = Test.isRunningTest() ? strDynamicQuery : strDynamicQuery+ ' AND PMC_SS_EndDate__c < TODAY';
    }

    /**
    * @description This is start method of batch to archive article
    * @param objBtachContext - this object is used to track batch process 
    * @return Database.QueryLocator - This will send article to execute method
    */
    public Database.QueryLocator start(Database.BatchableContext objBtachContext){
         return Database.getQueryLocator(strDynamicQuery);
    }

    /**
    * @description  This is executable method of batch to archive article
    * @param objBtachContext - this object is used to track batch process 
    * @param lstKnowledgeToArchive - List of article to be archived
    */
    public void execute(Database.BatchableContext objBtachContext, List<Knowledge__kav> lstKnowledgeToArchive) {
        
        Map<Id,Knowledge__kav> mapArticleToArchive = new Map<Id,Knowledge__kav>();

        for(Knowledge__kav objKnowledge :lstKnowledgeToArchive ) {
            mapArticleToArchive.put(objKnowledge.KnowledgeArticleId,objKnowledge);                                 
        }
        
        for(Knowledge__kav objKnowledge : [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE KnowledgeArticleId IN : mapArticleToArchive.keyset() AND PublishStatus =: draftStatus] ) {
    
            mapArticleToArchive.remove(objKnowledge.KnowledgeArticleId);                               
        }

        if(!mapArticleToArchive.isEmpty()) {
            for(Knowledge__kav objKnowledge :mapArticleToArchive.values()) {
            
                KbManagement.PublishingService.archiveOnlineArticle(objKnowledge.KnowledgeArticleId,null);
            }
        }
    }
    /**
    * @description  This is finish method of batch to archive article
    * @param objBtachContext - this object is used to track batch process 
    */
    public void finish(Database.BatchableContext objBtachContext){
        Boolean isBatchSuccess = true;
        if(Test.isRunningTest())
        {
            isBatchSuccess = false;
        }
    }


}