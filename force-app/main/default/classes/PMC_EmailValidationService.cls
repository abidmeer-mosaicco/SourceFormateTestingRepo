public with sharing class PMC_EmailValidationService {
    private static final Pattern EMAIL_PATTERN = Pattern.compile(
        '(?i)^[\\w.%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
    );

    /** retorna true se não for blank e casar com o regex */
    public static Boolean isValid(String email) {
        return email != null && EMAIL_PATTERN.matcher(email).matches();
    }
}