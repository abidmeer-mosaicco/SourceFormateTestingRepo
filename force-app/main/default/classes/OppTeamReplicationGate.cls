public with sharing class OppTeamReplicationGate {


    private static final Boolean ENABLE_QUOTE_MANUAL_SHARING   = true;
    private static final Boolean ENABLE_ACCOUNT_MANUAL_SHARING = true;

    public static Boolean isQuoteManualSharingEnabled() {
        return ENABLE_QUOTE_MANUAL_SHARING;
    }

    public static Boolean isAccountManualSharingEnabled() {
        return ENABLE_ACCOUNT_MANUAL_SHARING;
    }


    public static Boolean canReplicate() {
        return hasModifyAllData(UserInfo.getUserId())
            || hasPermissionSet(UserInfo.getUserId(), 'Access_to_update_team_members');
    }

    @AuraEnabled(cacheable=true)
    public static Boolean canReplicateForUser(Id userId) {
        if (userId == null) {
            return false;
        }

        return hasModifyAllData(userId)
            || hasPermissionSet(userId, 'Access_to_update_team_members');
    }

private static Boolean hasModifyAllData(Id userId) {
    List<User> users = [
        SELECT Profile.PermissionsModifyAllData
        FROM User
        WHERE Id = :userId
        LIMIT 1
    ];
    return !users.isEmpty() && users[0].Profile.PermissionsModifyAllData;
}


    private static Boolean hasPermissionSet(Id userId, String permissionSetName) {
        return ![
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
              AND PermissionSet.Name = :permissionSetName
            LIMIT 1
        ].isEmpty();
    }


    public static String normalizeAccess(String val) {
        if (String.isBlank(val)) return 'Read';
        String s = val.trim().toLowerCase();
        return (s.contains('edit') || s.contains('write')) ? 'Edit' : 'Read';
    }


   
@AuraEnabled(cacheable=true)
public static Boolean canCurrentUserReplicate() {
    Id currentUserId = UserInfo.getUserId();

    return hasModifyAllData(currentUserId)
        || hasPermissionSet(currentUserId, 'Access_to_update_team_members');
}


}