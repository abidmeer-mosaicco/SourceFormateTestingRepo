/**
* @description This class will be used to handle all the recursion issues in the contact record.
* @author Prashanth Kamma - 08/05/2025
*/

  public class PMC_SS_TriggerRecursionGuard {
    private static Map<String, Boolean> flags = new Map<String, Boolean>();

    public static Boolean isAlreadyProcessed(String key) {
        return flags.containsKey(key) && flags.get(key);
    }

    public static void markProcessed(String key) {
        flags.put(key, true);
    }

    public static void reset() {
        flags.clear();
    }
}