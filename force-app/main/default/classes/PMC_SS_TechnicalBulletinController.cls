/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-12-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class PMC_SS_TechnicalBulletinController {
    /**
     * @description - Method used to fetch the knowledge articles
     * @return lstWrapper - Returns Wrapper of type Knowledge Articles
     */
    @AuraEnabled(cacheable=true)
    public static List<KnowledgeArticleWrapper> getAllKnowledgeArticles(){
        String staticImageURL = URL.getSalesforceBaseUrl().toExternalForm() + PageReference.forResource(PMC_SS_ConstantClass.TECHBULLETIN_DEFAULTNEWS).getUrl();
        try {
            String loggedinUserRegion=PMC_SS_ConstantClass.NA_REGION;
            String userLanguage = UserInfo.getLanguage();
            if(userLanguage==PMC_SS_ConstantClass.USERLANGUAGE_PT){loggedinUserRegion=PMC_SS_ConstantClass.BR_REGION;}
            List<KnowledgeArticleWrapper> lstKAWrapper = new List<KnowledgeArticleWrapper>();
            Map<Id,KnowledgeArticleWrapper> mapKAWrapper = new Map<Id,KnowledgeArticleWrapper>();
            Map<Id, Knowledge__kav> mapIdKnowledges = new Map<Id, Knowledge__kav> ([SELECT Id, ArticleNumber, Answer__c, CreatedById, 
                    PublishStatus, Question__c, Summary, Title, UrlName, CreatedDate, PMC_SS_EndDate__c,RecordType.DeveloperName
                    FROM Knowledge__kav
                    WHERE PMC_SS_Region__c=:loggedinUserRegion AND PMC_SS_EndDate__c >= TODAY AND PublishStatus =:PMC_SS_ConstantClass.ONLINE_STATUS And RecordType.DeveloperName =:PMC_SS_ConstantClass.TECHBULLETIN_RECORDTYPE
                    ORDER by PMC_SS_EndDate__c ASC]);
            if(mapIdKnowledges.size()>0){
                mapKAWrapper=getContentDocumentLinks(mapIdKnowledges);
                for(Id mapId: mapIdKnowledges.keySet()){
                    if(mapKAWrapper.keySet().contains(mapId)){
                        lstKAWrapper.add(mapKAWrapper.get(mapId));
                    }else{
                        lstKAWrapper.add(createKnowledgeWrapper(mapIdKnowledges.get(mapId),staticImageURL));
                    }
                }
            }
            return lstKAWrapper;
        } 
        catch (Exception e) { throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * @description - Method used to fetch contentDocument Links for knowledge articles
     * @return mapOfKAWrapper - Returns map of type Knowledge Articles Wrapper
     * @param mapOfIdKnowledges - map of knowledge Id's
     */
    @AuraEnabled(cacheable=true)
    public static Map<Id,KnowledgeArticleWrapper> getContentDocumentLinks(Map<Id, Knowledge__kav> mapOfIdKnowledges){
            Set<Id> newKeySet = mapOfIdKnowledges.keySet();
            try{
                List<String> lstImageTypes = PMC_SS_ConstantClass.LSTIMAGETYPES;
                Map<Id,KnowledgeArticleWrapper> mapOfKAWrapper = new Map<Id,KnowledgeArticleWrapper>();
                List<ContentDocumentLink> lstContentDocLinks = [SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.FileType, 
                                                                                                    ContentDocument.LatestPublishedVersionId, 
                                                                                                    ContentDocument.LatestPublishedVersion.Title
                                                                                                    FROM ContentDocumentLink 
                                                                                                    WHERE LinkedEntityId IN: newKeySet
                                                                                                    WITH SECURITY_ENFORCED ];

                for(ContentDocumentLink objContentDocLink : lstContentDocLinks) {
                    if(mapOfIdKnowledges.get(objContentDocLink.LinkedEntityId) != null) {
                        if(lstImageTypes.contains(objContentDocLink.ContentDocument.FileType)){
                            mapOfKAWrapper.put(objContentDocLink.LinkedEntityId,
                                              createKnowledgeWrapper(mapOfIdKnowledges.get(objContentDocLink.LinkedEntityId),PMC_SS_ConstantClass.STATIC_URL + objContentDocLink.ContentDocument.LatestPublishedVersionId));
                        }
                    }

                }
                return mapOfKAWrapper;
            }catch (Exception e) { throw new AuraHandledException(e.getMessage());
            }
            
    }
    /**
     * @description - Create Knowledge Wrapper object to display
     * @return objKnowledgeWrapper - Returns map of type Knowledge Articles Wrapper
     * @param objKnowledge - map of knowledge Id's
     * @param strImageURL - Image URL to display
     */
    private static KnowledgeArticleWrapper createKnowledgeWrapper(Knowledge__kav objKnowledge,String strImageURL){

        KnowledgeArticleWrapper objKnowledgeWrapper = new KnowledgeArticleWrapper();
        objKnowledgeWrapper.title = objKnowledge.Title;
        objKnowledgeWrapper.description =objKnowledge.Summary;
        objKnowledgeWrapper.endDate = objKnowledge.PMC_SS_EndDate__c;
        objKnowledgeWrapper.publishStatus = objKnowledge.PublishStatus;
        objKnowledgeWrapper.createdById = objKnowledge.CreatedById;
        objKnowledgeWrapper.imageUrl = strImageURL;
        return objKnowledgeWrapper;
    } 
    
    /**
     * @description - Generic Wrapper class to hold the knowledge object record 
     */
    public class KnowledgeArticleWrapper {
        /**
         * @description - holds the article title
         */
        @AuraEnabled
        public String title {get;set;}
         /**
         * @description - holds the article description
         */
        @AuraEnabled
        public String description {get;set;}
         /**
         * @description - holds the article image URL
         */
        @AuraEnabled
        public String imageUrl {get;set;}
         /**
         * @description - holds the article end date
         */
        @AuraEnabled
        public Date endDate {get;set;}
         /**
         * @description - holds the article pusblished status
         */
        @AuraEnabled
        public String publishStatus {get;set;}
         /**
         * @description - holds the created date of artile 
         */
        @AuraEnabled
        public String createdById {get;set;}
    }
}