public without sharing class MiskiMayoAliasGenerator {
    // Allows deterministic collision testing
    @TestVisible private static String forcedCandidateOnce;

    @InvocableMethod(label='Generate Unique Alias' description='Generates a unique 8-character string (A-Z, a-z, 0-9) checked against User.CommunityNickname.')
    public static List<String> generate() {
        String aliasValue = generateUniqueCommunityNicknameChecked(8);
        return new List<String>{ aliasValue };
    }

    private static String generateUniqueCommunityNicknameChecked(Integer length) {
        if (length == null || length <= 0) {
            length = 8;
        }

        Integer attempts = 0;
        while (attempts < 50) {
            attempts++;

            String candidate;
            if (Test.isRunningTest() && forcedCandidateOnce != null) {
                candidate = forcedCandidateOnce;
                forcedCandidateOnce = null; // only force once
            } else {
                candidate = randomAlphaNumMixed(length);
            }

            List<User> existing = [
                SELECT Id
                FROM User
                WHERE CommunityNickname = :candidate
                LIMIT 1
            ];
            if (existing.isEmpty()) {
                return candidate;
            }
        }

        throw new AuraHandledException('Unable to generate a unique value after multiple attempts.');
    }

    private static String randomAlphaNumMixed(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        String out = '';
        for (Integer i = 0; i < len; i++) {
            Integer idx = Math.mod(Crypto.getRandomInteger(), chars.length());
            if (idx < 0) idx = -idx;
            out += chars.substring(idx, idx + 1);
        }
        return out;
    }
}