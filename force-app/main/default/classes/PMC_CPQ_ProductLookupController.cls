public with sharing class PMC_CPQ_ProductLookupController {
    
    @AuraEnabled(cacheable=true)
    public static List<Product2> findProducts(String searchKey) {
        if (String.isBlank(searchKey) || searchKey.length() < 2) {
            return new List<Product2>();
        }

        return [
            SELECT Id, PMC_CPQ_Product_Code_Name__c
            FROM Product2
            WHERE PMC_CPQ_Product_Code_Name__c LIKE :('%' + searchKey + '%')
            LIMIT 50
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Product2 getProductById(Id productId) {
        if (productId == null) {
            return null;
        }

        return [
            SELECT Id, PMC_CPQ_Product_Code_Name__c
            FROM Product2
            WHERE Id = :productId
            LIMIT 1
        ];
    }
}