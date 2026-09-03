public without sharing class MiskiMayoNickNameGenerator {
    // Allows deterministic collision testing
    @TestVisible private static String forcedCandidateOnce;

    @InvocableMethod(label='Generate Unique Community Nickname' description='Generates a unique 40-character CommunityNickname (A-Z, a-z, 0-9).')
    public static List<String> generate() {
        String nickname = generateUniqueCommunityNickname(40);
        return new List<String>{ nickname };
    }

    private static String generateUniqueCommunityNickname(Integer length) {
        if (length == null || length <= 0) {
            length = 40;
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

            // Ensure not already used as CommunityNickname
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

        // Extremely unlikely, but fail loudly to avoid infinite loops
        throw new AuraHandledException('Unable to generate a unique CommunityNickname after multiple attempts.');
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