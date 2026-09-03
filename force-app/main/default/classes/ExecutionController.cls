public class ExecutionController {
	private static Map<String, Integer> executionMap = new Map<String, Integer>();

	public static Boolean executeOnce(String key) {
		if (!executionMap.containsKey(key) || executionMap.get(key) == 0) {
			executionMap.put(key, 1);
			return true;
		}
		return false;
	}

	public static void start(String key) {
		Integer count = executionMap.containsKey(key) ? executionMap.get(key) : 0;
		executionMap.put(key, count + 1);
	}

	public static void start(String key, Set<Id> ids) {
		for (Id recordId : ids) {
			start(key + '_' + String.valueOf(recordId));
		}
	}

	public static void stop(String key) {
		Integer count = executionMap.containsKey(key) ? executionMap.get(key) : 0;
		executionMap.put(key, Math.max(0, count - 1));
	}

	public static void stop(String key, Set<Id> ids) {
		for (Id recordId : ids) {
			stop(key + '_' + String.valueOf(recordId));
		}
	}

	public static void reset(String key) {
		executionMap.remove(key);
	}

	public static void reset(String key, Set<Id> ids) {
		for (Id recordId : ids) {
			reset(key + '_' + String.valueOf(recordId));
		}
	}

	public static Integer getExecutionCount(String key) {
		return executionMap.containsKey(key) ? executionMap.get(key) : 0;
	}

	public static Boolean canExecute(String key) {
		return getExecutionCount(key) == 0;
	}

	public static Boolean hasExecuted(String key) {
		return getExecutionCount(key) > 0;
	}

	public static Set<String> getKeys() {
		return new Set<String>(executionMap.keySet());
	}

	public static Map<String, Integer> logStatus() {
		return new Map<String, Integer>(executionMap);
	}

	public static Set<Id> bulkExecuteOnce(String keyPrefix, Set<Id> ids) {
		Set<Id> toExecute = new Set<Id>();
		for (Id id : ids) {
			String fullKey = keyPrefix + '_' + String.valueOf(id);
			if (executeOnce(fullKey)) {
				toExecute.add(id);
			}
		}
		return toExecute;
	}

	public static void clearAll() {
		executionMap.clear();
	}
}