public without sharing class UserLookupController {
    @AuraEnabled(cacheable=true)
    public static List<User> searchUsers(String searchKey) {
        if (String.isBlank(searchKey)) return new List<User>();
        String escapedSearchKey = String.escapeSingleQuotes(searchKey);
        String query = 'SELECT Id, Name, Email FROM User WHERE IsActive = TRUE AND Name LIKE \'%' + escapedSearchKey + '%\' ORDER BY Name LIMIT 10';
        return Database.query(query);
    }
}