public without sharing class DocumentTopicController {

    // ---------- DTOs ----------
    public class ArticleDto {
        @AuraEnabled public Id id;
        @AuraEnabled public String title;
        @AuraEnabled public String bodyHtml;   // Rich Text (images supported)
        @AuraEnabled public String ctaLabel;
        @AuraEnabled public String ctaUrl;
        @AuraEnabled public Integer orderNo;
        @AuraEnabled public String tags;
    }
    public class TopicDto {
        @AuraEnabled public Id     id;
        @AuraEnabled public String name;       // Accordion section label
        @AuraEnabled public String slug;       // e.g., org-setup-governance (optional)
        @AuraEnabled public String shortDescription;
        @AuraEnabled public Integer orderNo;
        @AuraEnabled public List<ArticleDto> articles = new List<ArticleDto>();
    }

    /**
     * OLD (kept) — Returns all active Doc_Topic__c whose Slug__c starts with sectionKey + '-',
     * along with their active Doc_Article__c in display order.
     */
    @AuraEnabled(cacheable=true)
    public static List<TopicDto> getTopicsBySection(String sectionKey) {
        if (String.isBlank(sectionKey)) return new List<TopicDto>();

        List<Doc_Topic__c> topics = [
            SELECT Id, Name, Type_of_Doc__c, Doc_Description__c, Doc_Order__c,Active__c
            FROM Doc_Topic__c
            WHERE Active__c = TRUE
            ORDER BY Doc_Order__c, Name];
        return assemble(topics);
    }

    /**
     * NEW — Returns all active Doc_Topic__c where Section__c = sectionValue (picklist),
     * with their active Doc_Article__c ordered for display.
     */
    @AuraEnabled(cacheable=true)
    public static List<TopicDto> getTopicsBySectionValue(String sectionValue) {
        if (String.isBlank(sectionValue)) return new List<TopicDto>();

        List<Doc_Topic__c> topics = [
            SELECT Id, Name, Type_of_Doc__c, Doc_Description__c, Doc_Order__c,Active__c
            FROM Doc_Topic__c
            WHERE Active__c = TRUE
              AND Type_of_Doc__c = :sectionValue
            ORDER BY Doc_Order__c, Name];
        return assemble(topics);
    }

    // ---------- Private assembler ----------
    private static List<TopicDto> assemble(List<Doc_Topic__c> topics) {
        if (topics.isEmpty()) return new List<TopicDto>();

        Map<Id, TopicDto> topicMap = new Map<Id, TopicDto>();
        for (Doc_Topic__c t : topics) {
            TopicDto dto = new TopicDto();
            dto.id = t.Id;
            dto.name = t.Name;
            dto.shortDescription = t.Doc_Description__c;
            dto.orderNo = (Integer)t.Doc_Order__c;
            topicMap.put(t.Id, dto);
        }

        for (Doc_Article__c a : [
            SELECT Id, Doc_Topic__c, Doc_Article_Body__c, Doc_Article_order__c, Active__c
            FROM Doc_Article__c
            WHERE Active__c = TRUE
              AND Doc_Topic__c IN :topicMap.keySet()
            ORDER BY Doc_Topic__c, Doc_Article_order__c
        ]) {
            TopicDto t = topicMap.get(a.Doc_Topic__c);
            if (t == null) continue;

            ArticleDto ad = new ArticleDto();
            ad.id       = a.Id;
            ad.bodyHtml = a.Doc_Article_Body__c;
            ad.orderNo  = (Integer)a.Doc_Article_order__c;
            t.articles.add(ad);
        }

        List<TopicDto> outList = new List<TopicDto>();
        for (Doc_Topic__c t : topics) outList.add(topicMap.get(t.Id));
        return outList;
    }
}