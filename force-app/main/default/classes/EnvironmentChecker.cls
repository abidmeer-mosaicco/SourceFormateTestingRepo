public class EnvironmentChecker {
    
    public static Boolean isSandbox() {
        // Get the base URL of the current instance
        String orgUrl = Url.getOrgDomainUrl().toExternalForm();
        
        // Check if the URL contains sandbox-specific patterns
        return orgUrl.contains('sandbox') || orgUrl.contains('cs') || orgUrl.contains('.sb1.');
    }

    public static Boolean checkSandbox(String alias){
        return Url.getOrgDomainUrl().toExternalForm().contains('--' + alias);
    }

    /**
     * Returns the value associated with the current sandbox alias from the provided map.
     * If the current environment is not a sandbox or the alias is not found, returns the default value.
     *
     * @param sandboxValues Map of sandbox aliases to their corresponding values.
     * @param defaultValue The default value to return if no matching sandbox alias is found.
     * @return The value associated with the current sandbox alias, or the default value.
     */
    public static String getValueBySandboxAlias(String defaultValue, Map<String, String> sandboxValues) {
        if (!isSandbox() && !Test.isRunningTest()) {
            // If it's not a sandbox, return the default value
            return defaultValue;
        }

        // Iterate through the map to find the matching sandbox alias
        for (String alias : sandboxValues.keySet()) {
            if (checkSandbox(alias)) {
                return sandboxValues.get(alias); // Return the value for the matching alias
            }
        }

        // If no matching alias is found, return the default value
        return defaultValue;
    }
}