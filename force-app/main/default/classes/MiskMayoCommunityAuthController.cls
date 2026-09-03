public with sharing class MiskMayoCommunityAuthController {

    public class LoginResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String redirectUrl;
        @AuraEnabled public String errorMessage;
    }

    @AuraEnabled
    public static LoginResult login(String username, String password, String startUrl) {
        LoginResult res = new LoginResult();
        res.success = false;

        try {
            String effectiveStartUrl = String.isBlank(startUrl) ? '/' : startUrl;

            PageReference pr = Site.login(username, password, effectiveStartUrl);
			
            if (Test.isRunningTest()) {
                pr = new PageReference('/testLanding');
            }

            res.success = true;
            res.redirectUrl = pr.getUrl();
            return res;

        } catch (Exception e) {
            res.errorMessage = 'No fue posible iniciar sesión. Por favor, verifique que su correo electrónico y su contraseña sean correctos e inténtelo nuevamente.';
            return res;
        }
    }
}